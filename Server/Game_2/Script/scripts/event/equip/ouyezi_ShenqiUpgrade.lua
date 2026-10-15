local class = require "class"
local define = require "define"
local script_base = require "script_base"
local gbk = require "wire_charset"
local item_operator = require "item_operator":getinstance()
local packet_def = require "game.packet"
local ouyezi_ShenqiUpgrade = class("ouyezi_ShenqiUpgrade", script_base)
ouyezi_ShenqiUpgrade.script_id = 500505
ouyezi_ShenqiUpgrade.UpgradeMoney = 50000
ouyezi_ShenqiUpgrade.ShenBingFu_Need = 5

function ouyezi_ShenqiUpgrade:DoRefreshSuperAttr(selfId, nEquipPos)
    self:RefreshSuperAttr(selfId, nEquipPos)
    self:NotifysTip(selfId, "#{CXYH_140813_48}")
    self:BeginUICommand()
    self:UICommand_AddInt(nEquipPos)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 198311141)
end

function ouyezi_ShenqiUpgrade:ShenQiConfirm(selfId, nEquipPos, nTargetID)
	local equip_id,equip_qhd = self:GetEquipQHD(selfId,nEquipPos)
	if equip_qhd and equip_qhd > 0 then
		self:notify_tips(selfId,"Trang bị thông linh không thao tác ở đây được.")
		return
	end
    local nQuality = self:GetBagItemQuality(selfId, nEquipPos)
    if nQuality == nil or nQuality < 5 or nQuality > 6 then
        self:NotifysTip(selfId, "Chỉ Thần khí 5 sao, 6 sao mới có thể tiến hành Luyện Hồn")
        return
    end
    if nEquipPos == nil or nTargetID == nil then
        return
    end
    local nMenPaiID = self:GetMenPai(selfId)
    if nMenPaiID == -1 or nMenPaiID == 9 then
        self:NotifysTip(selfId, "Dữ liệu Môn Phái dị thường, xin hãy kiểm tra Trạng Thái nhân vật của bạn!")
        return
    end
    local nOldWeaponID = self:LuaFnGetItemTableIndexByIndex(selfId, nEquipPos)
    local nNewItemID, nNeedMoney, nMaterial_1 = self:LuaFnGetShenqiUpgradeInfo(nOldWeaponID, nMenPaiID)
    if nNewItemID == nil or nNewItemID == nil then
        self:NotifysTip(selfId, "#{CXYH_140813_37}")
        return
    end
    local nMoneySelf = self:GetMoneyJZ(selfId) + self:GetMoney(selfId)
    if nMoneySelf < nNeedMoney then
        self:NotifysTip(selfId, "#{CXYH_140813_40}")
        return
    end
    local nMaterialNum = 0
    if nMaterial_1 ~= -1 then
        nMaterialNum = self:LuaFnGetAvailableItemCount(selfId, nMaterial_1)
    end
    if nMaterialNum < self.ShenBingFu_Need then
        self:NotifysTip(selfId, "#{CXYH_140813_39}")
        return
    end
    local nRet = false
    if nMaterial_1 ~= -1 then
        -- nRet = self:LuaFnMtl_CostMaterial(selfId, self.ShenBingFu_Need, { nMaterial_1 })
		nRet = self:LuaFnDelAvailableItem(selfId, nMaterial_1, self.ShenBingFu_Need)
    end
    if not nRet then
        self:BeginEvent(self.script_id)
        self:AddText("Không đủ Thần Binh Phù")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return
    end
    self:LuaFnRewashEquipAttr(selfId, nEquipPos, nNewItemID)
    self:NotifysTip(selfId, "Luyện hồn thuộc tính thần khí thành công")
end

function ouyezi_ShenqiUpgrade:OnShenqiUpgrade(selfId, nEquipPos)
	local equip_id,equip_qhd = self:GetEquipQHD(selfId,nEquipPos)
	if equip_qhd and equip_qhd > 0 then
		self:notify_tips(selfId,"Trang bị thông linh không thao tác ở đây được.")
		return
	end
    local nQuality = self:GetBagItemQuality(selfId, nEquipPos)
    if nQuality == nil or nQuality < 5 or nQuality > 6 then
        self:NotifysTip(selfId, "Chỉ Thần khí 5 sao, 6 sao mới có thể tiến hành Luyện Hồn")
        return
    end
    local nOldWeaponID = self:LuaFnGetItemTableIndexByIndex(selfId, nEquipPos)
    local nMenPaiID = self:GetMenPai(selfId)
    if nMenPaiID == -1 or nMenPaiID == 9 then
        self:NotifysTip(selfId, "Dữ liệu Môn Phái dị thường, xin hãy kiểm tra Trạng Thái nhân vật của bạn!")
        return
    end
    local nNewItemID, nNeedMoney, nMaterial_1 = self:LuaFnGetShenqiUpgradeInfo(nOldWeaponID, nMenPaiID)
    if nNewItemID == nil or nNewItemID == nil then
        self:NotifysTip(selfId, "#{CXYH_140813_37}")
        return
    end
    local nMoneySelf = self:GetMoneyJZ(selfId) + self:GetMoney(selfId)
    if nMoneySelf < nNeedMoney then
        self:NotifysTip(selfId, "#{CXYH_140813_40}")
        return
    end
    local nMaterialNum = 0
    if nMaterial_1 ~= -1 then
        -- nMaterialNum = self:LuaFnMtl_GetCostNum(selfId, { nMaterial_1 })
        nMaterialNum = self:LuaFnGetAvailableItemCount(selfId, nMaterial_1)
    end
    if nMaterialNum < self.ShenBingFu_Need then
        self:NotifysTip(selfId, "#{CXYH_140813_39}")
        return
    end
    local nRet = false
    if nMaterial_1 ~= -1 then
        -- nRet = self:LuaFnMtl_CostMaterial(selfId, self.ShenBingFu_Need, { nMaterial_1 })
		nRet = self:LuaFnDelAvailableItem(selfId, nMaterial_1, self.ShenBingFu_Need)
    end
    if not nRet then
        self:BeginEvent(self.script_id)
        self:AddText("Trừ Thần Binh Phù thất bại")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return
    end
    self:LuaFnCostMoneyWithPriority(selfId, nNeedMoney)
    self:LuaFnRewashEquipAttr(selfId, nEquipPos, nNewItemID)
    self:NotifysTip(selfId, "#{CXYH_140813_41}")
    return
end

function ouyezi_ShenqiUpgrade:NotifysTip(selfId, Msg)
    self:BeginEvent(self.script_id)
    self:AddText(Msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function ouyezi_ShenqiUpgrade:DoSuperWeapon9Up(selfId, nPos)
    if nPos == nil or nPos < 0 then
        return
    end
    local tableIndex = self:LuaFnGetItemTableIndexByIndex(selfId, nPos)
    if tableIndex < 10300000 or tableIndex > 10399999 then
        self:NotifysTip(selfId, "Trang bị này không thăng sao được.")
        return
    end
    local nMoneyJB = self:GetMoney(selfId)
    if nMoneyJB < 200000 then
        self:NotifysTip(selfId, "Không đủ tiền, không thăng cấp thần khí được.")
        return
    end
    local Qula = self:GetBagItemQuality(selfId, nPos)
    if Qula >= 9 then
        self:NotifysTip(selfId, "Thần khí này đã sao tối đa, không thăng tiếp được.")
        return
    end
    if Qula < 5 then
        self:NotifysTip(selfId, "Phẩm chất thần khí không đủ, không thăng sao được.")
        return
    end
    local needNum = 0
    if Qula == 5 then
        needNum = 200
    elseif Qula == 6 then
        needNum = 500
    elseif Qula == 7 then
        needNum = 800
    elseif Qula == 8 then
        needNum = 1200
    end
    local Have = self:LuaFnGetAvailableItemCount(selfId, 30901252)
    if Have < needNum then
        self:NotifysTip(selfId, string.format("Thăng sao thần khí cần %s cái %s.", needNum, self:GetItemName(30901252)))
        return
    end
    self:CostMoney(selfId, 200000)
    if not self:LuaFnDelAvailableItem(selfId, 30901252, needNum) then
        return
    end
    local newQuality = Qula + 1

    -- 获取装备对象及数据
    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_prop_bag_container()
    local item = container:get_item(nPos)
    local equip_data = item:get_equip_data()

    -- 关键：根据新品质重新生成装备属性值（持久化写入）
    local params, attr_types, values = item_operator:gen_equip_attrs(tableIndex, 1, newQuality)

    -- 更新装备所有属性数据
    equip_data:set_quality(newQuality)
    equip_data:set_attr_count(#values)
    equip_data:set_attr_value(values)
    equip_data:set_attr_type(params.attr_type)
    equip_data:set_attr_types(attr_types)

    -- 通知客户端装备信息变更（GCItemInfo持久化刷新）
    local msg = packet_def.GCItemInfo.new()
    msg.bagIndex = nPos
    msg.item = item:copy_raw_data()
    self.scene:send2client(obj, msg)

    -- 如果装备在身上，刷新人物战斗属性
    obj:item_flush()
    obj:send_refresh_attrib()
        self:NotifysTip(selfId, "Thăng sao thành công.")

    -- 全服公告
    local transfer = self:GetBagItemTransfer(selfId, nPos)
    local playerName = gbk.fromutf8(self:GetName(selfId))
    local fmtStr = gbk.fromutf8("#{_INFOUSR%s}#Pluôn dùng một thần khí, nên tại chỗ#YÂu Trị Tử#Pqua tiến giai thần khí nhận được#{_INFOMSG%s}#P")
    local str = string.format(fmtStr, playerName, transfer)
    self:BroadMsgByChatPipe(selfId, str, 4)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 148, 0)
end

return ouyezi_ShenqiUpgrade
