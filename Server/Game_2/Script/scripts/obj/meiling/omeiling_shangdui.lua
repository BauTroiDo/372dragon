local class = require "class"
local define = require "define"
local script_base = require "script_base"
local omeiling_shangdui = class("omeiling_shangdui", script_base)
function omeiling_shangdui:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Thương đội đã dừng ở Mai Lĩnh rất nhiều ngày rồi, hàng hóa cũng gần bán hết, chuyến này mọi người chắc chắn sẽ được chia không ít.#r  Ông chủ Thẩm thật là một thiên tài Thương nghiệp, theo ông ấy làm việc thật là kiếp trước tích đức.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return omeiling_shangdui
