# 🔴 DIAGNÓSTICO: Alerta de Ataque Brute Force No Llega a Teams

## El Problema

Las reglas **200004** (SSH brute force) y **200005** (Windows brute force) generan alertas CRÍTICAS (Nivel 15) que DEBERÍAN enviarse inmediatamente a Teams, pero no están llegando.

---

## 🔍 Análisis de la Estructura de Datos

### Alertas Normales (Ejemplo: Regla 200001 - SSH failed login)
```json
{
  "timestamp": "2026-03-16T14:30:20",
  "rule": {
    "id": "200001",
    "level": 11,
    "description": "sshd: failed login attempt with non-nominal account $(user)"
  },
  "agent": {"name": "Linux-Server-01", "id": "001"},
  "data": {
    "srcip": "192.168.1.100",
    "dstuser": "admin",
    "srcuser": "attacker"
  },
  "full_log": "...",
  "decoder": {"name": "sshd"}
}
```

### Alertas de Correlación (Regla 200004 - Brute Force SSH)
```json
{
  "timestamp": "2026-03-16T14:30:35",
  "rule": {
    "id": "200004",        ⬅️ REGLA DE CORRELACIÓN
    "level": 15,           ⬅️ CRÍTICA
    "description": "CRITICAL: Multiple SSH logins detected with non-nominal accounts from same IP (192.168.1.100) - Possible brute force attack",
    "parent_rule_id": "200001"  ⬅️ DEPENDE DE ESTA REGLA
  },
  "agent": {"name": "Linux-Server-01", "id": "001"},
  "data": {
    "srcip": "192.168.1.100"    ⬅️ SOLO tiene IP, FALTA el usuario específico
  },
  "related_events": [
    {"rule_id": "200001", "timestamp": "2026-03-16T14:30:10", "user": "admin"},
    {"rule_id": "200001", "timestamp": "2026-03-16T14:30:15", "user": "admin"},
    {"rule_id": "200001", "timestamp": "2026-03-16T14:30:20", "user": "admin"}
  ]
}
```

---

## 🐛 Bug en `custom-teams-summary.py`

### Función: `extract_user_info()` - LÍNEAS 313-325

```python
def extract_user_info(alert):
    """Extraer usuario de alerta Windows"""
    if 'data' in alert:
        if 'win' in alert['data']:
            eventdata = alert['data']['win'].get('eventdata', {})
            user = eventdata.get('subjectUserName') or eventdata.get('targetUserName')
            domain = eventdata.get('subjectDomainName') or eventdata.get('targetDomainName')
            if user:
                return f"{domain}\\{user}" if domain else user
        elif 'srcuser' in alert['data']:  ⬅️ BUSCA AQUÍ
            return alert['data']['srcuser']
        elif 'dstuser' in alert['data']:  ⬅️ Y AQUÍ
            return alert['data']['dstuser']
    return None  ⬅️ PROBLEMA: En alertas de correlación NO EXISTEN srcuser/dstuser
```

### Función: `extract_source_ip()` - LÍNEAS 327-336

```python
def extract_source_ip(alert):
    """Extraer IP de origen"""
    if 'data' in alert:
        if 'srcip' in alert['data']:
            return alert['data']['srcip']  ⬅️ Esto SÍ funciona
        if 'win' in alert['data']:
            eventdata = alert['data']['win'].get('eventdata', {})
            return eventdata.get('ipAddress') or eventdata.get('workstationName')
    return None
```

**ESTADO:** IP se extrae correctamente ✅, pero usuario = `None` ❌

---

## 🔴 Síntomas del Bug

Cuando llega una alerta de correlación (brute force):

```
mensaje["attachments"][0]["content"]["body"][1]["facts"].insert(3, {"title": "Usuario", "value": None})
```

**Esta línea en la función `build_immediate_alert()` intenta insertar:**
```python
if user_info:  # ← user_info es None para correlaciones
    message["attachments"][0]["content"]["body"][1]["facts"].insert(3, {"title": "Usuario", "value": user_info})
```

**PERO Si `user_info = None`, la condición es False y NO se inserta nada.** Sin embargo, el mayor problema es que **el mensaje JSON podría estar mal formado y rechazarse**.

---

## 💥 El Verdadero Problema

En reglas de correlación como 200004 y 200005:
- La alerta tiene `level = 15` (CRÍTICA) ✅ → Debería enviarse inmediatamente
- La alerta tiene `srcip` en `data` ✅ 
- La alerta **NO TIENE** `srcuser` o `dstuser` en `data` ❌
- La alerta **NO TIENE** estructura `data.win` ❌

### Resultado:
`extract_user_info()` devuelve `None`, pero las siguientes líneas intentan usarlo:

```python
if user_info:  # ← Condición skipped si user_info es None
    message["attachments"][0]["content"]["body"][1]["facts"].insert(3, {"title": "Usuario", "value": user_info})

if source_ip:  # ← Esto SÍ entra
    message["attachments"][0]["content"]["body"][1]["facts"].insert(4, {"title": "IP Origen", "value": source_ip})
```

**El JSON resultante es válido, PERO:**
- No muestra el usuario específico (por eso parece incompleto)
- Power Automate **podría estar rechazando el mensaje** si el webhook espera ciertos campos

---

## ✅ SOLUCIÓN: Mejorar Extracción de Datos para Correlaciones

### Problema 1: Extraer usuario de eventos relacionados

Para una alerta de correlación, necesitamos buscar el usuario en los eventos relacionados:

```python
def extract_user_info(alert):
    """Extraer usuario (mejorado para correlaciones)"""
    if 'data' in alert:
        if 'win' in alert['data']:
            eventdata = alert['data']['win'].get('eventdata', {})
            user = eventdata.get('subjectUserName') or eventdata.get('targetUserName')
            domain = eventdata.get('subjectDomainName') or eventdata.get('targetDomainName')
            if user:
                return f"{domain}\\{user}" if domain else user
        
        # Para correlaciones: buscar en eventos relacionados
        if 'related_events' in alert['data']:
            for event in alert['data']['related_events']:
                if 'user' in event:
                    return event['user']
        
        # Búsqueda en campos directos
        return alert['data'].get('srcuser') or alert['data'].get('dstuser')
    
    return None
```

### Problema 2: Indicar que es alerta de correlación

```python
def build_immediate_alert(alert_json, webhook_url):
    """Mejorado: indicar tipo de alerta"""
    alert = alert_json
    level = alert['rule']['level']
    
    # Detectar si es correlación
    is_correlation = 'frequency' in alert.get('rule', {}) or 'parent_rule_id' in alert.get('rule', {})
    
    user_info = extract_user_info(alert) or "Múltiples usuarios (correlación)"  # ← Default mejorado
    source_ip = extract_source_ip(alert)
    
    # ... resto del código
```

### Problema 3: Agregar información de relacionadas

```python
# En la tarjeta adaptativa, Para correlaciones hacer:
if is_correlation and 'related_events' in alert.get('data', {}):
    message["attachments"][0]["content"]["body"].append({
        "type": "TextBlock",
        "text": "**Eventos Relacionados**",
        "weight": "Bolder",
        "separator": True
    })
    
    for event in alert['data']['related_events'][:5]:  # Top 5
        message["attachments"][0]["content"]["body"].append({
            "type": "TextBlock",
            "text": f"• Rule {event.get('rule_id')}: {event.get('timestamp')}",
            "size": "Small",
            "wrap": True
        })
```

---

## 🔧 Cambios Recomendados

## En `custom-teams-summary.py`:

**Líneas 313-325 (extract_user_info):**

```python
def extract_user_info(alert):
    """Extraer usuario de alerta (mejorado para correlaciones)"""
    data = alert.get('data', {})
    
    # Windows events
    if 'win' in data:
        eventdata = data['win'].get('eventdata', {})
        user = eventdata.get('subjectUserName') or eventdata.get('targetUserName')
        domain = eventdata.get('subjectDomainName') or eventdata.get('targetDomainName')
        if user:
            return f"{domain}\\{user}" if domain else user
    
    # Campos directos
    if 'srcuser' in data:
        return data['srcuser']
    if 'dstuser' in data:
        return data['dstuser']
    
    # Para correlaciones: buscar en eventos relacionados
    if 'related_events' in data:
        users = []
        for event in data['related_events']:
            if 'user' in event and event['user'] not in users:
                users.append(event['user'])
        if users:
            return " | ".join(users) if len(users) <= 3 else f"{users[0]} (+{len(users)-1} más)"
    
    return None
```

**Y en `build_immediate_alert()` (~línea 260), después de extraer datos:**

```python
# Agregar indicador de correlación
is_correlation = alert.get('rule', {}).get('parent_rule_id') is not None

# Mejorar valor default para usuario
if not user_info and is_correlation:
    user_info = "Múltiples intentos"

# ... resto del código (líneas de FactSet)
```

---

## 🧪 Cómo Probar el Fix

**En el servidor (10.27.20.171):**

```bash
# 1. Crear alerta de test de brute force
cat > /tmp/brute-force-test.json << 'EOF'
{
  "timestamp": "2026-03-16T15:30:00",
  "rule": {
    "id": "200004",
    "level": 15,
    "description": "CRITICAL: Multiple SSH logins detected from 192.168.1.100"
  },
  "agent": {"name": "Linux-Test", "id": "001"},
  "data": {
    "srcip": "192.168.1.100",
    "related_events": [
      {"rule_id": "200001", "user": "admin"},
      {"rule_id": "200001", "user": "admin"},
      {"rule_id": "200001", "user": "root"}
    ]
  }
}
EOF

# 2. Enviar a script
cat /tmp/brute-force-test.json | \
  /var/ossec/integrations/custom-teams-summary.py "YOUR_WEBHOOK_URL" 11 "custom-teams-summary"

# 3. Verificar en Teams que llegue con:
#    - ✅ IP Origen: 192.168.1.100
#    - ✅ Usuario: admin | admin | root (o similar)
#    - ✅ Nivel CRÍTICO (color rojo)
```

---

## 📋 Resumen

| Elemento | Estado | Acción |
|----------|--------|--------|
| Regla dispara (Nivel 15) | ✅ Funciona | - |
| Script `main()` detecta crítica | ✅ Funciona | - |
| Función `extract_source_ip()` | ✅ Funciona | - |
| Función `extract_user_info()` | ❌ Falla para correlaciones | **FIJAR:** agregar búsqueda en `related_events` |
| Formato JSON a Teams | ⚠️ Incompleto | **MEJORA:** agregar eventos relacionados |
| Power Automate recibe | ❓ Desconocido | **VERIFICAR:** logs de integración |

---

## 🚀 Próximos Pasos

1. **Implementar los cambios sugeridos** en `custom-teams-summary.py`
2. **Probar con alertas simuladas** de brute force
3. **Verificar que lleguen a Teams** con formato completo
4. **Monitorear logs:**
   ```bash
   tail -f /var/ossec/logs/integrations.log | grep custom-teams
   ```
