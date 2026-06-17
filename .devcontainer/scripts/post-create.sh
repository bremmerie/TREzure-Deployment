#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset
# Uncomment this line to see each command for debugging (careful: this will show secrets!)
# set -o xtrace

# show the AzureTRE OSS folder inside the workspace one
rm -fr AzureTRE || true
ln -s "${AZURETRE_HOME}" AzureTRE

cp ~/AzureTRE/config.sample.yaml .

# docker socket fixup
sudo bash AzureTRE/devops/scripts/set_docker_sock_permission.sh

# Patch AzureTRE and az for the UZB corporate SSL inspection proxy.
# The proxy re-signs TLS certs without the Authority Key Identifier extension,
# which Python 3.13 (used by az) rejects, and curl inside Docker builds can't verify.
DEVCONTAINER_DIR="/workspaces/TREzure-Deployment/.devcontainer"

# 1. Fix az acr login: patch Python 3.13 ssl to drop X509_V_FLAG_X509_STRICT
sudo cp "${DEVCONTAINER_DIR}/sitecustomize.py" /opt/az/lib/python3.13/site-packages/sitecustomize.py

# 2. Inject UZB cert into resource_processor Docker build context so curl works during porter install
python3 - << 'PYEOF'
import os, shutil

azuretre_home = os.environ.get("AZURETRE_HOME", os.path.expanduser("~/AzureTRE"))
devcontainer_dir = "/workspaces/TREzure-Deployment/.devcontainer"
dockerfile = os.path.join(azuretre_home, "resource_processor/vmss_porter/Dockerfile")
scripts_dir = os.path.join(azuretre_home, "resource_processor/scripts")

shutil.copy(os.path.join(devcontainer_dir, "uzb_root_ca.crt"), os.path.join(scripts_dir, "uzb_root_ca.crt"))

patch = (
    "# Install UZB corporate CA cert so curl can download through the SSL inspection proxy\n"
    "COPY scripts/uzb_root_ca.crt /usr/local/share/ca-certificates/uzb_root_ca.crt\n"
    "RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates \\\n"
    "    && update-ca-certificates && rm -rf /var/lib/apt/lists/*\n"
    "ENV CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt\n\n"
)
marker = "ARG PORTER_HOME_V1=/root/.porter/"

with open(dockerfile) as f:
    content = f.read()

if "uzb_root_ca.crt" not in content:
    content = content.replace(marker, patch + marker)
    with open(dockerfile, "w") as f:
        f.write(content)
    print("Patched resource_processor/vmss_porter/Dockerfile")
else:
    print("resource_processor/vmss_porter/Dockerfile already patched")
PYEOF

# 3. Patch all Porter bundle Dockerfile.tmpl files to install UZB CA cert before mixin steps
python3 - << 'PYEOF'
import os, glob

azuretre_home = os.environ.get("AZURETRE_HOME", os.path.expanduser("~/AzureTRE"))
cert_b64 = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUY3VENDQTlXZ0F3SUJBZ0lUWGdBQUFBY1REdndhRDVKa09BQUFBQUFBQnpBTkJna3Foa2lHOXcwQkFRc0YKQURDQmx6RWxNQ01HQ1NxR1NJYjNEUUVKQVJZV1kyVnlkR0ZuWlc1MFFIVjZZbkoxYzNObGJDNWlaVEVMTUFrRwpBMVVFQmhNQ1FrVXhFREFPQmdOVkJBZ1RCMEp5ZFhOelpXd3hFREFPQmdOVkJBY1RCMEp5ZFhOelpXd3hFakFRCkJnTlZCQW9UQ1ZWYVFuSjFjM05sYkRFTU1Bb0dBMVVFQ3hNRFNVTlVNUnN3R1FZRFZRUURFeEpWV2lCQ2NuVnoKYzJWc0lGSnZiM1FnUTBFd0hoY05NVGd3TVRFd01UUXdOVEExV2hjTk1qZ3dNVEV3TVRReE5UQTFXakNCcnpFTApNQWtHQTFVRUJoTUNRa1V4RVRBUEJnTlZCQWdUQ0VKeWRYTnpaV3h6TVJFd0R3WURWUVFIRXdoQ2NuVnpjMlZzCmN6RVRNQkVHQTFVRUNoTUtWVm9nUW5KMWMzTmxiREVaTUJjR0ExVUVDeE1RVG1WMGQyOXlheUJUWldOMWNtbDAKZVRFbE1DTUdBMVVFQXhNY1ZWb2dRbkoxYzNObGJDQkpiblJsY201bGRDQlRaV04xY21sMGVURWpNQ0VHQ1NxRwpTSWIzRFFFSkFSWVVkR1ZzWldOdmJVQjFlbUp5ZFhOelpXd3VZbVV3Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBCkE0SUJEd0F3Z2dFS0FvSUJBUUNwWERHaU5hUG5mYWl0SG9DUVVwYnlSWk5XVEJCcVY5U3FUM3VONnYzeW5sVU0KUTEySk16Y294V0Q0b3h1Z0pBZ29ud1FZUmcyYkkwSFpUZXl1NUllS2VycDFXSEdFbURHci9iaWdQcS85cWVQeQo5bEtSYkZzcVluSWlEZVdmYTNZVFFmVTZxSzYxakxGR0xEMllxZjB3RjVtOE52eS9VMlhDTkNnOFIxZUFBRW1mClBLaDJoUHAzVlFjQkxiSWhDQ3ZhbGlpNlNRWm9JZ1NJY3RzOC9RTmJuN2sxS2tQZGUrdWFDV2M4Y0xPVHBweVMKYjhCbUN3d1IwT0dWbGRQQjFqM3c1ampXU05hUUFKam5aRFRjcFUvTGNOeHppTHhiS3lLcy9WWkMvVGxGZldIZwpwcDdvRXNBL0dWbi9DVVB2NVFXc3pTUXhlYjRJbmd0ZEtvQ0pKNXoxQWdNQkFBR2pnZ0VXTUlJQkVqQWRCZ05WCkhRNEVGZ1FVQWtCdFFSd3o4SHEzRTZ1Y2p1WG5HUVdzUFZFd0h3WURWUjBqQkJnd0ZvQVVTSElYUkZZa1p6cisKWmJEZHd0SG9KUHpQNVdrd1JRWURWUjBmQkQ0d1BEQTZvRGlnTm9ZMGFIUjBjRG92TDJOa2NDNTFlbUp5ZFhOegpaV3d1WW1VdlZWb2xNakJDY25WemMyVnNKVEl3VW05dmRDVXlNRU5CTG1OeWJEQlFCZ2dyQmdFRkJRY0JBUVJFCk1FSXdRQVlJS3dZQkJRVUhNQUtHTkdoMGRIQTZMeTlqWkhBdWRYcGljblZ6YzJWc0xtSmxMMVZhSlRJd1FuSjEKYzNObGJDVXlNRkp2YjNRbE1qQkRRUzVqY213d0dRWUpLd1lCQkFHQ054UUNCQXdlQ2dCVEFIVUFZZ0JEQUVFdwpEd1lEVlIwVEFRSC9CQVV3QXdFQi96QUxCZ05WSFE4RUJBTUNBWVl3RFFZSktvWklodmNOQVFFTEJRQURnZ0lCCkFFa2xSWUdmbmttZVJyblFaMUJJbEtsK2xoVENsY2psRWhpYm9CcGgydVpsc01MOWdRTWdBNWNXUUlQZjZlcHgKU0dKRHFRUmRGeVovUk9GVk5tQlRoMVNNdlBodVphc3V1eGFhNS85aWMxZ2dlcVQvV1Bnb3Y2S215ZlNsWDJoWQppbWRKYW1XNmRYTldvd1Fua3ozWTdYQ1kxa3N3WVhDYU9qcEF3RmJpR0ZGSVkyOVIvN2l3STlmZzhDdVFPR1R3CjZtc3VjT29FdHZEWjdITUpFVG1qZGprOTZwMEtCazViVnBqd05Xcnk1aGR5WXVwbUhWUzVucWxNQXVQbUJmQ0kKV1g0eTkwR0l0K3o5TGdnRUg4MlRaZk1MUEZtQ0p0Z0Z5eHRhTzFremVxUU9VUUpoY2x1b1Z0aGtVa05BbjFkRgpsc2JPbkRHWldnQWZUM1ZWMllaREtCKzBzN3B0c2xieUJORDFlSkEvMFQvTjFzanBDenV0MCtKUkdEc3ZXNHVBClhkOXhZR2pNVzZoU2RBejZ6NkFIYmwwY2orQVB3eFJ0RU1wWlN5U2hDM2tIUzY4Vm1ETmVYUzltQzAwQy9NL0IKUEVRTmNRQ3dpNEplY0EzU3hjbVVVV1B3OUxLTk5lUWxTWWFGNjN0ZWJxUW9YbUFtaFhMRURpMEh3Z2lSQTVjWQpnaHNxL1cyWGdNZDBmbDBGRHppWXpWc0s1V1h5TjlnNFh2WVkxdkc5UmdoMjZyR3NvTmp5V3ZPNXlEWHFPY2E1CkdjMzZWTGZlT1VLY1Q5djhIZ0V1R05yeXZsUWxRZUgrQ2tYdEd3VzJ0ZlVhNTV5cXN0TDM5WlVKVHN2N0M2b1YKeWY4NFZqOGtEc1BoV1JyQ0JHbnZJdGtwY2pvZDhKOCtIVldOVWdsSXZmV0wKLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQotLS0tLUJFR0lOIENFUlRJRklDQVRFLS0tLS0KTUlJR0N6Q0NBL09nQXdJQkFnSVFNS3F6ME1QcGw2eEVEZDdkQjNxRHlEQU5CZ2txaGtpRzl3MEJBUXNGQURDQgpsekVsTUNNR0NTcUdTSWIzRFFFSkFSWVdZMlZ5ZEdGblpXNTBRSFY2WW5KMWMzTmxiQzVpWlRFTE1Ba0dBMVVFCkJoTUNRa1V4RURBT0JnTlZCQWdUQjBKeWRYTnpaV3d4RURBT0JnTlZCQWNUQjBKeWRYTnpaV3d4RWpBUUJnTlYKQkFvVENWVmFRbkoxYzNObGJERU1NQW9HQTFVRUN4TURTVU5VTVJzd0dRWURWUVFERXhKVldpQkNjblZ6YzJWcwpJRkp2YjNRZ1EwRXdIaGNOTVRjeE1ERXhNRGswTmpNNVdoY05ORGN4TURFeE1EazFOak0yV2pDQmx6RWxNQ01HCkNTcUdTSWIzRFFFSkFSWVdZMlZ5ZEdGblpXNTBRSFY2WW5KMWMzTmxiQzVpWlRFTE1Ba0dBMVVFQmhNQ1FrVXgKRURBT0JnTlZCQWdUQjBKeWRYTnpaV3d4RURBT0JnTlZCQWNUQjBKeWRYTnpaV3d4RWpBUUJnTlZCQW9UQ1ZWYQpRbkoxYzNObGJERU1NQW9HQTFVRUN4TURTVU5VTVJzd0dRWURWUVFERXhKVldpQkNjblZ6YzJWc0lGSnZiM1FnClEwRXdnZ0lpTUEwR0NTcUdTSWIzRFFFQkFRVUFBNElDRHdBd2dnSUtBb0lDQVFEQ1pKbFdvRkhBUlU3SjNGeXkKS0ZidkJEOFI0UTVESm41cy9qNHJqek1vUitGaThFYklYOTNob2lmMWwyUE9pNHl5UVNqbUlOS2FTblNqV2t6cgpwYVZaVlZWK2p0ckhsTkxtYkNrN0VVMEFVTytJSTFSaVgzQUZYcXl5NGc1NkZXM2N3WGIydlorc29SNXVvSy85CkRUaTU0SUNWWHRmT2RJdEJDUFpPSFRPVmVBNFRXUmJoSHQrbXBJTE1NN3ZtMTZkTjVHcy9QSGNnZ2lRY203MVYKS1J6Vi9Tc3FOc0JCbnowNExSaWJ1SU9kd2dzSTlZM2lpenVWVlFVcFdtbUI2bHBQN0U3dzlvbEExWHpxSkpyZQpHOE1MeEtYNEU5Q0NFRmJ4UFJpNitDRG05UWU5NUpjRDgrQmZ3WE10Unl4RExob3J2akdoTVdBaVhYZlBERWRDCnpBbmNTMXVTU2U4WllnRTBHZ3EzUFZEcjFjKzF2eEdyZDJaZ2ZqWk5VbHZKSm44Q3J5UWx5OXIzRmo4US9adDkKQU9JV2VDcDcxYkZIVmg3amgvaUZvTzQ3QTZ0SnZjOXhVdVNsM01XVExxejlJWExBQXdCWXlCN0wvUXAxeXNDcQpOSmt5Z2ZOSGRJTHVqNzE5NXFJc28zdHJLdVRlWEZCTmxwSzhTS2pOWmZIbDg5d0RTREZVdFp1em03MkNGL3JlCk01emdRTDI1eGxpM2EwaFl6cUtOS1Z0ZEZzNTI2bktzL3dxbkt5MGhBZHZSQjhyRHZMZjlWTGJwb0RybmdtSmUKQkxnT0U3eklNR3djUmYyUXlhcERYOWpVaWNaVjNIc29JSG5nbGhQZkNKUnNUSmQwaWkrU0FzRDhQcStwRHc2agpjcmQwU09mWExSdWo1aTdTNlRQRm9zMWlGd0lEQVFBQm8xRXdUekFMQmdOVkhROEVCQU1DQVlZd0R3WURWUjBUCkFRSC9CQVV3QXdFQi96QWRCZ05WSFE0RUZnUVVTSElYUkZZa1p6citaYkRkd3RIb0pQelA1V2t3RUFZSkt3WUIKQkFHQ054VUJCQU1DQVFBd0RRWUpLb1pJaHZjTkFRRUxCUUFEZ2dJQkFMampFUlZMbGp3ZysyWm1HazZaU2I3OApqaXJhWHhWaEE2cytWSGVRZVJzOVo0SXA0T1BTRWx0dzZpYUpHTFRxWmxsOXBkdS9kd25oSlRhNlpWRCtyQXV2Cm9vbFJ2QkQ4eC9nbXVMbEJCb2pvSTB4djh0MWtSR1kwZzJ0dy9meDdGaTVXT0pDRy9CcTBvQjNoaVlSWkpvRlEKcGpVNUJiZ0xxajcrTXlZVXpKdWRjenYxblZYS21vdk9oaCtBRHdOQVZqODdMWmZScFUxSndNNnBXYWRiWTNnLwpGbGhTTUY5a01RdVd3cDZTZE42TjZSdzlKUG15V0tpOHFoOVNxbnJGRmZoSWNmZjQrT0NndDh4aHFYKzEvYUpECldTcHBldkhib0JBTXh4WVROOVFNUUhIRkNNMUd1SitMbjZld013M1pKLzU4Y2NnWkdxdEJ0NDIzZWtZSmpLLzUKQ3N4NmlRLzJMMXA0bVlzYnRmSEJKTVdMQUlVck5oK3FPbUZYQ3Y5djRDeTI3MmFYU2NNOVBqR2lxUGRuR1dXMgozc0ZQTUJwdFluQkZWaUw0aHViUnRXaytmVHhCcURHZ1VEWS9ORWZ2UkVmSlNzdkZLUjE3c002bU1VY3VRZ0YyCittbDdKajZMY0RJNGpucDhmNm00V0lzOGdDVXZkbXVwNUdoMUVEaWFTYk5hN2xPeGMyNmlFYkRHN2lCOC8rbFYKY2JLNHVFVXVydis1RFM4WTRTU3VHZytMd1MvZytaK0JiVitPdnBCRHViRTN2RWFSVkxzb3c4VTNySEt1UWFBQgpHV1dZZTNPejI2N081eGJ3eEpEZjl4MDVMNFZUS25KalVHck1iSEc0R3MyTTh3aitpUzhKYzM5OVdabElVbno1CkR1MERIYzRyYkFQZzMzSkNNRXZ0Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K"

patch = f"""# Install UZB corporate CA cert so wget/curl can connect through the SSL inspection proxy
RUN mkdir -p /usr/local/share/ca-certificates \\\\
    && echo "{cert_b64}" | base64 -d > /usr/local/share/ca-certificates/uzb_root_ca.crt \\\\
    && apt-get update && apt-get install -y --no-install-recommends ca-certificates \\\\
    && update-ca-certificates && rm -rf /var/lib/apt/lists/*
ENV CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

# PORTER_MIXINS"""

marker = "# PORTER_MIXINS"
templates = glob.glob(f"{azuretre_home}/templates/**/Dockerfile.tmpl", recursive=True)
patched = already = 0
for tmpl in templates:
    with open(tmpl) as f:
        content = f.read()
    if "uzb_root_ca" in content:
        already += 1
        continue
    if marker not in content:
        continue
    with open(tmpl, "w") as f:
        f.write(content.replace(marker, patch, 1))
    patched += 1
print(f"Porter Dockerfile.tmpl: {patched} patched, {already} already patched")
PYEOF

# 4. (One-time fix, NOT for fresh installs) Copy Terraform import blocks for pre-existing
#    Azure resources that are missing from state. imports.tf contains hardcoded resource IDs
#    specific to this deployment — enabling this on a fresh install will break terraform plan
#    because it tries to import resources that don't exist yet.
#
# python3 - << 'PYEOF'
# import os, shutil
# azuretre_home = os.environ.get("AZURETRE_HOME", os.path.expanduser("~/AzureTRE"))
# devcontainer_dir = "/workspaces/TREzure-Deployment/.devcontainer"
# src = os.path.join(devcontainer_dir, "imports.tf")
# dst = os.path.join(azuretre_home, "core/terraform/imports.tf")
# if os.path.exists(src):
#     shutil.copy(src, dst)
#     print(f"Copied imports.tf to {dst}")
# else:
#     print(f"No imports.tf found at {src}, skipping")
# PYEOF
