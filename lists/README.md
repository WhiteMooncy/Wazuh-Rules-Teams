# CDB Lists

Este directorio contiene las listas CDB utilizadas por las reglas custom de Wazuh.

## Archivo: no-nominal-account

**Propósito:** Lista de cuentas genéricas/no-nominales para detectar inicios de sesión con cuentas compartidas.

**Formato:** key:value (cada línea debe tener el formato `cuenta:cuenta`)

**Uso:** Referenciado en `custom_linux_security_rules.xml` (reglas 200001-200003)

**Contenido:**
- admin
- test
- administrator
- root
- service
- backup
- system
- svc

## Instalación en Wazuh Server

1. Copiar el archivo al servidor:
   ```bash
   scp no-nominal-account root@wazuh-server:/var/ossec/etc/lists/
   ```

2. Configurar en ossec.conf:
   ```xml
   <ruleset>
     <list>etc/lists/no-nominal-account</list>
   </ruleset>
   ```

3. Compilar la lista CDB:
   ```bash
   /var/ossec/bin/ossec-makelists
   ```

4. Verificar compilación:
   ```bash
   ls -lh /var/ossec/etc/lists/no-nominal-account.cdb
   ```

5. Reiniciar Wazuh Manager:
   ```bash
   systemctl restart wazuh-manager
   ```

## Verificación

Para verificar que la lista está cargada correctamente:

```bash
grep "no-nominal-account" /var/ossec/logs/ossec.log
```

Deberías ver un mensaje indicando que la lista fue cargada exitosamente.
