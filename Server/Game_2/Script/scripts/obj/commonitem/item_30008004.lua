local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_30008004 = class("item_30008004", script_base)
item_30008004.script_id = 300052
item_30008004.g_ItemId = 30008004
function item_30008004:OnDefaultEvent(selfId)
    if index == 1 then
        local bCan = self:LuaFnIsCanWashPiont(selfId, 5)
        if bCan then
            local ret = self:DelItem(selfId, self.g_ItemId, 1)
            if ret then
                self:LuaFnWashPoints(selfId)
                self:BeginEvent(self.script_id)
                self:AddText("#YĐại Tẩy Tủy Đan")
                self:AddText("  Ngươi đã thành công đem #Ytất cả đã phân phối#W của Thuộc tính biến thành tiềm năng.")
                self:EndEvent()
                self:DispatchEventList(selfId, -1)
            end
        else
            self:BeginEvent(self.script_id)
            self:AddText("#YĐại Tẩy Tủy Đan")
            self:AddText("  Tất cả thuộc tính đều không còn điểm dư để phân phối, không thể tiến hành tẩy điểm.")
            self:EndEvent()
            self:DispatchEventList(selfId, -1)
        end
        return
    end
    if index == 2 then
        self:BeginUICommand()
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
        return
    end
end

function item_30008004:IsSkillLikeScript(selfId)
    return 0
end

return item_30008004
