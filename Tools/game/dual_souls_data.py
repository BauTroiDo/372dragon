"""Append prototype rows without rewriting any existing CY/HJ record."""
from pathlib import Path
import json, sys
import shutil
from hj_appearance_data import RawTable
ROOT=Path(__file__).resolve().parents[2]
PLAY=ROOT/'Build/world-gui/stage-play-21'
SERVER=Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913')
CAT=json.loads((ROOT/'Registry/dual-souls.json').read_text(encoding='utf8'))
BASELINE=ROOT/'Build/Logs/2026-09-25-dual-souls/table-baseline'
def live(name):
    return next(p for p in [PLAY/f'Overlay/{side}/ConfigFolder/{name}.txt' for side in ('Post','Pre')]+[ROOT/f'Assets/CanonicalCY/Data/ConfigFolder/{name}.txt'] if p.exists())
def tables():
    out={}
    for side in ('client','server'):
        def load(n):
            saved=BASELINE/side/(n+'.txt')
            if not saved.exists():
                saved.parent.mkdir(parents=True,exist_ok=True)
                shutil.copy2(live(n) if side=='client' else SERVER/f'configs/{n}.txt',saved)
            return RawTable(saved)
        base=load('EquipBase');added=[]
        for role,old,point in [('support',10156002,18),('assault',10156001,39)]:
            info=CAT[role];r=base.byid[old].copy()
            r[0]=info['item'];r[4]=info['item']%1000;r[5]=point;r[10]=info['name'].encode();r[11]=1
            r[13]=('Hồn cấp 1. '+('Huyền Giáp Hộ Thể (bị động); Cường Thể Hộ Hồn (buff).' if point==18 else 'Xích Diệm Trọng Kích (đơn mục tiêu); Xích Diệm Bát Phương (diện rộng).')+' Kéo chiêu chủ động xuống thanh F hoặc Alt+số. Mở Song hồn trong bảng Võ hồn để xem.').encode()
            r[19 if side=='client' else 22]=('Võ hồn' if point==18 else 'Chiến hồn').encode()
            r[102 if side=='client' else 20]=-1
            added.append(r)
        out[side+'/EquipBase.txt']=base.extend(added)
        if side=='client':
            base=load('KFSBase');added=[]
            for new,old in [(10156901,10156002),(10156902,10156001)]:
                r=base.byid[old].copy();r[0]=new;added.append(r)
            out['client/KFSBase.txt']=base.extend(added)
        templates=load('SkillTemplate_V1');details=load('SkillData_V1');ts=[];ds=[]
        for skill in CAT['skills']:
            r=templates.byid[skill['source']].copy();first=48 if side=='client' else 58
            d=details.byid[r[first]].copy();r[0]=skill['id'];d[0]=skill['data']
            r[2 if side=='client' else 3]=skill['name'].encode()
            r[79 if side=='client' else 74]=skill['description'].encode()
            r[13 if side=='client' else 16]=CAT['cooldown_groups'].get(str(skill['id']),-1)
            # One skill level in the prototype; each xinfa lookup selects the same data.
            for col in range(first,first+(31 if side=='client' else 16)):r[col]=skill['data']
            r[30 if side=='client' else 34]=1
            for col in ([1,2] if side=='client' else [3,4]):d[col]=skill['description'].encode()
            d[4 if side=='client' else 2]=skill['name'].encode()
            ts.append(r);ds.append(d)
        out[side+'/SkillTemplate_V1.txt']=templates.extend(ts)
        out[side+'/SkillData_V1.txt']=details.extend(ds)
    return out
if __name__=='__main__':
    out=ROOT/'Build/Logs/2026-09-25-dual-souls/data'
    generated=tables()
    for rel,data in generated.items():
        p=out/rel;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data)
    print('Prepared',len(generated),'tables, two items and four skills; original rows preserved.')
