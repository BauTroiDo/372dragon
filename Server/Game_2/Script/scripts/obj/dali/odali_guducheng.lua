local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_guducheng = class("odali_guducheng", script_base)
function odali_guducheng:OnDefaultEvent(selfId, targetId)
    local PlayerName = self:GetName(selfId)
    local PlayerSex = self:GetSex(selfId)
    if PlayerSex == 0 then
        PlayerSex = "Cô nương"
    else
        PlayerSex = "Thiếu hiệp"
    end
    self:BeginEvent(self.script_id)
    self:AddText("  " .. PlayerName .. PlayerSex .. ", đã lâu không gặp, Hoàng thượng đang đợi ngươi đó.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return odali_guducheng
