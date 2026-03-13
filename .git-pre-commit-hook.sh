#!/bin/bash
#
# Pre-commit hook for validating Wazuh custom rules
# Place this file in .git/hooks/pre-commit and make it executable
# or install via: cp pre-commit .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
#
# This hook:
# - Validates XML syntax of changed rule files
# - Detects duplicate rule IDs
# - Checks for critical rule integrity
# - Prevents commits with invalid rules
#

set -e

RULES_DIR="Wazuh-Rules-Teams/rules"
VALIDATOR_SCRIPT="validate_rules.py"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}[pre-commit hook] Validating Wazuh custom rules...${NC}"

# Check if validator script exists
if [ ! -f "$VALIDATOR_SCRIPT" ]; then
    echo -e "${YELLOW}[pre-commit] Warning: $VALIDATOR_SCRIPT not found, skipping validation${NC}"
    exit 0
fi

# Find all changed XML rule files
CHANGED_RULES=$(git diff --cached --name-only | grep "^${RULES_DIR}/.*\.xml$" || true)

if [ -z "$CHANGED_RULES" ]; then
    echo -e "${GREEN}[pre-commit] No rule files changed${NC}"
    exit 0
fi

echo -e "${YELLOW}[pre-commit] Validating changed rule files:${NC}"
for rule_file in $CHANGED_RULES; do
    echo "  - $rule_file"
done

# Run validator on all rules (not just changed, to catch cross-file issues)
if python3 "$VALIDATOR_SCRIPT" > /tmp/validator_output.txt 2>&1; then
    VALIDATION_RESULT=$?
else
    VALIDATION_RESULT=$?
fi

# Check for critical XML syntax errors
if grep -q "ERROR\|SyntaxError\|ParseError" /tmp/validator_output.txt; then
    echo -e "${RED}[pre-commit] ✗ VALIDATION FAILED${NC}"
    cat /tmp/validator_output.txt
    echo ""
    echo -e "${RED}Fix the validation errors before committing.${NC}"
    echo "Run: python3 $VALIDATOR_SCRIPT"
    exit 1
fi

# Check for duplicate rule IDs
if grep -q "Duplicate rule IDs detected" /tmp/validator_output.txt; then
    echo -e "${RED}[pre-commit] ✗ DUPLICATE RULE IDs DETECTED${NC}"
    cat /tmp/validator_output.txt
    echo ""
    echo -e "${RED}Resolve duplicate rule IDs before committing.${NC}"
    echo "Hint: Rules must have unique IDs in range 200001-200100"
    exit 1
fi

# Check for deprecated file overlaps
if grep -q "Deprecated file overlaps detected" /tmp/validator_output.txt; then
    echo -e "${YELLOW}[pre-commit] ⚠ WARNING: Deprecated file overlaps detected${NC}"
    cat /tmp/validator_output.txt
    echo ""
    echo -e "${YELLOW}This may cause rule conflicts. Review before committing.${NC}"
    # Don't fail on warnings, just alert
fi

# If all checks pass
echo -e "${GREEN}[pre-commit] ✓ All validation checks passed${NC}"
rm -f /tmp/validator_output.txt
exit 0
