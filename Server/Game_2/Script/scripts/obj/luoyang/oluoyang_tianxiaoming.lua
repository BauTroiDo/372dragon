local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_tianxiaoming = class("oluoyang_tianxiaoming", script_base)
oluoyang_tianxiaoming.script_id = 000104
oluoyang_tianxiaoming.g_Key = {["stu"] = 100, ["buy"] = 101}

oluoyang_tianxiaoming.g_Skill = {
    {["id"] = 446, ["name"] = "Kỵ thuật: Lục Hành Điêu"}
}

function oluoyang_tianxiaoming:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(
        "  Nếu như ngươi là đệ tử của Cửu Đại Môn phái, có thể tìm người truyền thụ Kỹ năng cưỡi ngựa trong Môn phái để học cưỡi ngựa.")
    self:AddNumText("Mua Kỵ Thừa", 7, self.g_Key["buy"])
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_tianxiaoming:OnEventRequest(selfId, targetId, arg, index)
    local key = index
    if key == 0 then
        self:AddSkill(selfId, 21)
        self:MsgBox(selfId, targetId,
                    "  Ngươi hiện tại đã học được Kỹ năng cưỡi.")
    elseif key == self.g_Key["buy"] then
        self:DispatchShopItem(selfId, targetId, 138)
    end
end

function oluoyang_tianxiaoming:MsgBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oluoyang_tianxiaoming
