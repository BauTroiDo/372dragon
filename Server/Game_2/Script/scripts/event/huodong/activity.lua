local class = require "class"
local define = require "define"
local script_base = require "script_base"
local activity = class("activity", script_base)
activity.DataValidator = 0
activity.script_id = 808000

function activity:GetDataValidator(param1,param2)
	activity.DataValidator = math.random(1,2100000000)
	return activity.DataValidator
end

function activity:OnDefaultEvent(actId, iNoticeType, param2, param3, param4, param5, param6)
	if param6 ~= activity.DataValidator then
		return
	elseif not iNoticeType or not param2 or not param3 or not param4 or not param5 then
		return
	end
    self:StartOneActivity(actId, math.floor(60 * 1000), iNoticeType)
end

function activity:OnTimer(actId, uTime, param1)
	if not uTime or uTime ~= param1 then
		return
	end
    if not self:CheckActiviyValidity(actId) then
        self:StopOneActivity(actId)
    end
end

return activity
