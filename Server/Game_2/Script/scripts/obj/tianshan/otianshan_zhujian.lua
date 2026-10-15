local class = require "class"
local define = require "define"
local script_base = require "script_base"
local otianshan_zhujian = class("otianshan_zhujian", script_base)
otianshan_zhujian.script_id = 017003
function otianshan_zhujian:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Ta có thể truyền thụ cho ngươi độc môn khinh công của bổn phái, nhưng Yêu cầu tiêu hao 1#-15.")
    self:AddNumText("Học tập khinh công Thiên Sơn", 12, 0)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function otianshan_zhujian:OnEventRequest(selfId, targetId, arg, index)
    if index == 0 then
        if self:GetMenPai(selfId) == 7 then
            if not self:HaveSkill(selfId, 30) then
                if self:GetMoney(selfId) + self:GetMoneyJZ(selfId) < define.STUDY_MENPAI_QINGGONG_SPEND then
                    self:BeginEvent(self.script_id)
                    self:AddText("  Tiền mặt trên người ngươi không đủ 1#-15, vì vậy không thể học khinh công của môn phái này.")
                    self:EndEvent()
                    self:DispatchEventList(selfId, targetId)
                    return
                end
                self:LuaFnCostMoneyWithPriority(selfId, define.STUDY_MENPAI_QINGGONG_SPEND)
                self:AddSkill(selfId, 30)
                self:DelSkill(selfId, 34)
                self:BeginEvent(self.script_id)
                self:AddText("  Chúc mừng ngươi học được khinh công của bổn môn, hy vọng ngươi tiếp tục nỗ lực để phát dương quang đại bổn môn.")
                self:EndEvent()
                self:DispatchEventList(selfId, targetId)
            else
                self:BeginEvent(self.script_id)
                self:AddText("Ngươi chẳng phải đã học được rồi sao?")
                self:EndEvent()
                self:DispatchEventList(selfId, targetId)
            end
        elseif self:GetMenPai(selfId) == 9 then
            self:BeginEvent(self.script_id)
            self:AddText("Học tập khinh công Thiên Sơn Yêu cầu trước tiên gia nhập Môn phái Thiên Sơn!")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        else
            self:BeginEvent(self.script_id)
            self:AddText("Ngươi không phải là đệ tử của Môn phái ta, ta không thể dạy ngươi khinh công của Thiên Sơn.")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        end
    end
end

function otianshan_zhujian:OnMissionAccept(selfId, targetId, missionScriptId)
end

function otianshan_zhujian:OnMissionRefuse(selfId, targetId, missionScriptId)
end

function otianshan_zhujian:OnMissionContinue(selfId, targetId, missionScriptId)
end

function otianshan_zhujian:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
end

function otianshan_zhujian:OnDie(selfId, killerId)
end

return otianshan_zhujian
