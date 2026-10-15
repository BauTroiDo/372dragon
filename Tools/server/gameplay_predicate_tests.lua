-- Offline: real Lua modules and real predicate/menu-buffer methods. External
-- scene/network methods are explicit fixtures; no server/database writes.
local root=assert(arg[1])
package.path=root..'/GameServer/lualib/?.lua;'..root..'/Game_2/Script/?.lua;'..package.path
local class=require 'class'
local define=require 'define'
local base=class('script_base_fixture')
local human={}
local function methods(path, owner, names, env)
    local f=assert(io.open(path,'r'));local text=f:read('*a');f:close()
    for _,name in ipairs(names) do
        local body=assert(text:match('(function '..owner..':'..name..'%b().-\nend)'),name)
        assert(load(body,'@'..path..':'..name,'t',setmetatable(env,{__index=_G})))()
    end
end
methods(root..'/GameServer/lualib/script_base.lua','script_base',
 {'get_scene','IsHaveMission','IsMissionHaveDone','reset','BeginEvent','AddText','AddNumText','AddNumTextWithTarget'},
 {script_base=base,define=define})
methods(root..'/GameServer/services/scene/human.lua','human',
 {'is_have_mission','get_mission_index','get_mission_have_done'},{human=human,define=define})
local player=setmetatable({mission_data={char_missions={},mission_have_done_flags={}}},{__index=human})
local scene={get_obj_by_id=function(_,id) assert(id==101);return player end}
function base:GetLevel(id) assert(id==101);return 15 end
function base:GetMenPai(id) assert(id==101);return self.fixture_menpai end
function base:GetName(id) assert(id==101 or id==202);return id==202 and self.g_Name or 'Test player' end
function base:GetDayTime() return 99999 end
function base:EndEvent() self.ended=true end
function base:DispatchEventList(who,target) assert(who==101 and target==202 and self.ended);self.sent=true end
function base:DispatchShopItem(who,target,shop) assert(who==101 and target==202);self.shop=shop end
function base:CallScriptFunction(id,callback,caller,who,target)
    assert((id==50018 or id==50019) and callback=='OnEnumerate')
    assert(caller==self and who==101 and target==202);self.called=id
end
package.loaded.script_base=base
local checks,errors=0,0
local function test(name,fn)
    checks=checks+1;local ok,err=pcall(fn)
    if not ok then errors=errors+1;print('FAIL '..name..': '..tostring(err)) end
end
local function state(obj,kind)
    obj:reset();obj.scene=scene
    player.mission_data.char_missions=kind=='active' and {{id=obj.g_MissionId}} or {}
    player.mission_data.mission_have_done_flags={}
    if kind=='done' then
        player.mission_data.mission_have_done_flags[(obj.g_MissionId >> 5)+1]=1 << (obj.g_MissionId & 31)
    end
end
local schools={'shaolin','tianshan','wudang','xiaoyao','xingxiu','gaibang','mingjiao'}
for _,school in ipairs(schools) do
    local obj=require('scripts.event.shimen.event_shimen_'..school).new()
    obj.fixture_menpai=assert(define.MENPAI_ATTRIBUTE['MATTRIBUTE_'..school:upper()])
    for _,kind in ipairs({'none','active','done'}) do
        test(school..' menu '..kind,function()
            state(obj,kind)
            local caller=base.new();caller:BeginEvent(888)
            obj:OnEnumerate(caller,101,202)
            assert(obj.size==0,'mission wrote to its own hidden menu buffer')
            if kind=='done' then assert(caller.size==0)
            else
                assert(caller.size==1,'NPC must receive one option')
                assert(caller.script_ids[1]==obj.script_id,'option must target mission script')
                assert(caller.types[1]==(kind=='active' and 4 or 3))
            end
        end)
    end
    test(school..' CheckSubmit without mission',function()state(obj,'none');assert(obj:CheckSubmit(101)==0)end)
end
local registry=assert(loadfile(root..'/Game_2/Script/scripts/scripts.lua','t',{}))()
for _,id in ipairs({50200,50201,50202,50203,311000}) do
    test('NPC registry and default menu '..id,function()
        local obj=require(assert(registry[id],'missing registry ID '..id)).new()
        state(obj,'none');obj:OnDefaultEvent(101,202)
        assert(obj.sent and obj.size>0)
        if id==50201 then obj:OnEventRequest(101,202,0,1);assert(obj.shop==166) end
    end)
end
for _,mission in ipairs({131,132}) do
    test('Lingzhen mission '..mission,function()
        local obj=require('scripts.obj.xihu.oxihu_lingzhen').new()
        state(obj,'none');player.mission_data.char_missions={{id=mission}}
        obj:OnDefaultEvent(101,202)
        assert(obj.called==(mission==131 and 50018 or 50019) and obj.sent)
    end)
end
print(string.format('checks=%d errors=%d',checks,errors))
os.exit(errors==0 and 0 or 1)
