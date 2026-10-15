local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oqiongzhou_yuanzijin = class("oqiongzhou_yuanzijin", script_base)
function oqiongzhou_yuanzijin:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Bang chủ Nam Hải Ngạc Ngư bang chúng ta, chính là Nhạc Lão Tam được xưng là \"Nam Hải Ngạc Thần\". Lần này ta phụng mệnh Tam Ca, đi Lưu Cầu đảo đón Tam Tẩu đến Quỳnh Châu. Hiện tại Tam Tẩu đã đến, chúng ta lược làm tu chỉnh, liền đến Cá sấu bang tìm Tam Ca.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oqiongzhou_yuanzijin
