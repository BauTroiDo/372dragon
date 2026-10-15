"""Build one versioned wardrobe catalog for the CY overlay and private server.

Reads CanonicalCY only. IDs of the older GL server are deliberately not reused:
categories 2..7 use 10000 + CY ID. Category 8 is event-only; mounts (9)
already use the CY ID axis on the private server.
"""
from pathlib import Path
import argparse
import hashlib
import json
import re
import sys

HERE = Path(__file__).resolve().parents[2]
ROOT = next(p for p in (HERE, *HERE.parents) if (p/'Assets/CanonicalCY/Data').is_dir())
sys.path.insert(0, str(ROOT/'Tools/redteam'))
from rt_dbc import Dbc
from wardrobe_soul_models import repairs as soul_model_repairs

LABELS = ['Trang phục', 'Mặt', 'Tóc', 'Avatar', 'Đầu sức', 'Bối sức', 'Huyễn sức', 'Thú hồn', 'Thú cưỡi']

def text(v):
    if not isinstance(v, bytes):
        return v
    try:
        return v.decode('utf-8')
    except UnicodeDecodeError:
        return v.decode('gbk', 'replace')

def lua(v):
    if isinstance(v, dict):
        return '{'+','.join('['+lua(k)+']='+lua(x) for k,x in v.items())+'}'
    if isinstance(v, (list, tuple)):
        return '{'+','.join(lua(x) for x in v)+'}'
    if isinstance(v, str):
        return json.dumps(v, ensure_ascii=False)
    if isinstance(v, bool):
        return 'true' if v else 'false'
    return str(v)

def build(root=ROOT):
    cfg=root/'Assets/CanonicalCY/Data/ConfigFolder'
    sources={}
    validation=json.loads(Path(__file__).with_name('wardrobe_fashion_validation.json').read_text(encoding='utf-8'))
    for relative,expected in validation['sources'].items():
        actual=hashlib.sha256((cfg.parent/relative).read_bytes()).hexdigest()
        if actual!=expected:
            raise ValueError('Fashion render census must be regenerated for changed data: '+relative)
    def rows(name):
        path=cfg/(name+'.txt')
        sources[name]=hashlib.sha256(path.read_bytes()).hexdigest()
        d=Dbc(path)
        return [[text(d.cell(r,c)) for c in range(d.nF)] for r in range(d.nR)]
    equip={r[0]:r for r in rows('EquipBase')}
    dress={r[0]:r for r in rows('EquipDress')}
    color_names={}
    for r in rows('DressColorRate'):
        for c in range(3,31,3):
            if r[c]>0: color_names[r[c]]=r[c+2]
    visuals={r[0]:r for r in rows('ItemVisualChar')}
    catalog={i:[] for i in range(1,10)}
    def add(cat, id, names, icons, visual, native=None, **extra):
        row=dict(id=id, native=id if cat==1 else 10000+id, name=names,
                 icon=icons, visual=visual, valid=[True,True])
        if native is not None: row['native']=native
        row.update(extra)
        catalog[cat].append(row)
    for id,r in equip.items():
        if r[5]!=16: continue
        d=dress.get(r[6]); v=visuals.get(d[2]) if d else None
        valid=[bool(v and v[c] and v[c]!='-1') for c in (1,12)]
        bad=validation['invalid'].get(str(r[6]))
        if bad: valid=[valid[0] and bad['W'],valid[1] and bad['M']]
        add(1,id,[r[10]]*2,[r[18]]*2,[r[6]]*2,valid=valid,
            group=d[6]*100000+d[2] if d else -id, base=d[6] if d else -id, model=d[2] if d else -1, color=d[5] if d else 1,
            colorName=color_names.get(r[6], 'Mặc định' if not d or d[5]==1 else 'Màu '+str(d[5]-1)))
    for cat,base,geo,ncol,icol in ((2,'Exterior_Face','CharFaceGeo',4,8),
                                  (3,'Exterior_Hair','CharHairGeo',6,10),
                                  (4,'Exterior_Head','CharHead',2,6)):
        g={r[0]:r for r in rows(geo)}
        for r in rows(base):
            pair=[g.get(r[1]),g.get(r[2])]
            add(cat,r[0],[x[ncol] if x else 'Dữ liệu chưa đủ' for x in pair],
                [x[icol] if x else '' for x in pair],r[1:3],valid=[x is not None for x in pair])
    ornaments={r[0]:r for r in rows('ItemOrnamentsVisual')}
    locator_actions={r[2]:r[6:9] for r in rows('ItemLocatorAction') if r[1]==3}
    moods={r[0]:r for r in rows('ChatMood')}
    equip_actions={}
    for r in rows('EquipMoodAction'):
        actions=[]
        for mid in r[4:10]:
            m=moods.get(mid)
            if m and re.fullmatch(r'\d+;[01](?:;\d+;[01])*',m[7]):
                actions.append(dict(order=m[7],name=m[11].split('#r')[0] or m[1]))
        if actions: equip_actions[r[1]]=actions
    for cat,base in ((5,'Exterior_TS'),(6,'Exterior_BG')):
        for r in rows(base):
            v=ornaments.get(r[4]); obj=[v[1],v[3]] if v else ['', '']
            add(cat,r[0],[r[1]]*2,[r[2]]*2,[r[4]]*2,obj=obj,
                pos=[r[12:15],r[15:18]],scale=[r[18:21],r[21:24]],bounds=r[6:12],
                valid=[bool(x and x!='-1') for x in obj],
                idle=locator_actions.get(r[4],[]) if cat==6 else [],
                actions=[dict(order=a,name='Động tác nghỉ '+str(i)) for i,a in enumerate(locator_actions.get(r[4],[])[1:],1) if a and a not in ('-1','站立')] if cat==6 else [])
    weapon_groups={leaf:(g[0],level,g[6]) for g in rows('Exterior_WeaponGroup')
                   for level,leaf in enumerate(g[9:14],1) if leaf>0}
    for r in rows('Exterior_Weapon'):
        e=equip.get(r[6])
        group,level,group_name=weapon_groups.get(r[0],(-r[0],1,r[4]))
        add(7,r[0],[e[10] if e else r[4]]*2,[r[5]]*2,[r[6]]*2,
            weaponVisual=e[6] if e else -1,valid=[bool(e)]*2,actions=equip_actions.get(r[6],[]),
            group=group,level=level,groupName=re.sub(r'\s*[（(](?:Cấp\s*\d+|\d+级)[)）]\s*$','',e[10],flags=re.I) if e else group_name)
    soul_colors=rows('PetPossColourRate')
    models={r[0]:r for r in rows('CharModelEx')}
    soul_models=soul_model_repairs(root)
    for r in rows('Exterior_PetPoss'):
        # Display only; the acquisition RPC excludes this category at both ends.
        variants=[]
        for color in soul_colors:
            if color[1]!=r[6]: continue
            index=color[2]%1000
            for level,fusion in enumerate((0,3,6,8,10),1):
                model=color[9+3*fusion]
                variants.append(dict(id=r[0],native=r[0],name=[r[7]]*2,
                    icon=[r[8+index] if 1<=index<=9 else r[8]]*2,
                    visual=[color[0]]*2,valid=[model in models or model in soul_models]*2,
                    color=index,colorName=color[42],level=level,fusion=fusion,model=model))
        add(8,r[0],[r[7]]*2,[r[8]]*2,[-1,-1],native=r[0],variants=variants)
    mounts={r[0]:r for r in rows('CharMount')}
    ride=Dbc(cfg/'Exterior_Ride.txt')
    for index,r in enumerate(rows('Exterior_Ride')):
        mount=mounts.get(r[10]); model=models.get(mount[3]) if mount else None
        # Names in this CY table are GBK, including byte pairs valid as UTF-8.
        name=ride.s(index,7).decode('gbk')
        add(9,r[0],[name]*2,[r[8]]*2,[r[10]]*2,native=r[0],
            valid=[bool(model and model[1] and model[1]!='-1')]*2,
            height=mount[4] if mount else 0,fly=mount[22] if mount else 0)
    for entries in catalog.values(): entries.sort(key=lambda x:x['id'])
    # Presentation families retain every leaf ID for ownership and the RPC.
    # Several shop items (duration/binding) share one EquipDress appearance.
    families={i:[] for i in catalog}
    for cat,entries in catalog.items():
        groups={}
        for row in entries:
            key=row.get('group',row['id'])
            if key not in groups:
                family=dict(row); family['key']=key; family['variants']=[]
                if cat==7: family['name']=[row['groupName']]*2
                groups[key]=family
            family=groups[key]
            if cat==8:
                family['variants']=row['variants']
                continue
            existing=next((v for v in family['variants'] if cat==1 and v['visual']==row['visual']),None)
            if existing: existing['aliases'].append(row['id'])
            else: family['variants'].append(dict(row,aliases=[row['id']]))
        for family in groups.values():
            if cat==1:
                available={v['visual'][0] for v in family['variants']}
                base=min(family['variants'],key=lambda v:(v['color'],v['id']))
                dyes={}
                for visual,d in dress.items():
                    if d[6]!=family['base'] or d[2]!=family['model']: continue
                    v=visuals.get(d[2]); bad=validation['invalid'].get(str(visual))
                    valid=[bool(v and v[c] and v[c]!='-1') for c in (1,12)]
                    if bad: valid=[valid[0] and bad['W'],valid[1] and bad['M']]
                    dyes[visual]=valid
                    if visual not in available:
                        family['variants'].append(dict(base,visual=[visual]*2,valid=valid,color=d[5],
                            colorName=color_names.get(visual,'Mặc định' if d[5]==1 else 'Màu '+str(d[5]-1))))
                # Server validates colour against this family, never arbitrary visuals.
                for row in entries:
                    if row['group']==family['key']: row['dyes']=dyes
            family['variants'].sort(key=lambda v:(v.get('color',1),v.get('level',1),v['id']))
            families[cat].append(family)
    hj_path=root/'Registry/hj-appearance-catalog.json'
    if hj_path.exists():
        addon=json.loads(hj_path.read_text(encoding='utf-8'))
        for key,entries in addon['categories'].items():
            cat=int(key);old={r['id'] for r in catalog[cat]}
            if old & {r['id'] for r in entries}:raise ValueError('HJ wardrobe ID collision: '+key)
            for row in entries:
                if 'dyes' in row:row['dyes']={int(k):v for k,v in row['dyes'].items()}
            catalog[cat].extend(entries)
            catalog[cat].sort(key=lambda r:r['id'])
            families[cat].extend(addon['families'][key])
        sources['HJ']=hashlib.sha256(hj_path.read_bytes()).hexdigest()
    return {'version':2,'labels':LABELS,'categories':catalog,'families':families,'sources':sources}

def main():
    p=argparse.ArgumentParser(); p.add_argument('--out',type=Path,required=True)
    args=p.parse_args(); args.out.mkdir(parents=True,exist_ok=True)
    c=build(); (args.out/'catalog.json').write_text(json.dumps(c,ensure_ascii=False,indent=2),encoding='utf-8')
    (args.out/'wardrobe_catalog.lua').write_text('return '+lua(c['categories'])+'\n',encoding='utf-8')
    print(json.dumps({'counts':{k:len(v) for k,v in c['categories'].items()},
                      'invalid':{k:sum(not all(x['valid']) for x in v) for k,v in c['categories'].items()}}))

if __name__=='__main__': main()
