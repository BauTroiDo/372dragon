local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ocaoyuan_laobing = class("ocaoyuan_laobing", script_base)
ocaoyuan_laobing.script_id = 020006
function ocaoyuan_laobing:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    local PlayerName = self:GetName(selfId)
    self:AddText("  " .. PlayerName .. "#{OBJ_caoyuan_0007}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return ocaoyuan_laobing
