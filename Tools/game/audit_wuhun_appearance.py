"""Read-only reference evidence for soul appearance (CY assets, GL UI, live config)."""
from pathlib import Path
import json
from dbc_inventory import Table
ROOT=Path(__file__).resolve().parents[2]
CY=ROOT/'Assets/CanonicalCY/Data/ConfigFolder'
GL=ROOT.parent/'client_GL/Data/ConfigFolder'
SERVER=Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913/configs')
def main():
    out={}
    for label,folder in [('CY',CY),('GL',GL),('server',SERVER)]:
        for name in ['KFSBase.txt','WuhunWg.txt','WuhunWgLevel.txt']:
            p=folder/name
            if p.exists():
                t=Table(p);out[label+'/'+name]={'names':t.names,'rows':t.rows}
    for label,folder in [('CY',CY),('GL',GL)]:
        t=Table(folder/'ItemVisualLocator.txt')
        out[label+'/KFSLocators']={'names':t.names,'rows':[r for r in t.rows if r[9] and r[9]!='-1']}
    dest=ROOT/'Build/Logs/2026-09-25-wuhun-appearance/reference-tables.json'
    dest.write_text(json.dumps(out,ensure_ascii=False,indent=1),encoding='utf8')
    for k,v in out.items():
        print(k,len(v['rows']),'rows')
        if 'WuhunWgLevel' not in k and 'KFSLocators' not in k:print(json.dumps(v,ensure_ascii=False))
        elif 'KFSLocators' in k:print(json.dumps(v['rows'][:14],ensure_ascii=False))
if __name__=='__main__':main()
