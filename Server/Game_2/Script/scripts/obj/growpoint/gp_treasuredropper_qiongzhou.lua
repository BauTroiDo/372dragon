local class = require "class"
local define = require "define"
local script_base = require "script_base"
local gp_treasuredropper_qiongzhou = class("gp_treasuredropper_qiongzhou", script_base)
gp_treasuredropper_qiongzhou.g_DropNumTable = {
    {["num"] = 1, ["odd"] = 0.2},
    {["num"] = 2, ["odd"] = 0.4},
    {["num"] = 3, ["odd"] = 0.2},
    {["num"] = 4, ["odd"] = 0.15},
    {["num"] = 5, ["odd"] = 0.05}
}

gp_treasuredropper_qiongzhou.g_TickCreate_Msg = ""
gp_treasuredropper_qiongzhou.g_DropTable = {
    {
        ["itemType"] = 1,
        ["odd"] = 0.284,
        ["numOdd"] = {
            {["num"] = 1, ["odd"] = 0.2},
            {["num"] = 2, ["odd"] = 0.4},
            {["num"] = 3, ["odd"] = 0.2},
            {["num"] = 4, ["odd"] = 0.15},
            {["num"] = 5, ["odd"] = 0.05}
        },
        ["idx"] = {30001004, 30003010, 30101040}
    },
    {
        ["itemType"] = 2,
        ["odd"] = 0.293,
        ["numOdd"] = {
            {["num"] = 1, ["odd"] = 0.2},
            {["num"] = 2, ["odd"] = 0.4},
            {["num"] = 3, ["odd"] = 0.2},
            {["num"] = 4, ["odd"] = 0.15},
            {["num"] = 5, ["odd"] = 0.05}
        },
        ["idx"] = {30002004, 30101050}
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
        ["idx"] = {30602010, 30603010, 30604010, 30605010}
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
        ["idx"] = {20101001, 20101002, 20102001, 20102013, 20103001, 20104001, 20105001}
    },
    {
        ["itemType"] = 12,
        ["odd"] = 0.02,
        ["numOdd"] = {
            {["num"] = 1, ["odd"] = 0.3},
            {["num"] = 2, ["odd"] = 0.4},
            {["num"] = 3, ["odd"] = 0.3}
        },
        ["idx"] = {20102031, 20103019, 20103031, 20103043, 20103055, 20105019}
    },
    {
        ["itemType"] = 5,
        ["odd"] = 0.045,
        ["numOdd"] = {
            {["num"] = 1, ["odd"] = 1.0}
        },
        ["idx"] = {10100010, 10101010, 10102010, 10103010, 10104010, 10105010}
    },
    {
        ["itemType"] = 10,
        ["odd"] = 0,
        ["numOdd"] = {
            {["num"] = 1, ["odd"] = 1.0}
        },
        ["idx"] = {10200010, 10201010, 10202010, 10203010, 10204010, 10205010}
    },
    {
        ["itemType"] = 6,
        ["odd"] = 0.045,
        ["numOdd"] = {
            {["num"] = 1, ["odd"] = 1.0}
        },
        ["idx"] = {
            10110045,
            10110046,
            10110047,
            10110048,
            10110049,
            10110050,
            10111045,
            10111046,
            10111047,
            10111048,
            10111049,
            10111050,
            10112045,
            10112046,
            10112047,
            10112048,
            10112049,
            10112050,
            10113045,
            10113046,
            10113047,
            10113048,
            10113049,
            10113050,
            10120010,
            10121010,
            10122010
        }
    },
    {
        ["itemType"] = 11,
        ["odd"] = 0,
        ["numOdd"] = {
            {["num"] = 1, ["odd"] = 1.0}
        },
        ["idx"] = {10210019, 10211019, 10212019, 10213019, 10220010, 10221010, 10222010}
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
        ["idx"] = {}
    },
    {
        ["itemType"] = 13,
        ["odd"] = 0.01,
        ["numOdd"] = {
            {["num"] = 1, ["odd"] = 1.0}
        },
        ["idx"] = {
            30302203,
            30302208,
            30302213,
            30302218,
            30302223,
            30302228,
            30302233,
            30302238,
            30302243,
            30302248,
            30302253,
            30302258,
            30302263,
            30302268,
            30302273,
            30302278,
            30302283,
            30302288,
            30302293,
            30302298,
            30302303,
            30302308,
            30302313,
            30302318
        }
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

function gp_treasuredropper_qiongzhou:GetTableIndexByOdd(tb)
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

function gp_treasuredropper_qiongzhou:OnCreate(growPointType, x, y, dur)
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

function gp_treasuredropper_qiongzhou:OnTickCreateFinish(growPointType, tickCount)
    local sceneId = self:get_scene():get_id()
    if (string.len(self.g_TickCreate_Msg) > 0) then
        print(sceneId .. " Cảnh số " .. self.g_TickCreate_Msg)
    end
end

function gp_treasuredropper_qiongzhou:OnOpen(selfId, targetId)
end

function gp_treasuredropper_qiongzhou:OnRecycle(selfId, targetId)
    return 1
end

function gp_treasuredropper_qiongzhou:OnProcOver(selfId, targetId)
end

function gp_treasuredropper_qiongzhou:OpenCheck(selfId, AbilityId, AblityLevel)
    return define.OPERATE_RESULT.OR_OK
end

return gp_treasuredropper_qiongzhou
