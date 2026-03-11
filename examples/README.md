# Configuration Examples

This directory contains example configuration files and templates.

## Files

### ossec.conf.example
Complete `<integration>` block for Wazuh Manager configuration.

**Usage:**
```bash
# View example
cat examples/ossec.conf.example

# Copy integration block to your ossec.conf
sudo nano /var/ossec/etc/ossec.conf
# Paste the <integration> block

# Restart Wazuh
sudo systemctl restart wazuh-manager
```

**Includes:**
- Standard configuration (level 11)
- High sensitivity variant (level 9)
- Critical only variant (level 15)
- Multi-channel setup
- Rule-specific filtering

---

### power-automate-flow.json
Exportable Power Automate flow definition.

**Usage:**
1. Go to Power Automate → **My flows**
2. Click **Import** → **Import Package (.zip)**
3. Upload `power-automate-flow-export.zip`
4. Configure connections
5. Copy webhook URL
6. Update ossec.conf

**Includes:**
- HTTP trigger configuration
- Teams message posting action
- Error handling

---

### adaptive-card-template.json
Teams Adaptive Card JSON template.

**Usage:**
Customize the card design sent to Teams:

```json
{
  "type": "AdaptiveCard",
  "body": [
    {
      "type": "TextBlock",
      "text": "Custom Alert Title",
      "weight": "Bolder",
      "size": "Large"
    }
  ]
}
```

Edit `custom-teams-summary.py` and replace card template.

---

### test-alert.json
Sample alert JSON for testing.

**Usage:**
```bash
# Test integration with sample alert
cat examples/test-alert.json | \
sudo /var/ossec/integrations/custom-teams-summary.py \
  "YOUR_WEBHOOK_URL" \
  11 \
  "custom-teams-summary"
```

---

## Quick Start Examples

### Example 1: Basic Setup

```bash
# 1. Copy integration config
sudo nano /var/ossec/etc/ossec.conf
# Add <integration> block from ossec.conf.example

# 2. Set your webhook URL
sudo sed -i 's|YOUR_WEBHOOK_URL_HERE|https://your-actual-webhook.com|' /var/ossec/etc/ossec.conf

# 3. Restart
sudo systemctl restart wazuh-manager

# 4. Test
cat examples/test-alert.json | \
sudo /var/ossec/integrations/custom-teams-summary.py \
  "$(sudo grep -oP '(?<=<hook_url>).*(?=</hook_url>)' /var/ossec/etc/ossec.conf)" \
  11 \
  "custom-teams-summary"
```

---

### Example 2: Multi-Environment Setup

**Production Server (Critical Only):**
```xml
<integration>
  <name>custom-teams-summary</name>
  <hook_url>PROD_WEBHOOK_URL</hook_url>
  <level>15</level>
  <alert_format>json</alert_format>
</integration>
```

**Development Server (All Alerts):**
```xml
<integration>
  <name>custom-teams-summary</name>
  <hook_url>DEV_WEBHOOK_URL</hook_url>
  <level>9</level>
  <alert_format>json</alert_format>
</integration>
```

---

### Example 3: Custom Threshold Tuning

Edit `/var/ossec/integrations/custom-teams-summary.py`:

```python
# For high-traffic environment
MAX_ALERTS_BEFORE_SUMMARY = 10  # Instead of 3
SUMMARY_INTERVAL_HOURS = 6       # Instead of 24

# For low-traffic environment
MAX_ALERTS_BEFORE_SUMMARY = 2
SUMMARY_INTERVAL_HOURS = 48
```

Restart Wazuh after changes:
```bash
sudo systemctl restart wazuh-manager
```

---

### Example 4: Testing Specific Rules

Create custom test script:

```bash
#!/bin/bash
# test-kerberos-rules.sh

# Test only Kerberos rules (100001-100006)
for rule_id in 100001 100002 100003 100004 100005 100006; do
  echo "Testing rule $rule_id..."
  echo '{"timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%S+0000)'","rule":{"level":12,"description":"Kerberos Test","id":"'$rule_id'"},"agent":{"name":"Test"}}' | \
  sudo /var/ossec/integrations/custom-teams-summary.py "YOUR_WEBHOOK" 11 "custom-teams-summary"
  sleep 1
done
```

---

## Configuration Matrix

| Scenario | Level | MAX_ALERTS | INTERVAL | Expected Behavior |
|----------|-------|------------|----------|-------------------|
| Production - Low Traffic | 11 | 3 | 24h | ~5 summaries/day |
| Production - High Traffic | 13 | 5 | 12h | ~2-3 summaries/day |
| Development | 9 | 10 | 6h | ~15 summaries/day |
| Testing | 7 | 20 | 1h | ~24 summaries/day |
| Critical Only | 15 | N/A | N/A | Immediate send |

---

## Customization Guide

### Change Alert Card Colors

Edit `custom-teams-summary.py` and modify card builder:

```python
def build_summary_card(alerts, stats):
    card = {
        "type": "AdaptiveCard",
        "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
        "version": "1.3",
        "body": [
            {
                "type": "Container",
                "style": "emphasis",  # Change to: "good", "warning", "attention"
                "items": [
                    {
                        "type": "TextBlock",
                        "text": "WAZUH ALERT SUMMARY",
                        "weight": "Bolder",
                        "size": "Large",
                        "color": "Accent"  # Change to: "Default", "Dark", "Light", "Accent", "Good", "Warning", "Attention"
                    }
                ]
            }
        ]
    }
```

### Add Custom Fields

To include additional alert data:

```python
# In build_summary_card or build_immediate_alert function
{
    "type": "FactSet",
    "facts": [
        {"title": "Agent", "value": alert.get('agent', {}).get('name', 'N/A')},
        {"title": "Rule ID", "value": str(alert.get('rule', {}).get('id', 'N/A'))},
        {"title": "Level", "value": str(alert.get('rule', {}).get('level', 'N/A'))},
        # Add custom field:
        {"title": "Event ID", "value": alert.get('data', {}).get('win', {}).get('system', {}).get('eventID', 'N/A')},
        {"title": "Source IP", "value": alert.get('data', {}).get('srcip', 'N/A')}
    ]
}
```

### Filter Specific Event IDs

Add filtering in integration script:

```python
def should_process_alert(alert_json):
    # Only process specific Event IDs
    allowed_event_ids = ['4768', '4688', '4720', '1102']
    event_id = alert_json.get('data', {}).get('win', {}).get('system', {}).get('eventID', '')
    
    if event_id not in allowed_event_ids:
        print(f"[SKIP] Event ID {event_id} not in whitelist")
        return False
    
    return True
```

---

## Testing Matrix

Use these commands to test different scenarios:

### Test 1: Single Alert (Should Accumulate)
```bash
cat examples/test-alert.json | sudo /var/ossec/integrations/custom-teams-summary.py "WEBHOOK" 11 "custom-teams-summary"
# Expected: [INFO] Alert accumulated (1/3)
```

### Test 2: Three Alerts (Should Send Summary)
```bash
for i in {1..3}; do
  cat examples/test-alert.json | sudo /var/ossec/integrations/custom-teams-summary.py "WEBHOOK" 11 "custom-teams-summary"
  sleep 1
done
# Expected: [OK] Summary sent: 3 alerts
```

### Test 3: Critical Alert (Should Send Immediately)
```bash
sed 's/"level": 12/"level": 15/' examples/test-alert.json | \
sudo /var/ossec/integrations/custom-teams-summary.py "WEBHOOK" 11 "custom-teams-summary"
# Expected: [CRITICAL] Immediate alert sent
```

### Test 4: Below Threshold (Should Ignore)
```bash
sed 's/"level": 12/"level": 10/' examples/test-alert.json | \
sudo /var/ossec/integrations/custom-teams-summary.py "WEBHOOK" 11 "custom-teams-summary"
# Expected: [SKIP] Alert level below threshold
```

---

## Validation Checklist

Before deploying to production, verify:

- [ ] Webhook URL is correct and accessible
- [ ] Teams channel exists and bot can post
- [ ] Alert level threshold matches expectation
- [ ] Integration script has execute permissions
- [ ] ossec.conf syntax is valid (no XML errors)
- [ ] Wazuh Manager restarts without errors
- [ ] Test alerts arrive in Teams as expected
- [ ] Cache directory is writable
- [ ] No SSL certificate errors in logs

---

## Troubleshooting Examples

### Debug Mode

Enable verbose logging:

```bash
# Add debug output to integration script
sudo nano /var/ossec/integrations/custom-teams-summary.py

# Add at top of main function:
import sys
sys.stderr.write(f"[DEBUG] Received args: {sys.argv}\n")
sys.stderr.write(f"[DEBUG] Alert JSON: {alert_json_str}\n")

# Monitor debug output:
sudo tail -f /var/ossec/logs/integrations.log | grep DEBUG
```

### Test Webhook Directly

```bash
curl -X POST "YOUR_WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d @examples/test-alert.json

# Should return HTTP 200 OK
```

### Verify Pickle Cache

```bash
sudo python3 << 'EOF'
import pickle
cache = pickle.load(open('/var/ossec/logs/teams_alerts_cache.pkl', 'rb'))
print(f"Alerts: {len(cache['alerts'])}")
print(f"Last summary: {cache['last_summary_time']}")
print(f"Summary count: {cache['summary_count']}")
EOF
```

---

## Additional Examples

More examples available in repository:

- **Windows Agent Configuration:** See `docs/WINDOWS_AGENT.md`
- **Custom Rule Development:** See `docs/CUSTOM_RULES.md`
- **Performance Tuning:** See `docs/PERFORMANCE.md`

---

## Contributing Examples

To add new examples:

1. Create file in `examples/` directory
2. Add documentation to this README
3. Test example on clean installation
4. Submit pull request

**Example template:**
```
### Example Name

**Purpose:** Brief description

**Usage:**
```bash
# Commands to run
```

**Expected Output:** What should happen

**Notes:** Any caveats or requirements
```

---

**All examples are under [MIT License](../LICENSE)**
