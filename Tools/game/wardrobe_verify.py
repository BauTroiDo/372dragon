"""Verify a completed real game run, including the wardrobe-specific assertions.

The general world rig passing is insufficient: it does not know wardrobe checks.
Never use this reader on an active stage's log.
"""
import argparse, json, re
from pathlib import Path

def verify(folder, arm, mount=False):
    run=json.loads((folder/'run.json').read_text(encoding='utf-8-sig'))
    text=(folder/'WXClient.log').read_bytes().decode('utf-8','replace')
    checks=re.findall(r'CYS-WARDROBE-PROBE: check=(\S+) cat=(\d+) pass=(\d)',text)
    results=re.findall(r'CYS-WARDROBE-PROBE: RESULT errors=(\d+) distance=([\d.]+)',text)
    errors=[]
    if not run['passed']: errors.append('general world gate failed')
    if len(results)!=1: errors.append('expected one fresh completed wardrobe run')
    if 'CYS Lua failure' in text: errors.append('Lua failure')
    if 'CYS-CRASHRPT:' in text: errors.append('crash')
    failed=[(name,int(cat)) for name,cat,ok in checks if ok=='0']
    types={9} if mount else set(range(1,8))
    expected=[('acquired',cat) for cat in sorted(types)] if arm=='negative' else []
    if failed!=expected: errors.append({'unexpected_assertions':failed,'expected':expected})
    if results and (int(results[0][0])!=len(expected) or float(results[0][1])<0.5): errors.append('result/movement mismatch')
    snapshots={int(cat) for name,cat,ok in checks if name=='server-snapshot' and ok=='1'}
    if snapshots!=({8,9} if mount else set(range(1,9))): errors.append('incomplete category snapshots')
    if arm=='acquire':
        for phase in (['acquired','applied'] if mount else ['acquired','applied','world-appearance-applied']):
            cats={int(cat) for name,cat,ok in checks if name==phase and ok=='1'}
            if cats!=types: errors.append('incomplete '+phase)
    if arm=='relogin':
        for phase in (['owned-after-relogin','current-after-relogin'] if mount else ['owned-after-relogin','current-after-relogin','world-appearance-after-relogin']):
            cats={int(cat) for name,cat,ok in checks if name==phase and ok=='1'}
            if cats!=types: errors.append('incomplete '+phase)
    if mount:
        if ('preview-keeps-world','9','1') not in checks: errors.append('missing isolated mount preview')
        for phase in ['alternate-mount-preview-entity','mount-preview-entity']:
            if (phase,'9','1') not in checks: errors.append('incomplete '+phase)
        if not list(folder.glob('*ward-preview-9.png')): errors.append('missing mount preview screenshot')
        if arm!='negative':
            for phase in ['mounted-model','mount-ack','dismounted-model','dismount-ack']:
                if (phase,'9','1') not in checks: errors.append('incomplete '+phase)
            if not list(folder.glob('*ward-mounted-world-9.png')): errors.append('missing mounted world screenshot')
    if not list(folder.glob('*ward-event-only-8.png')): errors.append('missing event-only screenshot')
    report={'folder':str(folder.resolve()),'arm':arm,'mount':mount,'checks':len(checks),'failed_assertions':failed,
            'result':results,'errors':errors,'passed':not errors}
    (folder/'wardrobe-verdict.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(report,ensure_ascii=False))
    return not errors

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('folder',type=Path);p.add_argument('--arm',choices=['browse','negative','acquire','relogin'],required=True)
    p.add_argument('--mount',action='store_true')
    a=p.parse_args();raise SystemExit(0 if verify(a.folder,a.arm,a.mount) else 1)
