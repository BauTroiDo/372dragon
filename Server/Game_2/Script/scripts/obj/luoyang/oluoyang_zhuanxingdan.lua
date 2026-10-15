local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_zhuanxingdan = class("oluoyang_zhuanxingdan", script_base)
oluoyang_zhuanxingdan.script_id = 000147
oluoyang_zhuanxingdan.g_eventList = {
    0147000, 0147001, 0147002, 0147003, 0147004, 0147005, 0147006
}

oluoyang_zhuanxingdan.g_item_zhuanxingdan = 30900048
oluoyang_zhuanxingdan.g_result_msg = {
    "#{ZXD_20080312_03}", "#{ZXD_20080318_01}", "#{ZXD_20080318_02}",
    "#{ZXD_20080318_03}", "#{ZXD_20080318_04}", "#{ZXD_20080318_05}"
}

function oluoyang_zhuanxingdan:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{ZXD_20080312_01}")
    self:AddNumText("#{ZXD_20080318_06}", 6, 0147000)
    self:AddNumText("#{ZXD_20080318_07}", 11, 0147001)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_zhuanxingdan:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oluoyang_zhuanxingdan:OnEventRequest(selfId, targetId, arg, index)
    local request_id = index
    print("function x000147_OnEventRequest")
    if request_id == 0147000 then
        local isMarried = self:LuaFnIsMarried(selfId)
        if isMarried then
            self:BeginEvent(self.script_id)
            self:AddText("#{ZXD_20080312_03}")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end
        local itemCount = self:LuaFnGetAvailableItemCount(selfId,
                                                    self.g_item_zhuanxingdan)
        if itemCount < 1 then
            self:BeginEvent(self.script_id)
            self:AddText("#{ZXD_20080312_04}")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 0147000)
    elseif request_id == 0147003 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 0147005)
    elseif request_id == 0147004 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 0147006)
    elseif request_id == 0147001 then
        self:BeginEvent(self.script_id)
        self:AddText("#{ZXD_20080312_02}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

function oluoyang_zhuanxingdan:OnZhuanXingRequest(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{ZXD_20080312_05}")
    self:AddNumText("là", 6, 0147003)
    self:AddNumText("không", 6, 0147004)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_zhuanxingdan:OnZhuanXingConfirm(selfId, targetId, sex,
                                                  hairColor, hairModel,
                                                  faceModel, nFaceId)
    print("x000147_OnZhuanXingConfirm")
    local pre_condition = self:PreZhuanXingCondition(selfId, targetId)
    if pre_condition == 0 then
		self:LuaFnDelAvailableItem(selfId, self.g_item_zhuanxingdan, 1)
        local is_suc = self:HumanZhuanXing(selfId, sex, hairColor, hairModel, faceModel, nFaceId)
        if is_suc then
            -- self:LuaFnDelAvailableItem(selfId, self.g_item_zhuanxingdan, 1)
            self:BeginEvent(self.script_id)
            self:AddText("#{ZXD_20080312_06}")
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 100)
            return
        end
    elseif (pre_condition >= 1 and pre_condition <= 6) then
        self:BeginEvent(self.script_id)
        self:AddText(self.g_result_msg[pre_condition])
        self:EndEvent()
        self:DispatchMissionTips(selfId)
    end
end

function oluoyang_zhuanxingdan:PreZhuanXingCondition(selfId, targetId)
    local isMarried = self:LuaFnIsMarried(selfId)
    if isMarried == 1 then return 1 end
    local isValidDistance = self:IsInDist(selfId, targetId, 1000.0)
    if not isValidDistance then return 2 end
    local itemCount = self:LuaFnGetAvailableItemCount(selfId,
                                                      self.g_item_zhuanxingdan)
    if itemCount <= 0 then return 3 end
    local hasTeam = self:LuaFnHasTeam(selfId)
    if hasTeam then return 4 end
    local isStall = self:LuaFnIsStalling(selfId)
    if isStall then return 5 end
    local isRiding = self:LuaFnIsRiding(selfId)
    if isRiding then return 6 end
    return 0
end

return oluoyang_zhuanxingdan
