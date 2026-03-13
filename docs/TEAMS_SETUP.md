# Teams Integration Setup Guide

Guía completa de configuración: Wazuh → Power Automate → Microsoft Teams

## Tabla de Contenidos

- [Requisitos Previos](#requisitos-previos)
- [Crear Incoming Webhook en Teams](#crear-incoming-webhook-en-teams)
- [Configurar Power Automate Flow](#configurar-power-automate-flow)
- [Configurar Variables de Entorno](#configurar-variables-de-entorno)
- [Instalar y Ejecutar Script](#instalar-y-ejecutar-script)
- [Testing y Validación](#testing-y-validación)
- [Troubleshooting](#troubleshooting)

## Requisitos Previos

### Software
- Wazuh Manager 4.x o superior
- Python 3.6+
- curl (para testing manual)
- Acceso a Microsoft 365 (Teams)
- Microsoft Power Automate (Microsoft 365 Business Standard o superior)

### Permisos
- Acceso como propietario a canal Teams
- Tenant Admin acceso para Microsoft 365 (crear Power Automate flow)
- Permiso para ejecutar scripts en Wazuh Manager

### Red
- Wazuh Manager puede conectar a `outlook.webhook.office.com` (HTTPS 443)
- No hay proxy requerido (cliente directo)

## Crear Incoming Webhook en Teams

### Opción 1: Crear Flow Manual en Power Automate (Recomendado)

1. **Ir a Power Automate**
   - Portal: https://flow.microsoft.com
   - Loguear con cuenta Microsoft 365

2. **Crear New Flow**
   ```
   Create → Cloud flow → Automated cloud flow
   ```

3. **Trigger: HTTP Request**
   - Trigger: "When a HTTP request is received"
   - Método: POST
   - JSON Schema (copiar completo):
   ```json
   {
     "type": "object",
     "properties": {
       "timestamp": {"type": "string"},
       "severity": {"type": "string"},
       "title": {"type": "string"},
       "message": {"type": "string"},
       "alerts_count": {"type": "integer"},
       "critical_count": {"type": "integer"},
       "rule_ids": {"type": "array", "items": {"type": "string"}},
       "source_ips": {"type": "array", "items": {"type": "string"}}
     },
     "required": ["timestamp", "severity", "title", "message"]
   }
   ```

4. **Action: Post to Teams Channel**
   - Acción: "Post a message in a chat or channel"
   - Team: Seleccionar tu equipo (ej: "Security Alerts")
   - Channel: Seleccionar canal (ej: "#incidents")
   - Message: Usar dynamic content para formatear
   ```
   **[${triggerBody()?['severity']}]** ${triggerBody()?['title']}
   
   ${triggerBody()?['message']}
   
   **Details:**
   - Timestamp: ${triggerBody()?['timestamp']}
   - Alert Count: ${triggerBody()?['alerts_count']}
   - Critical Alerts: ${triggerBody()?['critical_count']}
   ```

5. **Obtener Webhook URL**
   - Copiar "HTTP POST URL" generada automáticamente
   - Formato: `https://prod-XX.eastus.logic.azure.com:443/workflows/XXXXX/triggers/manual/paths/invoke?api-version=2016-06-...`

### Opción 2: Usar Incoming Webhook Nativo (Deprecado, pero funciona)

1. Ir a Teams → Configurar Webhook
2. Opción: Connectors → Incoming Webhook
3. Nuevo webhook → configurar destino
4. Copiar URL generada

**Nota:** Microsoft recomienda Power Automate sobre webhooks nativos.

## Configurar Power Automate Flow

### Estructura Completa del Flow

```
Trigger: HTTP Request Recibida
    ↓
Action: Initialize Variable (para tracking)
    ↓
Action: Compose Message Formateado
    ↓
Action: Post to Teams Channel
    ↓
Response: HTTP 200 OK
```

### Paso a Paso Detallado

#### 1. Trigger HTTP Request
```
Trigger Name: "When a HTTP request is received"
Request Body JSON Schema:
{
  "type": "object",
  "properties": {
    "timestamp": {
      "type": "string",
      "format": "date-time"
    },
    "severity": {
      "type": "string",
      "enum": ["CRÍTICO", "MUY ALTO", "ALTO", "MEDIO", "BAJO"]
    },
    "title": {"type": "string"},
    "message": {"type": "string"},
    "alerts_count": {"type": "integer"},
    "critical_count": {"type": "integer"}
  },
  "required": ["timestamp", "severity", "title", "message"]
}
```

#### 2. Initialize Variable (opcional pero recomendado)
```
Name: status
Type: String
Value: "Processing Wazuh Alert"
```

#### 3. Post Message con Adaptive Card (mejor formato)

Use Adaptive Card JSON para mejor visualización:

```json
{
  "type": "message",
  "attachments": [
    {
      "contentType": "application/vnd.microsoft.card.adaptive",
      "contentUrl": null,
      "content": {
        "type": "AdaptiveCard",
        "body": [
          {
            "type": "TextBlock",
            "text": "🚨 Wazuh Security Alert",
            "weight": "bolder",
            "size": "large",
            "color": "attention"
          },
          {
            "type": "FactSet",
            "facts": [
              {
                "name": "Severity:",
                "value": "@{triggerBody()?['severity']}"
              },
              {
                "name": "Title:",
                "value": "@{triggerBody()?['title']}"
              },
              {
                "name": "Timestamp:",
                "value": "@{triggerBody()?['timestamp']}"
              },
              {
                "name": "Alert Count:",
                "value": "@{string(triggerBody()?['alerts_count'])}"
              }
            ]
          },
          {
            "type": "TextBlock",
            "text": "@{triggerBody()?['message']}",
            "wrap": true,
            "separator": true
          }
        ],
        "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
        "version": "1.4"
      }
    }
  ]
}
```

#### 4. Response HTTP
```
Status Code: 200
Body: {"status": "Alert processed successfully"}
```

### Copiar Webhook URL

1. En el trigger HTTP, copiar: "HTTP POST URL"
2. Guardar en variable segura (ver siguiente sección)

## Configurar Variables de Entorno

### En Wazuh Manager (Linux/UNIX)

Editar perfiles de shell:

```bash
# 1. Crear archivos de configuración
sudo nano /var/ossec/etc/teams-integration.env
```

Contenido del archivo:

```bash
# Webhook URL de Power Automate (copiar completo)
export WAZUH_TEAMS_WEBHOOK_URL="https://prod-XX.eastus.logic.azure.com:443/workflows/XXXXX/triggers/manual/paths/invoke?api-version=2016-06-01&sp=%2F..."

# Ubicación del caché de alertas
export WAZUH_TEAMS_CACHE_FILE="/var/ossec/logs/teams_alerts_cache.json"

# Intervalo de resumen (horas)
export WAZUH_SUMMARY_INTERVAL_HOURS=24

# Nivel crítico (envía inmediatamente)
export WAZUH_CRITICAL_LEVEL=15

# Máximas alertas antes de enviar resumen
export MAX_ALERTS_BEFORE_SUMMARY=20

# Verificar SSL (false si usas cert auto-firmado)
export WAZUH_TEAMS_VERIFY_SSL="true"

# Dashboard URL (para links en Teams)
export WAZUH_DASHBOARD_URL="https://wazuh.ejemplo.com"
```

### En Wazuh Agente (Windows)

En PowerShell (como Administrator):

```powershell
# PowerShell
[Environment]::SetEnvironmentVariable("WAZUH_TEAMS_WEBHOOK_URL", "https://...", "Machine")
[Environment]::SetEnvironmentVariable("WAZUH_SUMMARY_INTERVAL_HOURS", "24", "Machine")

# Verificar
$env:WAZUH_TEAMS_WEBHOOK_URL
```

O editar en Sistema:
```
Control Panel → System → Environment Variables
```

### Cargar Variables en Script

En `custom-teams-summary.py`:

```python
import os

# Leer variables
webhook_url = os.environ.get('WAZUH_TEAMS_WEBHOOK_URL')
cache_file = os.environ.get('WAZUH_TEAMS_CACHE_FILE', '/var/ossec/logs/teams_alerts_cache.json')
summary_hours = int(os.environ.get('WAZUH_SUMMARY_INTERVAL_HOURS', '24'))
critical_level = int(os.environ.get('WAZUH_CRITICAL_LEVEL', '15'))

if not webhook_url:
    print("ERROR: WAZUH_TEAMS_WEBHOOK_URL no configurada")
    sys.exit(1)
```

## Instalar y Ejecutar Script

### Paso 1: Copiar Script

```bash
# En Wazuh Manager
sudo cp custom-teams-summary.py /var/ossec/integrations/
sudo chown root:wazuh /var/ossec/integrations/custom-teams-summary.py
sudo chmod 750 /var/ossec/integrations/custom-teams-summary.py
```

### Paso 2: Hacer Ejecutable

```bash
sudo chmod +x /var/ossec/integrations/custom-teams-summary.py
```

### Paso 3: Configurar en ossec.conf

```xml
<ossec_config>
  <!-- ... otras configuraciones ... -->

  <!-- Integración Teams -->
  <integration>
    <name>custom-summary</name>
    <hook_url>https://prod-XX.eastus.logic.azure.com/workflows/.../triggers/manual/paths/invoke?api-version=2016-06-01</hook_url>
    <level>1</level>
    <group>alerts</group>
    <alert_format>json</alert_format>
  </integration>

</ossec_config>
```

### Paso 4: Restart Wazuh

```bash
sudo systemctl restart wazuh-manager
```

### Paso 5: Ejecutar Manualmente (Testing)

```bash
# Como usuario wazuh
sudo -u wazuh python3 /var/ossec/integrations/custom-teams-summary.py

# Con variables de entorno
export WAZUH_TEAMS_WEBHOOK_URL="https://prod-XX..."
sudo -u wazuh -E python3 /var/ossec/integrations/custom-teams-summary.py
```

## Testing y Validación

### Test 1: Verificar Variables de Entorno

```bash
# Linux
env | grep WAZUH

# Windows PowerShell  
Get-Item Env:WAZUH*
```

### Test 2: Test Webhook URL (curl)

```bash
# Test POST simple
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "timestamp": "'$(date -Iseconds)'",
    "severity": "CRÍTICO",
    "title": "Test Alert",
    "message": "Este es un mensaje de prueba",
    "alerts_count": 1,
    "critical_count": 1
  }' \
  "https://prod-XX.eastus.logic.azure.com:443/workflows/XXXXX/triggers/manual/paths/invoke?api-version=2016-06-01&sp=%2F..."

# Esperado: HTTP 200
```

### Test 3: Ejecutar Script en Seco

```bash
# Ejecutar sin enviar
python3 custom-teams-summary.py --dry-run

# Ver caché actual
cat /var/ossec/logs/teams_alerts_cache.json | python3 -m json.tool
```

### Test 4: Simular Evento Wazuh

Para generar evento que dispare alertas:

```bash
# En Linux: Intentar login fallido múltiples veces
for i in {1..10}; do
  ssh invaliduser@localhost
done

# En Windows: 
# - Intentar RDP logout/login rápidamente
# - O trigger via PowerShell alert logon event
```

Luego:
```bash
# Ver alertas generadas
tail -f /var/ossec/logs/alerts/alerts.json | grep custom

# Ver si se envió a Teams
tail -f /var/ossec/logs/ossec.log | grep teams_integration
```

## Troubleshooting

### Webhook URL No Funciona

**Síntoma:** curl return 404 o 401

**Solución:**
1. Copiar URL **completa** desde Power Automate
2. Verificar no tiene cortes de línea: `echo $WAZUH_TEAMS_WEBHOOK_URL`
3. Probar acceso desde localhost: `curl https://prod-XX...`
4. Si 401: Power Automate flow puede estar deshabilitado → re-habilitar

### Teams No Recibe Mensajes

**Síntoma:** Webhook funciona (curl 200) pero Team vacío

**Solución:**
1. Verificar channel existe y estás miembro
2. Ver que flow Power Automate está "Turned on"
3. Ejecutar flow manual desde Power Automate portal
4. Revisar histórico de flow: Activity → Run history

### Caché Lleno / Alertas No Se Envían

**Síntoma:** `teams_alerts_cache.json` muy grande

**Solución:**
1. Revisar cuota: `du -h /var/ossec/logs/teams_alerts_cache.json`
2. Ejecutar limpieza: `python3 scripts/clean_cache.py`
3. O resetear: `rm /var/ossec/logs/teams_alerts_cache.json`

### SSL Certificate Errors

**Síntoma:** "SSL certificate verify failed"

**Solución (Temporal - no recomendado en producción):**
```bash
export WAZUH_TEAMS_VERIFY_SSL="false"
```

**Solución (Recomendada):**
1. Obtener certificado válido: Let's Encrypt
2. Instalar en Wazuh Manager
3. Setear `WAZUH_TEAMS_VERIFY_SSL="true"`

### Variables de Entorno No Se Cargan

**Síntoma:** Script no ve variables

**Solución:**
1. Cargar antes de ejecutar:
```bash
source /var/ossec/etc/teams-integration.env
python3 /var/ossec/integrations/custom-teams-summary.py
```

2. O agregar a crontab con full path:
```crontab
0 * * * * . /var/ossec/etc/teams-integration.env; /var/ossec/framework/python/bin/python3 /var/ossec/integrations/custom-teams-summary.py
```

## Automatización con Cron

Para enviar resúmenes automáticos cada hora:

```bash
# Editar crontab
sudo crontab -e

# Agregar línea:
0 * * * * source /var/ossec/etc/teams-integration.env && /var/ossec/framework/python/bin/python3 /var/ossec/integrations/custom-teams-summary.py >> /var/ossec/logs/teams_integration.log 2>&1
```

Verificar ejecución:

```bash
tail -f /var/ossec/logs/teams_integration.log
```

## Dashboard Links en Teams

Para agregar link al dashboard de Wazuh en mensajes:

```python
# En custom-teams-summary.py
dashboard_url = os.environ.get('WAZUH_DASHBOARD_URL', 'https://wazuh.example.com')

message = f"""
[Ver en Dashboard]({dashboard_url}/app/wazuh#/overview)
"""
```

## Seguridad y Mejores Prácticas

1. **No hardcodear webhook URL** - Usar variables de entorno
2. **Usar HTTPS siempre** - webhook_url debe começar con https://
3. **Rotar webhook URL periódicamente** - Cada 6 meses
4. **Limitar acceso a Teams** - Solo Security team
5. **Auditar webhook acceso** - En Power Automate run history
6. **Backup de variables** - Guardar webhook URL en gestor secretos (Azure Key Vault)

## Recursos Adicionales

- [Power Automate Docs](https://learn.microsoft.com/en-us/power-automate/)
- [Teams Webhook Docs](https://learn.microsoft.com/en-us/microsoftteams/platform/webhooks-and-connectors/how-to/connectors-using)
- [Wazuh Integration Docs](https://documentation.wazuh.com/current/user-manual/capabilities/alerting/)
- [../TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- [../custom-teams-summary.py](../integrations/custom-teams-summary.py)
