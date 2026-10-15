local class = require "class"
local define = require "define"
local script_base = require "script_base"
local tank = class("tank", script_base)
tank.script_id = 402302
tank.g_eventId_yes = 0
tank.g_eventId_no = 1
tank.g_A_TankID = {13339, 13340, 13341, 13342, 13343}
tank.g_B_TankID = {13334, 13335, 13336, 13337, 13338}

function tank:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function tank:UpdateEventList(selfId, targetId)
    local isAguild = self:CallScriptFunction(402047, "IsCommonAGuild", selfId)
    local DataId = self:GetMonsterDataID(targetId)
    local isNPCAguild = 0
    for j = 1, #(self.g_A_TankID) do
        if DataId == self.g_A_TankID[j] then
            isNPCAguild = 1
            break
        end
    end
    for j = 1, #(self.g_B_TankID) do
        if DataId == self.g_B_TankID[j] then
            isNPCAguild = 0
            break
        end
    end
    if isAguild == isNPCAguild then
        self:BeginEvent(self.script_id)
        self:AddText("#{BHXZ_081103_89}")
        self:AddNumText("Xác nhận", 9, self.g_eventId_yes)
        self:AddNumText("Hủy bỏ", 8, self.g_eventId_no)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    else
        self:BeginEvent(self.script_id)
        self:AddText("#{BHXZ_081103_90}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

function tank:OnEventRequest(selfId, targetId, arg, index)
    local selectEventId = index
    local isAguild = self:CallScriptFunction(402047, "IsCommonAGuild", selfId)
    local DataId = self:GetMonsterDataID(targetId)
    local isNPCAguild = 0
    local index = -1
    local base = 0
    for j = 1, #(self.g_A_TankID) do
        if DataId == self.g_A_TankID[j] then
            isNPCAguild = 1
            index = j
            base = 5
            break
        end
    end
    for j = 1, #(self.g_B_TankID) do
        if DataId == self.g_B_TankID[j] then
            isNPCAguild = 0
            index = j
            base = 0
            break
        end
    end
    if isAguild ~= isNPCAguild or index == -1 then
        return
    end
    if selectEventId == self.g_eventId_yes then
        local ret = self:CallScriptFunction(600051, "PowerUptank", selfId, targetId, index + base, isAguild, 0)
        if ret == 1 then
            self:LuaFnDeleteMonster(targetId)
        end
    else
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
    end
end

function tank:OnMissionAccept(selfId, targetId, missionScriptId)
end

function tank:OnMissionRefuse(selfId, targetId, missionScriptId)
end

return tank
