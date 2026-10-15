"""Check changed Lua using the actual LuaPlus parser and deterministic slot mocks."""
from pathlib import Path
import json,subprocess,sys,hashlib
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'Build/Logs/2026-10-01-runtime-fixes'
stage=ROOT/'Build/world-gui/stage-runtime-fixes-01'
paths=[stage/f'Overlay/{p}/InterfaceFolder/Packet/Packet.lua' for p in ('Pre','Post')]
(OUT/'ui-syntax-files.txt').write_text('\n'.join(str(p) for p in paths),encoding='utf8')
exe=ROOT/'Build/Logs/2026-09-22-residual-audit/client-syntax-native/lua_syntax_audit.exe'
r=subprocess.run([str(exe),str(OUT/'ui-syntax-files.txt')],capture_output=True,text=True)
(OUT/'ui-syntax.log').write_text(r.stdout+r.stderr,encoding='utf8');assert r.returncode==0,r.stdout+r.stderr
text=paths[0].read_text(encoding='utf8');fn=text[text.index('function Packet_UpdateChangedSlot(raw)'):]
script='''
local checks=0
local function check(v) assert(v);checks=checks+1 end
local changed,disabled,full,locked,empty=0,false,0,false,false
nTheTabIndex=0
DataPool={GetBaseBag_Num=function() return 100 end,GetMatBag_Num=function() return 100 end,GetTaskBag_Num=function() return 20 end}
PlayerPackage={EnumItem=function(_,name,index)return {GetID=function() return empty and 0 or index+1 end},locked and 1 or 0 end}
PACKAGE_BUTTONS={};for i=1,100 do PACKAGE_BUTTONS[i]={SetActionItem=function(_,id)changed=changed+1 end,Disable=function()disabled=true end,Enable=function()disabled=false end} end
Packet_Classify={Enable=function()end,Disable=function()end}
function Packet_ChangeTabIndex()full=full+1 end
'''+fn+'''
Packet_UpdateChangedSlot('1');check(changed==1 and full==0)
Packet_UpdateChangedSlot('99');check(changed==2 and full==0)
Packet_UpdateChangedSlot('100');check(changed==2 and full==0)
locked=true;Packet_UpdateChangedSlot('1');check(disabled and Lock_Flag==1)
locked=false;empty=true;Packet_UpdateChangedSlot('1');check(not disabled and Lock_Flag==0)
nTheTabIndex=1;Packet_UpdateChangedSlot('100');check(changed==5)
nTheTabIndex=2;Packet_UpdateChangedSlot('219');check(changed==6)
Packet_UpdateChangedSlot(nil);Packet_UpdateChangedSlot('-1');Packet_UpdateChangedSlot('220');check(full==3)
print('PASS slot delta checks='..checks)
'''
(OUT/'ui-delta-tests.lua').write_text(script,encoding='utf8')
r=subprocess.run(['wsl','-d','TLBB','-u','root','--','lua','/mnt/c/TLBB/085/CY-Source/Build/Logs/2026-10-01-runtime-fixes/ui-delta-tests.lua'],capture_output=True,text=True)
assert r.returncode==0,r.stderr
(OUT/'ui-tests.json').write_text(json.dumps(dict(passed=True,syntax='Actual LuaPlus 5.0 parser',slots=r.stdout.strip(),sources=[hashlib.sha256(p.read_bytes()).hexdigest() for p in paths]),indent=2));print(r.stdout.strip())
r=subprocess.run(['wsl','-d','TLBB','-u','root','--','lua','/mnt/c/TLBB/085/CY-Source/Tools/server/runtime_repairs/tests.lua','/mnt/c/TLBB/085/CY-Source/Build/Logs/2026-10-01-runtime-fixes/server'],capture_output=True,text=True)
assert r.returncode==0,r.stderr
(OUT/'server-tests.json').write_text(json.dumps(dict(passed=True,result=r.stdout.strip(),manifest=hashlib.sha256((OUT/'server-manifest.json').read_bytes()).hexdigest()),indent=2));print(r.stdout.strip())
