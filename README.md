# Wazuh Custom Rules & Teams Integration

**Sistema completo de reglas personalizadas y integración con Microsoft Teams para Wazuh SIEM**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Wazuh Version](https://img.shields.io/badge/Wazuh-4.x-blue)](https://wazuh.com/)
[![Platform](https://img.shields.io/badge/Platform-Linux-lightgrey)](https://www.linux.org/)

## Estado del Proyecto

**Versión en Producción:** Script de integración Teams simple y funcional
- **Ubicación Remota:** `/root/wazuh-teams/custom-teams.py` (en máquina 10.27.20.171)
- **Estado:** Operativo y probado en ambiente productivo
- **Procesamiento:** Real-time, alerta por alerta
- **Nota:** Este repositorio contiene versiones mejoradas del script base no aún desplegadas

## 📋 Descripción

La integración actual proporciona:
- **Script de integración Microsoft Teams** funcional y estable
- **Procesamiento individual de alertas** con envío inmediato
- **Tarjetas Adaptive Card** con formato enriquecido
- **Links dinámicos al Dashboard Wazuh** para cada alerta
- **Validación de integridad** de alertas y webhooks

## 🎯 Características Implementadas

### ✅ Integración Teams (Versión Actual)

- **Procesamiento Real-time**: Cada alerta se envía inmediatamente a Teams
- **Adaptive Cards**: Tarjetas formateadas con niveles de severidad
- **Dashboard Integration**: Enlaces directos al Wazuh Dashboard (192.168.30.2)
- **VirusTotal Integration**: Incluye links si están disponibles en los datos
- **Logging**: Registro a `/var/ossec/logs/integrations.log`
- **Validación**: Verifica webhook URL y formato de alertas

### 📝 Campos en Cada Alerta

- Nivel y Prioridad (CRITICAL/HIGH/MEDIUM/LOW)
- ID de Regla y Descripción
- Grupos de Detección
- Agente (nombre e IP)
- Timestamp de la Alerta
- Alert ID único
- VirusTotal permalink (si aplica)
- Full Log con truncamiento automático

## 📊 Implementación

| Aspecto | Estado |
|--------|--------|
| Procesamiento | Real-time individual |
| Caché | Ninguno (sin acumulación) |
| Retry logic | Básico (timeout 30s) |
| Logging | Sí, archivo + stdout |
| Dashboard | Sí, links dinámicos |
| VirusTotal | Sí, si disponible |

## 🚀 Instalación Rápida

### Prerrequisitos

- Wazuh Manager 4.x instalado
- Acceso root al servidor
- Cuenta de Microsoft Teams con Power Automate
- Webhook URL de Power Automate

### Paso 1: Descargar e Instalar Script de Integración

```bash
# Conectar al servidor Wazuh
ssh root@<WAZUH-SERVER-IP>
# Ejemplo: ssh root@10.27.20.171

# Copiar el script de integración
cd /var/ossec/integrations/
wget https://raw.githubusercontent.com/mateovillablanca/wazuh-custom-rules-teams/main/integrations/custom-teams-summary.py

# Dar permisos
chmod 750 custom-teams-summary.py
chown root:wazuh custom-teams-summary.py
```

### Paso 2: Configurar Webhook en Wazuh

```bash
# Editar ossec.conf
nano /var/ossec/etc/ossec.conf

# Agregar esta integración (antes de </ossec_config>):
```

```xml
<integration>
  <name>custom-teams-summary</name>
  <hook_url>https://prod-XX.logic.azure.com/workflows/...</hook_url>
  <level>11</level>
  <alert_format>json</alert_format>
</integration>
```

```bash
# Reiniciar Wazuh
systemctl restart wazuh-manager

# Verificar estado
systemctl status wazuh-manager
```

### Paso 3: Probar la Integración

```bash
# Generar una alerta de prueba
# Las alertas se enviarán automáticamente a Teams según la configuración de nivel
```

## 📁 Estructura del Proyecto

```text
wazuh-custom-rules-teams/
├── README.md                   # Este archivo
├── CHANGELOG.md               # Historial de cambios
├── STRUCTURE.md               # Mapa de navegación
├── LICENSE                    # MIT License
├── integrations/
│   ├── custom-teams-summary.py    # Script de integración actual (v4.1)
│   └── custom-teams-summary-FIXED.py # Versión mejorada (experimental)
├── docs/                      # Documentación adicional
│   ├── INSTALLATION.md        # Guía de instalación
│   ├── COMPARATIVO_ANTES_DESPUES.md
│   └── otros archivos...
├── examples/                  # Ejemplos de configuración
├── rules/                     # Referencia histórica
└── scripts/                   # Scripts de prueba y utilidades
```

**Nota:** La versión productiva (`custom-teams.py`) está simplificada. Las versiones mejoradas con acumulación de alertas y retry logic están en desarrollo pero no desplegadas aún.

## 🔍 Reglas Destacadas

### 🔴 Nivel CRÍTICO (15)

```xml
<!-- 100036: Mimikatz Detection -->
<rule id="100036" level="15">
  <if_sid>60000</if_sid>
  <field name="win.eventdata.objectName">lsass.exe</field>
  <field name="win.eventdata.processName">mimikatz|procdump</field>
  <description>Mimikatz detectado | Mimikatz credential dumping detected</description>
  <mitre>
    <id>T1003.001</id>
    <id>T1003</id>
  </mitre>
</rule>

<!-- 100101: Security Log Cleared -->
<rule id="100101" level="15">
  <if_sid>18101</if_sid>
  <field name="win.system.eventID">^1102$</field>
  <description>Log de eventos de seguridad limpiado | Windows Security log cleared</description>
  <mitre>
    <id>T1070.001</id>
  </mitre>
</rule>
```

### 🟠 Nivel MUY ALTO (12-13)

```xml
<!-- 100040: User Account Created -->
<rule id="100040" level="12">
  <if_sid>60103</if_sid>
  <field name="win.system.eventID">^4720$</field>
  <description>Cuenta de usuario creada | User account created</description>
  <mitre>
    <id>T1136.001</id>
  </mitre>
</rule>

<!-- 100048: Domain Admins Membership -->
<rule id="100048" level="15">
  <if_sid>60100</if_sid>
  <field name="win.eventdata.memberName">Domain Admins</field>
  <description>Usuario añadido a Domain Admins | User added to Domain Admins group</description>
  <mitre>
    <id>T1098</id>
  </mitre>
</rule>
```

## 🔄 Flujo de la Integración

1. **Wazuh detecta alerta** → Alert level ≥ 11 (configurable)
2. **Ejecuta integración** → Script `custom-teams-summary.py`
3. **Valida alerta** → Verifica formato JSON y estructura
4. **Construye tarjeta** → Formato Adaptive Card
5. **Envía a Teams** → POST a webhook URL
6. **Logging** → Registra resultado en `/var/ossec/logs/integrations.log`

## 📊 Ejemplo de Alerta en Teams

```
┌─────────────────────────────────────────────┐
│ ⚠ HIGH WAZUH ALERT                         │
├─────────────────────────────────────────────┤
│ Level:       HIGH (11)                      │
│ Rule ID:     100006                         │
│ Description: Kerberos authentication failed│
│ Groups:      authentication, account_change│
│ Agent:       DC01 (192.168.1.10)            │
│ Timestamp:   2026-03-17 14:30:45           │
│ Alert ID:    1710691445.123456             │
│ VirusTotal:  [link] (si aplica)            │
│                                             │
│ Full Log:                                   │
│ Event ID: 4771                              │
│ Account Name: testuser@contoso.com          │
│ Failure Code: 0x18                          │
│                                             │
│ [📊 Dashboard] [🔗 VirusTotal]             │
└─────────────────────────────────────────────┘
```

## 🎛️ Configuración del Script

El script de integración ubicado en `/var/ossec/integrations/custom-teams-summary.py` incluye:

**Constantes Configurables:**
- `LOG_FILE`: Ubicación del log de integración
- `DASHBOARD_BASE`: URL base del Dashboard Wazuh (actualmente: `https://192.168.30.2`)
- `USER_AGENT`: Identificador de la integración

**Validaciones:**
- Verifica que el archivo de alerta exista y tenga extensión `.alert`
- Valida que el webhook sea de un proveedor permitido (Power Automate, Azure Logic Apps)
- Filtra alertas por nivel mínimo

**Procesamiento:**
- Formatea timestamps a ISO format con timezone
- Asigna colores según severidad (CRITICAL -> rojo, HIGH -> naranja, etc.)
- Trunca logs largos automáticamente
- Incluye botones para acceder al Dashboard y VirusTotal (si aplica)

## 🐛 Troubleshooting

### Problema: Webhook retorna 404

**Causa**: URL expirada o flujo deshabilitado en Power Automate  

**Solución**:
1. Verifica que el flujo esté **activado** en Power Automate
2. Regenera el webhook si es necesario
3. Actualiza en `/var/ossec/etc/ossec.conf`
4. Reinicia: `systemctl restart wazuh-manager`

### Problema: No llegan alertas a Teams

**Diagnóstico**:
```bash
# Ver logs de integración
tail -50 /var/ossec/logs/integrations.log

# Ver alertas generadas en el sistema
tail -50 /var/ossec/logs/alerts/alerts.json | jq '.[] | select(.rule.level >= 11)'

# Probar la integración manualmente
python3 << 'EOF'
import json
from /var/ossec/integrations/custom-teams-summary import Integration

alert = {"rule": {"level": 11, "id": "100006"}, "agent": {"name": "test"}}
webhook = "TU-WEBHOOK-URL"
Integration("test.alert", webhook, 11).run()
EOF
```

### Problema: Script genera error 403

**Causa**: Webhook URL bloqueado o credenciales inválidas

**Solución**:
```bash
# Verificar permisos del archivo
ls -l /var/ossec/integrations/custom-teams-summary.py

# Verificar que el usuario wazuh tiene permisos
chown root:wazuh /var/ossec/integrations/custom-teams-summary.py
chmod 750 /var/ossec/integrations/custom-teams-summary.py

# Reiniciar el servicio
systemctl restart wazuh-manager
```

Para más ayuda, consultar logs en `/var/ossec/logs/integrations.log`

## 📝 Changelog

### v4.1 (2026-03-09)
- ✅ Script de integración Teams simplificado y estable
- ✅ Procesamiento real-time de alertas
- ✅ Adaptive Card formatting con Dashboard links
- ✅ Validación de integridad de alertas
- ✅ Logging a archivo y stdout
- ✅ VirusTotal integration cuando aplica

## 📄 Licencia

Este proyecto está bajo la Licencia MIT - ver [LICENSE](LICENSE) para detalles.

## 👤 Autor

**Mateo Villablanca**
- GitHub: [@mvillablanca](https://github.com/WhiteMooncy)

## Herramientas Utilizadas

- [Wazuh](https://wazuh.com/) - Plataforma SIEM open-source
- [Microsoft Teams](https://www.microsoft.com/microsoft-teams/) - Plataforma de comunicación
- [MITRE ATT&CK](https://attack.mitre.org/) - Framework de técnicas de atacantes

---
**⭐ Si este proyecto te fue útil, considera darle una estrella en GitHub**
