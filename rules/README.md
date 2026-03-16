# Wazuh Custom Rules (LEGACY DOCUMENTATION)

⚠️ **NOTE:** This directory contains an incomplete version of the custom rules. 

## Current Version Location

For the **complete and up-to-date** set of 101 custom rules (89 Windows + 5 Overrides + 7 Linux), please refer to:
- 📂 **`/Wazuh-Rules-Teams/rules/`** - Complete rule set with full documentation

## This Directory

This directory contains legacy rule files:
- **custom_windows_security_rules.xml**: 62 Windows Security rules (partial set)
- **local_rules_override.xml**: 5 override rules

**RECOMMENDATION:** Use the canonical rules from `/Wazuh-Rules-Teams/rules/` for production deployments.

## Legacy Files

### custom_windows_security_rules.xml
Contains 62 custom rules organized in the following categories:

- **Kerberos Authentication** (Rules 100001-100006): Detection of Kerberos attacks including Kerberoasting and ticket manipulation
- **Service Installation** (Rules 100007-100008): Monitoring of new service installations
- **Process Creation** (Rules 100009-100013): Critical process monitoring including Mimikatz and credential theft
- **LSASS Events** (Rules 100014-100015): Detection of LSASS process access
- **Account Management** (Rules 100016-100038): User account creation, modification, deletion, and privilege changes
- **Password Changes** (Rules 100039-100042): Password policy changes and modifications
- **Application Activity** (Rules 100043-100047): MS-Windows-SecurityAuditing event monitoring
- **Security Event Log** (Rules 100048-100049): Event log clearing and tampering detection
- **PAM** (Rule 100050): Pluggable Authentication Module events
- **Audit Rules** (Rules 100051-100062): Additional Windows audit events

### local_rules_override.xml
Contains 5 override rules that modify severity levels of existing Wazuh rules:

- **Rule 60103**: Increased from level 0 to level 8 for generic Windows Security events
- **Rules 100070-100072**: Password change variants (levels 0, 3, 3)
- **Rule 100101**: Event log clearing raised to level 15 (critical)
- **Rule 100103**: PAM authentication (level 3)

## Rule Naming Convention

- **100001-100062**: Custom Windows Security rules
- **100070-100103**: Override rules (modifying existing Wazuh rule behavior)

## Event ID Mapping

Each rule is mapped to specific Windows Event IDs:

| Event ID | Description | Rule IDs |
|----------|-------------|----------|
| 4768 | Kerberos TGT Request | 100001-100003 |
| 4770 | Kerberos Ticket Renewal | 100004-100005 |
| 4679 | Kerberos Service Ticket | 100006 |
| 4697 | Service Installed | 100007 |
| 7045 | Service Installed (Alternative) | 100008 |
| 4688 | Process Creation | 100009-100013 |
| 4663 | Object Access (includes LSASS) | 100014-100015 |
| 4720 | User Account Created | 100016 |
| 4722 | User Account Enabled | 100017 |
| 4723 | Change Password Attempt | 100018 |
| 4724 | Reset Password Attempt | 100019 |
| 4725 | User Account Disabled | 100020 |
| 4726 | User Account Deleted | 100021 |
| 4738 | User Account Changed | 100022 |
| 4740 | User Account Locked | 100023 |
| 4767 | User Account Unlocked | 100024 |
| 4781 | Account Name Changed | 100025 |
| 4732 | Member Added to Group | 100026 |
| 4733 | Member Removed from Group | 100027 |
| 4756 | Member Added to Universal Group | 100028 |
| 4757 | Member Removed from Universal Group | 100029 |
| 4735 | Group Changed | 100030 |
| 4737 | Global Group Changed | 100031 |
| 4727 | Global Security Group Created | 100032 |
| 4754 | Universal Security Group Created | 100033 |
| 4730 | Global Security Group Deleted | 100034 |
| 4758 | Universal Security Group Deleted | 100035 |
| 10 | Process Access (Mimikatz detection) | 100036 |
| 4672 | Special Privileges Assigned | 100037 |
| 4794 | DPAPI Restore Attempt | 100038 |
| 4739 | Domain Policy Changed | 100039 |
| 4713 | Kerberos Policy Changed | 100040 |
| 4719 | System Audit Policy Changed | 100041 |
| 4765 | SID History Added | 100042 |

## MITRE ATT&CK Mapping

All rules include MITRE ATT&CK technique tags for threat intelligence integration:

- **T1558**: Steal or Forge Kerberos Tickets
- **T1558.003**: Kerberoasting
- **T1543.003**: Windows Service
- **T1003**: OS Credential Dumping
- **T1003.001**: LSASS Memory
- **T1136**: Create Account
- **T1098**: Account Manipulation
- **T1078**: Valid Accounts
- **T1070.001**: Clear Windows Event Logs
- **T1055**: Process Injection
- **T1548**: Abuse Elevation Control Mechanism

## Compliance Mapping

Rules are tagged with compliance frameworks:

- **PCI DSS**: Payment Card Industry Data Security Standard
- **GDPR**: General Data Protection Regulation
- **HIPAA**: Health Insurance Portability and Accountability Act
- **NIST 800-53**: Security and Privacy Controls
- **TSC**: Trust Services Criteria

## Severity Levels

| Level | Description | Alert Threshold |
|-------|-------------|-----------------|
| 0-10 | Informational to Medium | Accumulated in summary |
| 11-14 | High | Sent via summary (level 11 minimum) |
| 15 | Critical | Sent immediately, bypasses accumulation |

## Installation

1. Copy both XML files to `/var/ossec/etc/rules/` on your Wazuh Manager:

```bash
sudo cp custom_windows_security_rules.xml /var/ossec/etc/rules/
sudo cp local_rules_override.xml /var/ossec/etc/rules/
```

2. Set proper ownership:

```bash
sudo chown root:wazuh /var/ossec/etc/rules/custom_windows_security_rules.xml
sudo chown root:wazuh /var/ossec/etc/rules/local_rules_override.xml
sudo chmod 640 /var/ossec/etc/rules/*.xml
```

3. Test rule syntax:

```bash
sudo /var/ossec/bin/wazuh-logtest
```

4. Restart Wazuh Manager:

```bash
sudo systemctl restart wazuh-manager
```

## Validation

Verify rules are loaded:

```bash
sudo grep -r "rule id=\"100" /var/ossec/etc/rules/
```

Check for syntax errors:

```bash
sudo tail -f /var/ossec/logs/ossec.log | grep -i error
```

## Customization

### Adjusting Severity Levels

Edit the `level` attribute in each `<rule>` tag:

```xml
<rule id="100001" level="3">  <!-- Change this number -->
```

### Disabling Specific Rules

Comment out unwanted rules:

```xml
<!-- <rule id="100001" level="3">
  ...
</rule> -->
```

### Adding Custom Fields

Extend rules with additional field matching:

```xml
<rule id="100001" level="3">
  <if_sid>60103</if_sid>
  <field name="win.system.eventID">^4768$</field>
  <field name="win.eventdata.targetUserName">admin</field>  <!-- New condition -->
  <description>...</description>
</rule>
```

## Troubleshooting

### Rules Not Triggering

1. **Check rule is loaded:**
   ```bash
   sudo /var/ossec/bin/wazuh-control info | grep rules
   ```

2. **Verify parent rule exists:**
   All custom rules depend on rule `60103` (Windows Security base rule)

3. **Test with sample alert:**
   ```bash
   echo '{"win":{"system":{"eventID":"4768"}}}' | sudo /var/ossec/bin/wazuh-logtest
   ```

### High False Positive Rate

- **Adjust frequency/timeframe:** Modify correlation rules (e.g., rule 100002)
- **Add exclusions:** Use `<match>` with negation patterns
- **Increase level threshold:** Raise level in ossec.conf integration

## References

- [Wazuh Rule Syntax Documentation](https://documentation.wazuh.com/current/user-manual/ruleset/ruleset-xml-syntax/index.html)
- [Windows Security Event IDs](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/plan/appendix-l--events-to-monitor)
- [MITRE ATT&CK Framework](https://attack.mitre.org/)
