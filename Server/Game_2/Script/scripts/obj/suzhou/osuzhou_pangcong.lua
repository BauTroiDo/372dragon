local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_pangcong = class("osuzhou_pangcong", script_base)
osuzhou_pangcong.g_shoptableindex = 29
function osuzhou_pangcong:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Ta đang dưới sự chỉ đạo của sư phụ mà nghiên chế thuốc bổ, đợi đến ngày nào đó nghiên chế thành công, ta có thể bán cho ngươi với giá gốc. Suỵt - Chuyện này ta không nói cho người khác đâu.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return osuzhou_pangcong
