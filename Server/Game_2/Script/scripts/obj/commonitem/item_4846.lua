local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4846 = class("item_4846", script_base)
item_4846.script_id = 334846
item_4846.g_Impact = -1
item_4846.g_Key = {}

item_4846.g_Key["nul"] = 0
item_4846.g_Key["log"] = 1
item_4846.g_Key["bus"] = 2
item_4846.g_UseTim = {8, 13, 20, 30}

item_4846.g_Yinpiao = 40002000
item_4846.g_Impact_NotTransportList = {5929}

item_4846.g_TalkInfo_NotTransportList = {"#{GodFire_Info_062}"}

item_4846.g_LimitTransLevel = 75
function item_4846:OnDefaultEvent(selfId, bagIndex)
end

function item_4846:IsSkillLikeScript(selfId)
    return 1
end

function item_4846:CancelImpacts(selfId)
    return 0
end

function item_4846:OnConditionCheck(selfId)
    local bagId = self:LuaFnGetBagIndexOfUsedItem(selfId)
    if bagId < 0 then
        return 0
    end
    -- 额鬼倘江技能状态检测（impact 48824~48839）
    for impact_id = 48824, 48839 do
        if self:LuaFnHaveImpactOfSpecificDataIndex(selfId, impact_id) then
            self:MsgBox(selfId, "Trạng thái Ác Quỷ Đạp Giang không dùng định vị phù được!")
            return 0
        end
    end
    if self:IsHaveMission(selfId, 4021) then
        self:MsgBox(selfId, "Ngươi đang ở trong Trạng thái không cho phép truyền tống, không thể sử dụng định vị phù!")
        return 0
    end
    if self:GetItemCount(selfId, self.g_Yinpiao) >= 1 then
        self:MsgBox(selfId, "Ngươi đang ở Trạng thái chạy thương, không thể sử dụng định vị phù!")
        return 0
    end
    for i, ImpactId in pairs(self.g_Impact_NotTransportList) do
        if self:LuaFnHaveImpactOfSpecificDataIndex(selfId, ImpactId) then
            self:BeginEvent(self.script_id)
            self:AddText(self.g_TalkInfo_NotTransportList[i])
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            return 0
        end
    end
    local opx, opy
    opx = self:GetBagItemParam(selfId, bagId, 6, "ushort")
    opy = self:GetBagItemParam(selfId, bagId, 8, "ushort")
    local osid = self:GetBagItemParam(selfId, bagId, 4, "ushort")
    local sceneId = self:get_scene_id()
    if opx <= 0 and opy <= 0 then
        if
            sceneId ~= define.SCENE_ENUM.SCENE_DALI and sceneId ~= define.SCENE_ENUM.SCENE_LUOYANG and
                sceneId ~= define.SCENE_ENUM.SCENE_SUZHOU and
                sceneId ~= define.SCENE_ENUM.SCENE_LOULAN and sceneId ~= 1300 and sceneId ~= 1301 and sceneId ~= 1302
         then
            self:MsgBox(selfId, "Ngoài Tô Châu, Lạc Dương, Đại Lý, Lâu Lan ra, khôngCó thểKhác cảnh sử dụng Định Vị Phù!")
            return 0
        end
    else
        if (osid == define.SCENE_ENUM.SCENE_LOULAN) and (self:GetLevel(selfId) < self.g_LimitTransLevel) then
            local szMsg = string.format("Lâu LanYêu cầu cấp %d trở lên mớiCó thểvào trong", self.g_LimitTransLevel)
            self:MsgBox(selfId, szMsg)
            return 0
        end
    end
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4846:OnDeplete(selfId)
    return 1
end

function item_4846:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact, 0)
    end
    local bagId = self:LuaFnGetBagIndexOfUsedItem(selfId)
    local key, tim = self:OnUse(selfId)
    if key == self.g_Key["bus"] and tim <= 0 then
        if bagId >= 0 then
            self:EraseItem(selfId, bagId)
        end
    end
    return 1
end

function item_4846:OnActivateEachTick(selfId)
    return 1
end

function item_4846:OnUse(selfId)
    local bagId = self:LuaFnGetBagIndexOfUsedItem(selfId)
    if bagId < 0 then
        return self.g_Key["nul"]
    end
    if self:IsHaveMission(selfId, 4021) then
        self:MsgBox(selfId, "Ngươi đang ở trong Trạng thái không cho phép truyền tống, không thể sử dụng định vị phù!")
        return self.g_Key["nul"]
    end
    if self:GetItemCount(selfId, self.g_Yinpiao) >= 1 then
        self:MsgBox(selfId, "Ngươi đang ở Trạng thái chạy thương, không thể sử dụng định vị phù!")
        return self.g_Key["nul"]
    end
    for i, ImpactId in pairs(self.g_Impact_NotTransportList) do
        if self:LuaFnHaveImpactOfSpecificDataIndex(selfId, ImpactId) then
            self:BeginEvent(self.script_id)
            self:AddText(self.g_TalkInfo_NotTransportList[i])
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            return 0
        end
    end
    local oid = self:LuaFnGetItemTableIndexByIndex(selfId, bagId)
    local olev = self:GetCommonItemGrade(oid)
    local omax = self.g_UseTim[olev]
    local otim
    local osid
    local opx, opy
    otim = self:GetBagItemParam(selfId, bagId, 3, "uchar")
    osid = self:GetBagItemParam(selfId, bagId, 4, "ushort")
    opx = self:GetBagItemParam(selfId, bagId, 6, "ushort")
    opy = self:GetBagItemParam(selfId, bagId, 8, "ushort")
    local sceneId = self:get_scene_id()
    if opx > 0 and opy > 0 then
        if sceneId == osid then
            self:SetPos(selfId, opx, opy)
        else
            if (osid == define.SCENE_ENUM.SCENE_LOULAN) and (self:GetLevel(selfId) < self.g_LimitTransLevel) then
                local szMsg = string.format("Lâu LanYêu cầu cấp %d trở lên mớiCó thểvào trong", self.g_LimitTransLevel)
                self:MsgBox(selfId, szMsg)
                return self.g_Key["nul"]
            end
            if not self:IsCanNewWorld(selfId, osid, opx, opy) then
                return self.g_Key["nul"]
            end
            self:NewWorld(selfId, osid, nil, opx, opy)
        end
        self:SetBagItemParam(selfId, bagId, 3, (otim - 1), "uchar")
        self:LuaFnAuditGPS(selfId, 0)
        self:LuaFnRefreshItemInfo(selfId, bagId)
        return self.g_Key["bus"], (otim - 1)
    end
    print("sceneId =", sceneId)
    if
        sceneId ~= define.SCENE_ENUM.SCENE_DALI and sceneId ~= define.SCENE_ENUM.SCENE_LUOYANG and
            sceneId ~= define.SCENE_ENUM.SCENE_SUZHOU and
            sceneId ~= define.SCENE_ENUM.SCENE_LOULAN and sceneId ~= 1300 and sceneId ~= 1301 and sceneId ~= 1302
     then
        self:MsgBox(selfId, "Ngoài Tô Châu, Lạc Dương, Đại Lý, Lâu Lan ra, khôngCó thểKhác cảnh sử dụng Định Vị Phù!")
        return self.g_Key["nul"]
    end
    osid = sceneId
    opx, opy = self:LuaFnGetUnitPosition(selfId)
    opx = math.floor(opx)
    opy = math.floor(opy)
    self:SetBagItemParam(selfId, bagId, 0, 10, "ushort")
    self:SetBagItemParam(selfId, bagId, 2, omax, "ushort")
    self:SetBagItemParam(selfId, bagId, 3, omax, "uchar")
    self:SetBagItemParam(selfId, bagId, 4, osid, "uchar")
    self:SetBagItemParam(selfId, bagId, 6, opx, "ushort")
    self:SetBagItemParam(selfId, bagId, 8, opy, "ushort")
    self:LuaFnRefreshItemInfo(selfId, bagId)
    self:LuaFnAuditGPS(selfId, 1)
    return self.g_Key["log"]
end

function item_4846:MsgBox(selfId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return item_4846
