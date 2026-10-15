local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oxiaoyao_shiganlin = class("oxiaoyao_shiganlin", script_base)
oxiaoyao_shiganlin.script_id = 014012
function oxiaoyao_shiganlin:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Ta có thể truyền thụ cho ngươi độc môn khinh công của bổn phái, nhưng Yêu cầu tiêu hao 1#-15.")
    self:AddNumText("Học Tiêu Dao khinh công", 12, 0)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oxiaoyao_shiganlin:OnEventRequest(selfId, targetId, arg, index)
    if index == 0 then
        if self:GetMenPai(selfId) == 8 then
            if not self:HaveSkill(selfId, 31) then
                if self:GetMoney(selfId) + self:GetMoneyJZ(selfId) < define.STUDY_MENPAI_QINGGONG_SPEND then
                    self:BeginEvent(self.script_id)
                    self:AddText("  Tiền mặt trên người ngươi không đủ 1#-15, vì vậy không thể học khinh công của môn phái này.")
                    self:EndEvent()
                    self:DispatchEventList(selfId, targetId)
                    return
                end
                self:LuaFnCostMoneyWithPriority(selfId, define.STUDY_MENPAI_QINGGONG_SPEND)
                self:AddSkill(selfId, 31)
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
            self:AddText("Học Tiêu Dao khinh công Yêu cầu trước tiên gia nhập phái Tiêu Dao.")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        else
            self:BeginEvent(self.script_id)
            self:AddText("Ngươi không phải là đệ tử của phái Tiêu Dao, ta không thể dạy ngươi khinh công bổn môn.")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        end
    end
end

function oxiaoyao_shiganlin:OnMissionAccept(selfId, targetId, missionScriptId)
end

function oxiaoyao_shiganlin:OnMissionRefuse(selfId, targetId, missionScriptId)
end

function oxiaoyao_shiganlin:OnMissionContinue(selfId, targetId, missionScriptId)
end

function oxiaoyao_shiganlin:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
end

function oxiaoyao_shiganlin:OnDie(selfId, killerId)
end

return oxiaoyao_shiganlin
