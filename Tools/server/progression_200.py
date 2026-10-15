"""Raise the private CY character cap and grant GM to existing test accounts.

Character levels only: xinfa/skill instance limits are separate tables/protocols.
The native AttrLevelUpTable repeats every ten levels above 100. Extend that
verified cycle through 200, preserving all 17 schools and every existing row.
"""
from pathlib import Path
import argparse, datetime, hashlib, json, re, subprocess
from cs3b_menpai import provision
from give_item import connected

ROOT = Path('/home/ubuntu/cys-test-20260913')
RELS = ['configs/ConfigInfo.ini', 'GameServer/lualib/define.lua',
        'GameServer/services/gm_tool_core.lua', 'GameServer/services/hs_admin.lua',
        'GameServer/services/scene/scenecore.lua',
        'Game_2/Script/scripts/GmTool_Self.lua', 'configs/AttrLevelUpTable.txt', 'configs/PlayerExpLevel.txt']

def transform(rel, raw, accounts):
    if rel.endswith('PlayerExpLevel.txt'):
        lines=raw.splitlines();rows={int(s.split(b'\t')[0]):s.split(b'\t') for s in lines[2:] if s.strip()}
        # The old terminal level150 contains zero; use the existing post150
        # plateau for that one missing requirement. All other costs stay intact.
        if int(rows[150][1])==0:
            for i,s in enumerate(lines):
                if s.startswith(b'150\t'):lines[i]=b'150\t'+rows[151][1]
        values=[int(rows[i][1]) for i in range(1,201) if i!=150]
        assert all(v>0 and v*3.5<4294967295 for v in values)
        return b'\r\n'.join(lines)+b'\r\n'
    if rel.endswith('AttrLevelUpTable.txt'):
        lines = raw.splitlines()
        rows = {int(s.split(b'\t')[0]): s.split(b'\t') for s in lines[2:] if s.strip()}
        assert all(rows[i][1:] == rows[i-10][1:] for i in range(110, 151))
        for i in range(151, 201):
            expected = [str(i).encode()] + rows[141+(i-151)%10][1:]
            if i in rows: assert rows[i] == expected
            else: lines.append(b'\t'.join(expected))
        return b'\r\n'.join(lines)+b'\r\n'
    # ConfigInfo is GBK; perform byte-preserving ASCII substitutions.
    if rel.endswith('ConfigInfo.ini'):
        return raw.replace(b'HumanMaxDefaultLevel=120', b'HumanMaxDefaultLevel=201')
    s = raw.decode('utf8')
    if rel.endswith('define.lua'):
        s = s.replace('define.HUMAN_MAX_LEVEL = 120', 'define.HUMAN_MAX_LEVEL = 201 -- exclusive: playable character levels 1..200')
    elif rel.endswith('GmTool_Self.lua'):
        start=s.index('GmTool_Self.GmCeshi = '); end=s.index(';',start)+1
        old=s[start:end]
        users=set(re.findall(r'user\s*=\s*"([^"]+)"',old)) | set(accounts)
        s=s[:start]+'GmTool_Self.GmCeshi = {\n'+''.join('    {user = '+json.dumps(a)+'},\n' for a in sorted(users))+'};'+s[end:]
        s=s.replace('index1 > 119','index1 > 200').replace('p1 > 119','p1 > 200').replace('1 tới 119','1 tới 200')
    else:
        s=s.replace('level > 119', 'level > 200').replace('1-119', '1-200')
    return s.encode('utf8')

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--out',type=Path,required=True);p.add_argument('--apply',action='store_true');a=p.parse_args()
    with provision().database() as c:
        accounts=[d['uid'] for d in c.tlbb.account.find({'uid':{'$regex':'^test[0-9]+$'}},{'_id':0,'uid':1}).sort('uid',1)]
    assert accounts and all(re.fullmatch(r'test[0-9]+',x) for x in accounts)
    changes=[];manifest={'root':str(ROOT),'cap':200,'gm_accounts':accounts,'files':[]}
    for rel in RELS:
        raw=(ROOT/rel).read_bytes();new=transform(rel,raw,accounts)
        assert transform(rel,new,accounts)==new,rel
        dst=a.out/rel;dst.parent.mkdir(parents=True,exist_ok=True);dst.write_bytes(new)
        if rel.endswith('.lua'):subprocess.run(['luac','-p',str(dst)],check=True)
        manifest['files'].append({'path':rel,'before':hashlib.sha256(raw).hexdigest(),'after':hashlib.sha256(new).hexdigest()})
        if raw!=new:changes.append((rel,raw,new))
    if a.apply and changes:
        assert not connected(),'private client connected'
        bak=ROOT/'backups'/('progression-200-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S'));bak.mkdir()
        for rel,raw,new in changes:
            assert (ROOT/rel).read_bytes()==raw
            dst=bak/rel;dst.parent.mkdir(parents=True,exist_ok=True);dst.write_bytes(raw)
        for rel,raw,new in changes:(ROOT/rel).write_bytes(new)
        manifest['backup']=str(bak);(bak/'manifest.json').write_text(json.dumps(manifest,indent=2))
    (a.out/'manifest.json').write_text(json.dumps(manifest,indent=2))
    print('APPLIED' if a.apply else 'PLAN',len(changes),'files; GM:',','.join(accounts))
if __name__=='__main__':main()
