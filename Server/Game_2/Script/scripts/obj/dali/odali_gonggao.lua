local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_gonggao = class("odali_gonggao", script_base)
odali_gonggao.g_MissionId = 704
odali_gonggao.g_SignPost = {["x"] = 160, ["z"] = 156, ["tip"] = "赵天师"}

function odali_gonggao:OnDefaultEvent(selfId, targetId)
    if self:IsHaveMission(selfId, self.g_MissionId) then
        local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
        self:SetMissionByIndex(selfId, misIndex, 0, 1)
        self:SetMissionByIndex(selfId, misIndex, 1, 1)
        self:BeginEvent(self.script_id)
        self:AddText("#{BGDH_81009_01}")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        self:BeginEvent(self.script_id)
        self:AddText("  Người dân thành Đại Lý chú ý! Buổi tối trong thành xuất hiện kẻ thần bí giết hại người vô tội, chuyên chọn phụ nữ độc thân, trẻ con để ra tay, xin mọi người chú ý an toàn.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        self:CallScriptFunction(
            define.SCENE_SCRIPT_ID,
            "AskTheWay",
            selfId,
            2,
            self.g_SignPost["x"],
            self.g_SignPost["z"],
            self.g_SignPost["tip"]
        )
    else
        self:BeginEvent(self.script_id)
        self:AddText("Đại hội võ lâm còn 7 ngày nữa sẽ khai mạc.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

return odali_gonggao
