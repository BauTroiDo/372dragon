local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local pc_agriculturalofficer = class("pc_agriculturalofficer", script_base)
pc_agriculturalofficer.script_id = 805014
pc_agriculturalofficer.g_BuildingID8 = 7
pc_agriculturalofficer.g_eventList = {600007}
pc_agriculturalofficer.g_eventSetList = {600007}

function pc_agriculturalofficer:UpdateEventList(selfId, targetId)
    local i = 1
    local eventId = 0
    local Humanguildid = self:GetHumanGuildID(selfId)
    local cityguildid = self:GetCityGuildID(selfId)
    self:BeginEvent(self.script_id)
    if Humanguildid == cityguildid then
        self:AddText("    Bang hội cường thịnh là ở nơi nông nghiệp, có yêu cầu gì ta có thể giúp ngươi chăng?")
        for i, eventId in pairs(self.g_eventList) do
            self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
        end
        self:AddNumText("Phát triển nhiệm vụ tửu quán", 11, 1)
        self:AddNumText("Gia cố tường thành", 6, 3)
        self:AddNumText("Tửu quán kho lúa", 11, 2)
        self:AddNumText("Đổi lấy Dưa Hấu Ướp Lạnh", 6, 4)
        self:AddNumText("Tửu quán Dưa Hấu Ướp Lạnh", 11, 5)
        self:CallScriptFunction(define.CITY_BUILDING_ABILITY_SCRIPT, "AddCityLifeAbilityOpt", selfId, self.script_id, self.g_BuildingID8, 888)
    else
        self:AddText("    Các hạ không phải thành viên bản bang, trông lạ mặt quá!")
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function pc_agriculturalofficer:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function pc_agriculturalofficer:IsValidEvent(selfId, eventId)
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

function pc_agriculturalofficer:OnEventRequest(selfId, targetId, arg, index)
    if self:IsValidEvent(selfId, arg) == 1 then
        self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId)
        return
    elseif arg ~= self.script_id then
        self:CallScriptFunction(define.CITY_BUILDING_ABILITY_SCRIPT, "OnDefaultEvent", selfId, targetId, arg, self.script_id, self.g_BuildingID8)
        return
    end
    if index == 1 then
        self:BeginEvent(self.script_id)
        self:AddText("#{City_Dev_Mission_Help}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 2 then
        self:BeginEvent(self.script_id)
        self:AddText("#{City_Intro_MiCang}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 3 then
        self:BeginEvent(self.script_id)
        self:AddText("Chức năng này sắp được mở")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 888 then
        self:BeginEvent(self.script_id)
        self:CallScriptFunction(define.CITY_BUILDING_ABILITY_SCRIPT, "OnEnumerate", self, selfId, targetId, self.g_BuildingID8)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 4 then
        self:BeginEvent(self.script_id)
        self:AddText("#{BGHXG_JS}")
        self:AddText("Ngươi xác nhận muốn dùng 9 điểm cống hiến bang để đổi lấy Dưa Hấu Ướp Lạnh không?")
        self:AddNumText("确认", 6, 16)
        self:AddNumText("Hủy bỏ", 8, 17)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 5 then
        self:BeginEvent(self.script_id)
        self:AddText("#{BGHXG_JS}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 16 then
        self:BingZhenXiGua(selfId, targetId)
    elseif index == 17 then
        self:OnDefaultEvent(selfId, targetId)
    end
end

function pc_agriculturalofficer:OnMissionAccept(selfId, targetId, missionScriptId)
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

function pc_agriculturalofficer:OnMissionRefuse(selfId, targetId,  missionScriptId)
    if self:IsValidEvent(selfId, missionScriptId) == 1 then
        self:UpdateEventList(selfId, targetId)
        return
    end
end

function pc_agriculturalofficer:OnMissionContinue(selfId, targetId,  missionScriptId)
    if self:IsValidEvent(selfId, missionScriptId) == 1 then
        self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
        return
    end
end

function pc_agriculturalofficer:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    if self:IsValidEvent(selfId, missionScriptId) == 1 then
        self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
        return
    end
end

function pc_agriculturalofficer:OnDie(selfId, killerId) end

function pc_agriculturalofficer:NotifyFailTips(selfId, Tip)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function pc_agriculturalofficer:BingZhenXiGua(selfId, targetId)
    local humanGuildId = self:GetHumanGuildID(selfId)
    local cityGuildId = self:GetCityGuildID(selfId)
    if not humanGuildId or not cityGuildId or humanGuildId ~= cityGuildId then
        self:BeginEvent(self.script_id)
        self:AddText("Chỉ có thành viên bổn bang mới có thể đổi.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return 0
    end
    local guildPoint = self:CityGetAttr(selfId, 6)
    if not guildPoint or guildPoint < 9 then
        self:BeginEvent(self.script_id)
        self:AddText("Ngươi cống hiến bang không đủ 9 điểm, không thể đổi.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return 0
    end
    self:LuaFnBeginAddItem()
    self:LuaFnAddItem(30501103, 1)
    local ret = self:LuaFnEndAddItem(selfId)
    if not ret then
        self:BeginEvent(self.script_id)
        self:AddText("Ngươi hiện tại không thể nhận được vật phẩm, xin kiểm tra hành trang.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return 0
    end
    ret = self:CityChangeAttr(selfId, 6, -9)
    if not ret then
        self:BeginEvent(self.script_id)
        self:AddText("Thao tác thất bại, xin thử lại.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return 0
    end
    self:AddItemListToHuman(selfId)
    self:NotifyFailTips(selfId, "Ngươi nhận được một Dưa Hấu Ướp Lạnh.")
    local szTransferItem = self:GetItemTransfer(selfId, 0)
    local selfName = self:LuaFnGetName(selfId)
    selfName = gbk.fromutf8(selfName)
    local strChatMessage = "#{_INFOUSR" .. selfName ..    gbk.fromutf8("}#P Vui vẻ cướp lấy một miếng #Y#{_INFOMSG") ..  szTransferItem .. gbk.fromutf8("}#P, chỉ cần cắn một miếng là mát lạnh từ đỉnh đầu xuống tận lòng bàn chân!")
    self:BroadMsgByChatPipe(selfId, "@*;SrvMsg;GLD:" .. strChatMessage, 6)
    self:OnDefaultEvent(selfId, targetId)
end

return pc_agriculturalofficer
