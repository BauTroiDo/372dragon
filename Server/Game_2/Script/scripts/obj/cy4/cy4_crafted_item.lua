local class = require "class"
local script_base = require "script_base"
local config = require "cy_four_crafting_config"
local item = class("cy4_crafted_item", script_base)
item.script_id = 980100

function item:IsSkillLikeScript() return 1 end
function item:CancelImpacts() return 0 end
function item:OnDefaultEvent() end

function item:product(selfId)
    return config.products[self:LuaFnGetItemIndexOfUsedItem(selfId)]
end

function item:OnConditionCheck(selfId)
    local row = self:product(selfId)
    if not row or not self:LuaFnVerifyUsedItem(selfId) then return 0 end
    if self:GetLevel(selfId) < row.level then
        self:notify_tips(selfId, "Bạn chưa đủ cấp sử dụng vật phẩm."); return 0
    end
    if row.faction_only and self:GetMenPai(selfId) ~= row.faction then
        self:notify_tips(selfId, "Dược phẩm này chỉ dành cho đệ tử bổn phái."); return 0
    end
    return 1
end

function item:OnDeplete(selfId)
    if self:OnConditionCheck(selfId) ~= 1 then return 0 end
    return self:LuaFnDepletingUsedItem(selfId) and 1 or 0
end

function item:OnActivateOnce(selfId)
    local row = self:product(selfId)
    if not row then return 0 end
    self:LuaFnSendSpecificImpactToUnit(selfId,selfId,selfId,row.impact,0)
    return 1
end

function item:OnActivateEachTick() return 1 end
return item
