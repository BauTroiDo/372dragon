local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_huaxian = class("oluoyang_huaxian", script_base)
function oluoyang_huaxian:OnDefaultEvent(selfId, targetId)
    local PlayerName = self:GetName(selfId)
    local PlayerSex = self:GetSex(selfId)
    if PlayerSex == 0 then
        PlayerSex = "Cô nương"
    else
        PlayerSex = "Thiếu hiệp"
    end
    self:BeginEvent(self.script_id)
    self:AddText(
        "  Dương liễu xanh xanh, nước sông phẳng lặng, nghe chàng trên sông cất tiếng ca. Phía đông mặt trời mọc, phía tây mưa giăng, bảo là vô tình, mà lại hữu tình." ..
            PlayerName .. PlayerSex ..
            ", có thích cuộc sống chỉ ước uyên ương, không ước thần tiên chăng?")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oluoyang_huaxian
