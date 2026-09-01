#!/bin/bash
# Upload this script to VPS and run it to set up the environment.
# API_KEY diambil dari variabel env agar tidak tersimpan di repo public.
# Isi nilai asli saat menjalankan, mis.:
#   sudo API_KEY='nilai-webhook-api-key' ./setup-env.sh
sudo cat > /var/ossec/etc/environment << ENVEOF
API_KEY=${API_KEY:-CHANGE_ME}
ENVEOF
sudo chmod 640 /var/ossec/etc/environment
sudo chown root:wazuh /var/ossec/etc/environment
echo "Environment file created:"
cat /var/ossec/etc/environment
