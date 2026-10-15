--绑定元宝票

local class = require "class"
local define = require "define"
local script_base = require "script_base"
local common_item = class("common_item", script_base)

local item_cfgs = {
    [38000060] = {2,100},
    [38000202] = {2,50},
    [38000203] = {2,200},
    [38002162] = {2,70},
    [38002163] = {2,75},
    [38002164] = {2,80},
    [38002165] = {2,85},
    [38002166] = {2,90},
    [38002167] = {2,95},
    [38002168] = {2,300},
    [38002169] = {2,500},
    [38002174] = {2,110},
    [38002175] = {2,130},
    [38002176] = {2,150},
    [38002224] = {2,40},
    [38002225] = {2,45},
    [38002226] = {2,55},
    [38002227] = {2,60},
    [38002263] = {2,20},
    [38002264] = {2,30},
	[38008001] = {2,400},
	[38008002] = {2,600},
	[38008003] = {2,700},
	[38008004] = {2,800},
	[38008005] = {2,1000},
    [38008021] = {2,500},
    [30505185] = {2,20000},
    [30505186] = {2,30000},
    [30505187] = {2,50000},
    [30505188] = {2,100000},
    [30505189] = {2,200000},
    [30505190] = {2,500000},

	[38008006] = {1,40},
	[38008007] = {1,50},
	[38008008] = {1,55},
	[38008009] = {1,60},
	[38008010] = {1,75},
	[38008011] = {1,100},
	[38008012] = {1,150},
	[38008013] = {1,200},
	[38008014] = {1,300},
	[38008015] = {1,400},
	[38008016] = {1,500},
	[38008017] = {1,600},
	[38008018] = {1,700},
	[38008019] = {1,800},
	[38008020] = {1,1000},
}

function common_item:IsSkillLikeScript()
    return 1
end

function common_item:CancelImpacts()
    return 0
end

function common_item:OnConditionCheck(selfId)
    if not self:LuaFnVerifyUsedItem(selfId) then
		return 0
	end
    local BagPos = self:LuaFnGetBagIndexOfUsedItem(selfId)
    local nItemId = self:GetItemTableIndexByIndex(selfId, BagPos)
    if item_cfgs[nItemId] == nil then
        self:notify_tips(selfId, "Đạo cụ chưa mở")
    end
    return 1
end

function common_item:OnDeplete(selfId)
    return 1
end

function common_item:OnActivateOnce(selfId)
    local BagPos = self:LuaFnGetBagIndexOfUsedItem(selfId)
	local nItemId = self:GetItemTableIndexByIndex(selfId, BagPos)
    local value = item_cfgs[nItemId]
    if value == nil then
        self:notify_tips(selfId, "Đạo cụ chưa mở")
        return 0
    end
	self:LuaFnDecItemLayCount(selfId, BagPos, 1)
	if value[1] == 2 then
		self:AddBindYuanBao(selfId, value[2])
		self:notify_tips(selfId, "Ngươi nhận nguyên bảo khóa"..tostring(value[2]).."。")
	elseif value[1] == 1 then
		self:CSAddYuanbao(selfId,value[2])
		self:notify_tips(selfId, "Ngươi nhận được nguyên bảo"..tostring(value[2]).."。")
	end
    -- self:LuaFnDepletingUsedItem(selfId)
    return define.USEITEM_RESULT.USEITEM_SUCCESS
end

return common_item