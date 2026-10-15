local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_wushi = class("odali_wushi", script_base)
function odali_wushi:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Nếu vị nào muốn luận bàn võ nghệ, xin mời lên lôi đài!")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return odali_wushi
