local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluzhishen = class("oluzhishen", script_base)
oluzhishen.script_id = 760705
oluzhishen.g_FuBenScriptId = 892009
function oluzhishen:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Gan lớn dám đến thách thức bọn ta Thập Nhị Sát Tinh, thật là sống không kiên nhẫn rồi!")
    self:AddNumText("Quyết chiến Lỗ Chí Sinh", 6, 1)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluzhishen:OnEventRequest(selfId, targetId, arg, index)
    if 1 == self:CallScriptFunction(self.g_FuBenScriptId, "IsSJZTimerRunning") then
        return
    end
    if self:GetTeamLeader(selfId) ~= selfId then
        self:BeginEvent(self.script_id)
        self:AddText("#{PMF_20080521_07}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    local ret, msg = self:CallScriptFunction(self.g_FuBenScriptId, "CheckHaveBOSS")
    if 1 == ret then
        self:BeginEvent(self.script_id)
        self:AddText(msg)
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return
    end
    self:CallScriptFunction(self.g_FuBenScriptId, "OpenSJZTimer", 7, self.script_id, -1, -1)
    self:BeginUICommand()
    self:EndUICommand()
    self:DispatchUICommand(selfId, 1000)
end

function oluzhishen:OnSJZTimer(step, data1, data2)
    if 7 == step then
        self:CallScriptFunction(self.g_FuBenScriptId, "TipAllHuman", "Đếm ngược 5 giây")
        return
    end
    if 6 == step then
        self:CallScriptFunction(self.g_FuBenScriptId, "TipAllHuman", "Đếm ngược 4 giây")
        return
    end
    if 5 == step then
        self:CallScriptFunction(self.g_FuBenScriptId, "TipAllHuman", "Đếm ngược 3 giây")
        return
    end
    if 4 == step then
        self:CallScriptFunction(self.g_FuBenScriptId, "TipAllHuman", "Đếm ngược 2 giây")
        return
    end
    if 3 == step then
        self:CallScriptFunction(self.g_FuBenScriptId, "TipAllHuman", "Đếm ngược 1 giây")
        return
    end
    if 2 == step then
        self:CallScriptFunction(self.g_FuBenScriptId, "TipAllHuman", "Lỗ Chí Sinh đã vào trận, đại hiệp chuẩn bị nghênh chiến!")
        self:CallScriptFunction(self.g_FuBenScriptId, "DeleteBOSS", "luzhishen_NPC")
        return
    end
    if 1 == step then
        self:CallScriptFunction(self.g_FuBenScriptId, "CreateBOSS", "luzhishen_BOSS", -1, -1)
        return
    end
end

return oluzhishen
