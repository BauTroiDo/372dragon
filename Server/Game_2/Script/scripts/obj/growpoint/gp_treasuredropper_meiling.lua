local class = require "class"
local define = require "define"
local script_base = require "script_base"
local gp_treasuredropper_meiling = class("gp_treasuredropper_meiling", script_base)
gp_treasuredropper_meiling.g_DropNumTable = {
    {["num"] = 1, ["odd"] = 0.2},
    {["num"] = 2, ["odd"] = 0.4},
    {["num"] = 3, ["odd"] = 0.2},
    {["num"] = 4, ["odd"] = 0.15},
    {["num"] = 5, ["odd"] = 0.05}
}

gp_treasuredropper_meiling.g_TickCreate_Msg = ""
gp_treasuredropper_meiling.g_DropTable = {
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
        ["idx"] = {30001004, 30003007, 30101037}
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
        ["idx"] = {30002004, 30101047}
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
        ["idx"] = {30602007, 30603007, 30604007, 30605007}
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
        ["idx"] = {10100007, 10101007, 10102007, 10103007, 10104007, 10105007}
    },
    {
        ["itemType"] = 10,
        ["odd"] = 0,
        ["numOdd"] = {
            {["num"] = 1, ["odd"] = 1.0}
        },
        ["idx"] = {10200007, 10201007, 10202007, 10203007, 10204007, 10205007}
    },
    {
        ["itemType"] = 6,
        ["odd"] = 0.045,
        ["numOdd"] = {
            {["num"] = 1, ["odd"] = 1.0}
        },
        ["idx"] = {
            10110018,
            10110019,
            10110020,
            10110021,
            10110022,
            10110023,
            10111018,
            10111019,
            10111020,
            10111021,
            10111022,
            10111023,
            10112018,
            10112019,
            10112020,
            10112021,
            10112022,
            10112023,
            10113018,
            10113019,
            10113020,
            10113021,
            10113022,
            10113023,
            10120007,
            10121007,
            10122007
        }
    },
    {
        ["itemType"] = 11,
        ["odd"] = 0,
        ["numOdd"] = {
            {["num"] = 1, ["odd"] = 1.0}
        },
        ["idx"] = {10210013, 10211013, 10212013, 10213013, 10220007, 10221007, 10222007}
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
            30302200,
            30302205,
            30302210,
            30302215,
            30302220,
            30302225,
            30302230,
            30302235,
            30302240,
            30302245,
            30302250,
            30302255,
            30302260,
            30302265,
            30302270,
            30302275,
            30302280,
            30302285,
            30302290,
            30302295,
            30302300,
            30302305,
            30302310,
            30302315
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

function gp_treasuredropper_meiling:GetTableIndexByOdd(tb)
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

function gp_treasuredropper_meiling:OnCreate(growPointType, x, y, dur)
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

function gp_treasuredropper_meiling:OnTickCreateFinish(growPointType, tickCount)
    local sceneId = self:get_scene():get_id()
    if (string.len(self.g_TickCreate_Msg) > 0) then
        print(sceneId .. " Cảnh số " .. self.g_TickCreate_Msg)
    end
end

function gp_treasuredropper_meiling:OnOpen(selfId, targetId)
end

function gp_treasuredropper_meiling:OnRecycle(selfId, targetId)
    return 1
end

function gp_treasuredropper_meiling:OnProcOver(selfId, targetId)
end

function gp_treasuredropper_meiling:OpenCheck(selfId, AbilityId, AblityLevel)
    return define.OPERATE_RESULT.OR_OK
end

return gp_treasuredropper_meiling
