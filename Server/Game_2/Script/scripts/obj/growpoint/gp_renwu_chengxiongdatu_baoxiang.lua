local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local gp_renwu_chengxiongdatu_baoxiang = class("gp_renwu_chengxiongdatu_baoxiang", script_base)
gp_renwu_chengxiongdatu_baoxiang.g_MainItemId = 20103008
gp_renwu_chengxiongdatu_baoxiang.g_SubItemId = 50112003
gp_renwu_chengxiongdatu_baoxiang.g_MustHaveItemId = 20309009
function gp_renwu_chengxiongdatu_baoxiang:OnCreate(growPointType, x, y)
    local targetId = self:ItemBoxEnterScene(x, y, growPointType, define.QUALITY_MUST_BE_CHANGE, 1, self.g_MainItemId)
    if math.random(100) <= 80 then
        local ItemSn = self:GetItemSnByDropRateOfItemTable()
        self:AddItemToBox(targetId, define.QUALITY_MUST_BE_CHANGE, 1, ItemSn)
    end
end

function gp_renwu_chengxiongdatu_baoxiang:OnOpen(selfId, targetId)
    if self:HaveItem(selfId, self.g_MustHaveItemId) then
        local Bagpos = self:GetBagPosByItemSn(selfId, self.g_MustHaveItemId)
        if self:LuaFnIsItemAvailable(selfId, Bagpos) then
            return define.OPERATE_RESULT.OR_OK
        else
            self:Msg2Player(selfId, "Chìa khóa của Chủ Nhân Bảo Tàng hiện tại dường như không thể dùng được.", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
            self:BeginEvent(self.script_id)
            self:AddText("Chìa khóa của Chủ Nhân Bảo Tàng hiện tại dường như không thể dùng được.")
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            return define.OPERATE_RESULT.OR_ERROR
        end
    else
        self:BeginEvent(self.script_id)
        self:AddText("Yêu cầu chìa khóa của Chủ Nhân Bảo Tàng mới có thể mở")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return define.OPERATE_RESULT.OR_STUFF_LACK
    end
end

function gp_renwu_chengxiongdatu_baoxiang:OnProcOver(selfId, targetId)
    if self:LuaFnDelAvailableItem(selfId, self.g_MustHaveItemId, 1) then
        local BonusMoney = 114 + (self:GetLevel(selfId) - 20) * 16
        self:AddMoney(selfId, BonusMoney)
        self:Msg2Player(selfId, "Ngươi nhận được#{_MONEY" .. tostring(BonusMoney) .. "}", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    else
        self:Msg2Player(selfId, "Chìa khóa của Chủ Nhân Bảo Tàng hiện tại dường như không thể dùng được.", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        return define.OPERATE_RESULT.OR_ERROR
    end
    return define.OPERATE_RESULT.OR_OK
end

function gp_renwu_chengxiongdatu_baoxiang:OnRecycle(selfId, targetId)
    return define.OPERATE_RESULT.OR_OK
end

function gp_renwu_chengxiongdatu_baoxiang:OnTickCreateFinish(growPointType, tickCount)
end

return gp_renwu_chengxiongdatu_baoxiang
