local class = require "class"
local define = require "define"
local script_base = require "script_base"
local daxishuidan = class("daxishuidan", script_base)
daxishuidan.script_id = 300042
daxishuidan.g_ItemId = 30008004
daxishuidan.g_UseScriptId = 300052

function daxishuidan:OnDefaultEvent(selfId)
    self:BeginEvent(self.script_id)
    self:AddText("#YĐại Tẩy Tủy Đan")
    self:AddText("  Sau khi sử dụng có thể đem tất cả điểm đã phân phối của biến thành tiềm năng.")
    self:AddNumText("Ta muốn tẩy điểm ngay bây giờ!", 0, 1)
    self:AddNumText("Để sau hẵng nói", 0, 2)
    self:EndEvent()
    self:DispatchEventList(selfId, -1)
    return 0
end

function daxishuidan:IsSkillLikeScript(selfId) return 0 end

function daxishuidan:WashPoint(selfId, nType, nPoint, szStr)
    local ret = self:DelItem(selfId, self.g_ItemId, 1)
    if ret then
        self:LuaFnWashPoints(selfId)
        self:BeginEvent(self.script_id)
        self:AddText("#YĐại Tẩy Tủy Đan")
        self:AddText("  Bạn tẩy điểm thành công.")
        self:EndEvent()
        self:DispatchEventList(selfId, -1)
    end
end

function daxishuidan:OnEventRequest(selfId, targetId, arg, index)
    self:WashPoint(selfId, index)
end

return daxishuidan
