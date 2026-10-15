"""Offline source-contract diagnostics; no sockets, database or live messages."""
from pathlib import Path
import hashlib, json, subprocess

root = Path('/home/ubuntu/cys-test-20260913/GameServer')
out = Path('/mnt/c/TLBB/085/CY-Source/Build/Logs/2026-10-01-runtime-audit')
gm = root / 'lualib/GMCommand.lua'
ma = root / 'services/msgagent.lua'
world = root / 'services/world/worldcore.lua'
net = root / 'lualib/net.lua'

def function_block(path, signature):
    text = path.read_text(encoding='utf8')
    start = text.index(signature)
    end = text.index('\nfunction ', start + len(signature))
    return text[start:end]

code = r'''
package.preload.wire_charset=function() return {toutf8=function(s) return s end} end
package.preload.class=function() return function() return {} end end
package.preload.define=function() return {INVAILD_ID=-1} end
for _,name in ipairs({'configenginer','impactenginer'}) do
 package.preload[name]=function() return {getinstance=function() return {} end} end
end
package.preload.human_item_logic=function() return {} end
local output=print
local function result(name,value) output('RESULT '..name..'='..tostring(value)) end
print=function() end
local gm=dofile(GM_PATH)
local calls=0
local human={get_money=function() return 100 end, get_yuanbao=function() return 100 end,
 notify_tips=function() calls=calls+1 end,
 get_world_pos=function() return {x=1,y=1} end,
 get_scene=function() return {create_temp_monster=function() return -1 end,get_obj_by_id=function() return nil end} end,
 skill_create_obj_specail=function() return nil end,
 change_scene=function(_,id,pos) assert(id==2 and pos.x==100 and pos.y==100);calls=calls+1 end}
gm:process(human,'帮助@')
result('gm_help_no_response',calls==0)
local ok=pcall(gm.process,gm,human,'获取金币@invalid')
result('gm_bad_money_raises_lua_error',not ok)
ok=pcall(gm.process,gm,human,'获取YB@invalid')
result('gm_bad_yuanbao_raises_lua_error',not ok)
ok=pcall(gm.process,gm,human,'创建怪物@99999999@1')
result('gm_missing_monster_raises_lua_error',not ok)
ok=pcall(gm.process,gm,human,'创建陷阱@99999999@1')
result('gm_missing_trap_raises_lua_error',not ok)
gm:process(human,'tp@2@100@100')
result('gm_valid_tp_dispatches',calls==1)
local sends=0
local request,ma_func,skynet={},{get_guid=function() return 200016 end},{send=function() sends=sends+1 end}
MAIL_HANDLER
for i=1,3 do request.CGMail({guid=200016,dest='synthetic',content='offline'}) end
result('mail_handler_forwards_each_repeat',sends==3)
local worldcore={get_db_user_by_name=function() return {attrib={guid=1}} end,find_user_by_name=function() return nil end}
MAIL_INSERT
MAIL_SEND
sends=0
for i=1,3 do worldcore:send_mail({guid=200016,dest='synthetic',content='offline'}) end
result('mail_world_enqueues_each_repeat',sends==3)
local net={}
MAIL_FILTER
local packet={guid=200016}
result('common_filter_does_not_limit_repeated_mail',net:filter_packet('CGMail',packet)==packet and net:filter_packet('CGMail',packet)==packet)
'''
code = code.replace('GM_PATH',json.dumps(str(gm)))
code = code.replace('MAIL_HANDLER',function_block(ma,'function request:CGMail()'))
code = code.replace('MAIL_INSERT',function_block(world,'function worldcore:insert_mail(guid, mail)'))
code = code.replace('MAIL_SEND',function_block(world,'function worldcore:send_mail(mail)'))
net_text=net.read_text(encoding='utf8')
code = code.replace('MAIL_FILTER',net_text[net_text.index('function net:filter_packet'):].split('\nreturn net')[0])
script = out / 'offline-contracts.lua'
script.write_text(code,encoding='utf8')
run = subprocess.run(['lua',str(script)],capture_output=True,text=True,check=True)
checks = dict(line.removeprefix('RESULT ').split('=',1) for line in run.stdout.splitlines() if line.startswith('RESULT '))
report = dict(scope='Actual source functions with synthetic dependencies; no live sends or DB writes',
              findings={k:v=='true' for k,v in checks.items()},
              sources={str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in (gm,ma,world,net)})
assert len(checks)==9 and all(report['findings'].values()),report
(out/'offline-contracts.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print(json.dumps(report['findings'],indent=2))
