#!/bin/bash
#
# test_factorized_rules.sh - Test completo arquitectura factorizada v2.0
# Autor: SOC Team
# Fecha: 2026-03-12
# 
# Tests base de las 101 reglas custom organizadas en 3 archivos:
#   - custom_windows_security_rules.xml (89 reglas)
#   - custom_windows_overrides.xml (5 reglas)
#   - custom_linux_security_rules.xml (7 reglas)
#
# Uso: sudo bash test_factorized_rules.sh
#

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Contadores
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  WAZUH FACTORIZED RULES TEST - Architecture v2.0             ║${NC}"
echo -e "${GREEN}║  101 Custom Rules across 3 specialized files                 ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar que estamos en el servidor correcto
if [ ! -f "/var/ossec/bin/wazuh-logtest" ]; then
    echo -e "${RED}ERROR: wazuh-logtest no encontrado. ¿Estás en el servidor Wazuh?${NC}"
    exit 1
fi

echo -e "${CYAN}[INFO]${NC} Verificando servicios Wazuh..."
systemctl is-active --quiet wazuh-manager
if [ $? -eq 0 ]; then
    echo -e "${GREEN}[OK]${NC} wazuh-manager activo"
else
    echo -e "${RED}[FAIL]${NC} wazuh-manager no está activo"
    exit 1
fi

echo ""
echo -e "${CYAN}[INFO]${NC} Verificando archivos de reglas..."
if [ -f "/var/ossec/etc/rules/custom_windows_security_rules.xml" ]; then
    echo -e "${GREEN}[OK]${NC} custom_windows_security_rules.xml encontrado"
else
    echo -e "${YELLOW}[WARN]${NC} custom_windows_security_rules.xml no encontrado"
fi

if [ -f "/var/ossec/etc/rules/custom_windows_overrides.xml" ]; then
    echo -e "${GREEN}[OK]${NC} custom_windows_overrides.xml encontrado"
else
    echo -e "${YELLOW}[WARN]${NC} custom_windows_overrides.xml no encontrado"
fi

if [ -f "/var/ossec/etc/rules/custom_linux_security_rules.xml" ]; then
    echo -e "${GREEN}[OK]${NC} custom_linux_security_rules.xml encontrado"
else
    echo -e "${YELLOW}[WARN]${NC} custom_linux_security_rules.xml no encontrado"
fi

echo ""
echo -e "${CYAN}[INFO]${NC} Verificando CDB list..."
if [ -f "/var/ossec/etc/lists/no-nominal-account.cdb" ]; then
    echo -e "${GREEN}[OK]${NC} no-nominal-account.cdb compilado"
else
    echo -e "${YELLOW}[WARN]${NC} no-nominal-account.cdb no encontrado"
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  INICIANDO TESTS DE REGLAS CRÍTICAS${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Función para test de regla
test_rule() {
    local rule_id=$1
    local description=$2
    local log_sample=$3
    
    ((TOTAL_TESTS++))
    echo -ne "${YELLOW}[Test #${TOTAL_TESTS}]${NC} Rule ${rule_id}: ${description}... "
    
    # Ejecutar wazuh-logtest
    result=$(echo "$log_sample" | /var/ossec/bin/wazuh-logtest 2>&1 | grep -E "rule: '${rule_id}'|Rule id: '${rule_id}'")
    
    if [ -n "$result" ]; then
        echo -e "${GREEN}PASS${NC}"
        ((PASSED_TESTS++))
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        ((FAILED_TESTS++))
        return 1
    fi
}

# ============================================================================
# TESTS: CUSTOM_WINDOWS_SECURITY_RULES.XML (89 reglas)
# ============================================================================

echo -e "${CYAN}>>> Testing custom_windows_security_rules.xml (89 reglas)${NC}"
echo ""

# Kerberos (6 reglas: 100001-100006)
test_rule "100001" "Kerberos TGT Request" "2026 Mar 12 10:00:00 WinEvtLog: Security: AUDIT_SUCCESS(4768): Microsoft-Windows-Security-Auditing: WIN-SERVER: INFO: A Kerberos authentication ticket (TGT) was requested."

test_rule "100004" "Kerberos TGT Renewal" "2026 Mar 12 10:00:00 WinEvtLog: Security: AUDIT_SUCCESS(4770): Microsoft-Windows-Security-Auditing: WIN-SERVER: INFO: A Kerberos service ticket was renewed."

test_rule "100006" "Kerberos Service Ticket" "2026 Mar 12 10:00:00 WinEvtLog: Security: AUDIT_SUCCESS(4769): Microsoft-Windows-Security-Auditing: WIN-SERVER: INFO: A Kerberos service ticket was requested."

# Process Execution (5 reglas: 100009-100013)
test_rule "100009" "CMD Process Creation" "2026 Mar 12 10:00:00 WinEvtLog: Security: AUDIT_SUCCESS(4688): Microsoft-Windows-Security-Auditing: WIN-SERVER: INFO: A new process has been created. Process Name: C:\\Windows\\System32\\cmd.exe"

test_rule "100010" "PowerShell Execution" "2026 Mar 12 10:00:00 WinEvtLog: Security: AUDIT_SUCCESS(4688): Microsoft-Windows-Security-Auditing: WIN-SERVER: INFO: A new process has been created. Process Name: C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe"

# Credential Access (2 reglas: 100014-100015)
test_rule "100014" "LSASS Access" "2026 Mar 12 10:00:00 WinEvtLog: Security: AUDIT_SUCCESS(4663): Microsoft-Windows-Security-Auditing: WIN-SERVER: INFO: An attempt was made to access an object. Object Name: C:\\Windows\\System32\\lsass.exe"

# Account Management (15 reglas)
test_rule "100016" "User Account Created" "2026 Mar 12 10:00:00 WinEvtLog: Security: AUDIT_SUCCESS(4720): Microsoft-Windows-Security-Auditing: WIN-SERVER: INFO: A user account was created."

test_rule "100017" "User Account Enabled" "2026 Mar 12 10:00:00 WinEvtLog: Security: AUDIT_SUCCESS(4722): Microsoft-Windows-Security-Auditing: WIN-SERVER: INFO: A user account was enabled."

test_rule "100020" "User Account Disabled" "2026 Mar 12 10:00:00 WinEvtLog: Security: AUDIT_SUCCESS(4725): Microsoft-Windows-Security-Auditing: WIN-SERVER: INFO: A user account was disabled."

test_rule "100021" "User Account Deleted" "2026 Mar 12 10:00:00 WinEvtLog: Security: AUDIT_SUCCESS(4726): Microsoft-Windows-Security-Auditing: WIN-SERVER: INFO: A user account was deleted."

test_rule "100023" "User Account Locked" "2026 Mar 12 10:00:00 WinEvtLog: Security: AUDIT_SUCCESS(4740): Microsoft-Windows-Security-Auditing: WIN-SERVER: INFO: A user account was locked out."

# Group Management (6 reglas)
test_rule "100026" "Member Added to Group" "2026 Mar 12 10:00:00 WinEvtLog: Security: AUDIT_SUCCESS(4732): Microsoft-Windows-Security-Auditing: WIN-SERVER: INFO: A member was added to a security-enabled local group. Group Name: Administrators"

test_rule "100027" "Member Removed from Group" "2026 Mar 12 10:00:00 WinEvtLog: Security: AUDIT_SUCCESS(4733): Microsoft-Windows-Security-Auditing: WIN-SERVER: INFO: A member was removed from a security-enabled local group."

test_rule "100032" "Security Group Created" "2026 Mar 12 10:00:00 WinEvtLog: Security: AUDIT_SUCCESS(4727): Microsoft-Windows-Security-Auditing: WIN-SERVER: INFO: A security-enabled global group was created."

# Security Auditing (9 reglas)
test_rule "100041" "Audit Policy Changed" "2026 Mar 12 10:00:00 WinEvtLog: Security: AUDIT_SUCCESS(4719): Microsoft-Windows-Security-Auditing: WIN-SERVER: INFO: System audit policy was changed."

# Special Logon (3 reglas)
test_rule "100037" "Special Privileges Assigned" "2026 Mar 12 10:00:00 WinEvtLog: Security: AUDIT_SUCCESS(4672): Microsoft-Windows-Security-Auditing: WIN-SERVER: INFO: Special privileges assigned to new logon."

# Session Management (4 reglas)
test_rule "100043" "RDP Reconnection" "2026 Mar 12 10:00:00 WinEvtLog: Security: AUDIT_SUCCESS(4778): Microsoft-Windows-Security-Auditing: WIN-SERVER: INFO: A session was reconnected to a Window Station."

test_rule "100044" "RDP Disconnection" "2026 Mar 12 10:00:00 WinEvtLog: Security: AUDIT_SUCCESS(4779): Microsoft-Windows-Security-Auditing: WIN-SERVER: INFO: A session was disconnected from a Window Station."

# Object Access (24 reglas)
test_rule "100051" "File System Access" "2026 Mar 12 10:00:00 WinEvtLog: Security: AUDIT_SUCCESS(4663): Microsoft-Windows-Security-Auditing: WIN-SERVER: INFO: An attempt was made to access an object."

# Scheduled Tasks (1 regla)
test_rule "100078" "Scheduled Task Created" "2026 Mar 12 10:00:00 WinEvtLog: Security: AUDIT_SUCCESS(4698): Microsoft-Windows-Security-Auditing: WIN-SERVER: INFO: A scheduled task was created."

echo ""
echo -e "${GREEN}[INFO]${NC} Tests de custom_windows_security_rules.xml completados"
echo ""

# ============================================================================
# TESTS: CUSTOM_WINDOWS_OVERRIDES.XML (5 reglas)
# ============================================================================

echo -e "${CYAN}>>> Testing custom_windows_overrides.xml (5 reglas)${NC}"
echo ""

# Override de Event 4724
test_rule "60103" "Password Reset (Override)" "2026 Mar 12 10:00:00 WinEvtLog: Security: AUDIT_SUCCESS(4724): Microsoft-Windows-Security-Auditing: WIN-SERVER: INFO: An attempt was made to reset an account's password."

# Regla CRÍTICA - Limpieza de logs
test_rule "100101" "Security Log Clearing (CRITICAL)" "2026 Mar 12 10:00:00 WinEvtLog: Security: AUDIT_SUCCESS(1102): Microsoft-Windows-Eventlog: WIN-SERVER: INFO: The audit log was cleared."

echo ""
echo -e "${GREEN}[INFO]${NC} Tests de custom_windows_overrides.xml completados"
echo ""

# ============================================================================
# TESTS: CUSTOM_LINUX_SECURITY_RULES.XML (7 reglas)
# ============================================================================

echo -e "${CYAN}>>> Testing custom_linux_security_rules.xml (7 reglas - cobertura base)${NC}"
echo ""

# PAM Root Authentication
test_rule "100103" "PAM Root Session" "2026 Mar 12 10:00:00 wazuh-server systemd: pam_unix(systemd-user:session): session opened for user root by (uid=0)"

# Non-nominal accounts (requiere CDB list)
test_rule "200001" "Non-nominal Account Login" "2026 Mar 12 10:00:00 wazuh-server sshd[12345]: Accepted password for admin from 192.168.1.100 port 22 ssh2"

test_rule "200002" "Sudo by Non-nominal Account" "2026 Mar 12 10:00:00 wazuh-server sudo: test : TTY=pts/0 ; PWD=/home/test ; USER=root ; COMMAND=/bin/bash"

echo ""
echo -e "${GREEN}[INFO]${NC} Tests de custom_linux_security_rules.xml completados"
echo ""

# ============================================================================
# RESUMEN FINAL
# ============================================================================

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  RESUMEN DE TESTS${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "Total tests ejecutados: ${CYAN}${TOTAL_TESTS}${NC}"
echo -e "Tests pasados:          ${GREEN}${PASSED_TESTS}${NC}"
echo -e "Tests fallidos:         ${RED}${FAILED_TESTS}${NC}"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}✓ TODOS LOS TESTS PASARON EXITOSAMENTE${NC}"
    echo ""
    exit 0
else
    percentage=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    echo -e "${YELLOW}⚠ ${FAILED_TESTS} tests fallaron (${percentage}% éxito)${NC}"
    echo ""
    echo "Posibles causas de fallo:"
    echo "  - Reglas no cargadas en Wazuh Manager"
    echo "  - CDB list no compilada (afecta reglas 200001, 200002 y 200006)"
    echo "  - Formato de log no coincide exactamente"
    echo "  - Dependencias de reglas base no cumplidas (if_sid>60100)"
    echo ""
    exit 1
fi
