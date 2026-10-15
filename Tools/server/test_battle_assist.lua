-- Contract tests against the executor, with no live database or items.
local root=assert(arg[1]);package.path=root..'/?.lua;'..package.path
package.loaded.skynet={}
package.loaded.define={OPERATE_RESULT={OR_OK=0}}
package.loaded.cys_assist_data={skills={},potions={}}
package.loaded.configenginer={getinstance=function(self)return self end,get_config=function()return {[199]=100,[200]=100} end}
local M=require 'cys_battle_assist'
local sent={};local script={}
function script:BeginUICommand()self.row={} end
function script:UICommand_AddInt(v)table.insert(self.row,v) end
function script:EndUICommand()end
function script:DispatchUICommand()sent[#sent+1]=self.row end
local ai={param_ai_use_skill={},param_use_item={},stop=function()end,change_state=function()end}
local scene={get_id=function()return 6 end,char_req_level_up=function(self,id)self.level_requests=(self.level_requests or 0)+1 end}
local h={level=199,menpai=3,follow=false,dead=false,exp=100,boost={is_lock=false}}
function h:get_obj_id()return 1 end
function h:get_level()return self.level end
function h:get_menpai()return self.menpai end
function h:get_team_follow_flag()return self.follow end
function h:is_die()return self.dead end
function h:is_alive()return not self.dead end
function h:get_scene()return scene end
function h:get_ai()return ai end
function h:notify_tips(v)self.tip=v end
function h:set_locked_target(v)self.target=v end
function h:get_double_exp_info()return self.boost end
function h:send_double_exp_info()self.boost_sent=true end
function h:get_today_kill_monster_count()return 0 end
function h:get_exp()return self.exp end
function h:can_use_skill_now()return false end
local function submit(rev,cfg)
 M.begin(script,h,rev)
 for k,row in ipairs(cfg)do for offset=1,#row,8 do M.chunk(script,h,rev,k,offset,table.unpack(row,offset,math.min(#row,offset+7))) end end
 M.commit(script,h,rev)
end
local cfg=M.defaults();cfg[11][3]=200;cfg[7][8]=1
submit(1,cfg);assert(h.cys_assist_revision==2 and M.config(h)[11][3]==200)
local saved=h.cys_assist
submit(1,M.defaults());assert(h.cys_assist==saved,'stale transaction replaced configuration')
M.begin(script,h,2);M.chunk(script,h,2,1,1,1);M.commit(script,h,2)
assert(h.cys_assist==saved,'partial transaction replaced configuration')
local bad=M.defaults();bad[7][1]=2;submit(2,bad);assert(h.cys_assist==saved,'invalid switch accepted')
M.start(script,h,1);assert(not h.cys_assist_active,'stale start accepted')
h.menpai=9;M.start(script,h,2);assert(not h.cys_assist_active,'factionless start accepted')
h.menpai=3;M.start(script,h,2);assert(h.cys_assist_active)
M.tick(h,500);assert(scene.level_requests==1,'automatic level-up was not requested through the normal scene handler')
h.level=200;M.tick(h,500);assert(h.cys_assist_active and scene.level_requests==1,'level target incorrectly stopped combat or exceeded cap')
h.cys_assist[7][5]=1;M.stop(h)
assert(not h.cys_assist_active and h.target==-1 and ai.param_ai_use_skill.auto_use_skill==-1 and ai.param_use_item.bagindex==-1)
assert(h.boost.is_lock and h.boost_sent,'stop failed to freeze double EXP')
h.cys_assist_pending=nil;M.start(script,h,2);h.follow=true;M.tick(h,500)
assert(not h.cys_assist_active,'team-follow did not stop battle')
h.follow=false
function h:can_use_skill_now()return true end
function h:get_pet()return nil end
function h:get_hp()return 10 end
function h:get_max_hp()return 100 end
function h:get_mp()return 100 end
function h:get_max_mp()return 100 end
function h:get_obj_type()return 'human' end
function h:get_world_pos()return {x=1,y=2} end
function h:is_skill_cool_down()return true end
function h:can_use_this_skill_in_this_status()return true end
local item={is_lock=function()return false end,get_index=function()return 30001001 end,get_lay_count=function()return 3 end,get_base_config=function()return {skill_id=1} end}
function h:get_prop_bag_container()return {get_item=function(_,i)if i==98 then return item end end} end
function scene:char_use_item(id,use)assert(id==1 and use.bagIndex==98 and use.item_index==30001001);self.item_uses=(self.item_uses or 0)+1 end
package.loaded.cys_assist_data.potions={{30001001,0,1,150}}
h.cys_assist[8]={0,0,0};h.cys_assist[9]={1,1,1};h.cys_assist[10]={50,50,50}
M.tick(h,500);assert(not scene.item_uses,'native do-not-use potion choice consumed an item')
h.cys_assist[8][1]=1;M.tick(h,500);assert(scene.item_uses==1 and item:get_lay_count()==3,'selected potion did not go through normal handler')
print('PASS stale/partial/invalid atomic settings, start gates, auto-level200, queue cleanup, freeze EXP, follow stop, do-not-use potion zero, real item handler')
