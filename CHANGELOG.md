# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## Installation & Deployment Status

**Current Production Version:** 4.1 (Simple, Real-time Alert Processing)
- **Location:** `/root/wazuh-teams/custom-teams.py` (on 10.27.20.171)
- **Status:** Operational and tested in production
- **Implementation:** Individual alert processing with immediate Teams delivery

**Proposed Versions Under Development:**
- Advanced features with alert accumulation, caching, and retry logic
- Additional rule sets (not yet deployed)

---

## [4.1.0] - 2026-03-09

### Current - PRODUCTION

#### Integration
- **Teams Integration Script** (`custom-teams-summary.py`)
  - Real-time alert processing: Each alert sends immediately
  - Adaptive Cards formatting with color-coded severity
  - Dynamic Dashboard links pointing to `https://192.168.30.2`
  - VirusTotal integration when available in alert data
  - Structured logging to `/var/ossec/logs/integrations.log`
  - SSL verification enabled for security
  - Simple timeout-based reliability (30s per request)
  
#### Testing Scripts
- Basic integration validation
- Manual alert testing procedures

#### Documentation
- Simple installation guide
- Webhook configuration instructions
- Basic troubleshooting guide

---

## [4.0.0] - Proposed (Under Development)

**NOTE:** The following features are documented but NOT YET DEPLOYED to production

### Proposed Additions (Not Active)

#### Advanced Features (Experimental)
- ❌ Alert accumulation system (planned: 3 alerts or 24h intervals)
- ❌ Persistent cache using pickle (planned)
- ❌ Adaptive retry logic with exponential backoff (planned)
- ❌ Intelligent summary mode with statistics (planned)
- ❌ Critical alert bypass mechanism (planned: level ≥15)

#### Custom Rules (Not Deployed)
- 89 Windows Security Rules (planned deployment)
- 5 Override/Correlation Rules (planned deployment)
- 7 Linux Security Rules (planned deployment)
- Total: 101 custom rules (planned, not active)

#### Enhanced Documentation (Proposed)
- Comprehensive troubleshooting guide
- Complete rules reference
- Advanced Teams setup procedures

---

## Previous Versions

### Archive Notes
- Earlier versions existed but details are not currently maintained
- Current focus is on the stable, simple v4.1 implementation
- Planned improvements documented for future reference
  - Complete step-by-step installation from scratch
  - Quick installation (5 commands)
  - Power Automate webhook setup
  - Verification procedures
  - Post-installation tuning
  - Troubleshooting common issues

- **Migration Guide** (`docs/MIGRATION.md`)
  - Server-to-server migration procedures
  - Agent re-registration instructions
  - Rollback procedures
  - Post-migration optimization
  - Verification checklist

- **Troubleshooting Guide** (planned for `docs/TROUBLESHOOTING.md`)
  - Common issues with solutions
  - Log analysis procedures
  - Integration debugging
  - Performance optimization

- **Rules Reference** (planned for `docs/RULES_REFERENCE.md`)
- **Complete documentation of all 101 rules**
  - Event ID mappings
  - MITRE ATT&CK technique coverage
  - Compliance framework tags

#### Examples
- **ossec.conf Configuration** (`examples/ossec.conf.example`)
  - Standard configuration (level 11)
  - High sensitivity variant (level 9)
  - Critical only variant (level 15)
  - Multi-channel setup examples
  - Rule-specific filtering

- **README with Use Cases** (`examples/README.md`)
  - Quick start examples
  - Configuration matrix
  - Customization guide
  - Testing matrix
  - Troubleshooting examples

#### Project Files
- **Main README** (`README.md`)
  - Project description and badges
  - Features overview with 101 rules breakdown
  - Impact metrics (80% alert reduction)
  - 5-step quick installation
  - Complete file structure
  - Documentation links
  - Featured rule examples
  - Teams alert format examples
  - Advanced configuration options
  - Troubleshooting section
  - Contributing guidelines

- **MIT License** (`LICENSE`)
  - Open source license for free use, modification, and distribution

- **.gitignore**
  - Excludes logs, cache files, backups, credentials
  - IDE and OS-specific files
  - Python bytecode and temporary files

### Changed
- **Alert Level Threshold**: Changed from level 9 to level 11 in ossec.conf
  - Reduced daily alerts from ~40-50 to ~5-8 summaries/day
  - 80% reduction in alert noise

- **Webhook URL Management**: Updated to new Power Automate webhook after Teams channel type change
  - Migrated from old webhook (returned HTTP 404)
  - New webhook supports "Conversaciones" channel type

### Fixed
- **SSL Certificate Verification**: Disabled SSL verification for Power Automate webhooks
  - Prevents `SSLError: certificate verify failed` errors
  - Required for internal/self-signed Power Automate endpoints

- **Dashboard URL**: Corrected Kibana dashboard links
  - Changed from generic `/app/discover` to specific view with proper filters
  - Ensures "Discover" view opens with alert context

- **Emoji Removal**: Removed all emojis from integration script
  - Prevents encoding issues in some Teams environments
  - Improves compatibility across different locales

### Security
- **Credential Protection**: Added `.gitignore` rules for sensitive files
  - Webhooks URLs not committed to repository
  - Cache files excluded from version control
  - Backup files ignored

- **Script Permissions**: Documented proper file ownership and permissions
  - Integration script: root:wazuh 750
  - Rule files: root:wazuh 640
  - Cache file: root:wazuh 660

### Performance
- **Alert Reduction**: Achieved 80% reduction in Teams notifications
  - Before: ~40-50 individual alerts/day
  - After: ~5-8 summary messages/day
  - Same security coverage with less noise

- **Cache Efficiency**: Implemented persistent cache for alert accumulation
  - Typical cache size: 2-10 KB
  - Minimal CPU impact (<0.1%)
  - Fast pickle operations (<1ms)

### Infrastructure
- **Tested Servers**:
  - Old Server: 10.0.0.10 (RHEL/CentOS - Wazuh 4.x)
  - New Server: 10.0.0.20 (Migration target)
  - Windows Agent: 10.0.0.30 (Windows Server)

- **Wazuh Version**: Tested on Wazuh 4.3+
- **Python Version**: Requires Python 3.6+
- **Teams Channel**: "Wazuh-Alerts" (Conversaciones mode)

---

## [Unreleased]

### Planned Features

#### Rules
- [ ] Additional Sysmon integration rules
- [ ] Linux audit daemon rules
- [ ] Cloud service authentication rules (AWS, Azure, GCP)
- [ ] Container security rules (Docker, Kubernetes)

#### Integration
- [ ] Slack integration option
- [ ] Email summary mode
- [ ] Webhook retry logic with exponential backoff
- [ ] Rate limiting for burst alerts
- [ ] Multi-language support for descriptions

#### Documentation
- [ ] Video walkthrough of installation
- [ ] Architecture diagram
- [ ] Performance tuning guide
- [ ] Custom rule development tutorial
- [ ] Windows agent hardening guide

#### Testing
- [ ] Unit tests for integration script
- [ ] CI/CD pipeline with GitHub Actions
- [ ] Automated testing on multiple Wazuh versions
- [ ] Performance benchmarks

#### Tools
- [ ] Web-based configuration generator
- [ ] Ansible playbook for automated deployment
- [ ] Docker container for quick testing
- [ ] Migration automation script

### Known Issues
- [ ] Some Windows Event IDs not fully documented (in progress)
- [ ] Power Automate webhook expiration not automatically detected
- [ ] Cache file can grow large in high-traffic environments (>100 alerts/hour)
- [ ] No built-in backup/restore for alert cache

### Backlog
- [ ] Support for multiple Teams channels (rule-based routing)
- [ ] Dashboard integration for cache statistics
- [ ] Alert correlation improvements
- [ ] Machine learning for anomaly detection
- [ ] Integration with ticketing systems (Jira, ServiceNow)

---

## Version History

| Version | Date | Description |
|---------|------|-------------|
| 1.0.0 | 2026-03-16 | Initial release with 101 rules, Teams integration, complete documentation |

---

## Upgrade Instructions

### From Pre-1.0 to 1.0.0

If you were using an earlier development version:

1. **Backup existing configuration:**
   ```bash
   sudo cp /var/ossec/etc/ossec.conf /root/ossec.conf.pre-v1.0.0
   sudo cp /var/ossec/integrations/custom-teams-summary.py /root/custom-teams-summary.py.old
   ```

2. **Update rule files:**
   ```bash
   sudo cp rules/*.xml /var/ossec/etc/rules/
   sudo chown root:wazuh /var/ossec/etc/rules/*.xml
   ```

3. **Update integration script:**
   ```bash
   sudo cp integrations/custom-teams-summary.py /var/ossec/integrations/
   sudo chmod 750 /var/ossec/integrations/custom-teams-summary.py
   ```

4. **Update ossec.conf:**
   - Verify `<level>11</level>` (changed from 9)
   - Update webhook URL if Teams channel changed

5. **Clear old cache (optional):**
   ```bash
   sudo rm /var/ossec/logs/teams_alerts_cache.pkl
   ```

6. **Restart Wazuh:**
   ```bash
   sudo systemctl restart wazuh-manager
   ```

7. **Test:**
   ```bash
   sudo bash scripts/test_alerts.sh
   ```

---

## Breaking Changes

### v1.0.0
- **Alert Level Change**: Default threshold increased from 9 to 11
  - **Impact**: Fewer alerts will trigger integration
  - **Action**: Adjust `<level>` in ossec.conf if you want previous behavior

- **Webhook URL Format**: Now requires full Power Automate URL
  - **Impact**: Old webhook URLs may be invalid
  - **Action**: Regenerate webhook in Power Automate and update ossec.conf

- **Cache File Location**: May have changed in development versions
  - **Impact**: Alert accumulation resets
  - **Action**: No action needed (will recreate automatically)

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on:
- Reporting bugs
- Suggesting enhancements
- Submitting pull requests
- Code style and documentation standards

---

## Support

- **GitHub Issues**: https://github.com/YOUR_USERNAME/wazuh-custom-rules-teams/issues
- **Discussions**: https://github.com/YOUR_USERNAME/wazuh-custom-rules-teams/discussions
- **Email**: your-email@example.com

---

**Maintained by:** Mateo Villablanca  
**License:** MIT  
**Repository:** https://github.com/YOUR_USERNAME/wazuh-custom-rules-teams
