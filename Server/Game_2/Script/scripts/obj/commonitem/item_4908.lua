local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4908 = class("item_4908", script_base)
item_4908.g_petCommonId = define.PETCOMMON
item_4908.g_itemList = {}

item_4908.g_itemList[30503016] = {["minLevel"] = 1, ["maxLevel"] = 85}

item_4908.g_itemList[30503017] = {["minLevel"] = 1, ["maxLevel"] = 35}

item_4908.g_itemList[30503018] = {["minLevel"] = 1, ["maxLevel"] = 65}

item_4908.g_itemList[30503019] = {["minLevel"] = 1, ["maxLevel"] = 85}

item_4908.g_itemList[30503020] = {["minLevel"] = 1, ["maxLevel"] = 95}

item_4908.script_id = 334908
function item_4908:IsSkillLikeScript(selfId)
    return 1
end

function item_4908:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    local itemTblIndex = self:LuaFnGetItemIndexOfUsedItem(selfId)
    local petItem = self.g_itemList[itemTblIndex]
    if not petItem then
        self:NotifyTip(selfId, "Đạo cụ chưa mở, không thể sử dụng.")
        return 0
    end
    local petGUID_H = self:LuaFnGetHighSectionOfTargetPetGuid(selfId)
    local petGUID_L = self:LuaFnGetLowSectionOfTargetPetGuid(selfId)
    if self:LuaFnPetCanReturnToChild(selfId, petGUID_H, petGUID_L, 1, -1) == 0 then
        return 0
    end
    local petDataID = self:LuaFnGetPetDataIDByGUID(selfId, petGUID_H, petGUID_L)
    if not petDataID or petDataID < 0 then
        self:NotifyTip(selfId, "Không thể hoàn đồng đối với Trân thú chỉ định.")
        return 0
    end
    local petTakeLevel = self:GetPetTakeLevel(petDataID)
    if not petTakeLevel or petTakeLevel < 1 then
        self:NotifyTip(selfId, "Không thể nhận dạng Cấp độ mang theo của Trân thú.")
        return 0
    end
    if petTakeLevel > petItem["maxLevel"] then
        if (petTakeLevel == 95) then
            self:NotifyTip(selfId, "#{95ZSH_081121_01}")
            return 0
        else
            self:NotifyTip(selfId, "Không thể dùng cho Trân thú mang Cấp độ" .. petItem["maxLevel"] .. "cấp trở lên của Trân thú để Hoàn Đồng.")
            return 0
        end
    end
    return 1
end

function item_4908:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4908:OnActivateOnce(selfId)
    local petGUID_H = self:LuaFnGetHighSectionOfTargetPetGuid(selfId)
    local petGUID_L = self:LuaFnGetLowSectionOfTargetPetGuid(selfId)
    local ret, perLevel = self:LuaFnPetReturnToChild(selfId, petGUID_H, petGUID_L, 1, -1)
    if ret then
        local szMsg = "Trân thú Hoàn Đồng thành công!"
        self:NotifyTip(selfId, szMsg)
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 0)
        local itemTblIndex = self:LuaFnGetItemIndexOfUsedItem(selfId)
        local nGrowLevel = 0
        if
            (itemTblIndex == 30503017 or itemTblIndex == 30503018 or itemTblIndex == 30503019 or
                itemTblIndex == 30503020 or
                itemTblIndex == 30503016)
         then
            nGrowLevel = self:LuaFnGetPetGrowRateByGUID(selfId, petGUID_H, petGUID_L)
        end
        local selfName = self:LuaFnGetName(selfId)
        local petTransfer = self:LuaFnGetPetTransferByGUID(selfId, petGUID_H, petGUID_L)
        if perLevel and perLevel >= 6 and selfName and petTransfer then
            local strWorldChat = "#{_INFOUSR" .. gbk.fromutf8(selfName) .. gbk.fromutf8("}#HSử dụng#YHoàn Đồng Thiên Thư#Hsau, #{_INFOMSG") .. petTransfer .. gbk.fromutf8("}#HTừ trên trời giáng xuống!")
            self:BroadMsgByChatPipe(selfId, strWorldChat, 4)
        end
        if (nGrowLevel >= 4) then
            local strTbl = {"Thường", "Ưu tú", "Kiệt xuất", "Xuất sắc", "Hoàn mỹ"}
            local Msg = "#W#{_INFOUSR%s}#{HT14}#Y" .. strTbl[nGrowLevel] .. "#{HT15}#{_INFOMSG%s}#{HT16}"
            Msg = gbk.fromutf8(Msg)
            local szPetTrans = self:GetPetTransString(selfId, petGUID_H, petGUID_L)
            local str = string.format(Msg, selfName, szPetTrans)
            self:BroadMsgByChatPipe(selfId, str, 4)
        end
    end
    return 1
end

function item_4908:OnActivateEachTick(selfId)
    return 1
end

function item_4908:CancelImpacts(selfId)
    return 0
end

function item_4908:NotifyTip(selfId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return item_4908
