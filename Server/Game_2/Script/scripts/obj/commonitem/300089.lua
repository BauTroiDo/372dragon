local class = require "class"
local define = require "define"
local script_base = require "script_base"
local common_item = class("common_item", script_base)
local g_SoulExp = {
	[30700230] = 3000,
	[30700231] = 4000,
	[30700232] = 5000,
}
function common_item:IsSkillLikeScript()
    return 0
end

function common_item:CancelImpacts()
    return 0
end

function common_item:OnConditionCheck(selfId)
	--校验使用的物品
	if not self:LuaFnVerifyUsedItem(selfId) then
		return 0
	end
	return 1
end

function common_item:OnDeplete(selfId)
    return self:LuaFnDepletingUsedItem(selfId)
end

function common_item:OnDefaultEvent(selfId, bagIndex)
    local itemTblIndex = self:GetItemTableIndexByIndex(selfId, bagIndex)
	if g_SoulExp[itemTblIndex] == nil then
		self:notify_tips(selfId, "Dữ liệu vật phẩm không hợp lệ")
		return 0
	end
	local is = self:IsEquipKfs(selfId)
	if not is then
		self:notify_tips(selfId, "#{WH_090729_08}")
		return 0
	end
	local ret = self:CallScriptFunction(809270, "AddKfsExp", selfId, g_SoulExp[itemTblIndex])
	if ret then
		self:LuaFnDecItemLayCount(selfId, bagIndex, 1)
	end
    return 0
end

return common_item