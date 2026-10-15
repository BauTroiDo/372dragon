local class = require "class"
local script_base = require "script_base"
local hongfu_npc = class("hongfu_npc", script_base)

function hongfu_npc:OnOpenUI(selfId)
end

function hongfu_npc:GetReward(selfId)
	self:notify_tips(selfId, "Chức năng này tạm chưa mở.")
end

function hongfu_npc:NpcText(selfId)
end

return hongfu_npc
