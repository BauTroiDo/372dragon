local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_fantong = class("oluoyang_fantong", script_base)
oluoyang_fantong.g_ShopTabId = 15
oluoyang_fantong.script_id = 000059
function oluoyang_fantong:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(
        "  Đến nếm thử món Thủy Tịch của #YLạc Dương#W tại Mính Trân Lâu đi, đảm bảo ngươi ăn rồi sẽ không muốn rời #YLạc Dương#W nữa.")
    --self:AddNumText("购买食物", 7, 0)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_fantong:OnEventRequest(selfId, targetId, arg, index)
    local key = index
    local ene = self:GetHumanEnergy(selfId)
    local vig = self:GetHumanVigor(selfId)
    if key == 0 then
        self:DispatchShopItem(selfId, targetId, self.g_ShopTabId)
    elseif key == 1 then
        if ene >= 40 then
            self:SetHumanEnergy(selfId, ene - 40)
            self:AddMoney(selfId, 3000)
            self:MsgBox(selfId, "Ngươi làm việc tiêu hao 40 Thể lực, nhận được 30 ngân tệ.")
        else
            self:MsgBox(selfId,
                        "Thể lực của ngươi không đủ 40 điểm, chủ quán không Yêu cầu ngươi làm việc.")
        end
    elseif key == 2 then
        if vig >= 40 then
            self:SetHumanVigor(selfId, vig - 40)
            self:AddMoney(selfId, 3000)
            self:MsgBox(selfId, "Ngươi làm việc tiêu hao 40 Hoạt lực, nhận được 30 ngân tệ.")
        else
            self:MsgBox(selfId,
                        "Hoạt lực của ngươi không đủ 40 điểm, chủ quán không Yêu cầu ngươi làm việc.")
        end
    end
end

function oluoyang_fantong:MsgBox(selfId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return oluoyang_fantong
