local class = require "class"
local script_base = require "script_base"
local hongfu_box = class("hongfu_box", script_base)

function hongfu_box:OnOpenUI(selfId)
end

function hongfu_box:GetHongFuDian(selfId)
	self:notify_tips(selfId, "Chức năng này tạm chưa mở.")
end

function hongfu_box:GetHFReward(selfId)
	self:notify_tips(selfId, "Chức năng này tạm chưa mở.")
end

function hongfu_box:NpcText(selfId)
end

return hongfu_box
