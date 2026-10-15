local class = require "class"
local define = require "define"
local script_base = require "script_base"
local equiprepair = class("equiprepair", script_base)
equiprepair.g_NeedItemBonus = {
    {
        ["sqid01"] = 10300000,
        ["sqid02"] = 10302000,
        ["sqid03"] = 10304000,
        ["sqid04"] = 10305000,
        ["sfid"] = {
            30505800, 30505801, 30505802, 30505803, 30505804, 30505805, 30505806
        }
    }, {
        ["sqid01"] = 10300001,
        ["sqid02"] = 10302001,
        ["sqid03"] = 10304001,
        ["sqid04"] = 10305001,
        ["sfid"] = {30505801, 30505802, 30505803, 30505804, 30505805, 30505806}

    }, {
        ["sqid01"] = 10300002,
        ["sqid02"] = 10302002,
        ["sqid03"] = 10304002,
        ["sqid04"] = 10305002,
        ["sfid"] = {30505802, 30505803, 30505804, 30505805, 30505806}

    }, {
        ["sqid01"] = 10300003,
        ["sqid02"] = 10302003,
        ["sqid03"] = 10304003,
        ["sqid04"] = 10305003,
        ["sfid"] = {30505803, 30505804, 30505805, 30505806}

    }, {
        ["sqid01"] = 10300004,
        ["sqid02"] = 10302004,
        ["sqid03"] = 10304004,
        ["sqid04"] = 10305004,
        ["sfid"] = {30505804, 30505805, 30505806}

    }, {
        ["sqid01"] = 10300005,
        ["sqid02"] = 10302005,
        ["sqid03"] = 10304005,
        ["sqid04"] = 10305005,
        ["sfid"] = {30505805, 30505806}

    }, {
        ["sqid01"] = 10300100,
        ["sqid02"] = 10300100,
        ["sqid03"] = 10300100,
        ["sqid04"] = 10300100,
        ["sfid"] = {30505806}

    }, {
        ["sqid01"] = 10300101,
        ["sqid02"] = 10300101,
        ["sqid03"] = 10300101,
        ["sqid04"] = 10300101,
        ["sfid"] = {30505806}

    }, {
        ["sqid01"] = 10300102,
        ["sqid02"] = 10300102,
        ["sqid03"] = 10300102,
        ["sqid04"] = 10300102,
        ["sfid"] = {30505806}

    }, {
        ["sqid01"] = 10301100,
        ["sqid02"] = 10301100,
        ["sqid03"] = 10301100,
        ["sqid04"] = 10301100,
        ["sfid"] = {30505806}

    }, {
        ["sqid01"] = 10301101,
        ["sqid02"] = 10301101,
        ["sqid03"] = 10301101,
        ["sqid04"] = 10301101,
        ["sfid"] = {30505806}

    }, {
        ["sqid01"] = 10301102,
        ["sqid02"] = 10301102,
        ["sqid03"] = 10301102,
        ["sqid04"] = 10301102,
        ["sfid"] = {30505806}

    }, {
        ["sqid01"] = 10301200,
        ["sqid02"] = 10301200,
        ["sqid03"] = 10301200,
        ["sqid04"] = 10301200,
        ["sfid"] = {30505806}

    }, {
        ["sqid01"] = 10301201,
        ["sqid02"] = 10301201,
        ["sqid03"] = 10301201,
        ["sqid04"] = 10301201,
        ["sfid"] = {30505806}

    }, {
        ["sqid01"] = 10301202,
        ["sqid02"] = 10301202,
        ["sqid03"] = 10301202,
        ["sqid04"] = 10301202,
        ["sfid"] = {30505806}

    }, {
        ["sqid01"] = 10302100,
        ["sqid02"] = 10302100,
        ["sqid03"] = 10302100,
        ["sqid04"] = 10302100,
        ["sfid"] = {30505806}

    }, {
        ["sqid01"] = 10302101,
        ["sqid02"] = 10302101,
        ["sqid03"] = 10302101,
        ["sqid04"] = 10302101,
        ["sfid"] = {30505806}

    }, {
        ["sqid01"] = 10302102,
        ["sqid02"] = 10302102,
        ["sqid03"] = 10302102,
        ["sqid04"] = 10302102,
        ["sfid"] = {30505806}

    }, {
        ["sqid01"] = 10303100,
        ["sqid02"] = 10303100,
        ["sqid03"] = 10303100,
        ["sqid04"] = 10303100,
        ["sfid"] = {30505806}

    }, {
        ["sqid01"] = 10303101,
        ["sqid02"] = 10303101,
        ["sqid03"] = 10303101,
        ["sqid04"] = 10303101,
        ["sfid"] = {30505806}

    }, {
        ["sqid01"] = 10303102,
        ["sqid02"] = 10303102,
        ["sqid03"] = 10303102,
        ["sqid04"] = 10303102,
        ["sfid"] = {30505806}

    }, {
        ["sqid01"] = 10303200,
        ["sqid02"] = 10303200,
        ["sqid03"] = 10303200,
        ["sqid04"] = 10303200,
        ["sfid"] = {30505806}

    }, {
        ["sqid01"] = 10303201,
        ["sqid02"] = 10303201,
        ["sqid03"] = 10303201,
        ["sqid04"] = 10303201,
        ["sfid"] = {30505806}

    }, {
        ["sqid01"] = 10303202,
        ["sqid02"] = 10303202,
        ["sqid03"] = 10303202,
        ["sqid04"] = 10303202,
        ["sfid"] = {30505806}

    }, {
        ["sqid01"] = 10304100,
        ["sqid02"] = 10304100,
        ["sqid03"] = 10304100,
        ["sqid04"] = 10304100,
        ["sfid"] = {30505806}

    }, {
        ["sqid01"] = 10304101,
        ["sqid02"] = 10304101,
        ["sqid03"] = 10304101,
        ["sqid04"] = 10304101,
        ["sfid"] = {30505806}

    }, {
        ["sqid01"] = 10304102,
        ["sqid02"] = 10304102,
        ["sqid03"] = 10304102,
        ["sqid04"] = 10304102,
        ["sfid"] = {30505806}

    }, {
        ["sqid01"] = 10305100,
        ["sqid02"] = 10305100,
        ["sqid03"] = 10305100,
        ["sqid04"] = 10305100,
        ["sfid"] = {30505806}

    }, {
        ["sqid01"] = 10305101,
        ["sqid02"] = 10305101,
        ["sqid03"] = 10305101,
        ["sqid04"] = 10305101,
        ["sfid"] = {30505806}

    }, {
        ["sqid01"] = 10305102,
        ["sqid02"] = 10305102,
        ["sqid03"] = 10305102,
        ["sqid04"] = 10305102,
        ["sfid"] = {30505806}

    }, {
        ["sqid01"] = 10305200,
        ["sqid02"] = 10305200,
        ["sqid03"] = 10305200,
        ["sqid04"] = 10305200,
        ["sfid"] = {30505806}

    }, {
        ["sqid01"] = 10305201,
        ["sqid02"] = 10305201,
        ["sqid03"] = 10305201,
        ["sqid04"] = 10305201,
        ["sfid"] = {30505806}

    }, {
        ["sqid01"] = 10305202,
        ["sqid02"] = 10305202,
        ["sqid03"] = 10305202,
        ["sqid04"] = 10305202,
        ["sfid"] = {30505806}

    }
}
equiprepair.g_SHENQI_BEGIN = 10300000
equiprepair.g_SHENQI_END = 10399999
equiprepair.g_ZHUCAI_INDEX = 0
equiprepair.g_Impact_Complete_Repair = 150
equiprepair.g_ShenCaiCount = 1
function equiprepair:OnEquipRepairofEquip(selfId, itemId)
    local price
    local cailiaoList = 0
    local cailiaoID = 1
    local ItemIndex = self:LuaFnGetItemTableIndexByIndex(selfId, itemId)
    if ItemIndex >= self.g_SHENQI_BEGIN and ItemIndex <= self.g_SHENQI_END then
        price = 0
        for i, item in pairs(self.g_NeedItemBonus) do
            if ItemIndex == item["sqid01"] or ItemIndex == item["sqid02"] or
                ItemIndex == item["sqid03"] or ItemIndex == item["sqid04"] then
                cailiaoList = item["sfid"]
                break
            end
        end
        if cailiaoList ~= 0 then
            for j, cailiao in pairs(cailiaoList) do
                if self:LuaFnGetAvailableItemCount(selfId, cailiao) > 0 then
                    cailiaoID = cailiao
                    break
                end
            end
        end
        self.g_ZHUCAI_INDEX = cailiaoID
        local ItemCount = self:LuaFnGetAvailableItemCount(selfId, cailiaoID)
    else
        self.g_ZHUCAI_INDEX = 0
        price = self:GetHighRepairPrice(selfId, itemId)
    end
    if price < 0 then
        self:BeginEvent(self.script_id)
        self:AddText("Trang bị Cấp độ Thông tin của ngài bị lỗi, hiện không thể sửa chữa.")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return
    end
    local ret = self:DoHighRepair(selfId, itemId, price)
    if ret == -1 then
        self:BeginEvent(self.script_id)
        self:AddText("Trang bị này không thể sửa chữa thêm nữa.")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        self:Msg2Player(selfId, "Trang bị này không thể sửa chữa thêm nữa.", 8)
    elseif ret == -2 then
        self:BeginEvent(self.script_id)
        self:AddText("Ngân lượng của ngươi không đủ chi trả phí sửa chữa.")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        self:Msg2Player(selfId, "#RBạc của ngươi không đủ để chi trả phí sửa chữa.", 8)
    elseif ret == -4 then
        self:BeginEvent(self.script_id)
        self:AddText("Sửa chữa thất bại, Số lần sửa chữa Trang bị của ngài giảm 1.")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        self:Msg2Player(selfId,"Sửa chữa thất bại, Số lần sửa chữa Trang bị của ngài #R－1.", 8)
    elseif ret == -5 then
        self:BeginEvent(self.script_id)
        self:AddText("Trong quá trình sửa chữa xuất hiện lỗi không xác định.")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        self:Msg2Player(selfId, "Trong quá trình sửa chữa xuất hiện lỗi không xác định.", 8)
    elseif ret == -6 then
        self:BeginEvent(self.script_id)
        self:AddText("Vật phẩm không hề hư hại, không cần sửa chữa.")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        self:Msg2Player(selfId, "Vật phẩm không hề hư hại, không cần sửa chữa.", 8)
    elseif ret == 0 then
        if self.g_ZHUCAI_INDEX ~= 0 then
            local bagbegin = self:GetBasicBagStartPos(selfId)
            local bagend = self:GetBasicBagEndPos(selfId)
            local ItemEX
            local scbagpos = -1
            for i = bagbegin, bagend do
                if self:LuaFnIsItemAvailable(selfId, i) then
                    ItemEX = self:LuaFnGetItemTableIndexByIndex(selfId, i)
                    if ItemEX == self.g_ZHUCAI_INDEX then
                        scbagpos = i
                        break
                    end
                end
            end
        end
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId,self.g_Impact_Complete_Repair, 0)
        self:BeginEvent(self.script_id)
        self:AddText("Sửa chữa thành công.")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        self:Msg2Player(selfId, "#GSửa chữa thành công.", 8)
    end
end

function equiprepair:OnEquipRepair(selfId, type, _, EquipPos, MaterialPos)
    local ret = self:DoShenQiRepaire(selfId, EquipPos, MaterialPos)
    if ret == -5 then
        self:BeginEvent(self.script_id)
        self:AddText("Trong quá trình sửa chữa xuất hiện lỗi không xác định.")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        self:Msg2Player(selfId, "Trong quá trình sửa chữa xuất hiện lỗi không xác định.", 8)
    elseif ret == -6 then
        self:BeginEvent(self.script_id)
        self:AddText("Vật phẩm không hề hư hại, không cần sửa chữa.")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        self:Msg2Player(selfId, "Vật phẩm không hề hư hại, không cần sửa chữa.", 8)
    elseif ret == 0 then
        self:LuaFnDecItemLayCount(selfId, MaterialPos, 1)
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId,self.g_Impact_Complete_Repair, 0)
        self:BeginEvent(self.script_id)
        self:AddText("Sửa chữa thành công.")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        self:Msg2Player(selfId, "#GSửa chữa thành công.", 8)
    end
end

function equiprepair:CalRepairPrice(selfId, itemId, targetId)
    local price = self:GetHighRepairPrice(selfId, itemId)
    if price < 0 then price = 0 end
    self:BeginUICommand()
    self:UICommand_AddInt(targetId)
    self:UICommand_AddInt(price)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 19810313)
end

return equiprepair