local root=assert(arg[1]);local f=assert(io.open(root..'/services/scene/obj/monster.lua'));local source=f:read('*a');f:close()
local M={};local env=setmetatable({monster=M,define={INVAILD_ID=-1},configenginer={get_config=function()return {Human={CanGetExpRange=20},Exp={ExpParam=1}}end}},{__index=_G})
local function method(name,nextname)
    local a=assert(source:find('function monster:'..name..'(',1,true));local b=assert(source:find('function monster:'..nextname..'(',a+1,true))
    assert(load(source:sub(a,b-1),'actual monster '..name,'t',env))()
end
method('caculate_owner_list','on_die_after');method('on_die_after','caculate_base_exp');method('caculate_base_exp','dispatch_exp');method('dispatch_exp','dispatch_good_bad')
local checks=0;local function check(v,n)checks=checks+1;assert(v,n)end
local humans={};local nearby={};local scene={scan=function()return nearby end,get_obj_by_guid=function(_,g)return humans[g]end,get_scene_exp_rate=function()return 0 end}
function scene:get_config_enginer()return {get_config=function()return {[0]=1}end}end
function scene:after_monster_die()end
local function human(guid,leader,dead)
    local h={guid=guid,exp=0,kills=0,dead=dead,team=5}
    function h:get_obj_type()return 'human'end
    function h:get_guid()return self.guid end
    function h:get_team_id()return self.team end
    function h:get_raid_id()return -1 end
    function h:is_die()return self.dead end
    function h:get_level()return 60 end
    function h:get_pet()end
    function h:get_team_info()return {is_leader=function()return leader end,get_exp_mode=function()return 1 end}end
    function h:on_kill_object()self.kills=self.kills+1 end
    function h:add_exp(n)self.exp=self.exp+math.floor(n)end
    humans[guid]=h;return h
end
local owner=human(1,false);local other=human(2,false);local chief=human(3,true);local dead=human(4,false,true);local foreign=human(5,false);foreign.team=8
local m=setmetatable({owners={},scene=scene},{__index=M})
function m:get_scene()return self.scene end
function m:get_world_pos()return {x=0,y=0}end
function m:get_occupant_guid()return 1 end
function m:get_team_occipant_guid()return 5 end
function m:get_raid_occipant_guid()return -1 end
function m:get_base_exp()return 1000 end
function m:get_level()return 60 end
function m:refix_occupant_guid()end
function m:dispatch_good_bad()end
function m:dispatch_friend_point()end
function m:dispatch_item_box()self.drops=(self.drops or 0)+1 end
function m:dispatch_kill_monster_count()end
nearby={owner,other,owner,dead,foreign}
local leader,owners=m:caculate_owner_list()
check(not leader and #owners==2,'deduplicate owner; exclude dead and foreign party')
m:dispatch_exp(owners,leader)
check(owner.exp==866 and other.exp==433,'sharing mode applies when chief is outside range')
m:caculate_owner_list();check(#m.owners==2,'owner recalculation replaces prior roster')
owner.exp=0;other.exp=0;m:on_die_after();m:on_die_after()
check(owner.exp==866 and other.exp==433 and m.drops==1,'duplicate death callback grants exp and loot once')
nearby={owner};m.cys_rewards_dispatched=nil;owner.exp=0;m:on_die_after()
check(owner.exp==1000 and m.drops==2,'new life single participant receives full base reward')
check(env.scene_exp_rate==nil,'scene multiplier is local')
print('PASS party experience checks='..checks)
