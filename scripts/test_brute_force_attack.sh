#!/bin/bash
################################################################################
# Script de Testing: Brute Force Attack Detection
# Autor: SOC Team
# Fecha: 2026-03-12
# Descripción: Simula ataques de fuerza bruta para probar reglas 200004/200005
################################################################################

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuración por defecto
DEFAULT_ATTEMPTS=6
DEFAULT_INTERVAL=2
DEFAULT_USER="admin"
DEFAULT_IP="192.168.X.X"  # Reemplazar con la IP de la máquina atacante

# Mostrar banner
show_banner() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║     WAZUH BRUTE FORCE ATTACK SIMULATION TEST SUITE        ║"
    echo "║                    SOC Testing Tool                        ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Mostrar ayuda
show_help() {
    cat << EOF
${YELLOW}USO:${NC}
    $0 [OPCIONES]

${YELLOW}OPCIONES:${NC}
    -a, --attempts NUM      Número de intentos de login (default: $DEFAULT_ATTEMPTS)
    -i, --interval SEC      Intervalo entre intentos en segundos (default: $DEFAULT_INTERVAL)
    -u, --user USERNAME     Usuario para simular login (default: $DEFAULT_USER)
    -s, --srcip IP          IP de origen simulada (default: $DEFAULT_IP)
    -t, --type TYPE         Tipo de test: ssh|windows|both (default: ssh)
    -v, --verify            Solo verificar alertas sin generar nuevas
    -h, --help              Mostrar esta ayuda

${YELLOW}EJEMPLOS:${NC}
    # Test básico (6 intentos con admin)
    $0

    # Test con 10 intentos, intervalo de 1 segundo
    $0 -a 10 -i 1

    # Test con usuario 'test' desde IP diferente
    $0 -u test -s 192.168.1.50

    # Solo verificar alertas existentes
    $0 -v

${YELLOW}REGLAS PROBADAS:${NC}
    - Rule 200001: SSH logon con cuenta no-nominal (Nivel 11)
    - Rule 200004: Múltiples logins SSH - CRÍTICO (Nivel 15, freq: 5 en 120s)
    - Rule 200002: Windows logon con cuenta no-nominal (Nivel 12)
    - Rule 200005: Múltiples logins Windows - CRÍTICO (Nivel 15, freq: 5 en 120s)

EOF
}

# Parse argumentos
ATTEMPTS=$DEFAULT_ATTEMPTS
INTERVAL=$DEFAULT_INTERVAL
USER=$DEFAULT_USER
SRCIP=$DEFAULT_IP
TYPE="ssh"
VERIFY_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--attempts)
            ATTEMPTS="$2"
            shift 2
            ;;
        -i|--interval)
            INTERVAL="$2"
            shift 2
            ;;
        -u|--user)
            USER="$2"
            shift 2
            ;;
        -s|--srcip)
            SRCIP="$2"
            shift 2
            ;;
        -t|--type)
            TYPE="$2"
            shift 2
            ;;
        -v|--verify)
            VERIFY_ONLY=true
            shift
            ;;
        -h|--help)
            show_banner
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Opción desconocida: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Función para generar logins SSH
generate_ssh_logins() {
    echo -e "${BLUE}🚀 GENERANDO INTENTOS DE LOGIN SSH${NC}"
    echo -e "${CYAN}╭────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│ Usuario:   $USER"
    echo -e "${CYAN}│ IP Origen: $SRCIP"
    echo -e "${CYAN}│ Intentos:  $ATTEMPTS"
    echo -e "${CYAN}│ Intervalo: ${INTERVAL}s"
    echo -e "${CYAN}╰────────────────────────────────────────╯${NC}"
    echo ""

    for i in $(seq 1 $ATTEMPTS); do
        logger -p authpriv.notice -t sshd "Accepted password for $USER from $SRCIP port 22 ssh2"
        echo -e "${GREEN}  ✓${NC} Login $i/$ATTEMPTS generado - $(date '+%H:%M:%S')"
        
        if [ $i -lt $ATTEMPTS ]; then
            sleep $INTERVAL
        fi
    done
}

# Función para verificar alertas
verify_alerts() {
    echo -e "\n${BLUE}📊 VERIFICACIÓN DE ALERTAS${NC}"
    echo -e "${CYAN}════════════════════════════════════════${NC}\n"

    # Contar alertas individuales (Rule 200001)
    INDIVIDUAL_COUNT=$(tail -200 /var/ossec/logs/alerts/alerts.log | grep -c "Rule: 200001" 2>/dev/null || echo "0")
    echo -e "${YELLOW}1. Alertas individuales (Rule 200001):${NC} $INDIVIDUAL_COUNT"
    
    if [ $INDIVIDUAL_COUNT -gt 0 ]; then
        echo -e "${GREEN}   ✓ Detección de cuentas no-nominales funcionando${NC}"
    else
        echo -e "${RED}   ✗ No se detectaron alertas individuales${NC}"
    fi

    echo ""

    # Verificar alerta de correlación (Rule 200004)
    if tail -200 /var/ossec/logs/alerts/alerts.log | grep -q "Rule: 200004"; then
        echo -e "${YELLOW}2. Alerta de correlación (Rule 200004):${NC} ${GREEN}✓ DETECTADA${NC}"
        echo -e "\n${CYAN}   Detalles de la alerta CRÍTICA:${NC}"
        tail -200 /var/ossec/logs/alerts/alerts.log | grep -A 5 "Rule: 200004" | tail -6 | sed 's/^/   /'
        
        # Verificar envío a Teams
        echo -e "\n${YELLOW}3. Envío a Microsoft Teams:${NC}"
        if tail -50 /var/ossec/logs/integrations.log 2>/dev/null | grep -q "Message sent successfully"; then
            LAST_SEND=$(tail -50 /var/ossec/logs/integrations.log 2>/dev/null | grep "sent successfully" | tail -1)
            echo -e "${GREEN}   ✓ $LAST_SEND${NC}"
        else
            echo -e "${RED}   ✗ No se encontró confirmación de envío reciente${NC}"
        fi
    else
        echo -e "${YELLOW}2. Alerta de correlación (Rule 200004):${NC} ${RED}✗ NO DETECTADA${NC}"
        echo -e "${RED}   Posibles causas:${NC}"
        echo -e "${RED}   - Menos de 5 intentos en ventana de 120 segundos${NC}"
        echo -e "${RED}   - IPs de origen diferentes (debe ser mismo IP)${NC}"
        echo -e "${RED}   - Esperar más tiempo para procesamiento${NC}"
    fi

    echo -e "\n${CYAN}════════════════════════════════════════${NC}"
}

# Función principal
main() {
    show_banner

    if [ "$VERIFY_ONLY" = true ]; then
        verify_alerts
        exit 0
    fi

    # Verificar permisos
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Error: Este script requiere permisos de root${NC}"
        echo "Ejecutar: sudo $0"
        exit 1
    fi

    # Mostrar advertencia
    echo -e "${YELLOW}⚠️  ADVERTENCIA:${NC} Este script generará alertas de seguridad en Wazuh"
    echo -e "   y enviará notificaciones a Microsoft Teams."
    echo ""
    read -p "¿Continuar? (s/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[SsYy]$ ]]; then
        echo -e "${RED}Operación cancelada${NC}"
        exit 0
    fi

    echo ""

    # Generar logins según tipo
    case $TYPE in
        ssh)
            generate_ssh_logins
            ;;
        windows)
            echo -e "${YELLOW}Nota: Simulación Windows no implementada (requiere agente Windows)${NC}"
            exit 1
            ;;
        both)
            generate_ssh_logins
            echo -e "${YELLOW}Nota: Simulación Windows no implementada${NC}"
            ;;
        *)
            echo -e "${RED}Error: Tipo desconocido: $TYPE${NC}"
            exit 1
            ;;
    esac

    # Esperar procesamiento
    echo -e "\n${YELLOW}⏳ Esperando procesamiento de Wazuh (5 segundos)...${NC}"
    sleep 5

    # Verificar resultados
    verify_alerts

    # Resumen final
    echo -e "\n${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║          TEST COMPLETADO               ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo -e "\n${CYAN}Verifica tu canal de Teams para la alerta CRÍTICA${NC}"
    echo -e "${CYAN}Log completo: /var/ossec/logs/alerts/alerts.log${NC}\n"
}

# Ejecutar
main
