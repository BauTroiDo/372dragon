local class = require "class"
local define = require "define"
local script_base = require "script_base"
local omingjiao_fangbaihua = class("omingjiao_fangbaihua", script_base)
omingjiao_fangbaihua.script_id = 011002
function omingjiao_fangbaihua:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Ta có thể truyền thụ cho ngươi độc môn khinh công của bổn phái, nhưng Yêu cầu tiêu hao 1#-15.")
    self:AddNumText("Học tập Khinh Công Minh Giáo", 12, 0)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function omingjiao_fangbaihua:OnEventRequest(selfId, targetId, arg, index)
    if index == 0 then
        if self:GetMenPai(selfId) == 1 then
            if not self:HaveSkill(selfId, 24) then
                if self:GetMoney(selfId) + self:GetMoneyJZ(selfId) < define.STUDY_MENPAI_QINGGONG_SPEND then
                    self:BeginEvent(self.script_id)
                    self:AddText("  Tiền mặt trên người ngươi không đủ 1#-15, vì vậy không thể học khinh công của môn phái này.")
                    self:EndEvent()
                    self:DispatchEventList(selfId, targetId)
                    return
                end
                self:LuaFnCostMoneyWithPriority(selfId, define.STUDY_MENPAI_QINGGONG_SPEND)
                self:AddSkill(selfId, 24)
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
            self:AddText("Học khinh công Minh Giáo Yêu cầu phải gia nhập Minh Giáo!")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        else
            self:BeginEvent(self.script_id)
            self:AddText("Ngươi không phải đệ tử Môn phái của ta, ta không thể dạy ngươi khinh công của Minh Giáo.")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        end
    end
end

function omingjiao_fangbaihua:OnMissionAccept(selfId, targetId, missionScriptId)
end

function omingjiao_fangbaihua:OnMissionRefuse(selfId, targetId, missionScriptId)
end

function omingjiao_fangbaihua:OnMissionContinue(selfId, targetId, missionScriptId)
end

function omingjiao_fangbaihua:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
end

function omingjiao_fangbaihua:OnDie(selfId, killerId)
end

return omingjiao_fangbaihua
