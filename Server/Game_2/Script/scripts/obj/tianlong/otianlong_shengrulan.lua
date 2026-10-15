local class = require "class"
local define = require "define"
local script_base = require "script_base"
local otianlong_shengrulan = class("otianlong_shengrulan", script_base)
otianlong_shengrulan.script_id = 013011
function otianlong_shengrulan:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Ta có thể truyền thụ cho ngươi độc môn khinh công của bổn phái, nhưng Yêu cầu tiêu hao 1#-15.")
    self:AddNumText("Học khinh công phái Đại Lý", 12, 0)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function otianlong_shengrulan:OnEventRequest(selfId, targetId, arg, index)
    if index == 0 then
        if self:GetMenPai(selfId) == 6 then
            if not self:HaveSkill(selfId, 29) then
                if self:GetMoney(selfId) + self:GetMoneyJZ(selfId) < define.STUDY_MENPAI_QINGGONG_SPEND then
                    self:BeginEvent(self.script_id)
                    self:AddText("  Tiền mặt trên người ngươi không đủ 1#-15, vì vậy không thể học khinh công của môn phái này.")
                    self:EndEvent()
                    self:DispatchEventList(selfId, targetId)
                    return
                end
                self:LuaFnCostMoneyWithPriority(selfId, define.STUDY_MENPAI_QINGGONG_SPEND)
                self:AddSkill(selfId, 29)
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
            self:AddText("Học khinh công chùa Thiên Long yêu cầu phải gia nhập phái Đại Lý trước!")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        else
            self:BeginEvent(self.script_id)
            self:AddText("Ngươi không phải đệ tử của bản môn phái, ta không thể dạy khinh công phái Đại Lý cho ngươi được.")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        end
    end
end

function otianlong_shengrulan:OnMissionAccept(selfId, targetId, missionScriptId)
end

function otianlong_shengrulan:OnMissionRefuse(selfId, targetId, missionScriptId)
end

function otianlong_shengrulan:OnMissionContinue(selfId, targetId, missionScriptId)
end

function otianlong_shengrulan:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
end

function otianlong_shengrulan:OnDie(selfId, killerId)
end

return otianlong_shengrulan
