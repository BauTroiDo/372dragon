"""Install verified Lua compatibility helpers in the private server, with backup.

No service operation or database access. A restart/reload is separately required.
"""
import argparse
import datetime
import hashlib
import json
from pathlib import Path

ROOT = Path('/home/ubuntu/cys-test-20260913')


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--confirm-root', required=True)
    ap.add_argument('--source', type=Path, required=True)
    args = ap.parse_args()
    if Path(args.confirm_root).resolve() != ROOT or ROOT.resolve() != ROOT:
        raise SystemExit('Only the private server root is allowed')
    src = args.source / 'GameServer/lualib/script_legacy_compat.lua'
    target = ROOT / 'GameServer/lualib/script_legacy_compat.lua'
    base = ROOT / 'GameServer/lualib/script_base.lua'
    before = base.read_bytes()
    hook = b'require("script_legacy_compat").install(script_base)'
    if hook in before:
        if target.is_file() and target.read_bytes() == src.read_bytes():
            print('Already installed, identical'); return
        raise SystemExit('Existing adapter differs; inspect before changing it')
    if target.exists() or before.count(b'return script_base') != 1:
        raise SystemExit('Unexpected source state')
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ')
    backup = ROOT / 'backups' / ('gameplay-compat-' + stamp)
    backup.mkdir(parents=True, exist_ok=False)
    (backup / 'script_base.lua').write_bytes(before)
    after = before.replace(b'return script_base', b'-- Converted gameplay uses these legacy spellings.\n' + hook + b'\nreturn script_base')
    target.write_bytes(src.read_bytes())
    base.write_bytes(after)
    manifest = {'backup': str(backup), 'files': [
        {'path': str(base.relative_to(ROOT)), 'before': hashlib.sha256(before).hexdigest(), 'after': hashlib.sha256(after).hexdigest()},
        {'path': str(target.relative_to(ROOT)), 'before': None, 'after': hashlib.sha256(target.read_bytes()).hexdigest()}]}
    (backup / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(json.dumps(manifest, indent=2))


if __name__ == '__main__':
    main()
