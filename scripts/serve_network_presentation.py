#!/usr/bin/env python3
"""
RadioHub Network Presentation & Multi-Device Server
Launches the Central Django API Backend and serves all Flutter Frontend Web Apps
over the local wireless network (Hotspot or Router).
"""

import os
import sys
import time
import socket
import signal
import subprocess
import threading
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

def get_lan_ip():
    """Detects active wireless / LAN IP address."""
    if len(sys.argv) > 1 and sys.argv[1].replace(".", "").isdigit():
        return sys.argv[1]
    env_ip = os.environ.get("BACKEND_IP")
    if env_ip:
        return env_ip
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
    except Exception:
        # Fallback to hostname -I
        try:
            out = subprocess.check_output(["hostname", "-I"]).decode().strip().split()
            ip = out[0] if out else "127.0.0.1"
        except Exception:
            ip = "127.0.0.1"
    finally:
        s.close()
    return ip

class SPAHandler(SimpleHTTPRequestHandler):
    """Serves static files, falling back to index.html for Flutter Web client routing."""
    def do_GET(self):
        # Prevent caching issues in presentation demos
        self.extensions_map.update({
            ".js": "application/javascript",
            ".wasm": "application/wasm",
            ".json": "application/json",
        })
        path = self.translate_path(self.path)
        if not os.path.exists(path) or os.path.isdir(path) and not os.path.exists(os.path.join(path, "index.html")):
            self.path = "/index.html"
        return super().do_GET()

    def end_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
        super().end_headers()

    def log_message(self, format, *args):
        # Silence verbose GET request logging during presentation
        pass

def serve_dir(directory, port, ip):
    handler = lambda *args, **kwargs: SPAHandler(*args, directory=directory, **kwargs)
    try:
        server = ThreadingHTTPServer(("0.0.0.0", port), handler)
        server.serve_forever()
    except Exception as e:
        print(f"[!] Web server on port {port} error: {e}")

def update_flutter_app_config_ip(lan_ip):
    """Updates defaultBackendHost in listener and radioadmin AppConfig."""
    files_to_update = [
        os.path.join(BASE_DIR, "listener", "lib", "core", "config", "app_config.dart"),
        os.path.join(BASE_DIR, "radioadmin", "lib", "core", "config", "app_config.dart"),
    ]
    for fpath in files_to_update:
        if os.path.exists(fpath):
            with open(fpath, "r", encoding="utf-8") as f:
                content = f.read()
            # Replace defaultBackendHost default value
            import re
            new_content = re.sub(
                r"defaultValue:\s*['\"][0-9a-zA-Z\.\-]+['\"]",
                f"defaultValue: '{lan_ip}'",
                content
            )
            with open(fpath, "w", encoding="utf-8") as f:
                f.write(new_content)

def main():
    lan_ip = get_lan_ip()
    print("=" * 70)
    print(" 🚀 RadioHub Presentation & Distributed Network Launcher")
    print("=" * 70)
    print(f" Detected Backend Host IP: {lan_ip}")
    print(f" (To use a custom IP: python3 scripts/serve_network_presentation.py <YOUR_IP>)\n")

    update_flutter_app_config_ip(lan_ip)

    # 1. Kill any existing Django on 8002
    try:
        subprocess.run(["fuser", "-k", "8002/tcp"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        time.sleep(0.5)
    except Exception:
        pass

    # 2. Launch Django Backend on 0.0.0.0:8002
    python_bin = os.path.join(BASE_DIR, "Hub", "venv", "bin", "python")
    manage_py = os.path.join(BASE_DIR, "Hub", "manage.py")
    if not os.path.exists(python_bin):
        python_bin = sys.executable

    django_proc = subprocess.Popen(
        [python_bin, manage_py, "runserver", "0.0.0.0:8002"],
        cwd=os.path.join(BASE_DIR, "Hub"),
        stdout=subprocess.DEVNULL,
        stderr=subprocess.STDOUT
    )

    # 3. Web Apps Directory Mapping
    apps = [
        ("Radio Admin Dashboard", os.path.join(BASE_DIR, "radioadmin", "build", "web"), 8081),
        ("Host Studio", os.path.join(BASE_DIR, "host", "build", "web"), 8082),
        ("Technician App", os.path.join(BASE_DIR, "technician", "build", "web"), 8083),
        ("SysAdmin Dashboard", os.path.join(BASE_DIR, "sysadmin", "build", "web"), 8084),
        ("Listener Web App", os.path.join(BASE_DIR, "listener", "build", "web"), 8085),
    ]

    for name, path, port in apps:
        if os.path.exists(path):
            t = threading.Thread(target=serve_dir, args=(path, port, lan_ip), daemon=True)
            t.start()
        else:
            print(f"[!] Warning: Build path missing for {name}: {path}")

    time.sleep(1)

    print("----------------------------------------------------------------------")
    print(" 🖥️  BACKEND SERVICES RUNNING ON THIS COMPUTER:")
    print("----------------------------------------------------------------------")
    print(f"  • Central Django API:       http://{lan_ip}:8002/api/")
    print(f"  • API Health Check:         http://{lan_ip}:8002/api/health/")
    print(f"  • Live Stream Endpoint:     http://{lan_ip}:8002/api/stream/<radioId>/")
    print("")
    print("----------------------------------------------------------------------")
    print(" 🌐 FRONTEND APPS READY FOR THE OTHER COMPUTER (Collaborator):")
    print("----------------------------------------------------------------------")
    print(f"  Open these links in the browser of Computer B / Collaborator:")
    print(f"  📻 Radio Admin:             http://{lan_ip}:8081")
    print(f"  🎙️  Host Studio:             http://{lan_ip}:8082")
    print(f"  🛠️  Technician App:          http://{lan_ip}:8083")
    print(f"  ⚙️  SysAdmin Dashboard:      http://{lan_ip}:8084")
    print(f"  🎧 Listener Web:            http://{lan_ip}:8085")
    print("----------------------------------------------------------------------")
    print("  📱 Listener Mobile App (Android/iOS):")
    print(f"     Will stream and connect directly to: http://{lan_ip}:8002")
    print("======================================================================")
    print(" [✓] Press Ctrl+C in this terminal when you want to stop all services.")

    def shutdown(signum, frame):
        print("\n[!] Shutting down all network services...")
        try:
            django_proc.terminate()
            django_proc.wait(timeout=2)
        except Exception:
            pass
        sys.exit(0)

    signal.signal(signal.SIGINT, shutdown)
    signal.signal(signal.SIGTERM, shutdown)

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        shutdown(None, None)

if __name__ == "__main__":
    main()
