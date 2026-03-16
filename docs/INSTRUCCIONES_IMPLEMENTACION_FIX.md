# 🔧 IMPLEMENTACIÓN DEL FIX - Alertas de Brute Force a Teams

## Resumen Rápido

**Problema:** Las alertas de correlación de ataque brute force (Reglas 200004, 200005) no llegan a Teams correctamente.

**Causa:** El script `custom-teams-summary.py` no extrae correctamente la información de usuarios en alertas de correlación.

**Solución:** Reemplazar el script con la versión mejorada que:
- ✅ Detecta alertas de correlación
- ✅ Extrae usuarios de eventos relacionados
- ✅ Muestra información de eventos relacionados en Teams
- ✅ Mejor manejo de errores

---

## 📋 Pasos de Implementación

### PASO 1: Backup del Script Original

```bash
# En el servidor 10.27.20.171, conectarse como root:
ssh root@10.27.20.171

# Hacer backup del script actual
sudo cp /var/ossec/integrations/custom-teams-summary.py \
        /root/backups/custom-teams-summary.py.backup-$(date +%Y%m%d)

# Verificar que se creó el backup
ls -lh /root/backups/custom-teams-summary.py.backup-*
```

### PASO 2: Copiar el Script Mejorado

```bash
# Opción A: Si tienes acceso al repo git
cd /opt/wazuh-custom-rules-teams
git pull  # Actualizar repositorio
ls -la custom-teams-summary.py  # Verificar que existe

# Copiar el script mejorado
sudo cp custom-teams-summary.py /var/ossec/integrations/custom-teams-summary.py

# Opción B: Si no tienes git, descargarlo directamente
# Desde tu máquina Windows, el archivo está en:
# C:\Users\Mateo Villablanca\Desktop\WORCKBENCH\custom-teams-summary-FIXED.py
# 
# Copiar al servidor (desde Windows, en PowerShell):
# scp custom-teams-summary-FIXED.py root@10.27.20.171:/root/
# Luego en el servidor:
# sudo cp /root/custom-teams-summary-FIXED.py /var/ossec/integrations/custom-teams-summary.py
```

### PASO 3: Verificar Permisos

```bash
# Asegurar permisos correctos
sudo chown root:wazuh /var/ossec/integrations/custom-teams-summary.py
sudo chmod 750 /var/ossec/integrations/custom-teams-summary.py
sudo chmod +x /var/ossec/integrations/custom-teams-summary.py

# Verificar
ls -la /var/ossec/integrations/custom-teams-summary.py
# Debería ver: -r-xr-x--- 1 root wazuh ...
```

### PASO 4: Verificar Sintaxis Python

```bash
# Validar que el script sea válido
python3 -m py_compile /var/ossec/integrations/custom-teams-summary.py

# Si no hay error, está OK
echo $?  # Debería mostrar 0
```

### PASO 5: Reiniciar Wazuh Manager

```bash
# Reiniciar el servicio
sudo systemctl restart wazuh-manager

# Verificar que está corriendo
sudo systemctl status wazuh-manager

# Ver logs
sudo tail -20 /var/ossec/logs/ossec.log | grep custom-teams
```

---

## 🧪 PRUEBAS

### TEST 1: Alerta Simple (Acumulación Normal)

```bash
# Crear alerta de test (Nivel 12)
cat > /tmp/test-alert-simple.json << 'EOF'
{
  "timestamp": "2026-03-16T15:00:00",
  "agent": {"id": "001", "name": "Linux-Server-01"},
  "rule": {
    "id": "100001",
    "level": 12,
    "description": "Kerberos TGT Request - Test Alert",
    "mitre": {"id": ["T1078"]}
  },
  "data": {
    "srcip": "192.168.1.100",
    "srcuser": "testuser"
  },
  "full_log": "TEST LOG: Sample authentication event"
}
EOF

# Enviar al script
WEBHOOK=$(grep -oP '(?<=<hook_url>).*(?=</hook_url>)' /var/ossec/etc/ossec.conf)
echo "Webhook detectado: $WEBHOOK"

cat /tmp/test-alert-simple.json | \
  /var/ossec/integrations/custom-teams-summary.py "$WEBHOOK" 11 "custom-teams-summary"

# Resultado esperado:
# [INFO] Alert accumulated (1/3). Not sending yet.
```

### TEST 2: Alerta de Brute Force (Crítica - Debería enviarse inmediatamente)

```bash
# Crear alerta simulada de ataque brute force
cat > /tmp/test-alert-brute-force.json << 'EOF'
{
  "timestamp": "2026-03-16T15:05:30",
  "agent": {"id": "001", "name": "Linux-Server-01"},
  "rule": {
    "id": "200004",
    "level": 15,
    "description": "CRITICAL: Multiple SSH logins detected with non-nominal accounts from same IP (192.168.1.100) - Possible brute force attack",
    "frequency": 5,
    "timeframe": 120,
    "mitre": {"id": ["T1110", "T1078.003"]}
  },
  "data": {
    "srcip": "192.168.1.100",
    "related_events": [
      {
        "timestamp": "2026-03-16T15:05:00",
        "rule_id": "200001",
        "user": "admin"
      },
      {
        "timestamp": "2026-03-16T15:05:05",
        "rule_id": "200001",
        "user": "admin"
      },
      {
        "timestamp": "2026-03-16T15:05:10",
        "rule_id": "200001",
        "user": "root"
      },
      {
        "timestamp": "2026-03-16T15:05:15",
        "rule_id": "200001",
        "user": "admin"
      },
      {
        "timestamp": "2026-03-16T15:05:20",
        "rule_id": "200001",
        "user": "test"
      }
    ]
  },
  "full_log": "5 failed login attempts detected from 192.168.1.100"
}
EOF

# Enviar al script
cat /tmp/test-alert-brute-force.json | \
  /var/ossec/integrations/custom-teams-summary.py "$WEBHOOK" 11 "custom-teams-summary"

# Resultado esperado:
# [OK] Critical alert sent immediately (Rule 200004, Level 15)
```

### TEST 3: Verificar en Teams

Después de ejecutar los tests:

1. **Abre Microsoft Teams**
2. **Ve al canal "Wazuh-Alerts"** (o donde configuraste)
3. **Deberías ver:**
   - ✅ **Primera prueba**: Acumulada internamente (no se envía aún)
   - ✅ **Segunda prueba**: **Mensaje inmediato con:**
     - 🔴 ALERTA CRÍTICA - Nivel 15
     - 🔗 **Alerta de Correlación** - Múltiples eventos relacionados
     - **Rule ID:** 200004
     - **Usuario/Cuenta:** admin | root | test
     - **IP Origen:** 192.168.1.100
     - **Eventos Relacionados:** 5 intentos listados

---

## 🔍 MONITOREO POST-IMPLEMENTACIÓN

### Ver Logs de Integración

```bash
# En tiempo real
sudo tail -f /var/ossec/logs/integrations.log | grep custom-teams

# Último 50 líneas
sudo tail -50 /var/ossec/logs/integrations.log | grep custom-teams

# Buscar errores
sudo grep -i "error\|exception" /var/ossec/logs/integrations.log | tail -20
```

### Ver Alertas Generadas

```bash
# Alertas de nivel 11+
sudo tail -50 /var/ossec/logs/alerts/alerts.json | \
  jq 'select(.rule.level >= 11) | {rule: .rule.id, level: .rule.level, desc: .rule.description}'

# Último alerta completa
sudo tail -1 /var/ossec/logs/alerts/alerts.json | jq '.'
```

### Verificar la Caché de Alertas

```bash
# Ver si el archivo de caché existe
ls -lh /var/ossec/logs/teams_alerts_cache.pkl

# Verificar permisos
stat /var/ossec/logs/teams_alerts_cache.pkl
```

---

## ⚠️ TROUBLESHOOTING

### Si no aparece nada en Teams:

#### 1. Verificar que el webhook está activo

```bash
# Obtener webhook
WEBHOOK=$(grep -oP '(?<=<hook_url>).*(?=</hook_url>)' /var/ossec/etc/ossec.conf)
echo "Webhook: $WEBHOOK"

# Probar directamente con curl
curl -X POST "$WEBHOOK" \
  -H "Content-Type: application/json" \
  -d '{"test": "message"}'

# Si devuelve 202 OK, el webhook está activo
# Si devuelve 404, el webhook expiró (necesita regenerarse en Power Automate)
```

#### 2. Verificar nivel de integración en ossec.conf

```bash
# El nivel debe ser <= 15 (o <= al nivel de tu alerta de test)
grep -A3 "custom-teams-summary" /var/ossec/etc/ossec.conf
```

Debería ver:
```xml
<integration>
  <name>custom-teams-summary</name>
  <hook_url>https://outlook.webhook.office.com/...</hook_url>
  <level>11</level>
  <alert_format>json</alert_format>
</integration>
```

#### 3. Verificar salida del script

```bash
# Crear alerta de test y capturar salida
cat /tmp/test-alert-brute-force.json | \
  /var/ossec/integrations/custom-teams-summary.py "$WEBHOOK" 11 "custom-teams-summary" 2>&1

# Verás:
# [OK] Critical alert sent immediately (Rule 200004, Level 15)
# O un error específico
```

#### 4. Verificar Permisos de Archivo de Caché

```bash
# Si hay error "Permission denied" en el caché:
sudo chmod 755 /var/ossec/logs
sudo chown root:wazuh /var/ossec/logs/teams_alerts_cache.pkl
sudo chmod 664 /var/ossec/logs/teams_alerts_cache.pkl
```

---

## ✅ CHECKLIST DE VALIDACIÓN FINAL

- [ ] Script copiado a `/var/ossec/integrations/custom-teams-summary.py`
- [ ] Permisos correctos: `root:wazuh 750`
- [ ] Script es ejecutable: `chmod +x`
- [ ] Sintaxis válida: `python3 -m py_compile` sin errores
- [ ] Wazuh reiniciado: `systemctl restart wazuh-manager`
- [ ] Webhook activo: `curl` devuelve 202
- [ ] TEST 1 ejecutado: Alerta de nivel 12 acumulada
- [ ] TEST 2 ejecutado: Alerta de brute force enviada inmediatamente
- [ ] TEST 3 verificado: Mensaje aparece en Teams con todos los detalles
- [ ] Logs monitoreados: Sin errores en `integrations.log`
- [ ] Caché creado: Archivo existe en `/var/ossec/logs/`

---

## 📞 Si Necesitas Ayuda

1. **Ver logs completos:**
   ```bash
   sudo tail -100 /var/ossec/logs/integrations.log
   ```

2. **Restaurar si algo sale mal:**
   ```bash
   sudo cp /root/backups/custom-teams-summary.py.backup-20260316 \
           /var/ossec/integrations/custom-teams-summary.py
   sudo systemctl restart wazuh-manager
   ```

3. **Verificar versión de Python:**
   ```bash
   /var/ossec/framework/python/bin/python3 --version
   ```

---

## 🎯 Resultado Esperado

Después de la implementación:

✅ Las alertas de **brute force (Reglas 200004, 200005)** llegarán a Teams inmediatamente
✅ Mostrarán **todos los intentos fallidos** en un formato organizado
✅ El campo "Usuario" mostrará **todos los usuarios atacados**
✅ El campo "IP Origen" mostrará la **IP del atacante**
✅ Las "Alertas de Correlación" aparecerán marcadas claramente

---

## 📝 Notas

- Este fix es **retrocompatible** (funciona igual para alertas normales)
- El cache sigue funcionando igual
- El formato de Power Automate no cambia (sigue siendo Adaptive Card)
- Mejora significativa en visualización de ataques de fuerza bruta
