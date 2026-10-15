"""Read-only checks of deployed level tables and actual GM authorization function."""
from pathlib import Path
import re,subprocess
from cs3b_menpai import provision
R=Path('/home/ubuntu/cys-test-20260913')
s=(R/'Game_2/Script/scripts/GmTool_Self.lua').read_text()
cfg=re.search(r'GmTool_Self.GmCeshi = (.*?);',s,re.S).group(1)
fn=re.search(r'^function GmTool_Self:IsGM\(.*?^end',s,re.M|re.S).group()
with provision().database() as c:
 accounts=[d['uid'] for d in c.tlbb.account.find({'uid':{'$regex':'^test[0-9]+$'}},{'_id':0,'uid':1})]
assert len(accounts)==16
script='local account; local skynet={getenv=function()return "test" end,call=function()return nil,account end}\n'
script+='local GmTool_Self={GmToolIsOpen=true,GmRootLarge={},GmRootIn={},GmRootSmall={}}\n'
script+='GmTool_Self.GmCeshi='+cfg+'\n'+fn+'\n'
script+='function GmTool_Self:get_scene()return {get_obj_by_id=function()return {get_guid=function()return 200016 end} end} end\n'
for account in accounts:
 assert re.fullmatch(r'test[0-9]+',account)
 script+=f'account="{account}";assert(GmTool_Self:IsGM(1)==98,"{account}")\n'
script+='account="ordinary_not_in_allowlist";assert(GmTool_Self:IsGM(1)==0);print("PASS 16 existing test accounts GM98; unlisted account remains ordinary")\n'
subprocess.run(['lua','-'],input=script,text=True,check=True)
def table(name):
 return {int(x.split('\t')[0]):x.split('\t') for x in (R/'configs'/name).read_text(encoding='gbk').splitlines()[2:] if x.strip()}
attrs=table('AttrLevelUpTable.txt');exp=table('PlayerExpLevel.txt')
assert all(len(attrs[i])==86 and attrs[i][1:]==attrs[141+(i-151)%10][1:] for i in range(151,201))
assert all(int(exp[i][1])>0 and int(exp[i][1])*3.5<2**32 for i in range(1,201))
assert 'define.HUMAN_MAX_LEVEL = 201' in (R/'GameServer/lualib/define.lua').read_text()
assert 'HumanMaxDefaultLevel=201' in (R/'configs/ConfigInfo.ini').read_text(encoding='gbk')
print('PASS level1..200 EXP positive and uint32-safe at3.5x; all17 faction attribute growth extended through200')
