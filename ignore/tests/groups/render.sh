#!/usr/bin/env bash
# Sourced by run-group.sh; common.sh supplies fixture paths and helpers.
# shellcheck disable=SC2154
prepare_source
render_managed_templates desktop
render_managed_templates headless
render_managed_templates skip
pass 'all managed files and templates render for every fixture profile'

if [[ $fixture_os == linux ]]; then
    grep -Fq '"height": 32' \
        "$tmp_dir/rendered-desktop/.config/waybar/generated.jsonc" \
        || fail 'Waybar uses the mocked focused monitor dimensions'
    pass 'Waybar uses the mocked focused monitor dimensions'

    grep -Fq 'IPAddressAllow=192.168.50.0/24' \
        "$tmp_dir/rendered-desktop/.config/systemd/user/config-share.service" \
        || fail 'config sharing service restricts clients to configured CIDR'
    pass 'config sharing service restricts clients to configured CIDR'
else
    python3 - "$tmp_dir" <<'PYTHON'
import json
import plistlib
import sys
from pathlib import Path
root = Path(sys.argv[1])
for profile in ('desktop', 'headless', 'skip'):
    rendered = root / f'rendered-{profile}'
    for path in rendered.rglob('*.plist'):
        with path.open('rb') as stream:
            data = plistlib.load(stream)
        assert data['Label'] == path.stem, path
        assert data['ProgramArguments'], path
        assert data['RunAtLoad'] is True, path
rendered = root / 'rendered-desktop'
with (rendered / '.config/karabiner/karabiner.json').open() as stream:
    assert json.load(stream)['profiles']
with (rendered / 'Library/LaunchAgents/config-share.plist').open('rb') as stream:
    args = plistlib.load(stream)['ProgramArguments']
assert args[args.index('--allowed-cidr') + 1] == '192.168.50.0/24'
assert args[args.index('--port') + 1] == '18080'
assert args[0].endswith('/.local/libexec/config-share-server')
PYTHON
    pass 'macOS plists and Karabiner JSON validate'
fi
