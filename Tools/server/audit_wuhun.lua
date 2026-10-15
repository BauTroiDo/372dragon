-- Read-only behavioral audit. Run with lua5.4 and the private server root.
-- Executes the actual gameplay module and cfghelper tables; storage/money are fixtures.
-- FAIL means an unmet gameplay invariant, not an expected-pass test suite.
local root = assert(arg[1], 'private server root required')
assert(root:match('/cys%-test%-20260913$'), 'private root only')
package.path = root..'/GameServer/lualib/?.lua;'..root..'/Game_2/Script/?.lua;'..package.path
package.cpath = root..'/GameServer/luaclib/?.so;'..package.cpath
local say, quiet = print, function()end
package.loaded.skynet = {getenv=function(k) if k=='config_path' then return root..'/configs/%s' end end,
    logd=quiet,logi=quiet,logw=quiet,loge=quiet,error=quiet,log=quiet}
package.loaded['skynet.manager'] = {}
package.loaded['skynet.sharetable'] = {}
table.tostr = function()return '' end
-- Same recursive copy helper as preloader.lua; avoid loading its process-wide IO restrictions.
function table.clone(obj)
    if type(obj)~='table' then return obj end
    local copy={};for k,v in pairs(obj)do copy[table.clone(k)]=table.clone(v)end
    return setmetatable(copy,getmetatable(obj))
end
print=quiet
local cfg = require('cfghelper').new()
print=say
local configs = {}
for _,name in ipairs({'kfs_slot','kfs_attr_ext','kfs_attr_ex_book','kfs_skill_level_up'}) do
    print=quiet; cfg['read_'..name](cfg); print=say
    configs[name]=cfg['get_'..name](cfg)
end
local S
local base = require('class')('wuhun_audit_base')
function base:IsPilferLockFlag()return S.pilfer end
function base:LuaFnIsItemLocked(_,pos)return S.locked[pos] or false end
function base:notify_tips(_,msg)S.tips[#S.tips+1]=msg end
function base:LuaFnGetBagEquipType(_,pos)return S.items[pos] and 18 or -1 end
function base:GetGemEmbededCount()return 0 end
function base:GetEquipWuHunData(_,pos)return assert(S.items[pos], 'empty bag slot') end
function base:SetEquipWuHunData(_,pos,delta)
    local item=assert(S.items[pos]); S.writes=S.writes+1
    for k,v in pairs(delta) do
        if type(v)=='table' then for i,x in pairs(v)do item[k][i]=x end else item[k]=v end
    end
end
function base:GetMoney()return S.money end
function base:GetMoneyJZ()return 0 end
function base:LuaFnCostMoneyWithPriority(_,n)S.money=S.money-n;S.spent=S.spent+n;return true end
function base:LuaFnGetItemBindStatus()return false end
function base:LuaFnItemBind()end
function base:LuaFnEraseItem(_,pos)S.items[pos]=nil;S.erased=S.erased+1 end
base.EraseItem=base.LuaFnEraseItem
function base:LuaFnSendSpecificImpactToUnit()end
function base:LuaFnGetItemTableIndexByIndex(_,pos)return S.material[pos] or 0 end
function base:GetKfsAttrExBookConfig()return configs.kfs_attr_ex_book end
function base:GetKfsAttrExConfig()return configs.kfs_attr_ext end
function base:GetKfsSlotConfig()return configs.kfs_slot end
function base:GetKfsSkillLevelUpConfig()return configs.kfs_skill_level_up end
function base:LuaFnIsItemAvailable()return true end
function base:LuaFnDecItemLayCount()S.consumed=S.consumed+1;return true end
function base:LuaFnDelAvailableItem()S.consumed=S.consumed+1;return true end
function base:WuHunUnstandSkill(_,pos,index)S.items[pos].skill[index]=1361;S.writes=S.writes+1 end
function base:GetItemName(id)return tostring(id) end
package.loaded.script_base=base
local wuhun=assert(loadfile((arg[3] or root)..'/Game_2/Script/scripts/event/equip/wuhun.lua'))().new()
local function item()
    return {hecheng_level=1,life=200,grow_rate=600,level=40,ex_attr_number=1,
        ex_attr={1,0,0,0,0,0,0,0,0,0},skill={-1,-1,-1}}
end
local function reset()
    S={items={[0]=item(),[1]=item()},material={},locked={},tips={},money=1000000,spent=0,erased=0,writes=0,consumed=0}
end
local passed,failed=0,0
local function result(name,ok,detail)
    if ok then passed=passed+1 else failed=failed+1 end
    say((ok and 'PASS' or 'FAIL')..'\t'..name..'\t'..(detail or ''))
end
local function run(name,action,check)
    reset();local ok,err=pcall(action)
    result(name,ok and check(), string.format('no_throw=%s spent=%d erased=%d writes=%d consumed=%d%s',
        tostring(ok),S.spent,S.erased,S.writes,S.consumed,ok and '' or (' error='..tostring(err))))
end
run('compound_distinct_valid_control',function()wuhun:OnAction(1,3,0,1,0)end,
    function()return S.items[0].hecheng_level==2 and S.items[1]==nil and S.spent==10000 end)
run('compound_same_item_must_reject',function()wuhun:OnAction(1,3,0,0,0)end,
    function()return S.items[0]~=nil and S.spent==0 and S.erased==0 and S.writes==0 end)
run('compound_locked_material_control',function()S.locked[1]=true;wuhun:OnAction(1,3,0,1,0)end,
    function()return S.spent==0 and S.erased==0 and #S.tips==1 end)
run('study_attr_with_space_control',function()
    S.items[0].ex_attr_number=2;S.material[2]=30700214;wuhun:OnAction(1,2,0,2,0)
end,function()return S.items[0].ex_attr[2]==11 and S.spent==80000 end)
run('study_attr_full_must_reject_cleanly',function()
    S.items[0].ex_attr_number=10;S.items[0].ex_attr={1,11,21,31,41,51,61,71,81,91}
    S.material[2]=30700214;wuhun:OnAction(1,2,0,2,0)
end,function()return S.spent==0 and S.writes==0 end)
run('upgrade_empty_attr_must_reject_cleanly',function()wuhun:OnAction(1,1,0,2,1)end,
    function()return S.spent==0 and S.writes==0 end)
run('upgrade_valid_attr_control',function()
    S.material[2]=configs.kfs_attr_ext[1].level_up_material;wuhun:OnAction(1,1,0,2,0)
end,function()return S.items[0].ex_attr[1]==2 and S.spent==5000 and S.consumed==1 end)
run('upgrade_empty_bag_must_reject_cleanly',function()wuhun:OnAction(1,1,255,2,0)end,
    function()return S.spent==0 and S.writes==0 end)
run('study_skill_level40_control',function()wuhun:OnAction(1,5,0,0,0)end,
    function()return S.items[0].skill[1]==1361 and S.spent==50000 end)
run('study_skill_level39_control',function()S.items[0].level=39;wuhun:OnAction(1,5,0,0,0)end,
    function()return S.spent==0 and S.writes==0 end)
run('restore_life_valid_control',function()S.material[2]=30700233;wuhun:OnAction(1,4,0,2,0)end,
    function()return S.items[0].life==300 and S.spent==50000 and S.consumed==1 end)
run('restore_life_full_control',function()S.items[0].life=300;S.material[2]=30700233;wuhun:OnAction(1,4,0,2,0)end,
    function()return S.spent==0 and S.consumed==0 end)
-- Deterministic exhaustive rolls with the REAL row for combination level 2 (index 1).
local original_random, successes=math.random,0
for roll=1,1000 do
    reset();S.items[0].hecheng_level=2;S.material[2]=configs.kfs_slot[1].materials[1]
    math.random=function()return roll end
    wuhun:OnAction(1,9,0,2,0)
    if S.items[0].ex_attr_number==2 then successes=successes+1 end
end
math.random=original_random
result('slot_probability_matches_table',successes==configs.kfs_slot[1].odd,
    string.format('successes=%d/1000 expected=%d/1000',successes,configs.kfs_slot[1].odd))
-- Extract the exact top-level server method; do not replace its body with a model.
if arg[4]=='gameplay-only' then
    say(string.format('SUMMARY gameplay pass=%d fail=%d',passed,failed))
    os.exit(failed==0 and 0 or 1)
end
local f=assert(io.open(root..'/GameServer/lualib/script_base.lua','rb'));local src=f:read('*a');f:close()
local body=assert(src:match('(function script_base:ReplaceKfsSkill%([^\n]+\n.-\nend)'))
local env={script_base={},packet_def={GCItemInfo={new=function()return {} end}}}
setmetatable(env,{__index=_G});assert(load(body,'@script_base.lua:ReplaceKfsSkill','t',env))()
local targetSkills,tempSkills,sent
local target={get_equip_data=function()return {set_wh_skill=function(_,i,v)assert(v);targetSkills[i]=v end}end,
    copy_raw_data=function()return {}end}
local human={get_prop_bag_container=function()return {get_item=function()return target end}end,
    get_temp_wh_skills=function()return tempSkills end,
    get_scene=function()return {send2client=function()sent=sent+1 end}end}
local host={scene={get_obj_by_id=function()return human end}}
targetSkills={-1,-1,-1};tempSkills=nil;sent=0
local ok,err=pcall(env.script_base.ReplaceKfsSkill,host,1,0)
result('replace_without_roll_must_reject_cleanly',ok and sent==0 and targetSkills[1]==-1,tostring(err))
targetSkills={-1,-1,-1};tempSkills={1361,1371,1381};sent=0
ok,err=pcall(env.script_base.ReplaceKfsSkill,host,1,0)
result('replace_pending_control',ok and sent==1 and targetSkills[1]==1361,tostring(err))
-- Same pending state, different target: method has no source item identity and does not consume state.
targetSkills={-1,-1,-1};sent=0
ok,err=pcall(env.script_base.ReplaceKfsSkill,host,1,1)
result('replace_second_item_must_reject',ok and sent==0 and targetSkills[1]==-1,
    'target skill='..tostring(targetSkills[1])..' sent='..sent)
if arg[2] then
    local cySkills=assert(loadfile(arg[2]))()
    local file=assert(io.open(root..'/GameServer/lualib/item.lua','rb'))
    local itemSource=file:read('*a');file:close()
    local method=assert(itemSource:match('(function equip_data:wh_understand_skill%([^\n]+\n.-\nend)'))
    local definition=require('define')
    local itemEnv={equip_data={},define=definition};setmetatable(itemEnv,{__index=_G})
    assert(load(method,'@item.lua:wh_understand_skill','t',itemEnv))()
    local bad,draws={},{}
    for roll=1,#definition.WUHUN_SKILLS[1] do
        local selected
        math.random=function()return roll end
        itemEnv.equip_data.wh_understand_skill({set_wh_skill=function(_,_,id)selected=id end},1)
        draws[#draws+1]=selected
        if not cySkills[selected] then bad[#bad+1]=selected end
    end
    math.random=original_random
    result('understand_skill_ids_must_be_in_CY_table',#bad==0,
        'all choices='..table.concat(draws,',')..' outside CY KFS='..table.concat(bad,','))
end
say(string.format('SUMMARY pass=%d fail=%d',passed,failed))
os.exit(failed==0 and 0 or 1)
