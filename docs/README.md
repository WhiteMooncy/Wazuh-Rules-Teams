# 📚 Documentación Completa

> **Bienvenido a la documentación del proyecto Wazuh Custom Rules & Teams Integration.**

> 🗺️ **¿No sabes por dónde empezar?** Lee primero [DOCUMENTATION_MAP.md](./DOCUMENTATION_MAP.md) para una guía visual.

## 🎓 ¿Por Dónde Empezar?

### Si Eres Principiante (Recomendado)
👉 **[LEARNING_PATH.md](./LEARNING_PATH.md)** ← Comienza aquí  
Ruta estructurada de 2-3 horas que te enseña todo desde cero.  
✅ Explica el QUÉ y el POR QUÉ  
✅ Incluye ejemplos y diagramas  
✅ Paso a paso para instalar  
✅ 5 módulos progresivos

### Si Tienes Prisa
👉 **[QUICK_START.md](./QUICK_START.md)** ← 10 minutos  
Setup mínimo para empezar rápido.

### Si Ya Sabes de Wazuh
👉 **[INSTALLATION.md](INSTALLATION.md)** ← Directamente

---

## 📖 Todos los Documentos

| Documento | Tipo | Tiempo | Para quién |
|-----------|------|--------|----------|
| [DOCUMENTATION_MAP.md](./DOCUMENTATION_MAP.md) | 🗺️ Guía | 5 min | Todos (empieza aquí) |
| [LEARNING_PATH.md](./LEARNING_PATH.md) | 🎓 Tutorial | 2-3h | Principiantes |
| [QUICK_START.md](./QUICK_START.md) | 🏃 Rápido | 10min | Apurados |
| [INSTALLATION.md](INSTALLATION.md) | 📖 Completo | 30min | DevOps |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | 🆘 Diagnóstico | Var. | Ops |
| [RULES_REFERENCE.md](RULES_REFERENCE.md) | 📋 Referencia | 20min | Analysts |
| [TEAMS_SETUP.md](TEAMS_SETUP.md) | 🔗 Config | 15min | Teams |
| [MIGRATION.md](MIGRATION.md) | 🔄 Upgrade | 10min | Usuarios |

## Documentation Overview

### For Administrators

**First-time Setup:**
1. Read [INSTALLATION.md](INSTALLATION.md)
2. Follow [TEAMS_SETUP.md](TEAMS_SETUP.md)
3. Review [RULES_REFERENCE.md](RULES_REFERENCE.md) to understand alerts

**Migrating Servers:**
1. Read [MIGRATION.md](MIGRATION.md)
2. Refer to [TROUBLESHOOTING.md](TROUBLESHOOTING.md) if issues arise

**Troubleshooting:**
1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues
2. Review logs as documented in each guide

### For Security Analysts

**Understanding Alerts:**
1. [RULES_REFERENCE.md](RULES_REFERENCE.md) - All 67 rules explained
2. [MITRE ATT&CK Mapping](#) - Technique coverage
3. [Alert Examples](#) - Real-world scenarios

**Tuning Detection:**
1. [RULES_REFERENCE.md](RULES_REFERENCE.md) - Adjust severity levels
2. [INSTALLATION.md](INSTALLATION.md#post-installation) - Change thresholds

### For Developers

**Customizing Integration:**
1. Integration script source: `integrations/custom-teams-summary.py`
2. Testing scripts: `scripts/test_*.sh`
3. See [Contributing Guide](../README.md#contributing)

## Document Summaries

### INSTALLATION.md
**Comprehensive installation guide**

- Prerequisites checklist
- Quick installation (5 commands)
- Detailed step-by-step setup
- Power Automate webhook configuration
- Verification procedures
- Post-installation tuning
- Troubleshooting common install issues

**Length:** ~15KB | **Time to complete:** 30-45 minutes

---

### MIGRATION.md
**Server-to-server migration guide**

- Pre-migration checklist
- Step-by-step transfer procedures
- Agent re-registration
- Verification and testing
- Rollback procedures
- Post-migration optimization

**Length:** ~12KB | **Time to complete:** 30-60 minutes

---

### TROUBLESHOOTING.md
**Problem diagnosis and resolution**

- Common issues with solutions
- Log analysis procedures
- Integration debugging
- Rule testing methods
- Cache management
- Performance optimization

**Length:** ~10KB | **Reference guide**

---

### RULES_REFERENCE.md
**Complete rules documentation**

- All 67 rules explained
- Event ID mappings
- MITRE ATT&CK techniques
- Severity levels
- Customization examples
- Compliance framework tags

**Length:** ~20KB | **Reference guide**

---

### TEAMS_SETUP.md
**Power Automate configuration**

- Creating HTTP-triggered flow
- Configuring Teams connector
- Channel setup requirements
- Webhook URL management
- Adaptive Card formatting
- Troubleshooting webhook issues

**Length:** ~8KB | **Time to complete:** 15-20 minutes

---

## Additional Resources

### Quick Reference Cards

- **Rule ID Quick Reference:** See [rules/README.md](../rules/README.md)
- **Integration Commands:** See [integrations/README.md](../integrations/README.md)
- **Testing Scripts:** See [scripts/README.md](../scripts/README.md)

### External Documentation

- **Wazuh Official Docs:** https://documentation.wazuh.com
- **Power Automate Docs:** https://learn.microsoft.com/en-us/power-automate/
- **Windows Event IDs:** https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/plan/appendix-l--events-to-monitor
- **MITRE ATT&CK:** https://attack.mitre.org/

### Community

- **GitHub Repository:** https://github.com/YOUR_USERNAME/wazuh-custom-rules-teams
- **Issues Tracker:** https://github.com/YOUR_USERNAME/wazuh-custom-rules-teams/issues
- **Discussions:** https://github.com/YOUR_USERNAME/wazuh-custom-rules-teams/discussions

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-03-11 | Initial release with 67 rules |
| | | Teams integration with summary mode |
| | | Complete documentation set |

## Contributing to Documentation

Improvements to documentation are welcome!

**To contribute:**

1. Fork repository
2. Create branch: `docs/improve-installation-guide`
3. Make changes
4. Test instructions on clean install
5. Submit pull request

**Documentation Standards:**

- Use clear, concise language
- Include code examples
- Test all commands before documenting
- Add screenshots where helpful
- Keep formatting consistent

---

## Documentation TODO

Future documentation enhancements:

- [ ] Video walkthrough of installation
- [ ] Architecture diagram with data flow
- [ ] Performance tuning deep-dive
- [ ] Custom rule development guide
- [ ] Windows agent hardening guide
- [ ] Advanced Adaptive Card customization
- [ ] Integration with SIEM platforms
- [ ] Multi-server deployment guide

---

## Support

If documentation doesn't answer your question:

1. **Search existing issues:** https://github.com/YOUR_USERNAME/wazuh-custom-rules-teams/issues
2. **Create new issue:** Use issue template
3. **Community discussions:** https://github.com/YOUR_USERNAME/wazuh-custom-rules-teams/discussions

**When asking for help, include:**
- Wazuh version (`/var/ossec/bin/wazuh-control info`)
- Operating system and version
- Relevant log excerpts
- Steps to reproduce issue
- What you've already tried

---

**All documentation is under [MIT License](../LICENSE)**
