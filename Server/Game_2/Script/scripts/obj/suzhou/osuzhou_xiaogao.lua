local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_xiaogao = class("osuzhou_xiaogao", script_base)
osuzhou_xiaogao.script_id = 001070
osuzhou_xiaogao.g_shoptableindex = 168
function osuzhou_xiaogao:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{PFBQ_20070926_001}")
    self:AddNumText("Trùng Cấu Phối Phương", 7, 100)
    self:AddNumText("Về việc mua lại công thức", 11, 101)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osuzhou_xiaogao:OnEventRequest(selfId, targetId, arg, index)
    local key = index
    if key == 100 then
        self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
    elseif key == 101 then
        self:BeginEvent(self.script_id)
        self:AddText("#{CGPF_2007_0109}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

return osuzhou_xiaogao
