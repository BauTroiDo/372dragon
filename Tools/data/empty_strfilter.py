"""Keep the original DBC headers and remove StrFilter rules, with a byte backup.

The user requested an empty rule list for CY testing. A zero-byte file would
break the legacy DBC loader, so its two schema/header lines remain unchanged.
"""
import argparse
import datetime
import hashlib
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]


def apply(relative):
    path=ROOT/relative
    if not path.is_file() or path.name!='StrFilter.txt':
        raise ValueError('Expected existing StrFilter.txt')
    allowed=(ROOT/'Build', ROOT/'Assets/Canonical')
    actual=path.resolve()
    if not any(actual.is_relative_to(p.resolve()) for p in allowed):
        raise ValueError('Only CY Build or Canonical test data is allowed')
    cursor=path
    while cursor!=ROOT:
        if cursor.is_symlink() or cursor.is_junction():
            raise ValueError('Do not traverse a junction or symlink')
        cursor=cursor.parent
    data=path.read_bytes()
    lines=data.split(b'\n')
    if len(lines)<3 or b'INT' not in lines[0] or b'STRING' not in lines[0]:
        raise ValueError('Unrecognized DBC header')
    empty=b'\n'.join(lines[:2])+b'\n'
    before=sum(bool(line.strip()) and not line.startswith(b'#') for line in lines[2:])
    if data==empty:
        print('StrFilter already has zero rules: '+str(path.relative_to(ROOT)))
        return
    folder=ROOT/'Build/Logs/strfilter-empty'/datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f')
    folder.mkdir(parents=True,exist_ok=False)
    (folder/'StrFilter.before.bin').write_bytes(data)
    path.write_bytes(empty)
    assert path.read_bytes()==empty
    record={'file':str(path.relative_to(ROOT)),'rules_before':before,'rules_after':0,
            'sha256_before':hashlib.sha256(data).hexdigest(),
            'sha256_after':hashlib.sha256(empty).hexdigest(),
            'headers_preserved':True,'backup':str((folder/'StrFilter.before.bin').relative_to(ROOT)),
            'authorization':'User requested blank StrFilter for CY tests on 2026-09-13.'}
    (folder/'result.json').write_text(json.dumps(record,indent=2),encoding='utf-8')
    print(json.dumps(record))


if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('file',help='Path relative to CY-Source')
    apply(parser.parse_args().file)
