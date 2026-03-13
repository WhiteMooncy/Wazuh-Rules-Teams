# Testing and Utility Scripts

This directory contains scripts for testing alert rules, simulating attacks, and managing the Wazuh integration.

> ⚠️ **Note:** Sensitive files (e.g., INSTRUCCIONES_ATAQUE_10.27.20.183.md) with internal IPs have been moved to `/internal/` folder for security. 
> These scripts in `/scripts/` have been sanitized with placeholder IPs (e.g., `192.168.X.X`).

## Testing Scripts

### validate_rules.py

Validates the canonical XML ruleset before deployment.

**Purpose:**
- Count rules per XML file.
- Detect duplicate rule IDs.
- Detect overlaps involving `local_rules_override.xml`.

**Usage:**

```bash
python3 validate_rules.py
```

**Expected behavior:**
- Exit code `0` when no duplicate IDs or deprecated overlaps are found.
- Exit code `1` when duplicate IDs or deprecated overlaps exist.

Run this before copying rule files to `/var/ossec/etc/rules/`.

---

### test_brute_force_attack.sh ⭐ NEW
Simulates brute force attacks to test frequency-based correlation rules.

**Purpose:** Test detection of multiple login attempts with non-nominal accounts (Rules 200004/200005).

**Usage:**
```bash
# Basic test (6 SSH login attempts with 'admin') - LOCAL SIMULATION
sudo bash test_brute_force_attack.sh

# Custom test (10 attempts, 1 second interval)
sudo bash test_brute_force_attack.sh -a 10 -i 1

# Test with different user
sudo bash test_brute_force_attack.sh -u test -s 192.168.1.50

# Verify existing alerts only
sudo bash test_brute_force_attack.sh -v

# See all options
sudo bash test_brute_force_attack.sh --help
```

**What it tests:**
- Rule 200001: SSH logon with non-nominal account (Level 11)
- Rule 200004: CRITICAL - Multiple SSH logins correlation (Level 15, freq: 5 in 120s)
- Rule 200002: Windows logon with non-nominal account (Level 12)
- Rule 200005: CRITICAL - Multiple Windows logins correlation (Level 15, freq: 5 in 120s)

**Expected Results:**
- Multiple individual alerts (Rule 200001, Level 11) sent to Teams
- 1 CRITICAL correlation alert (Rule 200004, Level 15) when threshold reached
- MITRE: T1110 (Brute Force) + T1078.003 (Valid Accounts: Local)

**Documentation:** See [TEST_BRUTE_FORCE.md](TEST_BRUTE_FORCE.md) for detailed usage guide.

---

### test_brute_force_remote.sh ⭐ NEW - RECOMMENDED
Simulates REAL SSH brute force attacks from external Linux machine (e.g., 10.27.20.183).

**Purpose:** Test realistic brute force detection with actual SSH traffic from external attacker.

**Requirements:**
- External Linux machine (e.g., 10.27.20.183)
- `sshpass` package installed: `sudo apt install sshpass`

**Quick Start from 10.27.20.183:**
```bash
# 1. Copy script to attacker machine
scp scripts/test_brute_force_remote.sh admin_emtec@10.27.20.183:~/

# 2. Execute attack
ssh admin_emtec@10.27.20.183
bash ~/test_brute_force_remote.sh

# 3. Verify on Wazuh server (from another terminal)
ssh root@10.27.20.171
tail -50 /var/ossec/logs/alerts/alerts.log | grep "10.27.20.183"
```

**Usage:**
```bash
# Basic remote attack (6 SSH attempts to 10.27.20.171)
bash ~/test_brute_force_remote.sh

# Intensive attack (10 attempts, 1 second interval)
bash ~/test_brute_force_remote.sh -a 10 -i 1

# Custom target and user
bash ~/test_brute_force_remote.sh -t 10.27.20.171 -u administrator

# See all options
bash ~/test_brute_force_remote.sh --help
```

**What it does:**
- Generates REAL SSH connection attempts from external IP (10.27.20.183)
- Uses incorrect password by design (simulates actual brute force)
- Attempts will fail but generate authentic SSH logs on target
- Wazuh detects patterns and triggers correlation rules

**Advantages over local simulation:**
- ✅ Real network traffic from external source
- ✅ Accurate source IP in alerts (10.27.20.183)
- ✅ Tests actual SSH authentication failures
- ✅ Realistic production scenario

**Documentation:** See [INSTRUCCIONES_ATAQUE_10.27.20.183.md](INSTRUCCIONES_ATAQUE_10.27.20.183.md) for step-by-step instructions.

---

### test_alerts.sh
Quick test of 17 representative rules covering all major categories.

**Purpose:** Rapid validation after installation or configuration changes.

**Usage:**
```bash
sudo bash test_alerts.sh
```

**What it tests:**
- 2 Kerberos rules
- 2 Service installation rules
- 3 Process creation rules (including Mimikatz)
- 1 LSASS access rule
- 3 Account management rules
- 2 Password change rules
- 3 Critical event rules (including log clearing)
- 1 PAM authentication rule

**Expected Duration:** ~30 seconds

**Expected Results:**
- 2 immediate critical alerts in Teams (Rules 100036, 100101)
- 1 summary message with remaining 15 alerts

---

### test_all_rules.sh
Comprehensive test of all 67 custom rules in 10 phases.

**Purpose:** Complete validation of entire ruleset for auditing or documentation.

**Usage:**
```bash
sudo bash test_all_rules.sh [webhook_url]
```

**What it tests:**

| Phase | Category | Rules |
|-------|----------|-------|
| 1 | Kerberos Authentication | 6 |
| 2 | Service Installation | 2 |
| 3 | Process Creation | 5 |
| 4 | LSASS Access | 2 |
| 5 | Account Management Part 1 | 8 |
| 6 | Account Management Part 2 | 7 |
| 7 | Groups & Privileges | 13 |
| 8 | Password & Policy | 4 |
| 9 | Critical Security Events | 4 |
| 10 | Compliance & Overrides | 16 |

**Expected Duration:** ~5 minutes

**Expected Results:**
- 2 immediate critical alerts (Level 15)
- Multiple summary messages as alerts accumulate
- ~65 total alerts in cache

**Phases Explained:**

**Phase 1 - Kerberos (6 rules):**
- TGT requests and failures
- Ticket renewals
- Service ticket operations
- Kerberoasting detection

**Phase 2 - Services (2 rules):**
- New service installations (Events 4697, 7045)
- Malicious service creation detection

**Phase 3 - Processes (5 rules):**
- Critical process monitoring
- Pass-the-Hash tools
- PsExec execution
- Credential theft tools
- PowerShell bypass

**Phase 4 - LSASS (2 rules):**
- LSASS memory access
- Suspicious LSASS object access

**Phase 5-7 - Account Management (28 rules):**
- User creation/deletion/modification
- Account lockouts and unlocks
- Security group membership changes
- Special privilege assignments
- DPAPI backup attempts

**Phase 8 - Passwords (4 rules):**
- Domain policy changes
- Kerberos policy modifications
- Audit policy changes
- SID history additions

**Phase 9 - Critical Events (4 rules):**
- EventLog service停止
- Log clearing (Level 15)
- PAM authentication

**Phase 10 - Compliance (16 rules):**
- Object access auditing
- Registry modifications
- File system access
- Network filtering
- Firewall events
- Override rules

---

## Utility Scripts

### clear_cache.sh
Resets the Teams alert cache to start fresh.

**Usage:**
```bash
sudo bash scripts/clear_cache.sh
```

**When to use:**
- After failed tests that left bad data
- To reset alert counters
- When troubleshooting accumulation issues

**Example:**
```bash
#!/bin/bash
sudo rm /var/ossec/logs/teams_alerts_cache.json
echo "[OK] Cache cleared"
```

---

### check_integration.sh
Validates Wazuh integration configuration and status.

**Usage:**
```bash
bash scripts/check_integration.sh
```

**Checks:**
- ✓ Integration script exists and is executable
- ✓ ossec.conf has valid integration section
- ✓ Webhook URL is configured
- ✓ Cache file permissions are correct
- ✓ Recent integration activity in logs

**Example Output:**
```
[✓] Integration script: /var/ossec/integrations/custom-teams-summary.py
[✓] Script executable: Yes
[✓] ossec.conf integration: Found (level 11)
[✓] Webhook configured: Yes
[✓] Cache file: Exists (4 alerts accumulated)
[✓] Last integration run: 2 minutes ago
[OK] Integration is healthy
```

---

### migration.sh
Automated migration script for moving configuration to new server.

**Usage:**
```bash
bash migration.sh [old_server_ip] [new_server_ip]
```

**Example:**
```bash
bash migration.sh 10.27.20.171 10.27.20.181
```

**What it does:**
1. Connects to old server via SSH
2. Backs up current configuration
3. Copies rules to new server
4. Copies integration scripts
5. Updates ossec.conf
6. Sets permissions
7. Verifies installation
8. Tests with sample alert

**Prerequisites:**
- SSH access to both servers
- Sudo privileges
- Same Wazuh version on both servers

**See:** [docs/MIGRATION.md](../docs/MIGRATION.md) for detailed migration guide

---

## Development Scripts

### generate_test_alerts.py
Python script to generate realistic test alerts with random data.

**Usage:**
```python
python3 generate_test_alerts.py --count 50 --rules 100001,100016,100036
```

**Options:**
- `--count`: Number of alerts to generate
- `--rules`: Comma-separated list of rule IDs
- `--agents`: Comma-separated list of agent names
- `--interval`: Seconds between alerts (default: 1)

---

### validate_rules.sh
Validates XML syntax and rule logic before deployment.

**Usage:**
```bash
bash validate_rules.sh ../rules/custom_windows_security_rules.xml
```

**Checks:**
- XML syntax validity
- Rule ID uniqueness
- Level values in valid range (0-15)
- Required tags present (`<if_sid>`, `<description>`)
- MITRE tags properly formatted
- Group tags exist

---

## Usage Examples

### Example 1: Quick Post-Installation Test

```bash
# After installing rules and integration
cd /opt/wazuh-custom-rules-teams/scripts
sudo bash test_alerts.sh

# Expected: 2 critical alerts + 1 summary in Teams within 30 seconds
```

### Example 2: Complete Rule Validation

```bash
# Test all 67 rules with your webhook
sudo bash test_all_rules.sh "https://your-webhook-url.com/..."

# Monitor in real-time
watch -n 2 'tail -5 /var/ossec/logs/integrations.log'
```

### Example 3: Troubleshooting Accumulation

```bash
# Clear cache
sudo bash clear_cache.sh

# Send exactly 3 test alerts
for i in {1..3}; do
  echo '{"timestamp":"2025-03-11T10:00:00","rule":{"id":"100001","level":12,"description":"Test"},"agent":{"name":"Test"}}' | \
  sudo /var/ossec/integrations/custom-teams-summary.py "YOUR_WEBHOOK" 11 "custom-teams-summary"
  sleep 2
done

# Should trigger summary on 3rd alert
```

### Example 4: Performance Testing

```bash
# Generate 100 alerts rapidly
time for i in {1..100}; do
  echo '{"timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%S)'","rule":{"id":"100001","level":11,"description":"Stress Test"},"agent":{"name":"PerfTest"}}' | \
  sudo /var/ossec/integrations/custom-teams-summary.py "YOUR_WEBHOOK" 11 "custom-teams-summary" &> /dev/null
done

# Verify system handled load
sudo tail -50 /var/ossec/logs/integrations.log
```

---

## Best Practices

### Before Running Tests

1. **Notify team:** Let SOC team know tests are planned
2. **Backup configuration:**
   ```bash
   sudo cp /var/ossec/etc/ossec.conf /root/backups/ossec.conf.$(date +%Y%m%d)
   ```
3. **Check current state:**
   ```bash
   sudo systemctl status wazuh-manager
   ```

### During Tests

1. **Monitor logs in real-time:**
   ```bash
   sudo tail -f /var/ossec/logs/integrations.log | grep custom-teams
   ```

2. **Watch Teams channel** for alert arrivals

3. **Track cache growth:**
   ```bash
   watch -n 5 'sudo python3 -c "import pickle; print(len(pickle.load(open(\"/var/ossec/logs/teams_alerts_cache.pkl\",\"rb\")).get(\"alerts\", [])))"'
   ```

### After Tests

1. **Clear test alerts:**
   ```bash
   sudo bash clear_cache.sh
   ```

2. **Review logs for errors:**
   ```bash
   sudo grep -i error /var/ossec/logs/integrations.log | tail -20
   ```

3. **Document results:**
   ```bash
   echo "Test completed: $(date)" >> /root/wazuh_test_log.txt
   ```

---

## Troubleshooting

### Test Script Not Executing

**Symptom:** `Permission denied` error

**Solution:**
```bash
sudo chmod +x scripts/*.sh
```

### No Alerts Arriving in Teams

**Symptom:** Scripts run但 Teams channel silent

**Diagnosis:**
```bash
# Check integration script execution
sudo tail -20 /var/ossec/logs/integrations.log

# Find errors
sudo grep -i "http" /var/ossec/logs/integrations.log | tail -10
```

**Common causes:**
1. Webhook URL incorrect or expired
2. Power Automate flow disabled
3. Teams channel type changed (Conversaciones ↔ Publicaciones)

### Tests Taking Too Long

**Symptom:** `test_all_rules.sh` hangs or times out

**Solution:**
```bash
# Reduce sleep intervals in script (edit line ~45)
sleep 0.2  # Instead of sleep 0.5

# Or run with timeout
timeout 300 sudo bash test_all_rules.sh
```

### Cache Not Accumulating

**Symptom:** Every alert sent immediately instead of accumulating

**Diagnosis:**
```bash
# Check cache file permissions
ls -lh /var/ossec/logs/teams_alerts_cache.pkl

# Check write permissions on logs directory
sudo -u wazuh touch /var/ossec/logs/test_write
```

**Solution:**
```bash
sudo chown root:wazuh /var/ossec/logs
sudo chmod 775 /var/ossec/logs
```

---

## Script Maintenance

### Updating Webhook URLs

When webhook changes, update in scripts:

```bash
# Update test_alerts.sh
sudo sed -i 's|WEBHOOK_URL=".*"|WEBHOOK_URL="https://new-webhook-url"|' scripts/test_alerts.sh

# Update test_all_rules.sh
sudo sed -i 's|WEBHOOK_URL=".*"|WEBHOOK_URL="https://new-webhook-url"|' scripts/test_all_rules.sh
```

### Adding New Test Rules

To test a new custom rule (e.g., Rule 100999):

```bash
# Add to test_alerts.sh in appropriate phase
send_alert "100999" "12" "My New Rule Description" "4700"
```

### Version Control

Keep scripts in Git:

```bash
git add scripts/*.sh
git commit -m "Updated test scripts with new rules"
git push origin main
```

---

## Performance Metrics

**test_alerts.sh** (17 rules):
- Duration: ~30 seconds
- Memory: <5 MB
- CPU: <1% on 4-core system
- Network: 3-5 requests (2 immediate + 1 summary)

**test_all_rules.sh** (67 rules):
- Duration: ~5 minutes
- Memory: <10 MB
- CPU: <2% on 4-core system
- Network: 15-25 requests (2 immediate + 13-23 summaries)

---

## Contributing

To add new test scripts:

1. Follow naming convention: `test_*.sh` or `verify_*.sh`
2. Add help text (`--help` flag)
3. Include error handling
4. Document in this README
5. Test on clean install before committing

---

## References

- [Wazuh Testing Guide](https://documentation.wazuh.com/current/development/testing.html)
- [Bash Scripting Best Practices](https://google.github.io/styleguide/shellguide.html)
- [Alert Simulation Examples](https://github.com/wazuh/wazuh/tree/master/framework/scripts)
