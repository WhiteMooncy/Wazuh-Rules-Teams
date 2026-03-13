# 🗺️ Mapa de Documentación Completo

> **Guía visual para navegar toda la documentación.**  
> *Usa este mapa para saber por dónde empezar según tu experiencia.*

---

## 👥 Elige tu Rol

```
┌─────────────────────────────────────────────────────────┐
│                    ¿QUIÉN ERES?                         │
└────────────────┬──────────────────────┬────────────────┘
                 │                      │
       ┌─────────▼─────────┐  ┌────────▼─────────┐
       │  PRINCIPIANTE     │  │   EXPERIMENTADO  │
       │  (SIN EXPERIENCIA)│  │   (SABE WAZUH)   │
       └────────┬──────────┘  └────────┬─────────┘
                │                      │
       ┌────────▼──────────┐  ┌───────▼─────────┐
       │ LEARNING_PATH.md  │  │ QUICK_START.md  │
       │  (2-3 horas)      │  │  (10 minutos)   │
       └────────┬──────────┘  └────────┬────────┘
                │                      │
                │                      │
                └──────────┬───────────┘
                          │
                  ┌───────▼──────────┐
                  │ Ahora instalado  │
                  │     Aprende:     │
                  │ RULES_REFERENCE  │
                  │ TEAMS_SETUP      │
                  │ INSTALLATION     │
                  └──────────────────┘
```

---

## 📚 Documentos por Propósito

### 🎓 **APRENDER** (Si eres nuevo)

```
LEARNING_PATH.md
├─ Módulo 1: Fundamentos (30 min)
│  └─ Entender el PROBLEMA y la SOLUCIÓN
├─ Módulo 2: Setup Básico (40 min)
│  └─ Instalar paso a paso
├─ Módulo 3: Teams Integration (30 min)
│  └─ Webhook + Power Automate
├─ Módulo 4: Entender Reglas (40 min)
│  └─ XML, severidades, MITRE ATT&CK
└─ Módulo 5: Operación (30 min)
   └─ Monitoreo y diagnóstico diario
```

**📖 Tiempo:** 2-3 horas  
**✅ Resultado:** Entiendes CÓMO y POR QUÉ funciona todo

### ⚡ **INSTALAR RÁPIDO**

```
QUICK_START.md
└─ 4 pasos en 10 minutos
   ├─ Descargar reglas
   ├─ Crear Teams webhook
   ├─ Configurar variables
   └─ Instalar script
```

**📖 Tiempo:** 10 minutos  
**✅ Resultado:** Sistema funcionando (sin entender completamente)

### 🔧 **CONFIGURAR DETALLES**

```
INSTALLATION.md
├─ Instalación de producción
├─ Parámetros avanzados
├─ SSL/TLS setup
├─ Clustering de Wazuh
└─ Backups y disaster recovery
```

**📖 Tiempo:** 30 minutos  
**✅ Resultado:** Sistema production-ready

### 📋 **ENTENDER LAS REGLAS**

```
RULES_REFERENCE.md
├─ Todas las 101 reglas
├─ Qué detecta cada una
├─ Cuándoson útiles
└─ Ejemplos de logs reales
```

**📖 Tiempo:** 20 minutos por ruleset  
**✅ Resultado:** Saber exactamente qué alertas recibirás

### 🔗 **CONFIGURAR TEAMS**

```
TEAMS_SETUP.md
├─ Crear Flow en Power Automate
├─ Webhook URL
├─ Variables y secretos
├─ Canales múltiples
└─ Filtros por tipo de alerta
```

**📖 Tiempo:** 15 minutos  
**✅ Resultado:** Teams conectado y personalizado

### 🆘 **RESOLVER PROBLEMAS**

```
TROUBLESHOOTING.md
├─ Las alertas no llegan
├─ Reglas duplicadas
├─ CDB list no se carga
├─ Errores de permisos
└─ Pasos de diagnóstico
```

**📖 Tiempo:** Variable (según el problema)  
**✅ Resultado:** Sistema funcionando nuevamente

### 🔄 **ACTUALIZAR O MIGRAR**

```
MIGRATION.md
├─ Actualizar a nueva versión
├─ Migrar de otro servidor
├─ Compatibilidad de reglas
└─ Data preservation
```

**📖 Tiempo:** 10 minutos  
**✅ Resultado:** Upgrade completado sin perder datos

### 📝 **HISTORIAL DE CAMBIOS**

```
CHANGELOG.md
├─ Qué cambió en cada versión
├─ Nuevas reglas
├─ Bug fixes
└─ Mejoras de performance
```

**📖 Tiempo:** 5 minutos (lectura rápida)  
**✅ Resultado:** Entender qué es nuevo

---

## 🎯 Rutas de Aprendizaje Predefinidas

### Ruta 1: **"Quiero entender TODO"** ⭐ RECOMENDADO

```
1. Leer LEARNING_PATH.md (2-3 horas)
   ↓
2. Leer RULES_REFERENCE.md (20 minutos)
   ↓
3. Leer TEAMS_SETUP.md (15 minutos)
   ↓
4. Leer INSTALLATION.md (30 minutos)
   ↓
5. Tener TROUBLESHOOTING.md a mano
   ↓
✅ RESULTADO: Experto en el sistema
```

### Ruta 2: **"Necesito funcionar YA"**

```
1. Leer QUICK_START.md (10 minutos)
   ↓
2. Ejecutar los 4 pasos (10 minutos)
   ↓
3. Validar installation (5 minutos)
   ↓
✅ RESULTADO: Sistema running
   ↓
[DESPUÉS, cuando tengas tiempo]
   ↓
4. Leer LEARNING_PATH.md (2-3 horas)
   ↓
5. Leer RULES_REFERENCE.md (20 minutos)
```

### Ruta 3: **"Ya tengo experiencia en Wazuh"**

```
1. Skim QUICK_START.md (2 minutos)
   ↓
2. Leer RULES_REFERENCE.md (15 minutos)
   ↓
3. Leer TEAMS_SETUP.md (10 minutos)
   ↓
✅ RESULTADO: Entiendes nuevas reglas
   ↓
4. Instalar usando INSTALLATION.md
```

### Ruta 4: **"Algo no funciona"**

```
1. Ir a TROUBLESHOOTING.md
   ↓
2. Ver árbol de decisión para tu síntoma
   ↓
3. Ejecutar comandos de diagnóstico
   ↓
✅ RESULTADO: Problema identificado
   ↓
4. Seguir las instrucciones específicas
   ↓
✅ RESULTADO: Problema resuelto
```

---

## 📊 Mapa de Dependencias

```
                    README.md
                 (Hub central)
                       │
         ┌─────────────┼─────────────┐
         │             │             │
    QUICK_START   LEARNING_PATH  INSTALLATION
         │             │             │
         └─────────────┼─────────────┘
                       │
         ┌─────────────┼─────────────┬──────────────┐
         │             │             │              │
    TEAMS_SETUP   RULES_REFERENCE TROUBLESHOOTING  │
         │             │             │              │
         └─────────────┴─────────────┴──────────────┘
                       │
                  MIGRATION
                  CHANGELOG
```

**Explicación:**
- README → Todos los documentos dependen del README
- QUICK_START → Puerta de entrada rápida
- LEARNING_PATH → Puerta de entrada completa
- INSTALLATION → Configuración avanzada
- TEAMS_SETUP → Específico de integración
- RULES_REFERENCE → Para entender reglas
- TROUBLESHOOTING → Para resolver problemas
- MIGRATION/CHANGELOG → Material de referencia

---

## ⏱️ Tiempo Total por Experiencia

| Rol | QUICK_START | LEARNING_PATH | RULES_REF | TEAMS | INSTALL |
|-----|-------------|---------------|----------|-------|---------|
| **Principiante** | 10 min | 2-3h ⭐ | 20 min | 15 min | 30 min |
| **Intermedio** | 5 min | 1h ⭐ | 15 min | 10 min | 20 min |
| **Experto Wazuh** | 2 min | - | 10 min | 5 min | 15 min |

**TOTAL:** 3.5 - 5.5 horas para ser experto (desde 0)

---

## 🎯 Decisión Rápida: "¿Por dónde empiezo?"

```
┌─ ¿Habéis usado Wazuh antes?
│
├─ SÍ → ¿Tienen prisa?
│       ├─ SÍ → QUICK_START + RULES_REFERENCE
│       └─ NO → LEARNING_PATH módulos 3-5
│
└─ NO → ¿Tienes 2-3 horas?
        ├─ SÍ → LEARNING_PATH (recomendado) ⭐
        └─ NO → QUICK_START + LEARNING_PATH después
```

---

## 📱 Para Vista Rápida (Mobile-Friendly)

1. **En 10 min:** [QUICK_START.md](./QUICK_START.md)
2. **En 30 min:** Primeros 3 módulos de [LEARNING_PATH.md](./LEARNING_PATH.md)
3. **En 1 hora:** [LEARNING_PATH.md](./LEARNING_PATH.md) completo
4. **En 2-3 horas:** Todo lo anterior + [RULES_REFERENCE.md](./RULES_REFERENCE.md) + [TEAMS_SETUP.md](./TEAMS_SETUP.md)

---

## 🔗 Links Rápidos

| Necesito... | Documento |
|------------|-----------|
| Instalar rápido | [QUICK_START.md](./QUICK_START.md) |
| Aprender todo | [LEARNING_PATH.md](./LEARNING_PATH.md) |
| Entender reglas | [RULES_REFERENCE.md](./RULES_REFERENCE.md) |
| Configurar Teams | [TEAMS_SETUP.md](./TEAMS_SETUP.md) |
| Setup avanzado | [INSTALLATION.md](./INSTALLATION.md) |
| Resolver problemas | [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) |
| Ver lo que cambió | [CHANGELOG.md](../CHANGELOG.md) |
| Migrar servidor | [MIGRATION.md](./MIGRATION.md) |

---

## 💾 Esta es tu "brújula de documentación"

**Úsala cuando:**
- No sepas por dónde empezar
- Quieras una visión general
- Busques un documento específico
- Necesites entender cómo se conectan los documentos

**Siguiente paso:** Elige tu rol arriba ↑ y empieza por el documento recomendado.

---

*Última actualización: Marzo 2025*  
*Documentación versión: 8.4/10 (Production Ready)*
