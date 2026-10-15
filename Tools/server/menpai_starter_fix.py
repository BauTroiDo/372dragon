"""Stage/apply starter weapons in the private CY server, with hash guards and backups."""
from pathlib import Path
import argparse, datetime, hashlib, json, re, shutil

ROOT = Path('/home/ubuntu/cys-test-20260913')
HERE = Path(__file__).resolve().parent
BASE = Path('GameServer/lualib/script_base.lua')
MODULE = Path('GameServer/lualib/menpai_starter.lua')
sha = lambda data: hashlib.sha256(data).hexdigest()


def replacements():
    raw = (ROOT / BASE).read_bytes()
    text = raw.decode('utf8')
    assert 'CYS-STARTER' not in text, 'already applied; use verify'
    old = '    if not ready then return false, reason end\n    local changed, change_reason = obj:set_menpai(menpai)'
    new = '''    if not ready then return false, reason end
    -- CYS-STARTER: reserve all joining gifts before changing faction or skills.
    if obj:get_menpai() == menpai then return false, "already_joined" end
    local gifts_ok, starter = require("menpai_starter").prepare(self, obj, menpai)
    if not gifts_ok then return false, starter end
    local changed, change_reason = obj:set_menpai(menpai)'''
    assert text.count(old) == 1
    text = text.replace(old, new)
    old = '    obj:send_setting()\n    return true\nend\n\nfunction script_base:LuaFnSetXinFaLevel'
    new = '''    obj:send_setting()
    if starter then
        self:AddItemListToHuman(selfId)
        obj:notify_tips("Đã nhận vũ khí Tân thủ của môn phái trong túi đồ.")
        skynet.logi("CYS-STARTER granted", obj:get_guid(), menpai, require("menpai_starter").weapons[menpai])
    end
    return true
end

function script_base:LuaFnSetXinFaLevel'''
    assert text.count(old) == 1
    yield BASE, text.replace(old, new).encode('utf8')
    yield MODULE, (HERE / 'menpai_starter.lua').read_bytes()
    # Old NPCs ignored JoinMenpai's return and continued after a refused join.
    # Guard those calls so a full bag cannot still upgrade foreign xinfa.
    pattern = re.compile(rb'^([ \t]*)self:LuaFnJoinMenpai\((selfId\s*,\s*\d+)\)[ \t]*(\r?)$', re.M)
    for path in sorted((ROOT / 'Game_2/Script/scripts/obj').rglob('*.lua')):
        data = path.read_bytes()
        new, n = pattern.subn(rb'\1if not self:LuaFnJoinMenpai(\2) then return end -- CYS-STARTER\3', data)
        if n:
            yield path.relative_to(ROOT), new


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('mode', choices=['plan', 'apply', 'verify'])
    p.add_argument('--staging', type=Path, required=True)
    a = p.parse_args()
    assert ROOT.resolve() == ROOT and ROOT.is_dir()
    planfile = a.staging / 'plan.json'
    if a.mode == 'plan':
        assert not planfile.exists()
        rows = []
        for rel, data in replacements():
            dst = a.staging / rel
            dst.parent.mkdir(parents=True, exist_ok=True)
            dst.write_bytes(data)
            original = ROOT / rel
            rows.append(dict(path=str(rel), before=sha(original.read_bytes()) if original.exists() else None, after=sha(data)))
        planfile.write_text(json.dumps(rows, indent=2))
        print(json.dumps(rows, indent=2))
        return
    rows = json.loads(planfile.read_text())
    if a.mode == 'verify':
        for row in rows:
            assert sha((ROOT / row['path']).read_bytes()) == row['after'], row['path']
        print('verified', len(rows), 'deployed files')
        return
    for row in rows:
        target = ROOT / row['path']
        assert target.resolve().is_relative_to(ROOT)
        assert (sha(target.read_bytes()) if target.exists() else None) == row['before'], row['path']
        assert sha((a.staging / row['path']).read_bytes()) == row['after']
    backup = ROOT / 'backups' / ('menpai-starter-' + datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ'))
    backup.mkdir(parents=True, exist_ok=False)
    shutil.copy2(planfile, backup / 'plan.json')
    for row in rows:
        target = ROOT / row['path']
        if target.exists():
            copy = backup / row['path']
            copy.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(target, copy)
        shutil.copy2(a.staging / row['path'], target)
    print('backup:', backup)


if __name__ == '__main__':
    main()
