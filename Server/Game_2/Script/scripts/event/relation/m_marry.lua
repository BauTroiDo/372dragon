local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local m_marry = class("m_marry", script_base)
m_marry.script_id = 806003
m_marry.g_eventId_marry = 0
m_marry.g_eventId_selectLevel1 = 1
m_marry.g_eventId_selectLevel2 = 2
m_marry.g_eventId_selectLevel3 = 3
m_marry.g_eventId_selectLevelCancel = 4
m_marry.g_eventId_selfAcceptLevel1 = 5
m_marry.g_eventId_selfAcceptLevel2 = 6
m_marry.g_eventId_selfAcceptLevel3 = 7
m_marry.g_eventId_selfCancelLevel = 8
m_marry.g_eventId_targetAcceptLevel1 = 9
m_marry.g_eventId_targetAcceptLevel2 = 10
m_marry.g_eventId_targetAcceptLevel3 = 11
m_marry.g_eventId_targetCancelLevel = 12
m_marry.g_eventId_end = 13
m_marry.g_ticketItemId = 30505079
m_marry.g_ticketItemId2 = 30505106
function m_marry:OnDefaultEvent(selfId, targetId, index)
    local selectEventId = index
    if self.g_eventId_marry == selectEventId then
        local canMarry = self:CheckOpenMarryLevelUI(selfId, targetId)
        if canMarry == 1 then
            self:OpenMarryLevelUI(selfId, targetId)
        end
    elseif
        self.g_eventId_selectLevel1 == selectEventId or self.g_eventId_selectLevel2 == selectEventId or
            self.g_eventId_selectLevel3 == selectEventId
     then
        local marryLevel = 0
        if self.g_eventId_selectLevel2 == selectEventId then
            marryLevel = 1
        elseif self.g_eventId_selectLevel3 == selectEventId then
            marryLevel = 2
        end
        self:SelfCheckSelectMarryLevel(selfId, targetId, marryLevel)
    elseif self.g_eventId_selectLevelCancel == selectEventId then
        self:BeginUICommand()
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
    elseif
        self.g_eventId_selfAcceptLevel1 == selectEventId or self.g_eventId_selfAcceptLevel2 == selectEventId or
            self.g_eventId_selfAcceptLevel3 == selectEventId
     then
        local marryLevel = 0
        if self.g_eventId_selfAcceptLevel2 == selectEventId then
            marryLevel = 1
        elseif self.g_eventId_selfAcceptLevel3 == selectEventId then
            marryLevel = 2
        end
        self:OnSelfAcceptSelectMarryLevel(selfId, targetId, marryLevel)
    elseif self.g_eventId_selfCancelLevel == selectEventId then
        local canMarry = self:CheckOpenMarryLevelUI(selfId, targetId)
        if canMarry == 1 then
            self:OpenMarryLevelUI(selfId, targetId)
        end
    elseif
        self.g_eventId_targetAcceptLevel1 == selectEventId or self.g_eventId_targetAcceptLevel2 == selectEventId or
            self.g_eventId_targetAcceptLevel3 == selectEventId
     then
        local marryLevel = 0
        if self.g_eventId_targetAcceptLevel2 == selectEventId then
            marryLevel = 1
        elseif self.g_eventId_targetAcceptLevel3 == selectEventId then
            marryLevel = 2
        end
        self:OnTargetAcceptSelectMarryLevel(selfId, targetId, marryLevel)
    elseif self.g_eventId_targetCancelLevel == selectEventId then
        self:OnTargetCancelSelectMarryLevel(selfId, targetId)
    elseif self.g_eventId_end == selectEventId then
        self:BeginUICommand()
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
    end
end

function m_marry:OnEnumerate(caller)
    caller:AddNumTextWithTarget(self.script_id, "Ta muốn kết hôn", 10, self.g_eventId_marry)
end

function m_marry:CheckOpenMarryLevelUI(selfId, targetId)
    local ret = self:CheckMarry(selfId, targetId, 0, 1)
    return ret
end

function m_marry:OpenMarryLevelUI(selfId, targetId)
    self:BeginEvent(self.script_id)
    local moneyLevel0 = self:CalcNeedMoney(0)
    local moneyLevel1 = self:CalcNeedMoney(1)
    local moneyLevel2 = self:CalcNeedMoney(2)
    self:AddText(
        "#{yuelao_jiehun}#rHôn lễ quy mô thường, Yêu cầu tốn #{_EXCHG" ..
            moneyLevel0 .. "}; Hôn lễ quy mô vừa, Yêu cầu tốn #{_EXCHG" .. moneyLevel1 .. "}. Hôn lễ quy mô lớn, Yêu cầu tốn #{_EXCHG" .. moneyLevel2 .. "}。"
    )
    self:AddNumText("Hôn lễ quy mô thường", 6, self.g_eventId_selectLevel1)
    self:AddNumText("Hôn lễ quy mô vừa", 6, self.g_eventId_selectLevel2)
    self:AddNumText("Hôn lễ quy mô lớn", 6, self.g_eventId_selectLevel3)
    self:AddNumText("Ta tạm thời chưa định kết hôn...", 8, self.g_eventId_selectLevelCancel)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function m_marry:SelfCheckSelectMarryLevel(selfId, targetId, marryLevel)
    self:LuaFnSetHumanMarryInfo(selfId, -1, 0)
    self:BeginEvent(self.script_id)
    if marryLevel == 2 then
        self:AddText(
            "Ngươi đã chọn" ..
                self:GetMarryLevelName(marryLevel) ..
                    ", đồng thời ngươi sẽ phải trả #Y" ..
                        self:GetItemName(self.g_ticketItemId) ..
                            "#W hoặc #{_EXCHG" .. self:CalcNeedMoney(marryLevel) .. "},#r các ngươi có hay chăng đã quyết định thành thân, hơn nữa trong cuộc sống tiếp theo, không rời không bỏ chứ?"
        )
    else
        self:AddText(
            "Ngươi đã chọn" ..
                self:GetMarryLevelName(marryLevel) ..
                    ", đồng thời ngươi sẽ phải trả #Y" ..
                        self:GetItemName(self.g_ticketItemId) ..
                            "#W hoặc #Y" ..
                                self:GetItemName(self.g_ticketItemId2) ..
                                    "#W hoặc #{_EXCHG" ..
                                        self:CalcNeedMoney(marryLevel) .. "},#r các ngươi có hay chăng đã quyết định thành thân, hơn nữa trong cuộc sống tiếp theo, không rời không bỏ chứ?"
        )
    end
    local tempAcceptEventID = self.g_eventId_selfAcceptLevel1
    if marryLevel == 1 then
        tempAcceptEventID = self.g_eventId_selfAcceptLevel2
    elseif marryLevel == 2 then
        tempAcceptEventID = self.g_eventId_selfAcceptLevel3
    end
    self:AddNumText("确认", 6, tempAcceptEventID)
    self:AddNumText("Hủy bỏ", 8, self.g_eventId_selfCancelLevel)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function m_marry:OnSelfAcceptSelectMarryLevel(selfId, targetId, marryLevel)
    local marryTargetId = self:GetMarryTargetId(selfId, 1, targetId)
    if marryTargetId ~= -1 then
        local marryTargetGUID = self:LuaFnGetGUID(marryTargetId)
        self:LuaFnSetHumanMarryInfo(selfId, marryTargetGUID, 1)
        self:TargetCheckSelectMarryLevel(selfId, targetId, marryLevel)
        self:MessageBox(selfId, targetId, "Đợi đối phương xác định...")
    end
end

function m_marry:TargetCheckSelectMarryLevel(selfId, targetId, marryLevel)
    local marryTargetId = self:GetMarryTargetId(selfId, 1, targetId)
    if marryTargetId ~= -1 then
        self:LuaFnSetHumanMarryInfo(marryTargetId, -1, 0)
        self:BeginEvent(self.script_id)
        if marryLevel == 2 then
            self:AddText(
                "Đối phương đã chọn" ..
                    self:GetMarryLevelName(marryLevel) ..
                        ", đồng thời đối phương sẽ phải trả #Y" ..
                            self:GetItemName(self.g_ticketItemId) ..
                                "#W hoặc #{_EXCHG" .. self:CalcNeedMoney(marryLevel) .. "},#r các ngươi có hay chăng đã quyết định thành thân, hơn nữa trong cuộc sống tiếp theo, không rời không bỏ chứ?"
            )
        else
            self:AddText(
                "Đối phương đã chọn" ..
                    self:GetMarryLevelName(marryLevel) ..
                        ", đồng thời đối phương sẽ phải trả #Y" ..
                            self:GetItemName(self.g_ticketItemId) ..
                                "#W hoặc #Y" ..
                                    self:GetItemName(self.g_ticketItemId2) ..
                                        "#W hoặc #{_EXCHG" ..
                                            self:CalcNeedMoney(marryLevel) .. "},#r các ngươi có hay chăng đã quyết định thành thân, hơn nữa trong cuộc sống tiếp theo, không rời không bỏ chứ?"
            )
        end
        local tempAcceptEventID = self.g_eventId_targetAcceptLevel1
        if marryLevel == 1 then
            tempAcceptEventID = self.g_eventId_targetAcceptLevel2
        elseif marryLevel == 2 then
            tempAcceptEventID = self.g_eventId_targetAcceptLevel3
        end
        self:AddNumText("确认", 6, tempAcceptEventID)
        self:AddNumText("Hủy bỏ", 8, self.g_eventId_targetCancelLevel)
        self:EndEvent()
        self:DispatchEventList(marryTargetId, targetId)
    end
end

function m_marry:OnTargetAcceptSelectMarryLevel(selfId, targetId, marryLevel)
    local marryTargetId = self:GetMarryTargetId(selfId, 1, targetId)
    if marryTargetId ~= -1 then
        local marryTargetGUID = self:LuaFnGetGUID(marryTargetId)
        self:LuaFnSetHumanMarryInfo(selfId, marryTargetGUID, 1)
        local checkRet, maleId, femaleId = self:CheckMarry(marryTargetId, targetId, marryLevel, 0)
        if checkRet == 1 then
            self:DoMarry(marryTargetId, targetId, marryLevel, maleId, femaleId)
        end
    end
end

function m_marry:OnTargetCancelSelectMarryLevel(selfId, targetId, marryLevel)
    self:BeginUICommand()
    self:EndUICommand()
    self:DispatchUICommand(selfId, 1000)
    local marryTargetId = self:GetMarryTargetId(selfId, 0, targetId)
    if marryTargetId ~= -1 then
        self:MessageBox(marryTargetId, targetId, "Đối phương cự tuyệt ngươi!")
    end
end

function m_marry:CheckMarry(selfId, targetId, marryLevel, isCheckOpenMarryLevelUI)
    local szMsg = "Nếu muốn kết hôn, tất phải nam nữ song phương cùng tổ đội sau đó lại đến tìm ta."
    if not self:LuaFnHasTeam(selfId) then
        self:MessageBox(selfId, targetId, szMsg)
        return 0
    end
    szMsg = "Đội tổ đội kết hôn của đội ngũ nhất định chỉ có thể do nam nữ song phương tạo thành, trong đội ngũ không được có người Khác."
    if self:LuaFnGetTeamSize(selfId) ~= 2 then
        self:MessageBox(selfId, targetId, szMsg)
        return 0
    end
    szMsg = "Chỉ khi cả hai người cùng đến bên ta mới có thể kết hôn."
    local nearNum = self:GetNearTeamCount(selfId)
    if nearNum ~= 2 then
        self:MessageBox(selfId, targetId, szMsg)
        return 0
    end
    szMsg = "Nhất định song phương phải là khác phái mới có thể kết hôn."
    local maleId = -1
    local femaleId = -1
    local marryTargetId = -1
    for nearIndex = 1, nearNum do
        local memId = self:GetNearTeamMember(selfId, nearIndex)
        local sexType = self:LuaFnGetSex(memId)
        if sexType == 1 then
            maleId = memId
        else
            femaleId = memId
        end
        if memId ~= selfId then
            marryTargetId = memId
        end
    end
    if maleId == -1 or femaleId == -1 then
        self:MessageBox(selfId, targetId, szMsg)
        return 0
    end
    szMsg = "Khi kết hôn, nam cần đạt cấp 35, nữ cần đạt cấp 20."
    if self:LuaFnGetLevel(maleId) < 35 or self:LuaFnGetLevel(femaleId) < 20 then
        self:MessageBox(selfId, targetId, szMsg)
        return 0
    end
    szMsg = "Cả hai bên phải còn độc thân mới có thể kết hôn."
    if self:LuaFnIsMarried(maleId) or self:LuaFnIsMarried(femaleId) then
        self:MessageBox(selfId, targetId, szMsg)
        return 0
    end
    szMsg = "Nếu muốn kết hôn, độ hảo hữu của cả hai bên phải đạt 1000."
    if not self:LuaFnIsFriend(maleId, femaleId) or not self:LuaFnIsFriend(femaleId, maleId) then
        self:MessageBox(selfId, targetId, szMsg)
        return 0
    end
    if self:LuaFnGetFriendPoint(maleId, femaleId) < 1000 or self:LuaFnGetFriendPoint(femaleId, maleId) < 1000 then
        self:MessageBox(selfId, targetId, szMsg)
        return 0
    end
    szMsg = "Các ngươi là sư đồ, sao có thể kết hôn được?"
    if self:LuaFnIsMaster(maleId, femaleId) or self:LuaFnIsMaster(femaleId, maleId) then
        self:MessageBox(selfId, targetId, szMsg)
        return 0
    end
    szMsg = "Hai bên đã kết bái thì không thể kết hôn."
    if self:LuaFnIsBrother(maleId, femaleId) or self:LuaFnIsBrother(femaleId, maleId) then
        self:MessageBox(selfId, targetId, szMsg)
        return 0
    end
    if isCheckOpenMarryLevelUI and isCheckOpenMarryLevelUI == 1 then
        return 1
    end
    local ticketItemPos
    local selectTicketItemId
    if marryLevel == 2 then
        ticketItemPos = self:GetBagPosByItemSn(selfId, self.g_ticketItemId)
        selectTicketItemId = self.g_ticketItemId
    else
        ticketItemPos = self:GetBagPosByItemSn(selfId, self.g_ticketItemId2)
        selectTicketItemId = self.g_ticketItemId2
        if not ticketItemPos or ticketItemPos < 0 then
            ticketItemPos = self:GetBagPosByItemSn(selfId, self.g_ticketItemId)
            selectTicketItemId = self.g_ticketItemId
        end
    end
    if ticketItemPos and ticketItemPos > -1 then
        local checkRet = self:LuaFnIsItemAvailable(selfId, ticketItemPos)
        if not checkRet then
            self:MessageBox(selfId, targetId, "Ngươi của#Y" .. self:GetItemName(selectTicketItemId) .. "#WBị khóa rồi, nên hiện tại vẫn chưa thể giao cho ta.")
            self:MessageBox(
                marryTargetId,
                targetId,
                "Đối phương của#Y" .. self:GetItemName(selectTicketItemId) .. "#WBị khóa rồi, nên hiện tại vẫn chưa thể giao cho ta."
            )
            return 0
        end
    else
        local nMoneyJZ = self:GetMoneyJZ(selfId)
        local nMoneyJB = self:LuaFnGetMoney(selfId)
        local nMoneySelf = nMoneyJZ + nMoneyJB
        local needMoney = self:CalcNeedMoney(marryLevel)
        if nMoneyJZ and nMoneyJB and nMoneySelf and needMoney and nMoneySelf >= needMoney then
        else
            szMsg = "Xin lỗi, kim tiền trên người ngươi không đủ."
            self:MessageBox(selfId, targetId, szMsg)
            szMsg = "Xin lỗi, kim tiền trên người đối phương không đủ."
            self:MessageBox(marryTargetId, targetId, szMsg)
            return 0
        end
    end
    szMsg = "Túi vật phẩm đã đầy, không thể đặt Giới Chỉ kết hôn, xin kiểm tra túi của cả hai bên."
    local maleProSpace = self:LuaFnGetPropertyBagSpace(maleId)
    local femaleProSpace = self:LuaFnGetPropertyBagSpace(femaleId)
    if maleProSpace < 1 or femaleProSpace < 1 then
        self:MessageBox(maleId, targetId, szMsg)
        self:MessageBox(femaleId, targetId, szMsg)
        return 0
    end
    local selfTaskCount = self:GetMissionCount(selfId)
    if selfTaskCount >= 20 then
        szMsg = "Nhật ký nhiệm vụ đã đầy, không thể nhận nhiệm vụ mới."
        self:MessageBox(selfId, targetId, szMsg)
        szMsg = "Nhật ký nhiệm vụ của đối phương đã đầy, không thể nhận nhiệm vụ mới."
        self:MessageBox(marryTargetId, targetId, szMsg)
        return 0
    end
    szMsg = "Hai bên vẫn chưa hoàn toàn đồng ý kết hôn."
    local maleGUID = self:LuaFnGetGUID(maleId)
    local femaleGUID = self:LuaFnGetGUID(femaleId)
    local maleIsAccept, maleTargetGUID = self:LuaFnGetHumanMarryInfo(maleId)
    if maleIsAccept and maleIsAccept == 1 and maleTargetGUID and maleTargetGUID == femaleGUID then
    else
        self:MessageBox(maleId, targetId, szMsg)
        return 0
    end
    local femaleIsAccept, femaleTargetGUID = self:LuaFnGetHumanMarryInfo(femaleId)
    if femaleIsAccept and femaleIsAccept == 1 and femaleTargetGUID and femaleTargetGUID == maleGUID then
    else
        self:MessageBox(femaleId, targetId, szMsg)
        return 0
    end
    return 1
end

function m_marry:DoMarry(selfId, targetId, marryLevel, maleId, femaleId)
    if not self:LuaFnHasTeam(selfId) then
        return 0
    end
    if self:LuaFnGetTeamSize(selfId) ~= 2 then
        return 0
    end
    local nearNum = self:GetNearTeamCount(selfId)
    if nearNum ~= 2 then
        return 0
    end
    for nearIndex = 1, nearNum do
        local memId = self:GetNearTeamMember(selfId, nearIndex)
        local sexType = self:LuaFnGetSex(memId)
        if sexType == 1 then
            maleId = memId
        else
            femaleId = memId
        end
    end
    if maleId == -1 or femaleId == -1 then
        return 0
    end
    local ticketItemPos
    if marryLevel == 2 then
        ticketItemPos = self:GetBagPosByItemSn(selfId, self.g_ticketItemId)
    else
        ticketItemPos = self:GetBagPosByItemSn(selfId, self.g_ticketItemId2)
        if not ticketItemPos or ticketItemPos < 0 then
            ticketItemPos = self:GetBagPosByItemSn(selfId, self.g_ticketItemId)
        end
    end
    if ticketItemPos and ticketItemPos > -1 then
        local checkRet = self:LuaFnIsItemAvailable(selfId, ticketItemPos)
        if not checkRet then
            return 0
        end
        local eraseItemRet = self:EraseItem(selfId, ticketItemPos)
        if not eraseItemRet or eraseItemRet ~= 1 then
            return 0
        end
    else
        local nMoneyJZ = self:GetMoneyJZ(selfId)
        local nMoneyJB = self:LuaFnGetMoney(selfId)
        local nMoneySelf = nMoneyJZ + nMoneyJB
        local needMoney = self:CalcNeedMoney(marryLevel)
        if nMoneyJZ and nMoneyJB and nMoneySelf and needMoney and nMoneySelf >= needMoney then
        else
            return 0
        end
        self:LuaFnCostMoneyWithPriority(selfId, needMoney)
    end
    local maleName = self:LuaFnGetName(maleId)
    local femaleName = self:LuaFnGetName(femaleId)
    self:LuaFnAwardSpouseTitle(femaleId, "#gB0E2FF" .. maleName .. "Nương tử của ta.")
    self:DispatchAllTitle(femaleId)
    self:LuaFnAwardSpouseTitle(maleId, "#gB0E2FF" .. femaleName .. "Phu quân của ta.")
    self:DispatchAllTitle(maleId)
    self:LuaFnSetPrivateInfo(femaleId, "school", "#gB0E2FF#826" .. maleName .. " nương tử#827")
    self:LuaFnSetPrivateInfo(maleId, "school", "#gB0E2FF#826" .. femaleName .. " phu quân#827")
    local pos
    local ringItemId = self:GetRingByMarryLevel(marryLevel)
    pos = self:TryRecieveItem(maleId, ringItemId, 1)
    if pos and pos ~= -1 then
        self:LuaFnSetItemCreator(maleId, pos, femaleName)
    end
    pos = self:TryRecieveItem(femaleId, ringItemId, 1)
    if pos and pos ~= -1 then
        self:LuaFnSetItemCreator(femaleId, pos, maleName)
    end
    self:SetMissionData(maleId, ScriptGlobal.MD_TW_REEXPERIENCE_WEDDING_TOTAL_COUNT, 0)
    self:SetMissionData(femaleId, ScriptGlobal.MD_TW_REEXPERIENCE_WEDDING_TOTAL_COUNT, 0)
    self:LuaFnMarry(maleId, femaleId, marryLevel)
    self:CallScriptFunction(250036, "OnAccept", selfId, marryLevel)
    self:Msg2Player(maleId, "Bạn nhận danh hiệu '" .. femaleName .. " phu quân'.", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    self:Msg2Player(femaleId, "Bạn nhận danh hiệu '" .. maleName .. " nương tử'.", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    local ringItemName = self:GetItemName(ringItemId)
    if ringItemName then
        self:Msg2Player(maleId, "Ngươi nhận được" .. ringItemName .. "。", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        self:Msg2Player(femaleId, "Ngươi nhận được" .. ringItemName .. "。", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    end
    local strChatMessage =
        "#b#cff99ffChúc mừng#W#{_INFOUSR" ..
        maleName .. "}#b#cff99ffvà#W#{_INFOUSR" .. femaleName .. "}#b#cff99ffkết tóc se duyên, chúc nguyện hai người bạc đầu giai lão, sánh cánh song phi, một đời hạnh phúc."
    strChatMessage = gbk.fromutf8(strChatMessage)
    self:BroadMsgByChatPipe(selfId, "@*;SrvMsg;AUC:" .. strChatMessage, 4)
    local maleGuid = self:LuaFnGetGUID(maleId)
    local femaleGuid = self:LuaFnGetGUID(femaleId)
    self:LuaFnSendMailToAllFriend(maleId, "Bằng hữu thân ái của ta, ta đã cùng" .. femaleName .. "Hỷ kết lương duyên, chúc phúc cho chúng ta đi!", 1, femaleGuid)
    self:LuaFnSendMailToAllFriend(femaleId, "Bằng hữu thân ái của ta, ta đã cùng" .. maleName .. "Hỷ kết lương duyên, chúc phúc cho chúng ta đi!", 1, maleGuid)
    local endMsg = "Chúc mừng hai vị hỷ kết liên lý, tiếp theo xin đến Lạc Dương (177, 94) tìm Hỷ Lai Lạc an bài hoa xa diễu phố, bất quá Hỷ Lai Lạc phụ trách toàn bộ hỷ sự của Lạc Dương, mỗi ngày vô cùng bận rộn, cho nên hai vị nhất định phải tìm được hắn sau một canh giờ. Nếu không quá thời hạn này thì không còn cách nào nữa."
    self:BeginEvent(self.script_id)
    self:AddText(endMsg)
    self:AddNumText("Đa tạ...", 8, self.g_eventId_end)
    self:EndEvent()
    self:DispatchEventList(maleId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(endMsg)
    self:AddNumText("Đa tạ...", 8, self.g_eventId_end)
    self:EndEvent()
    self:DispatchEventList(femaleId, targetId)
end

function m_marry:MessageBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function m_marry:CalcNeedMoney(marryLevel)
    if marryLevel == 1 then
        return 5203344
    elseif marryLevel == 2 then
        return 13145200
    else
        return 520520
    end
end

function m_marry:GetMarryLevelName(marryLevel)
    if marryLevel == 1 then
        return "Hôn lễ quy mô vừa"
    elseif marryLevel == 2 then
        return "Hôn lễ quy mô xa hoa"
    else
        return "Hôn lễ quy mô bình thường"
    end
end

function m_marry:GetRingByMarryLevel(marryLevel)
    if marryLevel == 1 then
        return 10422097
    elseif marryLevel == 2 then
        return 10422098
    else
        return 10422096
    end
end

function m_marry:GetMarryTargetId(selfId, showMessage, targetId)
    local marryTargetId = -1
    local szMsg = "Nếu muốn kết hôn, tất phải nam nữ song phương cùng tổ đội sau đó lại đến tìm ta."
    if not self:LuaFnHasTeam(selfId) then
        if showMessage and showMessage == 1 then
            self:MessageBox(selfId, targetId, szMsg)
        end
        return -1
    end
    szMsg = "Đội tổ đội kết hôn của đội ngũ nhất định chỉ có thể do nam nữ song phương tạo thành, trong đội ngũ không được có người Khác."
    if self:LuaFnGetTeamSize(selfId) ~= 2 then
        if showMessage and showMessage == 1 then
            self:MessageBox(selfId, targetId, szMsg)
        end
        return -1
    end
    szMsg = "Chỉ khi cả hai người cùng đến bên ta mới có thể kết hôn."
    local nearNum = self:GetNearTeamCount(selfId)
    if nearNum ~= 2 then
        if showMessage and showMessage == 1 then
            self:MessageBox(selfId, targetId, szMsg)
        end
        return -1
    end
    for nearIndex = 1, nearNum do
        local memId = self:GetNearTeamMember(selfId, nearIndex)
        if memId ~= selfId then
            marryTargetId = memId
        end
    end
    return marryTargetId
end

return m_marry
