# Wazuh Custom Rules - Factorized Architecture v2.0

Este directorio contiene las reglas custom de Wazuh organizadas en **3 archivos especializados** (98 reglas totales) para mejor mantenimiento, escalabilidad y separación de responsabilidades.

## 📁 Arquitectura de Archivos

### 1️⃣ custom_windows_security_rules.xml
**89 reglas** | **~44 KB** | **IDs: 100001-100089**

**Propósito:** Eventos críticos de seguridad Windows no cubiertos por reglas base de Wazuh o que requieren ajuste de severidad.

**Dependencia:** `if_sid>60100` (Windows Security Base - Event Channel Security)

**Categorías incluidas:**
- **Kerberos Authentication** (6 reglas): TGT, Service Tickets, Kerberoasting, Golden Ticket
- **Service Installation** (2 reglas): Servicios sospechosos, persistencia via servicios
- **Process Execution** (5 reglas): CMD, PowerShell, WScript, RegEdit, Net commands
- **Credential Access** (2 reglas): Acceso a LSASS, detección de Mimikatz
- **Account Management** (15 reglas): Creación, modificación, eliminación de cuentas
- **Password Operations** (4 reglas): Cambios de contraseña, resets, políticas
- **Group Policy** (2 reglas): Modificaciones GPO, MSI Group Policy
- **Security Auditing** (9 reglas): Cambios en políticas de auditoría del sistema
- **Session Management** (4 reglas): Reconexiones RDP, desconexiones, sesiones idle
- **Windows Firewall** (1 regla): Cambios en reglas de firewall
- **Special Logon** (3 reglas): Asignación de privilegios especiales
- **Object Access** (24 reglas): Acceso a archivos, registro, almacenamiento removible
- **System Security** (4 reglas): Extensiones de seguridad, cambios de estado
- **Other Security Events** (8 reglas): Manipulación de tokens, scheduled tasks

**Event IDs cubiertos:** 4624, 4625, 4634, 4647, 4648, 4663, 4670, 4672, 4673, 4674, 4688, 4689, 4697, 4698, 4699, 4700, 4701, 4702, 4713, 4714, 4715, 4719, 4720, 4722, 4723, 4725, 4726, 4727, 4728, 4729, 4730, 4731, 4732, 4733, 4734, 4735, 4737, 4738, 4739, 4740, 4741, 4742, 4743, 4754, 4755, 4756, 4757, 4758, 4759, 4760, 4761, 4764, 4765, 4766, 4767, 4768, 4769, 4770, 4771, 4776, 4778, 4779, 4781, 4782, 4793, 4794, 4817, 5136, 5137, 5141, 7045

**MITRE ATT&CK:** T1003, T1003.001, T1055, T1070.001, T1078, T1098, T1136, T1543.003, T1548, T1558, T1558.003

---

### 2️⃣ custom_windows_overrides.xml
**5 reglas** | **~3.5 KB** | **IDs: 60103, 100101, 100110-100112**

**Propósito:** Reglas de override que modifican comportamiento de reglas base de Wazuh y correlaciones avanzadas.

**Dependencia:** `if_sid>60100` (Windows Security Base)

**Reglas incluidas:**

| Rule ID | Event ID | Descripción | Level | Tipo |
|---------|----------|-------------|-------|------|
| 60103 | 4724 | Password Reset (Override) | 8 | Override |
| 100101 | 1102, 517 | Security Log Clearing | **15** | Critical |
| 100110 | Múltiples | Multiple Authentication Failures (5+ en 10 min) | 10 | Correlation |
| 100111 | Múltiples | Successful Login After Failures | 12 | Correlation |
| 100112 | Múltiples | Multiple Failed Logins from Single Source | 10 | Correlation |

**Notas importantes:**
- ⚠️ **Rule 60103** sobrescribe la regla base de Wazuh para Event 4724 (cambio de nivel 0 → 8)
- 🔥 **Rule 100101** es nivel 15 (**CRÍTICO**) - limpieza de logs de seguridad
- 🔗 **Rules 110-112** son reglas de **correlación** basadas en múltiples eventos

**MITRE ATT&CK:** T1070.001 (Indicator Removal: Clear Windows Event Logs)

---

### 3️⃣ custom_linux_security_rules.xml
**4 reglas** | **~2.2 KB** | **IDs: 100103, 200001-200003**

**Propósito:** Seguridad Linux/Unix, autenticación SSH y detección de cuentas no-nominales.

**Dependencias:**
- `if_sid>5501` (PAM authentication messages)
- `if_sid>5502` (Linux user login)
- CDB list: `/var/ossec/etc/lists/no-nominal-account.cdb`

**Reglas incluidas:**

| Rule ID | Descripción | Level | Detección |
|---------|-------------|-------|-----------|
| 100103 | PAM: Session opened for ROOT user | 8 | Autenticación root via PAM |
| 200001 | Non-nominal account login detected | 10 | Login con cuenta genérica (SSH/local) |
| 200002 | Sudo execution by non-nominal account | 12 | Uso de sudo con cuenta genérica |
| 200003 | Non-nominal account authentication | 8 | Autenticación con cuenta compartida |

**CDB List (no-nominal-account):**
Cuentas genéricas/compartidas detectadas:
- admin, test, administrator, root, service, backup, system, svc

**Instalación de CDB list:**
```bash
# Copiar archivo
scp no-nominal-account root@wazuh:/var/ossec/etc/lists/

# Compilar
/var/ossec/bin/ossec-makelists

# Verificar
ls -lh /var/ossec/etc/lists/no-nominal-account.cdb
```

---

### 4️⃣ local_rules_override.xml
**[DEPRECATED]** - Archivo antiguo de la estructura monolítica anterior. 

**Status:** Mantenido por compatibilidad pero reemplazado por los 3 archivos factorizados.

**Migración:** Ver `docs/CAMBIOS_FACTORIZACION_REGLAS.md` para detalles de la refactorización.

---

## 📊 Resumen Estadístico

| Métrica | Valor |
|---------|-------|
| **Total Reglas** | **98** |
| **Windows Security** | 89 |
| **Windows Overrides** | 5 |
| **Linux Security** | 4 |
| **Event IDs únicos** | 73+ |
| **MITRE Techniques** | 15+ |
| **Rules Críticas (Level 15)** | 1 (Log Clearing) |
| **CDB Lists** | 1 (no-nominal-account) |

---

## 🔧 Instalación

### 1. Copiar archivos al servidor Wazuh

```bash
ssh root@wazuh-server

# Copiar reglas
cd /var/ossec/etc/rules/
# Usar scp, wget o copiar manualmente los 3 archivos XML

# Copiar CDB list
cd /var/ossec/etc/lists/
# Copiar no-nominal-account

# Compilar CDB
/var/ossec/bin/ossec-makelists
```

### 2. Configurar ossec.conf

Agregar dentro de `<ossec_config>`:

```xml
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
```

### 3. Validar y reiniciar

```bash
# Verificar sintaxis XML
/var/ossec/bin/wazuh-logtest -t

# Reiniciar Wazuh Manager
systemctl restart wazuh-manager

# Verificar reglas cargadas
grep "Total rules enabled" /var/ossec/logs/ossec.log | tail -1
```

---

## 🧪 Testing

### Test individual de reglas

```bash
# Test Event 4624 (Logon)
echo '<Event><System><EventID>4624</EventID></System></Event>' | /var/ossec/bin/wazuh-logtest

# Test Event 1102 (Log Clearing - CRÍTICO)
echo '<Event><System><EventID>1102</EventID></System></Event>' | /var/ossec/bin/wazuh-logtest
```

### Test suite completo

Script de testing disponible en: `/scripts/test_all_rules.sh`

---

## 📋 Convenciones de Nombres

| Rango IDs | Propósito | Archivo |
|-----------|-----------|---------|
| 100001-100089 | Windows Security Events | custom_windows_security_rules.xml |
| 60103, 100101 | Windows Overrides (críticos) | custom_windows_overrides.xml |
| 100110-100112 | Windows Correlations | custom_windows_overrides.xml |
| 100103 | Linux PAM root auth | custom_linux_security_rules.xml |
| 200001-200003 | Linux non-nominal accounts | custom_linux_security_rules.xml |

**Nota:** IDs 100090-100091 fueron eliminados (duplicados Event 4724, ya cubierto por rule 60103)

---

## 🔗 Referencias

- **Documentación completa:** `docs/CAMBIOS_FACTORIZACION_REGLAS.md`
- **Reporte de tests:** `docs/TEST_REPORT.md`
- **Instalación:** `docs/INSTALLATION.md`
- **Migración:** `docs/MIGRATION.md`
- **CDB Lists:** `lists/README.md`

---

## ⚠️ Notas Importantes

1. **Orden de carga:** Los archivos se cargan en el orden definido en `ossec.conf`. Es importante cargar `custom_windows_overrides.xml` después de `custom_windows_security_rules.xml`.

2. **Rule 60103:** Esta regla sobrescribe comportamiento base de Wazuh. Si se elimina, Event 4724 volverá a nivel 0.

3. **CDB Lists:** Sin la lista compilada, las reglas 200001-200003 **no funcionarán**. Verificar con `ls /var/ossec/etc/lists/*.cdb`.

4. **Dependencies:** Todas las reglas Windows dependen de `rule 60100` (Windows Security Base). Si esta regla no existe, las custom rules no se dispararán.

5. **Testing:** Después de cualquier cambio, ejecutar `wazuh-logtest -t` para verificar sintaxis XML antes de reiniciar el servicio.

---

**Versión:** 2.0 (Factorizada)  
**Última actualización:** 2026-03-12  
**Autor:** SOC Team  
**Wazuh Compatible:** 4.x+
