"""Plan/apply HJ appearance additions to the private CY server with hash guards."""
from pathlib import Path
import argparse, datetime, hashlib, json, sys
ROOT=Path(__file__).resolve().parents[2]
sys.path[:0]=[str(ROOT/'Tools/game'),str(ROOT/'Tools/server/wardrobe'),str(ROOT/'Tools/reapply/ride')]
from hj_appearance_data import PACK,OUT,sha,json_write
from wardrobe_catalog import build,lua
from install import config_lock
import ride_axis as R
SERVER=Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913')

class TextTable:
    def __init__(self,path):
        self.path=path;self.raw=path.read_bytes();lines=self.raw.split(b'\n')
        self.header=[x.rstrip(b'\r') for x in lines[:2]]
        self.names=self.header[1].decode('gbk').split('\t')
        self.rows={}
        for line in lines[2:]:
            line=line.rstrip(b'\r');key=line.split(b'\t')[0]
            if not key.lstrip(b'-').isdigit():continue
            id=int(key);assert id not in self.rows,(path,id);self.rows[id]=line
        self.added={}
    def append(self,row):
        cells=[x if isinstance(x,bytes) else str(x).encode('gbk') for x in row]
        id=int(cells[0]);raw=b'\t'.join(cells)
        if id in self.rows:assert self.rows[id]==raw,('server ID collision',str(self.path),id)
        if id in self.added:assert self.added[id]==raw
        self.added[id]=raw
    def output(self):
        rows=dict(self.rows);rows.update(self.added)
        return b'\r\n'.join(self.header+[rows[k] for k in sorted(rows)])+b'\r\n'

def plan():
    deltas=json.loads((PACK/'server-rows.json').read_text(encoding='utf8'))
    mapping=json.loads((PACK/'mapping.json').read_text(encoding='utf8'))
    tables={}
    def table(n):
        if n not in tables:tables[n]=TextTable(SERVER/'configs'/(n+'.txt'))
        return tables[n]
    for name,rows in deltas.items():
        for row in rows:table(name).append(row)
    eb=table('EquipBase')
    for cat in ['fashion','weapons']:
        for entry in mapping[cat]:
            base=entry.get('template',entry['source_item']);cells=eb.rows[base].split(b'\t')
            id=entry['item'];cells[0]=str(id).encode();cells[3]=str((id%100000)//1000).encode();cells[4]=str(id%1000).encode()
            cells[6]=str(entry['visual']).encode();cells[10]=entry['name'].encode('gbk');cells[21]=entry['icon'].encode()
            if cat=='fashion':cells[12]=b'-1';cells[13]=b'HJ wardrobe'
            eb.append(cells)
    si=table('StandardImpact');slots=R.si_param_slots(si.names)
    assert slots and len(si.names)==81
    templates={};used=set(si.rows);next_id=48000;existing_impacts={}
    for id,line in sorted(si.rows.items()):
        c=R.si_fit(line.split(b'\t'));params=R.si_params(c,slots)
        if c[2]==b'14' and c[6]==b'99' and R.P_RIDE in params and R.P_SPEED in params:
            templates.setdefault(params[R.P_SPEED],c)
            if c[5]==b'-1':existing_impacts.setdefault((params[R.P_RIDE],params[R.P_SPEED]),id)
    assert all(t in templates for t in R.TIERS),(sorted(templates),R.TIERS)
    hjride=__import__('hj_appearance_data').RawTable(__import__('hj_appearance_data').HJ/'Config/Exterior_Ride.txt')
    for entry in mapping['mounts']:
        r=hjride.byid[entry['source']][:];r[0]=entry['id'];r[7]=(entry['name']+' [HJ]').encode('gbk');r[8]=entry['icon'].encode();r[10]=entry['mount']
        r.append(-1)
        old_ride=table('Exterior_Ride').rows.get(entry['id'])
        old_ride=old_ride.split(b'\t') if old_ride else None
        for tier,col in zip(R.TIERS,[15,16,17,19,20,21,22,23,26]):
            if old_ride:
                impact=int(old_ride[col]);current=si.rows[impact].split(b'\t');params=R.si_params(current,slots)
                assert current[2]==b'14' and params[R.P_RIDE]==entry['mount'] and params[R.P_SPEED]==tier
                r[col]=impact;continue
            if (entry['mount'],tier) in existing_impacts:
                r[col]=existing_impacts[(entry['mount'],tier)];continue
            while next_id in used:next_id+=1
            assert next_id<63000,'No free ride impact ID below private reserved range'
            c=templates[tier][:];c[0]=str(next_id).encode();c[1]=r[7];c[5]=b'-1';c[23]=b'0';c[24]=b'0'
            assert R.si_set_param(c,slots,R.P_RIDE,entry['mount'])
            assert R.si_set_param(c,slots,R.P_SPEED,tier)
            si.append(c);used.add(next_id);r[col]=next_id;next_id+=1
        r[18]=-1;r[24]=-1;r[25]=-1
        table('Exterior_Ride').append(r)
    files={'configs/'+n+'.txt':t.output() for n,t in tables.items()}
    c=build(ROOT)
    files['Game_2/Script/scripts/wardrobe_catalog.lua']=('return '+lua(c['categories'])+'\n').encode('utf8')
    files['Game_2/Script/scripts/wardrobe.lua']=(ROOT/'Tools/server/wardrobe/wardrobe.lua').read_bytes()
    rel='GameServer/services/login/packet.lua';packet=(SERVER/rel).read_text(encoding='utf8')
    if '-- CYS-FULL-HAIR-ID' not in packet:
        start=packet.index('\t\t\tif char.hair >= 255 then')
        end=packet.index('            stream:writeshort(char.head or 0)',start)
        packet=packet[:start]+'''            -- CYS-FULL-HAIR-ID: keep the native 32-bit hairstyle below intact.
            -- The legacy byte is only a compact compatibility field.
            local hair = char.hair or 0
            stream:writeuchar((hair >= 0 and hair <= 255) and hair or 0)
'''+packet[end:]
    files[rel]=packet.encode('utf8')
    return files,{n:len(t.added) for n,t in tables.items()}

def main():
    p=argparse.ArgumentParser();p.add_argument('mode',choices=['plan','apply','verify']);p.add_argument('--out',type=Path,default=OUT/'server');a=p.parse_args()
    a.out.mkdir(parents=True,exist_ok=True)
    if a.mode=='plan':
        files,counts=plan();manifest={}
        for rel,data in files.items():
            target=SERVER/rel;dest=a.out/rel;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(data)
            manifest[rel]={'before':sha(target.read_bytes()),'after':sha(data)}
        json_write(a.out/'plan.json',{'server':str(SERVER),'files':manifest,'counts':counts})
        print(json.dumps(counts));return
    m=json.loads((a.out/'plan.json').read_text(encoding='utf8'))
    assert m['server']==str(SERVER)
    with config_lock(a.mode=='apply'):
        for rel,hashes in m['files'].items():
            assert sha((a.out/rel).read_bytes())==hashes['after']
            actual=sha((SERVER/rel).read_bytes())
            assert actual in ([hashes['before'],hashes['after']] if a.mode=='apply' else [hashes['after']]),('changed server baseline',rel)
        if a.mode=='apply':
            backup=SERVER/'backups'/('hj-import-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S'))
            for rel,hashes in m['files'].items():
                dst=SERVER/rel
                if sha(dst.read_bytes())==hashes['after']:continue
                b=backup/rel;b.parent.mkdir(parents=True,exist_ok=True);b.write_bytes(dst.read_bytes())
                tmp=dst.with_name(dst.name+'.hj-tmp');tmp.write_bytes((a.out/rel).read_bytes());tmp.replace(dst)
            json_write(a.out/'applied.json',{'backup':str(backup),'files':m['files']})
    print('PASS',a.mode,len(m['files']),'files')

if __name__=='__main__':
    sys.stdout.reconfigure(encoding='utf8');main()
