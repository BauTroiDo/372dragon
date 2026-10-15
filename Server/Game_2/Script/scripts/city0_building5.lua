local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local city0_building5 = class("city0_building5", script_base)
city0_building5.script_id = 805012
city0_building5.g_BuildingID6 = 3
city0_building5.g_TicketItemIdx = 40002000
city0_building5.g_OutDateTicketItemIdx = 40000000
city0_building5.g_MerchandiseRate = 1.5
city0_building5.g_GuildRate = 1.00
city0_building5.g_PlayerRate = 1.20
city0_building5.g_TicketTakeTimes = 8
city0_building5.g_BaseTotalTicketTakeTimes = 200
city0_building5.g_TicketTakeTimesBonusPerLvl = 25
city0_building5.g_TicketDecValue = 136
city0_building5.g_TicketIncValue = 680
city0_building5.g_TicketDecRate = 1.0
city0_building5.g_TicketIncRate = 1.0
city0_building5.g_GuildBoomIndex = 18
city0_building5.g_GuildMoneyLimit = 10000

function city0_building5:OnDefaultEvent(selfId, targetId)
    local guildid = self:GetHumanGuildID(selfId)
    local cityguildid = self:GetCityGuildID(selfId)
    local strText
    if (guildid ~= cityguildid) then
        self:BeginEvent(self.script_id)
        strText = "    Nơi đây là trọng địa tài vụ của bang, xin chớ nán lại. Tại hạ còn trọng trách trên vai, cũng không tiện tiếp đãi."
        self:AddText(strText)
        self:AddNumText("Điếm Thương nhân", 7, 5)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    self:BeginEvent(self.script_id)
    strText = "    Tại hạ phụ trách tài sản tiền tài của bản bang, tiền bạc là mạch mệnh của mọi việc, nếu đến ta đây kiếm nhiều việc mà làm, thì với bang với ngươi đều có chỗ tốt."
    self:AddText(strText)
    self:AddNumText("Lĩnh Ngân phiếu", 6, 2)
    self:AddNumText("Giao trả Ngân phiếu", 6, 3)
    self:AddNumText("Tửu quán tiền trang", 11, 4)
    self:AddNumText("Điếm Thương nhân", 7, 5)
    self:AddNumText("Tuyến đường Thương nghiệp", 12, 6)
    self:AddNumText("Nộp Ngân phiếu quá hạn", 6, 7)
    self:AddNumText("Lĩnh lương", 7, 8)
    self:CallScriptFunction(define.CITY_BUILDING_ABILITY_SCRIPT,  "AddCityLifeAbilityOpt", selfId, self.script_id, self.g_BuildingID6, 888)
    self:AddNumText("#{BPZJ_0801014_001}", 6, 11)
    self:AddNumText("#{BPZJ_0801014_002}", 11, 12)
    local Guildpos = self:GetGuildPos(selfId)
    if self:IsManager(Guildpos) == 1 then
        self:AddNumText("Lĩnh phúc lợi người quản lý bang hội", 7, 9)
        self:AddNumText("Về phúc lợi của người quản lý bang phái", 11, 10)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function city0_building5:DrawPay(selfId)
    local msg
    if self:GetLevel(selfId) < 40 then
        msg = string.format("Cấp độ của ngài chưa đạt cấp 40, nên không thể lĩnh bổng lộc.")
        self:NotifyTips(selfId, msg)
        return 0
    end
    local nFactionJoinTime = self:GetFactionJoinTime(selfId)
    local nTimeCur = self:LuaFnGetCurrentTime()
    local nTimeDelta = nTimeCur - nFactionJoinTime
    if nTimeDelta < 7 * 24 * 60 * 60 then
        msg = string.format("Thời gian gia nhập bang của ngài chưa đủ 1 tuần, không thể lĩnh bổng lộc.")
        self:NotifyTips(selfId, msg)
        return 0
    end
    local nWeekCur = self:GetWeekTime()
    local nCaoYunTime = self:GetMissionData(selfId, ScriptGlobal.MD_CAOYUN_COMPLETE_TIME)
    local nCaoYunNum = (nCaoYunTime % 1000)
    local nWeek = math.floor(nCaoYunTime / 1000)
    local Guildpos = self:GetGuildPos(selfId)
    if ((Guildpos ~= define.GUILD_POSITION_CHIEFTAIN) and
        (Guildpos ~= define.GUILD_POSITION_ASS_CHIEFTAIN)) then
        if nCaoYunNum < 2 or nWeek ~= nWeekCur then
            msg = string.format("Số lần chạy thương của ngài trong tuần này chưa đủ 2 lần.")
            self:NotifyTips(selfId, msg)
            return 0
        end
    end
    local nFactionAllTimeNum = self:CityGetAttr(selfId, 14)
    local nFactionAllNum = nFactionAllTimeNum % 1000
    local nFactionWeek = math.floor(nFactionAllTimeNum / 1000)
    if nWeekCur ~= nFactionWeek then
        nFactionAllNum = 0
        nFactionAllTimeNum = nWeekCur * 1000 + nFactionAllNum
        local canset = self:CanCitySetAttr(selfId, 14)
        self:CitySetAttr(selfId, 14, nFactionAllTimeNum)
    end
    if nFactionAllNum >= 200 then
        msg = string.format("Xin lỗi, số lượng lĩnh lương của bổn bang trong tuần này đã đạt giới hạn.")
        self:NotifyTips(selfId, msg)
        return 0
    end
    if self:CityGetMaintainStatus(selfId) == 1 then
        msg = string.format("Bổn bang hiện đang ở Trạng thái bảo trì thấp, không thể lĩnh lương!")
        self:NotifyTips(selfId, msg)
        return 0
    end
    local nDrawPayTimeLast = self:GetMissionData(selfId, ScriptGlobal.MD_DRAWPAY_TIME)
    local nNum = nDrawPayTimeLast % 1000
    local isPosLongEnough = self:IsGuildPosLongEnough(selfId)
    local minusContri = 30
    if (isPosLongEnough == 1) then
        if (Guildpos == define.GUILD_POSITION_ASS_CHIEFTAIN) then
            minusContri = 15
        elseif (Guildpos == define.GUILD_POSITION_CHIEFTAIN) then
            minusContri = 0
        end
    end
    if nWeekCur ~= nWeek then
        local nContribPoint = self:CityGetAttr(selfId, ScriptGlobal.GUILD_CONTRIB_POINT)
        nContribPoint = nContribPoint - minusContri
        if nContribPoint < 0 then
            msg = string.format("Cống hiến bang của ngài không đủ, vì vậy không thể lĩnh lương.")
            self:NotifyTips(selfId, msg)
            return 0
        end
        local guildLevel = self:GetGuildLevel(selfId)
        local goldGet = 0
        if guildLevel == 1 then
            goldGet = 5 * 10000
        elseif guildLevel == 2 then
            goldGet = 6 * 10000
        elseif guildLevel == 3 then
            goldGet = 7 * 10000
        elseif guildLevel == 4 then
            goldGet = 8 * 10000
        elseif guildLevel == 5 then
            goldGet = 9 * 10000
        end
        local GuildMoney = self:CityGetAttr(selfId, ScriptGlobal.GUILD_MONEY)
        if GuildMoney < goldGet then
            self:NotifyTips(selfId, "Quỹ bang phái không đủ, không thể lĩnh ra.")
            return 0
        end
        self:CityChangeAttr(selfId, ScriptGlobal.GUILD_MONEY, (-1) * goldGet)
        nFactionAllNum = nFactionAllNum + 1
        nFactionAllTimeNum = nWeekCur * 1000 + nFactionAllNum
        self:CanCitySetAttr(selfId, 14)
        self:CitySetAttr(selfId, 14, nFactionAllTimeNum)
        if (isPosLongEnough == 1) then
            if (Guildpos == define.GUILD_POSITION_CHIEFTAIN) then
                self:NotifyTips(selfId, "Ngài đảm nhiệm chức bang chủ vượt quá một tuần, lần lĩnh lương này không tiêu hao cống hiến bang.")
            elseif (Guildpos == define.GUILD_POSITION_ASS_CHIEFTAIN) then
                self:NotifyTips(selfId, "Ngài đảm nhiệm chức phó bang chủ vượt quá một tuần, lần lĩnh lương này tiêu hao cống hiến bang giảm một nửa.")
            end
        end
        self:CityChangeAttr(selfId, ScriptGlobal.GUILD_CONTRIB_POINT, (-1) * minusContri)
        local guildid = self:GetHumanGuildID(selfId)
        self:LuaFnAuditPlayerGetGuildWage(selfId, guildid, goldGet)
        nNum = 1
        nDrawPayTimeLast = nWeekCur * 1000 + nNum
        self:SetMissionData(selfId, ScriptGlobal.MD_DRAWPAY_TIME, nDrawPayTimeLast)
        self:AddMoney(selfId, goldGet)
        local PlayerName = self:GetName(selfId)
        local sMessage = string.format("@*;SrvMsg;GLD:#Y#{_INFOUSR%s}#cffff00 tại Kim Khố Tổng Quản #YTiền Vi Nhất#cffff00 của bang phái đã lĩnh lương tuần này, tổng cộng #{_MONEY%d}.", PlayerName, goldGet)
        sMessage = gbk.fromutf8(sMessage)
        self:BroadMsgByChatPipe(selfId, sMessage, 6)
    else
        if nNum >= 1 then
            msg = string.format("Ngươi đã lĩnh lương tuần này rồi, tuần sau hãy đến.")
            self:NotifyTips(selfId, msg)
            return 0
        end
        local nContribPoint = self:CityGetAttr(selfId, ScriptGlobal.GUILD_CONTRIB_POINT)
        nContribPoint = nContribPoint - minusContri
        if nContribPoint < 0 then
            msg = string.format("Cống hiến bang của ngài không đủ, vì vậy không thể lĩnh lương.")
            self:NotifyTips(selfId, msg)
            return 0
        end
        local guildLevel = self:GetGuildLevel(selfId)
        local goldGet = 0
        if guildLevel == 1 then
            goldGet = 5 * 10000
        elseif guildLevel == 2 then
            goldGet = 6 * 10000
        elseif guildLevel == 3 then
            goldGet = 7 * 10000
        elseif guildLevel == 4 then
            goldGet = 8 * 10000
        elseif guildLevel == 5 then
            goldGet = 9 * 10000
        end
        local GuildMoney = self:CityGetAttr(selfId, ScriptGlobal.GUILD_MONEY)
        if GuildMoney < goldGet then
            self:NotifyTips(selfId, "Quỹ bang phái không đủ, không thể lĩnh ra.")
            return 0
        end
        self:CityChangeAttr(selfId, ScriptGlobal.GUILD_MONEY, (-1) * goldGet)
        nFactionAllNum = nFactionAllNum + 1
        nFactionAllTimeNum = nWeekCur * 1000 + nFactionAllNum
        self:CanCitySetAttr(selfId, 14)
        self:CitySetAttr(selfId, 14, nFactionAllTimeNum)
        if (isPosLongEnough == 1) then
            if (Guildpos == define.GUILD_POSITION_CHIEFTAIN) then
                self:NotifyTips(selfId, "Ngài đảm nhiệm chức bang chủ vượt quá một tuần, lần lĩnh lương này không tiêu hao cống hiến bang.")
            elseif (Guildpos == define.GUILD_POSITION_ASS_CHIEFTAIN) then
                self:NotifyTips(selfId, "Ngài đảm nhiệm chức phó bang chủ vượt quá một tuần, lần lĩnh lương này tiêu hao cống hiến bang giảm một nửa.")
            end
        end
        self:CityChangeAttr(selfId, ScriptGlobal.GUILD_CONTRIB_POINT, (-1) * minusContri)
        local guildid = self:GetHumanGuildID(selfId)
        self:LuaFnAuditPlayerGetGuildWage(selfId, guildid, goldGet)
        nNum = nNum + 1
        nDrawPayTimeLast = nWeekCur * 1000 + nNum
        self:SetMissionData(selfId, ScriptGlobal.MD_DRAWPAY_TIME, nDrawPayTimeLast)
        self:AddMoney(selfId, goldGet)
        local PlayerName = self:GetName(selfId)
        local sMessage = string.format("@*;SrvMsg;GLD:#Y#{_INFOUSR%s}#cffff00 tại Kim Khố Tổng Quản #YTiền Vi Nhất#cffff00 của bang phái đã lĩnh lương tuần này, tổng cộng #{_MONEY%d}.", PlayerName, goldGet)
        sMessage = gbk.fromutf8(sMessage)
        self:BroadMsgByChatPipe(selfId, sMessage, 6)
    end
end

function city0_building5:IsManager(Guildpos)
    if ((Guildpos == define.GUILD_POSITION_CHIEFTAIN) or
        (Guildpos == define.GUILD_POSITION_ASS_CHIEFTAIN) or
        (Guildpos == define.GUILD_POSITION_HR) or (Guildpos == define.GUILD_POSITION_INDUSTRY) or
        (Guildpos == define.GUILD_POSITION_AGRI) or (Guildpos == define.GUILD_POSITION_COM)) then
        return 1
    end
    return 0
end

function city0_building5:DrawManagerBonus(selfId)
    local msg
    if (self:LuaFnGetGuildAppointTime(selfId) < ScriptGlobal.MIN_APPOINT_TIME_FOR_BONUS) then
        msg = string.format("Ngươi xem ngươi kìa, tân quan nhậm chức, phải làm nhiều việc cho huynh đệ, chứ không phải vội vã đến lĩnh phúc lợi. Vài ngày nữa hãy đến!")
        self:NotifyTips(selfId, msg)
        return 0
    end
    local Guildpos = self:GetGuildPos(selfId)
    if (self:IsManager(Guildpos) ~= 1) then
        msg = string.format( "Ngươi không phải là quản lý, không thể lĩnh phúc lợi quan viên bang hội!")
        self:NotifyTips(selfId, msg)
        return 0
    end
    if self:CityGetMaintainStatus(selfId) == 1 then
        msg = string.format("Bang hội hiện tại đang thiếu vốn, mỗi một đồng tiền đều phải dùng vào việc quan trọng. Phúc lợi quản lý chỉ có thể tạm dừng phát thôi.")
        self:NotifyTips(selfId, msg)
        return 0
    end
    if self:GetTodayWeek() ~= 0 then
        msg = string.format("Vẫn chưa đến thời điểm phát phúc lợi quản lý, đừng quá nóng vội!")
        self:NotifyTips(selfId, msg)
        return 0
    end
    if self:GetFullExp(selfId) == self:GetExp(selfId) then
        msg = string.format( "#Ykinh nghiệm#W của ngươi đã đạt đến giới hạn, hiện tại lĩnh phúc lợi thật không đáng. Hãy dùng bớt đi rồi đến!")
        self:NotifyTips(selfId, msg)
        return 0
    end
    local nWeekCur = self:GetWeekTime()
    local nDrawPayTimeLast = self:GetMissionData(selfId, ScriptGlobal.MD_GUILD_MANAGER_DRAW_BONUS)
    if nWeekCur ~= nDrawPayTimeLast then
        local guildLevel = self:GetGuildLevel(selfId)
        local goldGet = 0
        local GuildMoney = self:CityGetAttr(selfId, ScriptGlobal.GUILD_MONEY)
        local nCount1 = GuildMoney * ScriptGlobal.GUILD_MANAGER_BONUS_MONEY_TABLE[Guildpos][1]

        local nCount2 = guildLevel * ScriptGlobal.GUILD_MANAGER_BONUS_MONEY_TABLE[Guildpos][2]
        goldGet = ((nCount1 < nCount2) and nCount1) or nCount2
        if GuildMoney < goldGet then
            self:NotifyTips(selfId, "Quỹ bang phái không đủ, không thể lĩnh ra.")
            return 0
        end
        self:CityChangeAttr(selfId, ScriptGlobal.GUILD_MONEY, (-1) * goldGet)
        self:AddMoney(selfId, goldGet)
        local level = self:GetLevel(selfId)
        local expGet = guildLevel * level * ScriptGlobal.GUILD_MANAGER_BONUS_EXP_TABLE[Guildpos]
        self:AddExp(selfId, expGet)
        self:AuditDrawGuildWelfare(selfId, goldGet, expGet)
        self:SetMissionData(selfId, ScriptGlobal.MD_GUILD_MANAGER_DRAW_BONUS, nWeekCur)
        local PlayerName = self:GetName(selfId)
        local sMessage = string.format("@*;SrvMsg;GLD:#YBổn bang[%s][#{_INFOUSR%s}]#cffff00lĩnh nhận Bổng Lộc Quan Viên Bang Hội #{_MONEY%d} và %d điểmkinh nghiệm.", ScriptGlobal.GUILD_POSITION_NAME_TABLE[Guildpos], PlayerName, goldGet, expGet)
        sMessage = gbk.fromutf8(sMessage)
        self:BroadMsgByChatPipe(selfId, sMessage, 6)
        msg = string.format("Chức vụ của ngươi là: %s", ScriptGlobal.GUILD_POSITION_NAME_TABLE[Guildpos])
        self:NotifyTips(selfId, msg)
    else
        msg = string.format( "Ngươi hay thật, làm quan mà còn thế ư, tuần này đã lĩnh qua một lần phúc lợi quản lý rồi, còn muốn lĩnh thêm lần nữa sao?")
        self:NotifyTips(selfId, msg)
        return 0
    end
end

function city0_building5:OnEventRequest(selfId, targetId, arg, index)
    if arg ~= self.script_id then
        self:CallScriptFunction(define.CITY_BUILDING_ABILITY_SCRIPT, "OnDefaultEvent", selfId, targetId, arg, self.script_id, self.g_BuildingID6)
        return
    end
    local sceneId = self:get_scene_id()
    if index == 1 then
        if (sceneId == 205) then
            self:DispatchShopItem(selfId, targetId, -1)
        elseif (sceneId == 206) then
            self:DispatchShopItem(selfId, targetId, -1)
        elseif (sceneId == 207) then
            self:DispatchShopItem(selfId, targetId, -1)
        elseif (sceneId == 208) then
            self:DispatchShopItem(selfId, targetId, -1)
        elseif (sceneId == 209) then
            self:DispatchShopItem(selfId, targetId, -1)
        elseif (sceneId == 210) then
            self:DispatchShopItem(selfId, targetId, -1)
        elseif (sceneId == 211) then
            self:DispatchShopItem(selfId, targetId, -1)
        elseif (sceneId == 212) then
            self:DispatchShopItem(selfId, targetId, -1)
        elseif (sceneId == 213) then
            self:DispatchShopItem(selfId, targetId, -1)
        elseif (sceneId == 214) then
            self:DispatchShopItem(selfId, targetId, -1)
        elseif (sceneId == 215) then
            self:DispatchShopItem(selfId, targetId, -1)
        elseif (sceneId == 216) then
            self:DispatchShopItem(selfId, targetId, -1)
        elseif (sceneId == 217) then
            self:DispatchShopItem(selfId, targetId, -1)
        elseif (sceneId == 218) then
            self:DispatchShopItem(selfId, targetId, -1)
        elseif (sceneId == 219) then
            self:DispatchShopItem(selfId, targetId, -1)
        elseif (sceneId == 220) then
            self:DispatchShopItem(selfId, targetId, -1)
        elseif (sceneId == 221) then
            self:DispatchShopItem(selfId, targetId, -1)
        elseif (sceneId == 222) then
            self:DispatchShopItem(selfId, targetId, -1)
        end
    elseif index == 888 then
        self:BeginEvent(self.script_id)
        self:CallScriptFunction(define.CITY_BUILDING_ABILITY_SCRIPT, "OnEnumerate",self,  selfId, targetId, self.g_BuildingID6)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 2 then
        local guildid = self:GetHumanGuildID(selfId)
        local cityguildid = self:GetCityGuildID(selfId)
        if (guildid ~= cityguildid) then
            self:BeginEvent(self.script_id)
            local strText = "Các hạ không phải là thành viên của bổn bang, nhiệm vụ của bổn bang xin phép không thông báo."
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            return
        end
        local guildpos = self:GetGuildPos(selfId)
        if ((guildpos ~= define.GUILD_POSITION_COM) and
            (guildpos ~= define.GUILD_POSITION_CHIEFTAIN) and
            (guildpos ~= define.GUILD_POSITION_ASS_CHIEFTAIN) and
            (guildpos ~= define.GUILD_POSITION_AGRI) and
            (guildpos ~= define.GUILD_POSITION_INDUSTRY) and
            (guildpos ~= define.GUILD_POSITION_HR)) then
            self:BeginEvent(self.script_id)
            local strText = "Xin lỗi, chỉ có Bang Chủ, Phó Bang Chủ, Nội Vụ Sử, Hoằng Hóa Sử, Công Vụ Sử và Thương nhân mới có thể nhận được Ngân phiếu."
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            return
        end
        local level = self:GetLevel(selfId)
        if (level < 40) then
            self:BeginEvent(self.script_id)
            local strText = "Vị tiểu huynh đệ này giờ đã muốn đến kinh doanh, chẳng phải là quá sớm sao? Chi bằng đạt đến cấp 40 rồi hãy đến tìm ta, đó mới là đạo lý."
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            return
        end
        local curMoney = 0
        local maxMoney = 0
        local maxmaxMoney = 0
        if level >= 40 and level < 55 then
            curMoney = 20000
            maxMoney = 100000
            maxmaxMoney = 250000
        elseif level >= 55 and level < 70 then
            curMoney = 30000
            maxMoney = 150000
            maxmaxMoney = 350000
        elseif level >= 70 and level < 85 then
            curMoney = 40000
            maxMoney = 250000
            maxmaxMoney = 450000
        elseif level >= 85 and level < 100 then
            curMoney = 50000
            maxMoney = 300000
            maxmaxMoney = 550000
        elseif level >= 100 and level < 115 then
            curMoney = 50000
            maxMoney = 310000
            maxmaxMoney = 600000
        elseif level >= 115 and level < 130 then
            curMoney = 60000
            maxMoney = 320000
            maxmaxMoney = 650000
        elseif level >= 130 and level < 145 then
            curMoney = 70000
            maxMoney = 330000
            maxmaxMoney = 700000
        else
            curMoney = 80000
            maxMoney = 340000
            maxmaxMoney = 750000
        end
        local haveImpact = self:LuaFnHaveImpactOfSpecificDataIndex(selfId, 113)
        if haveImpact then
            self:BeginEvent(self.script_id)
            local strText = "Xin lỗi, bạn đang vận chuyển, không nhận phiếu được"
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            return
        end
        local bagpos = self:GetBagPosByItemSn(selfId, self.g_TicketItemIdx)
        if bagpos ~= -1 then
            self:BeginEvent(self.script_id)
            local strText = "Xin lỗi, ngài chỉ có thể lĩnh một tấm Ngân phiếu."
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            return
        elseif bagpos == -1 then
            local GuildMoney = self:CityGetAttr(selfId, ScriptGlobal.GUILD_MONEY)
            if GuildMoney <= curMoney then
                self:BeginEvent(self.script_id)
                local strText = "Bang phái tư kim không đủ để mở Ngân phiếu cho ngươi."
                self:AddText(strText)
                self:EndEvent()
                self:DispatchMissionTips(selfId)
                return
            end
            local DayTimes, oldDate, nowDate, takenTimes, totalTakenTimes
            DayTimes = self:GetMissionData(selfId, ScriptGlobal.MD_GUILDTICKET_TAKENTIMES)
            oldDate = DayTimes % 100000
            takenTimes = math.floor(DayTimes / 100000)
            nowDate = self:GetDayTime()
            if nowDate == oldDate then
                takenTimes = takenTimes + 1
            else
                takenTimes = 1
            end
            if takenTimes > self.g_TicketTakeTimes then
                self:BeginEvent(self.script_id)
                self:AddText("Xin lỗi, hôm nay ngài lĩnh nhiệm vụ Thương nhân đã đạt 8 lần, xin ngày mai lại đến.")
                self:EndEvent()
                self:DispatchMissionTips(selfId)
                return
            end
            DayTimes = self:GetTicketTakenTimes(selfId)
            oldDate = DayTimes % 100000
            totalTakenTimes = math.floor(DayTimes / 100000)
            if nowDate == oldDate then
                totalTakenTimes = totalTakenTimes + 1
            else
                totalTakenTimes = 1
            end
            local guildLevel = self:GetGuildLevel(selfId)
            if not guildLevel or guildLevel < 1 or guildLevel > 5 then
                guildLevel = 1
            end
            local maxTimes = self.g_BaseTotalTicketTakeTimes + self.g_TicketTakeTimesBonusPerLvl * (guildLevel - 1)
            local curGuildBoom = self:CityGetAttr(selfId, self.g_GuildBoomIndex)
            if (curGuildBoom < self.g_TicketDecValue) then
                maxTimes = math.floor(maxTimes * self.g_TicketDecRate)
            elseif (curGuildBoom >= self.g_TicketIncValue) then
                maxTimes = math.floor(maxTimes * self.g_TicketIncRate)
            end
            if totalTakenTimes > maxTimes then
                self:BeginEvent(self.script_id)
                self:AddText("Ta nơi này hôm nay chỉ có" .. maxTimes .. "Trương Ngân phiếu, thật đáng tiếc, hiện tại đã lĩnh hết rồi, vẫn là ngày mai đến sớm thì hơn.")
                self:EndEvent()
                self:DispatchMissionTips(selfId)
                return
            end
            local itemIdx = 0
            for i = 0, 99 do
                itemIdx = self:LuaFnGetItemTableIndexByIndex(selfId, i)
                if itemIdx >= 20400001 and itemIdx <= 20400200 then
                    self:LuaFnEraseItem(selfId, i)
                end
            end
            self:BeginAddItem()
            self:AddItem(self.g_TicketItemIdx, 1)
            local ret = self:EndAddItem(selfId)
            if ret then

                self:AddItemListToHuman(selfId)
                bagpos = self:GetBagPosByItemSn(selfId, self.g_TicketItemIdx)
                self:SetBagItemParam(selfId, bagpos, ScriptGlobal.TICKET_ITEM_PARAM_CUR_MONEY_START, ScriptGlobal.TICKET_ITEM_PARAM_CUR_MONEY_TYPE, curMoney)
                self:SetBagItemParam(selfId, bagpos, ScriptGlobal.TICKET_ITEM_PARAM_MAX_MONEY_START, ScriptGlobal.TICKET_ITEM_PARAM_MAX_MONEY_TYPE, maxMoney)
                self:SetBagItemParam(selfId, bagpos, ScriptGlobal.TICKET_ITEM_PARAM_MAX_MAX_MONEY_START, ScriptGlobal.TICKET_ITEM_PARAM_MAX_MAX_MONEY_TYPE, maxmaxMoney)
                self:CityChangeAttr(selfId, ScriptGlobal.GUILD_MONEY, (-1) * curMoney)
                DayTimes = nowDate + totalTakenTimes * 100000
                self:SetTicketTakenTimes(selfId, DayTimes)
                DayTimes = nowDate + takenTimes * 100000
                self:SetMissionData(selfId, ScriptGlobal.MD_GUILDTICKET_TAKENTIMES, DayTimes)
                self:LuaFnRefreshItemInfo(selfId, bagpos)
                self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 113, 0)
                self:BeginEvent(self.script_id)
                local strText = "Ta nơi này còn có" .. (maxTimes + 1 - totalTakenTimes) .. "Trương Ngân phiếu, tốt lắm tốt lắm, Trương Ngân phiếu này ngươi hãy cầm lấy, vì bổn bang kiếm thêm chút vốn liếng, công lao không nhỏ a."
                self:AddText(strText)
                self:EndEvent()
                self:DispatchMissionTips(selfId)
                self:LuaFnAddMissionHuoYueZhi(selfId, 24)
            else
                self:BeginEvent(self.script_id)
                local strText = "Lĩnh nhận Ngân phiếu thất bại"
                self:AddText(strText)
                self:EndEvent()
                self:DispatchMissionTips(selfId)
            end
        end
    elseif index == 3 then
        local guildid = self:GetHumanGuildID(selfId)
        local cityguildid = self:GetCityGuildID(selfId)
        local merchandiseDayRate = 1.0
        if (self:GetTodayWeek() == 6) then
            merchandiseDayRate = self.g_MerchandiseRate
        end
        if (guildid ~= cityguildid) then
            self:BeginEvent(self.script_id)
            local strText = "Các hạ không phải là thành viên bổn bang..."
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            return
        end
        local guildpos = self:GetGuildPos(selfId)
        if ((guildpos ~= define.GUILD_POSITION_COM) and
            (guildpos ~= define.GUILD_POSITION_CHIEFTAIN) and
            (guildpos ~= define.GUILD_POSITION_ASS_CHIEFTAIN) and
            (guildpos ~= define.GUILD_POSITION_AGRI) and
            (guildpos ~= define.GUILD_POSITION_INDUSTRY) and
            (guildpos ~= define.GUILD_POSITION_HR)) then
            self:BeginEvent(self.script_id)
            local strText = "Xin lỗi, chỉ có Bang chủ, Phó Bang chủ, Nội vụ sứ, Hoằng hóa sứ, Công vụ sứ và Thương nhân mới có thể giao trả Ngân phiếu."
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            return
        end
        local level = self:GetLevel(selfId)
        if (level < 40) then
            self:BeginEvent(self.script_id)
            local strText = "Vị tiểu huynh đệ này bây giờ đã đến kinh doanh, chẳng phải là quá sớm sao..."
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            return
        end
        local bagpos = self:GetBagPosByItemSn(selfId, self.g_TicketItemIdx)
        if bagpos ~= -1 then
            local TicketMoney = self:GetBagItemParam(selfId, bagpos, ScriptGlobal.TICKET_ITEM_PARAM_CUR_MONEY_START, ScriptGlobal.TICKET_ITEM_PARAM_CUR_MONEY_TYPE)
            local MaxTicketMoney = self:GetBagItemParam(selfId, bagpos, ScriptGlobal.TICKET_ITEM_PARAM_MAX_MONEY_START, ScriptGlobal.TICKET_ITEM_PARAM_MAX_MONEY_TYPE)
            if TicketMoney ~= 0 then
                if TicketMoney < MaxTicketMoney then
                    self:BeginEvent(self.script_id)
                    local strText = "Ngân phiếu của ngươi chưa kiếm được giá trị nên kiếm được, hãy đi kiếm thêm đi."
                    self:AddText(strText)
                    self:EndEvent()
                    self:DispatchMissionTips(selfId)
                    return
                end
                local ReturnType = self:DelItem(selfId, self.g_TicketItemIdx, 1)
                self:LuaFnCancelSpecificImpact(selfId, 113)
                if not ReturnType then
                    self:BeginEvent(self.script_id)
                    local strText = "Không thể xóa Ngân phiếu"
                    self:AddText(strText)
                    self:EndEvent()
                    self:DispatchMissionTips(selfId)
                    return
                else
                    self:BeginEvent(self.script_id)
                    local strText = "Xóa Ngân phiếu thành công"
                    self:AddText(strText)
                    self:EndEvent()
                    self:DispatchMissionTips(selfId)
                end
                self:LuaFnAuditPaoShang(selfId, TicketMoney)
                local FatigueRate = 1.0
                local isLittleFatigueState = self:LuaFnIsLittleFatigueState(selfId)
                local isExceedingFatigueState = self:LuaFnIsExceedingFatigueState(selfId)
                if (isExceedingFatigueState == 1) then
                    FatigueRate = 0.0
                elseif (isLittleFatigueState == 1) then
                    FatigueRate = 0.5
                end
                self:CityChangeAttr(selfId, ScriptGlobal.GUILD_MONEY, TicketMoney * self.g_GuildRate * merchandiseDayRate * FatigueRate)
                self:AddMoney(selfId, TicketMoney * self.g_PlayerRate * merchandiseDayRate)
                local contripoint = 0
                local exppoint = 0
                if level >= 11 and level < 40 then
                    contripoint = 25 * merchandiseDayRate
                    exppoint = 30000
                elseif level >= 40 and level < 60 then
                    contripoint = 50 * merchandiseDayRate
                    exppoint = 45000
                elseif level >= 60 and level < 80 then
                    contripoint = 100 * merchandiseDayRate
                    exppoint = 50000
                elseif level >= 80 and level < 100 then
                    contripoint = 125 * merchandiseDayRate
                    exppoint = 55000
                elseif level >= 100 and level < 120 then
                    contripoint = 150 * merchandiseDayRate
                    exppoint = 60000
                elseif level >= 120 then
                    contripoint = 150 * merchandiseDayRate
                    exppoint = 65000
                end
                self:CityChangeAttr(selfId, ScriptGlobal.GUILD_CONTRIB_POINT, contripoint)
                self:AddExp(selfId, exppoint * merchandiseDayRate)
                local nCaoYunTime = self:GetMissionData(selfId, ScriptGlobal.MD_CAOYUN_COMPLETE_TIME)
                local nCaoYunNum = nCaoYunTime % 1000
                local nWeek = math.floor(nCaoYunTime / 1000)
                local nWeekCur = self:GetWeekTime()
                if nWeekCur ~= nWeek then
                    nCaoYunNum = 1
                    nCaoYunTime = nWeekCur * 1000 + nCaoYunNum
                    self:SetMissionData(selfId, ScriptGlobal.MD_CAOYUN_COMPLETE_TIME, nCaoYunTime)
                else
                    nCaoYunNum = nCaoYunNum + 1
                    nCaoYunTime = nWeekCur * 1000 + nCaoYunNum
                    self:SetMissionData(selfId, ScriptGlobal.MD_CAOYUN_COMPLETE_TIME, nCaoYunTime)
                end
                local name = self:GetName(selfId)
                local str = gbk.fromutf8("@*;SrvMsg;GLD:#Y#{_INFOUSR" .. name .. "}#RHoàn thành nhiệm vụ Thương nhân, thành công của việc này đã tăng Tiền vốn bang hội cho bang phái#{_MONEY" .. TicketMoney * self.g_GuildRate *  merchandiseDayRate * FatigueRate ..  "}")
                self:BroadMsgByChatPipe(selfId, str, 6)
                if (merchandiseDayRate ~= 1.0) then
                    self:Msg2Player(selfId, "#RBởi hôm nay là Ngày Thương Nhân, nên ngươi nhận được nhiều hơn so với bình thường.", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
                end
                self:LuaFnComMissComplete(selfId)
            else
                self:BeginEvent(self.script_id)
                local strText = "Xin lỗi, Ngân phiếu của ngài không có tiền"
                self:AddText(strText)
                self:EndEvent()
                self:DispatchMissionTips(selfId)
                return
            end
        else
            self:BeginEvent(self.script_id)
            local strText = "Xin lỗi, ngài không có Ngân phiếu."
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            return
        end
    elseif index == 4 then
        self:BeginEvent(self.script_id)
        self:AddText("#{City_Intro_QianZhuang}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 5 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:UICommand_AddInt(self.g_BuildingID6)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 104)
    elseif index == 6 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 105)
    elseif index == 7 then
        self:BeginEvent(self.script_id)
        self:AddText("Xin hãy kéo Ngân phiếu quá hạn vào ô vật phẩm đầu tiên!")
        self:EndEvent()
        self:DispatchMissionDemandInfo(selfId, targetId, self.script_id, -1, 2)
    elseif index == 8 then
        self:BeginUICommand()
        self:UICommand_AddInt(self.script_id)
        self:UICommand_AddInt(targetId)
        self:UICommand_AddStr("DrawPay")
        self:UICommand_AddStr(
            "Ngươi có chắc chắn muốn tiêu hao một lượng điểm cống hiến bang hội nhất định để nhận bổng lộc bang phái tuần này không?")
        self:EndUICommand()
        self:DispatchUICommand(selfId, 24)
    elseif index == 9 then
        self:DrawManagerBonus(selfId)
    elseif index == 10 then
        self:BeginEvent(self.script_id)
        self:AddText("#{BPFL_20080318_01}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 11 then
        local guildmoney = self:CityGetAttr(selfId, ScriptGlobal.GUILD_MONEY)
        local guildmaxmoney = self:CityGetAttr(selfId, 16)
        if guildmoney < guildmaxmoney then
            self:BeginUICommand()
            self:UICommand_AddInt(targetId)
            self:EndUICommand()
            self:DispatchUICommand(selfId, 19822)
        else
            self:BeginEvent(self.script_id)
            self:AddText("#{BPZJ_0801014_003}")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        end
    elseif index == 12 then
        self:BeginEvent(self.script_id)
        self:AddText("#{BPZJ_0801014_019}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

function city0_building5:OnMissionCheck(selfId, npcid, scriptId, index1, index2,  index3, indexpet)
    if index1 < 0 or index1 >= 255 then
        self:MyNotifyTip(selfId, "Ngươi vẫn chưa đặt Ngân phiếu quá hạn muốn nộp.")
        return
    else
        if self:LuaFnIsItemAvailable(selfId, index1) then
            local itm_id = self:LuaFnGetItemTableIndexByIndex(selfId, index1)
            if (itm_id == self.g_OutDateTicketItemIdx) then
                local TicketMoney = self:GetBagItemParam(selfId, index1, 0, 2)
                self:EraseItem(selfId, index1)
                self:CityChangeAttr(selfId, ScriptGlobal.GUILD_MONEY, TicketMoney)
                self:AddMoney(selfId, TicketMoney * 0.2)
                local name = self:GetName(selfId)
                local str = gbk.fromutf8("@*;SrvMsg;GLD:#{_INFOUSR" .. name .. "}Không biết từ đâu có được một tấm Ngân phiếu quá hạn, #{_MONEY" .. TicketMoney .. "}Đã nạp vào Tiền vốn bang hội của bang.")
                self:BroadMsgByChatPipe(selfId, str, 6)
                self:MyNotifyTip(selfId, "Nạp Ngân phiếu quá hạn vào Tiền vốn bang hội thành công.")
                return
            else
                self:MyNotifyTip(selfId, "Vật phẩm mà ngài muốn giao nộp hình như không phải Ngân phiếu hết hạn đâu.")
                return
            end
        end
    end
    self:MyNotifyTip(selfId, "Nộp thất bại")
end

function city0_building5:PutGuildMoney(selfId, money)
    local guildid = self:GetHumanGuildID(selfId)
    local cityguildid = self:GetCityGuildID(selfId)
    if guildid ~= cityguildid then
        self:NotifyTips(selfId, "Các hạ không phải là thành viên bang hội!")
        return
    end
    if money < self.g_GuildMoneyLimit then
        self:NotifyTips(selfId, "Số tiền ngài nhập nhỏ hơn #{_EXCHG" .. self.g_GuildMoneyLimit .. "}")
        return
    end
    local nMoneyJZ = self:GetMoneyJZ(selfId)
    local nMoneyJB = self:GetMoney(selfId)
    local nMoneySelf = nMoneyJZ + nMoneyJB
    if nMoneySelf < money then
        self:NotifyTips(selfId, "#{BPZJ_0801014_007}")
        return
    end
    if not self:IsPilferLockFlag(selfId) then return end

    local addmoney = math.floor(money * 0.9)
    local guildmoney = self:CityGetAttr(selfId, ScriptGlobal.GUILD_MONEY)
    local guildmaxmoney = self:CityGetAttr(selfId, 16)
    if addmoney + guildmoney > guildmaxmoney then
        self:NotifyTips(selfId, "#{BPZJ_0801014_021}#{_MONEY" .. guildmaxmoney .. "}#{BPZJ_0801014_014}")
        return
    end
    local r, jzCost, jbCost = self:LuaFnCostMoneyWithPriority(selfId, money)
    if not r then
        self:NotifyTips(selfId, "Khấu trừ tiền bạc thất bại!")
        return
    end
    if jzCost == 0 then
        self:CityChangeAttr(selfId, ScriptGlobal.GUILD_MONEY, addmoney)
        self:NotifyTips(selfId, "#{BPZJ_0801014_015}#{_MONEY" .. jbCost .. "}！")
        self:NotifyTips(selfId, "Sau khi khấu thuế, Tiền vốn bang hội thực tế tăng #{_MONEY" ..addmoney .. "}！")
        local name = self:GetName(selfId)
        name = gbk.fromutf8(name)
        self:BroadMsgByChatPipe(selfId, "@*;SrvMsg;GLD:#{_INFOUSR" .. name .. "}#{BPZJ_0801014_017}#{_MONEY" .. jbCost .."}#{BPZJ_0801014_018}", 6)
    end
    if jbCost == 0 then
        self:CityChangeAttr(selfId, ScriptGlobal.GUILD_MONEY, addmoney)
        self:NotifyTips(selfId, "#{BPZJ_0801014_015}#{_EXCHG" .. jzCost .. "}！")
        self:NotifyTips(selfId, "Sau khi khấu thuế, Tiền vốn bang hội thực tế tăng #{_MONEY" .. addmoney .. "}！")
        local name = self:GetName(selfId)
        name = gbk.fromutf8(name)
        self:BroadMsgByChatPipe(selfId, "@*;SrvMsg;GLD:#{_INFOUSR" .. name .. "}#{BPZJ_0801014_017}#{_EXCHG" .. jzCost .."}#{BPZJ_0801014_018}", 6)
    end
    if jzCost ~= 0 and jbCost ~= 0 then
        self:CityChangeAttr(selfId, ScriptGlobal.GUILD_MONEY, addmoney)
        self:NotifyTips(selfId, "#{BPZJ_0801014_015}#{_EXCHG" .. jzCost .. "}！")
        self:NotifyTips(selfId, "#{BPZJ_0801014_015}#{_MONEY" .. jbCost .. "}！")
        self:NotifyTips(selfId, "Sau khi khấu thuế, Tiền vốn bang hội thực tế tăng #{_MONEY" .. addmoney .. "}！")
        local name = self:GetName(selfId)
        name = gbk.fromutf8(name)
        self:BroadMsgByChatPipe(selfId, "@*;SrvMsg;GLD:#{_INFOUSR" .. name .. "}#{BPZJ_0801014_017}#{_EXCHG" .. jzCost .. "}và#{_MONEY" .. jbCost .. "}#{BPZJ_0801014_018}", 6)
    end
end

function city0_building5:NotifyTips(selfId, Tip)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function city0_building5:MyNotifyTip(selfId, str)
    self:BeginEvent(self.script_id)
    self:AddText(str)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return city0_building5
