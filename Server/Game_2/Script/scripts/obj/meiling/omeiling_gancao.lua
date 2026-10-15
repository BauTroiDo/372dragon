local class = require "class"
local define = require "define"
local script_base = require "script_base"
local omeiling_gancao = class("omeiling_gancao", script_base)
function omeiling_gancao:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Đại hộ pháp Bụi gai nói phải, việc lớn việc nhỏ của Mai Lĩnh, đều nằm trong tính toán của đại hộ pháp. Chúng ta đều làm theo ý của đại hộ pháp, dù chết vạn lần, cũng so với sống hồ đồ sung sướng hơn nhiều.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return omeiling_gancao
