local class = require "class"
local define = require "define"
local script_base = require "script_base"
local otaihu_songbing = class("otaihu_songbing", script_base)
function otaihu_songbing:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Chẳng hay chúng ta còn phải đợi đến bao giờ, mau chóng kết thúc chuyện ở đây, đến Ngọc Môn Quan chi viện Dương tướng quân thôi.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return otaihu_songbing
