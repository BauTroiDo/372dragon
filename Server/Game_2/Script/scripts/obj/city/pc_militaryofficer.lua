local class = require "class"
local define = require "define"
local script_base = require "script_base"
local pc_militaryofficer = class("pc_militaryofficer", script_base)
pc_militaryofficer.script_id = 805028
pc_militaryofficer.g_BuildingID16 = 11
pc_militaryofficer.g_eventList = {600030}
pc_militaryofficer.g_eventSetList = {600030}
pc_militaryofficer.TIME_2000_01_03_ = 946828868
pc_militaryofficer.g_BuffPalyer_25 = 60
pc_militaryofficer.g_BuffAll_15 = 62
pc_militaryofficer.g_BangGongLimit = 50
pc_militaryofficer.g_Item = 40004426

function pc_militaryofficer:UpdateEventList(selfId, targetId)
    local i = 1
    local eventId = 0
    local PlayerName = self:GetName(selfId)
    local guildid = self:GetHumanGuildID(selfId)
    local cityguildid = self:GetCityGuildID(selfId)
    local strText
    if (guildid ~= cityguildid) then
        self:BeginEvent(self.script_id)
        strText = "Người nào! Dám tự tiện xông vào bang hội ta!"
        self:AddText(strText)
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return
    end
    self:BeginEvent(self.script_id)
    strText = "Lão võ là Ô sự quan viên của thành này, tuy võ mỗ chỉ là một kẻ võ phu, nếu có cơ hội có thể so tài một phen, đúng rồi, còn gì chỉ giáo nữa không?"
    self:AddText(strText)
    self:AddText("    " .. PlayerName .. "! Đến làm nhiệm vụ Quốc phòng thôi!")
    local sceneId = self:get_scene_id()
    if self:CityGetSelfCityID(selfId) == sceneId then
        for i, eventId in pairs(self.g_eventList) do
            self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
        end
    end
    self:AddNumText("Quốc phòng nhiệm vụ tửu quán", 11, 1)
    self:AddNumText("Xây dựng vọng lâu", 6, 3)
    self:AddNumText("Tu luyệnTấn công", 6, 4)
    self:AddNumText("Cửa hàng công thức", 7, 5)
    self:AddNumText("võ phườngtửu quán", 11, 2)
    self:AddNumText("Nhận Kinh nghiệm gấp đôi", 6, 6)
    self:AddNumText("#{YPLJ_090116_01}", 6, 7)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function pc_militaryofficer:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function pc_militaryofficer:IsValidEvent(selfId, eventId)
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

function pc_militaryofficer:OnEventRequest(selfId, targetId, arg, index)
    if self:IsValidEvent(selfId, arg) == 1 then
        self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId)
        return
    end
    if index == 1 then
        self:BeginEvent(self.script_id)
        self:AddText("#{City_Defance_Mission_Help}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 2 then
        self:BeginEvent(self.script_id)
        self:AddText("#{City_Intro_WuFang}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 3 then
        self:BeginEvent(self.script_id)
        self:AddText("Chức năng này sắp được mở")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 4 then
        self:BeginEvent(self.script_id)
        self:AddText("Chức năng này sắp được mở")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 5 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:UICommand_AddInt(self.g_BuildingID16)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 104)
    elseif index == 6 then
        if self:CityGetMaintainStatus(selfId) == 1 then
            self:BeginEvent(self.script_id)
            self:AddText("  Hiện tại bang chúng ta đang ở trạng thái duy trì thấp, tất cả phúc lợi đều không thể cung cấp cho chư vị, vẫn là đồng cam cộng khổ cố gắng vì bản thành kiếm thêm nhiều #của tư kim mới tốt.")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end
        self:BeginEvent(self.script_id)
        self:AddText("Bôn tẩu giang hồ, chú trọng là hiệu suất, có muốn lĩnh chút thời gian kinh nghiệm gấp đôi không?")
        self:AddNumText("Ta muốn lĩnh một giờ gấp đôi kinh nghiệm", 6, 111)
        self:AddNumText("Ta muốn lĩnh hai giờ gấp đôi kinh nghiệm", 6, 222)
        self:AddNumText("Ta muốn lĩnh bốn giờ gấp đôi kinh nghiệm", 6, 333)
        self:AddNumText("Ta muốn tra thời gian kinh nghiệm gấp đôi của ta trong tuần này", 6, 444)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 7 then
        if self:GetItemCount(selfId, self.g_Item) >= 1 then
            self:BeginEvent(self.script_id)
            self:AddText("#{YPLJ_090116_02}")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end
        if self:CityGetAttr(selfId, 6) < self.g_BangGongLimit then
            self:BeginEvent(self.script_id)
            self:AddText("#{YPLJ_090116_03}")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end
        self:BeginEvent(self.script_id)
        self:AddText("#{YPLJ_090116_04}")
        self:AddNumText("#{YPLJ_090116_05}", 6, 8)
        self:AddNumText("#{YPLJ_090116_06}", 6, 9)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    elseif index == 8 then
        if self:GetItemCount(selfId, self.g_Item) >= 3 then return end
        local nGuildPoint = self:CityGetAttr(selfId, 6)
        if nGuildPoint < self.g_BangGongLimit then return end
        self:BeginAddItem()
        self:AddItem(self.g_Item, 1)
        local ret = self:EndAddItem(selfId)
        if not ret then
            self:BeginEvent(self.script_id)
            self:AddText("#{YPLJ_090116_07}")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end
        if self:CityChangeAttr(selfId, 6, -self.g_BangGongLimit) ~= 1 then
            self:BeginEvent(self.script_id)
            self:AddText("#{YPLJ_090116_08}")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end
        self:AddItemListToHuman(selfId)
        self:BeginEvent(self.script_id)
        self:AddText("#{YPLJ_090116_09}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    elseif index == 9 then
        self:BeginUICommand()
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
        return
    elseif index == 111 then
        self:DoubleExpTime(selfId, targetId, 1)
    elseif index == 222 then
        self:DoubleExpTime(selfId, targetId, 2)
    elseif index == 333 then
        self:DoubleExpTime(selfId, targetId, 4)
    elseif index == 444 then
        local _, nCount = self:DEGetCount(selfId)
        if nCount == 0 then
            self:BeginEvent(self.script_id)
            self:AddText("Thật là tiếc, ta có thể cung cấp cho ngươi thời gian kinh nghiệm gấp đôi của tuần này là ((R_CAP)) 0 giờ#W rồi.")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        else
            self:BeginEvent(self.script_id)
            self:AddText("  Ta có thể cung cấp cho ngươi thời gian gấp đôi kinh nghiệm tuần này là #R" ..  nCount .. "giờ#W, mau tận dụng tốt đi.")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        end

    elseif index == 201 then
        self:DealDoubleExpTime(selfId, targetId, index - 200)
    elseif index == 202 then
        self:DealDoubleExpTime(selfId, targetId, index - 200)
    elseif index == 204 then
        self:DealDoubleExpTime(selfId, targetId, index - 200)
    elseif index == 300 then
        self:BeginUICommand()
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
        return
    end
end

function pc_militaryofficer:DealDoubleExpTime(selfId, targetId, nPoint)
    local nGuildPos = self:GetGuildPos(selfId)
    local BasePoint = 25
    if nGuildPos == 8 then
        BasePoint = 12.5
    elseif nGuildPos == 9 then
        BasePoint = 0
    else
        BasePoint = 25
    end
    local bTimeOk = 1
    if nGuildPos == 8 or nGuildPos == 9 then
        local isPosLongEnough = self:IsGuildPosLongEnough(selfId)
        if isPosLongEnough < 1 then
            bTimeOk = 0
            BasePoint = 25
        end
    else
        bTimeOk = -1
    end
    local nCity = self:CityGetAttr(selfId, 6)
    if nCity < math.floor(BasePoint * nPoint) then
        self:BeginEvent(self.script_id)
        self:AddText("  Ngươi không có đủ điểm cống hiến bang hội để tiêu hao.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if BasePoint ~= 0 then
        if self:CityChangeAttr(selfId, 6, -(math.floor(BasePoint * nPoint))) ~= 1 then
            self:BeginEvent(self.script_id)
            self:AddText(" Trừ điểm cống hiến bang hội thất bại, xin hãy thử lại sau.")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end
    end
    local _, nCount = self:DEGetCount(selfId)
    if nCount < nPoint then return end
    local nCurHave = self:DEGetFreeTime(selfId)
    nCurHave = nCurHave + self:DEGetMoneyTime(selfId)
    local nFreeTime = self:DEGetFreeTime(selfId)
    local nTrueTime = nCurHave
    if nTrueTime < 0 then nTrueTime = 0 end
    self:WithDrawFreeDoubleExpTime(selfId, 0, nPoint, 0)
    local nCurTime = self:LuaFnGetCurrentTime()
    self:BeginEvent(self.script_id)
    self:AddText("  Ngươi đã thành công lĩnh #R" .. nPoint ..  "giờ #Wcủa song bội kinh nghiệm thời gian. Hiện tại ngươi tổng cộng có #Y" .. tostring(math.floor((nTrueTime + nPoint * 3600) / 60)) .. "phút #Wcủa song bội kinh nghiệm thời gian")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Ngươi đã thành công lĩnh #R" .. nPoint .. "giờ #Wcủa song bội kinh nghiệm thời gian. Hiện tại ngươi tổng cộng có #Y" ..  tostring(math.floor((nTrueTime + nPoint * 3600) / 60)) .. "phút #Wcủa song bội kinh nghiệm thời gian")
    self:EndEvent()
    self:DispatchMissionTips(selfId)
    if bTimeOk == 1 then
        if nGuildPos == 8 then
            self:BeginEvent(self.script_id)
            self:AddText( "  Do ngươi đảm nhiệm Phó Bang Chủ đã hơn một tuần, lần này nhận lĩnh song tu tiêu hao bang cống giảm một nửa.")
            self:EndEvent()
            self:DispatchMissionTips(selfId)
        elseif nGuildPos == 9 then
            self:BeginEvent(self.script_id)
            self:AddText("  Do ngươi đảm nhiệm Bang Chủ đã hơn một tuần, lần này nhận lĩnh song tu không tiêu hao bang cống.")
            self:EndEvent()
            self:DispatchMissionTips(selfId)
        end
    end
    self:SendDoubleExpToClient(selfId)
end

function pc_militaryofficer:DoubleExpTime(selfId, targetId, nTime)
    if self:CityGetMaintainStatus(selfId) == 1 then
        self:BeginEvent(self.script_id)
        self:AddText("  Hiện tại bang chúng ta đang ở trạng thái duy trì thấp, tất cả phúc lợi đều không thể cung cấp cho chư vị, vẫn là đồng cam cộng khổ cố gắng vì bản thành kiếm thêm nhiều #của tư kim mới tốt.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    local nCurTime = self:LuaFnGetCurrentTime()
    local nPreTime = self:DEGetPreTime(selfId)
    if (nCurTime - nPreTime >= 3600 * 24 * 7) or
        (math.floor((nCurTime - self.TIME_2000_01_03_) / (3600 * 24 * 7)) ~=
            math.floor((nPreTime - self.TIME_2000_01_03_) / (3600 * 24 * 7))) then
        self:DEResetWeeklyFreeTime(selfId)
    end
    self:AddDETime(selfId, targetId, nTime, nCurTime, nPreTime)
end

function pc_militaryofficer:AddDETime(selfId, targetId, nPoint, nCurTime, nPreTime)
    local nCurHave = self:DEGetFreeTime(selfId)
    nCurHave = nCurHave + self:DEGetMoneyTime(selfId)
    local nTrueTime = nCurHave
    local nFreeTime = self:DEGetFreeTime(selfId)
    if nTrueTime < 0 then nTrueTime = 0 end
    local _, nCount = self:DEGetCount(selfId)
    if (nCount <= 0) then
        self:BeginEvent(self.script_id)
        self:AddText("Thời gian kinh nghiệm gấp đôi của ngươi trong tuần này dường như đã dùng hết rồi.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if nCount < nPoint then
        self:BeginEvent(self.script_id)
        self:AddText("  Ngươi không có nhiều thời gian như vậy để có thể lĩnh nhận nữa rồi.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end

    if nFreeTime >= 120 * 60 then
        self:BeginEvent(self.script_id)
        self:AddText("Ngươi nhận thời gian kinh nghiệm gấp đôi tại tam đại thành thị và Tự kiến thành thị đã đạt đến giới hạn có thể lĩnh")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end

    if nFreeTime + nPoint * 3600 > 3600 * 4 then
        self:BeginEvent(self.script_id)
        self:AddText("Ngươi nhận thời gian kinh nghiệm gấp đôi tại tam đại thành thị và Tự kiến thành thị đã đạt đến giới hạn có thể lĩnh")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if self:DEIsLock(selfId) then
        self:BeginEvent(self.script_id)
        self:AddText( "Ngươi còn thời gian kinh nghiệm gấp đôi bị đóng băng, hay là giải đóng băng rồi lĩnh thời gian kinh nghiệm gấp đôi mới đi.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    self:BeginEvent(self.script_id)
    if (nTrueTime / 60) > 0 then
        self:AddText("  Thời gian gấp đôi kinh nghiệm trong tuần này của ngươi còn #R" ..
                         tostring(math.floor(nCount)) ..
                         "giờ#W, hiện đã có thời gian gấp đôi kinh nghiệm #Y" ..
                         tostring(math.floor(nTrueTime / 60)) ..
                         "phút#W, ngươi xác nhận muốn lĩnh #Y" ..
                         tostring(math.floor(nPoint * 60)) ..
                         "phút#W thời gian gấp đôi kinh nghiệm, đồng thời tiêu hao cống hiến bang hội" ..
                         tostring(math.floor(nPoint * 25)) ..
                         "không?#r Nếu như ngươi đảm nhiệm chức bang chủ trên một tuần, có thể không cần tiêu hao cống bang, phó bang chủ có thể giảm một nửa.")
    else
        self:AddText("  Thời gian gấp đôi kinh nghiệm trong tuần này của ngươi còn #R" ..
                         tostring(math.floor(nCount)) ..
                         "Giờ#W, ngươi xác nhận muốn lĩnh#Y" ..
                         tostring(math.floor(nPoint * 60)) ..
                         "phút#W thời gian gấp đôi kinh nghiệm, đồng thời tiêu hao cống hiến bang hội" ..
                         tostring(math.floor(nPoint * 25)) ..
                         "không?#r Nếu như ngươi đảm nhiệm chức bang chủ trên một tuần, có thể không cần tiêu hao cống bang, phó bang chủ có thể giảm một nửa.")
    end
    if self:LuaFnHaveImpactOfSpecificDataIndex(selfId, self.g_BuffPalyer_25) or self:LuaFnHaveImpactOfSpecificDataIndex(selfId, self.g_BuffAll_15) then
        self:AddText("  #r  #RXin chú ý: Trên người ngài đã có thời gian kinh nghiệm bội số, có xác nhận lĩnh hay không?")
    end
    self:AddNumText("Vâng, ta muốn lĩnh.", -1, 200 + nPoint)
    self:AddNumText("Không cần, ta bấm nhầm rồi.", -1, 300)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function pc_militaryofficer:OnMissionAccept(selfId, targetId, missionScriptId)
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

function pc_militaryofficer:OnMissionRefuse(selfId, targetId, missionScriptId)
    if self:IsValidEvent(selfId, missionScriptId) == 1 then
        self:UpdateEventList(selfId, targetId)
        return
    end
end

function pc_militaryofficer:OnMissionContinue(selfId, targetId, missionScriptId)
    if self:IsValidEvent(selfId, missionScriptId) == 1 then
        self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
        return
    end
end

function pc_militaryofficer:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    if self:IsValidEvent(selfId, missionScriptId) == 1 then
        self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId,  selectRadioId)
        return
    end
end

function pc_militaryofficer:OnDie(selfId, killerId) end

function pc_militaryofficer:NotifyFailTips(selfId, Tip)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return pc_militaryofficer
