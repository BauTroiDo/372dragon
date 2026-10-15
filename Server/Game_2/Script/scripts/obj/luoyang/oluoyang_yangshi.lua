local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_yangshi = class("oluoyang_yangshi", script_base)
function oluoyang_yangshi:OnDefaultEvent(selfId, targetId)
    local PlayerName = self:GetName(selfId)
    local PlayerSex = self:GetSex(selfId)
    if PlayerSex == 0 then
        PlayerSex = "Cô nương"
    else
        PlayerSex = "Thiếu hiệp"
    end
    self:BeginEvent(self.script_id)
    self:AddText("  " .. PlayerName .. PlayerSex ..
                     ", ngươi cũng đến bái kiến sư phụ sao? Ta và sư huynh chuyên trình đến thăm lão nhân gia, không đợi được sư phụ thì ta sẽ không đi.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oluoyang_yangshi
