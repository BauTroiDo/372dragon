-- 宝石镶嵌
-- 普�1�7�1�7
local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local packet_def = require "game.packet"
local human_item_logic = require "human_item_logic"
local script_base = require "script_base"
local skynet = require "skynet"
local gem_embed = class("gem_embed", script_base)
local MAT_ITEM_INDEX = 30900010
function gem_embed:EnchaseEx_3(selfId, gem_index, equip_index, mat_index, _,
                               location)
    local gem = self:GetBagItem(selfId, gem_index)
    local equip = self:GetBagItem(selfId, equip_index)
    local mat = self:GetBagItem(selfId, mat_index)
    if gem == nil or gem:get_serial_class() ~= define.ITEM_CLASS.ICLASS_GEM then
        self:notify_tips(selfId, "请放入宝矄1�7")
        return
    end
    if equip == nil or equip:get_serial_class() ~=
        define.ITEM_CLASS.ICLASS_EQUIP then
        self:notify_tips(selfId, "请放入装处1�7")
        return
    end
    if mat == nil or mat:get_index() ~= MAT_ITEM_INDEX then
        self:notify_tips(selfId, "Xin hãy bỏ Bảo Thạch Tương Khảm Phù vào")
        return
    end
    local equip_point = equip:get_equip_data():get_equip_point()
    local need_bind = gem:is_bind()
	if equip_point == define.HUMAN_EQUIP.HEQUIP_RIDER
	or equip_point == define.HUMAN_EQUIP.HEQUIP_UNKNOW1
	or equip_point == define.HUMAN_EQUIP.HEQUIP_UNKNOW2
	or equip_point == define.HUMAN_EQUIP.HEQUIP_FASHION
	or equip_point == define.HUMAN_EQUIP.HEQUIP_TOTAL
	or equip_point == define.HUMAN_EQUIP.LINGWU_JING
	or equip_point == define.HUMAN_EQUIP.LINGWU_CHI
	or equip_point == define.HUMAN_EQUIP.LINGWU_JIA
	or equip_point == define.HUMAN_EQUIP.LINGWU_GOU
	or equip_point == define.HUMAN_EQUIP.LINGWU_DAI
	or equip_point == define.HUMAN_EQUIP.LINGWU_DI
	or equip_point == define.HUMAN_EQUIP.HEQUIP_ALL then
		self:notify_tips("该装备不弄1�7放此功能哄1�7")
		return
	end
    -- if equip_point == define.HUMAN_EQUIP.HEQUIP_UNKNOW1 then
        -- return
    -- end
    -- if equip_point == define.HUMAN_EQUIP.HEQUIP_UNKNOW2 then
        -- return
    -- end
    -- if equip_point == define.HUMAN_EQUIP.HEQUIP_FASHION then
        -- return
    -- end
    local gem_item_index = gem:get_index()
	local gemval1 = gem_item_index % 100000
	local gemtype = math.floor(gemval1 / 1000)
	if gemtype >= 31 and gemtype <= 33 then
        self:notify_tips(selfId, "请不要放入点缄1�7矄1�7")
        return
    end
    local slot_gem = equip:get_equip_data():get_slot_gem(location + 1)
    if slot_gem ~= 0 then
        self:notify_tips(selfId, "Vị trí khảm đã có bảo thạch")
        return
    end
    if not self:CheckEnchaseExVaild(selfId, gem_index, equip) then
        self:notify_tips(selfId, "Khảm không hợp lệ")
        return
    end
    local equipType = self:LuaFnGetBagEquipType(selfId, equip_index)
    local gemType = self:LuaFnGetItemType(gem:get_index())
    if not self:CheckEnchaseGemTypeVaild(equipType, gemType) then
        self:notify_tips(selfId, "Loại Bảo thạch này không thể khảm nạm trên loại Trang bị này")
        return
    end
    local szTransferItem = self:GetBagItemTransfer(selfId, gem_index)
    local obj = self.scene:get_obj_by_id(selfId)
    local logparam = {}
    local del = human_item_logic:dec_item_lay_count(logparam, obj, gem_index, 1)
	if not del then
        self:notify_tips(selfId, "Trừ bảo thạch thất bại")
        return
    end
    del = human_item_logic:dec_item_lay_count(logparam, obj, mat_index, 1)
	if not del then
        self:notify_tips(selfId, "Trừ nguyên liệu thất bại")
        return
    end
    equip:get_equip_data():gem_embed(location + 1, gem:get_index())
    equip:set_is_bind(true)
    -- 强制同步 gem_count 为 gem_list 实际数量，防止计数器虚增
    do
        local _gem_list = equip:get_equip_data():get_gem_list()
        local _real_count = 0
        for _i = 1, 4 do
            if _gem_list[_i] and _gem_list[_i] ~= 0 then
                _real_count = _real_count + 1
            end
        end
        equip:get_equip_data():set_gem_count(_real_count)
    end
    local msg = packet_def.GCItemInfo.new()
    msg.bagIndex = equip_index
    msg.item = equip:copy_raw_data()
    self.scene:send2client(selfId, msg)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 49, 0)

										  
    local quality = self:GetItemQuality(gem_item_index)
    if quality >= 5 then
        local name = self:GetName(selfId)
        local szTransferEquip = self:GetBagItemTransfer(selfId, equip_index)
        local fmt = gbk.fromutf8("#W#{_INFOUSR%s}#H各1�7#W#{_INFOMSG%s}#H镶嵌了一预1�7#W#{_INFOMSG%s}#H，大幅的提升了装备的能力〄1�7")
        local message = string.format(fmt, gbk.fromutf8(name), szTransferEquip, szTransferItem)
        self:BroadMsgByChatPipe(selfId, message, 4)
    end
end

function gem_embed:CheckEnchaseExVaild(selfId, gem_index, equip)
    local gem_item_index = self:LuaFnGetItemTableIndexByIndex(selfId, gem_index)
    local gemType = self:LuaFnGetItemType(gem_item_index)
    local gem_list = equip:get_equip_data():get_gem_list()
    for i = 1, 3 do
        local exist_gem_index = gem_list[i] or 0
        if exist_gem_index ~= 0 then
            local exist_gem_type = self:LuaFnGetItemType(exist_gem_index)
            if exist_gem_type == gemType then
                return false
            end
        end
    end
    return true
end

local GemEmbed_four_ID = {
    50113004, 50213004, 50313004, 50413004, 50513004, 50613004, 50713004, 50813004, 50913004,
    50113006, 50213006, 50313006, 50413006, 50513006, 50613006, 50713006, 50813006, 50913006,
}
local g_EquipGemTable = {}
g_EquipGemTable[define.HUMAN_EQUIP.HEQUIP_WEAPON] = {1, 2, 3, 4, 21}
g_EquipGemTable[define.HUMAN_EQUIP.HEQUIP_CAP] = {11, 12, 13, 14}
g_EquipGemTable[define.HUMAN_EQUIP.HEQUIP_ARMOR] = {11, 12, 13, 14}
g_EquipGemTable[define.HUMAN_EQUIP.HEQUIP_CUFF] = {11, 12, 13, 14}
g_EquipGemTable[define.HUMAN_EQUIP.HEQUIP_GLOVE] = {11, 12, 13, 14}
g_EquipGemTable[define.HUMAN_EQUIP.HEQUIP_BOOT] = {11, 12, 13, 14}
g_EquipGemTable[define.HUMAN_EQUIP.HEQUIP_SASH] = {11, 12, 13, 14}
g_EquipGemTable[define.HUMAN_EQUIP.HEQUIP_RING_1] = {1, 2, 3, 4, 21}
define.HUMAN_EQUIP.SHENBING = 37
g_EquipGemTable[define.HUMAN_EQUIP.SHENBING] = {
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21
}
g_EquipGemTable[define.HUMAN_EQUIP.HEQUIP_NECKLACE] = {
    1, 2, 3, 4, 11, 12, 13, 14, 21
}
g_EquipGemTable[define.HUMAN_EQUIP.HEQUIP_RING_2] = {1, 2, 3, 4, 21}
g_EquipGemTable[define.HUMAN_EQUIP.HEQUIP_AMULET_1] = {1, 2, 3, 4, 21}
g_EquipGemTable[define.HUMAN_EQUIP.HEQUIP_AMULET_2] = {1, 2, 3, 4, 21}
g_EquipGemTable[define.HUMAN_EQUIP.HEQUIP_CUFF] = {1, 2, 3, 4, 21}
g_EquipGemTable[define.HUMAN_EQUIP.HEQUIP_SHOULDER] = {11, 12, 13, 14}
-- g_EquipGemTable[define.HUMAN_EQUIP.HEQUIP_FASHION] = { 11, 12, 13, 14 }--{ 11, 12, 13, 14 }--衣服
g_EquipGemTable[define.HUMAN_EQUIP.HEQUIP_ANQI] = {
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21
}
g_EquipGemTable[define.HUMAN_EQUIP.HEQUIP_WUHUN] = {
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21
}
-- g_EquipGemTable[define.HUMAN_EQUIP.HEQUIP_UNKNOW2] = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21 }
local g_AssisMat = {{idx = 30900009, odds = 50}, {idx = 30900010, odds = 100}}
-- 镶嵌不同等级宝石的金钱消耗表
local g_EquipGemCost = {}
g_EquipGemCost[1] = 5000
g_EquipGemCost[2] = 6000
g_EquipGemCost[3] = 7000
g_EquipGemCost[4] = 8000
g_EquipGemCost[5] = 9000
g_EquipGemCost[6] = 10000
g_EquipGemCost[7] = 11000
g_EquipGemCost[8] = 12000
g_EquipGemCost[9] = 13000

function gem_embed:CheckEnchaseGemTypeVaild(equipType, gemType)
    for _, gt in ipairs(g_EquipGemTable[equipType]) do
        if gt == gemType then
            return true
        end
    end
    return false
end

function gem_embed:EnchaseEx_4(selfId, GemBagIndex, EquipBagIndex, MatBagIndex1,
                               MatBagIndex2)
    local gemIdx, equipIdx, matIdx1, matIdx2 = -1, -1, -1, -1
    local _slot = self:GetBagGemCount(selfId, EquipBagIndex)
    local _embeded = self:GetGemEmbededCount(selfId, EquipBagIndex)
    local odds = 25 -- 成功玄1�7
    local szTransferItem = ""
    local GemIsBind = false
    local CharmIsBind = 0
    local OddsIsBind = 0
    local IsRedGem = false

    -- 防御双重请求：检查宝石是否仍然有效
    if not self:LuaFnIsItemAvailable(selfId, GemBagIndex) then
        return
    end

    if self:LuaFnGetItemBindStatus(selfId, GemBagIndex) then GemIsBind = true end
    local itemTableIndex = self:LuaFnGetItemTableIndexByIndex(selfId,
                                                              EquipBagIndex)
	if not itemTableIndex or itemTableIndex < 1 then
		return
	end
    local equip = self:GetBagItem(selfId, EquipBagIndex)
    local equip_point = equip:get_equip_data():get_equip_point()
	if equip_point == define.HUMAN_EQUIP.HEQUIP_RIDER
	or equip_point == define.HUMAN_EQUIP.HEQUIP_UNKNOW1
	or equip_point == define.HUMAN_EQUIP.HEQUIP_UNKNOW2
	or equip_point == define.HUMAN_EQUIP.HEQUIP_FASHION
	or equip_point == define.HUMAN_EQUIP.HEQUIP_TOTAL
	or equip_point == define.HUMAN_EQUIP.LINGWU_JING
	or equip_point == define.HUMAN_EQUIP.LINGWU_CHI
	or equip_point == define.HUMAN_EQUIP.LINGWU_JIA
	or equip_point == define.HUMAN_EQUIP.LINGWU_GOU
	or equip_point == define.HUMAN_EQUIP.LINGWU_DAI
	or equip_point == define.HUMAN_EQUIP.LINGWU_DI
	or equip_point == define.HUMAN_EQUIP.HEQUIP_ALL then
		self:notify_tips("该装备不弄1�7放此功能哄1�7")
		return
	end
    -- 褚少微，2008.7.1。重楼戒、重楼玉的机制修改：1、可以打孔；2、可以镶嵌宝石，但只能镶嵌不绑定的宝矄1�7
    --[[if GemIsBind then
        if (itemTableIndex == 10422016 or itemTableIndex == 10423024) then
            self:LuaFnSendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_STUFF_LACK)
            return
        end
    end--]]
    if MatBagIndex1 ~= -1 then
        if self:LuaFnGetItemBindStatus(selfId, MatBagIndex1) then
            CharmIsBind = true
        end
    end
    if MatBagIndex2 ~= -1 then
        if self:LuaFnGetItemBindStatus(selfId, MatBagIndex2) then
            OddsIsBind = true;
        end
    end
    -- 判断宝石合法怄1�7
    if not self:LuaFnIsItemAvailable(selfId, GemBagIndex) then -- 使用有问题的物品则�1�7�1�7出流稄1�7
        self:LuaFnSendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_STUFF_LACK)
        return
    else
        gemIdx = self:LuaFnGetItemTableIndexByIndex(selfId, GemBagIndex)
		local gemval1 = gemIdx % 100000
		local gemtype = math.floor(gemval1 / 1000)
		if gemtype >= 31 and gemtype <= 33 then
			self:notify_tips(selfId, "请不要放入点缄1�7矄1�7")
			return
		end
        if gemIdx > 0 then
            szTransferItem = self:GetBagItemTransfer(selfId, GemBagIndex)
        end
        if not self:IsGem(gemIdx) then
            self:LuaFnSendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_STUFF_LACK)
            return
        end
    end
    -- 判断装备合法怄1�7
    local equipType = self:LuaFnGetBagEquipType(selfId, EquipBagIndex)
    if self:LuaFnIsItemLocked(selfId, EquipBagIndex) or equipType == -1 then -- 使用有问题的物品则�1�7�1�7出流稄1�7
        self:LuaFnSendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_STUFF_LACK)
        return
    else
        equipIdx = self:LuaFnGetItemTableIndexByIndex(selfId, EquipBagIndex)
    end
    -- 判断是否还可以镶嵌更多宝矄1�7
    local equipMaxGemCount = self:GetBagGemCount(selfId, EquipBagIndex)
    local equipEmbededGemCount = self:GetGemEmbededCount(selfId, EquipBagIndex)
    if equipMaxGemCount < 4 then
        self:notify_tips(selfId, "��װ����δ�򿪵��Ŀף��޷����м�����Ƕ")
        return
    end
    if equipEmbededGemCount > 3 then
        self:notify_tips(selfId, "װ��ǰ������ȫ��������������Ƕ���Ŀ���ȷ��װ���Ѵ���Ŀ�")
        return
    end
    -- 如果是血精石或�1�7�红宝石，则放入失败
    for i in ipairs(GemEmbed_four_ID) do
        if GemEmbed_four_ID[i] == gemIdx then IsRedGem = true end
    end
    if IsRedGem then
        self:notify_tips(selfId, "�챦ʯ��Ѫ��ʯ�޷���Ƕ��װ���ĵ��Ŀ���")
        return
    end
    -- 判断宝石和装备的匹配怄1�7
    if not g_EquipGemTable[equipType] then
        self:LuaFnSendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_GEM_NOT_FIT_EQUIP)
        return
    end

    local gemType = self:LuaFnGetItemType(gemIdx)
    local passFlag = false
    for i, gt in ipairs(g_EquipGemTable[equipType]) do
        if gt == gemType then
            passFlag = true
            break
        end
    end
    if not passFlag then
        self:notify_tips(selfId, "Loại Bảo thạch này không thể khảm nạm trên loại Trang bị này")
        return
    end
    -- 判断辅助材料的有效�1�7�1�7
    if MatBagIndex1 == -1 or
        (not self:LuaFnIsItemAvailable(selfId, MatBagIndex1)) then
        MatBagIndex1 = -1
    else
        local findFlag = false
        matIdx1 = self:LuaFnGetItemTableIndexByIndex(selfId, MatBagIndex1)
        for _, matInfo in ipairs(g_AssisMat) do
            if matInfo.idx == matIdx1 then
                findFlag = true
                odds = matInfo.odds
                break
            end
        end
        if not findFlag then -- 这个东西不是镶嵌笄1�7
            MatBagIndex1 = -1
            matIdx1 = -1
        end
    end
    -- 必须镶嵌笄1�7
    if MatBagIndex1 == -1 then 
        self:notify_tips(selfId, "ȱ�ٱ�ʯ��Ƕ�������Ȼ�ȡ��Ƕ���ٽ��м�����Ƕ")
        return
    end

    if MatBagIndex2 == -1 or
        (not self:LuaFnIsItemAvailable(selfId, MatBagIndex2)) then
        MatBagIndex2 = -1
    else
        matIdx2 = self:LuaFnGetItemTableIndexByIndex(selfId, MatBagIndex2)
        if matIdx2 ~= g_FastenMat then -- 这个东西不是强化笄1�7
            MatBagIndex2 = -1
            matIdx2 = -1
        end
    end

    -- 判断金钱数量
    local gemQual = self:GetItemQuality(gemIdx)
    local cost = g_EquipGemCost[gemQual]
    if not cost then cost = 0 end

    -- 第一个孔原价，镶嵌第二个孔收费Ä1�72，镶嵌第三个孔收费Ä1�73
    cost = cost * (equipEmbededGemCount + 1)
    local PlayerMoney = self:GetMoney(selfId) + self:GetMoneyJZ(selfId) -- 交子普及 Vega
    if PlayerMoney < cost then
        self:LuaFnSendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_NOTENOUGH_MONEY)
        return
    end
    -- 按照规则进行消�1�7�1�7
    -- 不管成功失败都消耗金钱�1�7�特殊材斄1�7
    local ret = self:LuaFnCostMoneyWithPriority(selfId, cost) -- 交子普及 Vega
    if not ret then 
        self:LuaFnSendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_NOTENOUGH_MONEY)
        return
    end

    if MatBagIndex1 > -1 then
        local nMaterial = self:LuaFnGetItemTableIndexByIndex(selfId,
                                                             MatBagIndex1)
        self:LuaFnDelAvailableItem(selfId, nMaterial, 1)
    end

    if MatBagIndex2 > -1 then
        local nMaterial1 = self:LuaFnGetItemTableIndexByIndex(selfId,
                                                              MatBagIndex2)
        self:LuaFnDelAvailableItem(selfId, nMaterial1, 1)
    end

    -- 如果成功
    local randRet = math.random(100)
    if odds >= randRet then
        ret = self:GemEnchasing(selfId, GemBagIndex, EquipBagIndex, 4)
        if ret then
            if (GemIsBind or CharmIsBind or OddsIsBind or equipType == 10) then
                self:LuaFnItemBind(selfId, EquipBagIndex);
            end
            self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 49, 0);
            local name = self:GetName(selfId)
            local szTransferEquip = self:GetBagItemTransfer(selfId, EquipBagIndex)
            local fmt = gbk.fromutf8(
                            "#W#{_INFOUSR%s}#H各1�7#W#{_INFOMSG%s}#H镶嵌了一预1�7#W#{_INFOMSG%s}#H，大幅的提升了装备的能力〄1�7")
            local message = string.format(fmt, gbk.fromutf8(name), szTransferEquip,
                                          szTransferItem)
            self:BroadMsgByChatPipe(selfId, message, 4)
            -- 如果失败
        else
            -- 如果玩家有宝石强化符，镶嵌失败之后宝石将会降M=1级，丄1�70就消失�1�7�1�7
            local qualDec = 1
            local gemIdx_new = -1

            -- 如果玩家没有宝石强化符，那么镶嵌失败之后宝石将会降N=2级，丄1�70就消失�1�7�1�7
            if MatBagIndex2 == -1 then qualDec = qualDec + 1 end
            self:LuaFnEraseItem(selfId, GemBagIndex)
            if gemQual - qualDec > 0 then
                gemIdx_new = gemIdx - 100000 * qualDec
                local GemBagIndex = self:TryRecieveItem(selfId, gemIdx_new,
                                                             QUALITY_MUST_BE_CHANGE)
                if (GemIsBind == 1 or CharmIsBind == 1 or OddsIsBind == 1) then
                    self:LuaFnItemBind(selfId, GemBagIndex)
                end
                self:notify_tips(selfId,
                                 "#Y很遗憾，镶嵌失败，宝石降亄1�7" ..
                                     qualDec .. "cấp!")
            else
                self:notify_tips(selfId,
                                 "#YThật đáng tiếc, khảm nạm thất bại, Bảo thạch hỏng rồi!")
            end
            if GemIsBind or CharmIsBind or OddsIsBind then
                self:LuaFnItemBind(selfId, EquipBagIndex)
            end
            self:LuaFnSendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_FAILURE)
            return
        end
        -- 按照成功率进行合戄1�7
        return self:LuaFnSendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_OK)
    end
end

function gem_embed:notify_tip(selfId, msg)
    self:BeginEvent()
    self:AddText(msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function gem_embed:IsGem(itemIndex)
    if math.floor(itemIndex / 10000000) == 5 then return true end
    return false
end

local EnchaseEx_YuanbaoPay_Items = {
    [30900010] = true
}
function gem_embed:EnchaseEx_YuanbaoPay(selfId, ItemIndex, check)
    if EnchaseEx_YuanbaoPay_Items[ItemIndex] then
        self:CallScriptFunction(888902, "yuanbao_pay", selfId, ItemIndex, check, 2013060605, "#{BSLCYH_130529_88")
    end
end

local SplitGemEx_YuanbaoPay_Items = {
    [30900037] = true,
    [30900038] = true,
    [30900039] = true,
    [30900040] = true,
    [30900041] = true,
    [30900042] = true,
    [30900043] = true,
    [30900044] = true
}
function gem_embed:SplitGemEx_YuanbaoPay(selfId, ItemIndex, check)
    if SplitGemEx_YuanbaoPay_Items[ItemIndex] then
        self:CallScriptFunction(888902, "yuanbao_pay", selfId, ItemIndex, check, 2013060606, "#{BSLCYH_130529_109")
    end
end

return gem_embed