local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odunhuang_lichonggui = class("odunhuang_lichonggui", script_base)

function odunhuang_lichonggui:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Chúng ta đã đánh bại Hồi Hột và Quy Tư, công vào Ngọc Môn Quan, chiếm lấy Tống triều chỉ là chuyện sớm muộn.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return odunhuang_lichonggui