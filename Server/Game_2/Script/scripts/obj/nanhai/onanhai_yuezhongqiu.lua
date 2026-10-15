local class = require "class"
local define = require "define"
local script_base = require "script_base"
local onanhai_yuezhongqiu = class("onanhai_yuezhongqiu", script_base)
onanhai_yuezhongqiu.script_id = 34003
function onanhai_yuezhongqiu:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Vào lúc trước, Bang Cá Sấu cũng khá tốt, chỉ là hành vi quái dị một chút thôi, chưa từng làm gì sai trái lớn. Nhưng mà, dần dần, không biết vì lẽ gì, bọn trẻ đó bắt đầu luôn gây họa, làm sai còn không nhận lỗi, than ôi... thật là tội nghiệp a...")
    if self:IsHaveMission(selfId, 568) then
        local itemCount = self:GetItemCount(selfId, 40001039)
        if itemCount < 1 then
            self:AddNumText("Nhận được một khối vỏ cây dị chủng.", 7, 666)
        end
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function onanhai_yuezhongqiu:OnEventRequest(selfId, targetId, arg, index)
    if index == 666 then
        local itemCount = self:GetItemCount(selfId, 40001039)
        if itemCount < 1 then
            self:BeginAddItem()
            self:AddItem(40001039, 1)
            local ret = self:EndAddItem(selfId)
            if ret <= 0 then
                self:Msg2Player(selfId, "#YTúi nhiệm vụ của ngươi đã đầy.", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
            else
                self:AddItemListToHuman(selfId)
            end
        end
    end
end

return onanhai_yuezhongqiu
