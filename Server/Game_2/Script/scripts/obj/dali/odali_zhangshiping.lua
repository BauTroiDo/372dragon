local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_zhangshiping = class("odali_zhangshiping", script_base)
odali_zhangshiping.script_id = 002076
odali_zhangshiping.g_shoptableindex = 33
function odali_zhangshiping:OnDefaultEvent(selfId, targetId)
    self:AddText("#{QZG_80919_1}")
    self:AddNumText("Giới thiệu Thương nhân", 11, 1)
    self:AddNumText("Mở tiệm", 7, 2)
end

function odali_zhangshiping:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
        self:BeginEvent(self.script_id)
        self:AddText("#{SHANGREN_JIESHAO_02}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 2 then
        if (self:LuaFnGetAvailableItemCount(selfId, 40002000) == 1) then
            self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
        else
            self:BeginEvent(self.script_id)
            self:AddText("Các hạ không có Thương nhân Ngân phiếu, giao dịch giữa ta và ngươi từ đâu mà bàn?")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        end
    end
end

return odali_zhangshiping
