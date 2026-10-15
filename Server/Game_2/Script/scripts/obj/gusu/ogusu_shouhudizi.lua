local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ogusu_shouhudizi = class("ogusu_shouhudizi", script_base)

function ogusu_shouhudizi:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Đệ tử Mộ Dung Sơn Trang tuần tra nơi đây.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return ogusu_shouhudizi
