--御龙帖
--普通
local gbk = require "wire_charset"
local ScriptGlobal = require "scripts.ScriptGlobal"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local yulongtie = class("yulongtie", script_base)

function yulongtie:OnClickOpenBtn(selfId, targetId)
    self:BeginUICommand()
        local enddate = self:GetMissionData(selfId, ScriptGlobal.MD_YU_LONG_TIE_END_TIME)
        enddate = tostring(enddate)
        self:UICommand_AddInt(tonumber(string.sub(enddate, 1, 2)) + 2000)
        self:UICommand_AddInt(tonumber(string.sub(enddate, 3, 4)))
        self:UICommand_AddInt(tonumber(string.sub(enddate, 5, 6)))
    self:EndUICommand()
    self:DispatchUICommand(selfId, 89266604)
end

function yulongtie:DoFunc(selfId, index)
    print("yulongtie:DoFunc =", selfId, index)
    if not self:CheckMonthCardVaildate(selfId) then
        self:notify_tips(selfId, "#{HJYK_201223_11}")
        return
    end
    if index == 1 then
        self:on_click_double_exp(selfId)
    elseif index == 2 then
        self:open_chongwu_shop(selfId)
    elseif index == 3 then
        self:open_bank(selfId)
    elseif index == 9 then
        self:open_pet_bank(selfId)
    elseif index == 4 then
        self:open_fix_equip(selfId)
    elseif index == 5 then
        self:open_add_fix_equip_count(selfId)
    elseif index == 6 then
        self:open_fix_wuhun(selfId)
    elseif index == 7 then
        self:open_fix_shenqi(selfId)
    end
end

function yulongtie:UNLockTime(selfId)
    self:DESetLock(selfId, false)
	self:notify_tips(selfId, "Thời gian kinh nghiệm gấp đôi ngươi đóng băng đã được giải đóng băng.")
    self:SendDoubleExpToClient(selfId)
end

function yulongtie:LockTime(selfId)
    self:DESetLock(selfId, true)
	self:notify_tips(selfId, "Thời gian x2 của ngươi đã đóng băng")
    self:SendDoubleExpToClient(selfId)
end

function yulongtie:on_click_double_exp(selfId)
    local nCurHave = self:DEGetFreeTime(selfId)
    nCurHave = nCurHave + self:DEGetMoneyTime(selfId)
    if nCurHave == 0 then
        self:notify_tips(selfId, "#{HJYK_201223_20}")
    else
        if self:DEIsLock(selfId) then
            self:BeginUICommand()
                self:UICommand_AddInt(892666)
                self:UICommand_AddInt(-1)
                self:UICommand_AddInt(50)
                self:UICommand_AddStr("UNLockTime")
                local str = string.format("Ngươi có %d phút để rã đông, chắc chắn rã đông chứ?", math.floor(nCurHave / 60))
                self:UICommand_AddStr(str)
            self:EndUICommand()
            self:DispatchUICommand(selfId, 24)
        else
            self:BeginUICommand()
                self:UICommand_AddInt(892666)
                self:UICommand_AddInt(-1)
                self:UICommand_AddInt(50)
                self:UICommand_AddStr("LockTime")
                local str = string.format("Ngươi hiện có %d phút thời gian gấp đôi, ngươi xác định muốn đóng băng không?", math.floor(nCurHave / 60))
                self:UICommand_AddStr(str)
            self:EndUICommand()
            self:DispatchUICommand(selfId, 24)
        end
    end
end

function yulongtie:open_chongwu_shop(selfId)
    local targetId = define.INVAILD_ID
    self:DispatchShopItem(selfId, targetId, 27)
end

function yulongtie:open_bank(selfId)
    local targetId = define.INVAILD_ID
    self:BankBegin(selfId, targetId)
end

function yulongtie:open_pet_bank(selfId)
    local targetId = define.INVAILD_ID
    self:PetBankBegin(selfId, targetId)
end

function yulongtie:open_fix_equip(selfId)
    self:BeginUICommand()
        self:UICommand_AddInt(-1)
        self:UICommand_AddInt(-1)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 19810313)
end

function yulongtie:open_add_fix_equip_count(selfId)
    self:BeginUICommand()
        self:UICommand_AddInt(-1)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 1004)
end

function yulongtie:open_fix_wuhun(selfId)
    self:BeginUICommand()
        self:UICommand_AddInt(-1)
        self:UICommand_AddInt(3)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 20090721)
	--[[if self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_CHOULOU) == 1 then
		self:notify_tips( selfId, "您已经领取过了。" )
		return
	end
	self:BeginAddItem()
	self:AddItem(10415055, 1, true)
	if not self:EndAddItem(selfId) then
		self:notify_tips( selfId, "背包空间不足" )
		return
	end
	self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_CHOULOU, 1)
	self:AddItemListToHuman(selfId)
	self:notify_tips( selfId, "领取成功。" )--]]
end

function yulongtie:open_fix_shenqi(selfId)
    self:BeginUICommand()
        self:UICommand_AddInt(-1)
        self:UICommand_AddInt(-1)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 101526358)
end

function yulongtie:OnUseMonthCard(selfId)
    -- if self:CheckMonthCardVaildate(selfId) then
        -- self:notify_tips(selfId, "#{HJYK_201223_03}")
        -- return
    -- end
	local card1 = self:LuaFnGetAvailableItemCount(selfId, 38000221)
	local card30 = self:LuaFnGetAvailableItemCount(selfId, 38000205)
	local addtime = 0
	local costid = 0
	if card1 > 0 then
		addtime = 24 * 60 * 60
		costid = 38000221
	elseif card30 > 0 then
		addtime = 30 * 24 * 60 * 60
		costid = 38000205
	else
        self:notify_tips(selfId, "Túi không thấy đạo cụ Ngự Long Thiếp")
        return
    end
    local BagPos = self:LuaFnGetItemPosByItemDataID(selfId, costid)
    local itemTransfer = self:GetBagItemTransfer(selfId, BagPos)
    local del = self:LuaFnDelAvailableItem(selfId, costid, 1)
	if del then
		local havetime = self:GetMissionData(selfId, ScriptGlobal.MD_YU_LONG_TIE_END_TIME)
		local curtime = os.time()
		if havetime > 0 then
			local year = havetime // 100000000 + 2000
			havetime = havetime % 100000000
			local month = havetime // 1000000
			havetime = havetime % 1000000
			local day = havetime // 10000
			havetime = havetime % 10000
			local hour = havetime // 100
			local minute = havetime % 100
			havetime = os.time({year = year, month = month, day = day, hour = hour, min = minute, sec = 0})
		end
		if havetime > curtime then
			havetime = havetime - curtime
		else
			havetime = 0
		end
		havetime = havetime + addtime
		local end_date = self:GetDiffTime2Day2(havetime)
		self:SetMissionData(selfId, ScriptGlobal.MD_YU_LONG_TIE_END_TIME, end_date)
		-- if costid == 38000205 then
		-- 	self:AddBindYuanBao(selfId, 8888)
		-- end
		local sMessage = self:ContactArgsNotTransfer("#{HJYK_201223_09", gbk.fromutf8(self:GetName(selfId)), itemTransfer)
		self:AddGlobalCountNews(sMessage .. "}", true)
		self:BeginUICommand()
		self:EndUICommand()
		self:DispatchUICommand(selfId, 89266602)
	end
end
function yulongtie:OnUseMonthCard2(selfId)
	local card30 = self:LuaFnGetAvailableItemCount(selfId, 38000220)
	local addtime = 0
	local costid = 0
	if card30 > 0 then
		addtime = 30 * 24 * 60 * 60
		costid = 38000220
	else
        self:notify_tips(selfId, "Túi không thấy thẻ Tử Kim Du Long")
        return
    end
    local BagPos = self:LuaFnGetItemPosByItemDataID(selfId, costid)
    -- local itemTransfer = self:GetBagItemTransfer(selfId, BagPos)
    local del = self:LuaFnDelAvailableItem(selfId, costid, 1)
	if del then
		local havetime = self:GetMissionData(selfId, 534)
		local curtime = os.time()
		if havetime > curtime then
			havetime = havetime - curtime
		else
			havetime = 0
		end
		local newtime = havetime + addtime + curtime
		self:SetMissionData(selfId, 534, newtime)
		if havetime > 0 then
			self:notify_tips(selfId, "Bạn gia hạn thẻ Tử Kim Du Long thêm 30 ngày thành công.")
		else
			self:notify_tips(selfId, "Bạn kích hoạt thẻ Tử Kim Du Long 30 ngày thành công.")
		end
		-- local sMessage = self:ContactArgsNotTransfer("#{HJYK_201223_09", gbk.fromutf8(self:GetName(selfId)), itemTransfer)
		-- self:AddGlobalCountNews(sMessage .. "}", true)
		-- self:BeginUICommand()
		-- self:EndUICommand()
		-- self:DispatchUICommand(selfId, 89266602)
	end
end




function yulongtie:OnScenePlayerEnter(selfId)
    local UICOMMAND = 0
    if self:CheckMonthCardVaildate(selfId) then
        UICOMMAND = 89266602
    else
        UICOMMAND = 89266603
    end
    self:BeginUICommand()
    self:EndUICommand()
    self:DispatchUICommand(selfId, UICOMMAND)
end

function yulongtie:CheckMonthCardVaildate(selfId)
    local enddate = self:GetMissionData(selfId, ScriptGlobal.MD_YU_LONG_TIE_END_TIME)
    local nowdate = self:GetTime2Day2()
    return enddate >= nowdate
end

return yulongtie