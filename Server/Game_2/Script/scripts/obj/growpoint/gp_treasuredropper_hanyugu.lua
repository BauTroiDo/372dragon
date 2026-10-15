local class = require "class"
local define = require "define"
local script_base = require "script_base"
local gp_treasuredropper_hanyugu = class("gp_treasuredropper_hanyugu", script_base)
gp_treasuredropper_hanyugu.g_DropNumTable = {
    {["num"] = 1, ["odd"] = 0.2},
    {["num"] = 2, ["odd"] = 0.4},
    {["num"] = 3, ["odd"] = 0.2},
    {["num"] = 4, ["odd"] = 0.15},
    {["num"] = 5, ["odd"] = 0.05}
}

gp_treasuredropper_hanyugu.g_TickCreate_Msg = ""
gp_treasuredropper_hanyugu.g_DropTable = {
    {
        ["itemType"] = 4,
        ["odd"] = 0.42,
        ["numOdd"] = {
            {["num"] = 2, ["odd"] = 0.2},
            {["num"] = 4, ["odd"] = 0.4},
            {["num"] = 6, ["odd"] = 0.2},
            {["num"] = 8, ["odd"] = 0.15},
            {["num"] = 10, ["odd"] = 0.05}
        },
        ["idx"] = {20101011, 20101012, 20101013, 20102005, 20102017, 20103005, 20104005, 20105005}
    },
    {
        ["itemType"] = 12,
        ["odd"] = 0.42,
        ["numOdd"] = {
            {["num"] = 1, ["odd"] = 0.3},
            {["num"] = 2, ["odd"] = 0.4},
            {["num"] = 3, ["odd"] = 0.3}
        },
        ["idx"] = {20102029, 20103017, 20103029, 20103041, 20103053, 20105017}
    },
    {
        ["itemType"] = 3,
        ["odd"] = 0.01,
        ["numOdd"] = {
            {["num"] = 1, ["odd"] = 1.0}
        },
        ["idx"] = {30505178}
    },
    {
        ["itemType"] = 5,
        ["odd"] = 0.05,
        ["numOdd"] = {
            {["num"] = 1, ["odd"] = 1.0}
        },
        ["idx"] = {10100005, 10101005, 10102005, 10103005, 10104005, 10105005}
    },
    {
        ["itemType"] = 6,
        ["odd"] = 0.05,
        ["numOdd"] = {
            {["num"] = 1, ["odd"] = 1.0}
        },
        ["idx"] = {
            10110012,
            10110013,
            10110014,
            10111012,
            10111013,
            10111014,
            10112012,
            10112013,
            10112014,
            10113012,
            10113013,
            10113014,
            10120005,
            10121005,
            10122005
        }
    },
    {
        ["itemType"] = 7,
        ["odd"] = 0.04,
        ["numOdd"] = {
            {["num"] = 1, ["odd"] = 1.0}
        },
        ["idx"] = {30501148, 30501149, 30501150}
    },
    {
        ["itemType"] = 8,
        ["odd"] = 0.01,
        ["numOdd"] = {
            {["num"] = 1, ["odd"] = 1.0}
        },
        ["idx"] = {30700200}
    }
}

function gp_treasuredropper_hanyugu:GetTableIndexByOdd(tb)
    local oddNow = math.random()
    local base = 0.0
    for i = 1, #(tb) do
        if (tb[i]["odd"] + base >= oddNow) then
            return i
        end
        base = base + tb[i]["odd"]
    end
    return nil
end

function gp_treasuredropper_hanyugu:OnCreate(growPointType, x, y, dur)
    local ItemBoxId = nil
    local delDur = dur - 60000
    local sceneId = self:get_scene():get_id()
    local numIdx = self:GetTableIndexByOdd(self.g_DropNumTable)
    if (numIdx) then
        for i = 1, self.g_DropNumTable[numIdx]["num"] do
            local showIdx = self:GetTableIndexByOdd(self.g_DropTable)
            local dropNumIdx = nil
            local itemId = nil
            if (showIdx) then
                dropNumIdx = self:GetTableIndexByOdd(self.g_DropTable[showIdx]["numOdd"])
                if (dropNumIdx and 9 ~= self.g_DropTable[showIdx]["itemType"]) then
                    local itemNum = #(self.g_DropTable[showIdx]["idx"])
                    if (itemNum and 1 <= itemNum) then
                        local itemIdx = math.floor(math.random(1, itemNum))
                        itemId = self.g_DropTable[showIdx]["idx"][itemIdx]
                        for k = 1, self.g_DropTable[showIdx]["numOdd"][dropNumIdx]["num"] do
                            if (nil == ItemBoxId) then
                                ItemBoxId =
                                    self:ItemBoxEnterScene(
                                    x,
                                    y,
                                    growPointType,
                                    define.QUALITY_MUST_BE_CHANGE,
                                    1,
                                    itemId
                                )
                                print(
                                    sceneId ..
                                        " Số cảnh (" ..
                                            x ..
                                                ", " ..
                                                    y ..
                                                        ") Chỗ này mọc ra một rương vật phẩm." ..
                                                            "(" .. self.g_DropNumTable[numIdx]["num"] .. ")"
                                )
                            else
                                self:AddItemToBox(ItemBoxId, define.QUALITY_MUST_BE_CHANGE, 1, itemId)
                            end
                        end
                    end
                elseif (dropNumIdx and 9 == self.g_DropTable[showIdx]["itemType"]) then
                    local petIdx = math.floor(math.random(1, #(self.g_DropTable[showIdx]["idx"])))
                    local petId = self.g_DropTable[showIdx]["idx"][petIdx]
                    for k = 1, self.g_DropTable[showIdx]["numOdd"][dropNumIdx]["num"] do
                        local PetObjId = nil
                        PetObjId = self:CreatePetOnScene(petId, x, y)
                        self:SetCharacterDieTime(PetObjId, delDur)
                        print(sceneId .. " Số cảnh (" .. x .. ", " .. y .. ") Chỗ này mọc ra một Trân thú " .. self:GetName(PetObjId) .. "。")
                    end
                end
            end
            if (showIdx and dropNumIdx and itemId ~= nil) then
                if (9 ~= self.g_DropTable[showIdx]["itemType"]) then
                    local _, itemName = self:GetItemInfoByItemId(itemId)
                    print(
                        "Trong rương vật phẩm có (loại" ..
                            self.g_DropTable[showIdx]["itemType"] ..
                                ")" ..
                                    self.g_DropTable[showIdx]["numOdd"][dropNumIdx]["num"] .. "cái[" .. itemName .. "]。"
                    )
                    local itemNum = self.g_DropTable[showIdx]["numOdd"][dropNumIdx]["num"]
                    self:LuaFnAuditItemCreate(-1, itemNum, itemId, itemName, "Được tạo ra từ rương báu")
                end
            end
        end
        if (ItemBoxId) then
            self:SetItemBoxMaxGrowTime(ItemBoxId, delDur)
            return 0
        end
    end
    return -1
end

function gp_treasuredropper_hanyugu:OnTickCreateFinish(growPointType, tickCount)
    local sceneId = self:get_scene():get_id()
    if (string.len(self.g_TickCreate_Msg) > 0) then
        print(sceneId .. " Cảnh số " .. self.g_TickCreate_Msg)
    end
end

function gp_treasuredropper_hanyugu:OnOpen(selfId, targetId)
end

function gp_treasuredropper_hanyugu:OnRecycle(selfId, targetId)
    return 1
end

function gp_treasuredropper_hanyugu:OnProcOver(selfId, targetId)
end

function gp_treasuredropper_hanyugu:OpenCheck(selfId, AbilityId, AblityLevel)
    return define.OPERATE_RESULT.OR_OK
end

return gp_treasuredropper_hanyugu
