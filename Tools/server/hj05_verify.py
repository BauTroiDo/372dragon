"""Read-only verification of the deployed HJ05 layer; saves every test result."""
from pathlib import Path
import concurrent.futures,datetime,hashlib,json,subprocess
ROOT=Path(__file__).resolve().parents[2]
LIVE=Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913')
LOG=ROOT/'Build/Logs/2026-09-28-hj05-fixes'
R='/home/ubuntu/cys-test-20260913';LIB=R+'/GameServer/lualib'
TOOLS='/mnt/c/TLBB/085/CY-Source/Tools/server/'
jobs={
 'hj05_regression':[R],'hj05_pet_bank_tests':[R],
 'server_impact_tests':[R],'pet_integrity_tests':[R,LIB],
 'pvp_integrity_tests':[R,LIB],'test_equipment_passives':[R,R],
 'test_gameplay_audit':[R,R],'test_power':[R,R],
 'test_equipcraft':[R,R],'test_quest_rewards':[R,R],
 'social_trade_test':[R,R],
}
out=LOG/('verify-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S'));out.mkdir()
rows=json.loads((LOG/'server/manifest.json').read_text())
for row in rows:
    assert hashlib.sha256((LIVE/row['path']).read_bytes()).hexdigest()==row['after'],row['path']
syntax=[]
for row in rows:
    # This host's luac aborts while combining many parsed chunks (-p file1 file2).
    # Parse each complete module separately; no runtime code is executed.
    p=subprocess.run(['wsl','-d','TLBB','-u','root','--','luac','-p',R+'/'+row['path']],capture_output=True)
    syntax.append(dict(path=row['path'],exit=p.returncode,output=(p.stdout+p.stderr).decode('utf8','replace')))
(out/'syntax.json').write_text(json.dumps(syntax,indent=2),encoding='utf8')
def run(job):
    name,args=job
    p=subprocess.run(['wsl','-d','TLBB','-u','root','--','lua',TOOLS+name+'.lua']+args,capture_output=True,timeout=90)
    text=p.stdout+p.stderr;(out/(name+'.txt')).write_bytes(text)
    return dict(name=name,exit=p.returncode,tail=text.decode('utf8','replace').splitlines()[-2:])
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool: results=list(pool.map(run,jobs.items()))
report=dict(server_manifest_sha256=hashlib.sha256((LOG/'server/manifest.json').read_bytes()).hexdigest(),
    runtime_hashes_match=len(rows),syntax_pass=all(r['exit']==0 for r in syntax),tests=results)
(out/'report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8')
print(json.dumps(report,ensure_ascii=False,indent=1));print('Evidence',out)
raise SystemExit(0 if report['syntax_pass'] and all(r['exit']==0 for r in results) else 1)
