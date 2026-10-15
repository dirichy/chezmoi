#!/usr/bin/env python3
from __future__ import annotations

import importlib.machinery
import importlib.util
import ipaddress
import sys
from pathlib import Path


server_path = Path(sys.argv[1])
loader = importlib.machinery.SourceFileLoader("config_share_server", str(server_path))
spec = importlib.util.spec_from_loader(loader.name, loader)
assert spec is not None
module = importlib.util.module_from_spec(spec)
loader.exec_module(module)

handler = object.__new__(module.RestrictedHandler)
handler.allowed_network = ipaddress.ip_network("192.168.50.0/24")

handler.client_address = ("127.0.0.1", 12345)
assert handler.client_allowed()
handler.client_address = ("192.168.50.25", 12345)
assert handler.client_allowed()
handler.client_address = ("192.168.51.25", 12345)
assert not handler.client_allowed()
