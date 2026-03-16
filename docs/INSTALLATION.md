# Installation Guide

Complete step-by-step guide to install Wazuh custom rules and Teams integration from scratch.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Installation](#quick-installation)
3. [Detailed Installation](#detailed-installation)
4. [Power Automate Setup](#power-automate-setup)
5. [Verification](#verification)
6. [Post-Installation](#post-installation)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Wazuh Manager Requirements

- **OS:** Linux (RHEL/CentOS 7/8, Ubuntu 18.04+, Debian 9+)
- **Wazuh Version:** 4.x (tested on 4.3+)
- **RAM:** Minimum 2 GB, recommended 4 GB+
- **Disk Space:** 500 MB free in `/var/ossec/`
- **Python:** 3.6+ with standard library
- **Network:** Outbound HTTPS (443) access to Power Automate

### Required Permissions

- `root` or `sudo` access to Wazuh Manager
- Ability to restart `wazuh-manager` service
- Write permissions in `/var/ossec/etc/rules/` and `/var/ossec/integrations/`

### Microsoft Teams Requirements

- Microsoft 365 account
- Power Automate license (included in most M365 plans)
- Teams channel where alerts will be posted
- Permission to create Power Automate flows

---

## Quick Installation

For experienced administrators who want to get up and running fast:

```bash
# 1. Clone repository (reemplaza YOUR_USERNAME con tu usuario de GitHub)
cd /opt
git clone https://github.com/YOUR_USERNAME/wazuh-custom-rules-teams.git
cd wazuh-custom-rules-teams

# Ejemplo:
# git clone https://github.com/mateovillablanca/wazuh-custom-rules-teams.git

# 2. Copy rules
sudo cp rules/*.xml /var/ossec/etc/rules/
sudo chown root:wazuh /var/ossec/etc/rules/custom_windows_security_rules.xml
sudo chown root:wazuh /var/ossec/etc/rules/local_rules_override.xml

# 3. Copy integration script
sudo cp integrations/custom-teams-summary.py /var/ossec/integrations/
sudo chown root:wazuh /var/ossec/integrations/custom-teams-summary.py
sudo chmod 750 /var/ossec/integrations/custom-teams-summary.py

# 4. Configure ossec.conf (replace YOUR_WEBHOOK_URL)
sudo nano /var/ossec/etc/ossec.conf
# Add integration block (see section below)

# 5. Restart Wazuh
sudo systemctl restart wazuh-manager

# 6. Test
sudo bash scripts/test_alerts.sh
```

**Next:** Configure webhook URL in ossec.conf (see [Power Automate Setup](#power-automate-setup))

---

## Detailed Installation

### Step 1: Download/Clone Repository

#### Option A: Git Clone (recommended)

```bash
cd /opt
sudo git clone https://github.com/YOUR_USERNAME/wazuh-custom-rules-teams.git
cd wazuh-custom-rules-teams
```

#### Option B: Download ZIP

```bash
cd /opt
sudo curl -LO https://github.com/YOUR_USERNAME/wazuh-custom-rules-teams/archive/main.zip
sudo unzip main.zip
sudo mv wazuh-custom-rules-teams-main wazuh-custom-rules-teams
cd wazuh-custom-rules-teams
```

#### Option C: Manual Transfer

If no internet access on Wazuh server:

```bash
# On local machine with internet:
git clone https://github.com/YOUR_USERNAME/wazuh-custom-rules-teams.git
tar czf wazuh-custom-rules-teams.tar.gz wazuh-custom-rules-teams/

# Transfer to Wazuh server:
scp wazuh-custom-rules-teams.tar.gz root@YOUR_WAZUH_IP:/opt/

# On Wazuh server:
cd /opt
sudo tar xzf wazuh-custom-rules-teams.tar.gz
cd wazuh-custom-rules-teams
```

---

### Step 2: Backup Existing Configuration

```bash
# Backup current ossec.conf
sudo cp /var/ossec/etc/ossec.conf /var/ossec/etc/ossec.conf.backup-$(date +%Y%m%d-%H%M%S)

# Backup current rules (if any exist with same names)
if [ -f /var/ossec/etc/rules/custom_windows_security_rules.xml ]; then
  sudo cp /var/ossec/etc/rules/custom_windows_security_rules.xml \
         /root/backups/custom_windows_security_rules.xml.old
fi
```

---

### Step 3: Install Rules

#### 3.1 Copy Rule Files

```bash
sudo cp rules/custom_windows_security_rules.xml /var/ossec/etc/rules/
sudo cp rules/local_rules_override.xml /var/ossec/etc/rules/
```

#### 3.2 Set Permissions

```bash
sudo chown root:wazuh /var/ossec/etc/rules/custom_windows_security_rules.xml
sudo chown root:wazuh /var/ossec/etc/rules/local_rules_override.xml
sudo chmod 640 /var/ossec/etc/rules/custom_windows_security_rules.xml
sudo chmod 640 /var/ossec/etc/rules/local_rules_override.xml
```

#### 3.3 Verify XML Syntax

```bash
# Check for syntax errors
sudo /var/ossec/bin/wazuh-logtest < /dev/null

# Verify rules were loaded
sudo grep -c "rule id=\"100" /var/ossec/etc/rules/custom_windows_security_rules.xml
# Should output: 89

sudo grep -c "rule id" /var/ossec/etc/rules/local_rules_override.xml
# Should output: 5
```

---

### Step 4: Install Integration Script

#### 4.1 Copy Script

```bash
sudo cp integrations/custom-teams-summary.py /var/ossec/integrations/
```

#### 4.2 Set Ownership and Permissions

```bash
sudo chown root:wazuh /var/ossec/integrations/custom-teams-summary.py
sudo chmod 750 /var/ossec/integrations/custom-teams-summary.py
```

#### 4.3 Verify Python is Available

```bash
python3 --version
# Should output: Python 3.x.x

# Test script syntax
python3 -m py_compile /var/ossec/integrations/custom-teams-summary.py
echo $?
# Should output: 0 (no errors)
```

---

### Step 5: Configure Power Automate Webhook

See detailed section: [Power Automate Setup](#power-automate-setup)

You'll need to:
1. Create a Power Automate flow
2. Add HTTP trigger
3. Copy webhook URL
4. Configure Teams message posting

---

### Step 6: Configure ossec.conf

#### 6.1 Open Configuration File

```bash
sudo nano /var/ossec/etc/ossec.conf
```

#### 6.2 Add Integration Block

Add this block anywhere before the closing `</ossec_config>` tag (recommended: near other `<integration>` blocks):

```xml
<integration>
  <name>custom-teams-summary</name>
  <hook_url>YOUR_POWER_AUTOMATE_WEBHOOK_URL_HERE</hook_url>
  <level>11</level>
  <alert_format>json</alert_format>
  <options>{"verify_ssl": false}</options>
</integration>
```

**Configuration Explanation:**

| Tag | Value | Description |
|-----|-------|-------------|
| `<name>` | `custom-teams-summary` | Must match integration script filename |
| `<hook_url>` | Your webhook URL | Power Automate HTTP POST URL |
| `<level>` | `11` | Minimum alert level to process (recommended: 11-13) |
| `<alert_format>` | `json` | Send alerts as JSON (required) |
| `<options>` | `{"verify_ssl": false}` | Disable SSL verification for internal webhooks |

#### 6.3 Save and Validate

```bash
# Save file (Ctrl+X, Y, Enter in nano)

# Validate ossec.conf syntax
sudo /var/ossec/bin/wazuh-control info
# Should not show XML parse errors
```

---

### Step 7: Restart Wazuh Manager

```bash
sudo systemctl restart wazuh-manager

# Verify service started successfully
sudo systemctl status wazuh-manager
# Should show: active (running)

# Check for errors in log
sudo tail -50 /var/ossec/logs/ossec.log | grep -i error
# Should show no critical errors
```

---

### Step 8: Test Installation

#### 8.1 Quick Test with Single Alert

```bash
# Generate a test alert
echo '{"timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%S+0000)'","rule":{"level":12,"description":"Test Alert - Installation Verification","id":"100001"},"agent":{"id":"000","name":"Test-Agent"},"location":"test","data":{"win":{"system":{"eventID":"4768","computer":"TestServer"}}}}' | \
sudo /var/ossec/integrations/custom-teams-summary.py \
  "$(sudo grep hook_url /var/ossec/etc/ossec.conf | grep -oP '(?<=<hook_url>).*(?=</hook_url>)')" \
  11 \
  "custom-teams-summary"

# Expected output: [INFO] Alert accumulated (1/3). Not sending yet.
```

#### 8.2 Comprehensive Test

```bash
cd /opt/wazuh-custom-rules-teams/scripts
sudo bash test_alerts.sh

# Expected results:
# - Script sends 17 test alerts
# - 2 critical alerts arrive immediately in Teams (Rules 100036, 100101)
# - 1 summary message with remaining 15 alerts
```

#### 8.3 Verify Cache Creation

```bash
ls -lh /var/ossec/logs/teams_alerts_cache.pkl
# Should exist after first alert

# View cache contents
sudo python3 -c "import pickle; print(pickle.load(open('/var/ossec/logs/teams_alerts_cache.pkl','rb')))"
```

---

## Power Automate Setup

### Create the Flow

1. **Go to Power Automate:**
   - Visit https://make.powerautomate.com
   - Sign in with your Microsoft 365 account

2. **Create New Flow:**
   - Click **Create** → **Instant cloud flow**
   - Name it: "Wazuh Alerts to Teams"
   - Choose trigger: **When an HTTP request is received**
   - Click **Create**

3. **Configure HTTP Trigger:**
   - The trigger will show **HTTP POST URL** - Copy this (you'll need it for ossec.conf)
   - Set **Method:** POST
   - **Request Body JSON Schema:** (paste this)

   ```json
   {
     "type": "object",
     "properties": {
       "type": {
         "type": "string"
       },
       "attachments": {
         "type": "array",
         "items": {
           "type": "object",
           "properties": {
             "contentType": {
               "type": "string"
             },
             "content": {
               "type": "object"
             }
           }
         }
       }
     }
   }
   ```

4. **Add Teams Action:**
   - Click **+ New step**
   - Search for "Teams"
   - Select **Post adaptive card in a chat or channel**
   - Configure:
     - **Post as:** Flow bot
     - **Post in:** Channel
     - **Team:** Select your Teams workspace
     - **Channel:** Select channel (e.g., "Wazuh-Alerts")
     - **Adaptive Card:** 
       ```
       @{body('When_an_HTTP_request_is_received')['attachments'][0]['content']}
       ```

5. **Save Flow:**
   - Click **Save** at bottom
   - Copy the **HTTP POST URL** from the trigger (if you didn't already)

### Configure Channel Type

**IMPORTANT:** Teams channel must be set to "Conversaciones" mode, not "Publicaciones".

To change:
1. Open Teams → Your channel
2. Click **⋯** (More options) next to channel name
3. Select **Manage channel**
4. Under **Channel type**, ensure it's **Standard** (Conversaciones)
5. If it shows **Announcement** (Publicaciones), change it back

**Why this matters:** Power Automate webhooks become invalid when channel type changes.

---

## Verification

### Check Rules are Loaded

```bash
sudo grep "rule id=\"100" /var/ossec/etc/rules/*.xml | wc -l
# Should show: 101 (89 custom + 5 override + 7 linux)
```

### Check Integration is Active

```bash
sudo grep "custom-teams-summary" /var/ossec/etc/ossec.conf
# Should show your integration block

sudo ls -lh /var/ossec/integrations/custom-teams-summary.py
# Should show file exists with proper permissions
```

### Monitor Real-Time Alerts

```bash
# Watch for alerts processing
sudo tail -f /var/ossec/logs/alerts/alerts.json

# Watch integration execution logs
sudo tail -f /var/ossec/logs/integrations.log | grep custom-teams
```

### Verify Teams Reception

1. Open Teams → Your Wazuh channel
2. Send test alert (see Step 8.1 above)
3. After 3 test alerts, you should see summary message

---

## Post-Installation

### Adjust Alert Threshold

Default level is 11 (high sensitivity). To reduce alert volume:

```bash
sudo nano /var/ossec/etc/ossec.conf
# Change <level>11</level> to <level>13</level>

sudo systemctl restart wazuh-manager
```

**Recommended levels:**
- **Level 11:** ~40-50 alerts/day → 5-8 summaries/day (80% reduction)
- **Level 13:** ~10-15 alerts/day → 1-3 summaries/day (95% reduction)
- **Level 15:** ~2-5 alerts/day → all immediate (99% reduction)

### Tune Summary Thresholds

Edit `/var/ossec/integrations/custom-teams-summary.py`:

```python
MAX_ALERTS_BEFORE_SUMMARY = 3   # Send summary after this many alerts
SUMMARY_INTERVAL_HOURS = 24      # Or after this many hours
CRITICAL_LEVEL = 15              # Alerts at this level bypass accumulation
```

After changes:
```bash
sudo systemctl restart wazuh-manager
```

### Schedule Regular Tests

Add cron job to test integration weekly:

```bash
sudo crontab -e

# Add this line:
0 3 * * 1 /opt/wazuh-custom-rules-teams/scripts/test_alerts.sh >> /var/log/wazuh_test.log 2>&1
```

### Monitor Cache Size

Create script to alert if cache grows too large:

```bash
#!/bin/bash
# /usr/local/bin/check_wazuh_cache.sh

CACHE_FILE="/var/ossec/logs/teams_alerts_cache.pkl"
MAX_SIZE_MB=10

if [ -f "$CACHE_FILE" ]; then
  SIZE_MB=$(du -m "$CACHE_FILE" | cut -f1)
  if [ "$SIZE_MB" -gt "$MAX_SIZE_MB"]; then
    echo "[WARNING] Wazuh Teams cache exceeds ${MAX_SIZE_MB}MB: ${SIZE_MB}MB"
    # Optionally clear old alerts or send notification
  fi
fi
```

### Document Customizations

Keep a changelog of which settings you modified:

```bash
echo "$(date): Installed Wazuh Teams integration v1.0" >> /root/wazuh_changes.log
echo "$(date): Set alert level to 11" >> /root/wazuh_changes.log
```

---

## Troubleshooting

### Integration Script Not Executing

**Symptom:** No alerts arriving, no logs in integrations.log

**Check:**
```bash
# Verify script is executable
ls -lh /var/ossec/integrations/custom-teams-summary.py
# Should show: -rwxr-x--- (750)

# If not:
sudo chmod 750 /var/ossec/integrations/custom-teams-summary.py
```

### HTTP 404 Errors

**Symptom:** Logs show `HTTPError: 404 Not Found`

**Solution:**
1. Regenerate webhook in Power Automate
2. Update hook_url in ossec.conf
3. Restart wazuh-manager

### Rules Not Triggering

**Symptom:** Test alerts sent, but rules don't match

**Check:**
```bash
# Verify rule depends on parent rule 60103
sudo grep -A 5 "rule id=\"60103\"" /var/ossec/etc/rules/*.xml

# Test with wazuh-logtest
sudo /var/ossec/bin/wazuh-logtest
# Paste sample alert and check rule matching
```

### Python Import Errors

**Symptom:** `ModuleNotFoundError` in logs

**Solution:**
```bash
# Verify Python 3 is default
sudo alternatives --set python /usr/bin/python3

# Or add shebang to script:
sudo sed -i '1i #!/usr/bin/python3' /var/ossec/integrations/custom-teams-summary.py
```

### For more troubleshooting, see [docs/TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

## Next Steps

- **Configure Windows agents**: See [Windows Agent Setup Guide](WINDOWS_AGENT.md)
- **Migrate to another server**: See [Migration Guide](MIGRATION.md)
- **Customize rules**: See [Rules Reference](RULES_REFERENCE.md)
- **Review all 101 rules**: See [Complete Rule Documentation](RULES_REFERENCE.md)

---

## Support

- **GitHub Issues**: https://github.com/YOUR_USERNAME/wazuh-custom-rules-teams/issues
- **Wazuh Documentation**: https://documentation.wazuh.com
- **Power Automate Help**: https://learn.microsoft.com/en-us/power-automate/

---

**Installation complete!** You now have 101 custom Wazuh rules with intelligent Teams integration.
