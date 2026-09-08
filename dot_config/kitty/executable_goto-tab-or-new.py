#!/usr/bin/env python3
from kitty.boss import Boss
from kitty.window import CwdRequest
from kittens.tui.handler import result_handler


def main(args: list[str]) -> None:
    pass


@result_handler(no_ui=True)
def handle_result(args: list[str], answer: str, target_window_id: int, boss: Boss) -> None:
    try:
        target = int(args[1])
    except (IndexError, ValueError):
        return

    if target < 1:
        return

    window = boss.window_id_map.get(target_window_id)
    if window is None:
        return

    tab = window.tabref()
    tab_manager = tab.tab_manager_ref() if tab is not None else None
    if tab_manager is None:
        return

    if len(tuple(tab_manager.tabs_to_be_shown_in_tab_bar)) < target:
        tab_manager.new_tab(cwd_from=CwdRequest(window))
        return

    tab_manager.goto_tab(target - 1)
