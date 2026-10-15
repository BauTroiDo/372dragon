local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_weizhen = class("osuzhou_weizhen", script_base)
function osuzhou_weizhen:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    local PlayerName = self:GetName(selfId)
    local PlayerSex = self:GetSex(selfId)
    if PlayerSex == 0 then
        PlayerSex = "Cô nương"
    else
        PlayerSex = "Thiếu hiệp"
    end
    self:AddText("    " .. PlayerName .. PlayerSex .. ", trên cọc mai hoa so tài mới thấy công phu.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return osuzhou_weizhen
