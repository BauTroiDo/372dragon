"""Read-only inventory of HJ appearance tables against the current CY Play baseline."""
from pathlib import Path
import collections, datetime, hashlib, json, sys
from dbc_inventory import Table

ROOT = Path(__file__).resolve().parents[2]
HJ = ROOT.parent/'Tools/DATA NEW/CYHJ091026'
CY = ROOT/'Assets/CanonicalCY/Data/ConfigFolder'
PLAY = ROOT/'Build/world-gui/stage-play-21'
OUT = ROOT/'Build/Logs/2026-09-25-hj-import'
TABLES = '''EquipBase EquipDress ItemVisualChar DressColorRate SpecialDressEffect
Exterior_Face CharFaceGeo Exterior_Hair CharHairGeo Exterior_Head CharHead CharacterFace
Exterior_TS Exterior_BG ItemOrnamentsVisual Exterior_Weapon Exterior_WeaponGroup ItemVisualLocator
Exterior_Ride CharMount CharModelEx WuhunWg WuhunWgLevel Exterior_Poss Exterior_PetPoss
PetPossColourRate PetExterior PetHuanhuaTable EquipMoodAction ItemLocatorAction ChatMood
SpecialMountDisplay SpecialEquipVisiblRule Exterior_WeaponItem Exterior_ExchangeItem'''.split()

def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    baseline = OUT/'baseline.json'
    if not baseline.exists():
        baseline.write_text(json.dumps({'at':datetime.datetime.now().astimezone().isoformat(),
            'play':str(PLAY),'game':sha(PLAY/'Bin64/Game.exe'),
            'manifest':sha(PLAY/'Bin64/game_data_stage.json')},indent=2),encoding='utf8')
    report={}
    for name in TABLES:
        entry={}
        for label, cfg in [('HJ',HJ/'Config'),('CY',CY),('Play',PLAY/'Overlay/Post/ConfigFolder')]:
            path=cfg/(name+'.txt')
            if not path.exists(): continue
            t=Table(path)
            names=t.names
            if label=='HJ':
                names=path.read_bytes().split(b'\n')[1].rstrip(b'\r').decode('gbk',errors='replace').split('\t')
            entry[label]={'rows':t.records,'fields':len(t.types),'types':t.types,'names':names,
                'sha256':t.sha256,'sample':t.rows[:2]+t.rows[-3:],
                'max_id':max((r[0] for r in t.rows),default=None)}
            if name=='EquipBase':
                entry[label]['types_count']=dict(collections.Counter(r[4] for r in t.rows))
                entry[label]['slots_count']=dict(collections.Counter(r[5] for r in t.rows))
        report[name]=entry
    (OUT/'tables.json').write_text(json.dumps(report,ensure_ascii=False,indent=1),encoding='utf8')
    for name,entry in report.items():
        print(name, ' | '.join(f'{k}: {v["rows"]}x{v["fields"]} max={v["max_id"]}' for k,v in entry.items()))
    print('Details:',OUT/'tables.json')

if __name__=='__main__':
    sys.stdout.reconfigure(encoding='utf8')
    main()
