"""Read-only CY reference extraction for the four power systems."""
from pathlib import Path
import re,sys,json,hashlib
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'Tools/game'))
from dbc_inventory import Table
CY=ROOT.parent/'Tools/DATA NEW/DataCY31-08-26'
def lua(x):
    if isinstance(x,dict):return '{'+','.join('['+lua(k)+']='+lua(v) for k,v in x.items())+'}'
    if isinstance(x,list):return '{'+','.join(map(lua,x))+'}'
    if isinstance(x,str):return json.dumps(x,ensure_ascii=False)
    return str(x).lower()
def extract():
    source=CY/'tlbb15/Public/Data/Script/NewHJ_Script/EquipmentRelated/ShenMuWangDing/ShenMuWangDing.lua'
    text=source.read_text(encoding='gbk')
    pills=re.findall(r'\[(\d+)\]\s*=\s*\{ MaxCount=\d+, NingLianValue=(\d+),ConEffect=(\d+),',text)
    attack=[int(v) for v in re.search(r'x901000_g_AttrDanParam\s*=\s*\{([^}]+)',text).group(1).replace('\n','').split(',') if v.strip()]
    assert len(pills)==len(attack)==45
    ding=[dict(cost=int(p[1]),con=int(p[2]),attack=attack[i]) for i,p in enumerate(pills)]
    common=Table(CY/'Config/CommonItem.txt').rows
    dust={};gold={'con':{},'attack':{}}
    for r in common:
        if r[6] in ['玄机药尘','苍鹤药魄','冰髓药灵','天悔药魂']:
            amount=re.search(r'获得#G(\d+)点',r[7]);assert amount
            dust[r[0]]=int(amount.group(1))
        if r[6] in ['乾元金丹','坤武金丹']:gold['con' if r[6]=='乾元金丹' else 'attack'][r[0]]=1
    assert len(dust)==8 and len(gold['con'])==2 and len(gold['attack'])==2
    pet=Table(ROOT.parent/'client_GL/Data/ConfigFolder/PetSoulExtension.txt')
    souls=Table(ROOT.parent/'client_GL/Data/ConfigFolder/PetSoulBase.txt')
    names={r[0]:r[6] for r in Table(ROOT.parent/'client_GL/Data/ConfigFolder/CommonItem.txt').rows if r[0] in range(38002515,38002530)}
    result={'ding':ding,'dust':dust,'gold':gold,'soul_text':{r[0]:r[16] for r in pet.rows},'soul_maxlife':{r[0]:r[2] for r in souls.rows},'soul_material_name':names}
    evidence={'source':str(source),'sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'dust':dust,'gold':gold}
    return '-- Generated from CY reference by power_data.py.\nreturn '+lua(result)+'\n',evidence
if __name__=='__main__':
    text,e=extract();print(json.dumps(e,ensure_ascii=False,indent=2))
