local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ogusu_baoruoxing = class("ogusu_baoruoxing", script_base)

function ogusu_baoruoxing:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Ta là Bao Nhược Hành, người chỉ đường Mộ Dung Sơn Trang. Thiếu hiệp muốn đi đâu?")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return ogusu_baoruoxing
