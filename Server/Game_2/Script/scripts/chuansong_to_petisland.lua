--事件
--传送到珍兽岛

local class = require "class"
local script_base = require "script_base"
local chuansong_to_petisland = class("chuansong_to_petisland", script_base)
local g_MissionName="Đến Huyền Vũ Đảo"

function chuansong_to_petisland:OnEnumerate(caller, selfId)
	if self:GetLevel(selfId) >= 10 then
		caller:AddNumTextWithTarget(self.script_id, g_MissionName, 9, -1)
	else
		return
	end
end

function chuansong_to_petisland:OnEventRequest(selfId)
	self:CallScriptFunction((400900), "TransferFunc", selfId, 39, 109, 25)
end

return chuansong_to_petisland