#!/bin/bash
################################################################################
# Script de Testing: Remote Brute Force Attack Simulation
# Autor: SOC Team
# Fecha: 2026-03-12
# Descripción: Simula ataques de fuerza bruta SSH REALES desde máquina remota
# Ejecutar desde: Una máquina Linux EXTERNA (no el servidor Wazuh)
################################################################################

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuración por defecto
DEFAULT_TARGET="192.168.X.X"  # Reemplazar con tu Wazuh server IP
DEFAULT_USER="admin"
DEFAULT_PASSWORD="wrongpass"
DEFAULT_ATTEMPTS=6
DEFAULT_INTERVAL=2

# Mostrar banner
show_banner() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║   WAZUH BRUTE FORCE ATTACK - REMOTE SIMULATION (SSH)     ║"
    echo "║              Real SSH attempts from client                 ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Mostrar ayuda
show_help() {
    cat << EOF
${YELLOW}USO:${NC}
    $0 [OPCIONES]

${YELLOW}DESCRIPCIÓN:${NC}
    Este script debe ejecutarse desde una máquina Linux EXTERNA (no el servidor Wazuh)
    para simular un ataque de fuerza bruta REAL hacia tu servidor Wazuh.
    
    Genera intentos SSH reales que serán detectados por Wazuh.

${YELLOW}OPCIONES:${NC}
    -t, --target IP         IP del servidor Wazuh objetivo (default: $DEFAULT_TARGET)
    -u, --user USERNAME     Usuario para intentar login (default: $DEFAULT_USER)
    -p, --password PASS     Password a usar (default: $DEFAULT_PASSWORD)
    -a, --attempts NUM      Número de intentos (default: $DEFAULT_ATTEMPTS)
    -i, --interval SEC      Intervalo entre intentos en segundos (default: $DEFAULT_INTERVAL)
    -h, --help              Mostrar esta ayuda

${YELLOW}EJEMPLOS:${NC}
    # Test básico (6 intentos con admin)
    $0

    # Test con 10 intentos rápidos
    $0 -a 10 -i 1

    # Test con usuario 'test'
    $0 -u test

    # Test hacia diferente servidor
    $0 -t 192.168.1.100 -u administrator

${YELLOW}REGLAS QUE SE DISPARARÁN:${NC}
    - Rule 5715: sshd: authentication success
    - Rule 200001: SSH logon with non-nominal account (Nivel 11)
    - Rule 200004: Multiple SSH logins - CRÍTICO (Nivel 15, freq: 5 en 120s)
    
${YELLOW}PREREQUISITOS:${NC}
    - sshpass instalado: sudo apt install sshpass
    - Acceso de red al servidor Wazuh
    - Ejecutar desde una máquina externa diferente al servidor Wazuh

${YELLOW}IMPORTANTE:${NC}
    Este script usa passwords incorrectos a propósito para simular
    un ataque de fuerza bruta. Los intentos fallarán en SSH pero
    generarán alertas en Wazuh.

EOF
}

# Verificar prerequisitos
check_requirements() {
    if ! command -v sshpass &> /dev/null; then
        echo -e "${RED}Error: sshpass no está instalado${NC}"
        echo -e "${YELLOW}Instalar con: sudo apt install sshpass${NC}"
        exit 1
    fi
    
    if ! command -v ssh &> /dev/null; then
        echo -e "${RED}Error: ssh no está instalado${NC}"
        exit 1
    fi
}

# Parse argumentos
TARGET=$DEFAULT_TARGET
USER=$DEFAULT_USER
PASSWORD=$DEFAULT_PASSWORD
ATTEMPTS=$DEFAULT_ATTEMPTS
INTERVAL=$DEFAULT_INTERVAL

while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--target)
            TARGET="$2"
            shift 2
            ;;
        -u|--user)
            USER="$2"
            shift 2
            ;;
        -p|--password)
            PASSWORD="$2"
            shift 2
            ;;
        -a|--attempts)
            ATTEMPTS="$2"
            shift 2
            ;;
        -i|--interval)
            INTERVAL="$2"
            shift 2
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

# Función para ejecutar ataque SSH
execute_ssh_attack() {
    echo -e "${BLUE}🔥 EJECUTANDO ATAQUE SSH DE FUERZA BRUTA${NC}"
    echo -e "${CYAN}╭────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│ Atacante:   $(hostname) ($(hostname -I | awk '{print $1}'))"
    echo -e "${CYAN}│ Objetivo:   $TARGET"
    echo -e "${CYAN}│ Usuario:    $USER"
    echo -e "${CYAN}│ Intentos:   $ATTEMPTS"
    echo -e "${CYAN}│ Intervalo:  ${INTERVAL}s"
    echo -e "${CYAN}╰────────────────────────────────────────╯${NC}"
    echo ""
    
    # Verificar conectividad
    echo -e "${YELLOW}Verificando conectividad con $TARGET...${NC}"
    if ! ping -c 1 -W 2 $TARGET &> /dev/null; then
        echo -e "${RED}✗ No hay conectividad con $TARGET${NC}"
        echo -e "${YELLOW}Continuando de todas formas...${NC}\n"
    else
        echo -e "${GREEN}✓ Conectividad OK${NC}\n"
    fi
    
    SUCCESS_COUNT=0
    FAIL_COUNT=0
    
    for i in $(seq 1 $ATTEMPTS); do
        TIMESTAMP=$(date '+%H:%M:%S')
        
        # Intentar SSH con sshpass (probablemente fallará con password incorrecto)
        # Usamos StrictHostKeyChecking=no para evitar prompts
        # También usamos un timeout corto
        # IMPORTANTE: NO usar BatchMode=yes porque desactiva password authentication
        sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no \
                                    -o UserKnownHostsFile=/dev/null \
                                    -o ConnectTimeout=5 \
                                    -o PreferredAuthentications=password \
                                    -o NumberOfPasswordPrompts=1 \
                                    ${USER}@${TARGET} "echo test" 2>&1 | grep -q "successfully"
        
        RESULT=$?
        
        if [ $RESULT -eq 0 ]; then
            echo -e "${GREEN}  ✓${NC} Intento $i/$ATTEMPTS - ${TIMESTAMP} - ${GREEN}SUCCESS${NC}"
            ((SUCCESS_COUNT++))
        else
            echo -e "${YELLOW}  ⚠${NC} Intento $i/$ATTEMPTS - ${TIMESTAMP} - ${RED}FAILED${NC} (esperado para test)"
            ((FAIL_COUNT++))
        fi
        
        # Esperar intervalo (excepto en última iteración)
        if [ $i -lt $ATTEMPTS ]; then
            sleep $INTERVAL
        fi
    done
    
    echo ""
    echo -e "${CYAN}════════════════════════════════════════${NC}"
    echo -e "${YELLOW}Resumen:${NC}"
    echo -e "  Intentos totales: $ATTEMPTS"
    echo -e "  Exitosos: ${GREEN}$SUCCESS_COUNT${NC}"
    echo -e "  Fallidos: ${RED}$FAIL_COUNT${NC}"
    echo -e "${CYAN}════════════════════════════════════════${NC}"
}

# Función para mostrar instrucciones de verificación
show_verification_instructions() {
    echo -e "\n${BLUE}📊 VERIFICACIÓN DE ALERTAS EN WAZUH${NC}"
    echo -e "${CYAN}════════════════════════════════════════${NC}\n"
    
    echo -e "${YELLOW}Conectarse al servidor Wazuh para verificar:${NC}"
    echo -e "  ${CYAN}ssh root@${TARGET}${NC}\n"
    
    echo -e "${YELLOW}1. Ver alertas generadas:${NC}"
    echo -e "  ${CYAN}tail -50 /var/ossec/logs/alerts/alerts.log | grep -A 5 'Rule: 200001'${NC}\n"
    
    echo -e "${YELLOW}2. Ver alerta de correlación CRÍTICA:${NC}"
    echo -e "  ${CYAN}tail -100 /var/ossec/logs/alerts/alerts.log | grep -A 5 'Rule: 200004'${NC}\n"
    
    echo -e "${YELLOW}3. Verificar envío a Teams:${NC}"
    echo -e "  ${CYAN}tail -20 /var/ossec/logs/integrations.log${NC}\n"
    
    echo -e "${YELLOW}4. Contar alertas de este ataque:${NC}"
    echo -e "  ${CYAN}grep 'srcip.*$(hostname -I | awk '{print $1}')' /var/ossec/logs/alerts/alerts.log | tail -10${NC}\n"
    
    echo -e "${GREEN}✓ Los intentos SSH se registrarán en /var/log/auth.log del servidor${NC}"
    echo -e "${GREEN}✓ Wazuh detectará los logins y generará alertas${NC}"
    echo -e "${GREEN}✓ Con ≥5 intentos en 120s, se disparará Rule 200004 (CRÍTICO)${NC}\n"
}

# Función principal
main() {
    show_banner
    
    # Verificar prerequisitos
    check_requirements
    
    # Obtener IP del atacante
    ATTACKER_IP=$(hostname -I | awk '{print $1}')
    
    # Validar que no estemos en el servidor Wazuh
    if [ "$ATTACKER_IP" == "$TARGET" ]; then
        echo -e "${RED}⚠️  ADVERTENCIA: Estás ejecutando desde el servidor Wazuh${NC}"
        echo -e "${YELLOW}Este script está diseñado para ejecutarse desde una máquina EXTERNA${NC}"
        echo -e "${YELLOW}desde una máquina EXTERNA (no el servidor Wazuh)${NC}\n"
        read -p "¿Continuar de todas formas? (s/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[SsYy]$ ]]; then
            echo -e "${RED}Operación cancelada${NC}"
            exit 0
        fi
    fi
    
    # Mostrar advertencia
    echo -e "${YELLOW}⚠️  ADVERTENCIA DE SEGURIDAD:${NC}"
    echo -e "   Este script realizará intentos SSH REALES hacia $TARGET"
    echo -e "   Generará alertas de seguridad en Wazuh y Microsoft Teams"
    echo -e "   IP atacante que aparecerá en logs: ${CYAN}$ATTACKER_IP${NC}\n"
    
    read -p "¿Continuar con el ataque simulado? (s/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[SsYy]$ ]]; then
        echo -e "${RED}Operación cancelada${NC}"
        exit 0
    fi
    
    echo ""
    
    # Ejecutar ataque
    execute_ssh_attack
    
    # Mostrar instrucciones de verificación
    show_verification_instructions
    
    # Resumen final
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║       ATAQUE SIMULADO COMPLETADO      ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo -e "\n${CYAN}Espera 10-15 segundos para que Wazuh procese las alertas${NC}"
    echo -e "${CYAN}Luego verifica tu canal de Teams para la alerta CRÍTICA${NC}\n"
}

# Ejecutar
main
