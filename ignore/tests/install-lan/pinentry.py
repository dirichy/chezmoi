#!/usr/bin/env python3
"""Noninteractive passphrase UI for disposable fixture keys only."""
import sys

print("OK fixture pinentry", flush=True)
for line in sys.stdin:
    command = line.split()[0]
    if command == "GETPIN":
        print("D fixture-device-passphrase", flush=True)
    elif command == "GETINFO":
        print("D 0", flush=True)
    print("OK", flush=True)
    if command == "BYE":
        break
