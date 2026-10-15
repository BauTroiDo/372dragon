local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_yisha = class("oloulan_yisha", script_base)
oloulan_yisha.script_id = 001133
oloulan_yisha.g_eventList = {805029, 805030}

function oloulan_yisha:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{loulan_zhengrong_20080329}")
    self:AddNumText("Tu chỉnh dung mạo tửu quán", 11, 1)
    self:AddNumText("Tu chỉnh dung mạo", 6, 2)
    self:AddNumText("Sửa đổi ảnh đại diện tửu quán", 11, 3)
    self:AddNumText("Sửa đổi ảnh đại diện", 6, 4)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oloulan_yisha:OnEventRequest(selfId, targetId, arg, index)
    local NumText = index
    if NumText == 1 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_088}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif NumText == 3 then
        self:BeginEvent(self.script_id)
        self:AddText("#{INTERHEAD_XML_008}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif NumText == 2 then
        self:CallScriptFunction(805029, "OnEnumerate", self, selfId, targetId)
    elseif NumText == 4 then
        self:CallScriptFunction(805030, "OnEnumerate", self, selfId, targetId)
    end
end

return oloulan_yisha
