local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local obj_1 = class("obj_1", script_base)
obj_1.script_id = 331001
obj_1.g_Impact1 = 3003
obj_1.g_Impact2 = -1
obj_1.g_SpecailObj = 1
function obj_1:OnDefaultEvent(selfId, bagIndex) end
function obj_1:IsSkillLikeScript(selfId) return 1 end
function obj_1:CancelImpacts(selfId) return 0 end
function obj_1:OnConditionCheck(selfId)
    local ScriptGlobal = require "scripts.ScriptGlobal"
    if ScriptGlobal.is_internal_test then
        self:notify_tips(selfId, "Đang hoạt động test, không dùng được")
        return 0
    end
    return self:LuaFnVerifyUsedItem(selfId)
end

function obj_1:OnDeplete(selfId)
    local PlayerName = self:LuaFnGetName(selfId)
    local itemBagIndex = self:LuaFnGetBagIndexOfUsedItem(selfId)
    local szTransferItem = self:GetBagItemTransfer(selfId, itemBagIndex)
    local szSceneName = self:GetSceneName()
    if (self:LuaFnDepletingUsedItem(selfId)) then
        local message
        local randMessage = math.random(3)
        if randMessage == 1 then
            message = string.format(
                          "@*;SrvMsg;SCA:#{ManTian_00}#{_INFOUSR%s}#{ManTian_01}#G%s#cff0000#{ManTian_02}#{_INFOMSG%s}#{ManTian_03}",
                          gbk.fromutf8(PlayerName), gbk.fromutf8(szSceneName), szTransferItem)
        elseif randMessage == 2 then
            message = string.format(
                          "@*;SrvMsg;SCA:#{ManTian_04}#{_INFOUSR%s}#{ManTian_05}#G%s#cff0000#{ManTian_06}#{_INFOMSG%s}#{ManTian_07}#{_INFOUSR%s}#{ManTian_08}",
                          gbk.fromutf8(PlayerName), gbk.fromutf8(szSceneName), szTransferItem, gbk.fromutf8(PlayerName))
        else
            message = string.format(
                          "@*;SrvMsg;SCA:#{ManTian_09}#{_INFOUSR%s}#{ManTian_05}#G%s#cff0000#{ManTian_10}#{_INFOMSG%s}#{ManTian_11}#{_INFOMSG%s}#{ManTian_12}",
                          gbk.fromutf8(PlayerName), gbk.fromutf8(szSceneName), szTransferItem,
                          szTransferItem)
        end
        self:AddGlobalCountNews(message, true)
        return 1
    end
    return 0
end

function obj_1:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        local posX, posZ = self:GetWorldPos(selfId)
        self:CreateSpecialObjByDataIndex(selfId, self.g_SpecailObj, posX, posZ)
    end
    return 1
end

function obj_1:OnActivateEachTick(selfId) return 1 end

return obj_1
