local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ocaoyuan_xinbing = class("ocaoyuan_xinbing", script_base)
ocaoyuan_xinbing.script_id = 020007
function ocaoyuan_xinbing:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    local PlayerName = self:GetName(selfId)
    self:AddText("  " .. PlayerName .. "#{OBJ_caoyuan_0008}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return ocaoyuan_xinbing
