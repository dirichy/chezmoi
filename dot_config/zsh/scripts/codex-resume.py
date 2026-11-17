#!/usr/bin/env python3
"""Local, account-independent session index and frecency picker for the zsh wrapper."""

import json
import math
import os
from pathlib import Path
import shlex
import sqlite3
import subprocess
import sys
import tempfile
import time
import uuid


def clean(value):
    # Session text must not inject terminal escapes or fzf columns/actions.
    return " ".join("".join(c for c in str(value or "") if c.isprintable() or c.isspace()).split())


def session_id(value):
    try:
        return str(uuid.UUID(str(value)))
    except ValueError:
        return None


def open_index(home):
    home.mkdir(parents=True, exist_ok=True)
    db = sqlite3.connect(home / "wrapper-resume.sqlite3", timeout=10)
    db.execute("""CREATE TABLE IF NOT EXISTS sessions (
        id TEXT PRIMARY KEY, cwd TEXT, title TEXT, updated REAL,
        visits INTEGER NOT NULL DEFAULT 0, last_used REAL NOT NULL DEFAULT 0,
        path TEXT, mtime INTEGER)
    """)
    return db


def put(db, sid, cwd, title, updated, path=None, mtime=None):
    sid = session_id(sid)
    if not sid or not cwd:
        return
    db.execute("""INSERT INTO sessions (id,cwd,title,updated,path,mtime)
        VALUES (?,?,?,?,?,?) ON CONFLICT(id) DO UPDATE SET
        cwd=excluded.cwd,title=excluded.title,updated=excluded.updated,
        path=excluded.path,mtime=excluded.mtime""",
        (sid, str(Path(cwd).resolve()), title, updated, path, mtime))


def session_names(home):
    names = {}
    try:
        with (home / "session_index.jsonl").open() as stream:
            for line in stream:
                try:
                    entry = json.loads(line)
                except ValueError:
                    continue
                if not isinstance(entry, dict):
                    continue
                sid = session_id(entry.get("id"))
                name = entry.get("thread_name")
                if sid and isinstance(name, str) and name.strip():
                    # Codex appends renames; the last entry for a thread wins.
                    names[sid] = name.strip()
    except (OSError, UnicodeError):
        pass
    return names


def sync_database(db, home):
    # Read every account. Never use creator_account_id as a filter or modify Codex state.
    names = session_names(home)
    sources = sorted(home.glob("state_*.sqlite"),
                     key=lambda p: int(p.stem.split("_")[-1]) if p.stem.split("_")[-1].isdigit() else 0,
                     reverse=True)
    for source in sources:
        try:
            with sqlite3.connect(source.as_uri() + "?mode=ro", uri=True, timeout=2) as native:
                columns = {row[1] for row in native.execute("PRAGMA table_info(threads)")}
                name_column = "name" if "name" in columns else "NULL"
                rows = native.execute(f"""SELECT id,cwd,title,updated_at,rollout_path,{name_column}
                    FROM threads WHERE archived=0 AND source IN ('cli','vscode')""").fetchall()
            seen = set()
            for sid, cwd, title, updated, path, name in rows:
                if session_id(sid):
                    seen.add(session_id(sid))
                    display_title = (name or "").strip() or names.get(session_id(sid)) or title
                    put(db, sid, cwd, display_title, updated, path)
            for (sid,) in db.execute("SELECT id FROM sessions").fetchall():
                if sid not in seen:
                    db.execute("DELETE FROM sessions WHERE id=?", (sid,))
            return True
        except (sqlite3.Error, OSError):
            continue
    return False


def sync_rollouts(db, home):
    names = session_names(home)
    seen = set()
    for path in (home / "sessions").glob("**/*.jsonl"):
        try:
            stat = path.stat()
            seen.add(str(path))
            if db.execute("SELECT 1 FROM sessions WHERE path=? AND mtime=?",
                          (str(path), stat.st_mtime_ns)).fetchone():
                continue
            meta, title = None, ""
            # A bounded read avoids scanning entire long conversations on each launch.
            with path.open() as stream:
                for line in stream.read(262144).splitlines():
                    try:
                        item = json.loads(line)
                    except ValueError:
                        continue
                    payload = item.get("payload", {})
                    if item.get("type") == "session_meta":
                        meta = payload
                    if item.get("type") == "event_msg" and payload.get("type") == "user_message":
                        title = payload.get("message", "")
                        break
            if meta and meta.get("source", "cli") in ("cli", "vscode"):
                put(db, meta.get("id") or meta.get("session_id"), meta.get("cwd"),
                    title or "Untitled session", stat.st_mtime, str(path), stat.st_mtime_ns)
        except (OSError, UnicodeError):
            continue
    for sid, path in db.execute("SELECT id,path FROM sessions").fetchall():
        if path not in seen:
            db.execute("DELETE FROM sessions WHERE id=?", (sid,))
        elif sid in names:
            # Renaming does not necessarily change a rollout's mtime.
            db.execute("UPDATE sessions SET title=? WHERE id=?", (names[sid], sid))


def ranked(db, cwd, now):
    rows = db.execute("SELECT id,cwd,title,updated,visits,last_used FROM sessions").fetchall()

    def rank(row):
        _, directory, _, updated, visits, last_used = row
        age_hours = max(0, now - max(updated or 0, last_used)) / 3600
        weight = 4 if age_hours < 1 else 2 if age_hours < 24 else 0.5 if age_hours < 168 else 0.25
        return (directory == cwd, (1 + math.log1p(visits)) * weight,
                max(updated or 0, last_used))

    return sorted(rows, key=rank, reverse=True)


def relative_age(timestamp, now):
    if not timestamp:
        return ""
    age = max(0, now - timestamp)
    if age >= 365 * 86400:
        return ""
    for seconds, unit in ((604800, "w"), (86400, "d"), (3600, "h"), (60, "m")):
        if age >= seconds or unit == "m":
            return f"{int(age // seconds)}{unit}"


def line_for(row, cwd, now, show_directory=True):
    sid, directory, title, updated, visits, last_used = row
    age = relative_age(max(updated or 0, last_used), now)
    location = f"{'*' if directory == cwd else ' '} {clean(directory)}  " if show_directory else ""
    return f"{sid}\t{age:>3}  {visits:3d}x  {location}{clean(title)[:240]}\n"


def main():
    os.umask(0o077)
    home = Path(os.environ.get("CODEX_HOME", str(Path.home() / ".codex"))).resolve()
    cwd = str(Path.cwd().resolve())
    with open_index(home) as db:
        if not sync_database(db, home):
            sync_rollouts(db, home)
        db.commit()
        now = time.time()
        rows = ranked(db, cwd, now)
        by_id = {row[0]: row for row in rows}
        with tempfile.TemporaryDirectory(prefix="codex-resume-") as temporary:
            all_file = Path(temporary) / "all"
            cwd_file = Path(temporary) / "cwd"
            all_file.write_text("".join(line_for(row, cwd, now) for row in rows))
            cwd_file.write_text("".join(line_for(row, cwd, now, show_directory=False)
                                        for row in rows if row[1] == cwd))
            show_all = sys.argv[1:] == ["ra"]
            selected_file = all_file if show_all else cwd_file
            common_header = ("Enter: resume | C-d: current directory | C-a: all directories\n"
                             "All accounts · age: m/h/d/w · x: resume count · *: current directory")
            normal_header = "[NORMAL] j/k: move | i: search | q/Esc: cancel\n" + common_header
            insert_header = "[INSERT] type to search | Esc: normal | C-c: cancel\n" + common_header
            normal_action = f"hide-input+rebind(j,k,i,q)+change-header({normal_header})"
            # fzf reload runs through a shell: quote only our generated temporary paths.
            binds = (f"ctrl-d:reload(cat {shlex.quote(str(cwd_file))})+change-prompt(cwd> )+change-border-label(cwd),"
                     f"ctrl-a:reload(cat {shlex.quote(str(all_file))})+change-prompt(all> )+change-border-label(all),"
                     "start:unbind(j,k,i,q),j:down,k:up,q:abort,"
                     f"i:show-input+unbind(j,k,i,q)+change-header({insert_header}),"
                     'esc:transform:if test "$FZF_INPUT_STATE" = hidden; then echo abort; '
                     f"else printf %s {shlex.quote(normal_action)}; fi")
            env = dict(os.environ, FZF_DEFAULT_OPTS="", FZF_DEFAULT_OPTS_FILE="")
            with selected_file.open() as stream:
                result = subprocess.run([
                    "fzf", "--no-sort", "--delimiter=\t", "--with-nth=2..", "--layout=reverse",
                    "--height=80%", "--no-multi", "--border=rounded",
                    "--border-label", "all" if show_all else "cwd", "--bind", binds,
                    "--prompt", "all> " if show_all else "cwd> ",
                    "--header-first", "--header", insert_header,
                ], stdin=stream, stdout=subprocess.PIPE, text=True, env=env)
        if result.returncode in (1, 130):
            return 0
        if result.returncode:
            return result.returncode
        sid = result.stdout.split("\t", 1)[0].strip()
        if sid not in by_id:
            return 1
        directory = by_id[sid][1]
        if not Path(directory).is_dir():
            print(f"Session directory no longer exists: {clean(directory)}", file=sys.stderr)
            return 1
        # Count explicit selections, including sessions later interrupted with Ctrl-C.
        db.execute("UPDATE sessions SET visits=visits+1,last_used=? WHERE id=?", (time.time(), sid))
        db.commit()
    os.execvp("codex", ["codex", "resume", sid, "--cd", directory])


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, sqlite3.Error) as error:
        print(f"Codex session picker: {error}", file=sys.stderr)
        sys.exit(1)
