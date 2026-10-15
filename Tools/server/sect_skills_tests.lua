-- Actual cfghelper/configs and book callbacks + actual scenecore study function.
-- Only player inventory/state, network transport and engine services are fixtures.
-- lua5.4 sect_skills_tests.lua ROOT EXPECTED_BOOKS_LUA [OVERLAY]
local root, expected_path, overlay = assert(arg[1]), assert(arg[2]), arg[3]
local paths = {}
if overlay then
    paths[#paths+1] = overlay..'/GameServer/lualib/?.lua'
    paths[#paths+1] = overlay..'/Game_2/Script/?.lua'
end
paths[#paths+1] = root..'/GameServer/lualib/?.lua'
paths[#paths+1] = root..'/GameServer/services/?.lua'
paths[#paths+1] = root..'/Game_2/Script/?.lua'
package.path = table.concat(paths,';')..';'..package.path
package.cpath = root..'/GameServer/luaclib/?.so;'..package.cpath
local quiet = function() end
package.loaded.skynet = {getenv=function(k) if k=='config_path' then return root..'/configs/%s' end end,
    logd=quiet,logi=quiet,logw=quiet,loge=quiet,error=quiet,log=quiet}
package.loaded['skynet.manager'] = {}
package.loaded['skynet.sharetable'] = {}
table.tostr = table.tostr or function()return '' end
local cfg = require('cfghelper').new()
local cache = {}
local configs = {}
function configs:get_config(name)
    if not cache[name] then
        cfg['read_'..name](cfg);cache[name]=cfg['get_'..name](cfg)
    end
    return cache[name]
end
package.loaded.configenginer = {getinstance=function()return configs end}
local expected = assert(loadfile(expected_path))()
local template = configs:get_config('skill_template')
local xinfas = configs:get_config('xinfa_v1')
local costs = configs:get_config('xinfa_study_speed_v1')
local S
local base = require('class')('book_test_base')
function base:LuaFnVerifyUsedItem() return S.valid end
function base:LuaFnGetItemIndexOfUsedItem() return S.item end
function base:GetMenPai() return S.menpai end
function base:GetLevel() return S.level end
function base:HaveXinFa(_,id) return S.xinfa[id] or -1 end
function base:HaveSkill(_,id) return S.skills[id] == true end
function base:AddXinFa(_,id) assert(xinfas[id]);S.xinfa[id]=1;S.added=id end
function base:AddSkill(_,id) assert(template[id],'invalid learned skill '..id);S.skills[id]=true;S.added=id end
function base:notify_tips(_,msg) S.tip=msg end
function base:LuaFnDepletingUsedItem() S.consumed=S.consumed+1;return 1 end
function base:LuaFnSendSpecificImpactToUnit() S.effects=S.effects+1 end
function base:get_scene()
    return {get_obj_by_id=function()return {
        have_skill=function(_,id)return S.skills[id]==true end,
        get_total_skills_list=function()local t={};for i=1,S.total do t[i]=i end;return t end
    }end}
end
package.loaded.script_base = base
local book = require('scripts.obj.commonitem.338000').new()
local passed, failed = 0, 0
local function test(name,fn)
    local ok,err=pcall(fn)
    if ok then passed=passed+1 else failed=failed+1;print('FAIL '..name..': '..tostring(err)) end
end
local function setup(id,b)
    S={item=id,menpai=b.menpaiId,level=b.needLevel,xinfa={},skills={},consumed=0,effects=0,total=40,valid=true}
    if b.needXinfa~=-1 then S.xinfa[b.needXinfa]=b.needXinfaLevel end
end
local function attempt()
    if book:OnConditionCheck(1)~=1 then return false end
    if book:OnDeplete(1)~=1 then return false end
    return book:OnActivateOnce(1)==1
end
local ids={};for id in pairs(expected)do ids[#ids+1]=id end;table.sort(ids)
assert(#ids==106)
for _,id in ipairs(ids)do
    local b=expected[id]
    test('book '..id..' learns exact target once',function()
        setup(id,b);assert(attempt(),'not learned');assert(S.added==b.id);assert(S.consumed==1 and S.effects==1)
        assert(not attempt(),'duplicate learned');assert(S.consumed==1)
    end)
    test('book '..id..' low character level retains item',function()
        setup(id,b);S.level=b.needLevel-1;assert(not attempt());assert(S.consumed==0)
    end)
    test('book '..id..' invalid used item retains item',function()
        setup(id,b);S.valid=false;assert(not attempt());assert(S.consumed==0)
    end)
    if b.menpaiId~=-1 then
        test('book '..id..' foreign faction retains item',function()
            setup(id,b);S.menpai=(b.menpaiId+1)%9;assert(not attempt());assert(S.consumed==0)
        end)
    end
    if b.type==2 then
        test('book '..id..' full skill list retains item',function()
            setup(id,b);S.total=127;assert(not attempt());assert(S.consumed==0)
        end)
    end
    if b.needXinfa~=-1 then
        test('book '..id..' missing prerequisite retains item',function()
            setup(id,b);S.xinfa={};assert(not attempt());assert(S.consumed==0)
        end)
        test('book '..id..' changed prerequisite before depletion retains item',function()
            setup(id,b);assert(book:OnConditionCheck(1)==1);S.xinfa={}
            assert(book:OnDeplete(1)==0);assert(S.consumed==0)
        end)
    end
end
for _,id in ipairs({30308026,30308027,30308028,30308029,30308030,30308031,30308032,30308033,30308034,30308042,30308044,30308160,30308140,30308148})do
    test('unresolved/retired '..id..' retains item',function()
        setup(id,{menpaiId=10,needLevel=100,needXinfa=-1});assert(not attempt());assert(S.consumed==0)
    end)
end
test('invalid runtime target refuses before consumption',function()
    local saved=template[2921];template[2921]=nil
    setup(30308275,expected[30308275]);local ok,err=pcall(attempt);template[2921]=saved
    assert(ok,err);assert(S.consumed==0 and not S.added)
end)
-- Read the actual handler verbatim, not a reimplementation of the old function.
local scene_path=(overlay or root)..'/GameServer/services/scene/scenecore.lua'
local f=assert(io.open(scene_path));local text=f:read('*a');f:close()
local body=assert(text:match('(function scenecore:char_study_xinfa%(.+)function scenecore:char_req_level_up%('))
local handler={}
assert(load(body,'@'..scene_path,'t',setmetatable({scenecore=handler,configenginer=configs,
    packet_def={GCStudyXinfa={new=function()return{}end}}},{__index=_G})))()
local function human(id,level)
    local h={x={[id]={m_nXinFaID=id,m_nXinFaLevel=level}},mp=xinfas[id].menpai,exp=1000000000000,money=1000000000000,changes=0}
    function h:get_xinfa(i)return self.x[i]end
    function h:get_menpai()return self.mp end
    function h:get_level()return self.level or 200 end
    function h:get_exp()return self.exp end
    function h:get_attrib(k)return self[k]end
    function h:get_money()return self.money end
    function h:check_money_with_priority(n)return self.money>=n end
    function h:set_exp(n)self.exp=n end
    function h:cost_money_with_priority(n)self.money=self.money-n end
    function h:study_xinfa(i,n)if self.x[i]then self.x[i].m_nXinFaLevel=n end;self.changes=self.changes+1 end
    function h:notify_tips(s)self.tip=s end
    local scene=setmetatable({objs={[1]=h},sent={}},{__index=handler})
    function scene:send2client(_,msg)self.sent[#self.sent+1]=msg end
    return h,scene
end
for id in pairs(xinfas)do
    test('xinfa '..id..' valid upgrade and repeated request',function()
        local h,s=human(id,1);local exp,money=h.exp,h.money
        s:char_study_xinfa(1,{xinfa=id,now_level=1,menpai=h.mp})
        assert(h.x[id].m_nXinFaLevel==2 and h.changes==1)
        assert(h.exp==exp-tonumber(costs[2].cost_exp[id+1]));assert(h.money==money-tonumber(costs[2].cost_money[id+1]))
        exp,money=h.exp,h.money
        s:char_study_xinfa(1,{xinfa=id,now_level=1,menpai=h.mp})
        assert(h.exp==exp and h.money==money and h.changes==1,'stale request changed player')
    end)
end
for _,case in ipairs({'unowned','foreign','cap','out-of-range','no-exp','no-money','missing-cost'})do
    test('xinfa rejects '..case..' without deductions',function()
        local h,s=human(1,1);local req={xinfa=1,now_level=1,menpai=0};local saved
        if case=='unowned' then h.x={} elseif case=='foreign' then h.mp=1
        elseif case=='cap' then h.x[1].m_nXinFaLevel=119;req.now_level=119
        elseif case=='out-of-range' then req.now_level=65535
        elseif case=='no-exp' then h.exp=0 elseif case=='no-money' then h.money=0
        elseif case=='missing-cost' then saved=costs[2];costs[2]=nil end
        local exp,money=h.exp,h.money
        local ok,err=pcall(s.char_study_xinfa,s,1,req)
        if saved then costs[2]=saved end
        assert(ok,err);assert(h.exp==exp and h.money==money and h.changes==0)
    end)
end
for _,case in ipairs({'level-boundary','level-too-low','reentrant','zero-cost','yield-level-change'})do
    test('xinfa '..case,function()
        local h,s=human(1,6);h.level=2
        local req={xinfa=1,now_level=6,menpai=h.mp}
        local get=configs.get_config
        local row=costs[7];local money,exp=row.cost_money[2],row.cost_exp[2]
        if case=='level-too-low'then h.level=1 end
        if case=='zero-cost'then row.cost_money[2]=0;row.cost_exp[2]=0
            function h:cost_money_with_priority(n)assert(n>0);self.money=self.money-n end
        end
        local entered=false
        if case=='reentrant'or case=='yield-level-change'then
            function configs:get_config(name)
                if name=='xinfa_study_speed_v1'and not entered then
                    entered=true
                    if case=='reentrant'then s:char_study_xinfa(1,req)
                    else h.x[1].m_nXinFaLevel=7 end
                end
                return get(self,name)
            end
        end
        local beforeMoney,beforeExp=h.money,h.exp
        local ok,err=pcall(s.char_study_xinfa,s,1,req)
        configs.get_config=get;row.cost_money[2],row.cost_exp[2]=money,exp
        assert(ok,err);assert(not h._cys_studying_xinfa)
        if case=='level-too-low'or case=='yield-level-change'then assert(h.changes==0 and h.money==beforeMoney and h.exp==beforeExp)
        else assert(h.changes==1 and h.x[1].m_nXinFaLevel==7)end
        if case=='zero-cost'then assert(h.money==beforeMoney and h.exp==beforeExp)end
    end)
end
local hf=assert(io.open((overlay or root)..'/GameServer/services/scene/obj/human.lua'));local hs=hf:read('*a');hf:close()
local hb=assert(hs:match('(function human:on_study_xinfa%(.+)\n%-%- 获取生活技能列表'))
local hclass={};local define=require 'define'
assert(load(hb,'@human:on_study_xinfa','t',setmetatable({human=hclass,define=define,
    skillenginer={get_skill_templates=function()return template end}},{__index=_G})))()
for id,c in pairs(xinfas)do
    for _,level in ipairs({1,119})do
        test('authored unlock xinfa '..id..' level '..level,function()
            local learned={};local h={get_attrib=function()return c.menpai end,get_skill_list=function()return{}end,
                add_skill=function(_,sid)learned[sid]=true end}
            hclass.on_study_xinfa(h,id,level)
            for sid,t in pairs(template)do
                local expected=t.class_by_user==0 and t.xinfa==id and (t.xinfa_level_require or 0)<=level
                    and id~=define.MENPAI_7_XINFA[c.menpai] and id~=define.MENPAI_8_XINFA[c.menpai]
                assert((learned[sid]==true)==expected,'wrong unlock '..sid)
            end
        end)
    end
end
local sf=assert(io.open((overlay or root)..'/GameServer/lualib/skillenginer.lua'));local ss=sf:read('*a');sf:close()
local prefix=assert(ss:match('(function skillenginer:process_skill_request%(.-)    if not obj_me:is_skill_cool_down'))
local engine={get_skill_template=function(_,id)return template[id]end}
package.loaded.cys_dual_souls={authorized=function()return true end}
assert(load(prefix..' return true end','@actual-skill-request-eligibility','t',setmetatable({skillenginer=engine,define=define},{__index=_G})))()
for sid,t in pairs(template)do
    if t.class_by_user==0 and t.use_need_learnd and (t.xinfa or -1)>=0 then
        test('cast enforces authored xinfa threshold '..sid,function()
            local requirement=t.xinfa_level_require or 0
            local owned={m_nXinFaLevel=requirement};local bypass=false;local err
            local params={get_ignore_condition_check_flag=function()return bypass end,set_errcode=function(_,e)err=e end}
            local h={get_targeting_and_depleting_params=function()return params end,is_alive=function()return true end,
                can_use_this_skill_in_this_status=function()return true end,get_obj_type=function()return 'human'end,
                have_skill=function()return true end,get_xinfa=function(_,id)assert(id==t.xinfa);return owned end}
            assert(engine:process_skill_request(h,sid,1))
            owned.m_nXinFaLevel=requirement-1;assert(not engine:process_skill_request(h,sid,1))
            assert(err==define.OPERATE_RESULT.OR_NEED_LEARN_SKILL_FIRST)
            owned=nil;assert(not engine:process_skill_request(h,sid,1))
            bypass=true;assert(engine:process_skill_request(h,sid,1))
        end)
    end
end
print(string.format('sect_skills_tests: %d passed, %d failed; books=%d; actual configs/callbacks/study handler',passed,failed,#ids))
os.exit(failed==0 and 0 or 1)
