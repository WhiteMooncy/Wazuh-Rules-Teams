# Wazuh Teams Integration

This directory contains the Microsoft Teams integration scripts for Wazuh alert notifications with summary accumulation.

## Files

### custom-teams-summary.py
Main integration script with intelligent alert accumulation (29KB).

**Features:**
- **Alert Accumulation**: Groups multiple alerts before sending to reduce noise
- **Smart Thresholds**: Configurable alert count and time-based triggers
- **Critical Bypass**: High-severity alerts (level ≥15) sent immediately
- **Persistent Cache**: Uses pickle for alert storage across restarts
- **Adaptive Cards**: Rich formatted messages with statistics and details
- **SSL Verification**: Disabled for internal Power Automate webhooks
- **Error Handling**: Comprehensive logging and retry logic

**Configuration:**
```python
MAX_ALERTS_BEFORE_SUMMARY = 3  # Send summary after this many alerts
SUMMARY_INTERVAL_HOURS = 24     # Or after this many hours
CRITICAL_LEVEL = 15             # Alerts at this level bypass accumulation
```

**Key Functions:**
- `load_cache()`: Loads persisted alert data from disk
- `save_cache()`: Saves current alerts to disk
- `should_send_summary()`: Determines if summary should be sent
- `build_summary_card()`: Creates Teams Adaptive Card for summary
- `build_immediate_alert()`: Creates Teams card for critical alerts
- `send_msg()`: Sends HTTP requests to Power Automate webhook

### custom-teams-direct.py *(optional alternative)*
Direct alert integration without accumulation - sends every alert immediately.

**Use Case**: High-criticality environments where every alert must be reviewed individually.

### wrapper_custom-teams.sh
Bash wrapper for Python integration execution.

**Purpose:**
- Sets proper environment variables
- Handles Python path resolution
- Provides error logging
- Ensures correct working directory

## Installation

### 1. Copy Integration Script

```bash
sudo cp custom-teams-summary.py /var/ossec/integrations/
```

### 2. Set Permissions

```bash
sudo chown root:wazuh /var/ossec/integrations/custom-teams-summary.py
sudo chmod 750 /var/ossec/integrations/custom-teams-summary.py
```

### 3. Make Executable

```bash
sudo chmod +x /var/ossec/integrations/custom-teams-summary.py
```

### 4. Test Script Manually

```bash
# Get a sample alert from logs
ALERT_JSON=$(sudo tail -1 /var/ossec/logs/alerts/alerts.json)

# Test the integration
echo "$ALERT_JSON" | sudo /var/ossec/integrations/custom-teams-summary.py \
  "YOUR_WEBHOOK_URL" \
  11 \
  "custom-teams-summary"
```

### 5. Configure in ossec.conf

Edit `/var/ossec/etc/ossec.conf` and add:

```xml
<integration>
  <name>custom-teams-summary</name>
  <hook_url>YOUR_POWER_AUTOMATE_WEBHOOK_URL</hook_url>
  <level>11</level>
  <alert_format>json</alert_format>
  <options>{"verify_ssl": false}</options>
</integration>
```

### 6. Restart Wazuh Manager

```bash
sudo systemctl restart wazuh-manager
```

## Configuration Options

### Alert Level Threshold

Controls which alerts trigger the integration:

```xml
<level>11</level>  <!-- Only alerts level 11+ will be processed -->
```

**Recommended Values:**
- **`level="11"`**: High sensitivity (recommended for summary mode)
- **`level="13"`**: Medium sensitivity (fewer alerts)
- **`level="15"`**: Critical only (very few alerts)

### Webhook URL

Get your webhook from Power Automate flow:

1. Create **Instant cloud flow** → **When an HTTP request is received**
2. Copy **HTTP POST URL**
3. Replace in `<hook_url>` tag

Format example:
```
https://[tenant].environment.api.powerplatform.com/workflows/[workflow-id]/triggers/manual/paths/invoke?api-version=1&sp=/triggers/manual/run&sv=1.0&sig=[signature]
```

### Summary Tuning

Edit thresholds in `custom-teams-summary.py`:

```python
# Trigger summary after 3 alerts OR 24 hours (whichever comes first)
MAX_ALERTS_BEFORE_SUMMARY = 3
SUMMARY_INTERVAL_HOURS = 24
CRITICAL_LEVEL = 15  # Alerts ≥ this level sent immediately
```

**Tuning Guidelines:**

| Environment | MAX_ALERTS | INTERVAL_HOURS | CRITICAL_LEVEL |
|-------------|------------|----------------|----------------|
| Production  | 5          | 6              | 15             |
| Development | 10         | 24             | 13             |
| Testing     | 3          | 2              | 11             |

## Cache System

The integration uses a persistent cache to store alerts:

**Cache Location:** `/var/ossec/logs/teams_alerts_cache.pkl`

**Cache Structure:**
```python
{
    'alerts': [
        {
            'timestamp': '2025-03-11T10:30:00',
            'agent_name': 'Windows-Server',
            'rule_id': '100001',
            'rule_description': 'Kerberos TGT Request',
            'rule_level': 12
        },
        # ... more alerts
    ],
    'last_summary_time': '2025-03-11T09:00:00',
    'summary_count': 15
}
```

### Cache Management

**View cache contents:**
```bash
sudo python3 -c "import pickle; print(pickle.load(open('/var/ossec/logs/teams_alerts_cache.pkl','rb')))"
```

**Clear cache manually:**
```bash
sudo rm /var/ossec/logs/teams_alerts_cache.pkl
```

**Reset summary counter:**
```bash
sudo python3 << 'EOF'
import pickle
import os
cache_file = '/var/ossec/logs/teams_alerts_cache.pkl'
if os.path.exists(cache_file):
    data = pickle.load(open(cache_file, 'rb'))
    data['summary_count'] = 0
    pickle.dump(data, open(cache_file, 'wb'))
    print("[OK] Summary counter reset")
EOF
```

## Monitoring

### Check Integration Logs

```bash
sudo tail -f /var/ossec/logs/integrations.log | grep custom-teams
```

### Verify Alerts Being Processed

```bash
sudo grep "custom-teams-summary" /var/ossec/logs/ossec.log
```

### Test Summary Send

```bash
# Add exactly MAX_ALERTS_BEFORE_SUMMARY test alerts
for i in {1..3}; do
  echo '{"timestamp":"2025-03-11T10:00:00","agent":{"name":"Test"},"rule":{"id":"100001","level":12,"description":"Test Alert"}}' | \
  sudo /var/ossec/integrations/custom-teams-summary.py "YOUR_WEBHOOK" 11 "custom-teams-summary"
done
```

### Expected Output

**On alert accumulation:**
```
[INFO] Alert accumulated (2/3). Not sending yet.
```

**On summary send:**
```
[OK] Summary sent: 5 alerts accumulated
```

**On critical alert:**
```
[CRITICAL] Immediate alert sent (level 15)
```

## Troubleshooting

### Issue: Alerts Not Accumulating

**Symptoms:** Every alert sent immediately

**Diagnosis:**
```bash
ls -lh /var/ossec/logs/teams_alerts_cache.pkl
```

**Solution:**
```bash
# Ensure cache directory is writable
sudo chmod 755 /var/ossec/logs
sudo chown root:wazuh /var/ossec/logs
```

### Issue: HTTP 404 from Webhook

**Symptoms:** `HTTPError: 404 Not Found`

**Causes:**
1. Teams channel changed type (Conversaciones ↔ Publicaciones)
2. Webhook expired or regenerated
3. Power Automate flow disabled

**Solution:**
1. Go to Power Automate → **My flows**
2. Find your Wazuh integration flow
3. Copy **HTTP POST URL** again
4. Update `hook_url` in ossec.conf
5. Restart Wazuh Manager

### Issue: Summaries Not Sending After 24 Hours

**Symptoms:** Alerts accumulating beyond time threshold

**Diagnosis:**
```bash
# Check last summary time
sudo python3 -c "import pickle; cache=pickle.load(open('/var/ossec/logs/teams_alerts_cache.pkl','rb')); print('Last summary:', cache.get('last_summary_time'))"
```

**Solution:**
```bash
# Manually trigger summary
echo '{}' | sudo /var/ossec/integrations/custom-teams-summary.py "YOUR_WEBHOOK" 15 "custom-teams-summary"
```

### Issue: SSL Certificate Errors

**Symptoms:** `SSLError: certificate verify failed`

**Solution:** Ensure `verify=False` in `send_msg()` function:
```python
response = urllib.request.urlopen(request, timeout=30, context=ssl._create_unverified_context())
```

### Issue: Python Module Missing

**Symptoms:** `ModuleNotFoundError: No module named 'json'`

**Solution:**
```bash
# Verify Python 3 is installed
python3 --version

# Reinstall Python if needed
sudo yum reinstall python3
```

## Alert Format Examples

### Summary Message in Teams

```
📊 WAZUH SECURITY SUMMARY

Period: Last 24 hours
Total Alerts: 5

📍 By Agent:
• Windows-Server-01: 3 alerts
• Windows-DC-01: 2 alerts

🔥 By Severity:
• Level 12 (High): 3 alerts
• Level 11 (Medium): 2 alerts

🎯 Top Rules:
• 100001: Kerberos TGT Request (2)
• 100016: User Account Created (1)
• 100007: Service Installed (1)
• 100048: Event Log Cleared (1)

Dashboard: http://10.0.0.10:5601/...
```

### Critical Alert Message

```
🚨 CRITICAL WAZUH ALERT

Agent: Windows-Server-01
Rule: 100036 (Level 15)
Description: Mimikatz credential theft detected

Event ID: 10
Time: 2025-03-11 10:30:45
Source: Windows Security

⚠️ IMMEDIATE ACTION REQUIRED

Dashboard: http://10.0.0.10:5601/...
```

## Performance Considerations

**Cache File Size:**
- Typical: 2-10 KB
- High traffic: 50-100 KB
- Managed automatically (old alerts pruned)

**CPU Impact:**
- Minimal (<0.1% on 4-core system)
- Pickle operations are fast (<1ms)

**Network Traffic:**
- Summary mode: ~5-10 requests/day
- Direct mode: 40-100 requests/day (80% reduction with summary)

## Security Recommendations

1. **Protect Webhook URL**: Treat as secret credential
2. **Use HTTPS**: Power Automate enforces this automatically
3. **Restrict Integration Permissions**:
   ```bash
   sudo chmod 750 /var/ossec/integrations/custom-teams-summary.py
   ```
4. **Monitor for Tampering**:
   ```bash
   sha256sum /var/ossec/integrations/custom-teams-summary.py
   ```
5. **Regular Backups**:
   ```bash
   sudo cp /var/ossec/integrations/custom-teams-summary.py /root/backups/
   ```

## Migration to New Server

When migrating to a new Wazuh server:

1. Copy integration script
2. Copy cache file (to preserve state)
3. Update webhook URL in ossec.conf
4. Verify permissions
5. Test with sample alert

See [docs/MIGRATION.md](../docs/MIGRATION.md) for detailed steps.

## Contributing

To improve the integration:

1. Test changes in development environment
2. Validate against sample alerts
3. Update thresholds based on alert volume
4. Document configuration changes

## References

- [Wazuh Integration Documentation](https://documentation.wazuh.com/current/user-manual/manager/manual-integration.html)
- [Power Automate HTTP Triggers](https://learn.microsoft.com/en-us/power-automate/triggers-introduction)
- [Teams Adaptive Cards](https://adaptivecards.io/)
