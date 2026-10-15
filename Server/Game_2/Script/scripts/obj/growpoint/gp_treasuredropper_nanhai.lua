local class = require "class"
local define = require "define"
local script_base = require "script_base"
local gp_treasuredropper_nanhai = class("gp_treasuredropper_nanhai", script_base)
gp_treasuredropper_nanhai.g_DropNumTable = {
    {["num"] = 1, ["odd"] = 0.2},
    {["num"] = 2, ["odd"] = 0.4},
    {["num"] = 3, ["odd"] = 0.2},
    {["num"] = 4, ["odd"] = 0.15},
    {["num"] = 5, ["odd"] = 0.05}
}

gp_treasuredropper_nanhai.g_TickCreate_Msg = ""
gp_treasuredropper_nanhai.g_DropTable = {
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
        ["idx"] = {30001004, 30003009, 30101039}
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
        ["idx"] = {30002004, 30101049}
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
        ["idx"] = {30602009, 30603009, 30604009, 30605009}
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
        ["idx"] = {10100009, 10101009, 10102009, 10103009, 10104009, 10105009}
    },
    {
        ["itemType"] = 10,
        ["odd"] = 0,
        ["numOdd"] = {
            {["num"] = 1, ["odd"] = 1.0}
        },
        ["idx"] = {10200009, 10201009, 10202009, 10203009, 10204009, 10205009}
    },
    {
        ["itemType"] = 6,
        ["odd"] = 0.045,
        ["numOdd"] = {
            {["num"] = 1, ["odd"] = 1.0}
        },
        ["idx"] = {
            10110036,
            10110037,
            10110038,
            10110039,
            10110040,
            10110041,
            10110042,
            10110043,
            10110044,
            10111036,
            10111037,
            10111038,
            10111039,
            10111040,
            10111041,
            10111042,
            10111043,
            10111044,
            10112036,
            10112037,
            10112038,
            10112039,
            10112040,
            10112041,
            10112042,
            10112043,
            10112044,
            10113036,
            10113037,
            10113038,
            10113039,
            10113040,
            10113041,
            10113042,
            10113043,
            10113044,
            10120009,
            10121009,
            10122009
        }
    },
    {
        ["itemType"] = 11,
        ["odd"] = 0,
        ["numOdd"] = {
            {["num"] = 1, ["odd"] = 1.0}
        },
        ["idx"] = {10210017, 10211017, 10212017, 10213017, 10220009, 10221009, 10222009}
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
        ["idx"] = {
            30304067,
            30304068,
            30304069,
            30304070,
            30304080,
            30304081,
            30304082,
            30304083,
            30304084,
            30304085,
            30304086,
            30304087,
            30304088
        }
    },
    {
        ["itemType"] = 13,
        ["odd"] = 0.01,
        ["numOdd"] = {
            {["num"] = 1, ["odd"] = 1.0}
        },
        ["idx"] = {
            30302202,
            30302207,
            30302212,
            30302217,
            30302222,
            30302227,
            30302232,
            30302237,
            30302242,
            30302247,
            30302252,
            30302257,
            30302262,
            30302267,
            30302272,
            30302277,
            30302282,
            30302287,
            30302292,
            30302297,
            30302302,
            30302307,
            30302312,
            30302317
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

function gp_treasuredropper_nanhai:GetTableIndexByOdd(tb)
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

function gp_treasuredropper_nanhai:OnCreate(growPointType, x, y, dur)
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

function gp_treasuredropper_nanhai:OnTickCreateFinish(growPointType, tickCount)
    local sceneId = self:get_scene():get_id()
    if (string.len(self.g_TickCreate_Msg) > 0) then
        print(sceneId .. " Cảnh số " .. self.g_TickCreate_Msg)
    end
end

function gp_treasuredropper_nanhai:OnOpen(selfId, targetId)
end

function gp_treasuredropper_nanhai:OnRecycle(selfId, targetId)
    return 1
end

function gp_treasuredropper_nanhai:OnProcOver(selfId, targetId)
end

function gp_treasuredropper_nanhai:OpenCheck(selfId, AbilityId, AblityLevel)
    return define.OPERATE_RESULT.OR_OK
end

return gp_treasuredropper_nanhai
