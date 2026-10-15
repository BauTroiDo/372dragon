-- CYS dual souls v1. Server owns equipment, skill entitlement and visibility.
-- Legacy KFS instances and their saved progression are never migrated here.
local M={support=10156901,assault=10156902,slot=39,command=990031}
local definitions={
 [10156901]={point=18,visual=704,skills={6100,6101}},
 [10156902]={point=39,visual=699,skills={6102,6103}},
}
function M.definition(id) return definitions[id] end
function M.initialize(item)
 local d=definitions[item:get_index()];if not d then return false end
 local ed=item:get_equip_data()
 ed:set_equip_type(2);ed:set_wh_level(1);ed:set_wh_exp(0)
 ed:set_wh_life(300);ed:set_wh_grow_rate(1000);ed:set_wh_hecheng_level(1)
 for i=1,3 do ed:set_wh_skill(i,d.skills[i] or -1) end
 for i=1,10 do ed:set_wh_ex_attr(i,0) end
 ed:set_wh_ex_attr_number(0)
 return true
end
function M.skills(h,point)
 local item=h:get_equip_container():get_item(point)
 local d=item and definitions[item:get_index()]
 if not d or d.point~=point or item:get_equip_data():get_wh_life()<=0 then return {} end
 -- Catalog is authoritative; edited or stale wh_skill arrays cannot grant attacks.
 local out={};for _,id in ipairs(d.skills) do out[#out+1]=id end;return out
end
function M.authorized(h,id)
 if id<6100 or id>6103 then return true end
 if not h or h:get_obj_type()~='human' then return false end
 for _,skill in ipairs(M.skills(h,id<6102 and 18 or 39)) do if skill==id then return id~=6100 end end
 return false
end
function M.visual(h)
 local item=h:get_equip_container():get_item(39)
 local d=item and definitions[item:get_index()]
 local shown=h:get_game_flag_key('cys_assault_hidden')~=1
 return d and d.point==39 and shown and d.visual or 0,item and item:get_index() or -1,shown and 1 or 0
end
function M.saved_visual(char)
 local item=char.equip_list and char.equip_list['40']
 local d=item and definitions[item.item_index]
 local flags=char.game_flag or {}
 return d and d.point==39 and flags.cys_assault_hidden~=1 and d.visual or 0,item and item.item_index or -1
end
function M.snapshot(scene,h,to,broadcast)
 local packet=require 'game.packet'
 local visual,item,shown=M.visual(h)
 local support=h:get_equip_container():get_item(18)
 local p=packet.GCUICommand.new()
 p.m_nUIIndex=M.command
 p.m_Param.m_IntCount=6
 p.m_Param.m_aIntValue={1,h:get_obj_id(),item,visual,shown,support and support:get_index() or -1}
 if broadcast then scene:broadcast(h,p,true) else scene:send2client(to or h,p) end
end
function M.can_swap(h,point)
 if point~=18 and point~=39 then return true end
 return h:is_alive() and h:get_action_time()<=0 and os.time()>=(h:get_game_flag_key('cys_soul_combat_until') or 0)
end
function M.combat(h)
 if h:get_obj_type()=='human' then h:set_game_flag_key('cys_soul_combat_until',os.time()+10) end
end
function M.schedule_impact(scene,sender,receiver,imp,delay,skill)
 local release=({[6102]=1800,[6103]=1500})[skill]
 if not release or not sender or not receiver then return false end
 -- CY Bullet126/132 both travel at 15m/s. Do not apply damage/EXP before impact.
 local a,b=sender:get_world_pos(),receiver:get_world_pos()
 local distance=math.sqrt((a.x-b.x)^2+(a.y-b.y)^2)
 local wait=math.max(release,tonumber(delay) or 0)+math.ceil(distance/15*1000)
 local sid,rid=sender:get_obj_id(),receiver:get_obj_id()
 local skynet=require 'skynet'
 skynet.timeout(math.ceil(wait/10),function()
  if scene:get_obj_by_id(sid)~=sender or scene:get_obj_by_id(rid)~=receiver then return end
  if not sender:is_alive() or not receiver:is_alive() then return end
  local ok,err=pcall(receiver.register_impact,receiver,imp)
  if not ok then skynet.loge('CYS dual souls delayed impact: ',err) end
 end)
 return true
end
function M.unequip(h,item)
 if not item or item:get_index()~=M.support then return end
 local impacts=h:get_impact_list()
 for i=#impacts,1,-1 do
  local imp=impacts[i]
  if imp:get_skill_id()==6101 then h:on_impact_fade_out(imp);h:remove_impact(imp) end
 end
end
return M
