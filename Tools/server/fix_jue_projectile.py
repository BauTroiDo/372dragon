"""Private server: honor Jue 4515 projectile travel before damage/death/EXP."""
from pathlib import Path
import datetime,shutil,subprocess
R=Path('/home/ubuntu/cys-test-20260913')
p=R/'GameServer/lualib/eventenginer.lua'
old='''            if skill_id and define.TELE_PORT_SKILLS[skill_id] then'''
new='''            -- CYS-JUE 23/09: this engine used to discard delaytime entirely.
            -- GL 5723 (CY 4515) has 700ms delay; CY Bullet305 flies at 15m/s.
            -- Freeze the prepared impact/caster logic now; apply only after travel.
            if skill_id == 4515 and sender then
                local a, b = sender:get_world_pos(), reciver:get_world_pos()
                local dx, dy = a.x-b.x, a.y-b.y
                local wait_ms = math.max(700, tonumber(delaytime) or 0)
                    + math.ceil(math.sqrt(dx*dx+dy*dy)/15*1000)
                local receiver_id = reciver:get_obj_id()
                skynet.timeout(math.ceil(wait_ms/10), function()
                    -- Timers must not hit a despawned/replaced/transferred target.
                    if scene:get_obj_by_id(receiver_id) ~= reciver or not reciver:is_alive() then return end
                    local ok, err = pcall(reciver.register_impact, reciver, imp)
                    if not ok then skynet.loge("CYS-JUE delayed impact: ",err) end
                end)
            elseif skill_id and define.TELE_PORT_SKILLS[skill_id] then'''
text=p.read_text(encoding='utf8')
if new not in text:
 assert text.count(old)==1
 backup=R/'backups'/('jue-projectile-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S'))
 backup.mkdir(parents=True);shutil.copy2(p,backup/p.name)
 p.write_text(text.replace(old,new),encoding='utf8');print('Backup',backup)
subprocess.run(['luac','-p',str(p)],check=True)
# Execute the production registration function. The double records the real scheduled callback.
text=p.read_text(encoding='utf8')
body=text.split('function eventenginer:real_register_impact_event(reciver, sender, imp, delaytime, skill_id)',1)[1].split('\nfunction eventenginer:register_impact_event',1)[0]
lua='''local eventenginer={};local queue={};local hits=0;local live=true;local same=true
local skynet={timeout=function(t,f)table.insert(queue,{t,f})end,loge=error}
local define={INVAILD_ID=-1,TELE_PORT_SKILLS={},MISS_FLAG={FLAG_NORMAL=0},ENUM_BEHAVIOR_TYPE={BEHAVIOR_TYPE_HOSTILITY=1}}
local packet_def={};local impact={get_logic=function()return{}end}
local imp={get_data_index=function()return 10 end,get_logic_id=function()return 1 end,is_critical_hit=function()return false end,
get_skill_id=function()return 4515 end,get_is_out=function()return false end,get_stand_flag=function()return 1 end}
for _,k in ipairs({'set_caster_obj_id','set_caster_unique_id','set_caster_logic_count','mark_create_by_player_flag'})do imp[k]=function()end end
local reciver={get_world_pos=function()return{x=3,y=4}end,get_obj_id=function()return 2 end,is_alive=function()return live end,
is_unbreakable=function()return false end,on_filtrate_impact=function()return 0 end,register_impact=function()hits=hits+1 end}
local sender={get_world_pos=function()return{x=0,y=0}end,get_obj_id=function()return 1 end,get_guid=function()return 100 end,
get_logic_count=function()return 7 end,get_obj_type=function()return 'human' end,refix_impact=function()end}
local scene={get_impact_enginer=function()return impact end,get_obj_by_id=function()if same then return reciver end end}
function eventenginer:get_scene()return scene end
function eventenginer:real_register_impact_event(reciver,sender,imp,delaytime,skill_id)
BODY
eventenginer:real_register_impact_event(reciver,sender,imp,0,4515)
assert(hits==0 and #queue==1 and queue[1][1]==104,'must wait release+5m travel')
queue[1][2]();assert(hits==1,'one impact at arrival')
live=false;queue[1][2]();assert(hits==1,'dead target ignored')
live=true;same=false;queue[1][2]();assert(hits==1,'replaced target ignored')
same=true;eventenginer:real_register_impact_event(reciver,sender,imp,0,79)
assert(hits==2 and #queue==1,'other skills unchanged')
print('PASS Jue delayed once; dead/replaced target ignored; other skills unchanged')
'''.replace('BODY',body)
subprocess.run(['lua','-'],input=lua,text=True,check=True)
