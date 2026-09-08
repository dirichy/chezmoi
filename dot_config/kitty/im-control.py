import subprocess
from shutil import which


IS_ACTIVE_CMD = ("sh", "-c", 'test "$(fcitx5-remote)" = 2')
TEMP_ASCII_CMD = ("fcitx5-remote", "-c")
RESTORE_CMD = ("fcitx5-remote", "-o")

SAVED_STATES: dict[int, bool] = {}


def command_exists(cmd: tuple[str, ...]) -> bool:
    return bool(cmd) and which(cmd[0]) is not None


def run_command(cmd: tuple[str, ...]) -> None:
    if not command_exists(cmd):
        return

    try:
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

    try:
        result = subprocess.run(
            IS_ACTIVE_CMD,
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=0.5,
        )
    except (OSError, subprocess.SubprocessError):
        return None

    return result.returncode == 0


def temp_ascii(window) -> None:
    active = is_active()
    if active is None:
        return

    SAVED_STATES.setdefault(window.id, active)

    run_command(TEMP_ASCII_CMD)


def restore(window) -> None:
    active = SAVED_STATES.pop(window.id, None)
    if active is None:
        return

    if active:
        run_command(RESTORE_CMD)


def handle_im(value: str, window) -> None:
    if value == "temp_ascii":
        temp_ascii(window)
    elif value == "restore":
        restore(window)


def on_set_user_var(boss, window, data):
    if data.get("key") == "im" and data.get("value") is not None:
        handle_im(data["value"], window)
