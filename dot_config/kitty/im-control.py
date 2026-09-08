import subprocess
import time
from datetime import datetime
from pathlib import Path
from shutil import which


IS_ACTIVE_CMD = ("fcitx5-remote",)
IS_ACTIVE_OUTPUT = "2"
TEMP_ASCII_CMD = ("fcitx5-remote", "-c")
RESTORE_CMD = ("fcitx5-remote", "-o")
STATE_SETTLE_SECONDS = 0.15
DEBUG = False
DEBUG_LOG = Path("/tmp/kitty-im-control.log")

PERM_ASCII = 0
TEMP_ASCII = 1
NONE_ASCII = 2

WINDOW_STATES: dict[int, int] = {}


def state_name(state: int | None) -> str:
    names = {
        PERM_ASCII: "perm_ascii",
        TEMP_ASCII: "temp_ascii",
        NONE_ASCII: "non_ascii",
    }
    return names.get(state, "unknown")


def debug(message: str) -> None:
    if not DEBUG:
        return

    try:
        with DEBUG_LOG.open("a", encoding="utf-8") as file:
            file.write(f"{datetime.now().isoformat(timespec='milliseconds')} {message}\n")
    except OSError:
        pass


def command_exists(cmd: tuple[str, ...]) -> bool:
    return bool(cmd) and which(cmd[0]) is not None


def run_command(cmd: tuple[str, ...]) -> None:
    if not command_exists(cmd):
        return

    try:
        debug(f"run_command cmd={cmd}")
        subprocess.run(
            cmd,
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=0.5,
        )
    except (OSError, subprocess.SubprocessError):
        pass


def is_active() -> bool | None:
    if not command_exists(IS_ACTIVE_CMD):
        return None

    if STATE_SETTLE_SECONDS > 0:
        time.sleep(STATE_SETTLE_SECONDS)

    try:
        result = subprocess.run(
            IS_ACTIVE_CMD,
            check=False,
            capture_output=True,
            text=True,
            timeout=0.5,
        )
    except (OSError, subprocess.SubprocessError) as err:
        debug(f"is_active error={err!r}")
        return None

    output = result.stdout.strip()
    active = result.returncode == 0 and output == IS_ACTIVE_OUTPUT
    debug(
        "is_active "
        f"active={active} returncode={result.returncode} "
        f"stdout={output!r} stderr={result.stderr.strip()!r}"
    )
    return active


def initialize_state(window) -> int | None:
    state = WINDOW_STATES.get(window.id)
    if state is not None:
        return state

    active = is_active()
    if active is None:
        return None

    state = NONE_ASCII if active else PERM_ASCII
    WINDOW_STATES[window.id] = state
    debug(f"initialize window={window.id} active={active} state={state_name(state)}")
    return WINDOW_STATES[window.id]


def if_user_changed_im(window) -> tuple[bool, bool] | None:
    active = is_active()
    if active is None:
        return None

    state = initialize_state(window)
    if state is None:
        return None

    state_if_user_not_change_im = state == NONE_ASCII
    changed = active != state_if_user_not_change_im
    debug(
        "sync-before "
        f"window={window.id} active={active} state={state_name(state)} "
        f"expected_active={state_if_user_not_change_im} changed={changed}"
    )
    return changed, active


def sync_user_change(window) -> None:
    user_changed = if_user_changed_im(window)
    if user_changed is None:
        return

    user_changed_im, user_change_state = user_changed
    if user_changed_im:
        WINDOW_STATES[window.id] = NONE_ASCII if user_change_state else PERM_ASCII

    debug(
        "sync-after "
        f"window={window.id} user_changed={user_changed_im} "
        f"user_active={user_change_state} state={state_name(WINDOW_STATES.get(window.id))}"
    )


def update(window, new_state: bool) -> None:
    if initialize_state(window) is None:
        return

    debug(f"update-start window={window.id} new_state={new_state} state={state_name(WINDOW_STATES.get(window.id))}")
    sync_user_change(window)

    if new_state:
        if WINDOW_STATES[window.id] == TEMP_ASCII:
            run_command(RESTORE_CMD)
            WINDOW_STATES[window.id] = NONE_ASCII
    else:
        if WINDOW_STATES[window.id] == NONE_ASCII:
            run_command(TEMP_ASCII_CMD)
            WINDOW_STATES[window.id] = TEMP_ASCII

    debug(f"update-end window={window.id} new_state={new_state} state={state_name(WINDOW_STATES.get(window.id))}")


def reset(window) -> None:
    WINDOW_STATES.pop(window.id, None)
    debug(f"reset window={window.id}")


def handle_im(value: str, window) -> None:
    if value == "temp_ascii":
        update(window, False)
    elif value == "restore":
        update(window, True)
    elif value == "reset":
        reset(window)


def on_set_user_var(boss, window, data):
    if data.get("key") == "im" and data.get("value") is not None:
        handle_im(data["value"], window)
