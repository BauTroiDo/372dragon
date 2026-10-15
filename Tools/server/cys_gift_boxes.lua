-- CY table-backed optional boxes. Reward identities are generated only from
-- verified OptionalGiftBox rows; the client never supplies item ids/counts.
local M={}
local data=require 'cys_gift_boxes_data'
local config=require('configenginer'):getinstance()
local logic=require 'human_item_logic'
local guard=require 'cys_inventory_guard'
function M.supported(id) return data[id]~=nil end
local function valid(h,pos,expected)
 local box=h:get_prop_bag_container():get_item(pos)
 if not box or (expected and box~=expected) or box:is_lock() or box:get_lay_count()<1 then return end
 local row=data[box:get_index()]
 if not row then return end
 if h:get_level()<box:get_base_config().level then h:notify_tips('Chưa đủ cấp để mở lễ hộp.');return end
 if require('cys_mount_flight').active(h) then h:notify_tips('Hãy hạ cánh trước khi mở lễ hộp.');return end
 return box,row
end
function M.open(script,h,pos)
 if h.cys_gift_busy then return false end
 local box,row=valid(h,pos);if not box then return false end
 h.cys_gift_session={box=box,pos=pos}
 script:BeginUICommand();script:UICommand_AddInt(pos)
 for i=1,5 do script:UICommand_AddInt(0) end
 script:EndUICommand();script:DispatchUICommand(h:get_obj_id(),99825600+#row.items)
 return true
end
function M.claim(script,h,pos,...)
 local session=h.cys_gift_session
 if h.cys_gift_busy or not session or session.pos~=pos then return false end
 local box,row=valid(h,pos,session.box);if not box then h.cys_gift_session=nil;return false end
 local selected,index=0,nil
 local flags={...}
 for i=1,5 do
  local flag=flags[i]
  if i<=#row.items then
   if flag~=0 and flag~=1 then return false end
   if flag==1 then selected=selected+1;index=i end
  elseif flag~=-1 and flag~=0 and flag~=nil then return false end
 end
 if selected~=1 then return false end
 local reward=row.items[index]
 -- GUID allocation can yield. Close this session and serialize opens/claims
 -- before allocation; precommit rechecks the exact original box object.
 h.cys_gift_busy=true;h.cys_gift_session=nil
 local ok,result=pcall(function()
  return logic:create_multi_item_to_bag({reason='CY optional gift',box=box:get_index()},h,reward[1],reward[2],row.bind,1,nil,nil,function()
   if not valid(h,pos,box) then return false end
   return logic:dec_item_lay_count({reason='CY optional gift'},h,pos,1,box:get_index())
  end)
 end)
 h.cys_gift_busy=nil
 if not ok then error(result) end
 if not result then h:notify_tips('Chưa mở được lễ hộp: kiểm tra ô trống và vị trí hộp trong Túi.');return false end
 h:notify_tips('Đã mở lễ hộp và nhận vật phẩm đã chọn.')
 return true
end
return M
