#!/usr/bin/env python3
"""Local checks of proxy forwarding, fixture subscription and port shutdown.

Only uses loopback listeners; no Internet or Docker is needed.
"""
import http.client
import http.server
import importlib.util
import json
import os
from pathlib import Path
import socket
import subprocess
import sys
import threading
import time

fixture = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("lan_services", fixture / "lan-services.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class Target(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        body = b"local-proxy-target"
        self.send_response(200)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *_args):
        pass


servers = []
child = None
try:
    target = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Target)
    proxy = http.server.ThreadingHTTPServer(("127.0.0.1", 0), module.Proxy)
    proxy.label = "fixture"
    subscription = http.server.ThreadingHTTPServer(("127.0.0.1", 0), module.Subscription)
    os.environ["OLD_IP"] = "127.0.0.1"
    for server in (target, proxy, subscription):
        servers.append(server)
        threading.Thread(target=server.serve_forever, daemon=True).start()
    proxy_port = proxy.server_address[1]
    target_port = target.server_address[1]
    request = http.client.HTTPConnection("127.0.0.1", proxy_port, timeout=5)
    request.request("GET", f"http://127.0.0.1:{target_port}/target?fixture=1")
    response = request.getresponse()
    assert response.status == 200 and response.read() == b"local-proxy-target"
    request.close()
    request = http.client.HTTPConnection("127.0.0.1", proxy_port, timeout=5)
    request.set_tunnel("127.0.0.1", target_port)
    request.request("GET", "/target")
    response = request.getresponse()
    assert response.status == 200 and response.read() == b"local-proxy-target"
    request.close()
    request = http.client.HTTPConnection("127.0.0.1", proxy_port, timeout=5)
    request.request("GET", f"http://127.0.0.1:{subscription.server_address[1]}/subscription-fixture-token")
    response = request.getresponse()
    payload = json.loads(response.read())
    assert payload["proxies"][0] == {"name": "old-device", "type": "http", "server": "127.0.0.1", "port": 18081}
    request.close()
    # Killing the temporary proxy must close both existing tunnels and the listener.
    with socket.socket() as reservation:
        reservation.bind(("127.0.0.1", 0))
        temporary_port = reservation.getsockname()[1]
    child = subprocess.Popen([sys.executable, str(fixture / "lan-services.py"), "proxy", str(temporary_port), "temporary"],
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    for _ in range(100):
        try:
            tunnel = socket.create_connection(("127.0.0.1", temporary_port), timeout=1)
            break
        except OSError:
            assert child.poll() is None
            time.sleep(0.02)
    else:
        raise AssertionError("Temporary proxy did not start")
    with tunnel:
        tunnel.sendall(f"CONNECT 127.0.0.1:{target_port} HTTP/1.1\r\nHost: target\r\n\r\n".encode())
        header = b""
        while b"\r\n\r\n" not in header:
            header += tunnel.recv(4096)
        assert b"200 Connection established" in header
        child.terminate()
        child.wait(timeout=5)
        assert tunnel.recv(1) == b"", "Established tunnel survived proxy shutdown"
    with socket.socket() as connection:
        assert connection.connect_ex(("127.0.0.1", temporary_port)) != 0
    print("PASS: HTTP forwarding, CONNECT, subscription payload and temporary listener/tunnel shutdown")
finally:
    if child is not None and child.poll() is None:
        child.terminate()
        child.wait(timeout=5)
    for server in servers:
        server.shutdown()
        server.server_close()
