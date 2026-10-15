--装备资质鉴定
--脚本号
local class = require "class"
local script_base = require "script_base"
local DressPaint = class("DressPaint", script_base)
local HongYaoShiItemID = 30503140
local DressPraint = 50000
function DressPaint:OnDressPaint(selfId, ...)
    print("DressPaint:OnDressPaint =", ...)
    local pos, nYuanBaoCheck = ...
    local nItemId = self:GetItemTableIndexByIndex(selfId, pos)
	local EquipPoint = self:GetItemEquipPoint( nItemId )
	if EquipPoint ~= 16 then
		self:notify_tip(selfId, "#{SZPR_091023_17}")
		return
	end
	local ret = self:LuaFnIsItemAvailable(selfId, pos )
	if not ret then
		self:notify_tip(selfId, "#{SZPR_091023_18}")
		return
	end
	if self:LuaFnGetAvailableItemCount(selfId, HongYaoShiItemID) < 1 then
		--self:notify_tip(selfId, "#{SZPR_091023_21}")
		self:DressPaint_YuanbaoPay(selfId, HongYaoShiItemID, nYuanBaoCheck)
		return
	end
	self:OnDressPaint_OK(selfId, pos, 0)--直接走
end

function DressPaint:DressPaint_YuanbaoPay(selfId, ItemIndex, check)
	local hint = "#{SZRSYH_120912_02"
	local index, merchadise = self:GetMerchadiseByItemIndex(selfId, ItemIndex)
	if index == nil then
		return
	end
	self:BeginUICommand()
	self:UICommand_AddInt(2)
	self:UICommand_AddInt(5)
	self:UICommand_AddInt(merchadise.price)
	self:UICommand_AddInt(index - 1)
	self:UICommand_AddInt(0)
	self:UICommand_AddInt(self.script_id)
	self:UICommand_AddInt(check)
	self:UICommand_AddInt(-1)
	local str = self:ContactArgs(hint, merchadise.id, merchadise.price, "#{XFYH_20120221_10}", "#{XFYH_20120221_12}", merchadise.id) .. "}"
	self:UICommand_AddStr(str)
	self:EndUICommand()
	self:DispatchUICommand(selfId, 20210315)
end

function DressPaint:notify_tip(selfId, msg)
	self:BeginEvent()
        self:AddText(msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function DressPaint:OnDressPaint_OK(selfId, pos,isAuto)
	local nItemId =self: GetItemTableIndexByIndex(selfId, pos)
	local EquipPoint = self:GetItemEquipPoint(nItemId )
	if EquipPoint ~= 16 then
		self:notify_tip(selfId, "#{SZPR_091023_17}" )
		return
	end
	local ret = self:LuaFnIsItemAvailable(selfId, pos )
	if not ret then
		self:notify_tip(selfId, "#{SZPR_091023_18}" )
		return
	end
	if self:LuaFnGetAvailableItemCount(selfId, HongYaoShiItemID) < 1 then
		if isAuto == 1 then
			self:notify_tip( selfId, "#{YJRS_140613_13}" )
		else
			self:notify_tip( selfId, "#{SZPR_091023_21}" )
		end
		return
	end
	local PlayerMoney = self:GetMoney(selfId ) +  self:GetMoneyJZ(selfId)
	if PlayerMoney < DressPraint then
		if isAuto == 1 then
			self:notify_tip(selfId, "#{YJRS_140613_14}" )
		else
			self:notify_tip(selfId, "#{JXSQ_170804_44}" )
		end
		return
	end
    local DressColorRate = self:GetDressColorRate(selfId, pos)
	if DressColorRate == nil then
		self:notify_tip(selfId, "#{SZPR_091023_18}")
		return
	end
    local nFinalRandom = self:RandomColor(DressColorRate.visual)
	if nFinalRandom ~= 0 then
		self:LuaFnSetEquipVisual(selfId,pos,nFinalRandom)
		self:LuaFnDelAvailableItem(selfId,HongYaoShiItemID,1) --材料扣除
		self:LuaFnCostMoneyWithPriority(selfId, DressPraint) --扣钱
		self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 151, 0)
		self:notify_tip(selfId, "Chúc mừng, Nhuộm Thời Trang thành công")
		self:BeginUICommand()
		    self:UICommand_AddInt(nFinalRandom ) --visualid
		    self:UICommand_AddInt(pos ) --pos
		    self:UICommand_AddInt(1)
		self:EndUICommand( )
		self:DispatchUICommand(selfId, 1000000011 )
		return
	end
end

function DressPaint:RandomColor(colors)
    local total = 0
    for _, v in ipairs(colors) do
        if v.rate ~= -1 then
            total  = total + v.rate
        end
    end
    local num = math.random(total)
    local now = 0
    local RandColor
    for _, v in ipairs(colors) do
        if v.rate ~= -1 then
            now  = now + v.rate
			RandColor = v.id
			if now >= num then
				break
			end
        end
    end
	print("DressPaint:RandomColor RandColor =", RandColor, ";num =", num, ";colors =", table.tostr(colors))
	assert(RandColor, num)
    return RandColor
end

function DressPaint:OnAutoDressPaint(selfId, ...)
    print("DressPaint:OnAutoDressPaint =", ...)
    local pos, isFirstAuto, destVisualID = ...
    -- 自动染色和手动染色的逻辑一致，只是错误提示不同
    self:OnDressPaint_OK(selfId, pos, 1)
end

return DressPaint