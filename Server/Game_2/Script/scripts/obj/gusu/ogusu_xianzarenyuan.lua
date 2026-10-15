local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ogusu_xianzarenyuan = class("ogusu_xianzarenyuan", script_base)

function ogusu_xianzarenyuan:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  ……")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return ogusu_xianzarenyuan
