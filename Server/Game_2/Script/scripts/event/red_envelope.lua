local class = require "class"
local script_base = require "script_base"
local red_envelope = class("red_envelope", script_base)

function red_envelope:UpdateRedEnvelopeMD(selfId)
end

function red_envelope:SendRedEnvelopeUI(selfId)
	self:notify_tips(selfId, "Chức năng lì xì tạm chưa mở.")
end

function red_envelope:TakeRedEnvelope(selfId)
	self:notify_tips(selfId, "Chức năng lì xì tạm chưa mở.")
end

function red_envelope:QueryRedEnvelope(selfId)
end

function red_envelope:QueryRedEnvelopeLog(selfId)
end

function red_envelope:CheckPlayer(selfId)
	return 0
end

return red_envelope
