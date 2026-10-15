local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ogusu_dengwanren = class("ogusu_dengwanren", script_base)

function ogusu_dengwanren:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Ta là Đặng Vạn Nhận, truyền tống sứ Mộ Dung Sơn Trang. Thiếu hiệp muốn tới đâu?")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return ogusu_dengwanren
