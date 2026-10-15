local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_zhugekongliang = class("oluoyang_zhugekongliang", script_base)
oluoyang_zhugekongliang.script_id = 000077
oluoyang_zhugekongliang.g_ControlScript = 050026
oluoyang_zhugekongliang.g_ChangeLst = {
    -- [1] = {["id"] = 50401002, ["NeedItm"] = 30501249, ["NeedNum"] = 72},
    -- [2] = {["id"] = 50401001, ["NeedItm"] = 30501258, ["NeedNum"] = 72},
    -- [3] = {["id"] = 50403001, ["NeedItm"] = 30501267, ["NeedNum"] = 72},
    -- [4] = {["id"] = 50414001, ["NeedItm"] = 30501276, ["NeedNum"] = 72},
    -- [5] = {["id"] = 50402006, ["NeedItm"] = 30501294, ["NeedNum"] = 72},
    -- [6] = {["id"] = 50402007, ["NeedItm"] = 30501285, ["NeedNum"] = 72},
    -- [7] = {["id"] = 50402005, ["NeedItm"] = 30501303, ["NeedNum"] = 72},
    -- [8] = {["id"] = 50402008, ["NeedItm"] = 30501312, ["NeedNum"] = 72},
    -- [9] = {["id"] = 50413006, ["NeedItm"] = 30501340, ["NeedNum"] = 72},
    -- [10] = {["id"] = 50413004, ["NeedItm"] = 30501349, ["NeedNum"] = 72},
    -- [11] = {["id"] = 50501002, ["NeedItm"] = 30501250, ["NeedNum"] = 72},
    -- [12] = {["id"] = 50501001, ["NeedItm"] = 30501259, ["NeedNum"] = 72},
    -- [13] = {["id"] = 50503001, ["NeedItm"] = 30501268, ["NeedNum"] = 72},
    -- [14] = {["id"] = 50514001, ["NeedItm"] = 30501277, ["NeedNum"] = 72},
    -- [15] = {["id"] = 50502006, ["NeedItm"] = 30501295, ["NeedNum"] = 72},
    -- [16] = {["id"] = 50502007, ["NeedItm"] = 30501286, ["NeedNum"] = 72},
    -- [17] = {["id"] = 50502005, ["NeedItm"] = 30501304, ["NeedNum"] = 72},
    -- [18] = {["id"] = 50502008, ["NeedItm"] = 30501313, ["NeedNum"] = 72},
    -- [19] = {["id"] = 50513006, ["NeedItm"] = 30501341, ["NeedNum"] = 72},
    -- [20] = {["id"] = 50513004, ["NeedItm"] = 30501350, ["NeedNum"] = 72},
    -- [21] = {["id"] = 50601002, ["NeedItm"] = 30501251, ["NeedNum"] = 72},
    -- [22] = {["id"] = 50601001, ["NeedItm"] = 30501260, ["NeedNum"] = 72},
    -- [23] = {["id"] = 50603001, ["NeedItm"] = 30501269, ["NeedNum"] = 72},
    -- [24] = {["id"] = 50614001, ["NeedItm"] = 30501278, ["NeedNum"] = 72},
    -- [25] = {["id"] = 50602006, ["NeedItm"] = 30501296, ["NeedNum"] = 72},
    -- [26] = {["id"] = 50602007, ["NeedItm"] = 30501287, ["NeedNum"] = 72},
    -- [27] = {["id"] = 50602005, ["NeedItm"] = 30501305, ["NeedNum"] = 72},
    -- [28] = {["id"] = 50602008, ["NeedItm"] = 30501314, ["NeedNum"] = 72},
    -- [29] = {["id"] = 50613006, ["NeedItm"] = 30501342, ["NeedNum"] = 72},
    -- [30] = {["id"] = 50613004, ["NeedItm"] = 30501351, ["NeedNum"] = 72},
    -- [31] = {["id"] = 50701002, ["NeedItm"] = 30501252, ["NeedNum"] = 72},
    -- [32] = {["id"] = 50701001, ["NeedItm"] = 30501261, ["NeedNum"] = 72},
    -- [33] = {["id"] = 50703001, ["NeedItm"] = 30501270, ["NeedNum"] = 72},
    -- [34] = {["id"] = 50714001, ["NeedItm"] = 30501279, ["NeedNum"] = 72},
    -- [35] = {["id"] = 50702006, ["NeedItm"] = 30501297, ["NeedNum"] = 72},
    -- [36] = {["id"] = 50702007, ["NeedItm"] = 30501288, ["NeedNum"] = 72},
    -- [37] = {["id"] = 50702005, ["NeedItm"] = 30501306, ["NeedNum"] = 72},
    -- [38] = {["id"] = 50702008, ["NeedItm"] = 30501315, ["NeedNum"] = 72},
    -- [39] = {["id"] = 50713006, ["NeedItm"] = 30501325, ["NeedNum"] = 72},
    -- [40] = {["id"] = 50713004, ["NeedItm"] = 30501334, ["NeedNum"] = 72}
}

function oluoyang_zhugekongliang:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    --self:AddNumText("用宝石碎片兑换4级宝石", 6, 100)
    --self:AddNumText("用宝石碎片兑换5级宝石", 6, 200)
    --self:AddNumText("用宝石碎片兑换6级宝石", 6, 300)
    --self:AddNumText("用宝石碎片兑换7级宝石", 6, 400)
    --self:AddNumText("#{CJG_090413_33}", 6, 500)
    --if self:CallScriptFunction(self.g_ControlScript, "CheckRightTime") == 1 then
        --self:AddText("#{CHRISTMAS_LUOYANG_HTJS_1}")
        --self:CallScriptFunction(self.g_ControlScript, "OnEnumerate", self, selfId,
                                --targetId)
    --else
        --local i = math.random(0, 1)
        --if i <= 0 then
            --self:AddText("#{OBJ_luoyang_0023}")
        --else
            --self:AddText(
                --"--多么大富大贵的宝相啊！你这么有福的人不介意付十两卦金吧？")
        --end
    --end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_zhugekongliang:OnEventRequest(selfId, targetId, arg, index)
    local key = index
    if key == 500 then
        self:BeginEvent(self.script_id)
        self:AddText("#{CJG_090413_34}")
        self:AddNumText("#{CJG_090413_38}", 6, 501)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if key == 501 then
        if self:LuaFnGetAvailableItemCount(selfId,30505254) < 40 then
            self:MsgBox(selfId,targetId,"#{CJG_090413_35}")
            return
        end
        local nBagsPos = self:LuaFnGetPropertyBagSpace(selfId)
        if nBagsPos < 1 then
            self:MsgBox(selfId,targetId,"#{CJG_090413_36}")
            return
        end
        self:BeginAddItem()
        self:AddItem(30501171, 1)
        if self:EndAddItem(selfId) then
            if self:LuaFnDelAvailableItem(selfId, 30505254, 40) then
                self:AddItemListToHuman(selfId)
            else
                self:MsgBox(selfId, targetId, "#{CJG_090413_35}")
                return
            end
        else
            self:MsgBox(selfId, targetId, "#{CJG_090413_36}")
            return
        end
        return
    end
    if 100 == key or 200 == key or 300 == key or 400 == key then
        self:BeginEvent(self.script_id)
        self:AddText("#{CHANGE_BAOSHI_KONGMIMG}")
        self:AddNumText("Đổi Hổ Nhãn Thạch", 6, 1 + key)
        self:AddNumText("Đổi Miêu Nhãn Thạch", 6, 2 + key)
        self:AddNumText("Đổi Tử Ngọc", 6, 3 + key)
        self:AddNumText("Đổi Tổ Mẫu Lục", 6, 4 + key)
        self:AddNumText("Đổi Lam Tinh Thạch Tinh Khiết", 6, 5 + key)
        self:AddNumText("Đổi Hồng Tinh Thạch Tinh Khiết", 6, 6 + key)
        self:AddNumText("Đổi Hoàng Tinh Thạch Tinh Khiết", 6, 7 + key)
        self:AddNumText("Đổi Lục Tinh Thạch Tinh Khiết", 6, 8 + key)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    else
        self:OnMyChange(selfId, targetId, key)
    end
    if arg == self.g_ControlScript then
        self:CallScriptFunction(self.g_ControlScript, "OnDefaultEvent", selfId,
                                targetId)
        return
    end
end

function oluoyang_zhugekongliang:OnMyChange(selfId, targetId, key)
    local num = math.floor(key / 100)
    local numMod = key % 100
    local index = (num - 1) * 10 + numMod
    local unt = self.g_ChangeLst[index]
    if unt == nil then return end
    if self:LuaFnGetAvailableItemCount(selfId, unt["NeedItm"]) < unt["NeedNum"] then
        local strMsg = string.format("Đổi #H#{_ITEM%d}#W yêu cầu 72 #H#{_ITEM%d}#W, nguyên liệu của ngài không đủ.", unt["id"], unt["NeedItm"])
        self:MsgBox(selfId, targetId, strMsg)
        return
    end
    self:BeginAddItem()
    self:AddItem(unt["id"], 1)
    if self:EndAddItem(selfId) then
        if self:LuaFnDelAvailableItem(selfId, unt["NeedItm"], unt["NeedNum"]) then
            self:AddItemListToHuman(selfId)
        else
            self:MsgBox(selfId, targetId, "    Trừ vật phẩm thất bại!")
            return
        end
    else
        self:MsgBox(selfId, targetId, "    Xin lỗi, túi của ngươi đã đầy, không thể đổi.")
        return
    end
    local strMsg = string.format( "Đổi thành công, ngươi nhận được #H#{_ITEM%d}#W", unt["id"])
    self:MsgBox(selfId, targetId, strMsg)
    local strLog = string.format("change gem gem:%d gem scrap:%d", unt["id"], unt["NeedItm"])
    self:AuditChangeGem(selfId, strLog)
end

return oluoyang_zhugekongliang
