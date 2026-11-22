#!/usr/bin/env python3
"""Old-device HTTP proxies and the fake subscription endpoint (stdlib only)."""

import http.client
import http.server
import json
import os
import select
import socket
import sys
from urllib.parse import urlsplit


class Proxy(http.server.BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    timeout = 120

    def log_message(self, message, *args):
        print(f"{self.server.label}: {message % args}", flush=True)

    def do_CONNECT(self):
        host, separator, port = self.path.rpartition(":")
        if not separator:
            self.send_error(400)
            return
        try:
            remote = socket.create_connection((host.strip("[]"), int(port)), timeout=30)
        except OSError:
            self.send_error(502)
            return
        with remote:
            self.send_response(200, "Connection established")
            self.end_headers()
            # CONNECT tunnels end with the connection; no HTTP keep-alive reuse.
            self.close_connection = True
            while True:
                ready = select.select([self.connection, remote], [], [], self.timeout)[0]
                if not ready:
                    return
                for incoming in ready:
                    data = incoming.recv(65536)
                    if not data:
                        return
                    (remote if incoming is self.connection else self.connection).sendall(data)

    def do_GET(self):
        target = urlsplit(self.path)
        if target.scheme != "http" or not target.hostname:
            self.send_error(400)
            return
        headers = {key: value for key, value in self.headers.items()
                   if key.lower() not in ("proxy-connection", "proxy-authorization", "connection", "host")}
        headers["Host"] = target.netloc
        headers["Connection"] = "close"
        connection = http.client.HTTPConnection(target.hostname, target.port or 80, timeout=60)
        try:
            connection.request("GET", target.path + ("?" + target.query if target.query else ""), headers=headers)
            response = connection.getresponse()
            self.send_response(response.status)
            for key, value in response.getheaders():
                if key.lower() not in ("transfer-encoding", "connection", "content-length"):
                    self.send_header(key, value)
            self.send_header("Connection", "close")
            self.end_headers()
            while data := response.read(65536):
                self.wfile.write(data)
            self.log_message("GET %s -> %s", self.path, response.status)
        except OSError:
            self.close_connection = True
        finally:
            self.close_connection = True
            connection.close()


class Subscription(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path != "/subscription-fixture-token":
            self.send_error(404)
            return
        # JSON is valid YAML and is accepted as a Mihomo proxy-provider payload.
        body = json.dumps({"proxies": [{"name": "old-device", "type": "http",
                                      "server": os.environ["OLD_IP"], "port": 18081}]}).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)
        print("subscription: served permanent proxy address", flush=True)


def serve(kind, port, label):
    server = http.server.ThreadingHTTPServer(("0.0.0.0", port), Proxy if kind == "proxy" else Subscription)
    server.daemon_threads = True
    server.label = label
    print(f"{label}: listening on {port}", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    serve(sys.argv[1], int(sys.argv[2]), sys.argv[3] if len(sys.argv) > 3 else sys.argv[1])
