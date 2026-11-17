#!/usr/bin/env python3
"""Offline input checks using librime and its Lua plugin when available on Linux."""

from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time

repo, source, temporary = map(Path, sys.argv[1:])
if sys.platform != "linux" or not shutil.which("cc") or not shutil.which("pkg-config"):
    print("# skip - native Rime input checks require Linux, cc and pkg-config")
    sys.exit(0)
flags = subprocess.run(["pkg-config", "--cflags", "--libs", "rime"], capture_output=True, text=True)
if flags.returncode:
    print("# skip - native Rime input checks require librime development files")
    sys.exit(0)
libdir = subprocess.check_output(["pkg-config", "--variable=libdir", "rime"], text=True).strip()
plugin = Path(libdir) / "rime-plugins/librime-lua.so"
if not plugin.is_file():
    print("# skip - native Rime input checks require librime-lua")
    sys.exit(0)

with tempfile.TemporaryDirectory(prefix="radical-", dir=temporary) as directory:
    root = Path(directory)
    home = root / "home"
    home.mkdir()
    user = home / ".local/share/fcitx5/rime"
    user.mkdir(parents=True)
    # All dictionaries are tiny checked-in fixtures; no upstream downloads or real state.
    upstream = home / ".cache/rime-ice/upstream"
    fixture = repo / "ignore/tests/fixtures/rime-ice"
    shutil.copytree(fixture, upstream)
    shutil.copytree(repo / "ignore/tests/fixtures/rime-tiger", home / ".cache/rime-tiger/upstream")
    shutil.copytree(source / "dot_local/share/fcitx5/rime/lua", user / "lua")
    for path in (user / "lua").rglob("executable_*.lua"):
        path.rename(path.with_name(path.name.removeprefix("executable_")))
    command = ["chezmoi", "--source", str(source), "--destination", str(home),
               "--config", str(repo / "ignore/tests/fixtures/linux-desktop.toml"),
               "--cache", str(root / "cache"), "--persistent-state", str(root / "state"),
               "--refresh-externals=never", "--no-tty", "cat"]
    for name in ("rime_ice.schema.yaml", "rime_ice_full.schema.yaml", "radical_pinyin_flypy.schema.yaml",
                 "default.yaml", "symbols.yaml", "custom_phrase.txt",
                 "tiger.schema.yaml", "tiger_full.schema.yaml", "tiger.custom.yaml", "tiger_full.custom.yaml",
                 "tiger.dict.yaml", "tiger_common.dict.yaml", "tiger.extended.dict.yaml", "tiger_common.extended.dict.yaml"):
        (user / name).write_bytes(subprocess.check_output(command + [str(user / name)]))
    (user / "lua/tiger/simp_table.lua").write_bytes(
        subprocess.check_output(command + [str(user / "lua/tiger/simp_table.lua")]))
    for name in ("rime_ice.dict.yaml", "radical_pinyin.schema.yaml", "radical_pinyin.dict.yaml"):
        shutil.copy(upstream / name, user / name)
    # A harmless empty Emoji map keeps the enabled simplifier fully local.
    (user / "shared_emoji").mkdir()
    (user / "shared_emoji/emoji.json").write_text(
        '{"name":"fixture","segmentation":{"type":"mmseg",'
        '"dict":{"type":"text","file":"emoji.txt"}},'
        '"conversion_chain":[{"dict":{"type":"text","file":"emoji.txt"}}]}')
    (user / "shared_emoji/emoji.txt").write_text("笑\t笑 😄\n")
    binary = root / "input-check"
    subprocess.run(["cc", str(fixture / "input-check.c"), *flags.stdout.split(), "-ldl", "-o", str(binary)],
                   check=True, capture_output=True)
    cases = [
        ("rime_ice_full", "`riyue", "明"),
        ("rime_ice", "`riyt", "明"),
        ("rime_ice_full", "`mumu", "林"),
        ("rime_ice_full", "shi", "是"),
        ("rime_ice_full", "shi`mu", "柿"),
        ("rime_ice", "ui`mu", "柿"),
        ("rime_ice_full", ";", "："),
        ("rime_ice_full", "/d", time.strftime("%Y-%m-%d")),
        ("tiger", "/d", time.strftime("%Y-%m-%d")),
        ("tiger", "/t", "format:time"),
        ("rime_ice", "/time1", "format:time"),
        ("tiger", "/dt", "prefix:" + time.strftime("%Y-%m-%d ")),
        ("rime_ice", "/ts", "format:timestamp"),
        ("rime_ice_full", "/dt", "prefix:" + time.strftime("%Y-%m-%d ")),
        ("tiger_full", "/de", "prefix:" + str(int(time.strftime("%d"))) + " "),
        ("rime_ice", "/dc", "prefix:二"),
        ("tiger", "/dm", time.strftime("%B")),
        ("rime_ice_full", "/dw", "prefix:周"),
        ("tiger", "/", "箭头"),
        ("rime_ice", "/", "箭头"),
        ("tiger", "/a", "←"),
        ("rime_ice", "/c", "￥"),
        ("tiger_full", "/grk1", "α"),
        ("rime_ice_full", "/greek11", "commit:α"),
        ("tiger", "/lj", "平假名"),
        ("rime_ice", "/m", "数学符号"),
        ("rime_ice", "/ljk", "ア"),
        ("tiger", "/l", "希腊字母"),
        ("tiger", "/e", "表情"),
        ("tiger", "/ ", "←"),
        ("tiger", "/v", "对号"),
        ("tiger", "/a1", "commit:←"),
        ("tiger", "/vx", "❌"),
        ("tiger", "/a=-", "←"),
        ("rime_ice", "/a=-", "←"),
        ("tiger_full", "/jt=-", "←"),
        ("rime_ice_full", "/a-", "←"),
        ("tiger", "=1-2", "-1"),
        ("rime_ice", "cC1-2", "-1"),
        ("tiger", "=-1", "-1"),
        ("rime_ice_full", "cC-1", "-1"),
        ("rime_ice", "/m\t1", "星形"),
        ("rime_ice", "/a\b", "箭头"),
        ("rime_ice_full", "/ljh", "あ"),
        ("rime_ice", "/a", "←"),
        ("tiger_full", "/jt", "←"),
        ("rime_ice_full", "/sx", "≤"),
        ("tiger", "/b", "("),
        ("tiger", "/sz", "⚀"),
        ("tiger_full", "/bq", "😀"),
        ("rime_ice", ";s", "虎码·常用"),
        ("rime_ice", ";s3", "schema:rime_ice_full"),
        ("tiger", "qqqq", "qqqq"),
        ("tiger", "qqqq ", "commit:"),
        ("tiger", "qqqq1", "commit:qqqq"),
        ("tiger", "abcdqqqq ", "commit:来"),
        ("tiger", "qqqqefgh ", "commit:如"),
        ("tiger", "qqqq,", "commit:"),
        ("tiger", "abcd,", "commit:来，"),
        ("tiger", "abcdqqqq,", "commit:来，"),
        ("tiger", "lmno ", "commit:Rime"),
        ("tiger", "lmnoqqqq ", "commit:Rime"),
        ("tiger_full", "qqqq ", "commit:"),
        ("tiger", "z", "组词"),
        ("tiger", "aaab2z", "second:乙"),
        ("tiger", "abcdz", "second:来"),
        ("tiger", "abcdefghz", "second:如"),
        ("tiger", "aaab2abcdz", "second:来"),
        ("tiger", "aaab2z;", "commit:乙乙"),
        ("tiger", "aaab2z2", "commit:乙乙"),
        ("tiger", "abcdz2", "commit:来来"),
        ("tiger", "abcdefghz2", "commit:来如如"),
        ("tiger", "z1z2", "commit:组词词"),
        ("tiger", "abcd z;", "commit:来来"),
        ("tiger", "abcdz;", "commit:来来"),
        ("tiger", "abcdefghz;", "commit:来如如"),
        ("tiger", "aaab2abcdz;", "commit:乙来来"),
        ("tiger", "abcdz;z;", "commit:来来来"),
        ("tiger", "ijklz;", "commit:𠮷𠮷"),
        ("tiger_full", "aaab2z", "second:乙"),
        ("tiger_full", "abcdefghz", "second:如"),
        ("tiger_full", "abcdefghz2", "commit:来如如"),
        ("tiger_full", "aaab2z;", "commit:乙乙"),
        ("tiger_full", "abcdefghz;", "commit:来如如"),
    ]
    # Compile dependencies and exercise the actual processor/segmentor/translator/filter chain.
    for schema, code, expected in cases:
        result = subprocess.run([str(binary), str(user), schema, code, expected,
                                 str(plugin), str(user)], capture_output=True, text=True)
        if result.returncode:
            raise AssertionError(result.stdout + result.stderr)
        print(result.stdout.strip())
    print("Rime native input: radical lookup, auxiliary filtering, shared commands and Tiger native/pending repeat passed")
