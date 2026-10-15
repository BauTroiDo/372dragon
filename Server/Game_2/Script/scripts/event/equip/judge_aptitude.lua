--装备资质鉴定
--脚本号
local class = require "class"
local define = require "define"
local packet_def = require "game.packet"
local configenginer = require "configenginer":getinstance()
local script_base = require "script_base"
local judge_aptitude = class("judge_aptitude", script_base)
function judge_aptitude:FinishAdjust(selfId, ItemPos)
    print("judge_aptitude:FinishAdjust   =", selfId, ItemPos)
    if ItemPos == -1 then
        return
    end
    local Item = self:GetBagItem(selfId, ItemPos)
    if Item == nil then
        self:notify_tips(selfId, "Trang bị này không dùng được.")
        return
    end
    if Item:is_lock() then
        self:notify_tips(selfId, "Trang bị này không dùng được.")
        return
    end
    if Item:is_qidentd() then
        self:notify_tips(selfId, "Vật phẩm này đã được giám định tư chất.")
        return
    end
    if not Item:is_identd() then
        self:notify_tips(selfId, "Vật phẩm này chưa được giám định, nên không thể giám định tư chất.")
        return
    end
    local equip_base = configenginer:get_config("equip_base")
    local base = equip_base[Item:get_index()]
    if base["是否有资质"] == 0 then
        self:notify_tips(selfId, "Vật phẩm này không có tư chất, nên không thể giám định tư chất.")
        return
    end
    local equip_level = base.level
    local money = self:GetMoney(selfId) + self:GetMoneyJZ(selfId)
    local need_money
    if equip_level < 10 then
		need_money = 10
	elseif equip_level < 20 then
		need_money = 100
	elseif equip_level < 30 then
		need_money = 1000
	elseif equip_level < 40 then
		need_money = 3000
	elseif equip_level < 50 then
		need_money = 4000
	elseif equip_level < 60 then
		need_money = 5000
	elseif equip_level < 70 then
		need_money = 6000
	elseif equip_level < 80 then
		need_money = 7000
	elseif equip_level < 90 then
		need_money = 8000
	elseif equip_level < 100 then
		need_money = 10000
	elseif equip_level < 110 then
		need_money = 20000
	elseif equip_level < 120 then
		need_money = 30000
	else
		need_money = 40000
	end

    if money < need_money then
        self:notify_tips(selfId, "Kim tiền không đủ.")
        return
    end
    local ret = self:LuaFnCostMoneyWithPriority(selfId, need_money)
    if not ret then
        self:notify_tips(selfId, "Lỗi không xác định.")
        return
    end
    Item:set_qidentd(Item.item_index)
    local msg = packet_def.GCItemInfo.new()
    msg.bagIndex = ItemPos
    msg.item = Item:copy_raw_data()
    self.scene:send2client(selfId, msg)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 49, 0)
end

function judge_aptitude:FinishReAdjust(selfId, ItemPos)
    print("judge_aptitude:FinishAdjust   =", selfId, ItemPos)
    if ItemPos == -1 then
        return
    end
    local Item = self:GetBagItem(selfId, ItemPos)
    if Item == nil then
        self:notify_tips(selfId, "Trang bị này không dùng được.")
        return
    end
    if Item:is_lock() then
        self:notify_tips(selfId, "Trang bị này không dùng được.")
        return
    end
    if not Item:is_identd() then
        self:notify_tips(selfId, "Vật phẩm này chưa được giám định, nên không thể giám định tư chất.")
        return
    end
    local equip_base = configenginer:get_config("equip_base")
    local base = equip_base[Item:get_index()]
    if base["是否有资质"] == 0 then
        self:notify_tips(selfId, "Vật phẩm này không có tư chất, nên không thể giám định tư chất.")
        return
    end

    local itemCount = self:LuaFnGetAvailableItemCount(selfId, 30008034)
	local itemCount2 = self:LuaFnGetAvailableItemCount(selfId, 30008048)
	if itemCount < 1 and itemCount2 < 1 then
        self:notify_tips(selfId, "Ngươi thiếu Kim Cương Sa hoặc Kim Cương Tỏa.")
		return
	end
    local equip_level = base.level
    local money = self:GetMoney(selfId) + self:GetMoneyJZ(selfId)
	local need_money = 20 * equip_level + 50
    if money < need_money then
        self:notify_tips(selfId, "Kim tiền không đủ.")
        return
    end
	--检查装备是否是绑定
	local ret = self:LuaFnGetItemBindStatus(selfId, ItemPos)
	--扣除规则是：绑定优先，然后是金刚砂优先。也就扣除次序是绑定金刚砂，绑定金刚锉，金刚砂，金刚锉
	--找绑定金刚砂
	local ShaPos = self:GetBagPosByItemSnAvailableBind(selfId, 30008034, true)
	local needBind = false
	if ret then
		if ShaPos ~= -1 then
			needBind = true
		end
	end
	local ShaPos2 = -1
	if ShaPos == -1 then --找绑定金刚锉
		ShaPos2 = self:GetBagPosByItemSnAvailableBind(selfId, 30008048, true)
	end
	if ret then
		if ShaPos2 ~= -1 then
			needBind = true
		end
	end
	if ShaPos == -1 and ShaPos2 == -1 then --找金刚砂
		ShaPos = self:GetBagPosByItemSnAvailableBind(selfId, 30008034, false)
	end
	if ShaPos == -1 and ShaPos2 == -1 then --找金刚锉
		ShaPos2 = self:GetBagPosByItemSnAvailableBind(selfId, 30008048, false)
	end
	local ShaInfo = 0
	-- 扣金刚砂或金刚锉....
	if ShaPos ~= -1 then
		ShaInfo = self:GetBagItemTransfer(selfId, ShaPos )
		ret = self:LuaFnDecItemLayCount(selfId, ShaPos, 1)
		if not ret then
            self:notify_tips(selfId, "Kim Cương Sa không thể dùng.")
			return
		end
	elseif ShaPos2 ~= -1 then
		ShaInfo = self:GetBagItemTransfer( selfId, ShaPos2 )
		local r, t = self:LuaFnEraseItemTimes( selfId, ShaPos2, 11 )
		local szMsg = string.format( "Kim Cương Tỏa số lần sử dụng còn lại %d/%d", tonumber(t), tonumber(11) );
        self:notify_tips(selfId, szMsg)
	end
	-- 重新鉴定装备资质....
	ret = self:LuaFnReSetItemApt(selfId, ItemPos )
	if ret == 1 then
		-- 扣钱....
		self:LuaFnCostMoneyWithPriority(selfId, need_money ) --zchw
		-- 加鉴定成功特效....
		self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 49, 0);
		--绑定
		if needBind then
			self:LuaFnItemBind(selfId, ItemPos )
		end
        self:notify_tips(selfId, "Tư chất Trang bị giám định lại thành công")
		return

	elseif ret == 2 or ret == 3 then -- zchw for notice
		-- [ QUFEI 2007-09-17 17:22 UPDATE BugID 25245 ]
		-- 扣钱....
		self:LuaFnCostMoneyWithPriority(selfId, need_money ) --zchw

		-- 加鉴定成功特效....
		self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 49, 0);
		--绑定
		if needBind == 1 then
			self:LuaFnItemBind(selfId, ItemPos )
		end
        self:notify_tips(selfId, "Tư chất Trang bị giám định lại thành công")
		--发公告....
		--self:ReAdjustNotify(selfId, ret, ShaPos, ShaPos2, ShaInfo, ItemPos )
		return

	else
        self:notify_tips(selfId, "Lỗi không xác định.")
		return
	end
end

function judge_aptitude:notify_tip(selfId, msg)
	self:BeginEvent()
        self:AddText(msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return judge_aptitude