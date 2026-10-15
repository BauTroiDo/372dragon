local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshuhe_yunqianqian = class("oshuhe_yunqianqian", script_base)
oshuhe_yunqianqian.script_id = 001186
oshuhe_yunqianqian.g_shoptableindex = 27
oshuhe_yunqianqian.g_MsgInfo = {"#{SHGZ_0612_08}", "#{SHGZ_0620_22}", "#{SHGZ_0620_23}", "#{SHGZ_0620_24}"}

function oshuhe_yunqianqian:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    local msgidx = math.random(#(self.g_MsgInfo))
    self:AddText(self.g_MsgInfo[msgidx])
    self:AddNumText("Xem xem đồ vật ngươi bán.", 7, 0)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oshuhe_yunqianqian:OnEventRequest(selfId, targetId, arg, index)
    if index == 0 then
        self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
    end
end

return oshuhe_yunqianqian
