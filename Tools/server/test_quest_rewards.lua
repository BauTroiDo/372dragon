-- Execute the original/staged Dali callbacks with an in-memory mission journal.
-- World-specific objective checks are isolated from reward transaction tests.
local root,stage=assert(arg[1]),assert(arg[2])
package.path=root..'/GameServer/lualib/?.lua;'..root..'/Game_2/Script/?.lua;'..package.path
package.loaded.skynet={getenv=function()end}
local class=require 'class'
local base=class('quest_reward_test_base')
local S
function base:IsHaveMission(_,id)return S.active[id]~=nil end
function base:IsMissionHaveDone(_,id)return S.done[id]==true end
function base:AddMission(_,id)if S.active[id]or S.fulljournal then return false end;S.active[id]={};return true end
function base:DelMission(_,id)if not S.active[id]then return false end;S.active[id]=nil;return true end
function base:MissionCom(_,id)S.done[id]=true end
function base:BeginAddItem()S.pending={}end
function base:AddItem(id,n)assert(type(id)=='number'and n>0);S.pending[#S.pending+1]={id,n}end
function base:EndAddItem()return #S.pending>0 and not S.fullbag end
function base:AddItemListToHuman()if S.stale then return false end;for _,v in ipairs(S.pending)do S.items[v[1]]=(S.items[v[1]]or 0)+v[2]end;S.pending={};return true end
function base:AddMoneyJZ(_,n)S.money=S.money+n end
function base:LuaFnAddExp(_,n)S.exp=S.exp+n end
function base:GetLevel()return 200 end
function base:GetMenPai()return 0 end
function base:GetMissionIndexByID(_,id)return id end
function base:SetMissionByIndex(_,id,k,v)S.active[id][k]=v end
function base:GetMissionParam(_,id,k)return S.active[id]and S.active[id][k]or 0 end
function base:notify_tips()end
function base:LuaFnCreatePetToHuman()if S.fullpets then return false end;S.pets=(S.pets or 0)+1;return true end
function base:CallScriptFunction(_,method)if method=='CheckSubmit'then return 1 end end
function base:BeginEvent()end;function base:AddText()end;function base:EndEvent()end;function base:DispatchMissionTips()end
package.loaded.script_base=base
local pass,fail=0,0
local function check(name,fn)local ok,e=xpcall(fn,debug.traceback);if ok then pass=pass+1 else fail=fail+1;print('FAIL',name,e)end end
local function state()S={active={},done={},pending={},items={},money=0,exp=0};return S end
for n=1,23 do
    local rel=string.format('/Game_2/Script/scripts/event/dali/edali_newquest_%03d.lua',n)
    local f=io.open(stage..rel);local path=f and stage..rel or root..rel;if f then f:close()end
    f=io.open(path)
    if f then
        f:close();local cls=assert(loadfile(path))();local obj=cls.new();local id=obj.g_MissionId
        if obj.OnSubmit and id then
            local originalCheck=obj.CheckSubmit
            for _,scenario in ipairs({'valid','replay','not-owned','unfinished','full-bag','full-journal','choice-invalid','stale-reward'})do
                check('Dali '..id..' '..scenario,function()
                    state();S.active[id]={};obj.CheckSubmit=function()return scenario=='unfinished'and 0 or 1 end
                    if scenario=='not-owned'then S.active={}end
                    if scenario=='full-bag'then S.fullbag=true end
                    if scenario=='stale-reward'then
                        if not ({[3]=true,[4]=true,[7]=true,[8]=true,[15]=true,[20]=true})[n]then return end
                        S.stale=true
                    end
                    if scenario=='full-journal'then S.active={};S.fulljournal=true;obj.CheckAccept=function()return 1 end;obj:OnAccept(1);assert(not S.active[id]and not S.pets);return end
                    local radio=obj.g_RadioItemBonus;local choices=radio and #radio>0
                    if scenario=='choice-invalid'and not choices then return end
                    obj:OnSubmit(1,2,scenario=='choice-invalid'and 999 or (choices and radio[1].id or 0))
                    if scenario=='not-owned'or scenario=='unfinished'or scenario=='choice-invalid'then
                        assert(S.money==0 and S.exp==0 and next(S.items)==nil and not S.done[id],'invalid submission rewarded');return
                    end
                    local itemRewards=(obj.g_ItemBonus and #obj.g_ItemBonus>0)or choices
                    if scenario=='stale-reward'then assert(S.active[id]and not S.done[id]and S.money==0 and S.exp==0 and next(S.items)==nil);return end
                    if scenario=='full-bag'and itemRewards then assert(S.active[id]and not S.done[id]and S.money==0 and S.exp==0);return end
                    assert(not S.active[id]and S.done[id],'quest not completed')
                    if choices then
                        local count=0;for _,v in pairs(S.items)do count=count+v end
                        assert(count==radio[1].num,'radio reward granted more than the chosen item')
                    end
                    if scenario=='replay'then
                        local money,exp=S.money,S.exp;local items={};for k,v in pairs(S.items)do items[k]=v end
                        obj:OnSubmit(1,2,choices and radio[1].id or 0);assert(S.money==money and S.exp==exp)
                        for k,v in pairs(S.items)do assert(items[k]==v,'reward duplicated')end
                    end
                end)
            end
            obj.CheckSubmit=originalCheck
        end
    end
end
local cls=assert(loadfile(stage..'/Game_2/Script/scripts/event/dali/edali_newquest_015.lua'))()
local choicecls=assert(loadfile(stage..'/Game_2/Script/scripts/event/dali/edali_newquest_008.lua'))()
local choicequest=choicecls.new();choicequest.CheckSubmit=function()return 1 end
for _,reward in ipairs(choicequest.g_RadioItemBonus)do
    check('quest 1407 wire item ID '..reward.id,function()
        state();S.active[choicequest.g_MissionId]={}
        choicequest:OnSubmit(1,2,reward.id)
        local checkCount=0;for id,n in pairs(S.items)do assert(id==reward.id and n==reward.num);checkCount=checkCount+n end
        assert(checkCount==reward.num)
    end)
end
for _,scenario in ipairs({'full-pets','duplicate','completed','invalid-prerequisite'})do
    check('pet quest accept '..scenario,function()
        state();local obj=cls.new();local id=obj.g_MissionId
        obj.CheckAccept=function()return scenario=='invalid-prerequisite'and 0 or 1 end
        if scenario=='full-pets'then S.fullpets=true end
        if scenario=='completed'then S.done[id]=true end
        obj:OnAccept(1)
        if scenario=='duplicate'then obj:OnAccept(1);assert(S.pets==1 and S.active[id])
        else assert(not S.pets and not S.active[id])end
    end)
end
local guide=assert(loadfile(stage..'/Game_2/Script/scripts/event/dali/edali_zhidao_0200.lua'))().new()
guide.CheckSubmit=function()return 1 end
for _,scenario in ipairs({'valid','invalid-choice','not-owned','stale','replay'})do
    check('quest 1401 '..scenario,function()
        state();S.active[guide.g_MissionId]={}
        if scenario=='not-owned'then S.active={}end
        if scenario=='stale'then S.stale=true end
        local choice=guide.g_RadioItemBonus[1]
        guide:OnSubmit(1,2,scenario=='invalid-choice'and 999 or choice.id)
        if scenario=='invalid-choice'or scenario=='not-owned'or scenario=='stale'then
            assert(next(S.items)==nil and S.money==0 and S.exp==0 and not S.done[guide.g_MissionId])
        else
            assert(S.items[choice.id]==choice.num and S.items[30101001]==10 and S.exp==700 and S.done[guide.g_MissionId])
            if scenario=='replay'then guide:OnSubmit(1,2,choice.id);assert(S.items[choice.id]==choice.num and S.exp==700)end
        end
    end)
end
print(string.format('Dali reward callbacks: %d passed, %d failed',pass,fail))
os.exit(fail==0 and 0 or 1)
