"""Normalize proven boolean mission predicates; restore five GL NPC mappings.

Dry-run by default. Only the private server may be changed. Byte-preserving
edits skip Lua strings/comments, validate every file before any write, and
record before/after hashes plus full original files in a timestamped backup.
No database, service, or gameplay action is performed.
"""
import argparse
import collections
import datetime
import hashlib
import json
import re
from pathlib import Path

ROOT = Path('/home/ubuntu/cys-test-20260913')
NPCS = {50200: 'scripts.obj.xihu.oxihu_xueren',
        50201: 'scripts.obj.xihu.oxihu_xiaofan',
        50202: 'scripts.obj.xihu.oxihu_qunzhong',
        50203: 'scripts.obj.xihu.oxihu_lingzhen',
        311000: 'scripts.obj.luoyang.oluoyang_shumi'}
# Order matters: consume an entire string/comment before looking for code.
OPAQUE = re.compile(rb'--\[(=*)\[.*?\]\1\]|--[^\r\n]*|\[(=*)\[.*?\]\2\]|"(?:\\.|[^"\\])*"|\x27(?:\\.|[^\x27\\])*\x27', re.S)
PREDICATE = re.compile(rb'\b(self:(IsHaveMission|IsMissionHaveDone)\([^()\r\n]*\))\s*(<=|>=|==|~=|>|<)\s*([01])\b')
TRUTH = {('>', '0'): True, ('>=', '1'): True, ('==', '1'): True, ('~=', '0'): True,
         ('<=', '0'): False, ('<', '1'): False, ('==', '0'): False, ('~=', '1'): False}


def mask(data):
    return OPAQUE.sub(lambda m: re.sub(rb'[^\r\n]', b' ', m[0]), data)


def rewrite(data):
    edits = []
    for m in PREDICATE.finditer(mask(data)):
        key = (m[3].decode(), m[4].decode())
        if key not in TRUTH:
            raise ValueError('Unsupported boolean comparison: ' + str(key))
        before = data[m.start():m.end()]
        call = data[m.start(1):m.end(1)]
        after = call if TRUTH[key] else b'(not ' + call + b')'
        edits.append({'start': m.start(), 'end': m.end(), 'line': data.count(b'\n', 0, m.start()) + 1,
                      'api': m[2].decode(), 'before': before.decode('ascii'), 'after': after.decode('ascii')})
    result = data
    for edit in reversed(edits):
        result = result[:edit['start']] + edit['after'].encode('ascii') + result[edit['end']:]
    return result, edits


def rewrite_shimen_menu(data):
    # The five partially converted school scripts use their own buffer while
    # enumerating another NPC's menu. Mingjiao/Gaibang already use caller.
    scope = re.search(rb'^function event_shimen_\w+:OnEnumerate\(caller\b.*?(?=^function )', mask(data), re.M | re.S)
    assert scope, 'Expected the reviewed OnEnumerate callback'
    edits = []
    for m in re.finditer(rb'\bself:AddNumText\(', scope[0]):
        start, end = scope.start() + m.start(), scope.start() + m.end()
        edits.append({'start': start, 'end': end, 'line': data.count(b'\n', 0, start) + 1,
                      'menu_receiver': True, 'before': 'self:AddNumText(',
                      'after': 'caller:AddNumTextWithTarget(self.script_id,'})
    assert len(edits) in (0, 2), 'Unexpected menu structure; inspect before patching'
    result = data
    for e in reversed(edits):
        result = result[:e['start']] + e['after'].encode() + result[e['end']:]
    return result, edits


def sha(data):
    return hashlib.sha256(data).hexdigest()


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--confirm-root', required=True)
    ap.add_argument('--apply', action='store_true')
    ap.add_argument('--out', type=Path, required=True)
    args = ap.parse_args()
    if Path(args.confirm_root).resolve() != ROOT or ROOT.resolve() != ROOT:
        raise SystemExit('Only the private server root is allowed')
    root = ROOT / 'Game_2/Script'
    changes = []
    for path in sorted(root.rglob('*.lua')):
        data = path.read_bytes()
        updated, edits = rewrite(data)
        if path.name in {'event_shimen_' + school + '.lua' for school in ('shaolin', 'tianshan', 'wudang', 'xiaoyao', 'xingxiu')}:
            updated, menu_edits = rewrite_shimen_menu(updated)
            edits += menu_edits
        if edits:
            changes.append((path, data, updated, edits))
    registry = root / 'scripts/scripts.lua'
    data = registry.read_bytes()
    entries = {int(k): v.decode() for k, v in re.findall(rb'\[\s*(\d+)\s*\]\s*=\s*"([^"]+)"', data)}
    additions = []
    for sid, module in NPCS.items():
        source = (root / (module.replace('.', '/') + '.lua')).read_bytes()
        assert re.search(rb'\.script_id\s*=\s*0*' + str(sid).encode() + rb'\b', source), module
        if sid in entries:
            assert entries[sid] == module, ('Conflicting registry entry', sid)
        else:
            additions.append((sid, module))
    if additions:
        marker = b'\n}\nreturn dat'
        assert data.count(marker) == 1, 'Unexpected registry footer'
        block = b'\n    -- Verified against client_GL Script.dat (2026-09-21).\n'
        block += b''.join(('    [%d] = "%s",\n' % item).encode() for item in additions)
        updated = data.replace(marker, block + marker)
        changes.append((registry, data, updated, [{'registry_id': k, 'module': v} for k, v in additions]))
    manifest = {'applied': args.apply, 'root': str(ROOT), 'files': []}
    for path, before, after, edits in changes:
        manifest['files'].append({'path': path.relative_to(ROOT).as_posix(), 'before_sha256': sha(before),
                                  'after_sha256': sha(after), 'edits': edits})
    if args.apply and changes:
        stamp = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ')
        backup = ROOT / 'backups' / ('gameplay-predicates-' + stamp)
        backup.mkdir(parents=True, exist_ok=False)
        for path, before, _, _ in changes:
            assert path.resolve().is_relative_to(ROOT) and path.read_bytes() == before
            dest = backup / path.relative_to(ROOT)
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_bytes(before)
        manifest['backup'] = str(backup)
        for path, _, after, _ in changes:
            path.write_bytes(after)
        (backup / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    args.out.write_text(json.dumps(manifest, indent=2) + '\n')
    counts = collections.Counter(e['api'] for *_, edits in changes for e in edits if 'api' in e)
    print(json.dumps({'applied': args.apply, 'files': len(changes), 'predicates': dict(counts),
                      'menu_receivers': sum('menu_receiver' in e for *_, es in changes for e in es),
                      'registry_additions': len(additions), 'manifest': str(args.out)}))


if __name__ == '__main__':
    main()
