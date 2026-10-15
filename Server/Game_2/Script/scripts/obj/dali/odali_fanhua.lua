local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_fanhua = class("odali_fanhua", script_base)
function odali_fanhua:OnDefaultEvent(selfId, targetId)
    local PlayerName = self:GetName(selfId)
    local PlayerSex = self:GetSex(selfId)
    if PlayerSex == 0 then
        PlayerSex = "Cô nương"
    else
        PlayerSex = "Thiếu hiệp"
    end
    self:BeginEvent(self.script_id)
    self:AddText("  " .. PlayerName .. PlayerSex .. "#{OBJ_dali_0005}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return odali_fanhua
