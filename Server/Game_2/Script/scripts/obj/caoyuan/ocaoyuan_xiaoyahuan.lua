local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ocaoyuan_xiaoyahuan = class("ocaoyuan_xiaoyahuan", script_base)
ocaoyuan_xiaoyahuan.script_id = 020005
function ocaoyuan_xiaoyahuan:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{OBJ_caoyuan_0006}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return ocaoyuan_xiaoyahuan
