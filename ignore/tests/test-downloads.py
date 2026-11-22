#!/usr/bin/env python3
"""Offline checks for mirror selection, public download probes and opt-in scheduling."""

from io import BytesIO
import json
from pathlib import Path
import runpy
import shutil
import subprocess
import sys
import tomllib
from email.message import Message
from unittest.mock import patch

repo, temporary = map(Path, sys.argv[1:])
root = temporary / "downloads"
root.mkdir()
module = runpy.run_path(str(repo / "ignore/bin/check-downloads"))
fixture = repo / "ignore/tests/fixtures/linux-desktop.toml"
base = ["chezmoi", "--source", str(repo), "--destination", str(root / "home"),
        "--cache", str(root / "cache"), "--persistent-state", str(root / "state"),
        "--config", str(fixture), "--refresh-externals=never", "--no-tty"]

defaults = module["collect_downloads"](repo, fixture)
assert all(url.startswith("https://ghfast.top/") for label, url in defaults if "[fallback" not in label)

for mode, prefix in (("ghfast", "https://ghfast.top/"), ("direct", ""), ("custom", "https://mirror.example/github/")):
    prompts = ["--promptChoice", "GitHub download mirror=" + mode]
    if mode == "custom":
        prompts += ["--promptString", "GitHub mirror HTTPS prefix (prepended to the original URL)=" + prefix.rstrip("/")]
    rendered = subprocess.check_output(base + ["execute-template", "--init", "--stdinisatty=false",
                                               *prompts, "--file", str(repo / ".chezmoi.toml.tmpl")], text=True)
    data = tomllib.loads(rendered)["data"]
    assert data["downloads"] == {"preferChezmoi": True, "githubMirror": mode, "githubMirrorPrefix": prefix}
    assert data["features"]["downloadChecks"] is False
    # Preserve an intentionally failing secret command; collecting links must never invoke it.
    config = root / f"{mode}.json"
    config.write_text(json.dumps({"data": data, "secret": {"command": "/nonexistent-secret-command"}}))
    items = module["collect_downloads"](repo, config)
    assert len(items) > 60, items
    for label, url in items:
        if "[fallback" not in label:
            assert url.startswith(prefix + "https://"), (label, url)
        assert "subscribe.com" not in url and "gopass" not in url
        if ".spoon" in label:
            assert "/master/Spoons/" in url
        if label.startswith(("mihomo/geo", "mihomo/country.mmdb")):
            assert "/meta-rules-dat/release/" in url
    official = module["collect_downloads"](repo, config, direct=True)
    assert all(url.startswith(("https://github.com/", "https://raw.githubusercontent.com/")) for _, url in official)

# Geo follows the existing download preference on both platforms. Render only: no downloads.
geo_targets = {f".config/mihomo/{name}" for name in ("GeoIP.dat", "GeoSite.dat", "Country.mmdb")}
for platform in ("linux", "darwin"):
    for prefer in (None, True, False):
        override = {"chezmoi": {"os": platform}, "apps": {"mihomo": {"enabled": True}}}
        if prefer is not None:
            override["downloads"] = {"preferChezmoi": prefer}
        command = base + ["--override-data", json.dumps(override), "execute-template", "--file"]
        externals = tomllib.loads(subprocess.check_output(command + [str(repo / ".chezmoiexternal.toml")], text=True))
        assert geo_targets.intersection(externals) == (geo_targets if prefer is not False else set())
        for target in geo_targets.intersection(externals):
            entry = externals[target]
            assert entry["type"] == "file" and entry["refreshPeriod"] == "24h"
            assert len(entry["urls"]) == 4 and len(set(entry["urls"])) == 4
            assert all(url.endswith("/" + Path(target).name.lower()) for url in entry["urls"])
        mihomo = subprocess.check_output(command + [str(repo / "dot_config/mihomo/config.yaml.tmpl")], text=True)
        assert f"geo-auto-update: {'true' if prefer is False else 'false'}" in mihomo
        assert "geo-update-interval: 24" in mihomo
command = base + ["--override-data", '{"apps":{"mihomo":{"enabled":false}}}', "execute-template", "--file"]
externals = tomllib.loads(subprocess.check_output(command + [str(repo / ".chezmoiexternal.toml")], text=True))
assert not geo_targets.intersection(externals)

invalid = subprocess.run(base + ["execute-template", "--init", "--stdinisatty=false", "--promptChoice",
                                 "GitHub download mirror=custom", "--promptString",
                                 "GitHub mirror HTTPS prefix (prepended to the original URL)=http://mirror.example/",
                                 "--file", str(repo / ".chezmoi.toml.tmpl")], capture_output=True, text=True)
assert invalid.returncode != 0 and "HTTPS" in invalid.stderr, invalid


class Response(BytesIO):
    status = 200

    def __init__(self, body, content_type="application/octet-stream"):
        super().__init__(body)
        self.headers = Message()
        self.headers["Content-Type"] = content_type


check = module["check_download"]
for body, mime, url, expected in ((b"PK\x03\x04zip data", "application/zip", "https://example.com/a.zip", True),
                                  (b"<!doctype html>error", "application/octet-stream", "https://example.com/a.dat", False),
                                  (b"error page", "text/html", "https://example.com/a.dat", False),
                                  (b"not zip", "text/plain", "https://example.com/a.zip", False),
                                  (b"", "application/octet-stream", "https://example.com/a.dat", False)):
    with patch.dict(check.__globals__, urlopen=lambda *a, **kw: Response(body, mime)):
        assert check(("fixture", url), 1)[0] == expected
with patch.dict(check.__globals__, urlopen=lambda *a, **kw: (_ for _ in ()).throw(TimeoutError("timeout"))):
    assert not check(("fixture", "https://example.com/a.dat"), 1)[0]

# A minimal source ensures managed-list checks never inspect/download external resources.
source = root / "source"
source.mkdir()
shutil.copy2(repo / ".chezmoiignore", source)
units = source / "dot_config/systemd/user"
units.mkdir(parents=True)
for name in ("dotfiles-download-check.service.tmpl", "dotfiles-download-check.timer"):
    shutil.copy2(repo / "dot_config/systemd/user" / name, units)
for os_name, enabled, expected in (("linux", False, False), ("linux", True, True), ("darwin", True, False)):
    overrides = json.dumps({"chezmoi": {"os": os_name}, "features": {"downloadChecks": enabled}})
    command = base + ["--source", str(source), "--override-data", overrides]
    managed = subprocess.check_output(command + ["managed", "--include", "files", "--path-style", "relative"], text=True)
    for name in ("dotfiles-download-check.service", "dotfiles-download-check.timer"):
        assert (f".config/systemd/user/{name}" in managed.splitlines()) == expected, managed

print("Downloads: init mirror choices, secret-free rendering, bounded probes and opt-in Linux timer passed")

with (root / "source/.chezmoiexternal.toml").open("w") as stream:
    good = root / "good"
    good.write_text("fallback-ok")
    stream.write('[".fallback-result"]\ntype="file"\nurl="file:///nonexistent-primary-fixture"\nurls=["file:///nonexistent-fallback-fixture", "' + good.as_uri() + '"]\n')
(root / "home").mkdir(exist_ok=True)
subprocess.run(base + ["--source", str(source), "apply", str(root / "home/.fallback-result")], check=True, capture_output=True)
assert (root / "home/.fallback-result").read_text() == "fallback-ok"
