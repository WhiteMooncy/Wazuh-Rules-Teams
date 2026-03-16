# 🔌 WAZUH + TEAMS: Cómo Se Comunican y Trabajan Juntos

**Explicación completa de cómo Wazuh detecta problemas y los reporta en Microsoft Teams**

---

## 📡 EL FLUJO COMPLETO EN 1 IMAGEN

```
PASO 1          PASO 2           PASO 3            PASO 4
┌─────────┐     ┌─────────┐      ┌──────────────┐   ┌─────────┐
│ EVENTO  │────>│ WAZUH   │─────>│ ¿ES MALO?    │──>│ TEAMS   │
│ EN PC   │     │ MANAGER │      │              │   │ NOTIFICA│
└─────────┘     └─────────┘      └──────────────┘   └─────────┘

EJEMPLO:                        ANÁLISIS:
Usuario intenta       Wazuh     "3 intentos       Envía alerta
login 3 veces    recibe y      fallidos en       a Teams con
fallido          procesa        5 min = ATAQUE"   detalles
```

---

## 🎯 ENTENDER LOS 4 PASOS

### PASO 1: EL EVENTO OCURRE EN TU PC

```
Tu Windows (o Linux) registra algo importante:

✓ Usuario "Juan" intentó login con password incorrecta
✓ Programador ejecutó comando sospechoso
✓ Se instaló un programa nuevo
✓ Se accedió a un archivo crítico
✓ Se cambió una configuración de seguridad

Ejemplo en Windows:
═══════════════════════════════════════════════════
Event ID: 4625 (Failed Login)
Timestamp: 2026-03-16 14:23:45
Computer: DESKTOP-JUAN
User: DOMAIN\juan
IP Origin: 192.168.1.50
Reason: Invalid password
═══════════════════════════════════════════════════

Este evento EXISTE EN WINDOWS automáticamente.
Windows lo registra en su "Visor de Eventos"
```

---

### PASO 2: WAZUH RECIBE Y PROCESA

Tu PC tiene instalado el **AGENTE WAZUH** que:

```
1️⃣ LEE el evento de Windows
   ├─ Abre "Event Viewer" 
   ├─ Lee: "Evento 4625, usuario juan, password fallida"
   └─ Copia ese evento

2️⃣ COMPRIME y ENCRIPTA
   ├─ Lo comprime (reduce tamaño 80%)
   ├─ Lo encripta (TLS, clave privada)
   └─ Nadie puede leerlo en el camino

3️⃣ ENVÍA al MANAGER CENTRAL
   ├─ Por internet (Puerto 1514)
   ├─ Se envía cada 5 segundos o cuando se acumula
   └─ Manager recibe: "evento de pc-juan de usuario juan"

┌────────────────────────────────────────────────────┐
│ TU COMPUTADORA              WAZUH MANAGER (Central)│
│ (Windows/Linux)                                    │
│                                                    │
│ Evento en Event Log ───TLS Encriptado──> Recibe   │
│ "Failed Login"      Puerto 1514         y Guarda  │
└────────────────────────────────────────────────────┘
```

---

### PASO 3: WAZUH ANALIZA - "¿ES ESTO MALO?"

Cuando WAZUH recibe el evento, hace 4 preguntas:

#### 3A: DESCODIFICAR (Entender el evento)

```
EVENTO QUE LLEGA (CRUDO):
"2026-03-16T14:23:45.123Z DESKTOP-JUAN Security: 
Event ID 4625, john attempted login, password invalid"

         ↓ WAZUH DECODER

EVENTO PROCESADO (LIMPIO):
├─ Fecha:       2026-03-16 14:23:45
├─ Computadora: DESKTOP-JUAN
├─ Usuario:     john
├─ Tipo evento: Failed Login
├─ Evento ID:   4625
└─ Razón:       Invalid password

Ahora WAZUH entiende cada parte del evento.
```

#### 3B: COMPARAR CON REGLAS (¿Esto ya es peligroso?)

Tu proyecto tiene **101 reglas personalizadas** que dicen:

```
REGLA EJEMPLO:

IF evento = "Failed Login" (ID 4625)
THEN:
    Contar cuántas veces ocurrió en últimos 5 minutos
    
    IF contador >= 2:
        LEVEL = 8 (Sospechoso)
        ALERT = "Possible brute force attack"
```

Con el evento de ejemplo:

```
1er intento (14:23:45): Failed login
   └─ Contador = 1
   └─ Nivel = 3 (normal)
   └─ NO alertar aún

2do intento (14:24:10): Failed login 
   └─ Contador = 2
   └─ Nivel = 8 (SOSPECHOSO)
   └─ GENERAR ALERTA ✓

3er intento (14:24:30): Failed login
   └─ Contador = 3
   └─ Nivel = 10 (GRAVE)
   └─ ACTUALIZAR ALERTA ✓
```

**Las 101 reglas detectan tipos de ataque:**

| Regla | Detecta | Nivel |
|-------|---------|-------|
| 100008 | Servicio nuevo instalado (malware) | 12 |
| 100010 | Admin intenta desde 3 máquinas en 5 min | 10 |
| 100013 | PowerShell hace algo raro | 10 |
| 100012 | Word abre script (phishing) | 12 |
| Brute Force | 3+ intentos fallidos en 5 min | 8 |

#### 3C: DECIDIR GRAVEDAD (Nivel 0-15)

```
NIVEL DE GRAVEDAD:

🟢 VERDE     (0-3)    = Normal,   sin alerta
🟡 AMARILLO  (4-7)    = Revisar,  pero espera
🟠 NARANJA   (8-11)   = Sospechoso, préstale atención
🔴 ROJO      (12-14)  = Grave,      ¡revisa ya!
🔥 CRÍTICO   (15+)    = ALERTA YA, no esperes

EJEMPLO:
Failed login 3 veces = NIVEL 8 (NARANJA)
Malware detectado    = NIVEL 15 (CRÍTICO ⚠️)
Cambio normal        = NIVEL 2 (VERDE ✓)
```

---

### PASO 4: ENVÍA A TEAMS (LA INTEGRACIÓN)

Cuando WAZUH crea una alerta grave (nivel >= 8), ejecuta un script Python:

```python
# Pseudocódigo simplificado del script
# File: custom-teams-summary.py

IF alerta.level >= 15:
    # CRÍTICO: envía INMEDIATAMENTE
    enviar_a_teams(alerta)
    
ELIF alerta.level >= 11:
    # Grave: acumula en caché
    guardar_en_cache(alerta)
    
    IF han_pasado_24_horas OR cache_tiene_3+_alertas:
        # Envía resumen acumulado
        resumen = crear_resumen(todas_alertas_en_cache)
        enviar_a_teams(resumen)
        limpiar_cache()
```

**¿Qué significa esto en la práctica?**

```
Hora 14:30 → Alerta nivel 12 (grave)
            ├─ Se guarda en caché
            └─ NO se envía aún (espera) ⏳

Hora 14:35 → Alerta nivel 11 (grave)
            ├─ Se guarda en caché  
            └─ Cache ahora tiene 2 alertas (espera 1 más)

Hora 14:40 → Alerta nivel 13 (muy grave)
            ├─ Se guarda en caché
            └─ Cache ahora tiene 3 alertas → ¡LÍMITE ALCANZADO!
            
            WAZUH ENVÍA A TEAMS:
            ═══════════════════════════════════════
            📊 RESUMEN DE ALERTAS (últimas 24h)
            
            Total: 3 alertas
            Nivel máximo: 13 (MUY GRAVE)
            
            ✓ Alert 1: Brute force en PC-JUAN
            ✓ Alert 2: Cambio de política
            ✓ Alert 3: Servicio sospechoso
            
            → [VER DETALLES] [ABRIR WAZUH DASHBOARD]
            ═══════════════════════════════════════
            
            Cache se vacía y comienza de nuevo
```

---

## 💬 CÓMO SE COMUNICAN (EL VIAJE DE UN EVENTO)

### Viaje 1: PC → Manager (Agente Wazuh)

```
┌──────────────────┐
│ TU WINDOWS       │
│                  │
│ Event: "Failed   │
│ Login"           │
└────────┬─────────┘
         │
         │ (1) LEE
         │ Agente Wazuh abre
         │ "Event Viewer"
         │
         │ (2) COMPRIME
         │ Reduce tamaño
         │
         │ (3) ENCRIPTA
         │ Clave privada TLS
         │
         │ (4) ENVÍA
         │ Puerto 1514
         ▼
┌──────────────────────────┐
│ WAZUH MANAGER (Internet) │
│                          │
│ (5) RECIBE               │
│ (6) DESENCRIPTA          │
│ (7) DESCOMPRIME          │
│ (8) VERIFICA INTEGRIDAD  │
│ (9) COLOCA EN QUEUE      │
└────────┬─────────────────┘
         │
         │ En: /var/ossec/logs/events/
         │
         ▼
```

**¿Cuánto tarda?**
- Normal: 2-5 segundos
- Con internet lento: 10-30 segundos
- Si algo falla: se reintenta automáticamente

---

### Viaje 2: Manager → Analysis (Procesamiento)

```
┌──────────────────────┐
│ QUEUE DE EVENTOS     │
│ (Espera análisis)     │
└────────┬─────────────┘
         │
         │ Wazuh-analysisd (cerebro)
         │ procesa en paralelo
         │
         ├─ DECODER
         │  "Separa datos: usuario, IP, hora..."
         │
         ├─ PREPROCESSOR
         │  "Normaliza: mayúsculas, formatos..."
         │
         ├─ RULE MATCHING
         │  "Compara contra 2000+ reglas..."
         │
         ├─ CORRELATION
         │  "¿Es patrón de ataque?"
         │
         └─ ALERT GENERATION
            "Crea JSON de alerta"
            
Velocidad: ~1-5ms por evento
(muy rápido)
```

---

### Viaje 3: Manager → Teams (Integración)

```
┌──────────────────┐
│ ALERTA GENERADA  │
│ Level = 12       │
└────────┬─────────┘
         │
         │ (1) ¿Level >= 15?
         │ SÍ → Envía INMEDIATAMENTE
         │ NO → Continúa
         │
         │ (2) ¿Level >= 11?
         │ SÍ → Guarda en CACHÉ
         │ NO → Descarta
         │
         │ (3) ¿Caché lleno (3+ alertas) O 24h pasadas?
         │ SÍ → Crear RESUMEN
         │ NO → Espera más
         │
         ▼
┌────────────────────────────────┐
│ SCRIPT: custom-teams-summary.py│
│                                │
│ (4) Crea tarjeta bonita        │
│     - Estadísticas             │
│     - Top reglas               │
│     - MITRE ATT&CK             │
│     - Botones de acción        │
│                                │
│ (5) Envía a Webhook de Teams   │
│     URL: https://outlook.      │
│     webhook.office.com/...     │
│                                │
│ (6) Power Automate recibe      │
│     Publica en Teams           │
└────────┬──────────────────────┘
         │
         ▼
┌──────────────────────┐
│ MICROSOFT TEAMS      │
│ CANAL #SEGURIDAD     │
│                      │
│ 📊 ALERTA WAZUH      │
│ ━━━━━━━━━━━━━━━━━━  │
│ Nivel: 12 (GRAVE)    │
│ ...detalles...       │
│                      │
│ [VER EN DASHBOARD]   │
│ [INVESTIGAR]         │
└──────────────────────┘
```

---

## 🔄 EL CICLO COMPLETO CON EJEMPLO REAL

### Escenario: Ataque Brute Force a Usuario Admin

```
HORA 14:30:00
═════════════════════════════════════════════════════════════
PC: DESKTOP-SERVIDOR-01
Usuario intenta login: DOMAIN\Administrator
Contraseña: ❌ INCORRECTA
Evento ID: 4625 (Failed Login)
Origen: IP 203.45.67.89 (sospechosa)

     ↓

HORA 14:30:05
═════════════════════════════════════════════════════════════
[AGENTE WAZUH EN SERVIDOR]
✓ Lee evento 4625
✓ Comprime (2KB)
✓ Encripta con TLS
✓ Envía al Manager

     ↓

HORA 14:30:10
═════════════════════════════════════════════════════════════
[WAZUH MANAGER - RECEPCIÓN]
✓ Recibe evento
✓ Desencripta
✓ Descomprime
✓ Coloca en queue

     ↓

HORA 14:30:11
═════════════════════════════════════════════════════════════
[WAZUH MANAGER - ANÁLISIS]

DECODER: Extrae
  ├─ Evento ID: 4625
  ├─ Usuario: Administrator
  ├─ IP: 203.45.67.89
  └─ Timestamp: 14:30

RULE MATCHING: Compara contra 101 reglas
  ├─ Regla 1: "Failed login" → MATCH (level 3)
  ├─ Regla 2: "Malware detection" → NO match
  ├─ Regla 3: "Policy change" → NO match
  └─ ...resultado: Level 3 (normal)

ACCIÓN:
  Nivel 3 < 8 → No alertar
  → Solo guardar en histórico

     ↓

HORA 14:30:20 (2do intento fallido)
═════════════════════════════════════════════════════════════
[WAZUH MANAGER - CORRELACIÓN]

Pregunta: ¿Hay patrón?
  Admin intentó login fallido 2 veces en 20 segundos
  Contador: 2
  Intervalo: < 5 minutos
  
REGLA: "Brute force detection"
  IF contador >= 2 in < 5min: Level = 8
  
RESULTADO: ⚠️ Level 8 (SOSPECHOSO)

GENERACIÓN DE ALERTA:
{
  "timestamp": "2026-03-16T14:30:20",
  "rule_id": "BRUTE_FORCE",
  "level": 8,
  "description": "Possible brute force attack on Administrator",
  "user": "DOMAIN\\Administrator",
  "source_ip": "203.45.67.89",
  "agent": "DESKTOP-SERVIDOR-01"
}

     ↓

HORA 14:30:21
═════════════════════════════════════════════════════════════
[SCRIPT DE INTEGRACIÓN]

Alerta level 8 (< 15, no crítico)
  → Guardar en CACHÉ

CACHÉ AHORA:
  ├─ Alerta 1: Brute force (level 8)
  ├─ Esperando 2 más
  └─ O esperar 24 horas

     ↓

HORA 14:30:35 (3er intento fallido)
═════════════════════════════════════════════════════════════
[WAZUH MANAGER]

Contador: 3 intentos
Level: 10 (GRAVE)

CACHÉ ACTUALIZADO:
  ├─ Alerta 1: Brute force (level 8)
  └─ Alerta 2: Brute force (level 10)

     ↓

HORA 14:31:00 (4to intento fallido)
═════════════════════════════════════════════════════════════
[WAZUH MANAGER]

Contador: 4 intentos
Level: 12 (MUY GRAVE)

CACHÉ ACTUALIZADO:
  ├─ Alerta 1: level 8
  ├─ Alerta 2: level 10
  └─ Alerta 3: level 12 ← Total 3 alertas = ¡LÍMITE!
  
TRIGGER: Enviar RESUMEN a Teams

     ↓

HORA 14:31:02
═════════════════════════════════════════════════════════════
[SCRIPT: custom-teams-summary.py]

Crea TARJETA ADAPTATIVA:

   ┌─────────────────────────────────────┐
   │ 🔴 Resumen de Alertas Wazuh - 24h │
   ├─────────────────────────────────────┤
   │ CRÍTICO: Ataque Brute Force         │
   │                                     │
   │ Total Alertas: 3                    │
   │ Nivel Máximo: 12 (MUY GRAVE)        │
   │ Agente Afectado: SERVIDOR-01        │
   │                                     │
   │ Usuario: Administrator              │
   │ IP Atacante: 203.45.67.89           │
   │                                     │
   │ MITRE ATT&CK:                       │
   │ • T1110: Brute Force                │
   │ • T1078: Valid Accounts             │
   │                                     │
   │ ACCIONES:                           │
   │ [🔍 Ver Dashboard Wazuh]             │
   │ [🚨 Bloquear IP]                    │
   │ [👤 Resetear Password]              │
   │ [📋 Ver Detalles]                   │
   └─────────────────────────────────────┘

     ↓

HORA 14:31:05
═════════════════════════════════════════════════════════════
[POWER AUTOMATE]

Recibe JSON de Wazuh
  → Convierte a Adaptive Card
  → Publica en Teams

[WEBHOOK URL]
https://outlook.webhook.office.com/
webhookb2/aV2d3e4f5g6...
POST: Alerta

     ↓

HORA 14:31:07
═════════════════════════════════════════════════════════════
[MICROSOFT TEAMS]

🔔 NOTIFICACIÓN EN CANAL #SEGURIDAD

Usuario: @team-seguridad
Mensaje: "⚠️ Nueva alerta de seguridad"

[VER DETALLES]
  Nivel: 12
  Tipo: Brute Force
  Usuario: Administrator
  IP: 203.45.67.89
  
[ABRIR WAZUH DASHBOARD]
  Click → Ve todos los eventos en detail
  Click → Ve historial del usuario
  Click → Ve otras IPs de donde entró

═════════════════════════════════════════════════════════════

REACCIÓN DEL EQUIPO:
1. Lee alerta en Teams (5 segundos)
2. Hace click → Ve dashboard Wazuh (30 segundos)
3. Confirma: "Es realmente ataque" (1 minuto)
4. Toma acciones:
   - Bloquea IP atacante (firewall)
   - Resetea password de admin
   - Abre ticket de incident
   - Agrega evento a análisis
```

---

## 📊 LOS DATOS QUE SE INTERCAMBIAN

### Datos que AGENTE envía a MANAGER

```json
{
  "timestamp": "2026-03-16T14:30:20",
  "computer": "DESKTOP-JUAN",
  "logfile": "Security Event Log",
  "raw_log": "Microsoft-Windows-Security-Auditing: Event ID 4625...",
  
  "decoded_data": {
    "event_id": "4625",
    "user": "DOMAIN\\Administrator", 
    "source_ip": "203.45.67.89",
    "status": "Failed",
    "reason": "Invalid password"
  }
}
```

**Tamaño:**
- Sin comprimir: ~2-5 KB
- Comprimido: ~200-500 bytes
- Encriptado: igual size + header TLS

---

### Datos que MANAGER envía a TEAMS

```json
{
  "@type": "MessageCard",
  "summary": "Wazuh Security Alert",
  
  "themeColor": "ff0000",
  
  "sections": [{
    "activityTitle": "🔴 Resumen de Alertas",
    "facts": [
      {"name": "Severidad", "value": "CRÍTICO (12)"},
      {"name": "Total Alertas", "value": "3"},
      {"name": "Agente", "value": "SERVIDOR-01"},
      {"name": "Usuario", "value": "Administrator"},
      {"name": "IP Atacante", "value": "203.45.67.89"}
    ]
  }],
  
  "potentialAction": [{
    "name": "Ver en Wazuh",
    "targets": [{
      "os": "default",
      "uri": "https://wazuh-manager:5601/..."
    }]
  }]
}
```

**Tamaño:**
- ~5-10 KB por resumen
- Una vez cada 3 alertas o 24h

---

## 🔐 SEGURIDAD EN LA COMUNICACIÓN

### PC → Manager

```
┌─────────────────────┐
│ Data en PC          │
│ (PLAINTEXT)         │
└──────┬──────────────┘
       │
       │ TLS 1.2+
       │ • Certificado del Agente
       │ • Certificado del Manager
       │ • 2-way verification
       │
       ▼
┌─────────────────────┐
│ Data en Internet    │
│ (ENCRYPTED)         │
│ 203.45.67.89 (IP    │
│  se ve, pero datos  │
│  son secreto)       │
└──────┬──────────────┘
       │
       │ TLS decrypt
       │
       ▼
┌─────────────────────┐
│ Data en Manager     │
│ (PLAINTEXT)         │
└─────────────────────┘
```

### Manager → Teams

```
Manager → HTTPS (encrypted) → Power Automate → HTTPS → Teams

Tres niveles de seguridad:
1. TLS entre Manager y Power Automate
2. Microsoft 365 seguridad interna
3. Teams apenas se recibe
```

---

## 🎯 CONFIGURACIÓN BÁSICA PARA TEAMS

### Lo Mínimo que Necesitas

**En `/var/ossec/etc/ossec.conf`:**

```xml
<integration>
    <name>custom-teams</name>
    <enabled>yes</enabled>
    <webhook_url>https://outlook.webhook.office.com/webhookb2/...</webhook_url>
    <alert_format>json</alert_format>
    <rule_id>100,101,102,...</rule_id>  <!-- Qué reglas enviar -->
    <group>authentication,compliance</group>
    <level>8</level>  <!-- Nivel mínimo para alertar -->
    <event_processing>summary</event_processing>
</integration>
```

**En `/var/ossec/integrations/custom-teams-summary.py`:**

```python
# Configuración al principio del script:

WEBHOOK_URL = "https://outlook.webhook.office.com/..."
CACHE_FILE = "/var/ossec/logs/teams_alerts_cache.pkl"
SUMMARY_INTERVAL_HOURS = 24  # Enviar cada 24h
MAX_ALERTS_BEFORE_SUMMARY = 3  # O al alcanzar 3 alertas
CRITICAL_LEVEL = 15  # Enviar inmediatamente si >= 15
```

---

## ⚡ CASOS ESPECIALES

### Caso 1: Alerta CRÍTICA (Level 15+)

```
Evento: "Malware detectado - ransomware"
Level: 15 (CRÍTICO)

├─ Se GENERA ALERTA
├─ Se comprueba: ¿Level >= 15?
├─ Respuesta: SÍ
├─ NO se espera caché
├─ NO se espera 24h
├─ ENVÍA INMEDIATAMENTE a Teams
└─ El sistema avisa: 🔴 ALERTA CRÍTICA

En Teams:
  Notificación ROJA + SONIDO
  Sin batching
  Acción requerida: YA
```

### Caso 2: Evento Benigno (Level < 3)

```
Evento: "Usuario hizo login" 
Level: 1 (Normal)

├─ Se GENERA documento
├─ Se guarda en histórico
├─ ¿Level >= 3? NO
├─ NO se crea alerta
├─ NO se envía a Teams
├─ Solo está en logs/archives/ para auditoría

En Teams:
  Nada (silencio)
  Esto es normal, no molesta
```

### Caso 3: Manager No Conectado a Internet

```
Manager crea alerta
  ├─ Intenta enviar a Teams
  ├─ Fail: No internet
  ├─ Reintento automático (backoff)
  │  └─ 5 segundos
  │  └─ 30 segundos
  │  └─ 5 minutos
  │  └─ 1 hora
  ├─ Mientras: Alertas se guardan en caché
  └─ Cuando vuelve internet: envía todo acumulado

En Teams:
  Se reciben alertas en lotes (cuando vuelve internet)
  No se pierden datos
```

---

## 📈 FLUJO RESUMIDO EN PUNTOS

```
1. EVENTO SUCEDE
   └─ Windows/Linux registra

2. AGENTE LEE
   └─ Comprime + encripta

3. AGENTE ENVÍA
   └─ Puerto 1514 TLS

4. MANAGER RECIBE
   └─ Descomprime + verifica

5. MANAGER ANALIZA
   └─ Decoder → Rule Match → Correlate

6. ALERTA GENERADA
   ├─ Level 1-2 → IGNORAR
   ├─ Level 3-10 → GUARDAR histórico
   ├─ Level 11-14 → CACHÉ + ESPERAR
   └─ Level 15+ → ENVIAR YA

7. SCRIPT INTEGRACIÓN
   └─ Crea resumen bonito

8. TEAMS RECIBE
   └─ Publica en canal

9. EQUIPO REACCIONA
   └─ Click → Dashboard → Investigación
```

---

## 🔍 CÓMO VER QUE FUNCIONA

### Ver eventos llegando (Línea de comandos Linux)

```bash
# En el Manager, ver eventos en tiempo real
tail -f /var/ossec/logs/archives/$(date +%Y/%m/%d)/archive.json

# Ver alertas específicas
grep "level.*10" /var/ossec/logs/alerts/alerts.json

# Ver logs de integración
tail -100 /var/ossec/logs/wazuh.log | grep "integratord"
```

### Ver en el Dashboard Wazuh

```
1. Abre https://MANAGER-IP:5601
2. Ve a "Threat Detection"
3. Filtra por nivel >= 8
4. Haz click en cualquier alerta
5. Ve: usuario, IP, regla, tiempo, detalles
```

### Ver en Teams

```
1. Abre Teams
2. Va a canal #SEGURIDAD
3. Busca mensajes de Wazuh
4. Haz click en "[VER DASHBOARD]"
5. Te abre Wazuh automáticamente
```

---

## ✅ VERIFICAR INTEGRACIÓN

**Checklist de 1 minuto:**

```
☐ Agentes "Active" en Dashboard
☐ Eventos entrando (ves líneas nuevas en archive.json)
☐ Alertas generadas (ves en Dashboard > Threat Detection)
☐ Webhook URL valida (curl test funciona)
☐ Alertas nivel 11+ aparecen en Teams dentro de 3 eventos
☐ Alerta nivel 15+ aparece en Teams en < 5 segundos

SI TODAS están ✓:
  ¡INTEGRACIÓN FUNCIONANDO!

SI alguna está ☐:
  Ver sección "Troubleshooting" en archivo técnico
```

---

## 🎓 RESUMEN FINAL

**La comunicación Wazuh + Teams es:**

1. **Automática** - No necesitas hacer nada, funciona solo
2. **Inteligente** - Solo alerta de cosas importantes
3. **Segura** - Encriptada end-to-end
4. **Rápida** - 1-5 segundos en casos graves
5. **Accionable** - Botones en Teams para investigar

**El flujo es:**
```
Evento → Agente → Manager → Analiza → ¿Malo? → Teams → Acción
```

**Tus 101 reglas hacen:**
```
Detectan tipos de ataque → Niveles automáticos → Teams notifica
```
