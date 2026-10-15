local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_zhengtianshou = class("osuzhou_zhengtianshou", script_base)
function osuzhou_zhengtianshou:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    local PlayerName = self:GetName(selfId)
    local PlayerSex = self:GetSex(selfId)
    if PlayerSex == 0 then
        PlayerSex = "Cô nương"
    else
        PlayerSex = "Thiếu hiệp"
    end
    self:AddText("  " .. PlayerName .. PlayerSex .. ", có phải là muốn so tài võ nghệ? Vậy thì xin mời lên lôi đài!")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return osuzhou_zhengtianshou
