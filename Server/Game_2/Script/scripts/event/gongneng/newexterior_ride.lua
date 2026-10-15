local class = require "class"
local define = require "define"
local gbk = require "wire_charset"
-- local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local newexterior_ride = class("newexterior_ride", script_base)
newexterior_ride.script_id = 999900

function newexterior_ride:ReverseExteriorRideToItem(selfId,nExteriorID)
	if 1 == 1 then
		self:notify_tips(selfId, "Tạm chưa mở.")
		return
	end
	self:notify_tips(selfId, "nExteriorID。"..nExteriorID)
	if not nExteriorID or nExteriorID < 1 then
		return
	end
	if not self:CheckHaveExteriorRide(selfId,nExteriorID) then
		self:notify_tips(selfId, "Ngươi chưa kích hoạt tọa kỵ này.")
		return
	elseif self:LuaFnGetPropertyBagSpace(selfId) < 1 then
		self:notify_tips(selfId, "Xin chừa 1 ô trống trong ô đạo cụ.")
		return
	end
	local ret,itemname = self:LuaFnReverseExteriorRideToItemEx(selfId,nExteriorID)
	if ret == -1 then
		self:notify_tips(selfId, "Ngươi chưa kích hoạt tọa kỵ này.")
	elseif ret == -2 then
		self:notify_tips(selfId, "Lấy tọa kỵ thất bại.")
	elseif ret == -3 then
		self:notify_tips(selfId, "Không tồn tại tọa kỵ này.")
	elseif itemname ~= "" then
		local newpos = self:TryRecieveItem(selfId,ret)
		if newpos ~= -1 then
			self:GiveItemTip(selfId,ret,1,18)
		end
	else
		self:notify_tips(selfId, "Lỗi không xác định.")
	end
end
return newexterior_ride

