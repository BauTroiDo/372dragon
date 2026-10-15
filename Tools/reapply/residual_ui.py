"""Reapply CY UI fixes for optional event arguments and absent promotion data."""
from pathlib import Path
import argparse
import datetime
import shutil

ROOT = Path(__file__).resolve().parents[2]
UI = ROOT / 'Assets/CanonicalCY/Data/InterfaceFolder'


def fix(name, text):
    if name == 'PetBankMain':
        old = 'if 0<=nSelectArg0  and nSelectArg0 < nPetCount then'
        new = 'if nSelectArg0 ~= nil and 0<=nSelectArg0 and nSelectArg0 < nPetCount then'
        if new not in text:
            assert text.count(old) == 1
            text = text.replace(old, new)
    else:
        # Both values are optional until event metadata is available. Keep the
        # existing active-event checks and real dates, never fabricate a bonus.
        old = 'if(StartTime < 0 or EndTime < 0 or '
        new = 'if(StartTime == nil or EndTime == nil or StartTime < 0 or EndTime < 0 or '
        text = text.replace(old, new)
        assert new in text
    return text


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    changed = []
    for name in ('PetBankMain', 'Xiulian', 'XiulianStudy'):
        path = UI / name / (name + '.lua')
        raw = path.read_bytes()
        updated = fix(name, raw.decode('utf-8')).encode('utf-8')
        assert fix(name, updated.decode('utf-8')).encode('utf-8') == updated
        print(name, 'CHANGE' if updated != raw else 'unchanged')
        if updated != raw:
            changed.append((path, updated))
    if not args.apply or not changed:
        return
    backup = ROOT / 'Build/backups/residual-ui' / datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
    backup.mkdir(parents=True, exist_ok=False)
    for path, raw in changed:
        shutil.copy2(path, backup / path.name)
        path.write_bytes(raw)
    print('backup', backup)


if __name__ == '__main__':
    main()
