local class = require "class"
local define = require "define"
local script_base = require "script_base"
local wudaoNPC = class("wudaoNPC", script_base)
local ScriptGlobal = require "scripts.ScriptGlobal"
wudaoNPC.script_id = 992002
wudaoNPC.NpcInfo = {
    ["玄阅"] = {
        "#{TFYD_210729_543}", 0, "La Hán", "#{TFYD_210729_432}", "#{TalentSL_20210804_01}", 0, 23, 1053
    },
    ["玄篱"] = {
        "#{TFYD_210729_542}", 0, "Kim Cang", "#{TFYD_210729_431}", "#{TalentSL_20210804_01}", 1, 34, 1054
    },
    ["林焱"] = {
        "#{TFYD_210729_546}", 1, "Huyết Lệ", "#{TFYD_210729_433}","#{TalentMJ_20210804_01}", 1, 56, 1056
    },
    ["莫思归"] = {
        "#{TFYD_210729_547}", 1, "Thiên La", "#{TFYD_210729_434}", "#{TalentMJ_20210804_01}", 0, 45, 1055
    },
    ["路老大"] = {
        "#{TFYD_210729_544}", 2, "Hành Hiệp", "#{TFYD_210729_435}", "#{TalentGB_20210804_01}", 1, 12, 1058
    },
    ["杜少康"] = {
        "#{TFYD_210729_545}", 2, "Tửu Cuồng", "#{TFYD_210729_436}", "#{TalentGB_20210804_01}", 0, 1, 1057
    },
    ["碧落散人"] = {
        "#{TFYD_210729_548}", 3, "Bằng Hư", "#{TFYD_210729_437}", "#{TalentWD_20210804_01}", 0, 67, 1059
    },
    ["逐浪散人"] = {
        "#{TFYD_210729_549}", 3, "Trích Tinh", "#{TFYD_210729_438}", "#{TalentWD_20210804_01}", 1, 78, 1060
    },
    ["聚落花"] = {
        "#{TFYD_210729_555}", 4, "Thấm Phương", "#{TFYD_210729_439}", "#{TalentEM_20210804_01}", 0, 89, 1061
    },
    ["苏戈"] = {
        "#{TFYD_210729_554}", 4, "Thanh Âm", "#{TFYD_210729_441}", "#{TalentEM_20210804_01}", 1, 100, 1062
    },
    ["蒿莱子"] = {
        "#{TFYD_210729_556}", 5, "Hàn Minh", "#{TFYD_210729_442}","#{TalentXX_20210804_01}", 0, 111, 1063
    },
    ["莲舟子"] = {
        "#{TFYD_210729_557}", 5, "Cửu Ách", "#{TFYD_210729_443}", "#{TalentXX_20210804_01}", 1, 122, 1064
    },
    ["本喜"] = { 
        "#{TFYD_210729_550}", 6, "Long Uy", "#{TFYD_210729_444}","#{TalentTL_20210804_01}", 0, 133, 1065
    },
    ["本然"] = {
        "#{TFYD_210729_551}", 6, "Bồ Thiên", "#{TFYD_210729_445}", "#{TalentTL_20210804_01}", 1, 144, 1066
    },
    ["吴淼淼"] = {
        "#{TFYD_210729_559}", 7, "Tuyết Ẩn", "#{TFYD_210729_446}","#{TalentTS_20210804_01}", 1, 166, 1068
    },
    ["吴森森"] = {
        "#{TFYD_210729_558}", 7, "Sương Ngưng", "#{TFYD_210729_447}", "#{TalentTS_20210804_01}", 0, 155, 1067
    },
    ["秦烟萝"] = {
        "#{TFYD_210729_553}", 8, "Minh Quỷ", "#{TFYD_210729_448}", "#{TalentXY_20210804_01}", 1, 188, 1070
    },
    ["艾凉河"] = {
        "#{TFYD_210729_552}", 8, "Dật Tiên", "#{TFYD_210729_449}", "#{TalentXY_20210804_01}", 0, 177, 1069
    },
    ["嵇聆风"] = {
        "#{TFYD_210729_553}", 10, "Vãn Lại", "#{TFYD_220523_46}", "#{TalentMT_20220621_04}", 0, 379, 1205
    },
    ["嵇扶光"] = {
        "#{TFYD_210729_552}", 10, "Chiêu Minh", "#{TFYD_220523_47}", "#{TalentMT_20220621_05}", 1, 390, 1206
    },
    ["山人木"] = {
        "#{ERMP_240620_19}", 11, "Tố Hồn", "#{ERMP_240620_19}", "#{TalentER_20240802_04}", 0, 621, 1370
    },
    ["山姥"] = {
        "#{ERMP_240620_20}", 11, "Phán Mệnh", "#{ERMP_240620_20}", "#{TalentER_20240802_05}", 1, 632, 1371
    },
    ["慕容瑾"] = {
        "#{TFYD_210729_553}", 12, "Nghịch Phong", "#{TFYD_220523_46}", "#{TalentGS_20260326_01}", 0, 903, 1411
    },
    ["慕容瑜"] = {
        "#{TFYD_210729_552}", 12, "Dịch Thế", "#{TFYD_220523_47}", "#{TalentGS_20260326_02}", 1, 914, 1412
    }
}

wudaoNPC.g_Talent_Studyup_Info = {
    [0] = {
        [1] = {
            ["instrct"] = "#{TalentSL_20210804_02}",
            ["icon"] = "set:Talent image:Talent_SLLH",
            [1] = {23},
            [2] = {24, -1, 25},
            [3] = {26, 27, 28},
            [4] = {29, 30, -1},
            [5] = {31, 32, 33}
        },
        [2] = {
            ["instrct"] = "#{TalentSL_20210804_04}",
            ["icon"] = "set:Talent image:Talent_SLJG",
            [1] = {34},
            [2] = {35, -1, 36},
            [3] = {37, 38, 39},
            [4] = {40, -1, 41},
            [5] = {42, 43, 44}
        }
    },
    [1] = {
        [1] = {
            ["instrct"] = "#{TalentMJ_20210804_02}",
            ["icon"] = "set:Talent image:Talent_MJTL",
            [1] = {45},
            [2] = {46, -1, 47},
            [3] = {48, 49, 50},
            [4] = {51, -1, 52},
            [5] = {53, 54, 55}
        },
        [2] = {
            ["instrct"] = "#{TalentMJ_20210804_04}",
            ["icon"] = "set:Talent image:Talent_MJXL",
            [1] = {56},
            [2] = {57, -1, 58},
            [3] = {59, 60, 61},
            [4] = {62, -1, 63},
            [5] = {64, 65, 66}
        }
    },
    [2] = {
        [1] = {
            ["instrct"] = "#{TalentGB_20210804_02}",
            ["icon"] = "set:Talent image:Talent_GBJK",
            [1] = {1},
            [2] = {2, -1, 3},
            [3] = {4, 5, 6},
            [4] = {7, 8, -1},
            [5] = {9, 10, 11}
        },
        [2] = {
            ["instrct"] = "#{TalentGB_20210804_04}",
            ["icon"] = "set:Talent image:Talent_GBXX",
            [1] = {12},
            [2] = {13, -1, 14},
            [3] = {15, 16, 17},
            [4] = {18, -1, 19},
            [5] = {20, 21, 22}
        }
    },
    [3] = {
        [1] = {
            ["instrct"] = "#{TalentWD_20210804_02}",
            ["icon"] = "set:Talent2 image:Talent_WDPX",
            [1] = {67},
            [2] = {68, -1, 69},
            [3] = {70, 71, 72},
            [4] = {73, -1, 74},
            [5] = {75, 76, 77}
        },
        [2] = {
            ["instrct"] = "#{TalentWD_20210804_04}",
            ["icon"] = "set:Talent2 image:Talent_WDZX",
            [1] = {78},
            [2] = {79, -1, 80},
            [3] = {81, 82, 83},
            [4] = {84, -1, 85},
            [5] = {86, 87, 88}
        }
    },
    [4] = {
        [1] = {
            ["instrct"] = "#{TalentEM_20210804_02}",
            ["icon"] = "set:Talent image:Talent_EMQF",
            [1] = {89},
            [2] = {90, -1, 91},
            [3] = {92, 93, 94},
            [4] = {95, 96, -1},
            [5] = {97, 98, 99}
        },
        [2] = {
            ["instrct"] = "#{TalentEM_20210804_04}",
            ["icon"] = "set:Talent image:Talent_EMQY",
            [1] = {100},
            [2] = {101, -1, 102},
            [3] = {103, 104, 105},
            [4] = {106, -1, 107},
            [5] = {108, 109, 110}
        }
    },
    [5] = {
        [1] = {
            ["instrct"] = "#{TalentXX_20210804_02}",
            ["icon"] = "set:Talent2 image:Talent_XXHM",
            [1] = {111},
            [2] = {112, -1, 113},
            [3] = {114, 115, 116},
            [4] = {117, -1, 118},
            [5] = {119, 120, 121}
        },
        [2] = {
            ["instrct"] = "#{TalentXX_20210804_04}",
            ["icon"] = "set:Talent2 image:Talent_XXJE",
            [1] = {122},
            [2] = {123, -1, 124},
            [3] = {125, 126, 127},
            [4] = {128, -1, 129},
            [5] = {130, 131, 132}
        }
    },
    [6] = {
        [1] = {
            ["instrct"] = "#{TalentTL_20210804_02}",
            ["icon"] = "set:Talent image:Talent_TLLW",
            [1] = {133},
            [2] = {134, -1, 135},
            [3] = {136, 137, 138},
            [4] = {139, -1, 140},
            [5] = {141, 142, 143}
        },
        [2] = {
            ["instrct"] = "#{TalentTL_20210804_04}",
            ["icon"] = "set:Talent image:Talent_TLPT",
            [1] = {144},
            [2] = {145, -1, 146},
            [3] = {147, 148, 149},
            [4] = {150, -1, 151},
            [5] = {152, 153, 154}
        }
    },
    [7] = {
        [1] = {
            ["instrct"] = "#{TalentTS_20210804_02}",
            ["icon"] = "set:Talent2 image:Talent_TSNS",
            [1] = {155},
            [2] = {156, -1, 157},
            [3] = {158, 159, 160},
            [4] = {161, -1, 162},
            [5] = {163, 164, 165}
        },
        [2] = {
            ["instrct"] = "#{TalentTS_20210804_04}",
            ["icon"] = "set:Talent2 image:Talent_TSXY",
            [1] = {166},
            [2] = {167, -1, 168},
            [3] = {169, 170, 171},
            [4] = {172, -1, 173},
            [5] = {174, 175, 176}
        }
    },
    [8] = {
        [1] = {
            ["instrct"] = "#{TalentXY_20210804_02}",
            ["icon"] = "set:Talent2 image:Talent_XYYX",
            [1] = {177},
            [2] = {178, -1, 179},
            [3] = {180, 181, 182},
            [4] = {183, -1, 184},
            [5] = {185, 186, 187}
        },
        [2] = {
            ["instrct"] = "#{TalentXY_20210804_04}",
            ["icon"] = "set:Talent2 image:Talent_XYMG",
            [1] = {188},
            [2] = {189, -1, 190},
            [3] = {191, 192, 193},
            [4] = {194, -1, 195},
            [5] = {196, 197, 198}
        }
    }
}

function wudaoNPC:OnDefaultEvent(selfId, targetId)
    local mp = self:GetMenPai(selfId)
    local talent_type = self:GetTalentType(selfId)
    local NPCName = self:GetName(targetId)
    if self.NpcInfo[NPCName] == nil then return end
    if self.NpcInfo[NPCName][2] ~= mp then
        self:BeginEvent(self.script_id)
        self:AddText(self.NpcInfo[NPCName][1])
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    self:BeginEvent(self.script_id)
    self:AddText(self.NpcInfo[NPCName][4])
    if talent_type == define.INVAILD_ID then
        self:AddNumText("Chọn lưu phái·" .. self.NpcInfo[NPCName][3], 6, 1)
    elseif talent_type ~= self.NpcInfo[NPCName][6] then
        self:AddNumText("Đổi lưu phái·" .. self.NpcInfo[NPCName][3], 6, 3)
    end
    if talent_type == self.NpcInfo[NPCName][6] then
        self:AddNumText("Võ đạo Tu luyện", 6, 2)
        self:AddNumText("Võ đạo Trùng Tập", 6, 4)
    end
    self:AddNumText("Nhận điểm võ đạo đan (1 vạn)", 6, 8)
    self:AddNumText("Lưu phái xem trước", 6, 5)
    self:AddNumText("về Võ đạo", 11, 6)
    -- if NPCName == "慕容瑾" or NPCName == "慕容瑜" then
            -- self:CallScriptFunction(64, "Restore_hpmp", selfId, targetId)
        -- self:AddNumText("#R清除所有BUFF(测试)", 6, 9)
    -- end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function wudaoNPC:OnEventRequest(selfId, targetId, arg, index)
    local NPCName = self:GetName(targetId)
    local Talent = self:GetTalentType(selfId)
    if index == 1 then
        self:BeginEvent(self.script_id)
        self:AddText("    Bạn chắc chắn chọn#G" .. self.NpcInfo[NPCName][3] ..
                         "#llưu phái võ đạo? Bấm nút xác nhận để chọn thẳng lưu phái này.#r    #GMẹo: chọn xong có thể dùng Võ Đạo Quy Nguyên Lệnh đổi lưu phái.")
        self:AddNumText("Xác nhận", 6, 11)
        self:AddNumText("Trở về", 6, 100)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 2 then
        if Talent == define.INVAILD_ID then
            self:Tips(selfId, "Chưa vào võ đạo, không học được")
            return
        end
        self:NotifyTalent(selfId)
    elseif index == 5 then
        local id = self.NpcInfo[NPCName][6] + 1
        self:BeginUICommand()
        self:UICommand_AddInt(self:GetMenPai(selfId))
        self:UICommand_AddInt(id)
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 20210801)
    elseif index == 6 then
        self:BeginEvent(self.script_id)
        self:AddText("#{TalentMP_20210804_65}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 7 then
        self:BeginEvent(self.script_id)
        self:AddText(self.NpcInfo[NPCName][5])
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 11 then
        if self:GetLevel(selfId) < 60 then
            self:Tips(selfId, "#{TalentMP_20210804_36}")
            return
        end
        local talent_type = self:GetTalentType(selfId)
        if talent_type > 0 then
            self:Tips(selfId, "#{TalentMP_20210804_32}")
            return
        end
        self:SelectTalentType(selfId, self.NpcInfo[NPCName][6], self.NpcInfo[NPCName][7])
        self:LuaFnAddNewAgname(selfId, self.NpcInfo[NPCName][8])
        self:Tips(selfId, string.format("Chọn lưu phái %s thành công, kích hoạt võ đạo.", self.NpcInfo[NPCName][3]))
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 49, 0)
        self:BeginUICommand()
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
    elseif index == 3 then
        self:BeginEvent(self.script_id)
        self:AddText("    Bạn chắc chắn đổi lưu phái võ đạo thành#G" ..
                         self.NpcInfo[NPCName][3] ..
                         "#lkhông? Bấm xác nhận đổi xong, điểm lĩnh ngộ võ đạo đã phân sẽ hoàn hết vào lưu phái mới.#r    #GMẹo: tốn Võ Đạo Quy Nguyên Lệnh để đổi lưu phái, mỗi 72 giờ đổi được một lần.")
        self:AddNumText("Xác nhận", 6, 31)
        self:AddNumText("Trở về", 6, 100)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 31 then
        if self:GetLevel(selfId) < 60 then
            self:Tips(selfId, "#{TalentMP_20210804_44}")
            return
        end
        local talent_type = self:GetTalentType(selfId)
        if talent_type < 0 then
            self:Tips(selfId, "#{TalentMP_20210804_45}")
            return
        end
        local current_talent_type = self.NpcInfo[NPCName][6]
        if current_talent_type == talent_type then
            self:Tips(selfId, "#{TalentMP_20210804_38}")
            return
        end
        local nHaveItem = self:LuaFnGetAvailableItemCount(selfId, 38002405)
        if nHaveItem < 1 then
            self:Tips(selfId, "#{TalentMP_20210804_47}")
            return
        end
        self:SelectTalentType(selfId, self.NpcInfo[NPCName][6], self.NpcInfo[NPCName][7])
        self:LuaFnDelAvailableItem(selfId, 38002405, 1)
        self:Tips(selfId, string.format("Đổi lưu phái võ đạo %s thành công", self.NpcInfo[NPCName][3]))
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 49, 0)
        self:LuaFnAddNewAgname(selfId, self.NpcInfo[NPCName][8])
    elseif index == 8 then
        self:LuaFnAddTalentUnderstandPoint(selfId, 10000)
        self:Tips(selfId, "Nhận thành công 10 điểm lĩnh ngộ võ đạo.")
    elseif index == 9 then
        local human = self:get_scene():get_obj_by_id(selfId)
        if human then
            local impact_list = human:get_impact_list()
            local count = #impact_list
            for i = count, 1, -1 do
                local imp = impact_list[i]
                human:on_impact_fade_out(imp)
                human:remove_impact(imp)
            end
            self:Tips(selfId, string.format("Đã xóa %d hiệu ứng BUFF.", count))
        end
    elseif index == 100 then
        self:OnDefaultEvent(selfId, targetId)
    elseif index == 4 then
        self:BeginEvent(self.script_id)
        local cost_point = self:GetTalentCostPoint(selfId)
        local str = self:ContactArgs("#{TalentMP_20210804_52", self.NpcInfo[NPCName][3], cost_point)
        self:AddText(str .. "}")
        self:AddNumText("Xác nhận", 6, 41)
        self:AddNumText("Trở về", 6, 100)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 41 then
        if self:GetLevel(selfId) < 60 then
            self:Tips(selfId, "Cấp độ chưa đạt cấp 60, không thể học lại Võ đạo.")
            return
        end
        local nIsStudy = self:GetTalentCostPoint(selfId)
        if nIsStudy == 0 then
            self:Tips(selfId, "Ngươi chưa phân phối điểm lĩnh ngộ Võ đạo, không cần học lại.")
            return
        end
        local nMoneySelf = self:GetMoney(selfId) + self:GetMoneyJZ(selfId)
        if nMoneySelf < 100000 then
            self:Tips(selfId, "Không đủ Giao Tử, không học lại võ đạo được.")
            return
        end
        self:LuaFnCostMoneyWithPriority(selfId, 100000)
        self:SelectTalentType(selfId, self.NpcInfo[NPCName][6], self.NpcInfo[NPCName][7])
        self:Tips(selfId, "Hoàn trả thành công" .. nIsStudy .. "điểm lĩnh ngộ võ đạo, xin phân bổ lại.")
    end
end

function wudaoNPC:GetTalenLevel(selfId, nIndex)
    local nTalent = self:MathCilCompute_In(selfId)
    nIndex = nIndex + 1
    return nTalent[nIndex]
end

function wudaoNPC:MsgBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function wudaoNPC:Tips(selfId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function wudaoNPC:ShowPreview(selfId, targetId, index)
    self:BeginUICommand()
    self:UICommand_AddInt(self:GetMenPai(selfId))
    self:UICommand_AddInt(index)
    self:UICommand_AddInt(targetId)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 20210801)
end

function wudaoNPC:Talen(selfId)
    if self:GetLevel(selfId) < 60 then
        self:Tips(selfId, "Chưa đủ cấp 60, không xem võ đạo được.")
        return
    end
    local nTalent = self:GetMissionData(selfId, ScriptGlobal.MD_TALENT)
    if nTalent == 0 then
        self:Tips(selfId, "Chưa chọn võ đạo nào, không xem được thông tin.")
        return
    end
    local HasSect = ""
    local lua_table = self:MathCilCompute_In(selfId)
    for i = 1, #(lua_table) do
        HasSect = HasSect .. lua_table[i] .. "|"
    end
    self:BeginUICommand()
    self:UICommand_AddStr(HasSect)
    self:UICommand_AddInt(nTalent)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 20211030)
end

function wudaoNPC:Lua_HasSect(selfId, ID, int)
    for i = 1, ID do
        if ID <= 11 then break end
        ID = ID - 11
    end
    local nTalentData = self:MathCilCompute_In(selfId)
    if nTalentData[ID] >= 1 then return 1 end
    return 0
end

function wudaoNPC:Lua_GetSectTotalLevel(selfId, Index)
    local nTalentData = self:MathCilCompute_In(selfId)
    local ju_shuju = 0
    for i = 1, 10 do ju_shuju = nTalentData[i] + ju_shuju end
    return ju_shuju
end

function wudaoNPC:MutexSectID(selfId, ndetailID, nTalentData)
    local nTalent = self:GetMissionData(selfId, ScriptGlobal.MD_TALENT)
    local MenPai = self:GetMenPai(selfId)
    local List = self.g_Talent_Studyup_Info[MenPai][nTalent]
    local nInfoTable = {}

    local nIndex = 0
    for i = 2, 5 do
        for j = 1, #(List[i]) do
            if List[i][j] > 0 then
                if List[i][j] == ndetailID then
                    nIndex = i
                    break
                end
            end
        end
    end
    for i, v in pairs(List[nIndex]) do
        if v > 0 and v ~= ndetailID then
            local l = v
            for j = 1, l do if l > 11 then l = l - 11 end end
            if nTalentData[l] > 0 then return 0 end
        end
    end
    return 1
end

function wudaoNPC:AskSectOper(selfId, nIndex, ID)
    if ID < 1 or ID > 198 then
        self:Tips(selfId, "Xin hãy chọn Võ đạo cần tu luyện.")
        return
    end
    if nIndex == 0 then
        local infodetail = self:TBSearch_Index_EQU("DBC_SECT_INFO", ID)
        local totallevel = self:Lua_GetSectTotalLevel(selfId, 0)
        local ndetailID = ID
        for i = 1, ID do
            if ID <= 11 then break end
            ID = ID - 11
        end
        local nTalentData = self:MathCilCompute_In(selfId)
        if nTalentData[ID] >= infodetail["maxlevel"] then
            self:Tips(selfId,
                      "Võ đạo Cấp độ này đã đạt giới hạn, không thể tiếp tục tu luyện.")
            return
        end
        local Mutex = self:MutexSectID(selfId, ndetailID, nTalentData)
        if Mutex == 0 then
            self:Tips(selfId, "Không thể tu luyện cùng lúc.")
            return
        end
        if infodetail["limittype"] > 0 then
            local bhave, level = self:Lua_HasSect(selfId,
                                                  infodetail["limittype"], 0)
            local ju_info = self:TBSearch_Index_EQU("DBC_SECT_INFO",
                                                    infodetail["limittype"])
            if bhave <= 0 or level < infodetail["lparam1"] then
                self:Tips(selfId, string.format("Cần tu %s tới cấp %s",
                                              ju_info["szName"],
                                              infodetail["lparam1"]))
                return
            end
        end
        if infodetail["lparam2"] > 0 then
            if infodetail["lparam2"] > totallevel then
                self:Tips(selfId,
                          string.format(
                              "Cấp tu lưu phái %s hiện cần đạt %s",
                              infodetail["sectname"], infodetail["lparam2"]))
                return
            end
        end
        local nPoint = self:GetMissionData(selfId, ScriptGlobal.MD_TALENTPOINT)
        local nSectLevel = nTalentData[ID] + 1
        if nPoint < infodetail["m_levelinfo"][nSectLevel]["m_point"] then
            self:Tips(selfId,
                      "Số Võ đạo lĩnh ngộ điểm còn lại không đủ, không thể tiếp tục tu luyện.")
            return
        end
        nTalentData[ID] = nTalentData[ID] + 1
        self:MathCilCompute_Out(selfId, nTalentData)
        self:SetMissionData(selfId, ScriptGlobal.MD_TALENTPOINT, nPoint -
                                infodetail["m_levelinfo"][nSectLevel]["m_point"])
        self:Tips(selfId, "Võ đạo tu luyện thành công!")
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 49, 0)
        self:Flush_Sect_LevelUp(selfId, ndetailID)
        return
    end
end

function wudaoNPC:MathCilCompute_In(selfId)
    local nFinalData_1 = self:GetMissionData(selfId, 482)
    local nFinalData_2 = self:GetMissionData(selfId, 483)
    local nTab = {}
    local nValue = {1, 10, 100, 1000, 10000, 100000}
    for i = 1, 6 do
        table.insert(nTab, (math.floor(nFinalData_1 / nValue[i]) % 10))
    end
    for i = 1, 5 do
        table.insert(nTab, (math.floor(nFinalData_2 / nValue[i]) % 10))
    end
    nTab[1] = 1
    return nTab
end

function wudaoNPC:MathCilCompute_Out(selfId, nData)
    local nValue = {1, 10, 100, 1000, 10000, 100000}

    local nFinalData_1, nFinalData_2 = 0, 0
    for i = 1, 6 do nFinalData_1 = nFinalData_1 + nData[i] * nValue[i] end
    for i = 7, 11 do nFinalData_2 = nFinalData_2 + nData[i] * nValue[i - 6] end
    self:SetMissionData(selfId, 482, nFinalData_1)
    self:SetMissionData(selfId, 483, nFinalData_2)
end

function wudaoNPC:LuaFnGetSectInfo(ID)
    local nData = self:TBSearch_Index_EQU1("DBC_SECT_INFO", ID)
end

return wudaoNPC