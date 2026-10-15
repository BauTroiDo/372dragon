local class = require "class"
local define = require "define"
local script_base = require "script_base"
local pc_techofficer = class("pc_techofficer", script_base)
local ScriptGlobal = require "scripts.ScriptGlobal"
pc_techofficer.script_id = 805015
pc_techofficer.g_BuildingID9 = 13
pc_techofficer.g_eventList = {600012}
pc_techofficer.g_eventSetList = {600012}
pc_techofficer.g_MingTieNeedBangGong = 50
pc_techofficer.g_TangJinMingTieID = 30505205
pc_techofficer.g_TangJinMingTieCount = 1

function pc_techofficer:UpdateEventList(selfId, targetId)
    local i = 1
    local eventId = 0
    local Humanguildid = self:GetHumanGuildID(selfId)
    local cityguildid = self:GetCityGuildID(selfId)
    self:BeginEvent(self.script_id)
    if Humanguildid == cityguildid then
        self:AddText("    Cái hưng thịnh của cả thành, không gì nằm ngoài kỹ thuật cao thâm, chúng ta là huynh đệ cùng bang, có gì ta có thể giúp ngươi, cứ mở lời.")
        for i, eventId in pairs(self.g_eventList) do
            self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
        end
        self:AddNumText("Khoa kỹ nhiệm vụ tửu quán", 11, 1)
        self:AddNumText("Nghiên cứu hàng hóa mới của", 6, 4)
        self:AddNumText("Tượng Điêu Khắc Thành Thị", 6, 5)
        self:AddNumText("Chế tạo Huy Hiệu Bang Hội", 6, 6)
        self:AddNumText("Tửu quán Thư Phòng", 11, 2)
        self:AddNumText("Lĩnh Thưởng Thiệp Vàng", 6, 20)
        self:AddNumText("Về việc nhận danh hiệu tùy chỉnh Bang Hội", 11, 22)
        self:CallScriptFunction(define.CITY_BUILDING_ABILITY_SCRIPT, "AddCityLifeAbilityOpt", selfId, self.script_id, self.g_BuildingID9, 888)
    else
        local PlayerGender = self:GetSex(selfId)
        local rank
        if PlayerGender == 0 then
            rank = "Cô nương"
        elseif PlayerGender == 1 then
            rank = "Tiên sinh"
        else
            rank = "Xin hỏi"
        end
        self:AddText("    Ái da!" .. rank ..  "Khảng khái chẳng phải người trong bổn bang, tiểu sinh xin phép không tiện nhiều lời.")
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function pc_techofficer:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function pc_techofficer:IsValidEvent(selfId, eventId)
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

function pc_techofficer:OnEventRequest(selfId, targetId, arg, index)
    if self:IsValidEvent(selfId, arg) == 1 then
        self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId)
        return
    elseif arg ~= self.script_id then
        self:CallScriptFunction(define.CITY_BUILDING_ABILITY_SCRIPT, "OnDefaultEvent", selfId, targetId, arg, self.script_id, self.g_BuildingID9)
        return
    end
    if index == 1 then
        self:BeginEvent(self.script_id)
        self:AddText("#{City_Tec_Mission_Help}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 2 then
        self:BeginEvent(self.script_id)
        self:AddText("#{City_Intro_ShuFang}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 4 then
        self:BeginEvent(self.script_id)
        self:AddText("Chức năng này sắp được mở")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 5 then
        self:BeginEvent(self.script_id)
        self:AddText("Chức năng này sắp được mở")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 6 then
        self:BeginEvent(self.script_id)
        self:AddText("Chức năng này sắp được mở")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 20 then
        self:BeginEvent(self.script_id)
        self:AddText("#{TJMT_090213_01}")
        self:AddNumText("Vâng, ta xác định.", 6, 201)
        self:AddNumText("Không, ta vẫn là không cần.", 6, 202)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 201 then
        self:GetTangJinMinTie(selfId, targetId)
    elseif index == 202 then
        self:BeginEvent(self.script_id)
        self:OnDefaultEvent(selfId, targetId)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 22 then
        self:BeginEvent(self.script_id)
        self:AddText("#{TangJinMingTie_Help}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 888 then
        self:BeginEvent(self.script_id)
        self:CallScriptFunction(define.CITY_BUILDING_ABILITY_SCRIPT, "OnEnumerate", self, selfId, targetId, self.g_BuildingID9)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

function pc_techofficer:OnMissionAccept(selfId, targetId, missionScriptId)
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

function pc_techofficer:OnMissionRefuse(selfId, targetId, missionScriptId)
    if self:IsValidEvent(selfId, missionScriptId) == 1 then
        self:UpdateEventList(selfId, targetId)
        return
    end
end

function pc_techofficer:OnMissionContinue(selfId, targetId, missionScriptId)
    if self:IsValidEvent(selfId, missionScriptId) == 1 then
        self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
        return
    end
end

function pc_techofficer:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    if self:IsValidEvent(selfId, missionScriptId) == 1 then
        self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
        return
    end
end

function pc_techofficer:OnDie(selfId, killerId) end

function pc_techofficer:NotifyFailTips(selfId, Tip)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function pc_techofficer:GetTangJinMinTie(selfId, targetId)
    local szMsg = nil
    local nBangGongPoint = self:CityGetAttr(selfId, ScriptGlobal.GUILD_CONTRIB_POINT)
    if nBangGongPoint < self.g_MingTieNeedBangGong then
        szMsg = string.format("    Cống hiến bang hội của các hạ không đủ #G%d#W, không thể đổi tên chức vị tùy chỉnh.", self.g_MingTieNeedBangGong)
        self:NotifyFailTips(selfId, szMsg)
        return
    end
    if (self:LuaFnGetPropertyBagSpace(selfId) < self.g_TangJinMingTieCount) then
        self:NotifyFailTips(selfId, "#{YRJ_BagFullTip}")
        return
    end
    local ret = self:CityChangeAttr(selfId, 6, -self.g_MingTieNeedBangGong)
    if not ret then
        self:NotifyFailTips(selfId, "    Không thể khấu trừ cống hiến bang hội, xin hãy thử lại!")
        return
    end
    self:BeginAddItem()
    self:AddItem(self.g_TangJinMingTieID, self.g_TangJinMingTieCount)
    self:EndAddItem(selfId)
    self:AddItemListToHuman(selfId)
    self:BeginEvent(self.script_id)
    self:AddText("    Đây là một tấm #GThiếp Vàng#W, cầm lấy, hãy dùng cho tốt!")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return pc_techofficer
