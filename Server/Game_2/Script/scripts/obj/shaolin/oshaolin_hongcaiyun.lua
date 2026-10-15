local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshaolin_hongcaiyun = class("oshaolin_hongcaiyun", script_base)
oshaolin_hongcaiyun.script_id = 009018
function oshaolin_hongcaiyun:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Ta có thể truyền thụ cho ngươi độc môn khinh công của bổn phái, nhưng Yêu cầu tiêu hao 1#-15.")
    self:AddNumText("Học Thiếu Lâm khinh công", 12, 0)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oshaolin_hongcaiyun:OnEventRequest(selfId, targetId, arg, index)
    if index == 0 then
        if self:GetMenPai(selfId) == 0 then
            if not self:HaveSkill(selfId, 23)  then
                if self:GetMoney(selfId) + self:GetMoneyJZ(selfId) < define.STUDY_MENPAI_QINGGONG_SPEND then
                    self:BeginEvent(self.script_id)
                    self:AddText("  Tiền mặt trên người ngươi không đủ 1#-15, vì vậy không thể học khinh công của môn phái này.")
                    self:EndEvent()
                    self:DispatchEventList(selfId, targetId)
                    return
                end
                self:LuaFnCostMoneyWithPriority(selfId, define.STUDY_MENPAI_QINGGONG_SPEND)
                self:AddSkill(selfId, 23)
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
            self:AddText("Học Thiếu Lâm khinh công yêu cầu trước tiên phải gia nhập Thiếu Lâm phái!")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        else
            self:BeginEvent(self.script_id)
            self:AddText("Ngươi không phải là đệ tử của bổn Môn phái, ta không thể dạy ngươi khinh công của Thiếu Lâm.")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        end
    end
end

function oshaolin_hongcaiyun:OnMissionAccept(selfId, targetId, missionScriptId)
end

function oshaolin_hongcaiyun:OnMissionRefuse(selfId, targetId, missionScriptId)
end

function oshaolin_hongcaiyun:OnMissionContinue(selfId, targetId, missionScriptId)
end

function oshaolin_hongcaiyun:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
end

function oshaolin_hongcaiyun:OnDie(selfId, killerId)
end

return oshaolin_hongcaiyun
