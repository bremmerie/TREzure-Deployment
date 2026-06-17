# Loaded automatically by Python 3.13 in /opt/az at startup.
# The UZB SSL inspection proxy re-signs TLS certificates without the
# Authority Key Identifier extension. Python 3.13 added X509_V_FLAG_X509_STRICT
# (0x20) as a default, which rejects certs missing AKI. This patch removes
# that flag from every SSL context created by az's Python so that az commands
# can reach Azure endpoints through the corporate proxy.
import ssl as _ssl
_X509_STRICT = 0x20

_orig_cdc = _ssl.create_default_context
def _p_cdc(*a, **kw):
    ctx = _orig_cdc(*a, **kw)
    ctx.verify_flags &= ~_X509_STRICT
    return ctx
_ssl.create_default_context = _p_cdc

try:
    import urllib3.util.ssl_ as _u3
    _orig_u3 = _u3.create_urllib3_context
    def _p_u3(*a, **kw):
        ctx = _orig_u3(*a, **kw)
        ctx.verify_flags &= ~_X509_STRICT
        return ctx
    _u3.create_urllib3_context = _p_u3
except Exception:
    pass
