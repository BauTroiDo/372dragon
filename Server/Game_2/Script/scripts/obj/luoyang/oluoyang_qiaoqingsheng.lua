local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_qiaoqingsheng = class("oluoyang_qiaoqingsheng", script_base)
function oluoyang_qiaoqingsheng:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{OBJ_luoyang_0016}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oluoyang_qiaoqingsheng
