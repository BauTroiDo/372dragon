"""Fix the reproduced Lua 5.3 %d failure in stall currency receipts, separately."""
from pathlib import Path
import argparse,datetime,hashlib,json,re,shutil,subprocess
from inventory_integrity import function
ROOT=Path(__file__).resolve().parents[2]
LIVE=Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913')
LOG=ROOT/'Build/Logs/2026-09-28-hj05-stall'
REL='GameServer/services/scene/scenecore.lua'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
    p=argparse.ArgumentParser();p.add_argument('mode',choices=['plan','apply']);a=p.parse_args()
    base=LOG/'baseline'/REL;base.parent.mkdir(parents=True,exist_ok=True)
    if not base.exists():shutil.copy2(LIVE/REL,base)
    raw=base.read_text(encoding='utf8')
    def patch(body):
        for name in ('Gold','Silver'):
            body,n=re.subn(r'(local '+name+r'\s*=\s*)(\([^\n]+\))',r'\1math.floor(\2)',body)
            assert n==2,(name,n)
        assert body.count('%d kim %d ngân %d đồng')==2
        return body.replace('%d kim %d ngân %d đồng','%d Võ Thạch thượng phẩm %d trung phẩm %d hạ phẩm')
    out=LOG/'server'/REL;out.parent.mkdir(parents=True,exist_ok=True)
    out.write_text(function(raw,'scenecore:char_stall_buy',change=patch),encoding='utf8',newline='\n')
    row=dict(path=REL,before=sha(base),after=sha(out))
    (LOG/'manifest.json').write_text(json.dumps([row],indent=2))
    if a.mode=='apply':
        s=json.loads(subprocess.check_output(['wsl','-d','TLBB','-u','root','--','python3',
             '/mnt/c/TLBB/085/CY-Source/Tools/server/provision_test_wsl.py','status']))
        assert not next(x for x in s['services'] if x['name']=='Game')['running'],'Stop private Game before apply'
        assert sha(LIVE/REL)==row['before'],'Runtime changed since baseline'
        b=ROOT/'Build/backups/hj05-stall'/datetime.datetime.now().strftime('%Y%m%d-%H%M%S')/REL
        b.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(LIVE/REL,b);shutil.copy2(out,LIVE/REL)
        assert sha(LIVE/REL)==row['after']
        (LOG/'applied.json').write_text(json.dumps(dict(backup=str(b),**row),indent=2))
        print('Applied with backup',b)
    print(json.dumps(row))
if __name__=='__main__':main()
