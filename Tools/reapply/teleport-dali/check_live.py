from pathlib import Path
import argparse,json,re,sys
ap=argparse.ArgumentParser()
ap.add_argument('--a',type=Path,required=True)
ap.add_argument('--b',type=Path,required=True)
args=ap.parse_args()
def inspect(root,arm):
    run=json.loads((root/'run.json').read_text(encoding='utf-8-sig'))
    lines=(root/'WXClient.log').read_text(encoding='utf-8',errors='replace').splitlines()
    rows=[]
    starts=[]
    for i,line in enumerate(lines):
        m=re.search(r'ROUND (\d+) returned scene=(\d+) pos=([\d.-]+),([\d.-]+) ground-click BEGIN',line)
        if m:starts.append((i,int(m[1]),int(m[2]),float(m[3]),float(m[4])))
    for start,n,scene,x,z in starts:
        ends=[i for i in range(start+1,len(lines)) if re.search(r'ROUND '+str(n)+r' ground-click END ',lines[i])]
        if len(ends)!=1:rows.append({'round':n,'error':'missing or duplicate END'});continue
        end=ends[0]
        prior=[int(m[1]) for line in lines[:start] if (m:=re.search(r'\bself_moves=(\d+)',line))]
        later=[int(m[1]) for line in lines[end+1:] if (m:=re.search(r'\bself_moves=(\d+)',line))]
        delta=float(re.search(r'delta2=([\d.-]+)',lines[end])[1])
        click=sum('CYS: click-move' in line for line in lines[start:end+1])
        refused=sum('fly refused' in line and 'unreachable' in line for line in lines[start:end+1])
        moved=later[0]-prior[-1] if prior and later else None
        wanted=(241,141) if arm=='A' else (253,121)
        at_spawn=scene==2 and abs(x-wanted[0])<.1 and abs(z-wanted[1])<.1
        ok=at_spawn and ((click==0 and moved==0 and delta<.25) if arm=='A' else (click>=1 and moved is not None and moved>=1 and delta>=.25 and refused==0))
        rows.append({'round':n,'scene':scene,'spawn':[x,z],'click_moves':click,'self_moves_delta':moved,'position_delta2':delta,'unreachable':refused,'ok':ok})
    errors=[int(m[1]) for line in lines if (m:=re.search(r'\bhandler_errors=(\d+)',line))]
    expected=[1] if arm=='A' else [1,2,3]
    ok=(bool(run.get('game_sha256')) and run.get('account')=='test14' and run.get('exit_code')==0 and
        not run.get('terminated_after_timeout') and not run.get('dumps') and errors and max(errors)==0 and
        [r['round'] for r in rows]==expected and all(r.get('ok') for r in rows))
    return {'arm':arm,'telemetry_ok':bool(ok),'rows':rows,'game_sha256':run.get('game_sha256'),'manifest_sha256':run.get('stage_manifest_sha256'),
            'run_exit':run.get('exit_code'),'timeout':run.get('terminated_after_timeout'),'handler_errors_max':max(errors) if errors else None}
try:
    a=inspect(args.a,'A');b=inspect(args.b,'B')
    same=(a['game_sha256']==b['game_sha256'] and a['manifest_sha256']==b['manifest_sha256'])
    ok=a['telemetry_ok'] and b['telemetry_ok'] and same
    result={'telemetry_ok':ok,'same_binary_and_manifest':same,'a':a,'b':b,'visual_inspection':'Required separately: return screenshots and movement.'}
except (OSError,ValueError,KeyError,TypeError,AttributeError) as e:
    result={'telemetry_ok':False,'error':str(e)};ok=False
print(json.dumps(result,ensure_ascii=False,indent=2))
sys.exit(0 if ok else 1)
