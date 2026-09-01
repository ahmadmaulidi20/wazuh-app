#!/bin/bash
# ============================================================
# FIX pgAdmin Blank White Page on VPS (nginx native)
# Apply the proven-working nginx /pgadmin/ reverse-proxy block.
# Run on the VPS via SSH. Does NOT mutate the pgAdmin container.
# Sealum itu pastikan .htpasswd sudah benar, mis. lewat setup-htpasswd.sh.
# ============================================================
set -e

NGINX_CONF="/etc/nginx/sites-available/siem-web"
if [ ! -f "$NGINX_CONF" ]; then NGINX_CONF="/etc/nginx/conf.d/default.conf"; fi
domain_file="$NGINX_CONF"

echo "Using nginx config: $NGINX_CONF"

TS=$(date +%Y%m%d-%H%M%S)
sudo cp "$NGINX_CONF" "/tmp/siem-web.bak-fix.$TS"
echo "Backup -> /tmp/siem-web.bak-fix.$TS"

echo ""
echo "=== Applying verified pgAdmin reverse-proxy block ==="
sudo python3 - "$NGINX_CONF" << 'PYEOF'
import re, sys
path = sys.argv[1]
with open(path) as f:
    c = f.read()

new_block = '''    location /pgadmin/ {
        auth_basic "Restricted Database GUI";
        auth_basic_user_file /etc/nginx/.htpasswd;

        proxy_pass http://127.0.0.1:8080/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Script-Name /pgadmin;
        proxy_read_timeout 3600s;
        proxy_send_timeout 3600s;
        proxy_redirect / /pgadmin/;
        proxy_cookie_path / /pgadmin/;

        sub_filter_once off;
        sub_filter_types text/html;
        sub_filter 'href="/static/' 'href="/pgadmin/static/';
        sub_filter 'src="/static/' 'src="/pgadmin/static/';
        sub_filter 'href="/browser/' 'href="/pgadmin/browser/';
        sub_filter 'src="/browser/' 'src="/pgadmin/browser/';
        sub_filter 'src="/tools/' 'src="/pgadmin/tools/';
        sub_filter 'src="/vendor/' 'src="/pgadmin/vendor/';
        sub_filter 'href="/assets/' 'href="/pgadmin/assets/';
        sub_filter 'src="/assets/' 'src="/pgadmin/assets/';
        sub_filter 'src="/favicon' 'src="/pgadmin/favicon';
        sub_filter 'href="/favicon' 'href="/pgadmin/favicon';
    }
'''

pat = re.compile(r'    location /pgadmin/ \{.*?\n    \}\n', re.DOTALL)
if pat.search(c):
    c = pat.sub(new_block, c, count=1)
    print("  REPLACED /pgadmin/ block")
else:
    print("  WARNING: /pgadmin/ block not found; leaving config unchanged.")
    sys.exit(0)

with open(path, 'w') as f:
    f.write(c)
PYEOF

echo ""
echo "=== Testing & reloading nginx ==="
if sudo nginx -t 2>&1; then
    sudo systemctl reload nginx
    echo "  nginx reloaded OK"
else
    echo "  NGINX TEST FAILED - rolling back"
    LATEST_BAK=$(ls -t /tmp/siem-web.bak-fix.* | head -1)
    sudo cp "$LATEST_BAK" "$NGINX_CONF"
    exit 1
fi

echo ""
echo "=== Verify candidates ==="
URL="https://siemkampus-monitoring-app.duckdns.org"
HTPASSWD_USER="${HTPASSWD_USER:-dbadmin}"
HTPASSWD_PASS="${HTPASSWD_PASS:-CHANGE_ME}"
code=$(curl -sk -o /dev/null -w '%{http_code}' -u "$HTPASSWD_USER:$HTPASSWD_PASS" "$URL/pgadmin/")
echo "  /pgadmin/ (basic auth) -> HTTP $code"
code2=$(curl -sk -o /dev/null -w '%{http_code}' "$URL/health")
echo "  /health -> HTTP $code2"
echo ""
echo "NOTE: basic-auth password diambil dari env HTPASSWD_PASS (default CHANGE_ME)."
echo "Set HTPASSWD_USER/HTPASSWD_PASS saat menjalankan, atau pakai setup-htpasswd.sh terlebih dahulu."
echo "pgAdmin login: admin@siemkampus.id (password = PGADMIN_DEFAULT_PASSWORD in compose)."
echo "=== DONE ==="
