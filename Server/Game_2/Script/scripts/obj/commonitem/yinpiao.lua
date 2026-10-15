local class = require "class"
local define = require "define"
local script_base = require "script_base"
local yinpiao = class("yinpiao", script_base)
yinpiao.script_id = 333000

function yinpiao:OnDefaultEvent(selfId, bagIndex)
	local value = self:GetBagItemParam(selfId, bagIndex, 0, "uint")
	local nMoneyMax = 9990000
	-- 异常检查
	-- 钱是否超过最高上限
	if value > nMoneyMax then
		value = nMoneyMax
	end
	-- 是否是银票
	local nItemID = self:LuaFnGetItemTableIndexByIndex(selfId, bagIndex)
	if nItemID ~= 30001000 then
		return 0
	end
    self:EraseItem(selfId, bagIndex)
	self:AddMoney(selfId, value)
    return 0
end

function yinpiao:IsSkillLikeScript(selfId) return 0 end

return yinpiao
