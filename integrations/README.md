# Wazuh Teams Integration

This directory contains the Microsoft Teams integration scripts for Wazuh SIEM alert notifications.

## Status: PRODUCTION vs. PROPOSED

⚠️ **IMPORTANT:** This directory contains both production-ready and experimental/proposed code.

| Script | Status | Features | Deployment |
|--------|--------|----------|------------|
| `custom-teams-summary.py` | ✅ PRODUCTION (v4.1) | Real-time alerts, simple reliable | ACTIVE at 10.27.20.171 |
| `custom-teams-summary-FIXED.py` | 🔧 EXPERIMENTAL | Enhanced features, caching, retry | Under testing |

For details on the difference between versions, see [IMPROVEMENTS.md](../IMPROVEMENTS.md)

## Files

### custom-teams-summary.py (PRODUCTION)
**Current production script** - Simple, fast, reliable real-time alert processing.

**Current Features:**
- ✅ **Real-time Processing**: Each alert sends immediately to Teams
- ✅ **Adaptive Cards**: Rich formatted messages with severity color-coding
- ✅ **Dashboard Links**: Dynamic links to Wazuh Dashboard (192.168.30.2)
- ✅ **VirusTotal Integration**: Includes VT links when available in alert data
- ✅ **Alert Validation**: Verifies webhook URL and alert integrity
- ✅ **Simple Timeout**: 30-second timeout per request
- ✅ **Logging**: Records to `/var/ossec/logs/integrations.log`

**Why This Design?**
- Stateless (no cache complications)
- Low memory footprint (~20MB)
- Fast alert delivery (2-5 seconds typical)
- Easy to troubleshoot and maintain
- Proven stable in production

### custom-teams-summary-FIXED.py (EXPERIMENTAL)
**Enhanced version** with advanced features (under testing, NOT production-ready).

**Proposed Features (Not Active):**
- ⏳ Alert accumulation (cache-based)
- ⏳ Summary messages after N alerts or X hours
- ⏳ Retry logic with exponential backoff
- ⏳ Thread-safe file locking
- ⏳ Enhanced validation and deduplication

**Status:** Designed and documented but requires additional field testing before production deployment.

**For more information:** See [IMPROVEMENTS.md](../IMPROVEMENTS.md) for detailed comparison and rationale.

## Installation (Production v4.1)

### 1. Copy Integration Script (choose one)

**Option A: Production Script (Recommended)**
```bash
sudo cp custom-teams-summary.py /var/ossec/integrations/custom-teams-summary.py
```

**Option B: Experimental Script (Testing Only)**
```bash
sudo cp custom-teams-summary-FIXED.py /var/ossec/integrations/custom-teams-summary.py
```

### 2. Set Permissions

```bash
sudo chown root:wazuh /var/ossec/integrations/custom-teams-summary.py
sudo chmod 750 /var/ossec/integrations/custom-teams-summary.py
sudo chmod +x /var/ossec/integrations/custom-teams-summary.py
```

### 3. Verify Script Syntax

```bash
# Validate Python syntax
python3 -m py_compile /var/ossec/integrations/custom-teams-summary.py
echo $?  # Should show 0 (no errors)
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
</integration>
```

### 6. Restart Wazuh Manager

```bash
sudo systemctl restart wazuh-manager

# Verify it's running
sudo systemctl status wazuh-manager

# Check logs
sudo tail -20 /var/ossec/logs/ossec.log | grep custom-teams
```

## Configuration Options

### Alert Level Threshold

Controls which alerts trigger the integration:

```xml
<level>11</level>  <!-- Only alerts level 11+ will be processed -->
```

**Recommended Values:**
- **`level="11"`**: High sensitivity (recommended, catches most events)
- **`level="13"`**: Medium sensitivity (fewer alerts)
- **`level="15"`**: Critical only (immediate delivery only)

### Webhook URL

Get your webhook from Power Automate flow:

1. Create **Instant cloud flow** → **When an HTTP request is received**
2. Copy **HTTP POST URL**
3. Replace in `<hook_url>` tag

Format example:
```
https://[tenant].environment.api.powerplatform.com/workflows/[workflow-id]/triggers/manual/paths/invoke?api-version=1&sp=/triggers/manual/run&sv=1.0&sig=[signature]
```

### Configuration for Production Script (v4.1)

The production script has minimal configuration needed:

```python
# These are hardcoded and work well for most environments
LOG_FILE = "/var/ossec/logs/integrations.log"
DASHBOARD_BASE = "https://192.168.30.2"  # Update to your Wazuh Dashboard IP
```

**Change Dashboard IP if needed:**
```bash
sudo nano /var/ossec/integrations/custom-teams-summary.py
# Edit: DASHBOARD_BASE = "https://YOUR-DASHBOARD-IP"
```

### Configuration for Experimental Script (FIXED)

This version supports environment variables for tuning (if using FIXED version):

```bash
# Set these BEFORE restarting wazuh-manager
export WAZUH_TEAMS_SUMMARY_HOURS=24
export WAZUH_TEAMS_MAX_ALERTS=3
export WAZUH_TEAMS_CRITICAL_LEVEL=15
export WAZUH_TEAMS_CACHE_AGE=48
```

**Note:** The FIXED version is experimental. Do not use in production without thorough testing.

## Cache System

### Production Script (v4.1) - No Cache

The **production script is stateless** and does NOT use cache:
- ✅ No pickle files
- ✅ No state persistence
- ✅ Each alert processed independently
- ✅ No cache corruption risk

**Default behavior:** Alerts sent immediately in real-time (2-5 seconds typical).

### Experimental Script (FIXED) - Optional Cache

If using the experimental FIXED version, it can optionally use persistent cache:

**Cache Location:** `/var/ossec/logs/teams_alerts_cache.pkl`

**When cache is used:**
- Alerts are accumulated and grouped
- Summary sent after N alerts or X hours
- Cache survives Wazuh restarts

**Cache Management (FIXED version only):**

```bash
# View cache contents
sudo python3 -c "import pickle; print(pickle.load(open('/var/ossec/logs/teams_alerts_cache.pkl','rb')))"

# Clear cache manually
sudo rm /var/ossec/logs/teams_alerts_cache.pkl

# Reset summary counter
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

⚠️ **Note:** Cache features are only available in FIXED version, which is still experimental.

## Monitoring & Testing

### Check Integration Logs

```bash
# Real-time log monitoring
sudo tail -f /var/ossec/logs/integrations.log | grep custom-teams

# Or check recent history
sudo grep "custom-teams" /var/ossec/logs/integrations.log | tail -20
```

### Verify Alerts Being Processed

```bash
# Check Wazuh manager logs for integration execution
sudo grep "custom-teams-summary" /var/ossec/logs/ossec.log

# Check for any errors
sudo grep -i "error\|failed" /var/ossec/logs/integrations.log
```

### Test the Integration (Production v4.1)

```bash
# Test with a sample alert file
# First, get a real alert structure from your logs:
ALERT_FILE=$(sudo ls -t /var/ossec/logs/alerts/ | head -1)

# Or manually create a test alert:
cat > /tmp/test-alert.json << 'EOF'
{
  "timestamp": "2026-03-17T10:00:00",
  "rule": {
    "id": "100001",
    "level": 12,
    "description": "Test Alert"
  },
  "agent": {
    "name": "TEST-AGENT",
    "ip": "192.168.1.100"
  }
}
EOF

# Test the script
echo '${ALERT_FILE}' | sudo /var/ossec/integrations/custom-teams-summary.py "YOUR_WEBHOOK" 11 "custom-teams-summary"
```

### Expected Results

**Success:** Alert appears in Teams within 2-5 seconds

**Check for errors in logs:**
```bash
sudo tail -50 /var/ossec/logs/integrations.log
```

Successful output should show:
```
[INFO] custom-teams-summary: Alert received
[INFO] custom-teams-summary: Alert formatting...
[INFO] custom-teams-summary: Sending to Teams
[OK] Alert sent successfully
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
