"""Verify deployed bytes and real Cangjingge callbacks without touching players."""
from pathlib import Path
import hashlib,json,subprocess
ROOT=Path(__file__).resolve().parents[2]
LOG=ROOT/'Build/Logs/2026-09-29-cangjingge'
LIVE=Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
 manifest=json.loads((LOG/'manifest.json').read_text(encoding='utf8'))
 rows=manifest['server']
 for row in rows:assert sha(LIVE/row['path'])==row['after'],row['path']
 results=[]
 for row in rows:
  if row['path'].endswith('.lua'):
   p=subprocess.run(['wsl','-d','TLBB','-u','root','--','luac','-p','/home/ubuntu/cys-test-20260913/'+row['path']],capture_output=True)
   results.append(dict(path=row['path'],exit=p.returncode))
 p=subprocess.run(['wsl','-d','TLBB','-u','root','--','lua','/mnt/c/TLBB/085/CY-Source/Tools/server/cangjingge_tests.lua',
                   '/home/ubuntu/cys-test-20260913','/home/ubuntu/cys-test-20260913'],capture_output=True)
 raw=p.stdout+p.stderr;(LOG/'tests.txt').write_bytes(raw)
 result=dict(passed=p.returncode==0 and all(x['exit']==0 for x in results),manifest=sha(LOG/'manifest.json'),
             test_sha256=sha(ROOT/'Tools/server/cangjingge_tests.lua'),syntax=results,exit=p.returncode,
             output=raw.decode('utf8','replace'))
 (LOG/'tests.json').write_text(json.dumps(result,indent=2),encoding='utf8')
 print(result['output'].strip());assert result['passed']
if __name__=='__main__':main()
