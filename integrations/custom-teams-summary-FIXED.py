#!/var/ossec/framework/python/bin/python3
"""
Wazuh Teams Integration - Resumen Diario (MEJORADO v2)
Acumula alertas y envía resumen cada 24h o al alcanzar el límite
MEJORAS:
  - Retry con backoff exponencial
  - Validación de campos requeridos
  - Variables de entorno para configuración
  - Logging estructurado
  - Lock file para thread-safety
  - Deduplicación de alertas
"""
import ssl
ssl._create_default_https_context = ssl._create_unverified_context

import sys
import json
import urllib.request
import urllib.error
import os
from datetime import datetime, timedelta
import pickle
import logging
import fcntl
import time

# Configuración (desde variables de entorno o defaults)
CACHE_FILE = os.getenv('WAZUH_TEAMS_CACHE_FILE', "/var/ossec/logs/teams_alerts_cache.pkl")
LOG_FILE = os.getenv('WAZUH_TEAMS_LOG_FILE', "/var/ossec/logs/integrations.log")
SUMMARY_INTERVAL_HOURS = int(os.getenv('WAZUH_TEAMS_SUMMARY_HOURS', 24))
MAX_ALERTS_BEFORE_SUMMARY = int(os.getenv('WAZUH_TEAMS_MAX_ALERTS', 3))
CRITICAL_LEVEL = int(os.getenv('WAZUH_TEAMS_CRITICAL_LEVEL', 15))
MAX_RETRY_ATTEMPTS = int(os.getenv('WAZUH_TEAMS_MAX_RETRIES', 3))
RETRY_BACKOFF_INITIAL = float(os.getenv('WAZUH_TEAMS_RETRY_BACKOFF', 2))
CACHE_MAX_AGE_HOURS = int(os.getenv('WAZUH_TEAMS_CACHE_AGE', 48))
LOCK_FILE = CACHE_FILE + ".lock"

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s %(levelname)s %(message)s',
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger('wazuh-teams-integration')

def acquire_lock():
    """Adquirir lock file para thread-safety"""
    try:
        lock_file = open(LOCK_FILE, 'w')
        fcntl.flock(lock_file.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        return lock_file
    except IOError:
        return None

def release_lock(lock_file):
    """Liberar lock file"""
    if lock_file:
        try:
            fcntl.flock(lock_file.fileno(), fcntl.LOCK_UN)
            lock_file.close()
        except:
            pass

def load_cache():
    """Cargar caché de alertas acumuladas (con lock)"""
    cache = {
        'alerts': [],
        'last_summary_time': datetime.now() - timedelta(days=1),
        'summary_count': 0
    }
    
    if os.path.exists(CACHE_FILE):
        try:
            with open(CACHE_FILE, 'rb') as f:
                data = pickle.load(f)
                if isinstance(data, dict):
                    cache = data
                    logger.debug(f"Cache loaded with {len(cache.get('alerts', []))} alerts")
        except Exception as e:
            logger.warning(f"Failed to load cache: {e}. Starting fresh.")
    
    return cache

def save_cache(cache):
    """Guardar caché (con lock y expiración)"""
    lock_file = acquire_lock()
    if not lock_file:
        logger.error("Could not acquire lock file for cache write")
        return False
    
    try:
        # Eliminar alertas muy antiguas (>CACHE_MAX_AGE_HOURS)
        cutoff_time = datetime.now() - timedelta(hours=CACHE_MAX_AGE_HOURS)
        original_count = len(cache.get('alerts', []))
        cache['alerts'] = [
            a for a in cache.get('alerts', [])
            if datetime.fromisoformat(a.get('timestamp', '')) > cutoff_time
        ]
        
        if len(cache['alerts']) < original_count:
            logger.info(f"Removed {original_count - len(cache['alerts'])} expired alerts from cache")
        
        with open(CACHE_FILE, 'wb') as f:
            pickle.dump(cache, f)
        os.chmod(CACHE_FILE, 0o660)
        logger.debug(f"Cache saved with {len(cache['alerts'])} alerts")
        return True
    except Exception as e:
        logger.error(f"Error saving cache: {e}")
        return False
    finally:
        release_lock(lock_file)

def validate_alert(alert):
    """Validar que la alerta tenga todos los campos requeridos"""
    required_fields = [
        ('rule.id', lambda a: a.get('rule', {}).get('id')),
        ('rule.level', lambda a: a.get('rule', {}).get('level')),
        ('rule.description', lambda a: a.get('rule', {}).get('description')),
        ('agent.name', lambda a: a.get('agent', {}).get('name')),
        ('timestamp', lambda a: a.get('timestamp')),
    ]
    
    for field_name, getter in required_fields:
        try:
            value = getter(alert)
            if not value:
                logger.warning(f"Missing field: {field_name}")
                return False
        except Exception as e:
            logger.warning(f"Error validating {field_name}: {e}")
            return False
    
    return True

def is_duplicate_alert(cache, alert):
    """Detectar si la alerta ya está en caché (deduplicación)"""
    alert_id = alert.get('id')
    if not alert_id:
        return False
    
    for existing in cache.get('alerts', []):
        if existing.get('id') == alert_id:
            logger.info(f"Duplicate alert detected: {alert_id}")
            return True
    
    return False

def send_with_retry(webhook_url, message, max_attempts=None):
    """Enviar a Teams con retry y backoff exponencial"""
    if max_attempts is None:
        max_attempts = MAX_RETRY_ATTEMPTS
    
    for attempt in range(1, max_attempts + 1):
        try:
            data = json.dumps(message).encode('utf-8')
            headers = {'Content-Type': 'application/json'}
            
            request = urllib.request.Request(webhook_url, data=data, headers=headers)
            response = urllib.request.urlopen(request, timeout=30)
            
            if response.status in (200, 202):
                logger.info(f"Alert sent successfully (attempt {attempt})")
                return True
        except urllib.error.HTTPError as e:
            logger.warning(f"HTTP Error {e.code} (attempt {attempt}/{max_attempts}): {e.reason}")
            if attempt < max_attempts:
                wait_time = RETRY_BACKOFF_INITIAL * (2 ** (attempt - 1))
                logger.info(f"Retrying in {wait_time}s...")
                time.sleep(wait_time)
        except urllib.error.URLError as e:
            logger.warning(f"Network error (attempt {attempt}/{max_attempts}): {e.reason}")
            if attempt < max_attempts:
                wait_time = RETRY_BACKOFF_INITIAL * (2 ** (attempt - 1))
                logger.info(f"Retrying in {wait_time}s...")
                time.sleep(wait_time)
        except Exception as e:
            logger.error(f"Unexpected error (attempt {attempt}/{max_attempts}): {e}")
            if attempt < max_attempts:
                wait_time = RETRY_BACKOFF_INITIAL * (2 ** (attempt - 1))
                time.sleep(wait_time)
    
    logger.error(f"Failed to send after {max_attempts} attempts")
    return False

def should_send_summary(cache):
    """Determinar si es momento de enviar resumen"""
    time_since_summary = datetime.now() - cache['last_summary_time']
    hours_passed = time_since_summary.total_seconds() / 3600
    
    return (hours_passed >= SUMMARY_INTERVAL_HOURS or 
            len(cache['alerts']) >= MAX_ALERTS_BEFORE_SUMMARY)

def extract_user_info(alert):
    """
    Extraer usuario de alerta (MEJORADO para correlaciones)
    
    Busca en este orden:
    1. Windows eventdata (subjectUserName, targetUserName)
    2. Campos directos (srcuser, dstuser)
    3. Eventos relacionados (para correlaciones)
    """
    data = alert.get('data', {})
    
    # Windows events - estructura más detallada
    if 'win' in data:
        eventdata = data['win'].get('eventdata', {})
        user = eventdata.get('subjectUserName') or eventdata.get('targetUserName')
        domain = eventdata.get('subjectDomainName') or eventdata.get('targetDomainName')
        if user:
            return f"{domain}\\{user}" if domain else user
    
    # Campos directos en datos
    if 'srcuser' in data:
        return data['srcuser']
    if 'dstuser' in data:
        return data['dstuser']
    
    # Para correlaciones: buscar en eventos relacionados
    # Típicamente en reglas de brute force (200004, 200005)
    if 'related_events' in data:
        users = []
        for event in data['related_events']:
            if 'user' in event and event['user'] not in users:
                users.append(event['user'])
        
        if users:
            # Retornar lista de usuarios
            if len(users) <= 3:
                return " | ".join(users)
            else:
                return f"{users[0]} | {users[1]} (+{len(users)-2} más)"
    
    return None

def extract_source_ip(alert):
    """Extraer IP de origen"""
    data = alert.get('data', {})
    
    if 'srcip' in data:
        return data['srcip']
    
    if 'win' in data:
        eventdata = data['win'].get('eventdata', {})
        ip = eventdata.get('ipAddress') or eventdata.get('workstationName')
        return ip
    
    return None

def is_correlation_rule(alert):
    """Detectar si es una regla de correlación (frequency, timeframe o parent_rule_id)"""
    rule = alert.get('rule', {})
    return (
        'frequency' in rule or 
        'timeframe' in rule or 
        'parent_rule_id' in rule or
        'if_matched_sid' in rule
    )

def build_summary_card(cache, webhook_url):
    """Construir tarjeta de resumen con todas las alertas acumuladas"""
    alerts = cache['alerts']
    
    # Estadísticas
    total_alerts = len(alerts)
    by_level = {}
    by_rule = {}
    by_agent = {}
    top_mitre = {}
    
    for alert in alerts:
        level = alert['rule']['level']
        rule_id = alert['rule']['id']
        agent = alert['agent']['name']
        
        by_level[level] = by_level.get(level, 0) + 1
        by_rule[rule_id] = by_rule.get(rule_id, 0) + 1
        by_agent[agent] = by_agent.get(agent, 0) + 1
        
        # MITRE
        if 'mitre' in alert['rule']:
            for tech in alert['rule']['mitre'].get('id', []):
                top_mitre[tech] = top_mitre.get(tech, 0) + 1
    
    # Top 5 reglas
    top_rules = sorted(by_rule.items(), key=lambda x: x[1], reverse=True)[:5]
    top_mitre_list = sorted(top_mitre.items(), key=lambda x: x[1], reverse=True)[:5]
    
    # Severidad predominante
    max_level = max(by_level.keys()) if by_level else 0
    
    if max_level >= 15:
        severity_emoji = "🔴"
        severity_text = "CRÍTICO"
        color = "Attention"
    elif max_level >= 12:
        severity_emoji = "🟠"
        severity_text = "MUY ALTO"
        color = "Attention"
    elif max_level >= 10:
        severity_emoji = "🟡"
        severity_text = "ALTO"
        color = "Warning"
    else:
        severity_emoji = "🔵"
        severity_text = "MEDIO"
        color = "Good"
    
    # Construir mensaje
    message = {
        "type": "message",
        "attachments": [{
            "contentType": "application/vnd.microsoft.card.adaptive",
            "content": {
                "type": "AdaptiveCard",
                "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
                "version": "1.4",
                "body": [
                    {
                        "type": "Container",
                        "style": color,
                        "items": [
                            {
                                "type": "TextBlock",
                                "text": f"{severity_emoji} **Resumen de Alertas Wazuh - 24h**",
                                "weight": "Bolder",
                                "size": "Large",
                                "wrap": True
                            },
                            {
                                "type": "TextBlock",
                                "text": f"Severidad máxima: {severity_text}",
                                "weight": "Bolder",
                                "size": "Medium"
                            }
                        ]
                    },
                    {
                        "type": "FactSet",
                        "facts": [
                            {"title": "Total de Alertas", "value": str(total_alerts)},
                            {"title": "Período", "value": f"{SUMMARY_INTERVAL_HOURS}h"},
                            {"title": "Nivel Máximo", "value": str(max_level)},
                            {"title": "Agentes Afectados", "value": str(len(by_agent))}
                        ]
                    },
                    {
                        "type": "TextBlock",
                        "text": "**Distribución por Nivel**",
                        "weight": "Bolder",
                        "separator": True
                    },
                    {
                        "type": "FactSet",
                        "facts": [
                            {"title": f"Nivel {lvl}", "value": f"{count} alertas"}
                            for lvl, count in sorted(by_level.items(), reverse=True)
                        ]
                    },
                    {
                        "type": "TextBlock",
                        "text": "**Top 5 Reglas Activadas**",
                        "weight": "Bolder",
                        "separator": True
                    }
                ]
            }
        }]
    }
    
    # Agregar top reglas
    for i, (rule_id, count) in enumerate(top_rules, 1):
        # Buscar descripción
        desc = next((a['rule']['description'] for a in alerts if a['rule']['id'] == rule_id), "Unknown")
        if len(desc) > 80:
            desc = desc[:77] + "..."
        
        message["attachments"][0]["content"]["body"].append({
            "type": "TextBlock",
            "text": f"{i}. **Rule {rule_id}** ({count}x): {desc}",
            "wrap": True,
            "size": "Small"
        })
    
    # MITRE ATT&CK si existe
    if top_mitre_list:
        message["attachments"][0]["content"]["body"].append({
            "type": "TextBlock",
            "text": "**Top MITRE ATT&CK**",
            "weight": "Bolder",
            "separator": True
        })
        
        mitre_text = " | ".join([f"{tech} ({count}x)" for tech, count in top_mitre_list])
        message["attachments"][0]["content"]["body"].append({
            "type": "TextBlock",
            "text": mitre_text,
            "wrap": True,
            "size": "Small"
        })
    
    # Top 3 alertas más críticas
    top_critical = sorted(alerts, key=lambda x: (-x['rule']['level'], x['timestamp']))[:3]
    
    if top_critical:
        message["attachments"][0]["content"]["body"].append({
            "type": "TextBlock",
            "text": "**[ALERTA] Top 3 Alertas Críticas**",
            "weight": "Bolder",
            "separator": True
        })
        
        for i, alert in enumerate(top_critical, 1):
            ts = alert['timestamp'].split('T')[1][:8]
            desc = alert['rule']['description'][:60] + "..." if len(alert['rule']['description']) > 60 else alert['rule']['description']
            
            message["attachments"][0]["content"]["body"].append({
                "type": "TextBlock",
                "text": f"{i}. [{ts}] **Nivel {alert['rule']['level']}** - {desc}",
                "wrap": True,
                "size": "Small"
            })
    
    # Botón de acción
    dashboard_url = os.environ.get('WAZUH_DASHBOARD_URL', 'https://wazuh.example.invalid/app/wazuh')
    message["attachments"][0]["content"]["body"].append({
        "type": "ActionSet",
        "separator": True,
        "actions": [{
            "type": "Action.OpenUrl",
            "title": "Ver Dashboard Wazuh",
            "url": dashboard_url
        }]
    })
    
    return message

def build_immediate_alert(alert_json, webhook_url):
    """
    Construir tarjeta de alerta inmediata (nivel crítico >=15)
    MEJORADO: Mejor manejo de alertas de correlación
    """
    alert = alert_json
    level = alert['rule']['level']
    is_correlation = is_correlation_rule(alert)
    
    severity_emoji = "🔴"
    severity_text = "CRÍTICO"
    color = "Attention"
    
    user_info = extract_user_info(alert)
    source_ip = extract_source_ip(alert)
    
    # Para correlaciones, mejorar el texto de usuario
    if is_correlation and not user_info:
        user_info = "Múltiples intentos detectados"
    
    message = {
        "type": "message",
        "attachments": [{
            "contentType": "application/vnd.microsoft.card.adaptive",
            "content": {
                "type": "AdaptiveCard",
                "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
                "version": "1.4",
                "body": [
                    {
                        "type": "Container",
                        "style": color,
                        "items": [
                            {
                                "type": "TextBlock",
                                "text": f"{severity_emoji} **ALERTA CRÍTICA - Nivel {level}**",
                                "weight": "Bolder",
                                "size": "Large",
                                "wrap": True,
                                "color": "Attention"
                            },
                            {
                                "type": "TextBlock",
                                "text": alert['rule']['description'],
                                "wrap": True,
                                "weight": "Bolder"
                            },
                            # Agregar tipo si es correlación
                            {
                                "type": "TextBlock",
                                "text": "🔗 **Alerta de Correlación** - Múltiples eventos relacionados" if is_correlation else "",
                                "wrap": True,
                                "size": "Small",
                                "isSubtle": True
                            } if is_correlation else {"type": "TextBlock", "text": "", "isVisible": False}
                        ]
                    },
                    {
                        "type": "FactSet",
                        "facts": [
                            {"title": "Rule ID", "value": alert['rule']['id']},
                            {"title": "Nivel", "value": str(level)},
                            {"title": "Agente", "value": alert['agent']['name']},
                            {"title": "Timestamp", "value": alert['timestamp'].replace('T', ' ')[:19]}
                        ]
                    }
                ]
            }
        }]
    }
    
    # Agregar usuario si existe
    if user_info:
        message["attachments"][0]["content"]["body"][1]["facts"].insert(
            3, 
            {"title": "Usuario/Cuenta", "value": user_info}
        )
    
    # Agregar IP si existe
    if source_ip:
        user_idx = 3 if user_info else 3
        message["attachments"][0]["content"]["body"][1]["facts"].insert(
            user_idx + 1, 
            {"title": "IP Origen", "value": source_ip}
        )
    
    # Agregar eventos relacionados si es correlación
    if is_correlation and 'related_events' in alert.get('data', {}):
        message["attachments"][0]["content"]["body"].append({
            "type": "TextBlock",
            "text": "**Eventos Relacionados (muestras)**",
            "weight": "Bolder",
            "separator": True
        })
        
        related = alert['data']['related_events'][:5]  # Top 5
        for event in related:
            ts = event.get('timestamp', '').split('T')[1][:8] if 'timestamp' in event else 'N/A'
            rule = event.get('rule_id', 'Unknown')
            user = event.get('user', 'N/A')
            message["attachments"][0]["content"]["body"].append({
                "type": "TextBlock",
                "text": f"• [{ts}] Rule {rule}: Usuario={user}",
                "size": "Small",
                "wrap": True
            })
    
    # Log preview si existe
    if 'full_log' in alert:
        log_preview = alert['full_log'][:400]
        message["attachments"][0]["content"]["body"].append({
            "type": "TextBlock",
            "text": "**Log**",
            "weight": "Bolder",
            "separator": True
        })
        message["attachments"][0]["content"]["body"].append({
            "type": "TextBlock",
            "text": log_preview,
            "wrap": True,
            "size": "Small",
            "isSubtle": True
        })
    
    # Botón de acción
    dashboard_url = os.environ.get('WAZUH_DASHBOARD_URL', 'https://wazuh.example.invalid/app/wazuh')
    message["attachments"][0]["content"]["body"].append({
        "type": "ActionSet",
        "separator": True,
        "actions": [{
            "type": "Action.OpenUrl",
            "title": "Ver en Dashboard",
            "url": dashboard_url
        }]
    })
    
    return message

def send_to_teams(message, webhook_url):
    """Enviar mensaje a Teams con retry automático"""
    return send_with_retry(webhook_url, message)

def main():
    # Leer alerta desde stdin
    try:
        alert_json = json.loads(sys.stdin.read())
    except json.JSONDecodeError as e:
        logger.error(f"Error parsing JSON alert: {e}")
        sys.exit(1)
    
    # Validar alerta
    if not validate_alert(alert_json):
        logger.error("Alert validation failed - missing required fields")
        sys.exit(1)
    
    # Leer webhook de argumentos
    webhook_url = sys.argv[1] if len(sys.argv) > 1 else ""
    
    if not webhook_url:
        logger.error("No webhook URL provided")
        sys.exit(1)
    
    # Cargar caché
    cache = load_cache()
    
    # Nivel de alerta
    level = alert_json['rule']['level']
    
    # Alertas CRÍTICAS (>=15) se envían inmediatamente
    if level >= CRITICAL_LEVEL:
        message = build_immediate_alert(alert_json, webhook_url)
        if send_to_teams(message, webhook_url):
            logger.info(f"Critical alert sent immediately (Rule {alert_json['rule']['id']}, Level {level})")
        else:
            logger.error(f"Failed to send critical alert (Rule {alert_json['rule']['id']})")
        save_cache(cache)  # Guardar caché sin cambios
        sys.exit(0)
    
    # Alertas 11-14: acumular con deduplicación
    if is_duplicate_alert(cache, alert_json):
        logger.info(f"Skipping duplicate alert {alert_json.get('id', 'unknown')}")
        save_cache(cache)
        sys.exit(0)
    
    cache['alerts'].append(alert_json)
    logger.info(f"Alert accumulated (Rule {alert_json['rule']['id']}, Level {level})")
    
    # Enviar si se alcanzó el límite de acumulación
    if should_send_summary(cache):
        message = build_summary_card(cache, webhook_url)
        if send_to_teams(message, webhook_url):
            logger.info(f"Summary sent: {len(cache['alerts'])} alerts")
            cache['alerts'] = []
            cache['last_summary_time'] = datetime.now()
            cache['summary_count'] += 1
        else:
            logger.error(f"Failed to send summary with {len(cache['alerts'])} alerts")
    else:
        logger.info(f"Alert accumulated ({len(cache['alerts'])}/{MAX_ALERTS_BEFORE_SUMMARY}). Not sending yet.")
    
    # Guardar caché
    save_cache(cache)
    sys.exit(0)

if __name__ == '__main__':
    main()
