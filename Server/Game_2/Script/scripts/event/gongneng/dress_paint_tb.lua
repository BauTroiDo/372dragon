local class = require "class"
local define = require "define"
local gbk = require "wire_charset"
-- local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local dress_paint_tb = class("dress_paint_tb", script_base)
dress_paint_tb.script_id = 999361

function dress_paint_tb:OnDefaultEvent( selfId,targetId )
		self:BeginEvent()
			self:AddText("#{BGTS_220125_58}")
			self:AddNumText( "#{BGTS_220125_01}", 6, 1 )
			self:AddNumText( "#{BGTS_220125_02}", 6, 2 )
			self:AddNumText( "#{BGTS_220125_03}", 11, 100 ) 
		self:EndEvent(sceneId)
		self:DispatchEventList(selfId,targetId)
end
function dress_paint_tb:OnEventRequest(selfId, targetId, arg, index)
	if index == 0 then
		self:OnDefaultEvent( selfId,targetId )
	elseif index == 1 or index == 2 then
		self:BeginUICommand()
		self:UICommand_AddInt(index - 1)
		self:UICommand_AddInt(targetId)
		self:EndUICommand()
		self:DispatchUICommand(selfId,99936101)
	elseif index == 100 then
		self:BeginEvent()
			self:AddText("#{BGTS_220125_04}")
			self:AddNumText( "Trở về trang chủ", 11, 0 ) 
		self:EndEvent(sceneId)
		self:DispatchEventList(selfId,targetId)
	end
end
function dress_paint_tb:ChangeOrnamentsPos( selfId,g_ExteriorType,g_CurSelExteriorID,curX,curY,curZ )
	if g_ExteriorType == 0 then
		local backdata = self:LuaFnGetExteriorBackByID(selfId,g_CurSelExteriorID)
		if not backdata then
			self:notify_tips(selfId,"#{BGTS_220125_48}")
			return
		end
		if backdata.posx == curX
		and backdata.posy == curY
		and backdata.posz == curZ then
			self:notify_tips(selfId,"Vị trí trang sức lưng không đổi.")
			return
		end
		local ret = self:LuaFnGetExteriorBackPos(selfId,g_CurSelExteriorID,curX,curY,curZ)
		if ret then
			self:notify_tips(selfId,"Lưu vị trí thành công.")
		else
			self:notify_tips(selfId,"Lưu vị trí thất bại.")
		end
	elseif g_ExteriorType == 1 then
		local backdata = self:LuaFnGetExteriorHeadByID(selfId,g_CurSelExteriorID)
		if not backdata then
			self:notify_tips(selfId,"Trang sức đầu chưa kích hoạt.")
			return
		end
		if backdata.posx == curX
		and backdata.posy == curY
		and backdata.posz == curZ then
			self:notify_tips(selfId,"Vị trí trang sức đầu không đổi.")
			return
		end
		local ret = self:LuaFnGetExteriorHeadPos(selfId,g_CurSelExteriorID,curX,curY,curZ)
		if ret then
			self:notify_tips(selfId,"Lưu vị trí thành công.")
		else
			self:notify_tips(selfId,"Lưu vị trí thất bại.")
		end
	end
end
function dress_paint_tb:UnlockOrnaments( selfId,g_Item_Pos,itemID,g_Op_Type,flag )
	if not g_Item_Pos or not itemID or itemID < 10000000 then
		self:notify_tips(selfId,"Thiếu đạo cụ kích hoạt.")
		return
	end
	if self:LuaFnGetItemTableIndexByIndex(selfId,g_Item_Pos) ~= itemID then
		self:notify_tips(selfId,"ID đạo cụ bất thường.")
		return
	end
	if g_Op_Type == 0 then
		local szItemTransfer = self:GetBagItemTransfer(selfId, g_Item_Pos)
		local name = self:GetName(selfId)
		local ret = self:ActivateExteriorBackID(selfId,g_Item_Pos,itemID)
		if ret then
			self:notify_tips(selfId,"Kích hoạt thành công.")
			local fmt = gbk.fromutf8("#HHiệp sĩ #{_INFOUSR%s} lại thêm đồ mới! Trang sức sau lưng #{_INFOMSG%s} khéo đoạt thiên công, thật khiến người ta ghen tị!")
			local message = string.format(fmt, gbk.fromutf8(name), szItemTransfer)
			self:BroadMsgByChatPipe(selfId, message, 4)
		end
	elseif g_Op_Type == 1 then
		-- {item = {38003383},index = 1},
		local szItemTransfer = self:GetBagItemTransfer(selfId, g_Item_Pos)
		local name = self:GetName(selfId)
		local ret = self:ActivateExteriorHeadID(selfId,g_Item_Pos,itemID)
		if ret then
			self:notify_tips(selfId,"Kích hoạt thành công.")
			local fmt = gbk.fromutf8("#H#{_INFOUSR%s} quả là người phong lưu tiêu sái! Nhìn trang sức đầu #{_INFOMSG%s}, vàng nạm ngọc khảm, hoa lệ biết bao!")
			local message = string.format(fmt, gbk.fromutf8(name), szItemTransfer)
			self:BroadMsgByChatPipe(selfId, message, 4)
		end
	end
end
return dress_paint_tb
