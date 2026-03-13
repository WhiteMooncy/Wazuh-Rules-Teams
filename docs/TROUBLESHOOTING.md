# Troubleshooting Guide

Guía de diagnóstico y resolución de problemas comunes en la integración de Wazuh con Teams.

## Tabla de Contenidos

- [Validación de Reglas](#validación-de-reglas)
- [Problemas de Caché](#problemas-de-caché)
- [Integración con Teams](#integración-con-teams)
- [Análisis de Logs](#análisis-de-logs)
- [Verificación de CDB Lists](#verificación-de-cdb-lists)

## Validación de Reglas

### Las reglas no se cargan en Wazuh

**Síntoma:** Después de copiar archivos XML, los eventos no generan alertas.

**Diagnóstico:**
```bash
# Verificar que los archivos XML están en lugar correcto
ls -la /var/ossec/etc/rules/local-rules-*.xml

# Validar sintaxis XML
/var/ossec/bin/wazuh-logtest -v

# Buscar errores en logs de Wazuh
tail -f /var/ossec/logs/ossec.log | grep -i error
```

**Solución:**
1. Verificar permisos: `chmod 640 /var/ossec/etc/rules/local-rules-*.xml`
2. Confirmar propietario: `chown root:wazuh /var/ossec/etc/rules/local-rules-*.xml`
3. Validar sintaxis: `python3 validate_rules.py`
4. Restart Wazuh: `systemctl restart wazuh-manager`

### Reglas duplicadas detectadas

**Síntoma:** El validador reporta "Duplicate rule IDs detected".

**Diagnóstico:**
```bash
# Ejecutar validador
python3 validate_rules.py

# Buscar el ID duplicado
grep -r "id=\"12345\"" /var/ossec/etc/rules/
```

**Solución:**
1. Identificar archivos en conflicto (output del validador)
2. Cambiar ID de una de las reglas a uno disponible (rango 200001-200100)
3. Actualizar referencias en otros archivos si existen
4. Re-ejecutar validador para confirmar

### Reglas con sintaxis inválida

**Síntoma:** Wazuh logs muestran "XML parsing error".

**Diagnóstico:**
```bash
# Validar con wazuh-logtest
echo "test log" | /var/ossec/bin/wazuh-logtest -v

# Buscar errores específicos
python3 validate_rules.py 2>&1 | grep -i "error"
```

**Solución:**
1. Verificar caracteres especiales en descripciones (escapar `<`, `>`, `&`)
2. Confirmar que todas las etiquetas estén cerradas
3. Revisar indentación XML
4. Validar referenced lists existen en `/var/ossec/etc/lists/`

## Problemas de Caché

### Caché corrompido

**Síntoma:** Script Python falla con "JSONDecodeError" o "pickle.UnpicklingError".

**Diagnóstico:**
```bash
# Verificar contenido del caché
file /var/ossec/logs/teams_alerts_cache.json
cat /var/ossec/logs/teams_alerts_cache.json | python3 -m json.tool
```

**Solución:**
```bash
# Eliminar caché corrupto
rm -f /var/ossec/logs/teams_alerts_cache.json

# Recrear vacío
python3 -c "import json; json.dump({'alerts': [], 'last_summary_time': '2025-01-01T00:00:00', 'summary_count': 0}, open('/var/ossec/logs/teams_alerts_cache.json', 'w'))"
```

### Caché crece demasiado

**Síntoma:** El archivo `teams_alerts_cache.json` excede 100MB.

**Diagnóstico:**
```bash
# Tamaño actual
du -h /var/ossec/logs/teams_alerts_cache.json

# Cantidad de alertas en caché
python3 -c "import json; cache=json.load(open('/var/ossec/logs/teams_alerts_cache.json')); print(f'Alerts: {len(cache[\"alerts\"])}')"
```

**Solución:**
1. Aumentar `WAZUH_SUMMARY_INTERVAL_HOURS` para enviar resúmenes más frecuentes
2. Reducir `MAX_ALERTS_BEFORE_SUMMARY` para trigger antes
3. Implementar limpieza automática: `python3 scripts/clean_cache.py`

## Integración con Teams

### Las alertas no llegan a Teams

**Síntoma:** Los scripts se ejecutan sin errores pero Teams no recibe notificaciones.

**Diagnóstico:**
1. Verificar URL del webhook:
```bash
# Verificar que la variable de entorno está configurada
echo $WAZUH_TEAMS_WEBHOOK_URL

# Probar conectividad
curl -X POST -H "Content-Type: application/json" \
  -d '{"test":"mensaje"}' \
  "$WAZUH_TEAMS_WEBHOOK_URL"
```

2. Revisar logs del script:
```bash
tail -f /var/ossec/logs/teams_integration.log
```

**Solución:**
1. Confirmar webhook URL es válida: debe comenzar con `https://outlook.webhook.office.com/...`
2. Verificar que Power Automate flow está activo
3. Confirmar credenciales de autenticación si aplica
4. Probar manualmente con `curl` antes de troubleshooting del script

### Webhook URL rechaza conexiones

**Síntoma:** Error "403 Forbidden" o "401 Unauthorized" al enviar a Teams.

**Diagnóstico:**
```bash
# Verificar expiración del webhook
python3 -c "import os; print(os.environ.get('WAZUH_TEAMS_WEBHOOK_URL', 'NO CONFIGURADO'))"

# Probar con verbose
curl -X POST -v -H "Content-Type: application/json" \
  -d '{"test":"mensaje"}' \
  "$WAZUH_TEAMS_WEBHOOK_URL" 2>&1 | head -20
```

**Solución:**
1. Regenerar webhook en Power Automate (webhooks expiran)
2. Confirmar URL no tiene caracteres corruptos (copy-paste errors)
3. Verificar que Power Automate flow que recibe webhook está activo
4. Probar con una URL de webhook de test

## Análisis de Logs

### Ubicación de logs importantes

```bash
# Logs de Wazuh Manager
/var/ossec/logs/ossec.log

# Logs de alertas
/var/ossec/logs/alerts/alerts.json

# Logs de la integración Teams (si está configurado)
/var/ossec/logs/teams_integration.log

# Eventos con nivel >= 12
tail -f /var/ossec/logs/alerts/alerts.json | jq 'select(.rule.level >= 12)'
```

### Filtrar eventos por regla

```bash
# Ver todos los eventos de una regla específica (por ID)
grep "rule_id\": 200001" /var/ossec/logs/alerts/alerts.json | jq .

# Ver últimas 10 alertas críticas
jq 'select(.rule.level >= 15)' /var/ossec/logs/alerts/alerts.json | tail -10

# Contar alertas por IP origen
jq -r '.data.srcip // "unknown"' /var/ossec/logs/alerts/alerts.json | sort | uniq -c
```

### Correlación de eventos

```bash
# Ver eventos correlacionados (misma fuente IP, mismo agente)
awk -F'[,:]' '{print $1":"$NF}' /var/ossec/logs/alerts/alerts.json | \
  sort | uniq -d | wc -l
```

## Verificación de CDB Lists

### CDB list no se carga

**Síntoma:** Rule que usa CDB list (ej: "no-nominal-account.cdb") no genera match.

**Diagnóstico:**
```bash
# Verificar que archivo CDB existe
ls -la /var/ossec/etc/lists/no-nominal-account.cdb

# Verificar permisos
stat /var/ossec/etc/lists/no-nominal-account.cdb | grep Access

# Verificar contenido
/var/ossec/bin/wazuh-cdb-make -i /var/ossec/etc/lists/no-nominal-account.txt \
  -o /var/ossec/etc/lists/no-nominal-account.cdb
```

**Solución:**
1. Compilar CDB desde fuente:
```bash
cd /var/ossec/etc/lists/
/var/ossec/bin/wazuh-cdb-make -i no-nominal-account.txt -o no-nominal-account.cdb
```

2. Verificar permisos:
```bash
chown root:wazuh /var/ossec/etc/lists/no-nominal-account.cdb
chmod 640 /var/ossec/etc/lists/no-nominal-account.cdb
```

3. Restart Wazuh:
```bash
systemctl restart wazuh-manager
```

### Actualizar CDB list

```bash
# Editar fuente de texto
nano /var/ossec/etc/lists/no-nominal-account.txt

# Recompilar
/var/ossec/bin/wazuh-cdb-make -i no-nominal-account.txt -o no-nominal-account.cdb

# Restart para que Wazuh recargue
systemctl restart wazuh-manager
```

## Checklist de Diagnóstico

Use este checklist para diagnóstico rápido:

- [ ] Archivos XML en `/var/ossec/etc/rules/` existen y tienen permisos 640
- [ ] `validate_rules.py` no reporta errores
- [ ] CDB lists compilados y en `/var/ossec/etc/lists/`
- [ ] `WAZUH_TEAMS_WEBHOOK_URL` configurada y válida
- [ ] `teams_alerts_cache.json` < 50MB
- [ ] Logs sin "ERROR" en última hora: `tail -10000 /var/ossec/logs/ossec.log | grep -i error`
- [ ] Wazuh Manager restarted después de cambios: `systemctl status wazuh-manager`
- [ ] Tests ejecutados correctamente: `bash test_all_rules.sh`

## Reportar Problemas

Si los pasos anteriores no resuelven:

1. Colectar logs:
```bash
tar czf wazuh_logs_$(date +%s).tar.gz /var/ossec/logs/
```

2. Ejecutar script de diagnóstico:
```bash
bash scripts/diagnose.sh
```

3. Incluir output en reporte de issue
