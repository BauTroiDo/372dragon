local class = require "class"
local script_base = require "script_base"
local skynet = require "skynet"

local daluandou_timer = class("daluandou_timer", script_base)

daluandou_timer.script_id = 999860
daluandou_timer.main_script_id = 999861

function daluandou_timer:GetDataValidator(param1, param2)
    self.DataValidator = math.random(1, 2100000000)
    return self.DataValidator
end

function daluandou_timer:OnDefaultEvent(actId, iNoticeType, param2, param3, param4, param5, param6)
    if param6 ~= self.DataValidator then
        return
    end
    if not iNoticeType or not param2 or not param3 or not param4 or not param5 then
        return
    end
    if not self:HaveActivity(actId) then
        self:StartOneActivity(actId, 2100000000, iNoticeType, -1, -1, nil)
    end
end

function daluandou_timer:OnTimer_Second(actId, minute, hour_minute, hour, second)
	-- skynet.logw("skynet:"..second)
    if not second then
        return
    end

    -- 每 2 秒推一次 UI
    if (second % 2) == 0 then
        self:CallScriptFunction(self.main_script_id, "tick_update_ui")
		self:CallScriptFunction(self.main_script_id, "RefreshScenePlayersRelivePoint")		
    end

end

-- timer only dispatches; all time checks are in main
function daluandou_timer:OnTimer_Minute(actId, minute, hminute, hour)
    self:CallScriptFunction(self.main_script_id, "OnMinuteTick")
end

function daluandou_timer:OnTimer(actId, uTime, param1)
end

return daluandou_timer
