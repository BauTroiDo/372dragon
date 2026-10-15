local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_30008005 = class("item_30008005", script_base)
item_30008005.script_id = 300053
item_30008005.g_ItemId = 30008005
function item_30008005:OnDefaultEvent(selfId)
    if index == 1 then
        if not self:LuaFnIsCanWashPiont(selfId, 0) then
            self:BeginEvent(self.script_id)
            self:AddText("#YTiểu Tẩy Tủy Đan")
            self:AddText("  Cường lực Thuộc tính đã không còn điểm phân phối dư, không thể tiến hành tẩy điểm.")
            self:EndEvent()
            self:DispatchEventList(selfId, -1)
        else
            self:WashPoint(selfId, 0, 5, "力量")
        end
        return
    elseif index == 2 then
        if not self:LuaFnIsCanWashPiont(selfId, 1) then
            self:BeginEvent(self.script_id)
            self:AddText("#YTiểu Tẩy Tủy Đan")
            self:AddText("  Nội lực Thuộc tính đã không còn điểm phân phối dư, không thể tiến hành tẩy điểm.")
            self:EndEvent()
            self:DispatchEventList(selfId, -1)
        else
            self:WashPoint(selfId, 1, 5, "灵气")
        end
        return
    elseif index == 3 then
        if not self:LuaFnIsCanWashPiont(selfId, 2) then
            self:BeginEvent(self.script_id)
            self:AddText("#YTiểu Tẩy Tủy Đan")
            self:AddText("  Thể lực Thuộc tính đã không còn điểm phân phối dư, không thể tiến hành tẩy điểm.")
            self:EndEvent()
            self:DispatchEventList(selfId, -1)
        else
            self:WashPoint(selfId, 2, 5, "体力")
        end
        return
    elseif index == 4 then
        if not  self:LuaFnIsCanWashPiont(selfId, 3) then
            self:BeginEvent(self.script_id)
            self:AddText("#YTiểu Tẩy Tủy Đan")
            self:AddText("  Trí lực Thuộc tính đã không còn điểm phân phối dư, không thể tiến hành tẩy điểm.")
            self:EndEvent()
            self:DispatchEventList(selfId, -1)
        else
            self:WashPoint(selfId, 3, 5, "定力")
        end
        return
    elseif index == 5 then
        if not self:LuaFnIsCanWashPiont(selfId, 4) then
            self:BeginEvent(self.script_id)
            self:AddText("#YTiểu Tẩy Tủy Đan")
            self:AddText("  Thân pháp Thuộc tính đã không còn điểm phân phối dư, không thể tiến hành tẩy điểm.")
            self:EndEvent()
            self:DispatchEventList(selfId, -1)
        else
            self:WashPoint(selfId, 4, 5, "身法")
        end
        return
    elseif index == 6 then
        self:BeginUICommand()
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
        return
    end
end

function item_30008005:IsSkillLikeScript(selfId)
    return 0
end

function item_30008005:WashPoint(selfId, nType, nPoint, szStr)
    local ret = self:DelItem(selfId, self.g_ItemId, 1)
    if ret then
        local nNumber = self:LuaFnWashSomePoints(selfId, nType, nPoint)
        self:BeginEvent(self.script_id)
        self:AddText("#YTiểu Tẩy Tủy Đan")
        self:AddText("  Ngươi đã thành công đem #Y" .. tonumber(nNumber) .. "Điểm #Wđã phân phối của #Y" .. szStr .. "#WThuộc tính biến thành Tiềm Năng.")
        self:EndEvent()
        self:DispatchEventList(selfId, -1)
    end
end

return item_30008005
