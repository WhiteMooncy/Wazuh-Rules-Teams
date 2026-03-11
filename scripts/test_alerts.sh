#!/bin/bash
# test_alerts.sh - Quick test of representative Wazuh rules
# Tests 17 key rules covering major categories
#
# Usage: sudo bash test_alerts.sh

WEBHOOK_URL="YOUR_WEBHOOK_URL_HERE"  # Replace with your Power Automate webhook
SCRIPT="/var/ossec/integrations/custom-teams-summary.py"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Wazuh Alert Simulation - Quick Test ===${NC}"
echo "Testing 17 representative rules..."
echo ""

# Counter for successful tests
contador=0

# Function to send alert
send_alert() {
    local rule_id=$1
    local rule_level=$2
    local description=$3
    local event_id=$4
    
    echo -e "${YELLOW}[TEST $((contador+1))]${NC} Rule ${rule_id} (Level ${rule_level}): ${description}"
    
    cat <<EOF | $SCRIPT "$WEBHOOK_URL" 11 "custom-teams-summary" 2>&1 | grep -E "(OK|ERROR|WARNING)"
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%S+0000)",
  "rule": {
    "level": ${rule_level},
    "description": "${description}",
    "id": "${rule_id}",
    "mitre": {}
  },
  "agent": {
    "id": "001",
    "name": "Windows-Test-Agent"
  },
  "location": "EventChannel",
  "data": {
    "win": {
      "eventdata": {
        "targetUserName": "testuser"
      },
      "system": {
        "eventID": "${event_id}",
        "computer": "TestServer.domain.local"
      }
    }
  }
}
EOF
    
    ((contador++))
    sleep 1
}

# Test Phase 1: Kerberos (2 samples)
echo -e "\n${GREEN}>>> Phase 1: Kerberos Authentication${NC}"
send_alert "100001" "3" "Kerberos TGT Request" "4768"
send_alert "100002" "10" "Possible Kerberoasting Attack" "4768"

# Test Phase 2: Services (2 samples)
echo -e "\n${GREEN}>>> Phase 2: Service Installation${NC}"
send_alert "100007" "8" "Service Installed" "4697"
send_alert "100008" "8" "Service Installed (7045)" "7045"

# Test Phase 3: Processes (3 samples)
echo -e "\n${GREEN}>>> Phase 3: Process Creation${NC}"
send_alert "100009" "5" "Critical Process Created" "4688"
send_alert "100036" "15" "Mimikatz Detection" "10"
send_alert "100013" "12" "PowerShell Execution Policy Bypass" "4688"

# Test Phase 4: LSASS (1 sample)
echo -e "\n${GREEN}>>> Phase 4: LSASS Access${NC}"
send_alert "100014" "12" "LSASS Process Access" "4663"

# Test Phase 5: Accounts (3 samples)
echo -e "\n${GREEN}>>> Phase 5: Account Management${NC}"
send_alert "100016" "5" "User Account Created" "4720"
send_alert "100020" "5" "User Account Disabled" "4725"
send_alert "100026" "8" "Member Added to Security Group" "4732"

# Test Phase 6: Passwords (2 samples)
echo -e "\n${GREEN}>>> Phase 6: Password Changes${NC}"
send_alert "100018" "5" "User Change Password Attempt" "4723"
send_alert "100039" "8" "Domain Policy Changed" "4739"

# Test Phase 7: Critical Events (3 samples)
echo -e "\n${GREEN}>>> Phase 7: Critical Security Events${NC}"
send_alert "100048" "12" "Security Event Log Cleared" "1102"
send_alert "100101" "15" "Event Log Clearing Detected" "1102"
send_alert "100037" "8" "Special Privileges Assigned" "4672"

# Test Phase 8: PAM (1 sample)
echo -e "\n${GREEN}>>> Phase 8: PAM Authentication${NC}"
send_alert "100050" "3" "PAM Authentication" "4776"

# Summary
echo ""
echo -e "${GREEN}=== Test Summary ===${NC}"
echo -e "Total alerts sent: ${contador}"
echo ""
echo "Expected behavior:"
echo "  - Alerts below level 15 should accumulate"
echo "  - After 3 alerts, summary should be sent to Teams"
echo "  - Alerts at level 15 (Mimikatz, Log Clearing) sent immediately"
echo ""
echo "Check your Teams channel for:"
echo "  1. Immediate critical alerts (rules 100036, 100101)"
echo "  2. Summary message with accumulated alerts"
echo ""
echo -e "${YELLOW}Verify cache status:${NC}"
echo "  sudo python3 -c \"import pickle; print(pickle.load(open('/var/ossec/logs/teams_alerts_cache.pkl','rb')))\""
echo ""
echo -e "${GREEN}Test completed!${NC}"
