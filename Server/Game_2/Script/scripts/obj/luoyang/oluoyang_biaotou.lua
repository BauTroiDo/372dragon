local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_biaotou = class("oluoyang_biaotou", script_base)
function oluoyang_biaotou:OnDefaultEvent(selfId, targetId)
    local PlayerName = self:GetName(selfId)
    local PlayerSex = self:GetSex(selfId)
    if PlayerSex == 0 then
        PlayerSex = "Cô nương"
    else
        PlayerSex = "Thiếu hiệp"
    end
    self:BeginEvent(self.script_id)
    self:AddText(
        "  Bản tiêu cục chúng ta chữ tín là trên hết, nghĩa khí ngút trời, được bằng hữu cả hắc bạch lưỡng đạo nể mặt, mới có thể bảo đảm liên tục mười năm không mất tiêu." ..
            PlayerName .. PlayerSex ..
            ", có gì Yêu cầu của ngài cứ việc nói, dù lên núi đao, xuống biển lửa, Cái Thiên Minh ta cũng không hề chớp mắt.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oluoyang_biaotou
