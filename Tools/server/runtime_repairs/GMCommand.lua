-- CY: same authority as GmTool_Self; validate before touching character state.
local gbk = require "wire_charset"
local class = require "class"
local skynet = require "skynet"
local define = require "define"
local config = require "configenginer":getinstance()
local items = require "human_item_logic"
local impacts = require "impactenginer":getinstance()
local GMCommand = class("GMCommand")
local aliases = {['帮助']='help',['获取道具']='item',['获取YB']='nb',['获取金币']='vothach',
 ['获取经验']='exp',['清空背包']='clearbag',['获取状态']='impact',['回血']='heal',
 ['创建陷阱']='trap',['创建怪物']='monster',['传送']='tp',dichchuyen='tp',recover='heal',where='info',money='vothach'}
local levels={help=1,info=1,heal=1,item=2,nb=2,vothach=2,exp=2,tp=3,clearbag=3,impact=3,trap=3,monster=3}
local function integer(v,lo,hi)
 local n=tonumber(v);if not n or n~=n or n%1~=0 or n<lo or n>hi then return nil end;return n
end
local function tip(h,s) h:notify_tips(s) end
local function number(a,i,lo,hi)
 local n=integer(a[i],lo,hi);if not n then error('Tham số '..i..' phải là số nguyên từ '..lo..' đến '..hi,0) end;return n
end
function GMCommand:help(h)
 tip(h,'GM: help | info | heal | item@ID@số_lượng | vothach@số_lượng | nb@số_lượng')
 tip(h,'GM: exp@số_lượng | tp@scene@x@y | monster@ID@số_lượng | impact@ID | trap@ID | clearbag@confirm')
end
function GMCommand:info(h)
 local p=h:get_world_pos();tip(h,string.format('Scene %d; vị trí %.2f, %.2f; cấp %d',h:get_scene():get_id(),p.x,p.y,h:get_level()))
end
function GMCommand:heal(h)
 h:set_hp(h:get_max_hp());h:set_mp(h:get_max_mp());tip(h,'Đã hồi đầy Huyết và Khí.')
end
function GMCommand:vothach(h,a)
 local n=number(a,2,1,2000000000);local old=h:get_money()
 if old>2147483647-n then error('Võ Thạch vượt giới hạn lưu trữ.',0) end
 h:set_money(old+n,'GM thêm Võ Thạch');tip(h,'Đã thêm '..n..' Võ Thạch hạ phẩm.')
end
function GMCommand:nb(h,a)
 local n=number(a,2,1,2000000000);local old=h:get_yuanbao()
 if old>2147483647-n then error('Nguyên Bảo vượt giới hạn lưu trữ.',0) end
 h:set_yuanbao(old+n);tip(h,'Đã thêm '..n..' Nguyên Bảo.')
end
function GMCommand:exp(h,a)
 h:add_exp(number(a,2,1,2147483647),0);tip(h,'Đã cộng EXP theo giới hạn tích lũy của nhân vật.')
end
function GMCommand:item(h,a)
 local n=number(a,3,1,250);local id=integer(a[2],1,2147483647);local found
 for _,name in ipairs({'common_item','equip_base','gem_info','pet_equip_base'}) do
  local rows=config:get_config(name) or {}
  if id and rows[id] then found=id;break end
  if not id then for k,v in pairs(rows) do if v.name==a[2] and (v.level or 1)<=h:get_level() and (not found or k>found) then found=k end end end
 end
 if not found then error('Không tìm thấy vật phẩm. Dùng item@ID@số_lượng.',0) end
 local _,slot=items:create_multi_item_to_bag({reason='GM chat',user_name=h:get_name(),user_guid=h:get_guid()},h,found,n,false,0,1)
 if not slot or slot==define.INVAILD_ID then error('Không thể cấp vật phẩm; kiểm tra túi.',0) end
 tip(h,'Đã cấp vật phẩm '..found..', số lượng '..n..'.')
end
function GMCommand:clearbag(h,a)
 if a[2]~='confirm' then error('Dùng clearbag@confirm để xóa vật phẩm trong túi đồ/nguyên liệu.',0) end
 local bag=h:get_prop_bag_container()
 for i=0,199 do if bag:get_item(i) then items:erase_item_by_bag_index({reason='GM clearbag'},h,i) end end
 tip(h,'Đã xóa vật phẩm trong túi đồ/nguyên liệu.')
end
function GMCommand:impact(h,a)
 local id=number(a,2,1,2147483647)
 if not (config:get_config('std_impact_config') or {})[id] then error('Không tìm thấy hiệu ứng.',0) end
 impacts:send_impact_to_unit(h,id,h,500,false,0)
end
function GMCommand:trap(h,a)
 local id=number(a,2,1,2147483647)
 if not (config:get_config('special_obj_data') or {})[id] then error('Không tìm thấy cấu hình bẫy.',0) end
 local obj=h:skill_create_obj_specail(h:get_world_pos(),id)
 if not obj then error('Không thể tạo bẫy với ID này.',0) end;obj:set_continuance(100000)
end
function GMCommand:monster(h,a)
 local id=number(a,2,1,2147483647);local count=a[3] and number(a,3,1,100) or 1
 if not (config:get_config('monster_attr_ex') or {})[id] then error('Không tìm thấy cấu hình quái.',0) end
 local p=h:get_world_pos();local scene=h:get_scene();local made=0
 for i=1,count do
  local oid=scene:create_temp_monster(id,p.x,p.y,4,define.INVAILD_ID,define.INVAILD_ID)
  local obj=oid and oid>0 and scene:get_obj_by_id(oid)
  if not obj then tip(h,'Đã tạo '..made..' quái; dừng vì không tạo được quái tiếp theo.');return end
  obj:set_die_time(60000);made=made+1
 end
 tip(h,'Đã tạo '..made..' quái, tự xóa sau 60 giây.')
end
function GMCommand:tp(h,a)
 local id=number(a,2,0,9999);local x=number(a,3,0,65535);local y=number(a,4,0,65535)
 if not (config:get_config('scene_info') or {})['scene'..id] then error('Scene không tồn tại.',0) end
 local dest='.SCENE_'..id;local p={x=x,y=y}
 local ok,valid=pcall(skynet.call,dest,'lua','cys_gm_valid_destination',p)
 if not ok or not valid then error('Scene chưa sẵn sàng hoặc tọa độ không đi được.',0) end
 if id==h:get_scene():get_id() then h:on_teleport(p) else h:change_scene(id,p) end
 tip(h,'Đã yêu cầu dịch chuyển đến scene '..id..'.')
end
function GMCommand:process(h,content)
 if h._cys_gm_busy then tip(h,'Lệnh GM trước đang xử lý.');return false end
 if type(content)~='string' or #content>512 then return false end
 h._cys_gm_busy=true
 local ok,err=pcall(function()
  local level=h:get_scene():get_script_engienr():call(900066,'IsGM',h:get_obj_id()) or 0
  if level<1 then error('Tài khoản không có quyền GM.',0) end
  local a={};for part in (gbk.toutf8(content)..'@'):gmatch('(.-)@') do a[#a+1]=part end
  local cmd=aliases[a[1]] or a[1]:lower()
  if not levels[cmd] then error('Lệnh GM không tồn tại. Gõ help để xem hướng dẫn.',0) end
  if level<levels[cmd] then error('Quyền GM không đủ cho lệnh này.',0) end
  -- IsGM queries the account service and can yield. Reject stale character owners.
  if h._leaving or h._scene_detached then error('Nhân vật đang rời bản đồ.',0) end
  self[cmd](self,h,a)
 end)
 h._cys_gm_busy=nil
 if not ok then
  -- Expected validation errors have no source prefix. Internal failures stay in server logs.
  local msg=tostring(err)
  if msg:match('%.lua:%d+:') then skynet.logw('CYS GM command failed',msg);msg='Lệnh GM không hoàn tất; kiểm tra ID và tham số.' end
  tip(h,msg)
 end
 return ok
end
return GMCommand
