local class = require "class"
local define = require "define"
local script_base = require "script_base"
local edali_0233 = class("edali_0233", script_base)
edali_0233.script_id = 210233
edali_0233.g_Position_X = 160.4355
edali_0233.g_Position_Z = 127.9695
edali_0233.g_SceneID = 2
edali_0233.g_AccomplishNPC_Name = "李工部"
edali_0233.g_MissionId = 713
edali_0233.g_Name = "李工部"
edali_0233.g_MissionKind = 13
edali_0233.g_MissionLevel = 2
edali_0233.g_IfMissionElite = 0
edali_0233.g_IsMissionOkFail = 0
edali_0233.g_DemandItem = {
    { ["id"] = 20309001, ["num"] = 1 }, { ["id"] = 20309005, ["num"] = 1 }

}
edali_0233.g_MissionName = "Mũ Dệt Tinh Ngự Tứ"
edali_0233.g_MissionInfo = "#{event_dali_0046}"
edali_0233.g_MissionTarget = "Tìm Nhất phẩm nhu mễ và Nhất phẩm hồng đậu, rồi quay về #GĐại Lý thành Ngũ Hoa Đàn#W tìm #RLý Công Bộ#W#{_INFOAIM160,128,2,Lý Công Bộ}, một trong Tứ Đại Thiện Nhân."
edali_0233.g_ContinueInfo = "  Nhất Phẩm Nếp và Nhất Phẩm Đậu Đỏ ngươi đã tìm được rồi ư?"
edali_0233.g_MissionComplete = "  Hậu sinh khả úy, làm rất tốt."
edali_0233.g_ItemBonus = { { ["id"] = 10410047, ["num"] = 1 } }
function edali_0233:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText(self.g_MissionInfo)
    for i, item in pairs(self.g_DemandItem) do
        self:AddItemDemand(item["id"], item["num"])
    end
    self:EndEvent()
    local bDone = self:CheckSubmit(selfId)
    self:DispatchMissionDemandInfo(selfId, targetId, self.script_id, self.g_MissionId, bDone)
end

function edali_0233:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:IsMissionHaveDone(selfId, self.g_MissionId) then
        return
    elseif self:CheckAccept(selfId) > 0 then
        caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 1, -1)
    end
end

function edali_0233:CheckAccept(selfId) return 1 end

function edali_0233:OnAccept(selfId) end

function edali_0233:OnAbandon(selfId) self:DelMission(selfId, self.g_MissionId) end

function edali_0233:OnContinue(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText(self.g_MissionComplete)
    for i, item in pairs(self.g_ItemBonus) do
        self:AddItemBonus(item["id"], item["num"])
    end
    self:EndEvent()
    self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end

function edali_0233:CheckSubmit(selfId)
    if self:IsMissionHaveDone(selfId, self.g_MissionId) then return 0 end
    for i, item in pairs(self.g_DemandItem) do
        local itemCount = self:GetItemCount(selfId, item["id"])
        if itemCount < item["num"] then return 0 end
    end
    return 1
end

function edali_0233:OnSubmit(selfId, targetId, selectRadioId)
    if self:CheckSubmit(selfId) == 1 then
        self:BeginAddItem()
        for i, item in pairs(self.g_ItemBonus) do
            self:AddItem(item["id"], item["num"])
        end
        local ret = self:EndAddItem(selfId)
        if ret then
            for i, item in pairs(self.g_DemandItem) do
                ret = self:DelItem(selfId, item["id"], item["num"])
            end
            if ret then
                ret = self:DelMission(selfId, self.g_MissionId)
                if ret then
                    self:MissionCom(selfId, self.g_MissionId)
                    self:AddItemListToHuman(selfId)
                    self:Msg2Player(selfId, "#Yhoàn thành nhiệm vụ: Ngự Tứ Tinh Phường Mạo", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
                end
            else
                self:BeginEvent(self.script_id)
                local strText = "Không thể hoàn thành nhiệm vụ"
                self:AddText(strText)
                self:EndEvent()
                self:DispatchMissionTips(selfId)
            end
        else
            self:BeginEvent(self.script_id)
            local strText = "Túi đã đầy, không thể hoàn thành nhiệm vụ"
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
        end
    end
end

function edali_0233:OnKillObject(selfId, objdataId, objId) end

function edali_0233:OnEnterArea(selfId, zoneId) end

function edali_0233:OnItemChanged(selfId, itemdataId) end

return edali_0233
