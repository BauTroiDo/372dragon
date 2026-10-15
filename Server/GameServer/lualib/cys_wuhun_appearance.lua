-- GL soul operations with CY presentation and explicit state acknowledgements.
local M={}
local visuals={{{744,745,746},{762,763,764}},{{741,742,743},{759,760,761}},{{732,733,734},{750,751,752}},{{735,736,737},{753,754,755}},{{738,739,740},{756,757,758}},{{729,730,731},{747,748,749}}}
local bases={[10156001]={699,703},[10156002]={704,705},[10156003]={699,703},[10156004]={704,705}}
local function integer(n,a,b)return type(n)=='number' and n%1==0 and n>=a and n<=b end
function M.visual(item,compound,show,yy,qian,kun,unlocked)
 if item==10156901 then return show==0 and 0 or 704,show==0 and -1 or item end
 if not bases[item] or show==0 then return 0,-1 end
 local side=yy==1 and 2 or 1
 local index=side==1 and qian or kun
 if not index or index==0 then side=3-side;index=side==1 and qian or kun end
 local state=unlocked and (unlocked[tostring(index)] or unlocked[index])
 if integer(index,1,6) and state and integer(state.level,1,10) then
  local tier=state.level>=8 and 3 or state.level>=5 and 2 or 1
  return visuals[index][side][tier],item
 end
 return bases[item][(compound or 0)>=5 and 2 or 1],item
end
function M.snapshot(s,h)
 h:send_wuhun_wg(h:get_obj_id(),2)
 s:BeginUICommand()
 for _,v in ipairs({h:get_attrib('wuhun_yy_flag') or 0,h:get_attrib('huanhun_qian_index') or 0,h:get_attrib('huanhun_kun_index') or 0,h:get_attrib('wuhun_show_flag')==0 and 0 or 1})do s:UICommand_AddInt(v)end
 s:EndUICommand();s:DispatchUICommand(h:get_obj_id(),888800)
end
local function eligible(s,h)
 local item=h:get_equip_container():get_item(18)
 if item and item:get_index()==10156901 then s:notify_tips(h:get_obj_id(),'Võ hồn Huyền Giáp đang dùng bộ kỹ năng cố định cấp 1.');return false end
 if h:get_attrib('level')<80 then s:notify_tips(h:get_obj_id(),'Cần đạt cấp 80 để sử dụng Huyễn hồn.');return false end
 if not h:get_equip_container():get_item(18) then s:notify_tips(h:get_obj_id(),'Hãy đeo Võ hồn trước.');return false end
 return true
end
function M.slot(s,h,side,id)
 if not integer(side,0,1) or not integer(id,0,6) then return end
 if not eligible(s,h) then M.snapshot(s,h);return end
 local unlocked=h:get_wuhun_wg()
 if id~=0 and not (unlocked[tostring(id)] or unlocked[id]) then
  s:notify_tips(h:get_obj_id(),'Huyễn hồn chưa được kích hoạt.');M.snapshot(s,h);return
 end
 h:set_huanhun_qk(side,id);h:item_flush();h:send_refresh_attrib();M.snapshot(s,h)
end
function M.operate(s,id,fn,arg,original)
 local h=s.scene:get_obj_by_id(id);if not h or h:get_obj_type()~='human' then return end
 if fn=='CysState' or fn=='OpenChangeWg' then M.snapshot(s,h);return end
 if fn=='SetShowWuhun' then
  if integer(arg,0,1) then h:send_wuhun_show_state(arg);h:item_flush() end
 elseif fn=='TakeOut' then M.slot(s,h,arg,0);return
 elseif fn=='SwitchYY' then
  if integer(arg,0,1) and eligible(s,h) then original(s,id,arg);h:item_flush() end
 elseif fn=='ActiveWg' or fn=='LevelUpWg' or fn=='GradeUpWg' then
  if not integer(arg,1,6) or not eligible(s,h) then M.snapshot(s,h);return end
  local cfg=s:GetWuHunWgConfig(arg)
  if not cfg then M.snapshot(s,h);return end
  if fn~='ActiveWg' then
   local key=s:GetWuHunWgIndex(id,arg)
   if key==0 or not s:GetWuHunWgLevelConfig()[key] then M.snapshot(s,h);return end
  end
  -- Keep GL's material alternatives, gold/jiaozi priority, levels and costs.
  original(s,id,arg);h:update_wuhun_visual();h:send_refresh_attrib()
 end
 M.snapshot(s,h)
end
return M
