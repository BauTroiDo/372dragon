local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshuhe_haba = class("oshuhe_haba", script_base)
oshuhe_haba.script_id = 001170
oshuhe_haba.g_shoptableindex = 183
oshuhe_haba.g_MsgInfo = {"#{SHGZ_0612_03}", "#{SHGZ_0620_07}", "#{SHGZ_0620_08}", "#{SHGZ_0620_09}"}

function oshuhe_haba:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    local msgidx = math.random(#(self.g_MsgInfo))
    self:AddText(self.g_MsgInfo[msgidx])
    self:AddNumText("Xem xem đồ vật ngươi bán.", 7, 0)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oshuhe_haba:OnEventRequest(selfId, targetId, arg, index)
    if index == 0 then
        self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
    end
end

return oshuhe_haba
