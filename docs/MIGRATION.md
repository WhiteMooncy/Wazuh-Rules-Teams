# Migration Guide

Complete guide for migrating Wazuh custom rules and Teams integration from one server to another.

## Overview

This guide covers migrating from:
- **Old Server:** 10.0.0.10 (or any existing Wazuh installation)
- **New Server:** 10.0.0.20 (or your target server)

**Migration Components:**
- 101 custom Wazuh rules (89 Windows + 5 Overrides + 7 Linux)
- Teams integration with summary accumulation
- Agent configurations
- Alert cache (optional)

**Estimated Time:** 30-45 minutes

---

## Prerequisites

### Before Starting

- [ ] **New server has Wazuh Manager installed**
  ```bash
  # Verify Wazuh version on new server
  sudo /var/ossec/bin/wazuh-control info
  ```

- [ ] **SSH access to both servers** with root or sudo privileges

- [ ] **Network connectivity** between old and new servers

- [ ] **Backup of old server** configuration
  ```bash
  sudo tar czf /root/wazuh-backup-$(date +%Y%m%d).tar.gz \
    /var/ossec/etc/ossec.conf \
    /var/ossec/etc/rules/*.xml \
    /var/ossec/integrations/custom-teams-summary.py
  ```

- [ ] **Power Automate webhook URL** ready (same webhook can be used, or create new)

- [ ] **Wazuh versions match** (or are compatible)

- [ ] **Notification sent** to SOC team about migration

---

## Migration Steps

### Step 1: Verify Old Server Configuration

Connect to old server:

```bash
ssh root@10.0.0.10
```

#### 1.1 List Custom Rules

```bash
sudo ls -lh /var/ossec/etc/rules/ | grep -E "(custom|local)"
# Should show:
# - custom_windows_security_rules.xml
# - local_rules_override.xml
```

#### 1.2 Verify Integration Script

```bash
sudo ls -lh /var/ossec/integrations/custom-teams-summary.py
# Should show file exists (~29KB)
```

#### 1.3 Extract Webhook URL from ossec.conf

```bash
sudo grep -A 5 "custom-teams-summary" /var/ossec/etc/ossec.conf
# Note the <hook_url> value
```

#### 1.4 Check Current Alert Statistics

```bash
# View cache status
sudo python3 << 'EOF'
import pickle, os
cache_file = '/var/ossec/logs/teams_alerts_cache.pkl'
if os.path.exists(cache_file):
    data = pickle.load(open(cache_file, 'rb'))
    print(f"Alerts in cache: {len(data.get('alerts', []))}")
    print(f"Summaries sent: {data.get('summary_count', 0)}")
else:
    print("No cache file found")
EOF
```

---

### Step 2: Prepare New Server

Connect to new server:

```bash
ssh root@10.0.0.20
```

#### 2.1 Verify Wazuh Installation

```bash
sudo systemctl status wazuh-manager
# Should show: active (running)

sudo /var/ossec/bin/wazuh-control info
# Verify version matches old server
```

#### 2.2 Create Backup Directories

```bash
sudo mkdir -p /root/backups
sudo mkdir -p /root/migration-temp
```

#### 2.3 Backup Default Configuration

```bash
# Backup ossec.conf before modifications
sudo cp /var/ossec/etc/ossec.conf \
       /root/backups/ossec.conf.pre-migration-$(date +%Y%m%d-%H%M%S)

# Backup existing rules (if any)
sudo tar czf /root/backups/rules-backup-$(date +%Y%m%d).tar.gz \
  /var/ossec/etc/rules/ 2>/dev/null || true
```

---

### Step 3: Transfer Files from Old to New Server

#### Method A: Direct SCP Transfer (Recommended)

From your local machine or jump host:

```bash
# Transfer rules
scp root@10.0.0.10:/var/ossec/etc/rules/custom_windows_security_rules.xml \
    root@10.0.0.20:/root/migration-temp/

scp root@10.0.0.10:/var/ossec/etc/rules/local_rules_override.xml \
    root@10.0.0.20:/root/migration-temp/

# Transfer integration script
scp root@10.0.0.10:/var/ossec/integrations/custom-teams-summary.py \
    root@10.0.0.20:/root/migration-temp/

# Transfer cache (optional, to preserve alert history)
scp root@10.0.0.10:/var/ossec/logs/teams_alerts_cache.pkl \
    root@10.0.0.20:/root/migration-temp/ 2>/dev/null || echo "No cache to transfer"
```

#### Method B: Via GitHub (If Using Version Control)

On old server:
```bash
cd /opt/wazuh-custom-rules-teams
git add -A
git commit -m "Pre-migration snapshot"
git push origin main
```

On new server:
```bash
cd /opt
git clone https://github.com/YOUR_USERNAME/wazuh-custom-rules-teams.git
# Files are now ready in /opt/wazuh-custom-rules-teams/
```

#### Method C: Manual Copy via Intermediate Server

If no direct connectivity:

On old server:
```bash
sudo tar czf /tmp/wazuh-migration.tar.gz \
  /var/ossec/etc/rules/custom_windows_security_rules.xml \
  /var/ossec/etc/rules/local_rules_override.xml \
  /var/ossec/integrations/custom-teams-summary.py

# Transfer this file to new server via USB, shared storage, or intermediate jump host
```

On new server:
```bash
sudo tar xzf /tmp/wazuh-migration.tar.gz -C /
```

---

### Step 4: Install Rules on New Server

On new server (10.0.0.20):

#### 4.1 Copy Rules to Wazuh Directory

```bash
sudo cp /root/migration-temp/custom_windows_security_rules.xml \
       /var/ossec/etc/rules/

sudo cp /root/migration-temp/local_rules_override.xml \
       /var/ossec/etc/rules/
```

#### 4.2 Set Permissions

```bash
sudo chown root:wazuh /var/ossec/etc/rules/custom_windows_security_rules.xml
sudo chown root:wazuh /var/ossec/etc/rules/local_rules_override.xml
sudo chmod 640 /var/ossec/etc/rules/custom_windows_security_rules.xml
sudo chmod 640 /var/ossec/etc/rules/local_rules_override.xml
```

#### 4.3 Verify Rules Copied

```bash
sudo grep -c "rule id=\"100" /var/ossec/etc/rules/custom_windows_security_rules.xml
# Should output: 62

sudo grep -c "rule id" /var/ossec/etc/rules/local_rules_override.xml
# Should output: 5
```

---

### Step 5: Install Integration Script

#### 5.1 Copy Script

```bash
sudo cp /root/migration-temp/custom-teams-summary.py \
       /var/ossec/integrations/
```

#### 5.2 Set Permissions

```bash
sudo chown root:wazuh /var/ossec/integrations/custom-teams-summary.py
sudo chmod 750 /var/ossec/integrations/custom-teams-summary.py
```

#### 5.3 Verify Script Syntax

```bash
python3 -m py_compile /var/ossec/integrations/custom-teams-summary.py
echo $?
# Should output: 0 (no syntax errors)
```

---

### Step 6: Configure ossec.conf on New Server

#### 6.1 Edit Configuration

```bash
sudo nano /var/ossec/etc/ossec.conf
```

#### 6.2 Add Integration Block

Add before closing `</ossec_config>` tag:

```xml
<integration>
  <name>custom-teams-summary</name>
  <hook_url>YOUR_POWER_AUTOMATE_WEBHOOK_URL</hook_url>
  <level>11</level>
  <alert_format>json</alert_format>
  <options>{"verify_ssl": false}</options>
</integration>
```

**Use the same webhook URL from old server**, or create a new one in Power Automate.

#### 6.3 Validate Configuration

```bash
# Check XML syntax
sudo /var/ossec/bin/wazuh-control info | grep -E "(error|ERROR)"
# Should show no errors
```

---

### Step 7: Migrate Alert Cache (Optional)

If you want to preserve alert accumulation state:

```bash
# Copy cache file
sudo cp /root/migration-temp/teams_alerts_cache.pkl \
       /var/ossec/logs/

# Set permissions
sudo chown root:wazuh /var/ossec/logs/teams_alerts_cache.pkl
sudo chmod 660 /var/ossec/logs/teams_alerts_cache.pkl
```

**Note:** Migrating cache is optional. If omitted, the new server will start with a fresh cache.

---

### Step 8: Restart Wazuh Manager on New Server

```bash
sudo systemctl restart wazuh-manager

# Verify service started successfully
sudo systemctl status wazuh-manager
# Should show: active (running)

# Check for errors
sudo tail -50 /var/ossec/logs/ossec.log | grep -iE "(error|warn)"
```

---

### Step 9: Test Integration

#### 9.1 Send Test Alert

```bash
echo '{"timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%S+0000)'","rule":{"level":12,"description":"Migration Test Alert","id":"100001"},"agent":{"id":"000","name":"Migration-Test"},"location":"test","data":{"win":{"system":{"eventID":"4768","computer":"TestServer"}}}}' | \
sudo /var/ossec/integrations/custom-teams-summary.py \
  "$(sudo grep -oP '(?<=<hook_url>).*(?=</hook_url>)' /var/ossec/etc/ossec.conf | grep custom-teams -A 1 | tail -1)" \
  11 \
  "custom-teams-summary"

# Expected output: [INFO] Alert accumulated (1/3). Not sending yet.
```

#### 9.2 Run Comprehensive Test

```bash
# Clone scripts if not already done
cd /opt
git clone https://github.com/YOUR_USERNAME/wazuh-custom-rules-teams.git
cd wazuh-custom-rules-teams/scripts

# Run test (replace webhook URL)
sudo bash test_alerts.sh
```

#### 9.3 Verify Teams Reception

- Check your Teams "Wazuh-Alerts" channel
- Should receive 2 immediate critical alerts
- Should receive 1 summary message after 3rd alert

---

### Step 10: Update Agent Registrations

#### 10.1 List Agents on Old Server

On old server (10.0.0.10):
```bash
sudo /var/ossec/bin/agent_control -l
# Note all agent IDs and names
```

#### 10.2 Option A: Re-register Agents (Recommended)

On each Windows agent:

```powershell
# Stop agent
Stop-Service -Name WazuhSvc

# Edit ossec.conf
notepad "C:\Program Files (x86)\ossec-agent\ossec.conf"

# Change <address> from old IP to new IP:
# <address>10.0.0.20</address>

# Remove agent key
Remove-Item "C:\Program Files (x86)\ossec-agent\client.keys"

# Restart agent (will auto-register if configured)
Start-Service -Name WazuhSvc
```

On new server, verify agent connected:
```bash
sudo /var/ossec/bin/agent_control -l
```

#### 10.2 Option B: Export/Import Agent Keys

**⚠️ Advanced method** - use if you want to preserve agent IDs.

On old server:
```bash
# Export all agent keys
sudo cat /var/ossec/etc/client.keys > /root/client.keys.backup
```

Transfer to new server, then:
```bash
# Import keys
sudo cp /root/client.keys.backup /var/ossec/etc/client.keys
sudo chown root:wazuh /var/ossec/etc/client.keys
sudo chmod 640 /var/ossec/etc/client.keys

# Restart manager to load keys
sudo systemctl restart wazuh-manager
```

On each agent, update `<address>` in ossec.conf and restart.

---

### Step 11: Verification Checklist

- [ ] **Rules loaded:**
  ```bash
  sudo grep -c "rule id=\"100" /var/ossec/etc/rules/*.xml
  # Should show: 67
  ```

- [ ] **Integration script executable:**
  ```bash
  sudo test -x /var/ossec/integrations/custom-teams-summary.py && echo "OK" || echo "FAIL"
  ```

- [ ] **ossec.conf has integration block:**
  ```bash
  sudo grep -q "custom-teams-summary" /var/ossec/etc/ossec.conf && echo "OK" || echo "FAIL"
  ```

- [ ] **Wazuh Manager running:**
  ```bash
  sudo systemctl is-active wazuh-manager
  # Should output: active
  ```

- [ ] **Agents connected:**
  ```bash
  sudo /var/ossec/bin/agent_control -l | grep Active | wc -l
  # Should match number of expected agents
  ```

- [ ] **Test alerts reaching Teams:**
  ```bash
  sudo bash /opt/wazuh-custom-rules-teams/scripts/test_alerts.sh
  # Check Teams for alerts
  ```

- [ ] **No errors in logs:**
  ```bash
  sudo tail -100 /var/ossec/logs/ossec.log | grep -iE "error|fail"
  ```

---

### Step 12: Decommission Old Server (After Validation)

**Wait 24-48 hours** after migration to ensure stability before decommissioning old server.

#### Validation Period Checklist

- [ ] Monitor new server for errors:
  ```bash
  sudo tail -f /var/ossec/logs/ossec.log
  ```

- [ ] Verify all agents are reporting:
  ```bash
  watch -n 10 'sudo /var/ossec/bin/agent_control -l'
  ```

- [ ] Confirm Teams alerts arriving normally

- [ ] Check alert accuracy (no missing or duplicated alerts)

#### Decommission Steps

Once validated:

```bash
# On old server (10.0.0.10)
sudo systemctl stop wazuh-manager
sudo systemctl disable wazuh-manager

# Create final backup
sudo tar czf /root/wazuh-final-backup-$(date +%Y%m%d).tar.gz \
  /var/ossec/etc \
  /var/ossec/logs/alerts \
  /var/ossec/logs/archives

# Store backup securely
scp /root/wazuh-final-backup-*.tar.gz backup-server:/backups/wazuh/
```

Keep old server offline but preserved for 30 days in case rollback is needed.

---

## Rollback Procedure

If migration fails and you need to revert to old server:

### Quick Rollback

1. **Stop new server:**
   ```bash
   ssh root@10.0.0.20
   sudo systemctl stop wazuh-manager
   ```

2. **Restart old server:**
   ```bash
   ssh root@10.0.0.10
   sudo systemctl start wazuh-manager
   sudo systemctl status wazuh-manager
   ```

3. **Update agents (if they were changed):**
   - Change `<address>` back to `10.0.0.10` in agent ossec.conf
   - Restart agents

4. **Verify old server working:**
   ```bash
   sudo bash /opt/wazuh-custom-rules-teams/scripts/test_alerts.sh
   ```

---

## Troubleshooting Migration Issues

### Issue: Rules Not Loading

**Symptom:** `sudo grep "rule id=\"100" /var/ossec/etc/rules/*.xml` returns 0

**Solution:**
```bash
# Verify files were copied
sudo ls -lh /var/ossec/etc/rules/ | grep -E "(custom|local)"

# Re-copy files
sudo cp /root/migration-temp/*.xml /var/ossec/etc/rules/
sudo chown root:wazuh /var/ossec/etc/rules/*.xml
sudo systemctl restart wazuh-manager
```

### Issue: Integration Not Sending to Teams

**Symptom:** Test alerts not arriving in Teams

**Diagnosis:**
```bash
sudo tail -50 /var/ossec/logs/integrations.log | grep custom-teams
```

**Common Causes:**
1. **Wrong webhook URL:** Verify in ossec.conf
   ```bash
   sudo grep hook_url /var/ossec/etc/ossec.conf
   ```

2. **Script not executable:**
   ```bash
   sudo chmod 750 /var/ossec/integrations/custom-teams-summary.py
   ```

3. **Python errors:**
   ```bash
   python3 /var/ossec/integrations/custom-teams-summary.py --help
   ```

### Issue: Agents Not Connecting

**Symptom:** `agent_control -l` shows agents as disconnected

**Solution:**

1. **Check agent logs** (on Windows agent):
   ```
   C:\Program Files (x86)\ossec-agent\ossec.log
   ```
   Look for connection errors to new server IP.

2. **Verify firewall** on new server:
   ```bash
   sudo firewall-cmd --list-ports | grep 1514
   # Should show: 1514/tcp
   
   # If not:
   sudo firewall-cmd --permanent --add-port=1514/tcp
   sudo firewall-cmd --reload
   ```

3. **Check agent key** (on agent):
   ```powershell
   Get-Content "C:\Program Files (x86)\ossec-agent\client.keys"
   # Should not be empty
   ```

### Issue: Cache File Errors

**Symptom:** Logs show pickle errors

**Solution:**
```bash
# Delete corrupted cache
sudo rm /var/ossec/logs/teams_alerts_cache.pkl

# Will be recreated automatically
```

### Issue: Performance Degradation

**Symptom:** New server slower than old server

**Check:**
```bash
# CPU usage
top -n 1 -b | grep wazuh

# Memory
free -h

# Disk I/O
iostat -x 1 5
```

**Solutions:**
- Increase RAM allocation
- Use faster disks (SSD)
- Adjust Wazuh analysis threads in ossec.conf

---

## Post-Migration Optimization

### Update Documentation

```bash
echo "Migrated to 10.0.0.20 on $(date)" >> /root/wazuh_changelog.txt
```

### Update Monitoring/Dashboards

If using external monitoring (Nagios, Zabbix, etc.), update server IP.

### Update DNS (if applicable)

```bash
# Update A record wazuh.yourdomain.com to point to 10.0.0.20
```

### Review Performance

After 7 days, compare metrics:

```bash
# Old server metrics (from backups/logs)
# vs
# New server metrics
sudo /var/ossec/bin/wazuh-control info
```

---

## Migration Checklist Summary

| Task | Old Server | New Server | Status |
|------|------------|------------|--------|
| Verify Wazuh version | ✓ | ✓ | ☐ |
| Backup configuration | ✓ | ✓ | ☐ |
| Copy rules | ✓ | ✓ | ☐ |
| Copy integration script | ✓ | ✓ | ☐ |
| Configure ossec.conf | - | ✓ | ☐ |
| Set permissions | - | ✓ | ☐ |
| Restart Wazuh | - | ✓ | ☐ |
| Test alerts | - | ✓ | ☐ |
| Update agents | ✓ | ✓ | ☐ |
| Verify connectivity | - | ✓ | ☐ |
| Monitor 24-48h | - | ✓ | ☐ |
| Decommission old | ✓ | - | ☐ |

---

## Additional Resources

- [Installation Guide](INSTALLATION.md) - Full installation from scratch
- [Troubleshooting Guide](TROUBLESHOOTING.md) - Detailed problem resolution
- [Wazuh Migration Docs](https://documentation.wazuh.com/current/migration-guide/index.html)

---

**Migration complete!** Your Wazuh installation with custom rules is now running on the new server.
