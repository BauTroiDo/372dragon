local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ouyezi_ShenQiChongZhu = class("ouyezi_ShenQiChongZhu", script_base)
ouyezi_ShenQiChongZhu.script_id = 500504
ouyezi_ShenQiChongZhu.g_Name = "欧冶子"
ouyezi_ShenQiChongZhu.g_ControlScript = 001066
ouyezi_ShenQiChongZhu.g_MissionId = 420
ouyezi_ShenQiChongZhu.g_EventList = {}

ouyezi_ShenQiChongZhu.g_ChongXinYeLianInfo = "Trùng luyện Thần Khí"
ouyezi_ShenQiChongZhu.g_Impact_ShenQi = 47
ouyezi_ShenQiChongZhu.g_ItemBonus = {
    {["id"] = 30505700, ["num"] = 1, ["sqlvl"] = 42},
    {["id"] = 30505701, ["num"] = 1, ["sqlvl"] = 52},
    {["id"] = 30505702, ["num"] = 1, ["sqlvl"] = 62},
    {["id"] = 30505703, ["num"] = 1, ["sqlvl"] = 72},
    {["id"] = 30505704, ["num"] = 1, ["sqlvl"] = 82},
    {["id"] = 30505705, ["num"] = 1, ["sqlvl"] = 92}
}

ouyezi_ShenQiChongZhu.g_Item_ShenQi = {
    {
        ["id01"] = 10300000,
        ["id02"] = 10300001,
        ["id03"] = 10300002,
        ["id04"] = 10300003,
        ["id05"] = 10300004,
        ["id06"] = 10300005
    }, {
        ["id01"] = 10302000,
        ["id02"] = 10302001,
        ["id03"] = 10302002,
        ["id04"] = 10302003,
        ["id05"] = 10302004,
        ["id06"] = 10302005
    }, {
        ["id01"] = 10304000,
        ["id02"] = 10304001,
        ["id03"] = 10304002,
        ["id04"] = 10304003,
        ["id05"] = 10304004,
        ["id06"] = 10304005
    }, {
        ["id01"] = 10305000,
        ["id02"] = 10305001,
        ["id03"] = 10305002,
        ["id04"] = 10305003,
        ["id05"] = 10305004,
        ["id06"] = 10305005
    }
}

function ouyezi_ShenQiChongZhu:OnDefaultEvent(selfId, targetId, arg, index)
    if self:LuaFnGetName(targetId) ~= self.g_Name then
        self:NotifyTip(selfId, "Trùng đúc Thần khí thất bại")
        self:MissionLog(
            "[ShenBing]error: x500504_OnDefaultEvent..LuaFnGetName=" ..
                self:LuaFnGetName(targetId))
        return 0
    end
    local key = index
    if key == 116 then
        self:BeginEvent(self.script_id)
        self:AddText("#{CXYL_20071011}")
        self:AddNumText("#{INTERFACE_XML_1001}", 6, 136)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif key == 135 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:UICommand_AddInt(-1)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 101526358)
    elseif key == 136 then
        self:BeginEvent(self.script_id)
        self:AddText(self.g_ChongXinYeLianInfo)
        self:AddText("#{XYSB_20070928_005}")
        self:EndEvent()
        local bDone = 2
        self:DispatchMissionDemandInfo(selfId, targetId, self.script_id,
                                       self.g_MissionId, bDone)
    end
end

function ouyezi_ShenQiChongZhu:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:LuaFnGetName(targetId) ~= self.g_Name then return 0 end
    caller:AddNumTextWithTarget(self.script_id, self.g_ChongXinYeLianInfo, 6, 116)
    caller:AddNumTextWithTarget(self.script_id, "#{INTERFACE_XML_1004}", 6, 135)
end

function ouyezi_ShenQiChongZhu:NotifyTip(selfId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function ouyezi_ShenQiChongZhu:ChongXinYeLian(selfId, targetId, ItemID, bagpos)
    if self:LuaFnGetName(targetId) ~= self.g_Name then
        self:NotifyTip(selfId, "Nấu lại Thần khí thất bại")
        self:MissionLog(
            "[ShenBing]error: x500504_ChongXinYeLian..LuaFnGetName=" ..
                self:LuaFnGetName(targetId))
        return 0
    end
    if ItemID == self.g_Item_ShenQi[1]["id06"] or ItemID ==
        self.g_Item_ShenQi[2]["id06"] or ItemID == self.g_Item_ShenQi[3]["id06"] or
        ItemID == self.g_Item_ShenQi[4]["id06"] then
        self:NotifyTip(selfId, "#{XYSB_20070928_004}")
        return 0
    else
        local ItemBonusID = 0
        if ItemID == self.g_Item_ShenQi[1]["id01"] or ItemID ==
            self.g_Item_ShenQi[2]["id01"] or ItemID ==
            self.g_Item_ShenQi[3]["id01"] or ItemID ==
            self.g_Item_ShenQi[4]["id01"] then
            ItemBonusID = self.g_ItemBonus[2]["id"]
        elseif ItemID == self.g_Item_ShenQi[1]["id02"] or ItemID ==
            self.g_Item_ShenQi[2]["id02"] or ItemID ==
            self.g_Item_ShenQi[3]["id02"] or ItemID ==
            self.g_Item_ShenQi[4]["id02"] then
            ItemBonusID = self.g_ItemBonus[3]["id"]
        elseif ItemID == self.g_Item_ShenQi[1]["id03"] or ItemID ==
            self.g_Item_ShenQi[2]["id03"] or ItemID ==
            self.g_Item_ShenQi[3]["id03"] or ItemID ==
            self.g_Item_ShenQi[4]["id03"] then
            ItemBonusID = self.g_ItemBonus[4]["id"]
        elseif ItemID == self.g_Item_ShenQi[1]["id04"] or ItemID ==
            self.g_Item_ShenQi[2]["id04"] or ItemID ==
            self.g_Item_ShenQi[3]["id04"] or ItemID ==
            self.g_Item_ShenQi[4]["id04"] then
            ItemBonusID = self.g_ItemBonus[5]["id"]
        elseif ItemID == self.g_Item_ShenQi[1]["id05"] or ItemID ==
            self.g_Item_ShenQi[2]["id05"] or ItemID ==
            self.g_Item_ShenQi[3]["id05"] or ItemID ==
            self.g_Item_ShenQi[4]["id05"] then
            ItemBonusID = self.g_ItemBonus[6]["id"]
        end
        self:BeginAddItem()
        self:AddItem(ItemBonusID, 1)
        local ret = self:EndAddItem(selfId)
        if ret then
            self:TryRecieveItem(selfId, ItemBonusID, 1)
            local strMsg = "Ngươi nhận được" .. "#{_ITEM" .. (ItemBonusID) .. "}"
            self:NotifyTip(selfId, strMsg)
            local LogInfo = string.format(
                                "[ShenBing]Succeed: x500504_ChongXinYeLian( sceneId=%d, GUID=%0X ), ItemBonusID=%d",
                                self:LuaFnObjId2Guid(selfId), ItemBonusID)
            self:MissionLog(LogInfo)
            self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId,
                                               self.g_Impact_ShenQi, 0)
            local EraseRet = self:EraseItem(selfId, bagpos)
            if not EraseRet then
                strMsg = "Xóa Vũ khí thất bại"
                self:NotifyTip(selfId, strMsg)
                return 0
            end
            return 1
        end
        self:MissionLog("[ShenBing]error: x500504_ChongXinYeLian..ret=" .. ret)
        return 0
    end
end

function ouyezi_ShenQiChongZhu:OnMissionCheck(selfId, npcid, scriptId, index1,
                                              index2, index3, petindex)
    local LogInfo = string.format(
                        "[ShenBing]: x500504_OnMissionCheck( sceneId=%d, GUID=%0X ), index1=%d, index2=%d, index3=%d, petindex=%d",
                        self:LuaFnObjId2Guid(selfId), index1, index2, index3,
                        petindex)
    self:MissionLog(LogInfo)
    if index1 >= 100 then
        self:NotifyTip(selfId, "#{XYSB_20070928_006}")
        return 0
    end
    if self:LuaFnGetName(npcid) ~= self.g_Name then
        self:NotifyTip(selfId, "Nấu lại Thần khí thất bại")
        self:MissionLog(
            "[ShenBing]error: x500504_OnMissionCheck..LuaFnGetName=" ..
                self:LuaFnGetName(npcid))
        return 0
    end
    local index
    local ItemID
    ItemID = self:LuaFnGetItemTableIndexByIndex(selfId, index1)
    if ItemID == 10300100 or ItemID == 10300101 or ItemID == 10300102 or ItemID ==
        10301100 or ItemID == 10301101 or ItemID == 10301102 or ItemID ==
        10301200 or ItemID == 10301201 or ItemID == 10301202 or ItemID ==
        10302100 or ItemID == 10302101 or ItemID == 10302102 or ItemID ==
        10303100 or ItemID == 10303101 or ItemID == 10303102 or ItemID ==
        10303200 or ItemID == 10303201 or ItemID == 10303202 or ItemID ==
        10304100 or ItemID == 10304101 or ItemID == 10304102 or ItemID ==
        10305100 or ItemID == 10305101 or ItemID == 10305102 or ItemID ==
        10305200 or ItemID == 10305201 or ItemID == 10305202 then
        self:NotifyTip(selfId, "Thần khí cấp 102 không thể trùng đúc")
        return 0
    end
    for i = 1, 3 do
        if i == 1 then
            index = index1
        elseif i == 2 then
            index = index2
        elseif i == 3 then
            index = index3
        else
            index = index1
        end
        if index < 100 then
            ItemID = self:LuaFnGetItemTableIndexByIndex(selfId, index)
            if not self:LuaFnIsItemAvailable(selfId, index) then
                self:NotifyTip(selfId, "#{XYSB_20070928_019}")
                return 0
            end
            if (ItemID >= self.g_Item_ShenQi[1]["id01"] and ItemID <=
                self.g_Item_ShenQi[1]["id06"]) or
                (ItemID >= self.g_Item_ShenQi[2]["id01"] and ItemID <=
                    self.g_Item_ShenQi[2]["id06"]) or
                (ItemID >= self.g_Item_ShenQi[3]["id01"] and ItemID <=
                    self.g_Item_ShenQi[3]["id06"]) or
                (ItemID >= self.g_Item_ShenQi[4]["id01"] and ItemID <=
                    self.g_Item_ShenQi[4]["id06"]) then
                local yelianres = self:ChongXinYeLian(selfId, npcid, ItemID,
                                                      index)
                if yelianres == 0 then
                    self:MissionLog(
                        "[ShenBing]error: x500504_OnMissionCheck..index..yelianres=" ..
                            yelianres)
                    return 0
                end
                return 1
            end
        end
    end
    self:NotifyTip(selfId, "#{XYSB_20070928_006}")
    return 0
end

return ouyezi_ShenQiChongZhu
