local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oemei_sunerniang = class("oemei_sunerniang", script_base)
oemei_sunerniang.script_id = 15014
function oemei_sunerniang:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Ta có thể truyền thụ cho ngươi độc môn khinh công của bổn phái, nhưng Yêu cầu tiêu hao 1#-15.")
    self:AddNumText("Học khinh công Nga My", 12, 0)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oemei_sunerniang:OnEventRequest(selfId, targetId, arg, index)
    if index == 0 then
        if self:GetMenPai(selfId) == 4 then
            if not self:HaveSkill(selfId, 27) then
                if self:GetMoney(selfId) + self:GetMoneyJZ(selfId) < define.STUDY_MENPAI_QINGGONG_SPEND then
                    self:BeginEvent(self.script_id)
                    self:AddText("  Tiền mặt trên người ngươi không đủ 1#-15, vì vậy không thể học khinh công của môn phái này.")
                    self:EndEvent()
                    self:DispatchEventList(selfId, targetId)
                    return
                end
                self:LuaFnCostMoneyWithPriority(selfId, define.STUDY_MENPAI_QINGGONG_SPEND)
                self:AddSkill(selfId, 27)
                self:DelSkill(selfId, 34)
                self:BeginEvent(self.script_id)
                self:AddText("Chúc mừng ngươi học được khinh công của bổn môn, hy vọng ngươi tiếp tục nỗ lực để phát dương quang đại bổn môn.")
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
            self:AddText("Muốn học khinh công Nga My Yêu cầu trước tiên gia nhập Môn phái Nga My!")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        else
            self:BeginEvent(self.script_id)
            self:AddText("Ngươi không phải đệ tử Môn phái ta, ta không thể dạy ngươi khinh công của Nga My.")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        end
    end
end

function oemei_sunerniang:OnMissionAccept(selfId, targetId, missionScriptId)
end

function oemei_sunerniang:OnMissionRefuse(selfId, targetId, missionScriptId)
end

function oemei_sunerniang:OnMissionContinue(selfId, targetId, missionScriptId)
end

function oemei_sunerniang:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
end

function oemei_sunerniang:OnDie(selfId, killerId)
end

return oemei_sunerniang
