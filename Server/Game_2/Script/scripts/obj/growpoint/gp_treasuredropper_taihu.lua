local class = require "class"
local define = require "define"
local script_base = require "script_base"
local gp_treasuredropper_taihu = class("gp_treasuredropper_taihu", script_base)
gp_treasuredropper_taihu.g_DropNumTable = {
    {["num"] = 1, ["odd"] = 0.2},
    {["num"] = 2, ["odd"] = 0.4},
    {["num"] = 3, ["odd"] = 0.2},
    {["num"] = 4, ["odd"] = 0.15},
    {["num"] = 5, ["odd"] = 0.05}
}

gp_treasuredropper_taihu.g_TickCreate_Msg = ""
gp_treasuredropper_taihu.g_DropTable = {
    {
        ["itemType"] = 1,
        ["odd"] = 0.293,
        ["numOdd"] = {
            {["num"] = 1, ["odd"] = 0.2},
            {["num"] = 2, ["odd"] = 0.4},
            {["num"] = 3, ["odd"] = 0.2},
            {["num"] = 4, ["odd"] = 0.15},
            {["num"] = 5, ["odd"] = 0.05}
        },
        ["idx"] = {30001003, 30003003, 30101033}
    },
    {
        ["itemType"] = 2,
        ["odd"] = 0.294,
        ["numOdd"] = {
            {["num"] = 1, ["odd"] = 0.2},
            {["num"] = 2, ["odd"] = 0.4},
            {["num"] = 3, ["odd"] = 0.2},
            {["num"] = 4, ["odd"] = 0.15},
            {["num"] = 5, ["odd"] = 0.05}
        },
        ["idx"] = {30002003, 30101043}
    },
    {
        ["itemType"] = 3,
        ["odd"] = 0.2,
        ["numOdd"] = {
            {["num"] = 1, ["odd"] = 0.2},
            {["num"] = 2, ["odd"] = 0.4},
            {["num"] = 3, ["odd"] = 0.2},
            {["num"] = 4, ["odd"] = 0.15},
            {["num"] = 5, ["odd"] = 0.05}
        },
        ["idx"] = {30602003, 30603003, 30604003, 30605003}
    },
    {
        ["itemType"] = 4,
        ["odd"] = 0.1,
        ["numOdd"] = {
            {["num"] = 2, ["odd"] = 0.2},
            {["num"] = 4, ["odd"] = 0.4},
            {["num"] = 6, ["odd"] = 0.2},
            {["num"] = 8, ["odd"] = 0.15},
            {["num"] = 10, ["odd"] = 0.05}
        },
        ["idx"] = {20101005, 20101006, 20101007, 20102003, 20102015, 20103003, 20104003, 20105003}
    },
    {
        ["itemType"] = 12,
        ["odd"] = 0.02,
        ["numOdd"] = {
            {["num"] = 1, ["odd"] = 0.3},
            {["num"] = 2, ["odd"] = 0.4},
            {["num"] = 3, ["odd"] = 0.3}
        },
        ["idx"] = {20102027, 20103015, 20103027, 20103039, 20103051, 20105015}
    },
    {
        ["itemType"] = 5,
        ["odd"] = 0.045,
        ["numOdd"] = {
            {["num"] = 1, ["odd"] = 1.0}
        },
        ["idx"] = {10100003, 10101003, 10102003, 10103003, 10104003, 10105003}
    },
    {
        ["itemType"] = 10,
        ["odd"] = 0,
        ["numOdd"] = {
            {["num"] = 1, ["odd"] = 1.0}
        },
        ["idx"] = {10200003, 10201003, 10202003, 10203003, 10204003, 10205003}
    },
    {
        ["itemType"] = 6,
        ["odd"] = 0.045,
        ["numOdd"] = {
            {["num"] = 1, ["odd"] = 1.0}
        },
        ["idx"] = {
            10110006,
            10110007,
            10110008,
            10111006,
            10111007,
            10111008,
            10112006,
            10112007,
            10112008,
            10113006,
            10113007,
            10113008,
            10120003,
            10121003,
            10122003
        }
    },
    {
        ["itemType"] = 11,
        ["odd"] = 0,
        ["numOdd"] = {
            {["num"] = 1, ["odd"] = 1.0}
        },
        ["idx"] = {10210005, 10211005, 10212005, 10213005, 10220003, 10221003, 10222003}
    },
    {
        ["itemType"] = 7,
        ["odd"] = 0.001,
        ["numOdd"] = {
            {["num"] = 1, ["odd"] = 1.0}
        },
        ["idx"] = {
            50101001,
            50101002,
            50102001,
            50102002,
            50102003,
            50102004,
            50103001,
            50104002,
            50111001,
            50111002,
            50112001,
            50112002,
            50112003,
            50112004,
            50113001,
            50113002,
            50113003,
            50113004,
            50113005,
            50114001
        }
    },
    {
        ["itemType"] = 8,
        ["odd"] = 0.002,
        ["numOdd"] = {
            {["num"] = 1, ["odd"] = 1.0}
        },
        ["idx"] = {30303054, 30304039, 30304040, 30304041, 30304042, 30304043, 30304044}
    },
    {
        ["itemType"] = 9,
        ["odd"] = -1.0,
        ["numOdd"] = {
            {["num"] = 1, ["odd"] = 0.0}
        },
        ["idx"] = {3009, 3019, 3029}
    }
}

function gp_treasuredropper_taihu:GetTableIndexByOdd(tb)
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

function gp_treasuredropper_taihu:OnCreate(growPointType, x, y, dur)
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

function gp_treasuredropper_taihu:OnTickCreateFinish(growPointType, tickCount)
    local sceneId = self:get_scene():get_id()
    if (string.len(self.g_TickCreate_Msg) > 0) then
        print(sceneId .. " Cảnh số " .. self.g_TickCreate_Msg)
    end
end

function gp_treasuredropper_taihu:OnOpen(selfId, targetId)
end

function gp_treasuredropper_taihu:OnRecycle(selfId, targetId)
    return 1
end

function gp_treasuredropper_taihu:OnProcOver(selfId, targetId)
end

function gp_treasuredropper_taihu:OpenCheck(selfId, AbilityId, AblityLevel)
    return define.OPERATE_RESULT.OR_OK
end

return gp_treasuredropper_taihu
