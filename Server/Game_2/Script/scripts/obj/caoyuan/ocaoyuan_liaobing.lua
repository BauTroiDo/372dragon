local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ocaoyuan_liaobing = class("ocaoyuan_liaobing", script_base)
ocaoyuan_liaobing.script_id = 020008
function ocaoyuan_liaobing:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Tránh xa ta ra, người Tống không xứng nói chuyện với ta.#r  Ngô Hoàng vạn tuế! Đại Liêu tất thắng!")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return ocaoyuan_liaobing
