local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_jinzuohuan = class("oluoyang_jinzuohuan", script_base)
function oluoyang_jinzuohuan:OnDefaultEvent(selfId, targetId)
    local PlayerName = self:GetName(selfId)
    local PlayerSex = self:GetSex(selfId)
    if PlayerSex == 0 then
        PlayerSex = "Cô nương"
    else
        PlayerSex = "Thiếu hiệp"
    end
    self:BeginEvent(self.script_id)
    self:AddText(
        "  Ai nói quốc lễ tiến cống của Cao Ly quốc chúng ta bị mất? Nói bậy, căn bản không có chuyện đó." ..
            PlayerName .. PlayerSex ..
            "Nếu còn nghe thấy ai nói năng lung tung thì dẫn hắn đến gặp ta, ta sẽ phải hỏi cho ra nhẽ xem mắt nào của hắn thấy quốc lễ bị mất.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oluoyang_jinzuohuan
