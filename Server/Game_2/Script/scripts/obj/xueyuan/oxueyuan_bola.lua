local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oxueyuan_bola = class("oxueyuan_bola", script_base)
function oxueyuan_bola:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Ngân Ngai Tuyết Nguyên khắp nơi nguy cơ trùng trùng, hoạt động ở đây phải cẩn thận đó.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oxueyuan_bola
