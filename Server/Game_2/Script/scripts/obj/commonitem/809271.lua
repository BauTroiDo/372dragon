local class = require "class"
local define = require "define"
local script_base = require "script_base"
local common_item = class("common_item", script_base)

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
	return 1
end

function common_item:OnDeplete(selfId)
    return 1
end

function common_item:OnActivateOnce(selfId)
	local bagId	 = self:LuaFnGetBagIndexOfUsedItem(selfId)
    local use = {}
    use.equipPoint = define.HUMAN_EQUIP.HEQUIP_WUHUN
    use.type = 0
    use.bagIndex = bagId
    self:LuaFnItemBind(selfId, bagId)
    self:get_scene():char_use_equip(selfId, use)
    self:LuaFnRefreshItemInfo(selfId, bagId)
	return 1
end

return common_item