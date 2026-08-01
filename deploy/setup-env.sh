#!/bin/bash
# Upload this script to VPS and run it to set up the environment
sudo cat > /var/ossec/etc/environment << 'ENVEOF'
API_KEY=0d6630a9f1c2500daec2a16419e56b666e28fefb4b8c52a6
ENVEOF
sudo chmod 640 /var/ossec/etc/environment
sudo chown root:wazuh /var/ossec/etc/environment
echo "Environment file created:"
cat /var/ossec/etc/environment
