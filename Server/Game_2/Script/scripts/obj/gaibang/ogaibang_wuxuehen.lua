local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ogaibang_wuxuehen = class("ogaibang_wuxuehen", script_base)
ogaibang_wuxuehen.script_id = 010013
function ogaibang_wuxuehen:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Ta có thể truyền thụ cho ngươi độc môn khinh công của bổn phái, nhưng Yêu cầu tiêu hao 1#-15.")
    self:AddNumText("Học Cái Bang khinh công", 12, 0)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function ogaibang_wuxuehen:OnEventRequest(selfId, targetId, arg, index)
    if index == 0 then
        if self:GetMenPai(selfId) == 2 then
            if not self:HaveSkill(selfId, 25) then
                if self:GetMoney(selfId) + self:GetMoneyJZ(selfId) < define.STUDY_MENPAI_QINGGONG_SPEND then
                    self:BeginEvent(self.script_id)
                    self:AddText("  Tiền mặt trên người ngươi không đủ 1#-15, vì vậy không thể học khinh công của môn phái này.")
                    self:EndEvent()
                    self:DispatchEventList(selfId, targetId)
                    return
                end
                self:LuaFnCostMoneyWithPriority(selfId, define.STUDY_MENPAI_QINGGONG_SPEND)
                self:AddSkill(selfId, 25)
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
            self:AddText("Học tập Khinh Công Cái Bang Yêu cầu trước tiên gia nhập Môn phái Cái Bang!")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        else
            self:BeginEvent(self.script_id)
            self:AddText("Ngươi không phải đệ tử của Môn phái ta, ta không thể dạy ngươi khinh công của Cái Bang.")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        end
    end
end

function ogaibang_wuxuehen:OnMissionAccept(selfId, targetId, missionScriptId)
end

function ogaibang_wuxuehen:OnMissionRefuse(selfId, targetId, missionScriptId)
end

function ogaibang_wuxuehen:OnMissionContinue(selfId, targetId, missionScriptId)
end

function ogaibang_wuxuehen:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
end

function ogaibang_wuxuehen:OnDie(selfId, killerId)
end

return ogaibang_wuxuehen
