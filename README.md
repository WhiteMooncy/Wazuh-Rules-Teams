# Wazuh Custom Rules & Teams Integration

**Sistema completo de reglas personalizadas y integración con Microsoft Teams para Wazuh SIEM**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Wazuh Version](https://img.shields.io/badge/Wazuh-4.x-blue)](https://wazuh.com/)
[![Platform](https://img.shields.io/badge/Platform-Linux-lightgrey)](https://www.linux.org/)

## 📋 Descripción

Este proyecto proporciona una implementación completa de:
- **98 reglas custom** factorizadas en 3 archivos especializados:
  - **Windows Security** (89 reglas): Eventos críticos de seguridad Windows
  - **Windows Overrides** (5 reglas): Ajustes de severidad y correlaciones
  - **Linux Security** (4 reglas): Autenticación SSH y cuentas no-nominales
- **CDB Lists**: Sistema de listas para detección de cuentas genéricas
- **Integración inteligente con Microsoft Teams** usando Power Automate
- **Sistema de resúmenes acumulativos** (envío cada 3 alertas o 24 horas)
- **Alertas críticas inmediatas** (nivel ≥15)
- **Reducción de ruido del 80%** (de ~40 alertas/día a ~5-8)

## 🎯 Características Principales

### ✅ Arquitectura Factorizada v2.0

Las reglas están organizadas en **3 archivos especializados** para mejor mantenimiento:

#### 1️⃣ custom_windows_security_rules.xml (89 reglas)
**Propósito:** Eventos críticos de seguridad Windows no cubiertos por reglas base

**Categorías:**

**Categorías:**
- **Kerberos Authentication** (6 reglas): TGT, Service Tickets, Kerberoasting
- **Service Installation** (2 reglas): Servicios sospechosos, persistencia
- **Process Execution** (5 reglas): CMD, PowerShell, WScript, RegEdit, Net.exe
- **Credential Access** (2 reglas): LSASS, Mimikatz
- **Account Management** (15 reglas): Creación, modificación, grupos privilegiados
- **Password Operations** (4 reglas): Cambios y resets de contraseñas
- **Group Policy** (2 reglas): GPO modifications, MSI installs
- **Security Auditing** (9 reglas): Cambios en políticas de auditoría
- **Session Management** (4 reglas): Reconexiones, desconexiones, idle
- **Windows Firewall** (1 regla): Cambios en reglas de firewall
- **Special Logon** (3 reglas): Special privileges assigned
- **Object Access** (24 reglas): File access, registry, removable storage
- **System Security** (4 reglas): Security system extension, state changes
- **Other Security Events** (8 reglas): Token manipulation, filtering, scheduled tasks

**IDs:** 100001-100089 | **Base:** if_sid>60100 (Windows Base)

#### 2️⃣ custom_windows_overrides.xml (5 reglas)
**Propósito:** Ajustes de severidad y correlaciones avanzadas

- **60103**: Override Event 4724 (Password Reset) - Level 4 → 8
- **100101**: Security Log Clearing (**CRÍTICO** - Level 15)
- **100110-100112**: Correlaciones múltiples fallos de autenticación

**Base:** if_sid>60100 | **Nota:** Este archivo incluye reglas que sobrescriben comportamiento base de Wazuh

#### 3️⃣ custom_linux_security_rules.xml (4 reglas)
**Propósito:** Seguridad Linux/Unix y SSH

- **100103**: PAM root authentication (Level 8)
- **200001-200003**: Non-nominal account detection (admin, test, service, etc.)
  - Usa CDB list `/var/ossec/etc/lists/no-nominal-account`
  - Level 10 (Login) y Level 12 (Sudo execution)

**IDs:** 100103, 200001-200003 | **Requisito:** CDB list compilada

### ✅ CDB Lists System

**Archivo:** `no-nominal-account` (8 cuentas genéricas)
- admin, test, administrator, root, service, backup, system, svc
- **Formato:** key:value (compilado a .cdb)
- **Uso:** Detección de inicios de sesión con cuentas compartidas

### ✅ Integración Teams

- **Resúmenes inteligentes**: Acumulación de alertas con estadísticas
- **Alertas críticas**: Envío inmediato para nivel ≥15
- **Adaptive Cards**: Formato rico con MITRE ATT&CK, agentes, niveles
- **Dashboard links**: Botones directos al Wazuh Dashboard
- **Sin emojis**: Compatibilidad total con webhooks corporativos

## 📊 Impacto

| Métrica | Antes | Después | Mejora |
|---------|-------|---------|--------|
| Alertas/día | ~40 | ~5-8 | **80% reducción** |
| Nivel mínimo | 9 | 11 | Menos ruido |
| Formato | Individual | Resúmenes | Menos interrupciones |
| Críticas | Mezcladas | Inmediatas | Mejor respuesta |

## 🚀 Instalación Rápida

### Prerrequisitos

- Wazuh Manager 4.x instalado
- Acceso root al servidor
- Cuenta de Microsoft Teams
- Power Automate (incluido en Microsoft 365)

### Paso 1: Copiar Reglas y CDB Lists

```bash
# Conectar al servidor Wazuh
ssh root@<WAZUH-SERVER-IP>

# Copiar los 3 archivos de reglas custom
cd /var/ossec/etc/rules/
wget https://raw.githubusercontent.com/<TU-USUARIO>/wazuh-custom-rules-teams/main/rules/custom_windows_security_rules.xml
wget https://raw.githubusercontent.com/<TU-USUARIO>/wazuh-custom-rules-teams/main/rules/custom_windows_overrides.xml
wget https://raw.githubusercontent.com/<TU-USUARIO>/wazuh-custom-rules-teams/main/rules/custom_linux_security_rules.xml

# Copiar CDB list
cd /var/ossec/etc/lists/
wget https://raw.githubusercontent.com/<TU-USUARIO>/wazuh-custom-rules-teams/main/lists/no-nominal-account

# Compilar CDB list
/var/ossec/bin/ossec-makelists

# Verificar compilación
ls -lh /var/ossec/etc/lists/no-nominal-account.cdb

# Verificar sintaxis XML
/var/ossec/bin/wazuh-logtest -t
```

### Paso 2: Instalar Scripts de Integración

```bash
# Copiar scripts
cd /var/ossec/integrations/
wget https://raw.githubusercontent.com/<TU-USUARIO>/wazuh-custom-rules-teams/main/integrations/custom-teams-summary.py
wget https://raw.githubusercontent.com/<TU-USUARIO>/wazuh-custom-rules-teams/main/integrations/custom-teams-summary

# Dar permisos
chmod +x custom-teams-summary.py custom-teams-summary
chown root:wazuh custom-teams-summary.py custom-teams-summary
```

### Paso 3: Configurar Power Automate

1. Ve a [Power Automate](https://make.powerautomate.com)
2. **Crear flujo** → **Flujo de nube automatizado**
3. Trigger: **"Cuando se recibe una solicitud HTTP"**
4. Acción: **"Publicar mensaje en un chat o canal"** (Teams)
5. Copiar la **URL HTTP POST**

### Paso 4: Configurar Wazuh

```bash
# Editar ossec.conf
nano /var/ossec/etc/ossec.conf

# Agregar configuración de ruleset (después de otras reglas):
```

```xml
<ossec_config>
  <ruleset>
    <!-- Custom Windows Security Rules (89 rules) -->
    <rule_files>custom_windows_security_rules.xml</rule_files>
    
    <!-- Custom Windows Overrides (5 rules) -->
    <rule_files>custom_windows_overrides.xml</rule_files>
    
    <!-- Custom Linux Security Rules (4 rules) -->
    <rule_files>custom_linux_security_rules.xml</rule_files>
    
    <!-- CDB List for non-nominal accounts -->
    <list>etc/lists/no-nominal-account</list>
  </ruleset>
</ossec_config>
```

```bash
# (OPCIONAL) Agregar integración Teams al final (antes de </ossec_config>):
```

```xml
<integration>
  <name>custom-teams-summary</name>
  <hook_url>TU-WEBHOOK-URL-AQUI</hook_url>
  <level>11</level>
  <alert_format>json</alert_format>
  <options>{"verify_ssl": false}</options>
</integration>
```

```bash
# Reiniciar Wazuh
systemctl restart wazuh-manager

# Verificar estado y reglas cargadas
systemctl status wazuh-manager
grep "Total rules enabled" /var/ossec/logs/ossec.log | tail -1
```

### Paso 5: Probar

```bash
# Descargar script de prueba
cd /tmp
wget https://raw.githubusercontent.com/<TU-USUARIO>/wazuh-custom-rules-teams/main/scripts/test_alerts.sh
chmod +x test_alerts.sh

# Ejecutar (generará 17 alertas de prueba)
./test_alerts.sh
```

## 📁 Estructura del Proyecto

```
wazuh-custom-rules-teams/
├── README.md                                # Documentación principal
├── CHANGELOG.md                             # Historial de cambios
├── LICENSE                                  # Licencia MIT
├── .gitignore                               # Archivos excluidos
│
├── rules/                                   # Reglas de detección (98 reglas)
│   ├── custom_windows_security_rules.xml   # 89 reglas Windows Security
│   ├── custom_windows_overrides.xml        # 5 reglas overrides y correlaciones
│   ├── custom_linux_security_rules.xml     # 4 reglas Linux/SSH
│   ├── local_rules_override.xml            # [DEPRECATED] Versión anterior
│   └── README.md                            # Documentación de reglas
│
├── lists/                                   # CDB Lists
│   ├── no-nominal-account                   # Lista de cuentas genéricas
│   └── README.md                            # Instrucciones de instalación
│
├── integrations/                      # Scripts de integración
│   ├── custom-teams-summary.py              # Script principal Python
│   ├── custom-teams-summary                 # Wrapper bash
│   ├── custom-teams.py                      # Script alternativo
│   └── README.md                            # Documentación integración
│
├── scripts/                           # Utilidades y testing
│   ├── test_alerts.sh                       # Prueba 17 alertas
│   ├── test_all_rules.sh                    # Prueba 35+ alertas
│   ├── migration.sh                         # Script de migración
│   └── README.md                            # Guía de scripts
│
├── docs/                              # Documentación completa
│   ├── INSTALLATION.md                      # Guía de instalación detallada
│   ├── MIGRATION.md                         # Migración entre servidores
│   ├── RULES_REFERENCE.md                   # Referencia completa de reglas
│   ├── TEAMS_SETUP.md                       # Configuración de Teams
│   ├── TROUBLESHOOTING.md                   # Solución de problemas
│   ├── CONTEXTO_WAZUH.md                    # Contexto completo Wazuh
│   └── MANUAL_CONFIGURACION.md              # Manual técnico completo
│
└── examples/                          # Ejemplos de configuración
    ├── ossec.conf.example                   # Configuración ossec.conf
    ├── power_automate_flow.json             # Flujo de Power Automate
    └── adaptive_card_template.json          # Template de Adaptive Card
```

## 📖 Documentación

- **[Instalación Completa](docs/INSTALLATION.md)**: Guía paso a paso desde cero
- **[Migración](docs/MIGRATION.md)**: Mover configuración entre servidores
- **[Referencia de Reglas](docs/RULES_REFERENCE.md)**: Detalle de las 67 reglas
- **[Configuración Teams](docs/TEAMS_SETUP.md)**: Setup completo de Power Automate
- **[Troubleshooting](docs/TROUBLESHOOTING.md)**: Problemas comunes y soluciones

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

## 🎨 Ejemplos de Alertas en Teams

### Resumen Acumulado (Cada 3 alertas o 24h)

```
[MUY ALTO] Resumen de Alertas Wazuh - 24h

Total de Alertas: 5
Periodo: 24h
Nivel Máximo: 13
Agentes Afectados: 2

Distribución por Nivel:
  Nivel 13: 2 alertas
  Nivel 12: 1 alertas
  Nivel 9: 1 alertas

Top 5 Reglas Activadas:
  1. Rule 100006 (1×): Kerberos autenticación fallida - cuenta expirada
  2. Rule 100008 (1×): Servicio sospechoso instalado
  3. Rule 100035 (1×): Acceso a proceso LSASS
  4. Rule 100007 (1×): Servicio nuevo instalado
  5. Rule 5502 (1×): PAM: Login session closed

Top MITRE ATT&CK:
  • T1558 (Steal or Forge Kerberos Tickets)
  • T1543.003 (Create or Modify System Process)
  • T1003.001 (LSASS Memory)

[Ver Dashboard] [Descartar]
```

### Alerta Crítica Inmediata (Nivel ≥15)

```
[CRITICO] ALERTA CRÍTICA WAZUH

ID de Regla: 100101
Nivel: 15
Descripción: Log de seguridad limpiado | Security log cleared
Agente: DC01
Timestamp: 2026-03-11 14:30:45

Técnicas MITRE ATT&CK:
  • T1070.001: Clear Windows Event Logs

Usuario: administrator
IP de Origen: 192.168.1.50
Log: EventChannel

[Ver en Dashboard] [Investigar]
```

## 🔧 Configuración Avanzada

### Ajustar Umbral de Resúmenes

Edita `/var/ossec/integrations/custom-teams-summary.py`:

```python
# Línea ~15
MAX_ALERTS_BEFORE_SUMMARY = 3  # Cambiar a 5, 10, etc.
SUMMARY_INTERVAL_HOURS = 24    # Cambiar a 12, 48, etc.
CRITICAL_LEVEL = 15            # Nivel para envío inmediato
```

### Cambiar Nivel Mínimo

Edita `/var/ossec/etc/ossec.conf`:

```xml
<integration>
  <level>11</level>  <!-- Cambiar a 10, 12, etc. -->
</integration>
```

### Filtrar por Reglas Específicas

```xml
<integration>
  <name>custom-teams-summary</name>
  <hook_url>...</hook_url>
  <level>11</level>
  <rule_id>100001,100036,100101</rule_id>  <!-- Solo estas reglas -->
</integration>
```

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

# Ver alertas generadas
tail -50 /var/ossec/logs/alerts/alerts.json | jq 'select(.rule.level >= 11)'

# Probar manualmente
tail -1 /var/ossec/logs/alerts/alerts.json | \
  /var/ossec/integrations/custom-teams-summary "TU-WEBHOOK-URL"
```

### Problema: Muchas alertas acumuladas

**Solución temporal**:
```bash
# Limpiar caché
rm /var/ossec/logs/teams_alerts_cache.pkl

# O forzar envío
python3 << 'EOF'
import pickle
cache = {'alerts': [], 'last_summary_time': None, 'summary_count': 0}
pickle.dump(cache, open('/var/ossec/logs/teams_alerts_cache.pkl', 'wb'))
EOF
```

Ver [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) para más problemas comunes.

## 🤝 Contribuir

Las contribuciones son bienvenidas. Por favor:

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📝 Changelog

### v1.0.0 (2026-03-11)
- ✅ Implementación inicial de 67 reglas custom
- ✅ Integración con Microsoft Teams
- ✅ Sistema de resúmenes acumulativos
- ✅ Alertas críticas inmediatas
- ✅ Documentación completa
- ✅ Scripts de testing y migración

## 📄 Licencia

Este proyecto está bajo la Licencia MIT - ver [LICENSE](LICENSE) para detalles.

## 👤 Autor

**Mateo Villablanca**
- GitHub: [@mvillablanca](https://github.com/mvillablanca)

## 🙏 Agradecimientos

- [Wazuh](https://wazuh.com/) - Plataforma SIEM open-source
- [Microsoft Teams](https://www.microsoft.com/microsoft-teams/) - Plataforma de comunicación
- [MITRE ATT&CK](https://attack.mitre.org/) - Framework de técnicas de atacantes

## 📞 Soporte

---
**⭐ Si este proyecto te fue útil, considera darle una estrella en GitHub**
