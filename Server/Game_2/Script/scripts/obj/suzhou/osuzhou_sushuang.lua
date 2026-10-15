local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_sushuang = class("osuzhou_sushuang", script_base)
osuzhou_sushuang.script_id = 001059
osuzhou_sushuang.g_shoptableindex = 35
function osuzhou_sushuang:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{QZG_80919_1}")
    self:AddNumText("Giới thiệu Thương nhân", 11, 1)
    self:AddNumText("Mở tiệm", 7, 2)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osuzhou_sushuang:OnEventRequest(selfId, targetId, arg, index)
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

return osuzhou_sushuang
