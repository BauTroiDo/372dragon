--事件
--事件：传送到圣兽山

local class = require "class"
local script_base = require "script_base"
local chuansong_to_shengshoushan = class("chuansong_to_shengshoushan", script_base)
local g_MissionName="#{QSSS_090302_1}"

function chuansong_to_shengshoushan:OnEnumerate(caller, selfId)
	if self:GetLevel(selfId) >= 10 then
		caller:AddNumTextWithTarget(self.script_id, g_MissionName, 9, 1)
	else
		return
	end
end

function chuansong_to_shengshoushan:OnEventRequest(selfId)
	self:CallScriptFunction((400900), "TransferFunc", selfId, 158, 233, 225, 21)
end

return chuansong_to_shengshoushan