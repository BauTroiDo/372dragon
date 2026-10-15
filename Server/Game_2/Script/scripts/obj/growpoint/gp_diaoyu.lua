local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local gp_diaoyu = class("gp_diaoyu", script_base)
gp_diaoyu.script_id = 712000
gp_diaoyu.g_AbilityId = define.ABILITY_DIAOYU
gp_diaoyu.g_RandNum = 1000000
gp_diaoyu.g_GPInfo = {}

gp_diaoyu.g_rare = {
    [1] = {["Id"] = 20103106, ["Name"] = "Một sợi tơ [cấp 1]", ["Odds"] = 40000},
    [2] = {["Id"] = 20103107, ["Name"] = "Một sợi tơ [cấp 2]", ["Odds"] = 35000},
    [3] = {["Id"] = 20103108, ["Name"] = "Một sợi tơ [cấp 3]", ["Odds"] = 30000},
    [4] = {["Id"] = 20103109, ["Name"] = "Một thuốc nhuộm [cấp 1]", ["Odds"] = 4000},
    [5] = {["Id"] = 20103110, ["Name"] = "Một thuốc nhuộm [cấp 2]", ["Odds"] = 3500},
    [6] = {["Id"] = 20103111, ["Name"] = "Thuốc Nhuộm cấp 3", ["Odds"] = 3000},
    [7] = {["Id"] = 20102025, ["Name"] = "Một con Nghêu", ["Odds"] = 25000},
    [8] = {["Id"] = 20102026, ["Name"] = "Một cây Tảo Tía", ["Odds"] = 25000},
    [9] = {["Id"] = 20102027, ["Name"] = "Một con Tôm Trắng", ["Odds"] = 25000},
    [10] = {["Id"] = 20102028, ["Name"] = "Một con Tôm Hùm", ["Odds"] = 10000},
    [11] = {["Id"] = 20102029, ["Name"] = "Một con Cua Biển", ["Odds"] = 10000},
    [12] = {["Id"] = 20102030, ["Name"] = "Một con Ngao", ["Odds"] = 10000},
    [13] = {["Id"] = 20102031, ["Name"] = "Một con Vẹm Xanh", ["Odds"] = 4000},
    [14] = {["Id"] = 20102032, ["Name"] = "Một con Tôm Sú", ["Odds"] = 4000},
    [15] = {["Id"] = 20102033, ["Name"] = "Một con Nghêu Sặc Sỡ", ["Odds"] = 4000},
    [16] = {["Id"] = 20102034, ["Name"] = "Chỉ Hà Bạng", ["Odds"] = 4000},
    [17] = {["Id"] = 20102035, ["Name"] = "Chỉ Oa Giải", ["Odds"] = 4000},
    [18] = {["Id"] = 20102036, ["Name"] = "Chỉ Ngọc Giải", ["Odds"] = 4000},
    [19] = {["Id"] = 20102048, ["Name"] = "Chỉ Diêm Xác Bạng", ["Odds"] = 4000},
    [20] = {["Id"] = 20102049, ["Name"] = "Đóa Bào Tử Trần", ["Odds"] = 4000},
    [21] = {["Id"] = 20102050, ["Name"] = "Khoa Khỏa Tảo", ["Odds"] = 4000},
    [22] = {["Id"] = 20102051, ["Name"] = "Chỉ Doanh Mẫu", ["Odds"] = 4000},
    [23] = {["Id"] = 20102078, ["Name"] = "Hến sông", ["Odds"] = 50000},
    [24] = {["Id"] = 20102080, ["Name"] = "Rêu xanh", ["Odds"] = 50000}
}

gp_diaoyu.g_GPInfo[201] = {
    ["name"] = "Cá Trắm Cỏ",
    ["mainId"] = 20102001,
    ["rareId"] = {1, 4, 7},
    ["needLevel"] = 1
}

gp_diaoyu.g_GPInfo[202] = {
    ["name"] = "Cá Diếc",
    ["mainId"] = 20102002,
    ["rareId"] = {1, 4, 8},
    ["needLevel"] = 2
}

gp_diaoyu.g_GPInfo[203] = {
    ["name"] = "Cá Mè",
    ["mainId"] = 20102003,
    ["rareId"] = {1, 4, 9},
    ["needLevel"] = 3
}

gp_diaoyu.g_GPInfo[204] = {
    ["name"] = "Cá chim",
    ["mainId"] = 20102004,
    ["rareId"] = {2, 5, 10},
    ["needLevel"] = 4
}

gp_diaoyu.g_GPInfo[205] = {
    ["name"] = "Cá chình",
    ["mainId"] = 20102005,
    ["rareId"] = {2, 5, 11},
    ["needLevel"] = 5
}

gp_diaoyu.g_GPInfo[206] = {
    ["name"] = "Cá quả",
    ["mainId"] = 20102006,
    ["rareId"] = {2, 5, 12},
    ["needLevel"] = 6
}

gp_diaoyu.g_GPInfo[207] = {
    ["name"] = "Cá chọi",
    ["mainId"] = 20102007,
    ["rareId"] = {3, 6, 13},
    ["needLevel"] = 7
}

gp_diaoyu.g_GPInfo[208] = {
    ["name"] = "Cá chim trắng",
    ["mainId"] = 20102008,
    ["rareId"] = {3, 6, 14},
    ["needLevel"] = 8
}

gp_diaoyu.g_GPInfo[209] = {
    ["name"] = "Cá ngân",
    ["mainId"] = 20102009,
    ["rareId"] = {3, 6, 15},
    ["needLevel"] = 9
}

gp_diaoyu.g_GPInfo[210] = {
    ["name"] = "Cá hồi",
    ["mainId"] = 20102010,
    ["rareId"] = {3, 6, 16},
    ["needLevel"] = 10
}

gp_diaoyu.g_GPInfo[211] = {
    ["name"] = "Cá thát lát",
    ["mainId"] = 20102011,
    ["rareId"] = {3, 6, 17},
    ["needLevel"] = 11
}

gp_diaoyu.g_GPInfo[212] = {
    ["name"] = "Cá sáu sọc",
    ["mainId"] = 20102012,
    ["rareId"] = {3, 6, 18},
    ["needLevel"] = 12
}

gp_diaoyu.g_GPInfo[213] = {
    ["name"] = "Cá Trắm Đen",
    ["mainId"] = 20102013,
    ["rareId"] = {1, 4, 7},
    ["needLevel"] = 1
}

gp_diaoyu.g_GPInfo[214] = {
    ["name"] = "Cá Kiếm",
    ["mainId"] = 20102014,
    ["rareId"] = {1, 4, 8},
    ["needLevel"] = 2
}

gp_diaoyu.g_GPInfo[215] = {
    ["name"] = "Cá Vược",
    ["mainId"] = 20102015,
    ["rareId"] = {1, 4, 9},
    ["needLevel"] = 3
}

gp_diaoyu.g_GPInfo[216] = {
    ["name"] = "Cá Đầu Dẹt",
    ["mainId"] = 20102016,
    ["rareId"] = {2, 5, 10},
    ["needLevel"] = 4
}

gp_diaoyu.g_GPInfo[217] = {
    ["name"] = "Cá Du Lực",
    ["mainId"] = 20102017,
    ["rareId"] = {2, 5, 11},
    ["needLevel"] = 5
}

gp_diaoyu.g_GPInfo[218] = {
    ["name"] = "Cá Thu Đao",
    ["mainId"] = 20102018,
    ["rareId"] = {2, 5, 12},
    ["needLevel"] = 6
}

gp_diaoyu.g_GPInfo[219] = {
    ["name"] = "Cá Nhồng",
    ["mainId"] = 20102019,
    ["rareId"] = {3, 6, 13},
    ["needLevel"] = 7
}

gp_diaoyu.g_GPInfo[220] = {
    ["name"] = "Cá Lưng Trơn",
    ["mainId"] = 20102020,
    ["rareId"] = {3, 6, 14},
    ["needLevel"] = 8
}

gp_diaoyu.g_GPInfo[221] = {
    ["name"] = "Cá Móc",
    ["mainId"] = 20102021,
    ["rareId"] = {3, 6, 15},
    ["needLevel"] = 9
}

gp_diaoyu.g_GPInfo[222] = {
    ["name"] = "Cá Vây Đung Đưa",
    ["mainId"] = 20102022,
    ["rareId"] = {3, 6, 16},
    ["needLevel"] = 10
}

gp_diaoyu.g_GPInfo[223] = {
    ["name"] = "Cá Trân Châu",
    ["mainId"] = 20102023,
    ["rareId"] = {3, 6, 17},
    ["needLevel"] = 11
}

gp_diaoyu.g_GPInfo[224] = {
    ["name"] = "Cá Văn Xương",
    ["mainId"] = 20102024,
    ["rareId"] = {3, 6, 18},
    ["needLevel"] = 12
}

gp_diaoyu.g_GPInfo[225] = {
    ["name"] = "Cá Trắm Cỏ",
    ["mainId"] = 20102001,
    ["rareId"] = {1, 4, 7},
    ["needLevel"] = 1
}

gp_diaoyu.g_GPInfo[226] = {
    ["name"] = "Cá Diếc",
    ["mainId"] = 20102002,
    ["rareId"] = {1, 4, 8},
    ["needLevel"] = 2
}

gp_diaoyu.g_GPInfo[227] = {
    ["name"] = "Cá Mè",
    ["mainId"] = 20102003,
    ["rareId"] = {1, 4, 9},
    ["needLevel"] = 3
}

gp_diaoyu.g_GPInfo[228] = {
    ["name"] = "Cá chim",
    ["mainId"] = 20102004,
    ["rareId"] = {2, 5, 10},
    ["needLevel"] = 4
}

gp_diaoyu.g_GPInfo[229] = {
    ["name"] = "Cá chình",
    ["mainId"] = 20102005,
    ["rareId"] = {2, 5, 11},
    ["needLevel"] = 5
}

gp_diaoyu.g_GPInfo[230] = {
    ["name"] = "Cá quả",
    ["mainId"] = 20102006,
    ["rareId"] = {2, 5, 12},
    ["needLevel"] = 6
}

gp_diaoyu.g_GPInfo[231] = {
    ["name"] = "Cá chọi",
    ["mainId"] = 20102007,
    ["rareId"] = {3, 6, 13},
    ["needLevel"] = 7
}

gp_diaoyu.g_GPInfo[232] = {
    ["name"] = "Cá chim trắng",
    ["mainId"] = 20102008,
    ["rareId"] = {3, 6, 14},
    ["needLevel"] = 8
}

gp_diaoyu.g_GPInfo[233] = {
    ["name"] = "Cá ngân",
    ["mainId"] = 20102009,
    ["rareId"] = {3, 6, 15},
    ["needLevel"] = 9
}

gp_diaoyu.g_GPInfo[234] = {
    ["name"] = "Cá hồi",
    ["mainId"] = 20102010,
    ["rareId"] = {3, 6, 16},
    ["needLevel"] = 10
}

gp_diaoyu.g_GPInfo[235] = {
    ["name"] = "Cá thát lát",
    ["mainId"] = 20102011,
    ["rareId"] = {3, 6, 17},
    ["needLevel"] = 11
}

gp_diaoyu.g_GPInfo[236] = {
    ["name"] = "Cá sáu sọc",
    ["mainId"] = 20102012,
    ["rareId"] = {3, 6, 18},
    ["needLevel"] = 12
}

gp_diaoyu.g_GPInfo[237] = {
    ["name"] = "Cá Trắm Đen",
    ["mainId"] = 20102013,
    ["rareId"] = {1, 4, 7},
    ["needLevel"] = 1
}

gp_diaoyu.g_GPInfo[238] = {
    ["name"] = "Cá Kiếm",
    ["mainId"] = 20102014,
    ["rareId"] = {1, 4, 8},
    ["needLevel"] = 2
}

gp_diaoyu.g_GPInfo[239] = {
    ["name"] = "Cá Vược",
    ["mainId"] = 20102015,
    ["rareId"] = {1, 4, 9},
    ["needLevel"] = 3
}

gp_diaoyu.g_GPInfo[240] = {
    ["name"] = "Cá Đầu Dẹt",
    ["mainId"] = 20102016,
    ["rareId"] = {2, 5, 10},
    ["needLevel"] = 4
}

gp_diaoyu.g_GPInfo[241] = {
    ["name"] = "Cá Du Lực",
    ["mainId"] = 20102017,
    ["rareId"] = {2, 5, 11},
    ["needLevel"] = 5
}

gp_diaoyu.g_GPInfo[242] = {
    ["name"] = "Cá Thu Đao",
    ["mainId"] = 20102018,
    ["rareId"] = {2, 5, 12},
    ["needLevel"] = 6
}

gp_diaoyu.g_GPInfo[243] = {
    ["name"] = "Cá Nhồng",
    ["mainId"] = 20102019,
    ["rareId"] = {3, 6, 13},
    ["needLevel"] = 7
}

gp_diaoyu.g_GPInfo[244] = {
    ["name"] = "Cá Lưng Trơn",
    ["mainId"] = 20102020,
    ["rareId"] = {3, 6, 14},
    ["needLevel"] = 8
}

gp_diaoyu.g_GPInfo[245] = {
    ["name"] = "Cá Móc",
    ["mainId"] = 20102021,
    ["rareId"] = {3, 6, 15},
    ["needLevel"] = 9
}

gp_diaoyu.g_GPInfo[246] = {
    ["name"] = "Cá Vây Đung Đưa",
    ["mainId"] = 20102022,
    ["rareId"] = {3, 6, 16},
    ["needLevel"] = 10
}

gp_diaoyu.g_GPInfo[247] = {
    ["name"] = "Cá Trân Châu",
    ["mainId"] = 20102023,
    ["rareId"] = {3, 6, 17},
    ["needLevel"] = 11
}

gp_diaoyu.g_GPInfo[248] = {
    ["name"] = "Cá Văn Xương",
    ["mainId"] = 20102024,
    ["rareId"] = {3, 6, 18},
    ["needLevel"] = 12
}

gp_diaoyu.g_GPInfo[249] = {
    ["name"] = "Cá Yên Chi",
    ["mainId"] = 20102040,
    ["rareId"] = {3, 6, 19},
    ["needLevel"] = 9
}

gp_diaoyu.g_GPInfo[250] = {
    ["name"] = "Cá Thất Tinh",
    ["mainId"] = 20102041,
    ["rareId"] = {3, 6, 20},
    ["needLevel"] = 10
}

gp_diaoyu.g_GPInfo[251] = {
    ["name"] = "Cá Mõm Dài",
    ["mainId"] = 20102042,
    ["rareId"] = {3, 6, 21},
    ["needLevel"] = 11
}

gp_diaoyu.g_GPInfo[252] = {
    ["name"] = "Cá Đa Kỳ",
    ["mainId"] = 20102043,
    ["rareId"] = {3, 6, 22},
    ["needLevel"] = 12
}

gp_diaoyu.g_GPInfo[253] = {
    ["name"] = "Cá Kiều Chủy",
    ["mainId"] = 20102044,
    ["rareId"] = {3, 6, 19},
    ["needLevel"] = 9
}

gp_diaoyu.g_GPInfo[254] = {
    ["name"] = "Cá Thu Bạch Hồi",
    ["mainId"] = 20102045,
    ["rareId"] = {3, 6, 20},
    ["needLevel"] = 10
}

gp_diaoyu.g_GPInfo[255] = {
    ["name"] = "Cá Kỳ Bướm",
    ["mainId"] = 20102046,
    ["rareId"] = {3, 6, 21},
    ["needLevel"] = 11
}

gp_diaoyu.g_GPInfo[256] = {
    ["name"] = "Cá Văn Dao",
    ["mainId"] = 20102047,
    ["rareId"] = {3, 6, 22},
    ["needLevel"] = 12
}

gp_diaoyu.g_GPInfo[820] = {
    ["name"] = "Cá Thanh Giang",
    ["mainId"] = 20102077,
    ["rareId"] = {3, 6, 23},
    ["needLevel"] = 10
}

gp_diaoyu.g_GPInfo[821] = {
    ["name"] = "Lươn",
    ["mainId"] = 20102079,
    ["rareId"] = {3, 6, 24},
    ["needLevel"] = 10
}

gp_diaoyu.g_FishTime = {}
gp_diaoyu.g_FishTime[0] = {["time"] = 31000, ["rand"] = 10000}
gp_diaoyu.g_FishTime[1] = {["time"] = 25000, ["rand"] = 10000}
gp_diaoyu.g_FishTime[2] = {["time"] = 20000, ["rand"] = 10000}
gp_diaoyu.g_FishTime[3] = {["time"] = 15000, ["rand"] = 10000}
gp_diaoyu.g_FishBaitImpactID = {19, 20, 21}
gp_diaoyu.g_TaiGongYuGan = 10100032
gp_diaoyu.g_impact_id = 77
function gp_diaoyu:OnCreate(growPointType, x, y)
    local ItemCount = 0
    self:ItemBoxEnterScene(x, y, growPointType, define.QUALITY_MUST_BE_CHANGE, ItemCount)
end

function gp_diaoyu:OnOpen(selfId, targetId)
    local growPointType = self:LuaFnGetItemBoxGrowPointType(targetId)
    local GPInfo = self.g_GPInfo[growPointType]
    if not GPInfo then
        return define.OPERATE_RESULT.OR_INVALID_TARGET
    end
    local AbilityLevel = self:QueryHumanAbilityLevel(selfId, self.g_AbilityId)
    if AbilityLevel < GPInfo["needLevel"] then
        self:NotifyFailTips(selfId, "Yêu cầu Kỹ năng Câu Cá " .. GPInfo["needLevel"] .. " Cấp, hiện tại " .. AbilityLevel .. " cấp")
        return define.OPERATE_RESULT.OR_NO_LEVEL
    end
    local FishTime = self.g_FishTime[0]
    for i = 1, #(self.g_FishBaitImpactID) do
        if self:LuaFnHaveImpactOfSpecificDataIndex(selfId, self.g_FishBaitImpactID[i]) then
            FishTime = self.g_FishTime[i]
            break
        end
    end
    self:SetAbilityOperaTime(selfId, (FishTime["time"] + math.random(FishTime["rand"])))
    return define.OPERATE_RESULT.OR_OK
end

function gp_diaoyu:OnProcOver(selfId, targetId)
    local growPointType = self:LuaFnGetItemBoxGrowPointType(targetId)
    local GPInfo = self.g_GPInfo[growPointType]
    if not GPInfo then
        return define.OPERATE_RESULT.OR_INVALID_TARGET
    end
    self:CallScriptFunction(define.ABILITYLOGIC_ID, "GainExperience", selfId, self.g_AbilityId, GPInfo["needLevel"])
    self:LuaFnAuditAbility(selfId, self.g_AbilityId, -1, -1)
    local ret1 = self:TryRecieveItem(selfId, GPInfo["mainId"], true)
    if ret1 then
        self:Msg2Player(selfId, "Ngươi câu được một con" .. GPInfo["name"] .. "。", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    else
        self:Msg2Player(selfId, "Ngươi câu được một con" .. GPInfo["name"] .. ", nhưng hành trang đã đầy, ngươi tiện tay ném nó sang một bên.", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    end
    if
        self:LuaFnGetItemCount(selfId, self.g_TaiGongYuGan) > 0 and self:LuaFnGetHumanPKValue(selfId) < 1 and
            self:GetPlayerPvpMode(selfId) == 0
     then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_impact_id, 0)
    end
    local rareNum = #(GPInfo["rareId"])
    if (rareNum < 0) then
        return define.OPERATE_RESULT.OR_OK
    end
    for i = 1, rareNum do
        local rareInfo = self.g_rare[GPInfo["rareId"][i]]
        if (not rareInfo) then
            return define.OPERATE_RESULT.OR_OK
        end
        if (math.random(self.g_RandNum) <= rareInfo["Odds"]) then
            local ret1 = self:TryRecieveItem(selfId, rareInfo["Id"], define.QUALITY_MUST_BE_CHANGE)
            if (ret1 > 0) then
                self:Msg2Player(selfId, "Ngươi câu được một" .. rareInfo["Name"] .. "。", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
            elseif (ret1 == -1) then
                self:Msg2Player(selfId, "Ngươi câu được một" .. rareInfo["Name"] .. ", nhưng hành trang đã đầy, ngươi tiện tay ném nó sang một bên.", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
            end
        end
    end
    return define.OPERATE_RESULT.OR_OK
end

function gp_diaoyu:NotifyFailTips(selfId, Tip)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function gp_diaoyu:OnTickCreateFinish(growPointType, tickCount)
end

return gp_diaoyu
