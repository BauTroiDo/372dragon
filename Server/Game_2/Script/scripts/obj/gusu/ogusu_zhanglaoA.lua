local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ogusu_zhanglaoA = class("ogusu_zhanglaoA", script_base)

function ogusu_zhanglaoA:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Ta là Võ Đạo trưởng lão Mộ Dung Sơn Trang.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return ogusu_zhanglaoA
