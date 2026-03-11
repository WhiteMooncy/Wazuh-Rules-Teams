#!/bin/bash
# test_all_rules.sh - Comprehensive test of all 67 Wazuh custom rules
# Tests every rule in the custom_windows_security_rules.xml and local_rules_override.xml
#
# Usage: sudo bash test_all_rules.sh [webhook_url]
#
# This script generates alerts for ALL 67 rules organized in 10 phases:
#   1. Kerberos (6 rules)
#   2. Services (2 rules)
#   3. Processes (5 rules)
#   4. LSASS (2 rules)
#   5. Accounts Part 1 (8 rules)
#   6. Accounts Part 2 (7 rules)
#   7. Additional Account Management (13 rules)
#   8. Passwords (4 rules)
#   9. Critical Events (4 rules)
#  10. Compliance & Overrides (16 rules)

WEBHOOK_URL="${1:-YOUR_WEBHOOK_URL_HERE}"
SCRIPT="/var/ossec/integrations/custom-teams-summary.py"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   WAZUH COMPREHENSIVE RULE TEST - ALL 67 RULES           ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Webhook: ${WEBHOOK_URL:0:60}..."
echo "Script: $SCRIPT"
echo ""
read -p "Press Enter to start testing (Ctrl+C to cancel)..."
echo ""

contador=0
fase=1

send_alert() {
    local rule_id=$1
    local rule_level=$2
    local description=$3
    local event_id=$4
    
    ((contador++))
    echo -ne "${YELLOW}[${contador}/67]${NC} Rule ${rule_id} (L${rule_level}): "
    echo "$description" | cut -c1-60
    
    cat <<EOF | sudo $SCRIPT "$WEBHOOK_URL" 11 "custom-teams-summary" 2>&1 | grep -E "(OK|ERROR|INFO)" | head -1
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%S+0000)",
  "rule": {
    "level": ${rule_level},
    "description": "${description}",
    "id": "${rule_id}"
  },
  "agent": {
    "id": "001",
    "name": "Windows-Test-Agent-Full"
  },
  "location": "EventChannel",
  "data": {
    "win": {
      "eventdata": {
        "targetUserName": "testuser",
        "subjectUserName": "admin"
      },
      "system": {
        "eventID": "${event_id}",
        "computer": "TestServer.domain.local"
      }
    }
  }
}
EOF
    sleep 0.5
}

# PHASE 1: Kerberos Authentication (6 rules)
echo -e "\n${BLUE}═══ PHASE 1/${10}: Kerberos Authentication (6 rules) ═══${NC}"
send_alert "100001" "3" "Kerberos TGT Request" "4768"
send_alert "100002" "10" "Possible Kerberoasting - Multiple TGT Requests" "4768"
send_alert "100003" "5" "Kerberos TGT Failed - Account Disabled" "4768"
send_alert "100004" "3" "Kerberos Service Ticket Renewed" "4770"
send_alert "100005" "8" "Kerberos Renewal Failed - Integrity Check" "4770"
send_alert "100006" "3" "Kerberos Service Ticket Operations" "4679"

# PHASE 2: Service Installation (2 rules)
echo -e "\n${BLUE}═══ PHASE 2/10: Service Installation (2 rules) ═══${NC}"
send_alert "100007" "8" "Service Installed in System" "4697"
send_alert "100008" "8" "Service Installed (Event 7045)" "7045"

# PHASE 3: Process Creation (5 rules)
echo -e "\n${BLUE}═══ PHASE 3/10: Process Creation (5 rules) ═══${NC}"
send_alert "100009" "5" "Critical Process Created" "4688"
send_alert "100010" "12" "Suspicious Process - Pass-the-Hash Tool" "4688"
send_alert "100011" "10" "PsExec Remote Execution" "4688"
send_alert "100012" "12" "Credential Theft Tool Detected" "4688"
send_alert "100013" "12" "PowerShell Execution Policy Bypass" "4688"

# PHASE 4: LSASS Events (2 rules)
echo -e "\n${BLUE}═══ PHASE 4/10: LSASS Process Access (2 rules) ═══${NC}"
send_alert "100014" "12" "LSASS Process Memory Access" "4663"
send_alert "100015" "10" "Suspicious LSASS Object Access" "4663"

# PHASE 5: Account Management Part 1 (8 rules)
echo -e "\n${BLUE}═══ PHASE 5/10: Account Management Part 1 (8 rules) ═══${NC}"
send_alert "100016" "5" "User Account Created" "4720"
send_alert "100017" "5" "User Account Enabled" "4722"
send_alert "100018" "5" "User Change Password Attempt" "4723"
send_alert "100019" "5" "User Reset Password Attempt" "4724"
send_alert "100020" "5" "User Account Disabled" "4725"
send_alert "100021" "5" "User Account Deleted" "4726"
send_alert "100022" "5" "User Account Changed" "4738"
send_alert "100023" "8" "User Account Locked Out" "4740"

# PHASE 6: Account Management Part 2 (7 rules)
echo -e "\n${BLUE}═══ PHASE 6/10: Account Management Part 2 (7 rules) ═══${NC}"
send_alert "100024" "5" "User Account Unlocked" "4767"
send_alert "100025" "8" "Account Name Changed" "4781"
send_alert "100026" "8" "Member Added to Security Group" "4732"
send_alert "100027" "5" "Member Removed from Security Group" "4733"
send_alert "100028" "8" "Member Added to Universal Security Group" "4756"
send_alert "100029" "5" "Member Removed from Universal Security Group" "4757"
send_alert "100030" "5" "Security Group Changed" "4735"

# PHASE 7: Additional Account Management (13 rules)
echo -e "\n${BLUE}═══ PHASE 7/10: Groups & Privileges (13 rules) ═══${NC}"
send_alert "100031" "5" "Global Security Group Changed" "4737"
send_alert "100032" "5" "Global Security Group Created" "4727"
send_alert "100033" "5" "Universal Security Group Created" "4754"
send_alert "100034" "8" "Global Security Group Deleted" "4730"
send_alert "100035" "8" "Universal Security Group Deleted" "4758"
send_alert "100036" "15" "Mimikatz Credential Theft Detected" "10"
send_alert "100037" "8" "Special Privileges Assigned to New Logon" "4672"
send_alert "100038" "10" "DPAPI Master Key Backup Attempt" "4794"
send_alert "100043" "3" "Windows Security Auditing Application" "4625"
send_alert "100044" "5" "Windows Security Auditing Application" "4624"
send_alert "100045" "5" "Windows Security Auditing System Integrity" "4616"
send_alert "100046" "8" "Windows Security Auditing System Event" "4608"
send_alert "100047" "5" "Windows Security Auditing System" "4609"

# PHASE 8: Password & Policy Changes (4 rules)
echo -e "\n${BLUE}═══ PHASE 8/10: Password & Policy (4 rules) ═══${NC}"
send_alert "100039" "8" "Domain Policy Changed" "4739"
send_alert "100040" "8" "Kerberos Policy Changed" "4713"
send_alert "100041" "12" "System Audit Policy Changed" "4719"
send_alert "100042" "12" "SID History Added to Account" "4765"

# PHASE 9: Critical Events (4 rules)
echo -e "\n${BLUE}═══ PHASE 9/10: Critical Security Events (4 rules) ═══${NC}"
send_alert "100048" "12" "Security Event Log Service Stopped" "1100"
send_alert "100049" "12" "Windows EventLog Audit Log Cleared" "1102"
send_alert "100050" "3" "PAM: Authentication Attempt" "4776"
send_alert "100051" "5" "Audit Events: Object Handle Closed" "4658"

# PHASE 10: Additional Rules & Overrides (16 rules)
echo -e "\n${BLUE}═══ PHASE 10/10: Compliance & Overrides (16 rules) ═══${NC}"
send_alert "100052" "5" "Audit Events: Registry Value Modified" "4657"
send_alert "100053" "5" "Audit Events: File System Object Access" "4656"
send_alert "100054" "5" "Audit Events: Filtering Platform Connection" "5156"
send_alert "100055" "5" "Audit Events: Filtering Platform Packet Drop" "5157"
send_alert "100056" "8" "Audit Events: Windows Firewall Service Started" "5024"
send_alert "100057" "8" "Audit Events: Windows Firewall Driver Started" "5025"
send_alert "100058" "12" "Audit Events: Windows Firewall Failed to Load" "5028"
send_alert "100059" "12" "Audit Events: Windows Firewall Driver Failed" "5029"
send_alert "100060" "8" "Audit Events: Security Policy Changed" "4670"
send_alert "100061" "5" "Audit Events: Scheduled Task Created" "4698"
send_alert "100062" "5" "Audit Events: Scheduled Task Deleted" "4699"

# Override rules (5 rules from local_rules_override.xml)
echo -e "\n${BLUE}─── Override Rules (5 rules) ───${NC}"
send_alert "60103" "8" "Generic Windows Security Event (Override)" "4624"
send_alert "100070" "0" "Password Change Variant 1" "4724"
send_alert "100071" "3" "Password Change Variant 2" "4724"
send_alert "100072" "3" "Password Change Variant 3" "4724"
send_alert "100101" "15" "CRITICAL: Event Log Cleared" "1102"
send_alert "100103" "3" "PAM Authentication Override" "4776"

# Final Summary
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║               TEST COMPLETED SUCCESSFULLY                 ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Summary:${NC}"
echo "  ✓ Total rules tested: ${contador}/67"
echo "  ✓ Phases completed: 10/10"
echo ""
echo -e "${YELLOW}Expected Results in Teams:${NC}"
echo "  1. ${RED}Immediate alerts${NC} (Level 15):"
echo "     - Rule 100036: Mimikatz Detection"
echo "     - Rule 100101: Event Log Cleared"
echo ""
echo "  2. ${BLUE}Summary message${NC} with ~65 accumulated alerts"
echo "     (All other rules with level 11-14)"
echo ""
echo -e "${YELLOW}Verification Commands:${NC}"
echo "  # Check cache status:"
echo "  sudo python3 -c \"import pickle; cache=pickle.load(open('/var/ossec/logs/teams_alerts_cache.pkl','rb')); print(f'Alerts: {len(cache.get(\\\"alerts\\\", []))}  Summaries: {cache.get(\\\"summary_count\\\", 0)}')\""
echo ""
echo "  # View last 10 integration logs:"
echo "  sudo tail -20 /var/ossec/logs/integrations.log | grep custom-teams"
echo ""
echo "  # Clear cache to reset:"
echo "  sudo rm /var/ossec/logs/teams_alerts_cache.pkl"
echo ""
echo -e "${GREEN}All tests completed at $(date)${NC}"
