"""Restore CY mission-NPC group selection and nine-result shimen assignments.

Dry-run by default. Only the private server root is writable; every apply has
hashes and backups. Reapply AFTER equipment_skills.py if regenerating its base.
"""
from pathlib import Path
import argparse
import datetime
import hashlib
import json
import re
import shutil

ROOT = Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913')
REPO = Path(__file__).resolve().parents[2]
NAMES = 'shaolin tianshan wudang xiaoyao xingxiu gaibang mingjiao emei dali mantuo'.split()
REPLACEMENT = '''function script_base:GetOneMissionNpc(group)
    -- CY's argument is a membership column, not a row ID. Keep the direct
    -- lookup in GetNpcInfoByNpcId separate from this random group lookup.
    local config = configenginer:get_config("mission_npc_hash_table")
    local ids = config.index[group]
    local id = ids and #ids > 0 and ids[math.random(1, #ids)] or nil
    local row = id and config.data[id] or nil
    if not row then return -1, "", "", -1, 0, 0, "", -1, -1 end
    return id, row["NPC名称$1$"], row["场景名称$1$"],
        row["场景ID"], row["坐标X"], row["坐标Z"],
        row["NPC描述$1$"], row["性别"], row["等级"]
end'''


def transform(rel, raw):
    text = raw.decode('utf-8')
    if rel.endswith('script_base.lua'):
        text, count = re.subn(r'function script_base:GetOneMissionNpc\([^\n]*\).*?\nend',
                             lambda _: REPLACEMENT, text, flags=re.S)
        assert count == 1
    else:
        new = 'nMonsterId, strMonsterName, strMonsterScene, nScene, nPosX, nPosZ, strDesc, nSex, level = self:GetOneMissionNpc('
        old = 'nMonsterId = self:GetOneMissionNpc('
        if new not in text:
            assert text.count(old) == 1, rel
            text = text.replace(old, new)
    return text.encode('utf-8')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true')
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    assert ROOT.name == 'cys-test-20260913' and ROOT.is_dir()
    rels = ['GameServer/lualib/script_base.lua'] + [
        f'Game_2/Script/scripts/event/shimen/event_shimen_{name}.lua' for name in NAMES]
    args.out.mkdir(parents=True, exist_ok=True)
    records, changes = [], []
    sha = lambda raw: hashlib.sha256(raw).hexdigest()
    for rel in rels:
        raw = (ROOT / rel).read_bytes()
        new = transform(rel, raw)
        assert transform(rel, new) == new, rel
        dest = args.out / rel
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(new)
        records.append(dict(path=rel, before=sha(raw), after=sha(new)))
        if raw != new:
            changes.append((rel, raw, new))
    manifest = dict(root=str(ROOT), files=records)
    if args.apply and changes:
        backup = ROOT / 'backups' / ('shimen-targets-' + datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ'))
        backup.mkdir(parents=True, exist_ok=False)
        # Validate all inputs before changing any file.
        for rel, raw, new in changes:
            assert (ROOT / rel).read_bytes() == raw, rel
            dst = backup / rel
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / rel, dst)
        for rel, raw, new in changes:
            (ROOT / rel).write_bytes(new)
        manifest['backup'] = str(backup)
        (backup / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')
        print('backup', backup)
    (args.out / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')
    print(('APPLIED' if args.apply else 'PLAN'), len(changes), 'changes')


if __name__ == '__main__':
    main()
