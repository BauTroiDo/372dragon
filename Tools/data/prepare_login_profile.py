"""Apply the CY login data profile to an existing, private Build stage.

Copies the modern UTF-8 dictionary and offline server fixture, fixes the three
malformed ChatFrame background descriptors, and empties StrFilter rules.
Backups and hashes make every data change reviewable; no original client writes.
"""
import argparse
import datetime
import hashlib
import json
from pathlib import Path
import empty_strfilter

ROOT = Path(__file__).resolve().parents[2]


def checked(relative):
    relative = Path(relative)
    if relative.is_absolute() or '..' in relative.parts:
        raise ValueError('Use a path relative to CY-Source without traversal')
    path = ROOT / relative
    if not path.resolve().is_relative_to((ROOT / 'Build').resolve()):
        raise ValueError('Only private Build stages may be changed')
    for parent in (path, *path.parents):
        if parent.is_symlink() or parent.is_junction():
            raise ValueError('No junctions or symlinks')
        if parent == ROOT:
            break
    return path


def apply(stage_name):
    stage = checked(stage_name)
    if not (stage / 'Bin64/offline_stage.json').is_file():
        raise ValueError('Expected an existing private offline Game stage')
    chat = stage / 'Data/Interface/ChatFrame/ChatFrame.layout.xml'
    data = chat.read_bytes()
    old = b'Value="dir:CommonFrame set:Chat image:CommonEditBoxBK"'
    if data.count(old) == 3:
        for direction in (b'left', b'middle', b'right'):
            data = data.replace(old, b'Value="dir:' + direction + b' set:CommonFrame image:CommonEditBoxBK"', 1)
    elif any(data.count(b'Value="dir:' + d + b' set:CommonFrame image:CommonEditBoxBK"') != 1
             for d in (b'left', b'middle', b'right')):
        raise ValueError('Unexpected ChatFrame descriptors; inspect instead of guessing')
    updates = [
        (stage / 'Data/Config/StrDictionary.txt', (ROOT / 'Assets/Canonical/Data/ConfigFolder/StrDictionary.txt').read_bytes()),
        (stage / 'Patch/LoginServer.txt', (ROOT / 'Tests/ui/fixtures/login-server-utf8.txt').read_bytes()),
        (chat, data),
    ]
    # Validate every destination and required directory before any write.
    for path, _ in updates:
        checked(path.relative_to(ROOT))
        if not path.parent.is_dir():
            raise ValueError('Missing stage data directory')
    checked((stage / 'Data/Config/StrFilter.txt').relative_to(ROOT))
    out = checked(Path('Build/Logs/login-data') / datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f'))
    out.mkdir(parents=True, exist_ok=False)
    records = []
    for index, (path, after) in enumerate(updates):
        before = path.read_bytes() if path.exists() else None
        if before is not None:
            (out / (str(index) + '-' + path.name + '.before')).write_bytes(before)
        path.write_bytes(after)
        if path.read_bytes() != after:
            raise RuntimeError('Write verification failed')
        records.append({'path': str(path.relative_to(ROOT)),
                        'sha256_before': hashlib.sha256(before).hexdigest() if before is not None else None,
                        'sha256_after': hashlib.sha256(after).hexdigest()})
    empty_strfilter.apply(str((stage / 'Data/Config/StrFilter.txt').relative_to(ROOT)))
    report = {'stage': str(stage.relative_to(ROOT)), 'files': records,
              'encoding': 'UTF-8 two-column dictionary; Noto fonts supplied by stage',
              'endpoint': 'offline fixture 127.0.0.1:14400', 'filter_rules': 0,
              'chat_fix': 'three slots left/middle/right, CommonFrame/CommonEditBoxBK'}
    (out / 'result.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    print(json.dumps(report))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('stage')
    apply(parser.parse_args().stage)
