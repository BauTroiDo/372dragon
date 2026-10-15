local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ocaoyuan_laolietou = class("ocaoyuan_laolietou", script_base)
ocaoyuan_laolietou.script_id = 020009
function ocaoyuan_laolietou:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    local PlayerSex = self:GetSex(selfId)
    if PlayerSex == 0 then
        PlayerSex = "Cô nương"
    else
        PlayerSex = "Đại Hiệp"
    end
    self:AddText("  " .. PlayerSex .. "#{OBJ_caoyuan_0009}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return ocaoyuan_laolietou
