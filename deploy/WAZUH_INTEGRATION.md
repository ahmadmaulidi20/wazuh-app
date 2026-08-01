# Wazuh Manager Integration

**Server IP: 103.30.194.158** (Backend + Wazuh Manager di server yang sama)

## 1. Copy Script to Wazuh Manager

```bash
scp backend/wazuh/custom-wazuh.py root@103.30.194.158:/var/ossec/integrations/
chmod 755 /var/ossec/integrations/custom-wazuh.py
chown root:ossec /var/ossec/integrations/custom-wazuh.py
```

## 2. Configure Wazuh Manager

Add to `/var/ossec/etc/ossec.conf` inside the `<ossec_config>` block:

```xml
<integration>
    <name>custom-wazuh</name>
    <hook_url>http://localhost:3000/api/webhook/wazuh</hook_url>
    <api_key>ISI_WEBHOOK_API_KEY_DARI_ENV</api_key>
    <level>7</level>
    <alert_format>json</alert_format>
</integration>
```

Or set environment variables in `/var/ossec/etc/environment`:

```
WEBHOOK_URL=http://localhost:3000/api/webhook/wazuh
API_KEY=ISI_WEBHOOK_API_KEY_DARI_ENV
```

## 3. Restart Wazuh Manager

```bash
systemctl restart wazuh-manager
# atau
/var/ossec/bin/ossec-control restart
```

## 4. Verify Integration

```bash
tail -f /var/ossec/logs/ossec.log | grep custom-wazuh
```

## Testing

```bash
echo '{"id":"test-001","rule":{"id":100,"level":10,"description":"Test Alert"},"agent":{"id":"001","name":"test-agent"}}' | WEBHOOK_URL="http://localhost:3000/api/webhook/wazuh" API_KEY="ISI_KEY" python3 /var/ossec/integrations/custom-wazuh.py
```
