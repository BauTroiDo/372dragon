local class = require "class"
local define = require "define"
local script_base = require "script_base"

local DuiHuan = class("DuiHuan", script_base)
DuiHuan.script_id = 901029

local UI_COMMAND_SHOW_LIST = 20170204
local UI_COMMAND_SHOW_TIPS = 20170205
local DAILY_RECHARGE_SCRIPT_ID = 888817

local OneItem = {
     50602005,
     50602006,
     50602007,
     50602008,
     50603001,
     50604002,
     50611001,
     50611002,
     50612005,
     50612006,
     50612007,
     50612008,
     50613001,
     50613002,
     50613003,
     50613004,
     50613005,
     50613006,
     50614001,
     50621001,
     50621002,
     50621003,
     50621004,
}

local TwoItem = {
	
}

local ExchangeCfg = {
--材料兑换
	[1] = {
        [1] = { costItem = 30900132, costNum = 1, awardNum = 1 },
		[2] = { costItem = 30900132, costNum = 1, awardNum = 1 },
		[3] = { costItem = 30900132, costNum = 1, awardNum = 1 },
		[4] = { costItem = 30900132, costNum = 1, awardNum = 1 },
		[5] = { costItem = 30900132, costNum = 1, awardNum = 1 },
		[6] = { costItem = 30900132, costNum = 1, awardNum = 1 },
		[7] = { costItem = 30900132, costNum = 1, awardNum = 1 },
		[8] = { costItem = 30900132, costNum = 1, awardNum = 1 },
		[9] = { costItem = 30900132, costNum = 1, awardNum = 1 },
		[10] = { costItem = 30900132, costNum = 1, awardNum = 1 },
        [11] = { costItem = 30900132, costNum = 1, awardNum = 1 },
		[12] = { costItem = 30900132, costNum = 1, awardNum = 1 },
		[13] = { costItem = 30900132, costNum = 1, awardNum = 1 },
		[14] = { costItem = 30900132, costNum = 1, awardNum = 1 },
		[15] = { costItem = 30900132, costNum = 1, awardNum = 1 },	
        [16] = { costItem = 30900132, costNum = 1, awardNum = 1 },	
        [17] = { costItem = 30900132, costNum = 1, awardNum = 1 },	
        [18] = { costItem = 30900132, costNum = 1, awardNum = 1 },	
        [19] = { costItem = 30900132, costNum = 1, awardNum = 1 },	
        [20] = { costItem = 30900132, costNum = 1, awardNum = 1 },	
        [21] = { costItem = 30900132, costNum = 1, awardNum = 1 },	
        [22] = { costItem = 30900132, costNum = 1, awardNum = 1 },	
        [23] = { costItem = 30900132, costNum = 1, awardNum = 1 },	
		
		
	},
	--经验兑换
	-- [2] = {
		-- [1] = { costExp = 2000, awardNum = 1 },
	-- },
}

local function build_id_list(list)
    local nData = ""
    for i = 1, #list do
        nData = nData .. tostring(list[i]) .. ","
    end
    return nData
end

function DuiHuan:OpenList(selfId, oper)
    local list
    if oper == 1 then
        list = OneItem
    elseif oper == 2 then
        list = TwoItem
    else
        return
    end

    local nData = build_id_list(list)
    self:BeginUICommand()
    self:UICommand_AddInt(oper)
    self:UICommand_AddInt(oper)
    self:UICommand_AddStr("")
    self:UICommand_AddStr(nData)
    self:EndUICommand()
    self:DispatchUICommand(selfId, UI_COMMAND_SHOW_LIST)
end

function DuiHuan:OnDefaultEvent(selfId, targetId, arg, index)
    self:BeginEvent(self.script_id)
    --self:AddText("#Y我这里可以进行装备解绑，需满足以下条件：#R#r1.装备必须是手工装备#R#r2.装备等级 ≥ 60#R#r3.装备未强化#R#r4.装备未镶嵌宝石、未佩戴雕纹#R#r5.背包内有解绑材料")
    --self:AddNumText("#G每日充值", 6, 0)
    --self:AddNumText("#G装备解绑#R（将装备放在第一格）", 6, 1)
    --self:AddNumText("#G幸运抽奖", 6, 2)
    self:AddNumText("#GTri ân tinh phẩm", 6, 3)
   -- self:AddNumText("#G经验兑换", 6, 2)
    self:AddNumText("#GĐổi bảo thạch", 6, 4)
    --self:AddNumText("离开……", 11, 0)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function DuiHuan:OnEventRequest(selfId, targetId, arg, index)
    index = tonumber(index) or 0
    if index == 0 then
        self:CallScriptFunction(888817,"OpenUI",selfId,0)
        return
    end
    if index == 1 then
        --self:OpenList(selfId, index)
        self:CallScriptFunction(998525, "DoUnbind", selfId, targetId)
        return
    end
    if index == 2 then
        self:CallScriptFunction(893998, "SendPool", selfId)
        return
    end
    if index == 3 then
        self:CallScriptFunction(180001,"OpenTopChongZhi",selfId,targetId,101)
        return
    end
    if index == 4 then
        self:OpenList(selfId, 1)
        return
    end
end
function DuiHuan:OnUICommand(selfId, cmd, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
    -- 处理UI命令，这里可以根据需要添加具体逻辑
    -- 目前主要用于接收转发，可以留空或添加日志
end
function DuiHuan:DuiHuanXiTong(selfId, type, oper, nIndex)
    type = tonumber(type) or 0
    oper = tonumber(oper) or 0
    nIndex = tonumber(nIndex) or 0

    local list
    if oper == 1 then
        list = OneItem
    elseif oper == 2 then
        list = TwoItem
    else
        return
    end

    local itemId = list and list[nIndex] or nil
    if not itemId then
        return
    end

	local cfg = ExchangeCfg[oper] and ExchangeCfg[oper][nIndex] or nil
	if not cfg then
		return
	end

    if type == 1 then
        self:BeginUICommand()
        self:UICommand_AddInt(nIndex)
		local tip1 = "#cFF0000" .. tostring(self:GetItemName(itemId))
		local tip2 = ""
		local tip3 = ""
		if cfg.costExp and cfg.costExp > 0 then
			tip2 = "#GKinh nghiệm cần để đổi:#cFF0000" .. tostring(cfg.costExp)
		elseif cfg.costItem and cfg.costNum and cfg.costNum > 0 then
			tip2 = "#GCần để đổi:#cFF0000" .. tostring(self:GetItemName(cfg.costItem))
			tip3 = "#GSố tiêu hao:#cFF0000" .. tostring(cfg.costNum)
		end
		self:UICommand_AddStr(tip1 .. "," .. tip2 .. "," .. tip3)
        self:EndUICommand()
        self:DispatchUICommand(selfId, UI_COMMAND_SHOW_TIPS)
        return
    end

    if type == 2 then
		if cfg.costExp and cfg.costExp > 0 then
			local myExp = self:GetExp(selfId) or 0
			if myExp < cfg.costExp then
				self:notify_tips(selfId, "Không đủ kinh nghiệm")
				return
			end
		elseif cfg.costItem and cfg.costNum and cfg.costNum > 0 then
			local haveCount = self:LuaFnGetAvailableItemCount(selfId, cfg.costItem) or 0
			if haveCount < cfg.costNum then
				self:notify_tips(selfId, "Không đủ nguyên liệu")
				return
			end
			if self:LuaFnGetPropertyBagSpace(selfId) < 1 then
				self:notify_tips(selfId, "Túi hành trang không đủ chỗ")
				return
			end
			if not self:LuaFnMtl_CostMaterial(selfId, cfg.costNum, { cfg.costItem }) then
				self:notify_tips(selfId, "Trừ nguyên liệu thất bại")
				return
			end
		else
			return
		end
		self:BeginAddItem()
		self:AddItem(itemId, cfg.awardNum or 1, false)
		if not self:EndAddItem(selfId) then
			self:notify_tips(selfId, "Túi hành trang không đủ chỗ")
			return
		end
		if cfg.costExp and cfg.costExp > 0 then
			self:AddExp(selfId, 0 - cfg.costExp)
		end
		self:AddItemListToHuman(selfId)
		self:notify_tips(selfId, "Đổi thành công.")
        return
    end
end

return DuiHuan
