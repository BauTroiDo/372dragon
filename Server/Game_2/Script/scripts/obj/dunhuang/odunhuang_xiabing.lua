local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odunhuang_xiabing = class("odunhuang_xiabing", script_base)

function odunhuang_xiabing:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Không hiểu vì sao Hoàng đế Bệ hạ phải biên chế quân đoàn người Hán, chiến đấu lực của quân đoàn Đảng Hạng ta vượt xa người Hán vậy.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return odunhuang_xiabing
