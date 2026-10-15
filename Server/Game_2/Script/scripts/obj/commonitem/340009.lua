-- 武灵丹/武境丹 - 经验2倍（人物经验+武境经验，1小时）
-- 使用后给予BUFF 85，AddWuJingExp检测此BUFF乘算武境经验

local class = require "class"
local define = require "define"
local script_base = require "script_base"
local common_item = class("common_item", script_base)

local g_scriptId = 340009
local g_ItemId_1 = 38003625    -- 武灵丹
local g_ItemId_2 = 38003737    -- 武境丹
local g_BuffId = 85             -- 经验2倍 BUFF

function common_item:IsSkillLikeScript()
    return 0
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
    return self:LuaFnDepletingUsedItem(selfId)
end

function common_item:OnActivateOnce(selfId)
    return 1
end

function common_item:OnDefaultEvent(selfId, BagPos)
    -- 检查是否已有武境经验加成BUFF，存在则禁止重复使用
    if self:LuaFnHaveImpactOfSpecificDataIndex(selfId, g_BuffId) then
        self:notify_tips(selfId, "Bạn đang có hiệu ứng cộng kinh nghiệm võ cảnh, xin chờ hết rồi dùng.")
        return 0
    end
    return self:UseItem(selfId, BagPos)
end

function common_item:UseItem(selfId, BagPos)
    -- 验证物品
    local nItemId = self:GetItemTableIndexByIndex(selfId, BagPos)
    if nItemId ~= g_ItemId_1 and nItemId ~= g_ItemId_2 then
        self:notify_tips(selfId, "Lỗi bên trong túi")
        return 0
    end

    -- 消耗物品（单个）
    local ret = self:EraseItem(selfId, BagPos)
    if ret then
        -- 施加武境经验加成BUFF
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, g_BuffId, 100)
        self:notify_tips(selfId, "Bạn nhận 1 giờ cộng kinh nghiệm x2.")
    else
        self:notify_tips(selfId, "Vật phẩm không thể sử dụng")
        return 0
    end

    -- 刷新客户端
    self:LuaFnRefreshItemInfo(selfId, BagPos)
    return define.USEITEM_RESULT.USEITEM_SUCCESS
end

return common_item
