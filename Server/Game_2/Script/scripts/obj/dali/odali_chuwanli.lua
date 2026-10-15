local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_chuwanli = class("odali_chuwanli", script_base)
function odali_chuwanli:OnDefaultEvent(selfId, targetId)
    local PlayerName = self:GetName(selfId)
    local PlayerSex = self:GetSex(selfId)
    if PlayerSex == 0 then
        PlayerSex = "Cô nương"
    else
        PlayerSex = "Thiếu hiệp"
    end
    self:BeginEvent(self.script_id)
    self:AddText(
        "  Muốn luyện thành một thân võ công hảo hạng, cùng chúng ta trở thành Cấm Quân hộ vệ sao?" .. PlayerName .. PlayerSex .. ", ngươi có thể bái nhập Cửu Đại Môn phái, tại Ngọc Hoa Đàn có người chỉ dẫn của Cửu Đại Môn phái, ngươi đi các Đại Môn phái xem thử, biết đâu sẽ có thu hoạch bất ngờ đó."
    )
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return odali_chuwanli
