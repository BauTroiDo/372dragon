local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oyannan_baixing = class("oyannan_baixing", script_base)

function oyannan_baixing:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(
        "  Chúng ta đều là dân lành Đại Tống, sống ở Nhạn Môn Quan đã mấy đời, ổ vàng ổ bạc, không bằng ổ đất của ta. Chúng ta sẽ không rời đi đâu.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oyannan_baixing
