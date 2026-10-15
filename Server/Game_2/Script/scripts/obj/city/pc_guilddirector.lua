local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local pc_guilddirector = class("pc_guilddirector", script_base)
pc_guilddirector.script_id = 805009
pc_guilddirector.g_BuildingID1 = 0
pc_guilddirector.g_eventList = {600035, 600040}
pc_guilddirector.g_eventSetList = {600035, 600040}
pc_guilddirector.g_TicketItemIdx = 40002000
pc_guilddirector.g_Yinpiao = 40002000
pc_guilddirector.g_GuildContriTitle = {{
    ["currName"] = "",
    ["nextId"] = 242,
    ["needContri"] = 250,
    ["name"] = "★Quan Nội Hầu"
}, {
    ["currName"] = "★Quan Nội Hầu",
    ["nextId"] = 243,
    ["needContri"] = 750,
    ["name"] = "★Đình Hầu"
}, {
    ["currName"] = "★Đình Hầu",
    ["nextId"] = 244,
    ["needContri"] = 1500,
    ["name"] = "★Hương Hầu"
}, {
    ["currName"] = "★Hương Hầu",
    ["nextId"] = 245,
    ["needContri"] = 3000,
    ["name"] = "★Huyện Hầu"
}, {
    ["currName"] = "★Huyện Hầu",
    ["nextId"] = 246,
    ["needContri"] = 7500,
    ["name"] = "★Quận Hầu"
}, {
    ["currName"] = "★Quận Hầu",
    ["nextId"] = 247,
    ["needContri"] = 15000,
    ["name"] = "★Huyện Công"
}, {
    ["currName"] = "★Huyện Công",
    ["nextId"] = 248,
    ["needContri"] = 30000,
    ["name"] = "★Quận Công"
}, {
    ["currName"] = "★Quận Công",
    ["nextId"] = 249,
    ["needContri"] = 60000,
    ["name"] = "★Quốc Công"
}, {
    ["currName"] = "★Quốc Công",
    ["nextId"] = 250,
    ["needContri"] = 125000,
    ["name"] = "★Quận Vương"
}, {
    ["currName"] = "★Quận Vương",
    ["nextId"] = 251,
    ["needContri"] = 250000,
    ["name"] = "★Thân Vương"
}}

function pc_guilddirector:UpdateEventList(selfId, targetId)
    local i = 1
    local eventId = 0
    local Humanguildid = self:GetHumanGuildID(selfId)
    local cityguildid = self:GetCityGuildID(selfId)
    self:BeginEvent(self.script_id)

    if (Humanguildid == cityguildid) then
        self:AddText("    Mọi việc lớn nhỏ trong bang, có yêu cầu gì ta có thể giúp ngươi, huynh đệ một nhà đừng khách sáo.")
        self:AddNumText("Thiết lập/Xem tin nhắn offline", 6, 22)
        self:AddNumText("Kiến thiết thành thị", 6, 12)
        self:AddNumText("Nghiên cứu thành thị", 6, 14)
        for i, eventId in pairs(self.g_eventList) do
            self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
        end
        self:AddNumText("Tuyến đường Thương nghiệp", 12, 18)
        self:AddNumText("Huyện Nha tửu quán", 11, 19)
        self:AddNumText("Nhiệm vụ kiến thiết tửu quán", 11, 20)
        self:AddNumText("Nhiệm vụ nghiên cứu tửu quán", 11, 21)
        self:AddNumText("#{BGCH_8829_02}", 11, 25)
        self:AddNumText("Xin trở thành Bang Chủ", 6, 23)
        self:AddNumText("#{SQBZ_090205_01}", 11, 26)
        self:AddNumText("#{BHCS_090226_10}", 9, 29)
        local currGuildContriSum = self:CityGetAttr(selfId, 15)
        local currGuildContriTitle = self:GetGuildContriTitle(selfId)
        local guildName = self:LuaFnGetGuildName(selfId)
        for i, titleItem in pairs(self.g_GuildContriTitle) do
            if currGuildContriTitle == "" then
                currGuildContriTitle = guildName
            end
            if currGuildContriTitle == guildName .. titleItem["currName"] then
                self:AddNumText("Thăng chức thành" .. titleItem["name"], 6, 30)
                break
            end
        end
        self:AddNumText("#{BGCH_8829_01}", 6, 24)
    else
        local PlayerGender = self:GetSex(selfId)
        local rank
        if PlayerGender == 0 then
            rank = "Hiệp Nữ"
        elseif PlayerGender == 1 then
            rank = "Thiếu hiệp"
        else
            rank = "Vị này"
        end
        self:AddText("    " .. rank .. "Diện mạo lạ lẫm thật, ta là chủ quản của bản thành, có chuyện gì ta có thể tiếp đãi khách ngoài.")
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function pc_guilddirector:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function pc_guilddirector:IsValidEvent(selfId, eventId)
    local i = 1
    local findId = 0
    local bValid = 0
    for i, findId in pairs(self.g_eventList) do
        if eventId == findId then
            bValid = 1
            break
        end
    end
    if bValid == 0 then
        for i, findId in pairs(self.g_eventSetList) do
            if self:CallScriptFunction(findId, "IsInEventList", selfId, eventId) == 1 then
                bValid = 1
                break
            end
        end
    end
    return bValid
end

function pc_guilddirector:OnEventRequest(selfId, targetId, arg, index)
    if self:IsValidEvent(selfId, arg) == 1 then
        self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId)
        return
    end
    local strText = ""
    if index == 1 then
        self:CityBuildingChange(selfId, self.g_BuildingID1, 0)
    elseif index == 2 then
        self:CityBuildingChange(selfId, self.g_BuildingID1, 1)
    elseif index == 3 then
        self:CityBuildingChange(selfId, self.g_BuildingID1, 2)
    elseif index == 4 then
        self:CityBuildingChange(selfId, self.g_BuildingID1, 3)
    elseif index == 5 then
        self:CityBuildingChange(selfId, self.g_BuildingID1, 4)
    elseif index == 6 then
        self:CitySetLevel(selfId, 0)
    elseif index == 7 then
        self:CitySetLevel(selfId, 1)
    elseif index == 8 then
        self:CitySetLevel(selfId, 2)
    elseif index == 9 then
        self:CitySetLevel(selfId, 3)
    elseif index == 10 then
        self:CitySetLevel(selfId, 4)
    elseif index == 11 then
        if self:GetItemCount(selfId, self.g_Yinpiao) >= 1 then
            self:BeginEvent(self.script_id)
            self:AddText("  Ngươi đang mang theo Ngân phiếu, đang trong lúc chạy thương! Ta không thể giúp ngươi.")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end
        self:CallScriptFunction((400900), "TransferFuncFromNpc", selfId, 0, 238, 238)
    elseif index == 12 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 100)
    elseif index == 13 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 101)
    elseif index == 14 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 102)
    elseif index == 15 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 103)
    elseif index == 18 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 105)
    elseif index == 16 then
        local guildid = self:GetHumanGuildID(selfId)
        local cityguildid = self:GetCityGuildID(selfId)
        if (guildid ~= cityguildid) then
            self:BeginEvent(self.script_id)
            strText = "Các hạ không phải là thành viên của bổn bang, nhiệm vụ của bổn bang xin phép không thông báo."
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            return
        end
        local guildpos = self:GetGuildPos(selfId)
        if ((guildpos ~= define.GUILD_POSITION_COM) and (guildpos ~= define.GUILD_POSITION_CHIEFTAIN)) then
            self:BeginEvent(self.script_id)
            strText = "Xin lỗi, chỉ có Thương nghiệp quan viên hoặc bang chủ mới có thể nhận được Quan Phiếu."
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            return
        end
        local level = self:GetLevel(selfId)
        if (level < 40) then
            self:BeginEvent(self.script_id)
            strText = "Vị tiểu huynh đệ này giờ đã muốn đến kinh doanh, chẳng phải là quá sớm sao? Chi bằng đạt đến cấp 40 rồi hãy đến tìm ta, đó mới là đạo lý."
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            return
        end
        local curMoney = 0
        local maxMoney = 0
        if level >= 40 and level < 55 then
            curMoney = 20000
            maxMoney = 100000
        elseif level >= 55 and level < 70 then
            curMoney = 30000
            maxMoney = 150000
        elseif level >= 70 and level < 85 then
            curMoney = 40000
            maxMoney = 250000
        elseif level >= 85 and level <= 200 then
            curMoney = 50000
            maxMoney = 300000
        end
        local bagpos = self:GetBagPosByItemSn(selfId, self.g_TicketItemIdx)
        if bagpos ~= -1 then
            self:BeginEvent(self.script_id)
            strText = "Xin lỗi, người chỉ có thể lĩnh một tấm quan phiếu."
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            return
        elseif bagpos == -1 then
            local GuildMoney = self:CityGetAttr(selfId, ScriptGlobal.GUILD_MONEY)
            if GuildMoney < curMoney then
                self:BeginEvent(self.script_id)
                strText = "Bang phái tư kim không đủ để mở Ngân phiếu cho ngươi."
                self:AddText(strText)
                self:EndEvent()
                self:DispatchMissionTips(selfId)
                return
            end
            if self:CityChangeAttr(selfId, ScriptGlobal.GUILD_MONEY, -curMoney) ~= 1 then return end
            self:BeginAddItem()
            self:AddItem(self.g_TicketItemIdx, 1)
            ret = self:EndAddItem(selfId)
            if ret then
                if not self:AddItemListToHuman(selfId) then
                    self:CityChangeAttr(selfId, ScriptGlobal.GUILD_MONEY, curMoney)
                    return
                end
                bagpos = self:GetBagPosByItemSn(selfId, self.g_TicketItemIdx)
                self:SetBagItemParam(selfId, bagpos, ScriptGlobal.TICKET_ITEM_PARAM_CUR_MONEY_START, curMoney, ScriptGlobal.TICKET_ITEM_PARAM_CUR_MONEY_TYPE)
                self:SetBagItemParam(selfId, bagpos, ScriptGlobal.TICKET_ITEM_PARAM_MAX_MONEY_START, maxMoney, ScriptGlobal.TICKET_ITEM_PARAM_MAX_MONEY_TYPE)
                self:LuaFnRefreshItemInfo(selfId, bagpos)
                self:BeginEvent(self.script_id)
                strText = "Rất tốt rất tốt, tấm Ngân phiếu này ngươi cứ cầm lấy, ra sức kiếm về cho bản bang chút vốn liếng, công lao không nhỏ a."
                self:AddText(strText)
                self:EndEvent()
                self:DispatchMissionTips(selfId)
            else
                self:CityChangeAttr(selfId, ScriptGlobal.GUILD_MONEY, curMoney)
                self:BeginEvent(self.script_id)
                strText = "Hành trang đã đầy, không thể chấp nhận nhiệm vụ"
                self:AddText(strText)
                self:EndEvent()
                self:DispatchMissionTips(selfId)
            end
        end
    elseif index == 17 then
        local guildid = self:GetHumanGuildID(selfId)
        local cityguildid = self:GetCityGuildID(selfId)
        if (guildid ~= cityguildid) then
            self:BeginEvent(self.script_id)
            strText = "Các hạ không phải là thành viên bổn bang..."
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            return
        end
        local guildpos = self:GetGuildPos(selfId)
        if ((guildpos ~= define.GUILD_POSITION_COM) and (guildpos ~= define.GUILD_POSITION_CHIEFTAIN)) then
            self:BeginEvent(self.script_id)
            strText = "Xin lỗi, chỉ có Thương nghiệp quan viên hoặc là bang chủ mới có thể giao trả Ngân phiếu."
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            return
        end
        local level = self:GetLevel(selfId)
        if (level < 40) then
            self:BeginEvent(self.script_id)
            strText = "Vị tiểu huynh đệ này bây giờ đã đến kinh doanh, chẳng phải là quá sớm sao..."
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
                    strText = "Ngân phiếu của ngươi chưa kiếm được giá trị nên kiếm được, hãy đi kiếm thêm đi."
                    self:AddText(strText)
                    self:EndEvent()
                    self:DispatchMissionTips(selfId)
                    return
                end
                local ReturnType = self:DelItem(selfId, self.g_TicketItemIdx, 1)
                if not ReturnType  then
                    self:BeginEvent(self.script_id)
                    strText = "Không thể xóa Ngân phiếu"
                    self:AddText(strText)
                    self:EndEvent()
                    self:DispatchMissionTips(selfId)
                    return
                else
                self:CityChangeAttr(selfId, ScriptGlobal.GUILD_CONTRIB_POINT, 50)
                self:CityChangeAttr(selfId, ScriptGlobal.GUILD_MONEY, TicketMoney * 0.9)
                self:AddMoney(selfId, TicketMoney * 0.1)
                self:AddExp(selfId, 20000)
                    self:BeginEvent(self.script_id)
                    strText = "Xóa Ngân phiếu thành công"
                    self:AddText(strText)
                    self:EndEvent()
                    self:DispatchMissionTips(selfId)
                    return
                end
            else
                self:BeginEvent(self.script_id)
                strText = "Xin lỗi, Ngân phiếu của ngài không có tiền"
                self:AddText(strText)
                self:EndEvent()
                self:DispatchMissionTips(selfId)
                return
            end
        else
            self:BeginEvent(self.script_id)
            strText = "Xin lỗi, ngài không có Ngân phiếu."
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            return
        end
    elseif index == 19 then
        self:BeginEvent(self.script_id)
        self:AddText("#{City_Intro_XianYa}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 20 then
        self:BeginEvent(self.script_id)
        self:AddText("#{City_Intro_Build}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 21 then
        self:BeginEvent(self.script_id)
        self:AddText("#{City_Intro_Research}")

        self:EndEvent()

        self:DispatchEventList(selfId, targetId)

    elseif index == 22 then
        local guildpos = self:GetGuildPos(selfId)
        if guildpos ~= define.GUILD_POSITION_ASS_CHIEFTAIN and guildpos ~= define.GUILD_POSITION_CHIEFTAIN then
            self:BeginUICommand()
            self:UICommand_AddInt(targetId)
            self:EndUICommand()
            self:DispatchUICommand(selfId, 19841120)
            return
        else
            self:BeginUICommand()
            self:UICommand_AddInt(targetId)
            self:EndUICommand()
            self:DispatchUICommand(selfId, 19840424)
            return
        end
    elseif index == 23 then
        self:GuildPromoteToChief(selfId)
    elseif index == 24 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 19821)
    elseif index == 25 then
        self:BeginEvent(self.script_id)
        self:AddText("#{BGCH_8829_05}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 26 then
        self:BeginEvent(self.script_id)
        self:AddText("#{SQBZ_090205_02}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 27 then
        if self:GetItemCount(selfId, self.g_Yinpiao) >= 1 then
            self:BeginEvent(self.script_id)
            self:AddText("  Ngươi đang mang theo Ngân phiếu, đang trong lúc chạy thương! Ta không thể giúp ngươi.")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end
        self:CallScriptFunction((400900), "TransferFuncFromNpc", selfId, 2, 181, 120)
    elseif index == 28 then
        if self:GetItemCount(selfId, self.g_Yinpiao) >= 1 then
            self:BeginEvent(self.script_id)
            self:AddText("  Ngươi đang mang theo Ngân phiếu, đang trong lúc chạy thương! Ta không thể giúp ngươi.")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end
        self:CallScriptFunction((400900), "TransferFuncFromNpc", selfId, 1, 326, 280)
    elseif index == 29 then
        self:BeginEvent(self.script_id)
        self:AddText("#{BHCS_090226_11}")
        self:AddNumText("Trở lại Lạc Dương", 9, 11)
        self:AddNumText("#{BHCS_090219_02}", 9, 27)
        self:AddNumText("#{BHCS_090219_03}", 9, 28)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 30 then
        local currGuildContriSum = self:CityGetAttr(selfId, 15)
        local currGuildContriTitle = self:GetGuildContriTitle(selfId)
        local guildName = self:LuaFnGetGuildName(selfId)
        for i, titleItem in pairs(self.g_GuildContriTitle) do
            if currGuildContriTitle == "" then
                currGuildContriTitle = guildName
            end
            if currGuildContriTitle == guildName .. titleItem["currName"] then
                local playerName = self:GetName(selfId)
                if currGuildContriSum < titleItem["needContri"] then
                    local strTip = "#R" .. playerName .. "#W! Thăng làm thành viên bang hội #G" .. guildName .. titleItem["name"] .. "#WYêu cầu cống hiến cho bang hội #G" .. titleItem["needContri"] .. "#Wđiểm cống hiến! Nếu muốn thăng tiến, hãy làm nhiều việc hơn cho bang hội!"
                    self:BeginEvent(self.script_id)
                    self:AddText(strTip)
                    self:EndEvent()
                    self:DispatchEventList(selfId, targetId)
                    return
                end
                self:AwardGuildContriTitle(selfId, guildName .. titleItem["name"])
                self:SetCurTitle(selfId, 38, 0)
                self:LuaFnDispatchAllTitle(selfId)
                local strTip = "Chúc mừng huynh! #R" .. playerName .. "#W! Giờ huynh đã là #G" .. guildName .. titleItem["name"] .. "#Wcủa bang hội ta rồi! Vì sự nghiệp hưng thịnh của bang hội, hãy tiếp tục cố gắng nhé!"
                self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 49, 0)
                local sMessage = string.format("@*;SrvMsg;GLD:#WBổn bang cao thủ #R#{_INFOUSR%s}#W lập đại công cho bang, ban tước vị: #G%s#W! Mong #R#{_INFOUSR%s}#W tiếp tục cố gắng, lập thêm công mới cho bang!", playerName, guildName .. titleItem["name"], playerName)
                sMessage = gbk.fromutf8(sMessage)
                self:BroadMsgByChatPipe(selfId, sMessage, 6)
                sMessage = string.format("#W#{_INFOUSR%s} vì #G%s#W của kiến thiết mà không quản khó nhọc, đặc biệt ban cho tước vị: #G%s#W!", playerName, guildName, guildName .. titleItem["name"])
                sMessage = gbk.fromutf8(sMessage)
                self:BroadMsgByChatPipe(selfId, sMessage, 4)
                self:BeginEvent(self.script_id)
                self:AddText(strTip)
                self:EndEvent()
                self:DispatchEventList(selfId, targetId)
                break
            end
        end
    end
end

function pc_guilddirector:OnMissionAccept(selfId, targetId, missionScriptId)
    if self:IsValidEvent(selfId, missionScriptId) == 1 then
        local ret = self:CallScriptFunction(missionScriptId, "CheckAccept", selfId)
        if ret > 0 then
            self:CallScriptFunction(missionScriptId, "OnAccept", selfId, targetId)
        elseif ret == -1 then
            self:NotifyFailTips(selfId, "Ngươi hiện tại không thể lĩnh nhiệm vụ này")
        elseif ret == -2 then
            self:NotifyFailTips(selfId, "Không thể nhận thêm nhiệm vụ.")
        end
        return
    end
end

function pc_guilddirector:OnMissionRefuse(selfId, targetId, missionScriptId)
    if self:IsValidEvent(selfId, missionScriptId) == 1 then
        self:UpdateEventList(selfId, targetId)
        return
    end
end

function pc_guilddirector:OnMissionContinue(selfId, targetId, missionScriptId)
    if self:IsValidEvent(selfId, missionScriptId) == 1 then
        self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
        return
    end
end

function pc_guilddirector:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    if self:IsValidEvent(selfId, missionScriptId) == 1 then
        self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
        return
    end
end

function pc_guilddirector:OnDie(selfId, killerId)

end

function pc_guilddirector:NotifyFailTips(selfId, Tip)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function pc_guilddirector:BanggongExchange(selfId, nvalue)
    local haveBangGong = self:CityGetAttr(selfId, ScriptGlobal.GUILD_CONTRIB_POINT)
    if not self:IsPilferLockFlag(selfId) then
        return
    end
    if nvalue > haveBangGong then
        self:NotifyFailTips(selfId, "#{BGCH_8829_03}")
        return
    end
    if nvalue > 200 then
        self:NotifyFailTips(selfId, "#{BGCH_8922_25}")
        return
    end
    if nvalue < 10 then
        self:NotifyFailTips(selfId, "#{BGCH_8922_26}")
        return
    end
    local totalvalue = math.floor(nvalue * 0.1) + nvalue
    if totalvalue > haveBangGong then
        self:NotifyFailTips(selfId, "#{BGCH_8922_27}")
        return
    end
    if self:LuaFnGetPropertyBagSpace(selfId) <= 0 then
        self:NotifyFailTips(selfId, "#{SJQM_8819_20}")
        return
    end
    local ret = self:CityChangeAttr(selfId, ScriptGlobal.GUILD_CONTRIB_POINT, -totalvalue)
    if ret == 1 then
        local BagIndex = self:TryRecieveItem(selfId, 30900050)
        local roleBangPaiID = self:GetHumanGuildID(selfId)
        if BagIndex ~= -1 then
            self:SetBagItemParam(selfId, BagIndex, 4, 2, roleBangPaiID)
            self:SetBagItemParam(selfId, BagIndex, 8, 2, nvalue)
            self:LuaFnRefreshItemInfo(selfId, BagIndex)
            self:NotifyFailTips(selfId, "#{BGCH_8829_10}" .. nvalue .. "#{BGCH_8829_11}")
        else
            self:NotifyFailTips(selfId, "Lỗi khi tạo vật phẩm")
        end
    else
        self:NotifyFailTips(selfId, "Trừ cống hiến bang hội thất bại")
    end
end

return require('cys_social_npc').install(pc_guilddirector)
