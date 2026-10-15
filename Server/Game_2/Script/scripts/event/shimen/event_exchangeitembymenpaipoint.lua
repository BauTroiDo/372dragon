local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ScriptGlobal = require "scripts.ScriptGlobal"
local event_exchangeitembymenpaipoint = class("event_exchangeitembymenpaipoint", script_base)
event_exchangeitembymenpaipoint.script_id = 229009
event_exchangeitembymenpaipoint.g_ExchangeItem = "Đổi vật phẩm"
event_exchangeitembymenpaipoint.g_ExchangeTitle = "Đổi danh hiệu"
event_exchangeitembymenpaipoint.g_MissionInfo = "Để khuyến khích các đệ tử đem Môn phái này phát dương quang đại, vi sư đặc biệt chuẩn bị một vài phần thưởng, sử dụng #R400#W điểm cống hiến Môn phái là có thể đổi."
event_exchangeitembymenpaipoint.g_MissionTarget = ""
event_exchangeitembymenpaipoint.g_ContinueInfo = ""
event_exchangeitembymenpaipoint.g_MissionComplete = ""
event_exchangeitembymenpaipoint.g_exchangeitembymenpaipoint_Index = 23
event_exchangeitembymenpaipoint.g_menpainpc_table =
{
    {
        ["menpaiid"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_SHAOLIN,
        ["menpainame"] = "少林",
        ["name"] = "玄慈",
        ["title"] = "少林寺方丈",
        ["x"] = 38,
        ["z"] = 98
    }
    ,
    {
        ["menpaiid"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_MINGJIAO,
        ["menpainame"] = "明教",
        ["name"] = "林世长",
        ["title"] = "明教教主",
        ["x"] = 98,
        ["z"] = 52
    }
    ,
    {
        ["menpaiid"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_GAIBANG,
        ["menpainame"] = "丐帮",
        ["name"] = "宋慈",
        ["title"] = "丐帮长老",
        ["x"] = 91,
        ["z"] = 63
    }
    ,
    {
        ["menpaiid"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_WUDANG,
        ["menpainame"] = "武当",
        ["name"] = "张玄素",
        ["title"] = "Chưởng môn phái Võ Đang",
        ["x"] = 73,
        ["z"] = 82
    }
    ,
    {
        ["menpaiid"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_EMEI,
        ["menpainame"] = "Nga Mi",
        ["name"] = "孟青青",
        ["title"] = "Chưởng môn Nga My phái",
        ["x"] = 96,
        ["z"] = 73
    }
    ,
    {
        ["menpaiid"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_DALI,
        ["menpainame"] = "天龙",
        ["name"] = "本因",
        ["title"] = "Phương trượng Thiên Long Tự",
        ["x"] = 96,
        ["z"] = 66
    }
    ,
    {
        ["menpaiid"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_XINGXIU,
        ["menpainame"] = "星宿",
        ["name"] = "丁春秋",
        ["title"] = "星宿派掌门",
        ["x"] = 142,
        ["z"] = 55
    }
    ,
    {
        ["menpaiid"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_TIANSHAN,
        ["menpainame"] = "天山",
        ["name"] = "梅剑",
        ["title"] = "Đại sư tỷ Thiên Sơn phái",
        ["x"] = 91,
        ["z"] = 44
    }
    ,
    {
        ["menpaiid"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_XIAOYAO,
        ["menpainame"] = "逍遥",
        ["name"] = "苏星河",
        ["title"] = "逍遥派代掌门",
        ["x"] = 125,
        ["z"] = 144
    }
    ,
    {
        ["menpaiid"] = ScriptGlobal.MP_MANTUO,
        ["menpainame"] = "曼陀山庄",
        ["name"] = "王夫人",
        ["title"] = "曼陀山庄庄主",
        ["x"] = 140,
        ["z"] = 75
    }
}
event_exchangeitembymenpaipoint.g_MaleTitleInfoA = {
    {
        ["tlvl"] = 1,
        ["mpp"] = 0,
        ["slt"] = 145,
        ["mjt"] = 153,
        ["gbt"] = 161,
        ["wdt"] = 169,
        ["emt"] = 177,
        ["xxt"] = 185,
        ["tlt"] = 193,
        ["tst"] = 201,
        ["xyt"] = 209,
        ["mtt"] = 376
    }
    ,
    {
        ["tlvl"] = 2,
        ["mpp"] = 1000,
        ["slt"] = 146,
        ["mjt"] = 154,
        ["gbt"] = 162,
        ["wdt"] = 170,
        ["emt"] = 178,
        ["xxt"] = 186,
        ["tlt"] = 194,
        ["tst"] = 202,
        ["xyt"] = 210,
        ["mtt"] = 377
    }
    ,
    {
        ["tlvl"] = 3,
        ["mpp"] = 2500,
        ["slt"] = 147,
        ["mjt"] = 155,
        ["gbt"] = 163,
        ["wdt"] = 171,
        ["emt"] = 179,
        ["xxt"] = 187,
        ["tlt"] = 195,
        ["tst"] = 203,
        ["xyt"] = 211,
        ["mtt"] = 378
    }
    ,
    {
        ["tlvl"] = 4,
        ["mpp"] = 5000,
        ["slt"] = 148,
        ["mjt"] = 156,
        ["gbt"] = 164,
        ["wdt"] = 172,
        ["emt"] = 180,
        ["xxt"] = 188,
        ["tlt"] = 196,
        ["tst"] = 204,
        ["xyt"] = 212,
        ["mtt"] = 379
    }
}
event_exchangeitembymenpaipoint.g_femaleTitleInfoA = {
    {
        ["tlvl"] = 1,
        ["mpp"] = 0,
        ["slt"] = 149,
        ["mjt"] = 157,
        ["gbt"] = 165,
        ["wdt"] = 173,
        ["emt"] = 181,
        ["xxt"] = 189,
        ["tlt"] = 197,
        ["tst"] = 205,
        ["xyt"] = 213,
        ["mtt"] = 380
    }
    ,
    {
        ["tlvl"] = 2,
        ["mpp"] = 1000,
        ["slt"] = 150,
        ["mjt"] = 158,
        ["gbt"] = 166,
        ["wdt"] = 174,
        ["emt"] = 182,
        ["xxt"] = 190,
        ["tlt"] = 198,
        ["tst"] = 206,
        ["xyt"] = 214,
        ["mtt"] = 381
    }
    ,
    {
        ["tlvl"] = 3,
        ["mpp"] = 2500,
        ["slt"] = 151,
        ["mjt"] = 159,
        ["gbt"] = 167,
        ["wdt"] = 175,
        ["emt"] = 183,
        ["xxt"] = 191,
        ["tlt"] = 199,
        ["tst"] = 207,
        ["xyt"] = 215,
        ["mtt"] = 382
    }
    ,
    {
        ["tlvl"] = 4,
        ["mpp"] = 5000,
        ["slt"] = 152,
        ["mjt"] = 160,
        ["gbt"] = 168,
        ["wdt"] = 176,
        ["emt"] = 184,
        ["xxt"] = 192,
        ["tlt"] = 200,
        ["tst"] = 208,
        ["xyt"] = 216,
        ["mtt"] = 383
    }
}
event_exchangeitembymenpaipoint.g_MaleTitleInfo = {
    {
        ["tlvl"] = 1,
        ["mpp"] = 0,
        ["slt"] = "Thiếu Lâm hiệp sĩ",
        ["mjt"] = "Minh Giáo hiệp sĩ",
        ["gbt"] = "Cái Bang hiệp sĩ",
        ["wdt"] = "Võ Đang hiệp sĩ",
        ["emt"] = "Hiệp Sĩ Nga My",
        ["xxt"] = "Tinh Túc hiệp sĩ",
        ["tlt"] = "Thiên Long hiệp sĩ",
        ["tst"] = "Thiên Sơn Hiệp Sĩ",
        ["xyt"] = "Tiêu Dao hiệp sĩ",
        ["mtt"] = "Hiệp Sĩ Mạn Đà"
    }
    ,
    {
        ["tlvl"] = 2,
        ["mpp"] = 1000,
        ["slt"] = "Hộ pháp áo xám",
        ["mjt"] = "Thị Hỏa Hiệp Sĩ",
        ["gbt"] = "Thanh Liên Đệ Tử",
        ["wdt"] = "Thanh Minh Cư Sĩ",
        ["emt"] = "Thanh Phong Cư Sĩ",
        ["xxt"] = "Hành Ôn Lang Quân",
        ["tlt"] = "Tàng Kinh hiệp sĩ",
        ["tst"] = "Dương Thiên Bộ Chúng",
        ["xyt"] = "Phủ Cầm cư sĩ",
        ["mtt"] = "Cầm Sư Ngưng Huy"
    }
    ,
    {
        ["tlvl"] = 3,
        ["mpp"] = 2500,
        ["slt"] = "Kim Thân La Hán",
        ["mjt"] = "Hộ Giáo Pháp Vương",
        ["gbt"] = "玄武长老",
        ["wdt"] = "Vô Vi Chân Nhân",
        ["emt"] = "Ngọc Long hiệp sĩ",
        ["xxt"] = "Thôi Mệnh Phán Quan",
        ["tlt"] = "Sùng Thánh Thiên Sư",
        ["tst"] = "Thiên Sơn Thương Ưng",
        ["xyt"] = "Lạc Thần hiệp sĩ",
        ["mtt"] = "Cầm Tông Phất Hiểu"
    }
    ,
    {
        ["tlvl"] = 4,
        ["mpp"] = 5000,
        ["slt"] = "Địa Tạng Bồ Tát",
        ["mjt"] = "Quang Minh Thần Sứ",
        ["gbt"] = "Chưởng Bổng Long Đầu",
        ["wdt"] = "Võ Đang Thiên Tôn",
        ["emt"] = "Nga My tiên nhân",
        ["xxt"] = "Độc Thủ Y Tiên",
        ["tlt"] = "Thiên Nam Long Vương",
        ["tst"] = "Hỗn Nguyên Sơn Thần",
        ["xyt"] = "Tiêu Dao Thần Long",
        ["mtt"] = "Cầm Tiên Độ Tình"
    }
}
event_exchangeitembymenpaipoint.g_femaleTitleInfo = {
    {
        ["tlvl"] = 1,
        ["mpp"] = 0,
        ["slt"] = "Thiếu Lâm hiệp nữ",
        ["mjt"] = "Minh Giáo Hiệp Nữ",
        ["gbt"] = "Cái Bang hiệp nữ",
        ["wdt"] = "Võ Đang Hiệp Nữ",
        ["emt"] = "Nga My hiệp nữ",
        ["xxt"] = "Tinh Túc Hiệp Nữ",
        ["tlt"] = "Thiên Long hiệp nữ",
        ["tst"] = "Thiên Sơn Hiệp Nữ",
        ["xyt"] = "Tiêu Dao hiệp nữ",
        ["mtt"] = "Hiệp Nữ Mạn Đà"
    }
    ,
    {
        ["tlvl"] = 2,
        ["mpp"] = 1000,
        ["slt"] = "Bạch Y Thị Giả",
        ["mjt"] = "Thị Hỏa Hiệp Nữ",
        ["gbt"] = "Đệ tử Bạch Liên",
        ["wdt"] = "Bạch Vân cư sĩ",
        ["emt"] = "Minh Nguyệt cư sĩ",
        ["xxt"] = "Hành Ôn Nương Tử",
        ["tlt"] = "Tàng Kinh hiệp nữ",
        ["tst"] = "Hạo Thiên Bộ Chúng",
        ["xyt"] = "Thì Hoa cư sĩ",
        ["mtt"] = "Cầm Sư Linh Vận"
    }
    ,
    {
        ["tlvl"] = 3,
        ["mpp"] = 2500,
        ["slt"] = "Độ Thế Quan Âm",
        ["mjt"] = "Hộ Giáo Tán Nhân",
        ["gbt"] = "Trưởng lão Chu Tước",
        ["wdt"] = "Thanh Tịnh tán nhân",
        ["emt"] = "Kim Phụng hiệp nữ",
        ["xxt"] = "Đoạt Mệnh Dạ Xoa",
        ["tlt"] = "Sùng Thánh Thiên Nữ",
        ["tst"] = "Thiên Sơn Tuyết Điêu",
        ["xyt"] = "Lăng Ba Hiệp Nữ",
        ["mtt"] = "Cầm Tông Thanh Chiếu"
    }
    ,
    {
        ["tlvl"] = 4,
        ["mpp"] = 5000,
        ["slt"] = "Già Lam Bồ Tát",
        ["mjt"] = "光明圣女",
        ["gbt"] = "Chưởng Bát Long Nữ",
        ["wdt"] = "Tiên Tử Võ Đang",
        ["emt"] = "Nga My tiên tử",
        ["xxt"] = "Độc Thủ Dược Vương",
        ["tlt"] = "Thiên Nam Long Nữ",
        ["tst"] = "Hỗn Nguyên Hoa Thần",
        ["xyt"] = "Thánh nữ Tiêu Dao",
        ["mtt"] = "Cầm Tiên Quan Tình"
    }
}
event_exchangeitembymenpaipoint.g_shimentitle_bonusitem = {
    { ["menpaiid"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_SHAOLIN, ["bonusItem"] = 10113004 }
    , { ["menpaiid"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_MINGJIAO, ["bonusItem"] = 10113004 }
, { ["menpaiid"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_GAIBANG, ["bonusItem"] = 10113004 }
, { ["menpaiid"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_WUDANG, ["bonusItem"] = 10113004 }
, { ["menpaiid"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_EMEI, ["bonusItem"] = 10113004 }
, { ["menpaiid"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_DALI, ["bonusItem"] = 10113004 }
, { ["menpaiid"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_XINGXIU, ["bonusItem"] = 10113004 }
, { ["menpaiid"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_TIANSHAN, ["bonusItem"] = 10113004 }
, { ["menpaiid"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_XIAOYAO, ["bonusItem"] = 10113004 }
, { ["menpaiid"] = ScriptGlobal.MP_MANTUO, ["bonusItem"] = 10113004 }
}
function event_exchangeitembymenpaipoint:OnDefaultEvent(selfId, targetId, arg, index)
    for i, v in pairs(self.g_menpainpc_table) do
        if v["name"] == self:GetName(targetId) then
            if v["menpaiid"] == self:GetMenPai(selfId) then
                if 10 <= index and index <= 14 then
                    self:ExchangeTitleBymenpaipoint(selfId, targetId, index - 10)
                elseif 7 == index then
                    self:ExchangeItemBymenpaipoint(selfId, targetId)
                    break
                elseif 8 == index then
                    self:AddExchangeTitleList(selfId, targetId)
                    break
                end
            else
                local str = "Ngươi không phải đệ tử bản Môn phái, ta chỉ vì đệ tử bản Môn phái phục vụ."
                self:BeginEvent(self.script_id)
                self:AddText(str)
                self:EndEvent()
                self:DispatchMissionTips(selfId)
                self:Msg2Player(selfId, str, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
            end
        end
    end
end

function event_exchangeitembymenpaipoint:OnEnumerate(caller, selfId, targetId, arg, index)
    self:AddNumText(self.g_ExchangeItem, 3, 7)
    self:AddNumText(self.g_ExchangeTitle, 3, 8)
end

function event_exchangeitembymenpaipoint:ExchangeItemBymenpaipointFn(selfId, targetId, needPoint)
    if (needPoint < 0) then
        return
    end
    local menpaipoint = self:GetHumanMenpaiPoint(selfId)
    if menpaipoint < 400 then
        local str = "Sư môn cống hiến độ của ngươi hiện tại là" .. self:tostring(menpaipoint) .. ", vẫn chưa đủ 400 điểm, hãy cố gắng hơn nữa đi."
        self:BeginEvent(self.script_id)
        self:AddText(str)
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        self:Msg2Player(selfId, str, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    else
        local nItemId, strItemName, strItemDesc = self:GetOneMissionItem(self.g_exchangeitembymenpaipoint_Index)
        self:BeginAddItem()
        self:AddItem(nItemId, 1)
        local ret = self:EndAddItem(selfId)
        if ret <= 0 then
            self:BeginEvent(self.script_id)
            self:AddText("Túi của ngươi đã đầy, không thể đổi!")
            self:EndEvent()
            self:DispatchMissionTips(selfId)
        else
            self:AddItemListToHuman(selfId)
            self:SetHumanMenpaiPoint(selfId, menpaipoint - 400)
            local str = string.format("Khấu trừ 400 điểm Môn phái cống hiến độ, ngài nhận được %s.", strItemName)
            self:Msg2Player(selfId, str, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
            str = string.format("Ngươi đã nhận được %s.", strItemName)
            self:BeginEvent(self.script_id)
            self:AddText(str)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
        end
    end
end

function event_exchangeitembymenpaipoint:ExchangeItemBymenpaipoint(selfId, targetId)
    self:BeginUICommand()
    self:UICommand_AddInt(self.script_id)
    self:UICommand_AddInt(targetId)
    self:UICommand_AddStr("ExchangeItemBymenpaipointFn")
    self:UICommand_AddStr(self.g_MissionInfo)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 24)
end

function event_exchangeitembymenpaipoint:GetCurShimenTitleLevel(menpai, title)
    local titlelevel = 0
    if menpai == define.MENPAI_ATTRIBUTE.MATTRIBUTE_SHAOLIN then
        for i = 1, 4 do
            if title == self.g_MaleTitleInfo[i]["slt"] then
                titlelevel = self.g_MaleTitleInfo[i]["tlvl"]
                return titlelevel
            end
            if title == self.g_femaleTitleInfo[i]["slt"] then
                titlelevel = self.g_femaleTitleInfo[i]["tlvl"]
                return titlelevel
            end
        end
    elseif menpai == define.MENPAI_ATTRIBUTE.MATTRIBUTE_MINGJIAO then
        for i = 1, 4 do
            if title == self.g_MaleTitleInfo[i]["mjt"] then
                titlelevel = self.g_MaleTitleInfo[i]["tlvl"]
                return titlelevel
            end
            if title == self.g_femaleTitleInfo[i]["mjt"] then
                titlelevel = self.g_femaleTitleInfo[i]["tlvl"]
                return titlelevel
            end
        end
    elseif menpai == define.MENPAI_ATTRIBUTE.MATTRIBUTE_GAIBANG then
        for i = 1, 4 do
            if title == self.g_MaleTitleInfo[i]["gbt"] then
                titlelevel = self.g_MaleTitleInfo[i]["tlvl"]
                return titlelevel
            end
            if title == self.g_femaleTitleInfo[i]["gbt"] then
                titlelevel = self.g_femaleTitleInfo[i]["tlvl"]
                return titlelevel
            end
        end
    elseif menpai == define.MENPAI_ATTRIBUTE.MATTRIBUTE_WUDANG then
        for i = 1, 4 do
            if title == self.g_MaleTitleInfo[i]["wdt"] then
                titlelevel = self.g_MaleTitleInfo[i]["tlvl"]
                return titlelevel
            end
            if title == self.g_femaleTitleInfo[i]["wdt"] then
                titlelevel = self.g_femaleTitleInfo[i]["tlvl"]
                return titlelevel
            end
        end
    elseif menpai == define.MENPAI_ATTRIBUTE.MATTRIBUTE_EMEI then
        for i = 1, 4 do
            if title == self.g_MaleTitleInfo[i]["emt"] then
                titlelevel = self.g_MaleTitleInfo[i]["tlvl"]
                return titlelevel
            end
            if title == self.g_femaleTitleInfo[i]["emt"] then
                titlelevel = self.g_femaleTitleInfo[i]["tlvl"]
                return titlelevel
            end
        end
    elseif menpai == define.MENPAI_ATTRIBUTE.MATTRIBUTE_DALI then
        for i = 1, 4 do
            if title == self.g_MaleTitleInfo[i]["tlt"] then
                titlelevel = self.g_MaleTitleInfo[i]["tlvl"]
                return titlelevel
            end
            if title == self.g_femaleTitleInfo[i]["tlt"] then
                titlelevel = self.g_femaleTitleInfo[i]["tlvl"]
                return titlelevel
            end
        end
    elseif menpai == define.MENPAI_ATTRIBUTE.MATTRIBUTE_XINGXIU then
        for i = 1, 4 do
            if title == self.g_MaleTitleInfo[i]["xxt"] then
                titlelevel = self.g_MaleTitleInfo[i]["tlvl"]
                return titlelevel
            end
            if title == self.g_femaleTitleInfo[i]["xxt"] then
                titlelevel = self.g_femaleTitleInfo[i]["tlvl"]
                return titlelevel
            end
        end
    elseif menpai == define.MENPAI_ATTRIBUTE.MATTRIBUTE_TIANSHAN then
        for i = 1, 4 do
            if title == self.g_MaleTitleInfo[i]["tst"] then
                titlelevel = self.g_MaleTitleInfo[i]["tlvl"]
                return titlelevel
            end
            if title == self.g_femaleTitleInfo[i]["tst"] then
                titlelevel = self.g_femaleTitleInfo[i]["tlvl"]
                return titlelevel
            end
        end
    elseif menpai == define.MENPAI_ATTRIBUTE.MATTRIBUTE_XIAOYAO then
        for i = 1, 4 do
            if title == self.g_MaleTitleInfo[i]["xyt"] then
                titlelevel = self.g_MaleTitleInfo[i]["tlvl"]
                return titlelevel
            end
            if title == self.g_femaleTitleInfo[i]["xyt"] then
                titlelevel = self.g_femaleTitleInfo[i]["tlvl"]
                return titlelevel
            end
        end
    elseif menpai == ScriptGlobal.MP_MANTUO then
        for i = 1, 4 do
            if title == self.g_MaleTitleInfo[i]["mtt"] then
                titlelevel = self.g_MaleTitleInfo[i]["tlvl"]
                return titlelevel
            end
            if title == self.g_femaleTitleInfo[i]["mtt"] then
                titlelevel = self.g_femaleTitleInfo[i]["tlvl"]
                return titlelevel
            end
        end
    end
    return titlelevel
end

function event_exchangeitembymenpaipoint:GetSelectedTitle(menpai, titleinfo, level)
    if level < 1 or level > 4 then
        return 0
    end
    local title = ""
    if menpai == define.MENPAI_ATTRIBUTE.MATTRIBUTE_SHAOLIN then
        title = titleinfo[level]["slt"]
    elseif menpai == define.MENPAI_ATTRIBUTE.MATTRIBUTE_MINGJIAO then
        title = titleinfo[level]["mjt"]
    elseif menpai == define.MENPAI_ATTRIBUTE.MATTRIBUTE_GAIBANG then
        title = titleinfo[level]["gbt"]
    elseif menpai == define.MENPAI_ATTRIBUTE.MATTRIBUTE_WUDANG then
        title = titleinfo[level]["wdt"]
    elseif menpai == define.MENPAI_ATTRIBUTE.MATTRIBUTE_EMEI then
        title = titleinfo[level]["emt"]
    elseif menpai == define.MENPAI_ATTRIBUTE.MATTRIBUTE_DALI then
        title = titleinfo[level]["tlt"]
    elseif menpai == define.MENPAI_ATTRIBUTE.MATTRIBUTE_XINGXIU then
        title = titleinfo[level]["xxt"]
    elseif menpai == define.MENPAI_ATTRIBUTE.MATTRIBUTE_TIANSHAN then
        title = titleinfo[level]["tst"]
    elseif menpai == define.MENPAI_ATTRIBUTE.MATTRIBUTE_XIAOYAO then
        title = titleinfo[level]["xyt"]
    elseif menpai == ScriptGlobal.MP_MANTUO then
        title = titleinfo[level]["mtt"]
    end
    return titleinfo[level]["tlvl"]
end

function event_exchangeitembymenpaipoint:AddExchangeTitleList(selfId, targetId)
    local level = self:GetLevel(selfId)
    local menpai = self:GetMenPai(selfId)
    local titleinfo
    local sex = self:GetSex(selfId)
    if 1 == sex then
        titleinfo = self.g_MaleTitleInfo
    elseif 0 == sex then
        titleinfo = self.g_femaleTitleInfo
    end
    local step = 10
    self:BeginEvent(self.script_id)
    if menpai == define.MENPAI_ATTRIBUTE.MATTRIBUTE_SHAOLIN then
        for i = 1, 4 do
            local seltitlelvl, needpoint, seltitle = self:GetSelectedTitle(menpai, titleinfo, i)
            local str = seltitle .. "(Yêu cầu" .. needpoint .. "Điểm cống hiến Sư môn)"
            self:AddNumText(str, 3, i + step)
        end
    elseif menpai == define.MENPAI_ATTRIBUTE.MATTRIBUTE_MINGJIAO then
        for i = 1, 4 do
            local seltitlelvl, needpoint, seltitle = self:GetSelectedTitle(menpai, titleinfo, i)
            local str = seltitle .. "(Yêu cầu" .. needpoint .. "Điểm cống hiến Sư môn)"
            self:AddNumText(str, 3, i + step)
        end
    elseif menpai == define.MENPAI_ATTRIBUTE.MATTRIBUTE_GAIBANG then
        for i = 1, 4 do
            local seltitlelvl, needpoint, seltitle = self:GetSelectedTitle(menpai, titleinfo, i)
            local str = seltitle .. "(Yêu cầu" .. needpoint .. "Điểm cống hiến Sư môn)"
            self:AddNumText(str, 3, i + step)
        end
    elseif menpai == define.MENPAI_ATTRIBUTE.MATTRIBUTE_WUDANG then
        for i = 1, 4 do
            local seltitlelvl, needpoint, seltitle = self:GetSelectedTitle(menpai, titleinfo, i)
            local str = seltitle .. "(Yêu cầu" .. needpoint .. "Điểm cống hiến Sư môn)"
            self:AddNumText(str, 3, i + step)
        end
    elseif menpai == define.MENPAI_ATTRIBUTE.MATTRIBUTE_EMEI then
        for i = 1, 4 do
            local seltitlelvl, needpoint, seltitle = self:GetSelectedTitle(menpai, titleinfo, i)
            local str = seltitle .. "(Yêu cầu" .. needpoint .. "Điểm cống hiến Sư môn)"
            self:AddNumText(str, 3, i + step)
        end
    elseif menpai == define.MENPAI_ATTRIBUTE.MATTRIBUTE_DALI then
        for i = 1, 4 do
            local seltitlelvl, needpoint, seltitle = self:GetSelectedTitle(menpai, titleinfo, i)
            local str = seltitle .. "(Yêu cầu" .. needpoint .. "Điểm cống hiến Sư môn)"
            self:AddNumText(str, 3, i + step)
        end
    elseif menpai == define.MENPAI_ATTRIBUTE.MATTRIBUTE_XINGXIU then
        for i = 1, 4 do
            local seltitlelvl, needpoint, seltitle = self:GetSelectedTitle(menpai, titleinfo, i)
            local str = seltitle .. "(Yêu cầu" .. needpoint .. "Điểm cống hiến Sư môn)"
            self:AddNumText(str, 3, i + step)
        end
    elseif menpai == define.MENPAI_ATTRIBUTE.MATTRIBUTE_TIANSHAN then
        for i = 1, 4 do
            local seltitlelvl, needpoint, seltitle = self:GetSelectedTitle(menpai, titleinfo, i)
            local str = seltitle .. "(Yêu cầu" .. needpoint .. "Điểm cống hiến Sư môn)"
            self:AddNumText(str, 3, i + step)
        end
    elseif menpai == define.MENPAI_ATTRIBUTE.MATTRIBUTE_XIAOYAO then
        for i = 1, 4 do
            local seltitlelvl, needpoint, seltitle = self:GetSelectedTitle(menpai, titleinfo, i)
            local str = seltitle .. "(Yêu cầu" .. needpoint .. "Điểm cống hiến Sư môn)"
            self:AddNumText(str, 3, i + step)
        end
    elseif menpai == ScriptGlobal.MP_MANTUO then
        for i = 1, 4 do
            local seltitlelvl, needpoint, seltitle = self:GetSelectedTitle(menpai, titleinfo, i)
            local str = seltitle .. "(Yêu cầu" .. needpoint .. "Điểm cống hiến Sư môn)"
            self:AddNumText(str, 3, i + step)
        end
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function event_exchangeitembymenpaipoint:GetShimenTitle_BonusItem(selfId)
    local menpai = self:GetMenPai(selfId)
    for i, v in pairs(self.g_shimentitle_bonusitem) do
        if v["menpaiid"] == menpai then
            return v["bonusItem"]
        end
    end
    return 0
end

function event_exchangeitembymenpaipoint:ExchangeTitleBymenpaipoint(selfId, targetId, level)
    local titleinfo, titleIdInfo
    local menpai = self:GetMenPai(selfId)
    local sex = self:GetSex(selfId)
    if 1 == sex then
        titleinfo = self.g_MaleTitleInfo
        titleIdInfo = self.g_MaleTitleInfoA
    elseif 0 == sex then
        titleinfo = self.g_femaleTitleInfo
        titleIdInfo = self.g_femaleTitleInfoA
    end
    local title = self:GetShimenTitle(selfId)
    local seltitlelvl, needpoint, seltitle = self:GetSelectedTitle(menpai, titleinfo, level)
    local seltitlelvlEx, needpointEx, seltitleEx = self:GetSelectedTitle(menpai, titleIdInfo, level)
    local curtitlelvl = self:GetCurShimenTitleLevel(menpai, title)
    local str
    if seltitlelvl == curtitlelvl or self:GetCurTitle(selfId) == seltitleEx then
        str = "Ngươi đã sở hữu danh hiệu này, không Yêu cầu đổi."
    elseif seltitlelvl > curtitlelvl then
        local menpaipoint = self:GetHumanMenpaiPoint(selfId)
        if needpoint <= menpaipoint then
            if seltitlelvl == 2 then
                self:BeginAddItem()
                self:AddItem(self:GetShimenTitle_BonusItem(selfId), 1)
                local ret = self:EndAddItem(selfId)
                if ret then
                    self:AddItemListToHuman(selfId)
                    str = "Chúc mừng ngươi nhận được #Y" .. seltitle .. "#Wcủadanh hiệu, mong con tiếp tục nỗ lực vì sự phát dương quang đại bổn môn. Đây là một bộ Y phục bổn môn, xem như là phần thưởng của vi sư cho những vất vả của con trong thời gian qua."
                    self:LuaFnSetCharTitleNewData(selfId, seltitleEx, 1)
                    self:SetHumanMenpaiPoint(selfId, menpaipoint - needpoint)
                else
                    str = "Ba lô của ngươi đã đầy, sư phụ ta chuẩn bị tặng chút quà nhỏ cho ngươi, hãy chỉnh lý lại ba lô rồi đến tìm ta."
                end
            else
                str = "Chúc mừng ngươi nhận được #Y" .. seltitle .. "#Wdanh hiệu, hy vọng con tiếp tục nỗ lực vì sự hưng thịnh của bản môn."
                self:LuaFnSetCharTitleNewData(selfId, seltitleEx, 1)
                self:SetHumanMenpaiPoint(selfId, menpaipoint - needpoint)
            end
        else
            str = "Điểm cống hiến Môn phái của con không đủ, không thể đổi."
        end
    end
    self:BeginEvent(self.script_id)
    self:AddText(str)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function event_exchangeitembymenpaipoint:Tips(selfId, str)
    self:BeginEvent(self.script_id)
    self:AddText(str)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return event_exchangeitembymenpaipoint
