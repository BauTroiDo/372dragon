local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_332200 = class("item_332200", script_base)
item_332200.script_id = 332200
item_332200.g_DarkBox = 30008010
function item_332200:OnDefaultEvent(selfId, bagIndex)
end

function item_332200:IsSkillLikeScript(selfId)
    return 1
end

function item_332200:CancelImpacts(selfId)
    return 0
end

function item_332200:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    local FreeSpace = self:LuaFnGetPropertyBagSpace(selfId)
    if (FreeSpace < 1) then
        local strNotice = "Ô Đạo cụcủangươi không đủ chỗ trống, Yêu cầu thu xếp lại."
        self:ShowNotice(selfId, strNotice)
        return 0
    end
    FreeSpace = self:LuaFnGetMaterialBagSpace(selfId)
    if (FreeSpace < 1) then
        local strNotice = "Ô Nguyên liệucủangươi không đủ chỗ trống, Yêu cầu thu xếp lại."
        self:ShowNotice(selfId, strNotice)
        return 0
    end
    local ItemCount = self:LuaFnGetAvailableItemCount(selfId, self.g_DarkBox)
    if ItemCount < 1 then
        local strNotice = "Cần" .. "#{_ITEM" .. (self.g_DarkBox) .. "}"
        self:ShowNotice(selfId, strNotice)
        return 0
    end
    return 1
end

function item_332200:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_332200:OnActivateOnce(selfId)
    local ret = self:LuaFnDelAvailableItem(selfId, self.g_DarkBox, 1)
    if not ret then
        return
    end
    self:LuaFnAuditDarkKeyUsed(selfId, 0, 0)
    local RandomBase = self:GetDarkBoxItemDropCount(selfId)
    if (RandomBase > 0) then
        local RandomNum = math.random(1, RandomBase)
        local RandomID, Notice = self:DarkBoxItemDropRandom(selfId, RandomNum)
        if (RandomID > 0) then
            self:BeginAddItem()
            self:AddItem(RandomID, 1)
            local Ret = self:LuaFnEndAddItemIgnoreFatigueState(selfId)
            if Ret > 0 then
                self:LuaFnAddItemListToHumanIgnoreFatigueState(selfId)
                if 1 == Notice then
                    local szItemTransfer = self:GetItemTransfer(selfId, 0)
                    local ItemInfo = "#{_INFOMSG" .. szItemTransfer .. "}"
                    self:ShowRandomSystemNotice(selfId, ItemInfo)
                end
                local strNotice = "Mở Hộp Báu thành công, chúc mừng ngươinhận được" .. "#B#{_ITEM" .. (RandomID) .. "}"
                self:ShowNotice(selfId, strNotice)
                self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 0)
            else
                local strNotice = "Túi hành trang không đủ chỗ"
                self:ShowNotice(selfId, strNotice)
            end
            local SubItem = 30008026
            self:BeginAddItem()
            self:AddItem(SubItem, 1)
            Ret = self:LuaFnEndAddItemIgnoreFatigueState(selfId)
            if Ret > 0 then
                self:LuaFnAddItemListToHumanIgnoreFatigueState(selfId)
            else
                local strNotice = "Túi hành trang không đủ chỗ"
                self:ShowNotice(selfId, strNotice)
            end
        end
    end
    return 1
end

function item_332200:OnActivateEachTick(selfId)
    return 1
end

function item_332200:ShowNotice(selfId, strNotice)
    self:BeginEvent(self.script_id)
    self:AddText(strNotice)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function item_332200:ShowRandomSystemNotice(selfId, strItemInfo)
    local strNotice = {
        "#W%s#H nhìn #Y%s#H trống không, cơn giận nổi lên, vung đao chém nát, bất ngờ phát hiện #W%s#H được giấu trong lớp lót của bảo rương.",
        "#W%s#H run run mở #Y%s#H ra, chỉ thấy một đạo kim quang chợt lóe, #W%s#H liền lẳng lặng nằm ở đáy rương.",
        "#W%s#H tắm gội thay y phục, trai giới ăn chay... Sau khi tụng kinh ngàn lần, mở #Y%s#H ra, quả nhiên trong rương có một #W%s!"
    }

    local strDarkBox = "#{_ITEM30008010}"
    local PlayerName = self:GetName(selfId)
    local PlayerInfoName = "#{_INFOUSR" .. PlayerName .. "}"
    local RandomNotice = math.random(1, 3)
    local notice = gbk.fromutf8(strNotice[RandomNotice])
    PlayerInfoName = gbk.fromutf8(PlayerInfoName)
    local SysStr = string.format(notice, PlayerInfoName, strDarkBox, strItemInfo)
    self:BroadMsgByChatPipe(selfId, SysStr, 4)
end

return item_332200
