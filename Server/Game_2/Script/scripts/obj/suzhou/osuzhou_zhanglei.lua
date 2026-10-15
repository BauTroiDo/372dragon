local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_zhanglei = class("osuzhou_zhanglei", script_base)
function osuzhou_zhanglei:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    local PlayerName = self:GetName(selfId)
    local PlayerSex = self:GetSex(selfId)
    if PlayerSex == 0 then
        PlayerSex = "Cô nương"
    else
        PlayerSex = "Thiếu hiệp"
    end
    self:AddText("  " .. PlayerName .. PlayerSex .. ", ngươi cũng đến tham gia khảo thí sao? Đợi khảo thí kết thúc ta muốn đi bái kiến lão sư," .. PlayerSex .. "chi bằng cùng nhau lên đường?")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return osuzhou_zhanglei
