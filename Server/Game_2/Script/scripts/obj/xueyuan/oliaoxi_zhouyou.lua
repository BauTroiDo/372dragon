local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oliaoxi_zhouyou = class("oliaoxi_zhouyou", script_base)
oliaoxi_zhouyou.script_id = 021009
function oliaoxi_zhouyou:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("    Bằng hữu, quái vật trên Ngân Ngai Tuyết Nguyên này đều sở hữu hàn băng thần lực, chỉ có #GKháng Băng#W đủ cao mới có thể ở đây hoành hành vô kỵ. Tại hạ có thể giúp ngươi tăng thêm một chút Kháng Băng, nhưng Kháng Băng phần nhiều Yêu cầu tự ngươi nỗ lực.")
    self:AddNumText("Tăng thêm một chút Kháng Băng", 6, 0)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oliaoxi_zhouyou:OnEventRequest(selfId, targetId, arg, index)
    if index == 0 then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 153, 0)
    end
end

return oliaoxi_zhouyou
