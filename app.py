from flask import Flask, request, jsonify
import time
import requests
from threading import Lock
from collections import defaultdict
import json
import socket
import random

app = Flask(__name__)

# Webhook URLs
REAL_WEBHOOK_URL = "https://discord.com/api/webhooks/1365980615329189929/VYnMsc4_3xTB5pmINbpbkFyXGKgtfy6oQx3MOUmWq6Ztj920Yj5efA2EzDVdOGiZhsDg"
SECURITY_WEBHOOK = "https://discord.com/api/webhooks/1367042450203607114/Fj7JfYokSNQ73-RLt3KGD1Cx7EnjOiwsqpa-yajzuZEvqzB_gDgObWShI7F3zGCQINPd"
NEW_WEBHOOK_URL = "https://discord.com/api/webhooks/1372224432755445833/iRgN4jnS-ineeFlvkAIfQrFj9KlsolFg3mC514yrq1daqsQ-iWVn3Z_rjstSde4Ef87U"

# Rate limiting configuration
RATE_LIMIT_SECONDS = 1
MIN_REQUEST_INTERVAL = 0.5
request_times = defaultdict(float)
rate_lock = Lock()

# Security tracking
alerted_ips = set()
spam_ips = set()
security_lock = Lock()

def get_client_info(ip):
    try:
        hostname = socket.gethostbyaddr(ip)[0]
    except:
        hostname = "N/A"
    
    return {
        "IP": ip,
        "Hostname": hostname,
        "User-Agent": request.headers.get('User-Agent', 'None'),
        "Content-Length": request.headers.get('Content-Length', '0'),
        "Headers": dict(request.headers),
        "X-Forwarded-For": request.headers.get('X-Forwarded-For', 'None')
    }

def is_skid_request(client_info):
    skid_indicators = [
        "python-requests", 
        "curl", 
        "wget",
        "Thread",
        "Spam",
        "Hack",
        "Skid",
        "LMAO",
        "KYS"
    ]
    ua = client_info['User-Agent'].lower()
    return any(indicator.lower() in ua for indicator in skid_indicators)

def format_skid_message(client_info):
    insults = [
        "Imagine getting ratioed by a rate limiter",
        "Your mom writes better Python scripts",
        "0/10 spamming technique",
        "Even Cloudflare blocks harder than this",
        "Your IP: ☠️ REST IN PEPPERONIS ☠️",
        "Try harder skid 😂"
    ]
    return random.choice(insults)

def send_security_alert(message, client_info, payload=None):
    if isinstance(payload, bytes):
        try:
            payload = payload.decode('utf-8', errors='replace')
        except:
            payload = str(payload)[:1000]

    is_skid = is_skid_request(client_info)
    title = "😂 SKID ALERT 😂" if is_skid else "🚨 Proxy Security Alert 🚨"
    color = 0xFF69B4 if is_skid else 0xFF0000
    
    embed = {
        "title": title,
        "color": color,
        "fields": [
            {"name": "IP Address", "value": f"`{client_info['IP']}`", "inline": True},
            {"name": "Hostname", "value": f"`{client_info['Hostname']}`", "inline": True},
            {"name": "User Agent", "value": f"```{client_info['User-Agent']}```"},
            {"name": "Content Length", "value": client_info['Content-Length'], "inline": True},
            {"name": "Alert Type", "value": message, "inline": True},
            {"name": "X-Forwarded-For", "value": f"`{client_info['X-Forwarded-For']}`", "inline": False}
        ],
        "footer": {
            "text": format_skid_message(client_info) if is_skid else "Security System Alert"
        },
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    }
    
    if payload:
        try:
            payload_str = json.dumps(json.loads(payload), indent=2)[:1000] if isinstance(payload, str) else str(payload)[:1000]
            embed["fields"].append({
                "name": "Payload Preview",
                "value": f"```{payload_str}```"
            })
        except:
            pass
    
    data = {
        "content": "@creator" if is_skid else "@Creator",
        "embeds": [embed]
    }
    
    requests.post(SECURITY_WEBHOOK, json=data)

def validate_roblox_data(data):
    try:
        if isinstance(data, bytes):
            data = data.decode('utf-8')
        payload = json.loads(data)
        if not isinstance(payload.get('embeds'), list):
            return False
        if len(payload['embeds']) == 0:
            return False
        embeds = payload['embeds'][0]
        return all(key in embeds for key in ['description', 'color', 'footer'])
    except:
        return False

def check_executor_and_send(data):
    try:
        payload = json.loads(data)
        embeds = payload.get('embeds', [{}])[0]
        description = embeds.get('description', '')
        for field in description.split('\n'):
            if 'Executor:' in field:
                executor = field.split(': ')[1].strip().lower()
                if not any(ex in executor for ex in ['xeno', 'solara', 'delta', 'swift', 'codex', 'arceus', 'krnl']):
                    requests.post(
                        NEW_WEBHOOK_URL,
                        data=data,
                        headers={'Content-Type': 'application/json'},
                        timeout=5
                    )
                break
    except:
        pass

@app.route('/proxy', methods=['POST'])
def proxy_webhook():
    client_ip = request.remote_addr
    client_info = get_client_info(client_ip)
    is_valid_request = validate_roblox_data(request.data)

    with rate_lock:
        current_time = time.time()
        last_request_time = request_times.get(client_ip, 0)
        time_since_last = current_time - last_request_time
        
        if time_since_last < MIN_REQUEST_INTERVAL:
            if is_skid_request(client_info):
                send_security_alert("BURST ATTACK DETECTED", client_info, "Skid tried to spam too fast")
            return jsonify({"error": "Request too fast"}), 429
            
        if time_since_last < RATE_LIMIT_SECONDS:
            with security_lock:
                if client_ip not in alerted_ips:
                    alert_msg = "SKID RATE LIMIT" if is_skid_request(client_info) else "Rate limit violation"
                    send_security_alert(alert_msg, client_info, request.data)
                    alerted_ips.add(client_ip)
            return jsonify({"error": "Rate limited"}), 429
            
        request_times[client_ip] = current_time

    if not is_valid_request:
        with security_lock:
            if client_ip not in spam_ips:
                alert_type = "SKID PAYLOAD" if is_skid_request(client_info) else "Invalid request"
                send_security_alert(alert_type, client_info, request.data)
                spam_ips.add(client_ip)
        return jsonify({"error": "Invalid request format"}), 400

    check_executor_and_send(request.data)

    try:
        discord_response = requests.post(
            REAL_WEBHOOK_URL,
            data=request.data,
            headers={'Content-Type': 'application/json'},
            timeout=5
        )
        return jsonify({
            "status": "forwarded",
            "discord_status": discord_response.status_code
        }), 200
    except Exception as e:
        send_security_alert(f"Forwarding error: {str(e)}", client_info)
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
