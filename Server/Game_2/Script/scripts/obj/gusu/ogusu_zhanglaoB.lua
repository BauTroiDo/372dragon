local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ogusu_zhanglaoB = class("ogusu_zhanglaoB", script_base)

function ogusu_zhanglaoB:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Ta là Hộ Pháp trưởng lão Mộ Dung Sơn Trang.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return ogusu_zhanglaoB
