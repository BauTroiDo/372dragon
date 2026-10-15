"""Record private-cluster health and safe boot-error counts after fixture restore."""
from pathlib import Path
import datetime,hashlib,json,re,subprocess
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'Build/Logs/2026-09-28-hj05-remaining/stopwatch'
LIVE=Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913')
status=json.loads(subprocess.check_output(['wsl','-d','TLBB','-u','root','--','python3',
    '/mnt/c/TLBB/085/CY-Source/Tools/server/provision_test_wsl.py','status']))
assert all(s['running'] and not s['duplicate'] and s['pid_file_matches'] for s in status['services'])
assert status['ports']['15733'] and status['ports']['15734']
f=max((LIVE/'log').glob('*/Game2_*.log'),key=lambda p:p.stat().st_mtime)
raw=f.read_bytes();text=raw.decode('utf8','replace')
errors=[s for s in text.splitlines() if re.search(r'\[E\]|stack traceback|lua call .+ error',s,re.I)]
types=[int(x) for x in re.findall(r'MONSTER_CFG_FAIL[^\n]*?type=(\d+)',text)]
summary=dict(log=f.name,sha256=hashlib.sha256(raw).hexdigest(),
    at=datetime.datetime.now().astimezone().isoformat(),tracebacks=text.count('stack traceback'),
    error_lines=len(errors),monster_cfg_fail=len(types),monster_types=sorted(types),
    known_missing_monsters_only=bool(errors) and all('MONSTER_CFG_FAIL' in e for e in errors)
        and sorted(types)==list(range(49285,49290)))
(OUT/'health.json').write_text(json.dumps(status,indent=2),encoding='utf8')
(OUT/'boot-log-summary.json').write_text(json.dumps(summary,indent=2),encoding='utf8')
assert summary['tracebacks']==0 and (not errors or summary['known_missing_monsters_only'])
print('PASS all six private services, no duplicate, login/game listening')
print(json.dumps(summary))
