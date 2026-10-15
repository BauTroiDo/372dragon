local class = require "class"
local define = require "define"
local script_base = require "script_base"
local common_item = class("common_item", script_base)
-- local gbk = require "wire_charset"
local use_item = 
{
    [30505076] = 500000,
    [38008188] = 500000,
    [38008189] = 500000,
    [38008190] = 1000000,
    [38008191] = 1000000,
    [38008192] = 2000000,
    [38008193] = 2000000,
    [38008194] = 3000000,
    [38008195] = 3000000,
    [38008196] = 5000000,
    [38008197] = 5000000,
    [38008198] = 8000000,
    [38008199] = 8000000,
    [38008200] = 10000000,
    [38008201] = 10000000,
}

function common_item:OnDefaultEvent(selfId, bagIndex)
end

function common_item:IsSkillLikeScript(selfId)
    return 1
end

function common_item:CancelImpacts(selfId)
    return 0
end

function common_item:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
	local useid = self:LuaFnGetItemIndexOfUsedItem(selfId )
	if not use_item[useid] then
		return 0
	end
    local nLevel = self:GetLevel(selfId)
    if nLevel < 30 then
		self:notify_tips(selfId, "Chưa đủ cấp 30.")
        return 0
    end
    return 1
end

function common_item:OnDeplete(selfId)
    return 1
end

function common_item:OnActivateOnce(selfId)
	local useid = self:LuaFnGetItemIndexOfUsedItem(selfId )
	local add_exp = use_item[useid]
	if not add_exp then
		return 0
	end
    local nLevel = self:GetLevel(selfId)
    if nLevel < 30 then
		self:notify_tips(selfId, "Chưa đủ cấp 30.")
        return 0
    end
	local usepos = self:LuaFnGetBagIndexOfUsedItem(selfId)
	if self:LuaFnGetItemTableIndexByIndex(selfId,usepos) ~= useid then
		self:notify_tips(selfId, "Dùng đạo cụ bất thường, xin thử lại.")
        return 0
    end
    -- local szTransfer = self:GetBagItemTransfer(selfId, usepos)
	self:LuaFnDecItemLayCount(selfId,usepos,1)
	self:AddExp(selfId, add_exp)
	local msg = string.format("Ngươi nhận kinh nghiệm %d.",add_exp)
	self:notify_tips(selfId,msg)
	self:ShowObjBuffEffect(selfId,selfId,-1,18)
    -- local message = string.format(gbk.fromutf8("#{_INFOUSR%s}服用了一颗天下第一奇药#{_INFOMSG%s}，不禁觉得浑身舒泰，感觉自己功力大有长进。"),gbk.fromutf8(szPlayerName), szTransfer)
    -- self:AddGlobalCountNews(message,true)
    return 1
end

function common_item:OnActivateEachTick(selfId)
    return 1
end

return common_item
