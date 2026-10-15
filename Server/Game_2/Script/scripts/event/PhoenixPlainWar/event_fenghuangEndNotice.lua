local class = require "class"
local define = require "define"
local script_base = require "script_base"
local event_fenghuangEndNotice = class("event_fenghuangEndNotice", script_base)
event_fenghuangEndNotice.DataValidator = 0
event_fenghuangEndNotice.script_id = 403011

function event_fenghuangEndNotice:OnTimer(actId, uTime, param1)
	if not uTime or uTime ~= param1 then
		return
	end
    if self:CheckActiviyValidity(actId) == 0 then
        self:StopOneActivity(actId)
    end
end

function event_fenghuangEndNotice:OnDefaultEvent(actId, iNoticeType, param2, param3, param4, param5, param6)
	if param6 ~= event_fenghuangEndNotice.DataValidator then
		return
	elseif not iNoticeType or not param2 or not param3 or not param4 or not param5 then
		return
	end
	self:StopOneActivity(actId)
	
	
    -- local nFlag = -1
    -- for i = 0, 7 do
        -- if self:LuaFnGetCopySceneData_Param(i) + self:LuaFnGetCopySceneData_Param(i + 22) < 10000 then
            -- nFlag = 1
        -- end
    -- end
    -- if nFlag ~= -1 then
        -- self:AddGlobalCountNews("#{FHZD_090708_71}")
    -- end
    -- if self:LuaFnGetCopySceneData_Param(21) > 0 then
        -- self:LuaFnSetCopySceneData_Param(21, 0)
    -- end
    -- self:StartOneActivity(actId, 60 * 1000, iNoticeType)
end
function event_fenghuangEndNotice:GetDataValidator(param1,param2)
	event_fenghuangEndNotice.DataValidator = math.random(1,2100000000)
	return event_fenghuangEndNotice.DataValidator
end
return event_fenghuangEndNotice
