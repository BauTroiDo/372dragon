"""Compare every playable CY school and six damage channels by explicit identity."""
import argparse,json,hashlib
from pathlib import Path
from pvp_integrity import base_values,TRAITS
p=argparse.ArgumentParser();p.add_argument('--runtime',type=Path,default=Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913/configs/AttackTraits.txt'));a=p.parse_args()
cy=Path('C:/TLBB/085/Tools/DATA NEW/DataCY31-08-26/Config/AttackTraits.txt')
def rows(path):
    raw=path.read_bytes()
    try:text=raw.decode('utf-8-sig')
    except UnicodeDecodeError:text=raw.decode('gbk')
    result={}
    for line in text.splitlines():
        cells=line.split('\t')
        if cells[0].isdigit():result[int(cells[0])]=[int(x) for x in cells[3:9]]
    assert result
    return result
c,r=rows(cy),rows(a.runtime)
mapping=[0,1,2,3,4,5,6,7,8,9,16,17,18,19,20,15]
report=[]
for school,row in enumerate(mapping):
    cyrow=school if school<10 else school+4
    assert r[row]==c[cyrow],(school,row,r[row],c[cyrow])
    report.append(dict(school=school,cy_row=cyrow,runtime_row=row,coefficients=r[row]))
cybase=cy.parent.parent/'tlbb15/Server/Config/BaseValueTable.ini'
runtimebase=a.runtime.parent/'BaseValueTable.ini'
cb,rb=base_values(cybase.read_bytes()),base_values(runtimebase.read_bytes())
for school in range(16):
    for key in range(40):assert rb[school][key]==cb[school][key],('base',school,key)
    assert rb[school][41]==TRAITS[school],('trait metadata',school)
print(json.dumps(dict(passed=True,channels=96,base_coefficients=640,trait_metadata=16,cy=str(cy),cy_sha256=hashlib.sha256(cy.read_bytes()).hexdigest(),runtime_sha256=hashlib.sha256(a.runtime.read_bytes()).hexdigest(),runtime_base_sha256=hashlib.sha256(runtimebase.read_bytes()).hexdigest(),schools=report),indent=2))
