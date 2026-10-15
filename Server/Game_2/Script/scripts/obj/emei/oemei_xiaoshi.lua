local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oemei_xiaoshi = class("oemei_xiaoshi", script_base)
function oemei_xiaoshi:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Chưởng môn tỷ tỷ dạo gần đây luôn nhắc tới một người tên là Hàn Thế Trung, nói người ấy là đại anh hùng hiếm có trên đời, có thể sánh ngang \"Bắc Kiều Phong\", \"Nam Mộ Dung\".")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oemei_xiaoshi
