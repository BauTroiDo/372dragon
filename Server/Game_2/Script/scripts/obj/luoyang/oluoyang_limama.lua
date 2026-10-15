local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_limama = class("oluoyang_limama", script_base)
function oluoyang_limama:OnDefaultEvent(selfId, targetId)
    local PlayerName = self:GetName(selfId)
    local PlayerSex = self:GetSex(selfId)
    if PlayerSex == 0 then
        PlayerSex = "Cô nương"
    else
        PlayerSex = "Thiếu hiệp"
    end
    self:BeginEvent(self.script_id)
    self:AddText("  Ai da, chẳng phải là" .. PlayerName .. PlayerSex ..
                     "#{OBJ_luoyang_0015}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oluoyang_limama
