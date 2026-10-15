"""Capture only log boundaries/hashes/counts; never copy account traffic."""
from pathlib import Path
import argparse,hashlib,json,re
ROOT=Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913/log')
ERROR=re.compile(rb'stack traceback|lua call [^\r\n]* error|\[E\]',re.I)

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('mode',choices=['start','check']);p.add_argument('snapshot',type=Path)
    p.add_argument('--out',type=Path);a=p.parse_args()
    if a.mode=='start':
        state={f.relative_to(ROOT).as_posix():f.stat().st_size for f in ROOT.glob('*/*.log')}
        a.snapshot.write_text(json.dumps(state,indent=2),encoding='utf8');return
    assert a.out
    before=json.loads(a.snapshot.read_text(encoding='utf8'));rows=[]
    for f in ROOT.glob('*/*.log'):
        rel=f.relative_to(ROOT).as_posix();offset=before.get(rel,0)
        raw=f.read_bytes();assert len(raw)>=offset,('server log truncated',rel)
        delta=raw[offset:]
        if delta:rows.append(dict(path=rel,start=offset,end=len(raw),sha256=hashlib.sha256(delta).hexdigest(),errors=len(ERROR.findall(delta))))
    result=dict(passed=bool(rows) and not any(r['errors'] for r in rows),files=rows)
    a.out.write_text(json.dumps(result,indent=2),encoding='utf8')
    assert result['passed'],'New server error in this GUI interval; inspect private logs'
    print('PASS server log interval: no Lua traceback or error')

if __name__=='__main__':main()
