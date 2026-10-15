local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oxingxiu_chuchenzi = class("oxingxiu_chuchenzi", script_base)
oxingxiu_chuchenzi.script_id = 016005
function oxingxiu_chuchenzi:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Ta có thể truyền thụ cho ngươi độc môn khinh công của bổn phái, nhưng Yêu cầu tiêu hao 1#-15.")
    self:AddNumText("Học tập Khinh Công Tinh Túc", 12, 0)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oxingxiu_chuchenzi:OnEventRequest(selfId, targetId, arg, index)
    if index == 0 then
        if self:GetMenPai(selfId) == 5 then
            if not self:HaveSkill(selfId, 28) then
                if self:GetMoney(selfId) + self:GetMoneyJZ(selfId) < define.STUDY_MENPAI_QINGGONG_SPEND then
                    self:BeginEvent(self.script_id)
                    self:AddText("  Tiền mặt trên người ngươi không đủ 1#-15, vì vậy không thể học khinh công của môn phái này.")
                    self:EndEvent()
                    self:DispatchEventList(selfId, targetId)
                    return
                end
                self:LuaFnCostMoneyWithPriority(selfId, define.STUDY_MENPAI_QINGGONG_SPEND)
                self:AddSkill(selfId, 28)
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
            self:AddText("Học tập Khinh Công Tinh Túc Yêu cầu trước tiên gia nhập Môn phái Tinh Túc!")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        else
            self:BeginEvent(self.script_id)
            self:AddText("Ngươi không phải là đệ tử của Môn phái này, ta không thể dạy ngươi Khinh Công Tinh Túc.")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        end
    end
end

function oxingxiu_chuchenzi:OnMissionAccept(selfId, targetId, missionScriptId)
end

function oxingxiu_chuchenzi:OnMissionRefuse(selfId, targetId, missionScriptId)
end

function oxingxiu_chuchenzi:OnMissionContinue(selfId, targetId, missionScriptId)
end

function oxingxiu_chuchenzi:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
end

function oxingxiu_chuchenzi:OnDie(selfId, killerId)
end

return oxingxiu_chuchenzi
