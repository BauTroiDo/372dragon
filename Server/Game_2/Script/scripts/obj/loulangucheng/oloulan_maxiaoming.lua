local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_maxiaoming = class("oloulan_maxiaoming", script_base)
oloulan_maxiaoming.script_id = 001158
function oloulan_maxiaoming:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(
        "  Tại Tây Vực, bạch lạc đà rất hiếm có. Ban đầu chỉ có một vài quý tộc cưỡi, sau này một số phú thương cũng bỏ ra rất nhiều tiền của để tìm kiếm. Lâu dần, người ta coi bạch lạc đà là tượng trưng của sự giàu có...#rTa đây vừa hay có một ít bạch lạc đà, đại hiệp có muốn mua không?")
    self:AddNumText("Mua Kỵ Thừa", 7, 1)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oloulan_maxiaoming:OnEventRequest(selfId, targetId, arg, index)
    local key = index
    if key == 1 then self:DispatchShopItem(selfId, targetId, 185) end
end

function oloulan_maxiaoming:MsgBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oloulan_maxiaoming
