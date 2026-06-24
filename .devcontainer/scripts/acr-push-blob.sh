#!/bin/bash
# Push a single blob to ACR in chunks, bypassing proxy size limits on monolithic uploads.
#
# Usage:
#   acr-push-blob.sh <acr-name> <repository> <blob-digest> <blob-file>
#
# Example (after extracting a layer via docker save):
#   acr-push-blob.sh acruzbtrezurecoreuat tre-shared-service-firewall \
#     sha256:836699bc... /tmp/layer.tar.gz
#
# Typical workflow when porter publish / docker push fails with 416:
#   1. Find the failing blob digest in the error output
#   2. Extract it: docker save <image> | tar -xO blobs/sha256/<hash> > /tmp/layer.tar.gz
#   3. Run this script to push it
#   4. Re-run porter publish / docker push (blob will show "Layer already exists")

set -o errexit
set -o pipefail
set -o nounset

ACR_NAME="${1:?Usage: $0 <acr-name> <repository> <blob-digest> <blob-file>}"
REPOSITORY="${2:?}"
BLOB_DIGEST="${3:?}"
BLOB_FILE="${4:?}"

BASE_URL="https://${ACR_NAME}.azurecr.io"
CHUNK_SIZE=5242880  # 5MB chunks

if [ ! -f "$BLOB_FILE" ]; then
  echo "Error: blob file not found: $BLOB_FILE" >&2
  exit 1
fi

BLOB_SIZE=$(wc -c < "$BLOB_FILE")
echo "Blob: $BLOB_DIGEST"
echo "Size: $BLOB_SIZE bytes ($(( BLOB_SIZE / 1024 / 1024 ))MB)"
echo "Repository: ${ACR_NAME}.azurecr.io/${REPOSITORY}"

get_token() {
  local REFRESH_TOKEN
  REFRESH_TOKEN=$(az acr login --name "$ACR_NAME" --expose-token --output tsv --query accessToken 2>/dev/null)
  curl -s -X POST "${BASE_URL}/oauth2/token" \
    --data-urlencode "grant_type=refresh_token" \
    --data-urlencode "service=${ACR_NAME}.azurecr.io" \
    --data-urlencode "scope=repository:${REPOSITORY}:push,pull" \
    --data-urlencode "refresh_token=$REFRESH_TOKEN" \
    | jq -r '.access_token'
}

TOKEN=$(get_token)

echo "Starting upload session..."
SESSION_URL=$(curl -s -i -X POST \
  -H "Authorization: Bearer $TOKEN" \
  "${BASE_URL}/v2/${REPOSITORY}/blobs/uploads/" \
  | grep -i "^location:" | tr -d '\r' | awk '{print $2}')

if [ -z "$SESSION_URL" ]; then
  echo "Error: failed to get upload session" >&2
  exit 1
fi
echo "Session started: $(echo "$SESSION_URL" | grep -o '[0-9a-f-]\{36\}')"

OFFSET=0
CHUNK_NUM=0
while [ "$OFFSET" -lt "$BLOB_SIZE" ]; do
  END=$(( OFFSET + CHUNK_SIZE - 1 ))
  [ "$END" -ge "$BLOB_SIZE" ] && END=$(( BLOB_SIZE - 1 ))
  CHUNK_LEN=$(( END - OFFSET + 1 ))
  CHUNK_NUM=$(( CHUNK_NUM + 1 ))

  echo -n "  Chunk ${CHUNK_NUM}: bytes ${OFFSET}-${END} ($(( CHUNK_LEN / 1024 ))KB)... "

  RESP=$(curl -s -i -X PATCH \
    "${BASE_URL}${SESSION_URL}" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/octet-stream" \
    -H "Content-Range: ${OFFSET}-${END}" \
    -H "Content-Length: ${CHUNK_LEN}" \
    --data-binary "@-" \
    < <(dd if="$BLOB_FILE" bs=1 skip="$OFFSET" count="$CHUNK_LEN" 2>/dev/null))

  CODE=$(echo "$RESP" | grep "^HTTP" | tail -1 | awk '{print $2}')
  NEW_LOC=$(echo "$RESP" | grep -i "^location:" | tr -d '\r' | awk '{print $2}')
  [ -n "$NEW_LOC" ] && SESSION_URL="$NEW_LOC"

  if [ "$CODE" != "202" ]; then
    echo "FAILED (HTTP $CODE)"
    echo "$RESP" | tail -5 >&2
    exit 1
  fi

  echo "OK"
  OFFSET=$(( END + 1 ))

  # Refresh token every ~25MB to avoid expiry on large blobs
  if [ $(( CHUNK_NUM % 5 )) -eq 0 ]; then
    TOKEN=$(get_token)
  fi
done

echo -n "Committing blob... "
TOKEN=$(get_token)
RESULT=$(curl -s -i -X PUT \
  "${BASE_URL}${SESSION_URL}&digest=${BLOB_DIGEST}" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Length: 0")

CODE=$(echo "$RESULT" | grep "^HTTP" | tail -1 | awk '{print $2}')
COMMITTED_DIGEST=$(echo "$RESULT" | grep -i "docker-content-digest:" | tr -d '\r' | awk '{print $2}')

if [ "$CODE" = "201" ]; then
  echo "OK"
  echo "Committed: $COMMITTED_DIGEST"
else
  echo "FAILED (HTTP $CODE)"
  echo "$RESULT" | tail -5 >&2
  exit 1
fi
