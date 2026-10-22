#!/usr/bin/env python3
"""Inventory DBC tables from checked-in client loaders and configured data directories.

Use build [--out-dir Registry/abi] or report TABLE.txt [TABLE.txt ...].
Record layout: INT/FLOAT/UINT/DWORD-time use four bytes; STRING uses one pointer.
"""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import re
import struct
import sys

ROOT = Path(__file__).resolve().parents[2]
SOURCES = {
    'CAN': ROOT / 'Assets/Canonical/Data/ConfigFolder',
    'REF': ROOT / 'Reference/tlbb085/085/Build/Client/Data/Config',
    'S2': ROOT.parent / 'Tools/DATA NEW/DataCY31-08-26/Config',
    'SRV': ROOT.parent / 'wsl/source-snapshot/ubuntu/configs',
}
GMDB = ROOT / 'Src/Client/WXClient/DBC/GMDataBase.cpp'
TYPE_NAMES = ('INT', 'FLOAT', 'STRING', 'UINT', 'DWORDTIME')

# Tables Game.exe reads outside CDataBaseSystem::OpenAllDataBase (static review of Src; phase = first use).
OTHER_LOADERS = [
    # file, phase, loader (Src path), note
    ('BeHit.txt', 'startup-ui', 'Client/CEGUISystem/UICreatureBoardSystem.cpp', 'UI reader (20-column modern BeHit)'),
    ('StrDictionary.txt', 'startup-ui', 'Client/CEGUISystem/UIString.cpp', 'UI dictionary reader (UTF-8 two-column)'),
    ('Config_VideoCard.txt', 'startup', 'Engine/WXRender/HardwareInfoSystem.cpp', 'hardware profile table'),
    ('Config_Cpu.txt', 'startup', 'Engine/WXRender/HardwareInfoSystem.cpp', 'hardware profile table'),
    ('Config_PhyMemory.txt', 'startup', 'Engine/WXRender/HardwareInfoSystem.cpp', 'hardware profile table'),
    ('CityIdOfChina.txt', 'login', 'Client/WXClient/Procedure/GameProcedure.cpp', 'login province list'),
    ('CysLoginShowroom.txt', 'charsel', 'Client/WXClient/Procedure/CysLoginScene.cpp', 'CY creation profile overlay'),
    ('CysCreatePreview.txt', 'charcreate', 'Client/WXClient/Interface/GMGameInterface_Script_CreateRole.cpp', 'CY creation profile overlay'),
    ('CysCreateCamera.txt', 'charcreate', 'Client/WXClient/Procedure/CysCreateRoleAppearanceGame.cpp', 'CY creation profile overlay (Model_Parameter bytes)'),
    ('CysCreateRace.txt', 'charcreate', 'Client/WXClient/Procedure/CysCreateRoleAppearance.cpp', 'CY creation profile overlay (CharRace bytes)'),
    ('CysCreateModel.txt', 'charcreate', 'Client/WXClient/Procedure/CysCreateRoleAppearance.cpp', 'CY creation profile overlay (CharModelEx bytes)'),
    ('CysCreateFace.txt', 'charcreate', 'Client/WXClient/Procedure/CysCreateRoleAppearance.cpp', 'CY creation profile overlay (CharFaceGeo bytes)'),
    ('CysCreateHair.txt', 'charcreate', 'Client/WXClient/Procedure/CysCreateRoleAppearance.cpp', 'CY creation profile overlay (CharHairGeo bytes)'),
    ('CysCreatePortrait.txt', 'charcreate', 'Client/WXClient/Procedure/CysCreateRoleAppearance.cpp', 'CY creation profile overlay (CharacterFace bytes)'),
    ('CysCreateOutfit.txt', 'charcreate', 'Client/WXClient/Procedure/CysCreateRoleAppearance.cpp', 'CY creation profile overlay (NewRoleEquipset bytes)'),
    ('CysCreateVisual.txt', 'charcreate', 'Client/WXClient/Procedure/CysCreateRoleAppearance.cpp', 'CY creation profile overlay (ItemVisualChar bytes)'),
    ('ActionSet/ActionSet.txt', 'world', '(B only)', 'modern action sets (data table)'),
    ('ActionSet/ActionSetLine.txt', 'world', '(B only)', 'modern action set lines'),
    ('ActionSet/ActionSetKV.txt', 'world', '(B only)', 'modern action set key/value track names'),
    ('<scene>.esd', 'world', 'Client/WXClient/World/Scene.cpp', 'per-scene environment sounds (_DBC_ENV_SOUND)'),
]


def decode(raw):
    for encoding in ('utf-8', 'gbk'):
        try:
            return raw.decode(encoding)
        except UnicodeDecodeError:
            pass
    return raw.decode('gbk', 'replace')


class Table:
    """Parsed DBC table (binary 00CCBBDD or text), read-only. Mirrors TLBB_DBC.cpp rules."""

    def __init__(self, path, keep_rows=True):
        self.path = Path(path)
        raw = self.path.read_bytes()
        self.sha256 = hashlib.sha256(raw).hexdigest()
        self.bytes = len(raw)
        self.names = None
        self.rows = []
        if raw[:4] == b'\x00\xcc\xbb\xdd':
            self.format = 'binary'
            _, fields, records, strings = struct.unpack_from('<Iiii', raw, 0)
            kinds = struct.unpack_from('<%dI' % fields, raw, 16)
            self.types = [TYPE_NAMES[k] if k < len(TYPE_NAMES) else 'T%d' % k for k in kinds]
            self.records = records
            if keep_rows:
                base = 16 + 4 * fields
                cells = struct.unpack_from('<%dI' % (fields * records), raw, base)
                pool = raw[base + 4 * fields * records:base + 4 * fields * records + strings]
                for r in range(records):
                    row = []
                    for c in range(fields):
                        v = cells[r * fields + c]
                        t = self.types[c]
                        if t == 'FLOAT':
                            row.append(round(struct.unpack('<f', struct.pack('<I', v))[0], 4))
                        elif t == 'STRING':
                            end = pool.find(b'\0', v) if v < len(pool) else -1
                            row.append(decode(pool[v:end]) if end >= 0 else '')
                        elif t == 'INT':
                            row.append(struct.unpack('<i', struct.pack('<I', v))[0])
                        else:
                            row.append(v)
                    self.rows.append(row)
        else:
            self.format = 'text'
            lines = raw.split(b'\n')
            self.types = [c.decode('ascii', 'replace') for c in lines[0].rstrip(b'\r').split(b'\t') if c]
            second = lines[1].rstrip(b'\r').split(b'\t') if len(lines) > 1 else []
            names = [decode(n) for n in second]
            if [n for n in names if n] != self.types:
                self.names = names[:len(self.types)] + [''] * max(0, len(self.types) - len(names))
            count = 0
            for line in lines[2:]:
                line = line.rstrip(b'\r')
                if not line or line.startswith(b'#'):
                    continue
                fields = line.split(b'\t')
                if not fields[0]:
                    continue
                count += 1
                if not keep_rows:
                    continue
                fields += [b''] * (len(self.types) - len(fields))
                row = []
                for c, t in enumerate(self.types):
                    v = fields[c]
                    if t == 'INT':
                        try:
                            row.append(int(v) if v.strip() else 0)
                        except ValueError:
                            try:
                                row.append(int(float(v)))
                            except ValueError:
                                row.append(0)
                    elif t == 'FLOAT':
                        try:
                            row.append(round(float(v), 4) if v.strip() else 0.0)
                        except ValueError:
                            row.append(0.0)
                    else:
                        row.append(decode(v))
                self.rows.append(row)
            self.records = count

    def schema(self):
        return ' '.join(t[0] if t in ('INT', 'FLOAT', 'STRING') else t for t in self.types)


def natural_size(types, pointer=8):
    """Record size with the natural C layout of the column types (TLBB_DBC.cpp _BuildLayout, B GetDataBase size)."""
    offset, align = 0, 4
    for t in types:
        size = pointer if t == 'STRING' else 4
        offset = (offset + size - 1) // size * size + size
        align = max(align, size)
    return (offset + align - 1) // align * align


def align(old, new, maxrows=4000):
    """Monotonic column alignment old->new by value agreement over rows with the same column-0 id."""
    io = {r[0]: r for r in old.rows}
    inew = {r[0]: r for r in new.rows}
    common = [k for k in io if k in inew][:maxrows]
    if not common:
        return [], 0
    na, nb = len(old.types), len(new.types)
    score = [[0.0] * nb for _ in range(na)]
    for j in range(na):
        values = [io[k][j] for k in common]
        informative = len(set(values)) >= 2
        for k in range(nb):
            if old.types[j] != new.types[k]:
                continue
            equal = sum(1 for key in common if io[key][j] == inew[key][k])
            score[j][k] = (1.0 if informative else 0.05) * equal / len(common)
    best = [[0.0] * (nb + 1) for _ in range(na + 1)]
    step = [[None] * (nb + 1) for _ in range(na + 1)]
    for j in range(1, na + 1):
        for k in range(1, nb + 1):
            value, how = best[j - 1][k], 'u'
            if best[j][k - 1] > value:
                value, how = best[j][k - 1], 'l'
            s = score[j - 1][k - 1]
            if s >= 0.30 and best[j - 1][k - 1] + s > value:
                value, how = best[j - 1][k - 1] + s, 'd'
            best[j][k], step[j][k] = value, how
    pairs, j, k = [], na, nb
    while j > 0 and k > 0:
        how = step[j][k]
        if how == 'd':
            pairs.append([j - 1, k - 1, round(score[j - 1][k - 1], 3)])
            j, k = j - 1, k - 1
        elif how == 'u':
            j -= 1
        else:
            k -= 1
    return list(reversed(pairs)), len(common)


def our_tables(path=GMDB):
    """(DBC id macro, file) pairs of CDataBaseSystem::OpenAllDataBase in Src."""
    text = path.read_text(encoding='utf-8-sig', errors='replace')
    return [(m.group(1), m.group(2)) for m in re.finditer(r'^\s*\{\s*(DBC_\w+)\s*,\s*"([^"]+)"\s*(?:,[^}]*)?\}', text, re.M)]


def find(source, name):
    base = SOURCES[source]
    path = base / name
    if path.is_file():
        return path
    lower = name.lower()
    parent = path.parent
    if parent.is_dir():
        for entry in parent.iterdir():
            if entry.name.lower() == Path(name).name.lower():
                return entry
    return None


def describe(name, with_alignment=True):
    record = {'file': name}
    can_path = find('CAN', name)
    if not can_path:
        record['canonical'] = None
        return record
    can = Table(can_path)
    record['canonical'] = {
        'path': str(can_path.relative_to(ROOT)).replace('\\', '/'), 'format': can.format, 'columns': len(can.types),
        'types': can.types, 'names': can.names, 'records': can.records, 'bytes': can.bytes, 'sha256': can.sha256,
        'record_size_x64': natural_size(can.types, 8), 'record_size_x86': natural_size(can.types, 4)}
    if not with_alignment:
        return record
    for source in ('REF', 'S2', 'SRV'):
        path = find(source, name)
        if not path:
            continue
        try:
            other = Table(path)
        except Exception as error:  # noqa: BLE001 - evidence only, keep going
            record[source.lower()] = {'error': type(error).__name__}
            continue
        pairs, common = align(other, can)
        record[source.lower()] = {
            'format': other.format, 'columns': len(other.types), 'types': other.types, 'names': other.names,
            'records': other.records, 'common_ids': common, 'alignment_to_canonical': pairs}
    return record


def build(out_dir):
    ours = our_tables()
    by_file = {}
    for dbc, name in ours:
        by_file.setdefault(name, {})['ours'] = {'dbc': dbc, 'loader': 'CDataBaseSystem::OpenAllDataBase', 'phase': 'startup'}
    for name, phase, loader, note in OTHER_LOADERS:
        by_file.setdefault(name, {})['other'] = {'phase': phase, 'loader': loader, 'note': note}
    tables = []
    for name in sorted(by_file, key=str.lower):
        info = by_file[name]
        wanted = 'ours' in info or 'other' in info
        record = describe(name, with_alignment=wanted) if not name.startswith('<') else {'file': name, 'canonical': None}
        record.update(info)
        tables.append(record)
    summary = {
        'generated': datetime.datetime.now().astimezone().isoformat(timespec='seconds'),
        'tool': 'Tools/game/dbc_inventory.py',
        'sources': {k: str(v) for k, v in SOURCES.items()},
        'counts': {'ours_openall': len(ours), 'other_loaders': len(OTHER_LOADERS)},
        'tables': tables}
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / 'dbc_inventory_gl.json').write_text(json.dumps(summary, ensure_ascii=False, indent=1) + '\n',
                                                 encoding='utf-8', newline='\n')
    header = ['file', 'our_dbc', 'phase', 'loader', 'format', 'columns', 'records',
              'size_x64', 'names', 'schema']
    rows = ['\t'.join(header)]
    for t in tables:
        can = t.get('canonical') or {}
        ours_info = t.get('ours') or {}
        other = t.get('other') or {}
        rows.append('\t'.join(str(x) for x in [
            t['file'], ours_info.get('dbc', '-'), ours_info.get('phase', other.get('phase', '-')),
            ours_info.get('loader', other.get('loader', '-')),
            can.get('format', 'MISSING'), can.get('columns', 0), can.get('records', 0), can.get('record_size_x64', 0),
            'yes' if can.get('names') else 'no',
            ' '.join(x[0] if x in ('INT', 'FLOAT', 'STRING') else x for x in can.get('types', []))]))
    (out_dir / 'dbc_inventory_gl.tsv').write_text('\n'.join(rows) + '\n', encoding='utf-8', newline='\n')
    print('tables=%d ours=%d other=%d' % (len(tables), len(ours), len(OTHER_LOADERS)))
    return 0


def report(names):
    for name in names:
        record = describe(name)
        can = record.get('canonical')
        if not can:
            print('##', name, 'not in Canonical')
            continue
        print('## %s CAN %s %d cols %d rows size x64=%d' % (name, can['format'], can['columns'], can['records'],
                                                           can['record_size_x64']))
        print('   types: ' + ' '.join('%d:%s' % (i, t[0]) for i, t in enumerate(can['types'])))
        if can['names']:
            print('   names: ' + ' | '.join('%d:%s' % (i, n) for i, n in enumerate(can['names'])))
        for source in ('ref', 's2', 'srv'):
            other = record.get(source)
            if not other or 'error' in other:
                continue
            print('   %s %d cols; %s' % (source.upper(), other['columns'],
                                       ' '.join('%d>%d(%.2f)' % tuple(p) for p in other['alignment_to_canonical'])))
            if other.get('names'):
                print('   %s names: %s' % (source.upper(), ' | '.join('%d:%s' % (i, n) for i, n in enumerate(other['names']))))
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest='cmd', required=True)
    p_build = sub.add_parser('build')
    p_build.add_argument('--out-dir', type=Path, default=ROOT / 'Registry/abi')
    p_report = sub.add_parser('report')
    p_report.add_argument('tables', nargs='+')
    args = parser.parse_args()
    if args.cmd == 'build':
        out = args.out_dir if args.out_dir.is_absolute() else ROOT / args.out_dir
        if not out.resolve().is_relative_to(ROOT.resolve()):
            parser.error('--out-dir must stay inside CY-Source')
        return build(out)
    return report(args.tables)


if __name__ == '__main__':
    sys.exit(main())
