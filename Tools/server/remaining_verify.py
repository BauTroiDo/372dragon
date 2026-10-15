"""Read-only cumulative runtime verification, after the HJ05 continuation."""
from pathlib import Path
import concurrent.futures,datetime,hashlib,json,subprocess
ROOT=Path(__file__).resolve().parents[2];LOG=ROOT/'Build/Logs/2026-09-28-hj05-remaining'
OLD=ROOT/'Build/Logs/2026-09-28-hj05-fixes';R='/home/ubuntu/cys-test-20260913';TOOLS='/mnt/c/TLBB/085/CY-Source/Tools/server'
LIVE=Path('//wsl.localhost/TLBB')/R.lstrip('/')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
    out=LOG/('verify-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S'));out.mkdir()
    rows={r['path']:r for r in json.loads((OLD/'server/manifest.json').read_text())}
    rows.update({r['path']:r for r in json.loads((LOG/'deployed-manifest.json').read_text())})
    stall=ROOT/'Build/Logs/2026-09-28-hj05-stall'
    if (stall/'applied.json').exists():
        for r in json.loads((stall/'manifest.json').read_text()):
            assert rows[r['path']]['after']==r['before'],'Stall patch baseline mismatch'
            rows[r['path']]=r
    for rel,row in rows.items():assert sha(LIVE/rel)==row['after'],rel
    assert json.loads((LOG/'server/manifest.json').read_text())==json.loads((LOG/'deployed-manifest.json').read_text())
    (LOG/'runtime-manifest.json').write_text(json.dumps(list(rows.values()),indent=2))
    syntax=[]
    for rel in rows:
        p=subprocess.run(['wsl','-d','TLBB','-u','root','--','luac','-p',R+'/'+rel],capture_output=True)
        syntax.append(dict(path=rel,exit=p.returncode,output=(p.stdout+p.stderr).decode('utf8','replace')))
    (out/'syntax.json').write_text(json.dumps(syntax,indent=2))
    jobs={'remaining_shop_tests':[R,R],'remaining_soul_tests':[R,TOOLS],'test_power':[R,R],
        'hj05_regression':[R],'hj05_pet_bank_tests':[R],'pet_integrity_tests':[R,R+'/GameServer/lualib'],'social_trade_test':[R,R]}
    if (stall/'applied.json').exists():jobs['check_hj05_stall_currency']=[R]
    def run(job):
        name,args=job;p=subprocess.run(['wsl','-d','TLBB','-u','root','--','lua',TOOLS+'/'+name+'.lua']+args,capture_output=True,timeout=100)
        raw=p.stdout+p.stderr;(out/(name+'.txt')).write_bytes(raw)
        return dict(name=name,exit=p.returncode,tail=raw.decode('utf8','replace').splitlines()[-2:])
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:tests=list(pool.map(run,jobs.items()))
    report=dict(server_manifest_sha256=sha(LOG/'server/manifest.json'),runtime_manifest_sha256=sha(LOG/'runtime-manifest.json'),
        runtime_hashes_match=len(rows),syntax_pass=all(x['exit']==0 for x in syntax),tests=tests)
    if (stall/'applied.json').exists():report['stall_manifest_sha256']=sha(stall/'manifest.json')
    report['passed']=report['syntax_pass'] and all(x['exit']==0 for x in tests)
    (out/'report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2));print(json.dumps(report,ensure_ascii=False));print('Evidence',out)
    raise SystemExit(0 if report['passed'] else 1)
if __name__=='__main__':main()
