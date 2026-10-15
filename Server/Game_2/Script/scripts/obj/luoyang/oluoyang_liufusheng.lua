local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_liufusheng = class("oluoyang_liufusheng", script_base)
function oluoyang_liufusheng:OnDefaultEvent(selfId, targetId)
    local PlayerName = self:GetName(selfId)
    local PlayerSex = self:GetSex(selfId)
    if PlayerSex == 0 then
        PlayerSex = "Cô nương"
    else
        PlayerSex = "Thiếu hiệp"
    end
    self:BeginEvent(self.script_id)
    self:AddText("  Yên tâm đi." .. PlayerName .. PlayerSex ..
                     ", ta nhất định sẽ cố gắng tham gia so tài của ngươi.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oluoyang_liufusheng
