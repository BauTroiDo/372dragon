local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_jinwuye = class("odali_jinwuye", script_base)
function odali_jinwuye:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Hành tẩu giang hồ, đương nhiên là ai nắm đấm cứng người đó là đại gia. Nhưng tục ngữ nói rất đúng, có tiền có thể khiến ma xui quỷ khiến, trong tay có Nguyên bảo, có thể khiến rất nhiều chuyện khó khăn trở nên đơn giản.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return odali_jinwuye
