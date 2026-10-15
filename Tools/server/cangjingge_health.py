"""Record private service health and error counts without account traffic."""
from pathlib import Path
import datetime,hashlib,json,re,subprocess
ROOT=Path(__file__).resolve().parents[2];LOG=ROOT/'Build/Logs/2026-09-29-cangjingge'
state=json.loads(subprocess.check_output(['wsl','-d','TLBB','-u','root','--','python3',
 '/mnt/c/TLBB/085/CY-Source/Tools/server/provision_test_wsl.py','status']))
state['at']=datetime.datetime.now().astimezone().isoformat()
state['healthy']=all(s['running'] and not s['duplicate'] and s['pid_file_matches'] for s in state['services']) and all(state['ports'].values())
(LOG/'health.json').write_text(json.dumps(state,indent=2))
folder=Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913/log')
p=max(folder.glob('*/Game2_*.log'),key=lambda x:x.stat().st_mtime)
raw=p.read_bytes();errors=[l for l in raw.splitlines() if b'[E]' in l]
types=sorted({int(n) for line in errors for n in re.findall(rb'\b4928[5-9]\b',line)})
known=all(re.search(rb'\b4928[5-9]\b',line) and b'monster' in line.lower() for line in errors)
result=dict(log=p.name,at=state['at'],sha256=hashlib.sha256(raw).hexdigest(),tracebacks=len(re.findall(rb'stack traceback',raw)),
 error_lines=len(errors),monster_types=types,known_missing_monsters_only=bool(errors) and known)
(LOG/'boot-log-summary.json').write_text(json.dumps(result,indent=2))
print(json.dumps(dict(healthy=state['healthy'],boot=result)))
assert state['healthy'] and not result['tracebacks'] and (not errors or known)
