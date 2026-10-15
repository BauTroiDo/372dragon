local class = require "class"
local define = require "define"
local script_base = require "script_base"
local xiaoxishuidan = class("xiaoxishuidan", script_base)
xiaoxishuidan.script_id = 300043
xiaoxishuidan.g_ItemId = 30008005
xiaoxishuidan.g_UseScriptId = 300053

function xiaoxishuidan:OnDefaultEvent(selfId)
    self:BeginEvent(self.script_id)
    self:AddText("#YTiểu Tẩy Tủy Đan")
    self:AddText("  Sau khi sử dụng có thể đem #Y5 điểm#W của một Thuộc tính nào đó từ điểm đã phân phối biến thành tiềm năng.")
    self:AddNumText("Quên 5 điểm Cường lực", 0, 1)
    self:AddNumText("Quên 5 điểm Nội lực", 0, 2)
    self:AddNumText("Quên 5 điểm Thể lực", 0, 3)
    self:AddNumText("Quên 5 điểm Trí lực", 0, 4)
    self:AddNumText("Quên 5 điểm Thân pháp", 0, 5)
    self:AddNumText("Để sau hẵng nói", 0, 6)
    self:EndEvent()
    self:DispatchEventList(selfId, -1)
    return 0
end

function xiaoxishuidan:IsSkillLikeScript(selfId) return 0 end

function xiaoxishuidan:WashPoint(selfId, nType, nPoint, szStr)
    local ret = self:DelItem(selfId, self.g_ItemId, 1)
    if ret then
        local nNumber = self:LuaFnWashSomePoints(selfId, nType, nPoint)
        self:BeginEvent(self.script_id)
        self:AddText("#YTiểu Tẩy Tủy Đan")
        self:AddText("  Ngươi đã thành công đem #Y" .. tonumber(nNumber) .. "Điểm #Wđã phân phối của #Y" .. szStr ..  "#WThuộc tính biến thành Tiềm Năng.")
        self:EndEvent()
        self:DispatchEventList(selfId, -1)
    end
end

function xiaoxishuidan:OnEventRequest(selfId, targetId, arg, index)
    local str_list = {
        "力量", "灵气", "体力", "定力", "身法"
    }
    self:WashPoint(selfId, index, 5, str_list[index])
end

return xiaoxishuidan
