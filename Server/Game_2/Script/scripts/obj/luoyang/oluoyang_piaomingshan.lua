local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_piaomingshan = class("oluoyang_piaomingshan", script_base)
function oluoyang_piaomingshan:OnDefaultEvent(selfId, targetId)
    local PlayerName = self:GetName(selfId)
    local PlayerSex = self:GetSex(selfId)
    if PlayerSex == 0 then
        PlayerSex = "Cô nương"
    else
        PlayerSex = "Thiếu hiệp"
    end
    self:BeginEvent(self.script_id)
    self:AddText(
        "  Hoa mẫu đơn #YLạc Dương#W quả danh bất hư truyền, so với hoa trà #YCao Ly#W của chúng ta cũng chẳng kém là bao. Nghe nói thành #YTô Châu#W của #YSong Vương triều#W cũng đẹp lắm," ..
            PlayerName .. PlayerSex .. ", chư vị đã từng đến chưa?")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oluoyang_piaomingshan
