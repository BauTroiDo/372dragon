local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ocaoyuan_yahuan = class("ocaoyuan_yahuan", script_base)
ocaoyuan_yahuan.script_id = 020004
function ocaoyuan_yahuan:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    local PlayerSex = self:GetSex(selfId)
    if PlayerSex == 0 then
        PlayerSex = "Cô nương"
    else
        PlayerSex = "Thiếu hiệp"
    end
    self:AddText("  " .. PlayerSex .. "#{OBJ_caoyuan_0005}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function ocaoyuan_yahuan:OnDie(selfId, killerId) end

return ocaoyuan_yahuan
