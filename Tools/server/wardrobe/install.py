"""Plan/apply the wardrobe feature to the private server only; backs up every edit.
Run with Windows Python. Original server and CanonicalCY stay read-only.
"""
from pathlib import Path
import argparse, datetime, hashlib, json, sys, subprocess, contextlib
REPO=next(p for p in Path(__file__).resolve().parents if (p/'Tools/game/wardrobe_catalog.py').is_file())
ROOT=next(p for p in (REPO,*REPO.parents) if (p/'Assets/CanonicalCY/Data').is_dir())
sys.path.insert(0,str(REPO/'Tools/game'))
from wardrobe_catalog import build,lua
sys.path.insert(0,str(ROOT/'Tools/redteam'))
from rt_dbc import Dbc
SERVER=Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913')
NATIVE=10000

def plan():
    c=build(ROOT); files={}
    # Unlike the other GL exterior tables, ride-finish already migrated mounts
    # to CY IDs. Refuse deployment if an old or mixed axis would summon a
    # different animal from the one shown in the catalog.
    ride_lines=(SERVER/'configs/Exterior_Ride.txt').read_bytes().splitlines()
    columns=ride_lines[1].decode('gbk').split('\t')
    model_column=columns.index('模型索引')
    rides={int(cells[0]):int(cells[model_column]) for line in ride_lines[2:]
           if (cells:=line.split(b'\t'))[0].isdigit()}
    for row in c['categories'][9]:
        assert rides.get(row['native'])==row['visual'][0],('mount ID axis mismatch',row['id'])
    files['Game_2/Script/scripts/wardrobe.lua']=Path(__file__).with_name('wardrobe.lua').read_bytes()
    files['Game_2/Script/scripts/wardrobe_catalog.lua']=('return '+lua(c['categories'])+'\n').encode('utf-8')
    reg='Game_2/Script/scripts/scripts.lua'; before=(SERVER/reg).read_bytes()
    marker=b'[990021] = "scripts.wardrobe"'
    if marker not in before:
        assert b'[990021]' not in before
        end=before.rfind(b'}'); assert end>0
        before=before[:end]+b'    '+marker+b',\n'+before[end:]
    files[reg]=before
    rel='configs/AllowableScriptFunc.txt'; before=(SERVER/rel).read_bytes()
    if b'\t990021\tRequest' not in before:
        assert b'\t990021\t' not in before
        ids=[int(x.split(b'\t')[0]) for x in before.splitlines()[2:] if x.split(b'\t')[0].isdigit()]
        before=before.rstrip(b'\r\n')+b'\n'+str(max(ids)+1).encode()+b'\t990021\tRequest\n'
    files[rel]=before
    for cat,name in ((2,'Exterior_Face'),(3,'Exterior_Hair'),(4,'Exterior_Head'),(5,'Exterior_TS'),(6,'Exterior_BG'),(7,'Exterior_Weapon')):
        rel='configs/'+name+'.txt'; old=(SERVER/rel).read_bytes()
        existing={int(line.split(b'\t')[0]):line for line in old.splitlines()[2:] if line.split(b'\t')[0].isdigit()}
        d=Dbc(ROOT/'Assets/CanonicalCY/Data/ConfigFolder'/f'{name}.txt')
        source={d.i(r,0):r for r in range(d.nR)}
        added=[]
        for row in c['categories'][cat]:
            if row.get('source')=='HJ':
                hj=json.loads((ROOT/'Assets/Imported/HJ20260910/server-rows.json').read_text(encoding='utf8'))
                cells=next(r for r in hj[name] if r[0]==row['native'])
                data='\t'.join(map(str,cells)).encode('gbk')
            elif cat==7:
                cells=[row['native'],row['name'][0],row['icon'][0],'CY wardrobe',2,2,3,2,row['visual'][0],row['weaponVisual'],row['weaponVisual'],row['weaponVisual'],-1]
                data='\t'.join(map(str,cells)).encode('gbk','replace')
            else:
                r=source[row['id']]; cells=[]
                for i in range(d.nF):
                    v=d.cell(r,i)
                    if i==0: v=row['native']
                    cells.append(v if isinstance(v,bytes) else str(v).encode())
                data=b'\t'.join(cells)
            if row['native'] in existing:
                assert existing[row['native']].rstrip(b'\r')==data,(name,row['native'],'namespace collision')
            else: added.append(data)
        files[rel]=old.rstrip(b'\r\n')+b'\n'+b'\n'.join(added)+b'\n' if added else old
    return files,c

@contextlib.contextmanager
def config_lock(enabled):
    if not enabled:
        yield
        return
    code="import fcntl,sys; f=open('/home/ubuntu/cys-test-20260913/configs/.scene_install.lock','a'); fcntl.flock(f,fcntl.LOCK_EX|fcntl.LOCK_NB); print('LOCKED',flush=True); sys.stdin.read()"
    process=subprocess.Popen(['wsl','-d','TLBB','-u','root','--','python3','-c',code],stdin=subprocess.PIPE,stdout=subprocess.PIPE,text=True)
    try:
        if process.stdout.readline().strip()!='LOCKED': raise RuntimeError('Private server configuration lock is busy')
        yield
    finally:
        process.communicate(timeout=10)

def main():
    p=argparse.ArgumentParser(); p.add_argument('mode',choices=['plan','apply','verify']); p.add_argument('--out',type=Path,required=True)
    a=p.parse_args()
    with config_lock(a.mode=='apply'):
        install(a)

def install(a):
    files,c=plan(); a.out.mkdir(parents=True,exist_ok=True)
    changes=[]
    backup=SERVER/'backups'/('wardrobe-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S'))
    for rel,data in files.items():
        dest=SERVER/rel; before=dest.read_bytes() if dest.exists() else None
        row={'path':rel,'changed':before!=data,'sha256':hashlib.sha256(data).hexdigest()}
        changes.append(row)
        staging=a.out/rel; staging.parent.mkdir(parents=True,exist_ok=True); staging.write_bytes(data)
        if a.mode=='apply' and before!=data:
            b=backup/rel; b.parent.mkdir(parents=True,exist_ok=True)
            if before is not None: b.write_bytes(before)
            else: b.with_suffix(b.suffix+'.absent').write_bytes(b'')
            temp=dest.with_name(dest.name+'.wardrobe-tmp'); temp.write_bytes(data); temp.replace(dest)
        if a.mode=='verify': assert before==data,rel
    report={'mode':a.mode,'server':str(SERVER),'backup':str(backup) if a.mode=='apply' else None,'files':changes,
            'counts':{k:len(v) for k,v in c['categories'].items()}}
    (a.out/'report.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    print(json.dumps(report))
if __name__=='__main__': main()
