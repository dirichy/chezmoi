#!/usr/bin/env python3
"""Offline Tiger generation, cache and Git external ordering checks."""

from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import json
import runpy
import shutil
import subprocess
import sys
import tempfile
import tomllib
from unittest.mock import patch

repo = Path(sys.argv[1])
helper = repo / "ignore/bin/rime-tiger-dictionary"
module = runpy.run_path(str(helper))
build = module["common_dictionary"]
cached = module["cached_dictionary"]
short_table = module["short_code_table"]
data = b'name: tiger\nversion: "1"\nsort: by_weight\n...\n# fixture\n'
data += "的\tu\t1000\n一\tfi\t0\n龘\ttt\t254\n一\tf\t255\n".encode()
expected = build(data, "tiger_common")
assert build(data.replace(b"\n", b"\r\n"), "tiger_common") == expected
assert "一\tfi\t0" in expected.decode() and "龘\t" not in expected.decode()
# Short recommendations use the common set, by_weight first candidates and shortest codes.
short_data = data + "次\tf\t256\n次\tab\t300\n一\tz\t255\n的\tuuu\t1000\n词语\taa\t500\n".encode()
short_expected = short_table(build(short_data, "tiger_common")).decode()
assert '["次"] = "f"' in short_expected and '["一"] = "z"' in short_expected
assert '["的"] = "u"' in short_expected
assert '"龘"' not in short_expected and '"词语"' not in short_expected
assert '["一"] = "fi"' not in short_expected
tie_data = b"name: tiger\nsort: by_weight\n...\n" + "甲\taa\t255\n乙\taa\t255\n".encode()
assert '["甲"] = "aa"' in short_table(tie_data).decode()
assert '"乙"' not in short_table(tie_data).decode()

with tempfile.TemporaryDirectory(prefix="rime-tiger-test-", dir=sys.argv[2]) as temporary:
    root = Path(temporary)
    cache = root / "unit-cache"
    assert cached(data, cache) == expected
    with patch.dict(cached.__globals__, {"common_dictionary": lambda *args: (_ for _ in ()).throw(
            AssertionError("cache hit regenerated dictionary"))}):
        assert cached(data, cache) == expected
    next(cache.glob("*.cache")).write_bytes(b"corrupted")
    assert cached(data, cache) == expected
    changed = data.replace(b"254", b"255")
    assert "龘\t" in cached(changed, cache).decode()
    revised_helper = root / "changed-helper"
    revised_helper.write_bytes(helper.read_bytes() + b"\n# script version changed\n")
    assert runpy.run_path(str(revised_helper))["cached_dictionary"](data, cache) == expected
    assert len(list(cache.glob("*.cache"))) == 3
    assert cached(short_data, cache, "simp").decode() == short_expected
    with patch.dict(cached.__globals__, {"short_code_table": lambda *args: (_ for _ in ()).throw(
            AssertionError("cache hit regenerated shorthand table"))}):
        assert cached(short_data, cache, "simp").decode() == short_expected
    next(cache.glob("*.simp.cache")).write_bytes(b"corrupted")
    assert cached(short_data, cache, "simp").decode() == short_expected
    upstream = root / "upstream"
    upstream.mkdir()
    (upstream / "tiger.dict.yaml").write_bytes(data)
    (upstream / "opencc").mkdir()
    (upstream / "opencc/emoji.json").write_text("{}")
    (upstream / "opencc/emoji.txt").write_text("笑\t笑 😀 😄 😀\n虎\t虎 🐯\n")
    (upstream / "opencc/hu_cf.json").write_text("{}")
    (upstream / "lua").mkdir()
    (upstream / "lua/exe.lua").write_text("return function() return 2 end\n")
    (upstream / "rime.lua").write_text("do not deploy")
    def git(*args):
        return subprocess.run(["git", *args], capture_output=True, check=True)
    git("init", "-b", "master", str(upstream))
    def commit(message):
        git("-C", str(upstream), "add", ".")
        git("-C", str(upstream), "-c", "user.name=Test", "-c", "user.email=test@example.invalid",
            "commit", "-m", message)
    commit("initial fixture")
    ice = root / "ice-upstream"
    ice.mkdir()
    for directory in ("cn_dicts", "en_dicts", "opencc"):
        (ice / directory).mkdir()
    (ice / "rime_ice.dict.yaml").write_text('name: rime_ice\nversion: "1"\nimport_tables:\n  - cn_dicts/base\n...\n')
    (ice / "cn_dicts/base.dict.yaml").write_text("name: base\n...\n测试\tce shi\t100\n")
    (ice / "en_dicts/cn_en.txt").write_text("测试A\tceshia\n")
    (ice / "opencc/emoji.txt").write_text("笑\t笑 😄 😊\n雾\t雾 🌫️\n")
    for name in ("radical_pinyin.schema.yaml", "radical_pinyin.dict.yaml"):
        shutil.copy(repo / "ignore/tests/fixtures/rime-ice" / name, ice / name)
    (ice / "opencc/others.txt").write_text("一月\t一月 January\n")
    git("init", "-b", "main", str(ice))
    def commit_ice(message):
        git("-C", str(ice), "add", ".")
        git("-C", str(ice), "-c", "user.name=Test", "-c", "user.email=test@example.invalid",
            "commit", "-m", message)
    commit_ice("initial Ice fixture")
    # Concurrent renderers must produce complete identical artifacts.
    def generate(_):
        return subprocess.run(["python3", str(helper), str(upstream / "tiger.dict.yaml"),
                               str(root / "concurrent-cache")], capture_output=True, check=True).stdout
    with ThreadPoolExecutor(max_workers=2) as pool:
        assert list(pool.map(generate, range(2))) == [expected, expected]
    assert not list((root / "concurrent-cache").glob(".tmp-*"))

    source = root / "source"
    target = source / "dot_local/share/fcitx5/rime"
    target.mkdir(parents=True)
    (source / "ignore/bin").mkdir(parents=True)
    shutil.copy(helper, source / "ignore/bin/rime-tiger-dictionary")
    shutil.copy(repo / "ignore/bin/rime-merge-emoji", source / "ignore/bin/rime-merge-emoji")
    shutil.copytree(repo / "dot_local/share/fcitx5/rime/shared_emoji", target / "shared_emoji")
    shutil.copytree(repo / "dot_local/share/fcitx5/rime/shared_opencc", target / "shared_opencc")
    for name in ["tiger.dict.yaml.tmpl", "tiger_common.dict.yaml.tmpl",
                 "tiger_common.extended.dict.yaml.tmpl", "tiger.extended.dict.yaml",
                 "symlink_opencc.tmpl", "rime_ice.dict.yaml.tmpl", "symlink_cn_dicts.tmpl",
                 "symlink_en_dicts.tmpl", "rime_ice.schema.yaml.tmpl",
                 "symlink_radical_pinyin.dict.yaml.tmpl", "symlink_radical_pinyin.schema.yaml.tmpl",
                 "radical_pinyin_flypy.schema.yaml"]:
        shutil.copy(repo / "dot_local/share/fcitx5/rime" / name, target / name)
    (target / "lua").mkdir()
    (target / "lua/tiger").mkdir()
    shutil.copy(repo / "dot_local/share/fcitx5/rime/lua/tiger/simp_table.lua.tmpl", target / "lua/tiger")
    (source / ".chezmoiignore").write_text("ignore\n")
    (source / ".chezmoiexternal.toml").write_text("")
    (source / ".chezmoitemplates").mkdir()
    for name in ("preferChezmoiDownloads", "zsh-plugin-repos"):
        shutil.copy(repo / ".chezmoitemplates" / name, source / ".chezmoitemplates" / name)
    config = root / "config.toml"
    config.write_bytes((repo / "ignore/tests/fixtures/linux-desktop.toml").read_bytes())
    (root / "home").mkdir()
    command = ["chezmoi", "--source", str(source), "--destination", str(root / "home"),
               "--config", str(config), "--cache", str(root / "cache"),
               "--persistent-state", str(root / "state.boltdb"), "--no-tty"]
    external = (repo / ".chezmoiexternal.toml").read_text()
    def render_external():
        return subprocess.run(command + ["execute-template"], input=external,
                              text=True, capture_output=True, check=True).stdout
    rendered = render_external()
    entry = tomllib.loads(rendered)[".cache/rime-tiger/upstream"]
    ice_entry = tomllib.loads(rendered)[".cache/rime-ice/upstream"]
    assert entry["type"] == "git-repo" and entry["pull"]["args"] == ["--ff-only"]
    assert ice_entry["type"] == "git-repo" and ice_entry["pull"]["args"] == ["--ff-only"]
    assert ice_entry["refreshPeriod"] == "24h"
    config.write_bytes((repo / "ignore/tests/fixtures/macos-desktop.toml").read_bytes())
    assert all(key in tomllib.loads(render_external()) for key in (
        ".cache/rime-tiger/upstream", ".cache/rime-ice/upstream"))
    config.write_bytes((repo / "ignore/tests/fixtures/linux-headless.toml").read_bytes())
    assert ".cache/rime-tiger/upstream" not in tomllib.loads(render_external())
    assert ".cache/rime-ice/upstream" not in tomllib.loads(render_external())
    config.write_bytes((repo / "ignore/tests/fixtures/linux-desktop.toml").read_bytes())
    # Only install the Rime externals under test, never unrelated downloads.
    fixture_external = []
    for name, settings in ((".cache/rime-tiger/upstream", entry),
                           (".cache/rime-ice/upstream", ice_entry)):
        fixture_external.append(f'[{json.dumps(name)}]')
        for key, value in settings.items():
            if isinstance(value, dict):
                for nested_key, nested_value in value.items():
                    fixture_external.append(f'{key}.{nested_key} = {json.dumps(nested_value)}')
            else:
                fixture_external.append(f'{key} = {json.dumps(value)}')
    (source / ".chezmoiexternal.toml").write_text("\n".join(fixture_external).replace(
        entry["url"], upstream.as_uri()).replace(ice_entry["url"], ice.as_uri()))
    def apply(*paths):
        # Deliberately isolated destination, state, source and local Git remote.
        subprocess.run(command + ["apply", "--force", "--refresh-externals=always", *paths], capture_output=True, check=True)
    apply()
    destination = root / "home/.local/share/fcitx5/rime"
    assert (destination / "tiger.dict.yaml").read_bytes() == data
    assert (destination / "tiger_common.dict.yaml").read_bytes() == expected
    short_path = destination / "lua/tiger/simp_table.lua"
    assert short_path.read_bytes() == short_table(expected)
    if shutil.which("lua"):
        subprocess.run(["lua", "-", str(short_path)],
                       input='local t=dofile(arg[1]); assert(t["的"]=="u" and t["一"]=="f" and not t["龘"])',
                       text=True, capture_output=True, check=True)
    # The shorthand template also renders before any common dictionary is installed.
    (destination / "tiger_common.dict.yaml").unlink()
    preview = subprocess.run(command + ["cat", str(short_path)], capture_output=True, check=True).stdout
    assert preview == short_table(expected)
    assert (destination / "opencc/hu_cf.json").read_text() == "{}"
    assert not (destination / "opencc/s2t.json").exists()  # Use installed OpenCC standard data.
    assert not (destination / "rime.lua").exists()
    assert (destination / "rime_ice.dict.yaml").read_bytes() == (ice / "rime_ice.dict.yaml").read_bytes()
    assert (destination / "cn_dicts/base.dict.yaml").read_text().endswith("测试\tce shi\t100\n")
    assert (destination / "en_dicts/cn_en.txt").is_file()
    assert not (destination / "lua/exe.lua").exists()
    merged = (destination / "shared_emoji/emoji.txt").read_text()
    assert "笑\t笑 😄 😊 😀\n" in merged
    assert "虎\t虎 🐯\n" in merged and "雾\t雾 🌫️\n" in merged
    assert "January" not in merged
    assert str(destination / "shared_emoji/emoji.json") in (destination / "rime_ice.schema.yaml").read_text()
    for name in ("radical_pinyin.dict.yaml", "radical_pinyin.schema.yaml"):
        assert (destination / name).read_bytes() == (ice / name).read_bytes()
    custom = (destination / "tiger_common.extended.dict.yaml").read_text()
    assert "name: tiger_common.extended" in custom and "  - tiger_common\n" in custom, repr(custom[:500])
    assert "爸爸" in custom and "；\t;" in custom
    # A single apply must use the newly pulled data, not the previous checkout.
    (upstream / "tiger.dict.yaml").write_bytes(changed)
    commit("admit another character")
    (ice / "cn_dicts/base.dict.yaml").write_text("name: base\n...\n更新\tgeng xin\t100\n")
    (ice / "opencc/emoji.txt").write_text("笑\t笑 😄 😊\n新增\t新增 🆕\n")
    commit_ice("update Ice data")
    apply()
    assert (destination / "tiger.dict.yaml").read_bytes() == changed
    assert "龘\t" in (destination / "tiger_common.dict.yaml").read_text()
    assert '["龘"] = "tt"' in short_path.read_text()
    assert "更新\tgeng xin" in (destination / "cn_dicts/base.dict.yaml").read_text()
    assert "新增\t新增 🆕" in (destination / "shared_emoji/emoji.txt").read_text()
    artifacts = list((root / "cache/rime-tiger").glob("*.cache"))
    mtimes = {p.name: p.stat().st_mtime_ns for p in artifacts}
    subprocess.run(command + ["diff"], capture_output=True, check=True)
    assert mtimes == {p.name: p.stat().st_mtime_ns for p in artifacts}
    # Editing the local extension is rendered independently of the common dictionary cache.
    custom_source = target / "tiger.extended.dict.yaml"
    custom_source.write_bytes(custom_source.read_bytes() + "\n龘\tzz\t1\n".encode())
    apply()
    assert "龘\tzz\t1" in (destination / "tiger_common.extended.dict.yaml").read_text()
    assert mtimes == {p.name: p.stat().st_mtime_ns for p in artifacts}

print("Rime: Tiger/Ice Git updates, local schemas, common dictionary cache and shared Emoji passed")
