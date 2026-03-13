# 📚 Learning Path - Ruta de Aprendizaje

Una guía estructurada para aprender desde cero cómo funciona este proyecto.

**Duración total:** ~2-3 horas | **Nivel:** Principiante a Intermedio

---

## 🎯 ¿Qué Aprenderás?

Al completar este learning path, entenderás:

1. **Conceptos fundamentales**
   - Qué es Wazuh y cómo usa reglas
   - Cómo funcionan las 101 reglas personalizadas
   - Arquitectura de caché y acumulación de alertas

2. **Procedimientos prácticos**
   - Instalar y configurar el proyecto
   - Crear integraciones con Teams
   - Diagnosticar y resolver problemas

3. **Habilidades técnicas**
   - Validar y testear reglas
   - Analizar eventos en logs
   - Ajustar severidades según necesidades

---

## 📖 Estructura de Aprendizaje

```
┌─────────────────────────────────────────────────────┐
│  MÓDULO 1: Fundamentos (30 min)                     │
│  Entender QUÉ y POR QUÉ                             │
├─────────────────────────────────────────────────────┤
│  ↓                                                  │
│  MÓDULO 2: Setup Básico (40 min)                    │
│  Instalar y validar                                 │
├─────────────────────────────────────────────────────┤
│  ↓                                                  │
│  MÓDULO 3: Integración Teams (30 min)               │
│  Conectar notificaciones                            │
├─────────────────────────────────────────────────────┤
│  ↓                                                  │
│  MÓDULO 4: Entendiendo Reglas (40 min)              │
│  Cómo funcionan las 101 reglas                      │
├─────────────────────────────────────────────────────┤
│  ↓                                                  │
│  MÓDULO 5: Operación & Troubleshooting (30 min)     │
│  Mantener y diagnosticar                           │
└─────────────────────────────────────────────────────┘
```

---

## 📚 MÓDULO 1: Fundamentos (30 min)

### Objetivo
Entender **qué** es este proyecto y **por qué** existe.

### 1.1 El Problema (5 min) 📋

**Situación inicial:**
- Wazuh genera ~40 alertas por día
- Muchas alertas son "ruido" (no importante)
- Admin está abrumado por alertas
- No sabe cuáles son críticas
- Alertas llegan desorganizadas

**Pregunta:** ¿Cómo reducir el ruido sin perder eventos importantes?

### 1.2 La Solución (10 min) 💡

Este proyecto soluciona el problema con **3 estrategias:**

#### Estrategia 1: Mejores Reglas (101 custom)
```
ANTES: Solo reglas base de Wazuh
  ├─ Detecta eventos comunes
  └─ Mucho ruido

DESPUÉS: 101 reglas personalizadas
  ├─ Detecta eventos críticos específicos
  ├─ Ignora eventos normales
  └─ Menos ruido → Mejor señal
```

**Cómo funciona:**
- Reglas Windows (89) → Eventos específicos de seguridad Windows
- Reglas Linux (7) → Autenticación y cuentas sospechosas
- Reglas de Override (5) → Ajustes por contexto

**Resultado:** 40 alertas/día → 5-8 alertas/día (80% reducción)

#### Estrategia 2: Acumulación Inteligente
```
ANTES: Cada alerta → Notification inmediata
  ├─ Notificaciones constantemente
  └─ Admin desconecta notificaciones

DESPUÉS: Sistema de acumulación
  ├─ Alertas normales → Se acumulan (3 alertas)
  ├─ Alertas críticas → Se envían inmediatamente
  └─ Resumen automático cada 24h
```

**Cómo funciona:**
- Si alerta tiene nivel < 15: Entra a caché
- Cuando caché tiene 3+ alertas O 24 horas pasaron: Enviar resumen
- Si alerta tiene nivel ≥ 15: Enviar inmediatamente

**Resultado:** Menos interrupciones + Info consolidada

#### Estrategia 3: Teams Integration
```
ANTES: Alertas solo en Wazuh Dashboard
  ├─ Admin debe revisar Dashboard constantemente
  └─ Alerga que evento crítico pasó

DESPUÉS: Alertas en Teams (donde trabaja el admin)
  ├─ Notificaciones en tiempo real
  ├─ Resúmenes consolidados
  └─ Con botones para ir al Dashboard
```

### 1.3 Diagrama General (10 min) 📊

```
┌──────────────────┐
│  Eventos Windows │
│  Eventos Linux   │
└────────┬─────────┘
         │
         ↓
┌─────────────────────────────────┐
│  Wazuh Manager                  │
│  ├─ Base Rules (4,000+)         │
│  ├─ Custom Rules (101) ⭐        │  ← Las nuestras
│  └─ CDB Lists                   │
└────────┬───────────────────────┘
         │
         ↓ Eventos que coinciden con nuestras reglas
┌─────────────────────────────────┐
│  Alert Processing               │
│  ├─ Level < 15 → caché          │
│  └─ Level ≥ 15 → inmediato ⚠️   │
└────────┬───────────────────────┘
         │
         ↓
     ┌───┴───┐
     │       │
     ↓       ↓
  ┌──────┐ ┌──────────────┐
  │Caché │ │Custom Script │
  └──┬───┘ └──────┬───────┘
     │           │
     ↓           ↓
  ┌─────────────────────┐
  │  Teams Webhook      │  ← Power Automate
  │  (Microsoft 365)    │
  └─────────┬───────────┘
            │
            ↓
    ┌───────────────┐
    │  Microsoft    │
    │  Teams        │  ← Admin recibe notificación
    │  Channel      │
    └───────────────┘
```

**Flujo clave:**
```
Evento Windows → Wazuh lo ve → "¿Coincide con una regla custom?"
  ├─ NO → Ignorar (ruido eliminado ✓)
  └─ YES → ¿Level ≥ 15?
       ├─ SÍ → Enviar a Teams inmediatamente ⚡
       └─ NO → Guardar en caché
                Si caché tiene 3+ alertas o 24h → Enviar resumen a Teams
```

### 1.4 Conceptos Clave (5 min) 🔑

| Concepto | Qué es | Por qué importa |
|----------|--------|-----------------|
| **Regla Wazuh** | XML que describe evento a detectar | Define qué alertas generar |
| **Level (1-15)** | Severidad de alerta | Determina si enviar inmediatamente |
| **mitre (ATT&CK)** | Mapping a técnicas de ataque conocidas | Contexto de amenaza |
| **Caché JSON** | Almacenamiento temporal de alertas | Acumula alertas para resúmenes |
| **Webhook Teams** | URL que recibe JSON → envía mensaje Teams | Liga Wazuh con Teams |
| **CDB List** | "Base de datos" de cuentas sospechosas | Detección de abuso de cuentas |

---

## 💻 MÓDULO 2: Setup Básico (40 min)

### Objetivo
Instalar el proyecto **entendiendo cada paso**.

### 2.1 Pre-instalación: Verificar Requisitos (5 min) ✓

**Antes de empezar, necesitas:**

```bash
# 1. ¿Tengo Wazuh Manager instalado?
systemctl status wazuh-manager
# Esperado: active (running) ✓

# 2. ¿Tengo acceso de root?
sudo whoami
# Esperado: root ✓

# 3. ¿Python 3 está disponible?
which python3
# Esperado: /usr/bin/python3 ✓

# 4. ¿Tengo internet en el servidor?
curl https://www.google.com
# Esperado: HTML response ✓
```

**Si alguno falla:** Arreglar antes de continuar

### 2.2 Descarga de Archivos (5 min) 📥

**¿Por qué?** Necesitas los 3 archivos de reglas + CDB list

**Cómo hacerlo:**

```bash
# PASO 1: Conectar al servidor Wazuh
ssh root@<IP-WAZUH>

# PASO 2: Ir a carpeta de reglas
cd /var/ossec/etc/rules/
# ¿Por qué esta carpeta? Porque Wazuh busca reglas aquí

# PASO 3: Descargar las 3 reglas personalizadas
wget https://raw.githubusercontent.com/TU-USER/wazuh-custom-rules-teams/main/rules/custom_windows_security_rules.xml
wget https://raw.githubusercontent.com/TU-USER/wazuh-custom-rules-teams/main/rules/custom_windows_overrides.xml
wget https://raw.githubusercontent.com/TU-USER/wazuh-custom-rules-teams/main/rules/custom_linux_security_rules.xml

# PASO 4: Verificar que se descargaron
ls -la custom_*.xml
# Esperado: 3 archivos listados
```

**¿Qué es esto?**
- `custom_windows_security_rules.xml` = **89 reglas** Windows
- `custom_windows_overrides.xml` = **5 reglas** de ajustes
- `custom_linux_security_rules.xml` = **7 reglas** Linux

### 2.3 Instalar CDB List (5 min) 📝

**¿Por qué?** Una de nuestras reglas necesita una "lista" de cuentas sospechosas

**Cómo hacerlo:**

```bash
# PASO 1: Ir a carpeta de listas
cd /var/ossec/etc/lists/

# PASO 2: Descargar archivo de cuenta genéricas
wget https://raw.githubusercontent.com/TU-USER/wazuh-custom-rules-teams/main/lists/no-nominal-account

# PASO 3: Compilar la lista (convertir a formato .cdb)
/var/ossec/bin/wazuh-cdb-make -i no-nominal-account -o no-nominal-account.cdb
# ¿Por qué compilar? CDB es formato binario = más rápido para búsquedas

# PASO 4: Verificar compilación
ls -la no-nominal-account*
# Esperado: 2 archivos (texto + .cdb)
```

**¿Qué es no-nominal-account?**
- Lista de cuentas "genéricas" (admin, test, root, service, etc)
- Cuando alguien accede con cuenta "test" → ALERTA
- Porque "test" no debería acceder en producción

### 2.4 Validar Instalación (5 min) ✓

**¿Por qué?** Confirmar que Wazuh puede leer las nuevas reglas

```bash
# PRUEBA 1: Valida sintaxis XML de reglas
/var/ossec/bin/wazuh-logtest -t
# Esperado: "Compilation OK ✓"

# PRUEBA 2: Ver cuántas reglas tiene Wazuh ahora
/var/ossec/bin/grep -c "<rule" /var/ossec/etc/rules/custom_*.xml
# Esperado: 101 reglas

# PRUEBA 3: Verificar que Wazuh inicia sin errores
systemctl restart wazuh-manager
systemctl status wazuh-manager
# Esperado: active (running) ✓

# PRUEBA 4: Ver logs por cualquier warning
tail -20 /var/ossec/logs/ossec.log | grep -i error
# Esperado: (vacío = buen signo)
```

### 2.5 Prueba Rápida (10 min) 🧪

**¿Por qué?** Confirmar que una regla realmente funciona

**Cómo hacerlo:**

```bash
# Simulamos un evento que debería dispara la regla 200001
# (Múltiples intentos fallidos de login)

# PASO 1: Crear evento de test
echo "2025-03-13 14:30:45 DESKTOP-ABC: Authentication failed for user john from 192.168.1.100" | /var/ossec/bin/wazuh-logtest

# Esperado: Output mostrando que Rule 200001 matcheó ✓

# PASO 2: Si quieres testear todas las 101 reglas, ejecuta:
sudo bash scripts/test_all_rules.sh
# Duración: ~5 minutos
# Resultado: Alertas generadas para cada regla
```

**Conceptos que aprendiste:**
- Dónde va cada archivo en Wazuh
- Cómo compilar CDB lists
- Validación básica de reglas
- Cómo probar que una regla funciona

---

## 🔗 MÓDULO 3: Integración Teams (30 min)

### Objetivo
Conectar Wazuh con Teams para recibir notificaciones.

### 3.1 Entender el Flujo (10 min) 🔄

**¿Cómo comunica Wazuh con Teams?**

```
1. Wazuh genera alerta ✓
   └─ "Rule 200001 disparó con Level 12"

2. Wazuh ve que Level < 15
   └─ NO enviar inmediatamente

3. Wazuh busca script integrador
   └─ /var/ossec/integrations/custom-teams-summary.py

4. Script recibe la alerta
   └─ La guarda en caché JSON

5. Script chequea si debe enviar
   └─ ¿Caché > 3 alertas O >24h pasaron?
   └─ SÍ → Armar resumen + enviar a Teams

6. Script hace HTTP POST a Teams Webhook
   └─ Teams recibe el JSON
   └─ Power Automate convierte a mensaje bonito
   └─ Admin ve mensaje en Teams Channel

TODO esto ocurre en < 1 segundo ⚡
```

### 3.2 Crear Webhook en Teams (10 min) 🪝

**¿Qué es un Webhook?** URL especial que acepta información y la convierte en mensaje

**Cómo crear:**

```
PASO 1: Abrir Power Automate
  → Ve a https://make.powerautomate.com
  → Loguea con tu cuenta Microsoft 365

PASO 2: Crear nuevo flow
  → Click "Create" → "Cloud flow" → "Automated cloud flow"
  → Nombre: "Wazuh Alerts"
  → Trigger: "When a HTTP request is received"

PASO 3: Configurar trigger HTTP
  → Generar esquema JSON (pega esto):
  
  {
    "type": "object",
    "properties": {
      "rule_id": {"type": "string"},
      "level": {"type": "integer"},
      "agent": {"type": "string"},
      "message": {"type": "string"}
    }
  }

PASO 4: Agregar acción Teams
  → New step → "Post a message in Teams"
  → Team: Selecciona tu equipo
  → Channel: #incidents (o donde quieras)
  → Message: 
    Rule: @{triggerBody()?['rule_id']}
    Level: @{triggerBody()?['level']}
    ...

PASO 5: Guardar y obtener URL
  → Save
  → Copy "HTTP POST URL" (es el webhook)
  → (Este es tu secret - no compartir públicamente)
```

**URL webhook se ve así:**
```
https://prod-xx.eastus.logic.azure.com:443/workflows/abc123/triggers/manual/paths/invoke?api-version=2016-06-01&sp=%2Factivities...
```

### 3.3 Configurar Variables de Entorno (5 min) 🔐

**¿Por qué?** Decirle al script dónde enviar las alertas

**Cómo hacerlo:**

```bash
# PASO 1: Crear archivo de configuración
sudo nano /var/ossec/etc/teams-integration.env

# PASO 2: Pegar este contenido:
export WAZUH_TEAMS_WEBHOOK_URL="https://prod-xx.eastus.logic.azure.com:443/workflows/..."
export WAZUH_DASHBOARD_URL="https://wazuh.tu-empresa.com"
export WAZUH_SUMMARY_INTERVAL_HOURS=24
export WAZUH_CRITICAL_LEVEL=15

# PASO 3: Guardar (Ctrl+X, Y, Enter)

# PASO 4: Asegurar permisos
sudo chmod 640 /var/ossec/etc/teams-integration.env
```

**¿Qué significa cada variable?**
- `WEBHOOK_URL` - Dónde enviar las alertas (Teams)
- `DASHBOARD_URL` - Link al Wazuh Dashboard (para botón en Teams)
- `SUMMARY_INTERVAL_HOURS` - Cada cuántas horas enviar resumen
- `CRITICAL_LEVEL` - Qué nivel es crítico (enviar inmediatamente)

### 3.4 Instalar Script Integrador (5 min) 🔧

**¿Qué es?** El programa que recibe alertas → las acumula → envía a Teams

**Cómo hacerlo:**

```bash
# PASO 1: Copiar script
sudo cp integrations/custom-teams-summary.py /var/ossec/integrations/
sudo chmod +x /var/ossec/integrations/custom-teams-summary.py

# PASO 2: Hacer ejecutable por Wazuh
sudo chown root:wazuh /var/ossec/integrations/custom-teams-summary.py
sudo chmod 750 /var/ossec/integrations/custom-teams-summary.py

# PASO 3: Verificar que está listo
ls -la /var/ossec/integrations/custom-teams-summary.py
# Esperado: archivo con permisos rwxr-x---
```

**Conceptos que aprendiste:**
- Cómo funciona un webhook
- Dónde guarda Wazuh las variables de integración
- Cómo instalar un script integrador

---

## 📊 MÓDULO 4: Entendiendo Reglas (40 min)

### Objetivo
Aprender **cómo funcionan** nuestras 101 reglas.

**Ver:** [RULES_REFERENCE.md](./RULES_REFERENCE.md) - Documento completo con todas las 101 reglas

### 4.1 Anatomy de una Regla (10 min)

**Una regla Wazuh es un XML que dice:**
"Si ves un evento con estas características → genera alerta con este nivel"

**Ejemplo simple:**

```xml
<rule id="200001" level="10">
  <if_sid>4625</if_sid>
  <description>Multiple failed logon attempts detected</description>
  <match>Failed logon</match>
  <mitre>
    <id>T1110</id>  <!-- Brute Force técnica ATT&CK -->
  </mitre>
</rule>
```

**Traducción:**
```
ID: 200001          ← Identificador único de esta regla
Level: 10           ← Severidad (1-15)
IF_SID: 4625        ← Si el evento es Windows Event 4625 (Failed Logon)
Description: ...    ← Mensaje descriptivo
Match: ...          ← Patrón a buscar en el evento
MITRE: T1110        ← Esta alerta indica intento de Brute Force
```

### 4.2 Los 3 Archivos de Reglas (10 min)

#### Archivo 1: custom_windows_security_rules.xml (89 reglas)
**Propósito:** Detectar eventos de seguridad Windows importantes

**Categorías y para qué detectan:**

```
1. Kerberos Authentication (6 reglas)
   └─ Detecta: Ataques de tickets Kerberos

2. Service Installation (2 reglas)
   └─ Detecta: Servicios maliciosos instalados

3. Process Execution (5 reglas)
   └─ Detecta: CMD, PowerShell malicioso

4. Credential Access (2 reglas)
   └─ Detecta: LSASS access (robo de credenciales)

5. Account Management (15 reglas)
   └─ Detecta: Creación de usuarios sospechosos
```

**Pregunta:** ¿Por qué tantas reglas? Respuesta: Windows genera ~1000s de eventos/día. Queremos detectar solo los "malos" y ignorar los "normales".

#### Archivo 2: custom_windows_overrides.xml (5 reglas)
**Propósito:** Modular el comportamiento de reglas base de Wazuh

**Ejemplo:**
```xml
<!-- Regla base Wazuh tiene level=4 (bajo) -->
<!-- Nosotros queremos level=8 (más alto) para este evento -->
<rule id="60103" level="8">  <!-- Override a 8 -->
  <if_sid>4724</if_sid>      <!-- Password Reset event -->
  <description>Password reset overridden to ALTO</description>
</rule>
```

#### Archivo 3: custom_linux_security_rules.xml (7 reglas)
**Propósito:** Detectar anomalías Linux + correlación cross-platform

**Ejemplo de correlación:**
```
Si ves "failed SSH login desde Windows + cuenta 'test'"
    ↓
Rule 200004 dispara: CRÍTICO
    ↓
Porqué: 'test' es acuenta de prueba que NO debería acceder
```

### 4.3 Severidades Explicadas (10 min) 📊

**¿Por qué existen 15 niveles?**

```
Level 0-3:   INFO (ignorar)
  └─ "User logged in" - evento normal

Level 4-6:   LOW (no urgente)
  └─ "Password changed" - cambio legítimo

Level 7-10:  MEDIUM (revisar)
  └─ "Suspicious process launched" - podría ser problema

Level 11-14: HIGH (investigar)
  └─ "Failed login brute force" - probable ataque

Level 15:    CRITICAL (inmediato)
  └─ "Boot sector modified" - ataque Rootkit en progreso
```

**Nuestros levels:**
- Alertas < 15 → Acumular en caché
- Alertas = 15 → Enviar inmediatamente a Teams ⚡

**¿Por qué?** Queremos notificar al admin de inmediato solo para ataques en progreso.

### 4.4 MITRE ATT&CK Mapping (10 min) 🎯

**¿Qué es MITRE ATT&CK?**

Es un catálogo de técnicas de ataque reales usadas por adversarios:
```
T1110: Brute Force
  └─ Atacante intenta múltiples contraseñas
  └─ Nuestra Rule 200001 detecta esto

T1548: Abuse Elevation Control
  └─ Atacante intenta elevar privilegios
  └─ Nuestras Rules detectan esto

T1078: Valid Accounts
  └─ Atacante usa credenciales legítimas robadasas
  └─ Nuestras Rules detectan uso anómalo
```

**Por qué importa:**
- Si tu regla dispara → Sabes qué tipo de ataque es
- Puedes correlacionar con otros eventos
- Informes de compliance se completan automáticamente

---

## 🔧 MÓDULO 5: Operación & Troubleshooting (30 min)

### Objetivo
Mantener el sistema funcionando y resolver problemas.

**Ver:** [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) - Guía completa

### 5.1 Monitoreo Diario (5 min) 📊

**¿Qué debo revisar cada día?**

```bash
# 1. ¿Las reglas cargan sin errores?
tail -20 /var/ossec/logs/ossec.log | grep -i error
# Esperado: (vacío) = bien ✓

# 2. ¿Cuántas alertas generamos hoy?
grep "rule: 200" /var/ossec/logs/alerts/alerts.json | wc -l
# Esperado: 5-20 alertas (depende de tu entorno)

# 3. ¿Están llegando los mensajes a Teams?
tail -20 /var/ossec/logs/teams_integration.log | grep "sent"
# Esperado: múltiples menciones de "sent"

# 4. ¿El caché no crece demasiado?
ls -lh /var/ossec/logs/teams_alerts_cache.json
# Esperado: < 50MB
```

### 5.2 Troubleshooting Paso a Paso (15 min) 🆘

**Situación 1: "Las alertas no llegan a Teams"**

```
Diagnóstico en 5 pasos:

PASO 1: ¿Wazuh genera alertas?
  → tail -f /var/ossec/logs/alerts/alerts.json
  → ¿Ves eventos nuevos? SÍ → PASO 2 | NO → problema en reglas

PASO 2: ¿El script Teams se ejecuta?
  → tail -f /var/ossec/logs/teams_integration.log
  → ¿Ves "Alert received" o "Alert processed"? 
  → SÍ → PASO 3 | NO → problema en scripting

PASO 3: ¿Webhook URL es correcta?
  → cat /var/ossec/etc/teams-integration.env | grep WEBHOOK
  → ¿Comienza con https://? SÍ → PASO 4 | NO → copiar URL nuevamente

PASO 4: ¿Conectividad a Teams?
  → curl -X POST -d '{}' https://tu-webhook-url
  → ¿Respuesta 200 OK? SÍ → PASO 5 | NO → webhook expiró

PASO 5: Power Automate flow activo?
  → Ve a https://make.powerautomate.com
  → Flow debe estar "ON" (no gris)
  → Si está OFF activarlo
```

**Situación 2: "Recibo alertas pero son ruido"**

```
Solución: Aumentar severidad mínima

PASO 1: Ir a ossec.conf
  → sudo nano /var/ossec/etc/ossec.conf
  
PASO 2: Buscar sección integration
  → <level>11</level>  ← Cambiar este número

PASO 3: Aumentar a 12 o 13
  → <level>13</level>  ← Solo alertas MÁS importantes

PASO 4: Restart Wazuh
  → sudo systemctl restart wazuh-manager
```

### 5.3 Logs Importantes (10 min) 📝

**¿Dónde buscar información?**

```
/var/ossec/logs/ossec.log
  └─ Log principal de Wazuh
  └─ Errores de configuración
  └─ Warnings de reglas

/var/ossec/logs/alerts/alerts.json
  └─ Cada alerta generada
  └─ Información completa del evento
  └─ DEBUG: grep "rule: 200" para ver nuestras reglas

/var/ossec/logs/teams_integration.log
  └─ Cada envío a Teams
  └─ Errores de webhook
  └─ DEBUG: grep "ERROR" para problemas

/var/ossec/etc/rules/
  └─ Los archivos XML de reglas
  └─ Editar aquí si necesitas custom rules
```

**Comandos útiles:**

```bash
# Ver últimas alertas críticas (level ≥ 15)
jq 'select(.rule.level >= 15)' /var/ossec/logs/alerts/alerts.json | tail -5

# Ver alertas de una regla específica
grep "rule_id\": \"200001" /var/ossec/logs/alerts/alerts.json | wc -l

# Ver errores en logs
tail -100 /var/ossec/logs/ossec.log | grep -i "error\|critical"

# Ver si caché tiene datos
cat /var/ossec/logs/teams_alerts_cache.json | python3 -m json.tool | head -20
```

---

## 🎓 Resumen de Aprendizaje

### Conceptos Clave Aprendidos

```
┌────────────────────────────────────────────┐
│ Wazuh → detecta eventos                    │
│   ↓                                        │
│ Nuestras 101 reglas → filtran ruido       │
│   ↓                                        │
│ Custom script → acumula alertas            │
│   ↓                                        │
│ Teams webhook → notifica al admin          │
│   ↓                                        │
│ Admin actúa sobre incidente                │
└────────────────────────────────────────────┘
```

### Skills Técnicas Adquiridas

- [x] Entender arquitectura Wazuh
- [x] Instalar reglas personalizadas
- [x] Configurar integraciones
- [x] Validar y testear
- [x] Diagnosticar problemas
- [x] Leer logs y eventos
- [x] Ajustar configuraciones

### Próximos Pasos

1. **Nivel Intermedio:** Crear reglas personalizadas propias
2. **Nivel Avanzado:** Analizar eventos en Wazuh Dashboard
3. **Nivel Pro:** Integrar con Splunk/ELK stack

---

## 📚 Referencias Cruzadas

- **Quiero instalar paso a paso:** [QUICK_START.md](./QUICK_START.md)
- **Quiero ver todas las reglas:** [RULES_REFERENCE.md](./RULES_REFERENCE.md)
- **Tengo un problema:** [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
- **Quiero entender Teams:** [TEAMS_SETUP.md](./TEAMS_SETUP.md)
- **Quiero ver ejemplos:** [../examples/](../examples/)

---

**¡Felicitaciones!** 🎉  
Completaste el Learning Path. Ya entiendes cómo funciona el proyecto de arriba a abajo.

**Siguiente:** Instala usando [QUICK_START.md](./QUICK_START.md) o [INSTALLATION.md](./INSTALLATION.md).

---

Last Updated: 2025-03-13  
Learning Path Status: ✅ Complete
