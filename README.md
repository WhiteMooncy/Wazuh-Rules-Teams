# Wazuh Custom Rules & Teams Integration

**Sistema completo de reglas personalizadas y integración con Microsoft Teams para Wazuh SIEM**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Wazuh Version](https://img.shields.io/badge/Wazuh-4.x-blue)](https://wazuh.com/)
[![Platform](https://img.shields.io/badge/Platform-Linux-lightgrey)](https://www.linux.org/)

## Estado del Repositorio

La estructura activa y mantenida está en `Wazuh-Rules-Teams/`.

- Usa `Wazuh-Rules-Teams/` como fuente principal para reglas, scripts, listas y documentación.
- Las carpetas de la raíz (`docs/`, `rules/`, `scripts/`, `integrations/`, `examples/`) son una versión anterior o reducida.
- La guía rápida de navegación está en [STRUCTURE.md](STRUCTURE.md).
- La carpeta vacía `Wazuh-Rules-Teams/Wazuh-Rules-Teams/` no contiene contenido operativo.

## 📋 Descripción

Este proyecto proporciona una implementación completa de:
- **101 reglas custom** organizadas en una versión factorizada dentro de `Wazuh-Rules-Teams/`
- **Integración inteligente con Microsoft Teams** usando Power Automate
- **Sistema de resúmenes acumulativos** (envío cada 3 alertas o 24 horas)
- **Alertas críticas inmediatas** (nivel ≥15)
- **Reducción de ruido del 80%** (de ~40 alertas/día a ~5-8)

## 🎯 Características Principales

### ✅ Reglas Custom (101 totales)

- **Windows Security** (89 reglas): Autenticación, escalación, malware, red, integridad
  - Autenticación y Acceso (200001-200020)
  - Escalación de Privilegios (200021-200040)
  - Detección de Malware/PUA (200041-200070)
  - Detección de Red (200071-200090)
  - Integridad de Sistema (200091-200100)
- **Overrides/Correlación** (5 reglas): Personalización y reducción de falsos positivos
- **Linux Security** (7 reglas): SSH, PAM, autenticación root, correlación cross-platform

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

### Paso 1: Copiar Reglas

```bash
# Conectar al servidor Wazuh
ssh root@<WAZUH-SERVER-IP>
# Ejemplo: ssh root@10.27.20.171

# Copiar reglas custom (reemplaza <GITHUB-USERNAME> con tu usuario de GitHub)
cd /var/ossec/etc/rules/
wget https://raw.githubusercontent.com/<GITHUB-USERNAME>/wazuh-custom-rules-teams/main/rules/custom_windows_security_rules.xml
wget https://raw.githubusercontent.com/<GITHUB-USERNAME>/wazuh-custom-rules-teams/main/rules/local_rules_override.xml

# Ejemplo con usuario real:
# wget https://raw.githubusercontent.com/mateovillablanca/wazuh-custom-rules-teams/main/rules/custom_windows_security_rules.xml

# Verificar sintaxis
/var/ossec/bin/wazuh-logtest -t
```

### Paso 2: Instalar Scripts de Integración

```bash
# Copiar scripts (reemplaza <GITHUB-USERNAME> con tu usuario de GitHub)
cd /var/ossec/integrations/
wget https://raw.githubusercontent.com/<GITHUB-USERNAME>/wazuh-custom-rules-teams/main/integrations/custom-teams-summary.py

# Ejemplo con usuario real:
# wget https://raw.githubusercontent.com/mateovillablanca/wazuh-custom-rules-teams/main/integrations/custom-teams-summary.py

# Dar permisos
chmod 750 custom-teams-summary.py
chown root:wazuh custom-teams-summary.py
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

# Agregar al final (antes de </ossec_config>):
```

```xml
<integration>
  <name>custom-teams-summary</name>
  <hook_url>TU-WEBHOOK-URL-AQUI</hook_url>
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

### Paso 5: Probar

```bash
# Descargar script de prueba (reemplaza <GITHUB-USERNAME> con tu usuario)
cd /tmp
wget https://raw.githubusercontent.com/<GITHUB-USERNAME>/wazuh-custom-rules-teams/main/scripts/test_alerts.sh
chmod +x test_alerts.sh

# Ejemplo:
# wget https://raw.githubusercontent.com/mateovillablanca/wazuh-custom-rules-teams/main/scripts/test_alerts.sh

# Ejecutar (generará alertas de prueba)
./test_alerts.sh
```

## 📁 Estructura del Proyecto

```text
wazuh-custom-rules-teams/
|-- README.md
|-- STRUCTURE.md
|-- docs/                      # Documentación legacy o resumida
|-- examples/                  # Ejemplos legacy o resumidos
|-- integrations/              # Integración legacy o resumida
|-- rules/                     # Reglas legacy o resumidas
|-- scripts/                   # Scripts legacy o resumidos
`-- Wazuh-Rules-Teams/         # Proyecto canónico y mantenido
  |-- README.md
  |-- docs/                  # Documentación operativa actual
  |-- examples/              # Configuración ejemplo actual
  |-- integrations/          # Código de integración actual
  |-- lists/                 # CDB lists activas
  |-- rules/                 # Reglas XML activas
  |-- scripts/               # Testing y simulación actuales
  `-- Wazuh-Rules-Teams/     # Carpeta vacía, ignorar
```

### Flujo recomendado

1. Lee `Wazuh-Rules-Teams/README.md`.
2. Usa `Wazuh-Rules-Teams/docs/` para instalación y operación.
3. Edita reglas en `Wazuh-Rules-Teams/rules/`.
4. Ejecuta pruebas desde `Wazuh-Rules-Teams/scripts/`.

## 📖 Documentación

- **[Mapa del repositorio](STRUCTURE.md)**: Qué carpeta usar y cuál ignorar
- **[Proyecto activo](Wazuh-Rules-Teams/README.md)**: Punto de entrada principal
- **[Docs activas](Wazuh-Rules-Teams/docs/README.md)**: Índice de documentación vigente
- **[Instalación activa](Wazuh-Rules-Teams/docs/INSTALLATION.md)**: Guía operativa actual
- **[Migración activa](Wazuh-Rules-Teams/docs/MIGRATION.md)**: Procedimiento de migración vigente

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
IP de Origen: 192.168.1.100
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

Ver [Wazuh-Rules-Teams/docs/README.md](Wazuh-Rules-Teams/docs/README.md) para la guía actual de documentación y resolución de problemas.

## 🤝 Contribuir

Las contribuciones son bienvenidas. Por favor:

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📝 Changelog

### v1.0.0 (2026-03-11)
- ✅ Implementación inicial de 101 reglas custom (89 Windows + 5 Overrides + 7 Linux)
- ✅ Integración con Microsoft Teams
- ✅ Sistema de resúmenes acumulativos
- ✅ Alertas críticas inmediatas
- ✅ Documentación completa
- ✅ Scripts de testing y migración

## 📄 Licencia

Este proyecto está bajo la Licencia MIT - ver [LICENSE](LICENSE) para detalles.

## 👤 Autor

**Mateo Villablanca**
- GitHub: [@mvillablanca](https://github.com/WhiteMooncy)

## 🙏 Agradecimientos

- [Wazuh](https://wazuh.com/) - Plataforma SIEM open-source
- [Microsoft Teams](https://www.microsoft.com/microsoft-teams/) - Plataforma de comunicación
- [MITRE ATT&CK](https://attack.mitre.org/) - Framework de técnicas de atacantes

---
**⭐ Si este proyecto te fue útil, considera darle una estrella en GitHub**
