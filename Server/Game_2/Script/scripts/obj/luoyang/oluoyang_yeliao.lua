local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_yeliao = class("oluoyang_yeliao", script_base)
function oluoyang_yeliao:OnDefaultEvent(selfId, targetId)
    local PlayerName = self:GetName(selfId)
    local PlayerSex = self:GetSex(selfId)
    if PlayerSex == 0 then
        PlayerSex = "Cô nương"
    else
        PlayerSex = "Thiếu hiệp"
    end
    self:BeginEvent(self.script_id)
    self:AddText("  " .. PlayerName .. PlayerSex ..
                     ", Nhạn Môn Quan đang đánh nhau sao? Sao lại có nhiều nạn dân vậy?")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oluoyang_yeliao
