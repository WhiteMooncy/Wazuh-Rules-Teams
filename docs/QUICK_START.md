# 🚀 Quick Start Guide

**Comienza en 10 minutos.** Para instalación completa, ver [INSTALLATION.md](./INSTALLATION.md).

> 💡 **¿Por qué?** Este guía te configurará las 101 reglas personalizadas + integración con Microsoft Teams en 10 minutos.

## 4 Pasos para Empezar

> **⏱️ Tiempo total:** ~10 minutos  
> **🎯 Objetivo:** Detectar eventos de seguridad y enviatlos a Teams

### 1️⃣ Descargar Archivos (1 min)

**¿Qué haces?** Descargas las 101 reglas personalizadas + la lista CDB (necesaria para detectar cuentas anómalas)  
**¿Por qué?** Wazuh sin reglas no detecta nada. Necesitas estas reglas específicas para Windows/Linux.

```bash
# Conectar al servidor Wazuh
ssh root@<WAZUH-SERVER>

# Descargar reglas
cd /var/ossec/etc/rules/
wget https://raw.githubusercontent.com/<USER>/wazuh-custom-rules-teams/main/rules/custom_windows_security_rules.xml
wget https://raw.githubusercontent.com/<USER>/wazuh-custom-rules-teams/main/rules/custom_windows_overrides.xml
wget https://raw.githubusercontent.com/<USER>/wazuh-custom-rules-teams/main/rules/custom_linux_security_rules.xml

# Descargar CDB list
cd /var/ossec/etc/lists/
wget https://raw.githubusercontent.com/<USER>/wazuh-custom-rules-teams/main/lists/no-nominal-account

# Compilar CDB list
/var/ossec/bin/wazuh-cdb-make -i no-nominal-account -o no-nominal-account.cdb
```

### 2️⃣ Crear Teams Webhook (3 min)

**¿Qué haces?** Creas un "puente" desde Wazuh → Power Automate → Teams  
**¿Por qué?** Wazuh no puede hablar directo con Teams. Necesitas Power Automate como intermediario.
1. Ve a https://make.powerautomate.com
2. **Crear** → **Flujo nube automatizado**
3. Trigger: **"Cuando se recibe una solicitud HTTP"**
4. Acción: **"Publicar mensaje en Teams"**
5. Copiar **HTTP POST URL**

Más detalles: [TEAMS_SETUP.md](./TEAMS_SETUP.md)

### 3️⃣ Configurar Variables (2 min)

**¿Qué haces?** Guardas credenciales en un archivo `.env` para que el script de Python las use  
**¿Por qué?** El script necesita saber: ¿Dónde está el Teams webhook? ¿Dónde está tu Wazuh dashboard? ¿Cada cuándo envío resúmenes?

```bash
# Crear archivo de configuración
cat > /var/ossec/etc/teams-integration.env << 'EOF'
export WAZUH_TEAMS_WEBHOOK_URL="https://outlook.webhook.office.com/webhookb2/..."
export WAZUH_DASHBOARD_URL="https://wazuh.tu-empresa.com"
export WAZUH_SUMMARY_INTERVAL_HOURS=24
export WAZUH_CRITICAL_LEVEL=15
EOF

chmod 640 /var/ossec/etc/teams-integration.env
```

### 4️⃣ Instalar Integrador (2 min)

**¿Qué haces?** Copias el script de Python que envía alertas a Teams + lo configurar en `ossec.conf`  
**¿Por qué?** Wazuh necesita saber qué hacer con los eventos que detecta. El script se encarga de formateador y enviar a Teams.

```bash
# Copiar script
cp integrations/custom-teams-summary.py /var/ossec/integrations/
chmod +x /var/ossec/integrations/custom-teams-summary.py

# Editar ossec.conf
nano /var/ossec/etc/ossec.conf

# Agregar antes de </ossec_config>:
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
# Restart Wazuh
systemctl restart wazuh-manager

# Verificar que se inició correctamente
systemctl status wazuh-manager
```

---

## ✅ Validar Instalación (Paso a Paso)

> **¿Por qué validar?** Porque si algo anda mal, es mejor averiguar AHORA en lugar de esperar un ataque real.

### Paso 1: Verificar Sintaxis de Reglas

```bash
/var/ossec/bin/wazuh-logtest -t
```

**Esperado:** `[OK] OK`  
**Si falla:** Una regla tiene sintaxis XML incorrecta (posible conflicto de IDs)

### Paso 2: Probar con un Evento Windows

```bash
echo "WIN-SERVER: EventID: 4625 (Failed Logon)" | /var/ossec/bin/wazuh-logtest
```

**Esperado:** Muestra la regla 200003 (Failed Logon Attempt) que detectó  
**Si no aparece:** La regla no se cargó correctamente

### Paso 3: Ver los Logs

```bash
tail -f /var/ossec/logs/ossec.log | grep custom
```

**Esperado:** Líneas con `custom_windows_security_rules`, `custom_linux_security_rules`  
**Si está vacío:** Las reglas no se cargaron al reiniciar

### Paso 4: Testear Integración con Teams

```bash
source /var/ossec/etc/teams-integration.env
python3 /var/ossec/integrations/custom-teams-summary.py << EOF
{"rule": {"id": "200001", "level": 12}, "agent": {"name": "test"}, "timestamp": "$(date -Iseconds)"}
EOF
```

**Esperado:** Sin errores + un mensaje en Teams (si todo está conectado)  
**Si falla:** Posible problema con URLs de webhook o permisos de archivo

---

## 🪛 Solución de Problemas Rápida

> **Si algo no funciona, usa este árbol de decisión:**

| Síntoma | Causa Probable | Solución |
|---------|----------------|---------|
| `Rule ID duplicated` | Tienes 2 reglas con el mismo ID | Ver [TROUBLESHOOTING.md](./TROUBLESHOOTING.md#reglas-duplicadas-detectadas) |
| Teams no recibe nada | Webhook incorrecto o no válido | Copiar de nuevo: [TEAMS_SETUP.md](./TEAMS_SETUP.md#las-alertas-no-llegan-a-teams) |
| `CDB list no se carga` | Archivo `.cdb` no se compiló | Ejecutar: `/var/ossec/bin/wazuh-cdb-make -i no-nominal-account -o no-nominal-account.cdb` |
| `Permission denied` | Archivos con permisos incorrectos | Cambiar: `chmod 755 /var/ossec/integrations/custom-teams-summary.py` |

---

## 📚 Siguientes Pasos (Después de 10 min)

> **Ahora que lo tienes corriendo, aprende más:**

| Documento | Tiempo | Propósito |
|-----------|--------|---------|
| [LEARNING_PATH.md](./LEARNING_PATH.md) | 2-3h | Aprender TODO desde 0 (recomendado) |
| [RULES_REFERENCE.md](./RULES_REFERENCE.md) | 20 min | Entender cada una de las 101 reglas |
| [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) | Variable | Cuando algo no anda bien |
| [INSTALLATION.md](./INSTALLATION.md) | 30 min | Setup de producción |
| [TEAMS_SETUP.md](./TEAMS_SETUP.md) | 15 min | Teams avanzado (canales, filtros) |

---

## 📊 Qué Deberías Ver Después de 5-10 min

### En la Terminal (logs de Wazuh)

```
2025-03-13 14:23:45 | INFO | Alert received: Rule 200001
2025-03-13 14:23:46 | DEBUG | Alert cached (1/3)
2025-03-13 14:23:47 | WARNING | CRITICAL alert (Rule 200024) - sending immediately
2025-03-13 14:23:48 | INFO | Teams alert delivered successfully
```

### En el Dashboard de Wazuh

✅ New rules loaded (101 custom rules)  
✅ Agent status = Active  
✅ Alerts appearing in real-time  

### En Microsoft Teams

Un mensaje similar a este:

```
[CRITICAL] Wazuh Sample Alert
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Rule: 200024 | Level: 15 | Windows-Agent
Category: Windows Security
Timestamp: 2025-03-13 14:23:47

User 'attacker' tried to login 15 times
Source IP: 192.168.1.50
[View in Dashboard]
```

---

## ✅ Checklist Final

- [ ] Archivo `/var/ossec/etc/rules/custom_windows_security_rules.xml` existe
- [ ] `/var/ossec/bin/wazuh-logtest -t` muestra `[OK]`
- [ ] Archivo `/var/ossec/etc/teams-integration.env` configurado
- [ ] Script en `/var/ossec/integrations/custom-teams-summary.py`
- [ ] `<integration>` agregada a `ossec.conf`
- [ ] `systemctl restart wazuh-manager` ejecutado
- [ ] Mensaje de prueba llegó a Teams

**Si todos los ✅ están marcados → ¡Instalación exitosa! 🎉**

---

## 🎓 Próximo: Aprende Cómo Funciona

👉 Lee [LEARNING_PATH.md](./LEARNING_PATH.md) para entender:
- Por qué estas 101 reglas protegen tu infraestructura
- Cómo se estruturan las reglas Wazuh
- Cómo personalizar reglas para TUS eventos
- Cómo investigar alertas

**¿Stuck?** Ver [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) o contactar al team.
