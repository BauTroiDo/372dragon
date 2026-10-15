local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_jiangli = class("oluoyang_jiangli", script_base)
oluoyang_jiangli.script_id = 000102
oluoyang_jiangli.g_ShopTabId = 15
oluoyang_jiangli.g_eventList = {}

oluoyang_jiangli.g_ControlScript = 050009
oluoyang_jiangli.g_ExchangeList = {
    ["id"] = 40004303,
    ["name"] = "Bột Mì Tinh Chế",
    ["cost"] = 20
}

function oluoyang_jiangli:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(
        "  Trên trời bay, dưới đất chạy, dưới nước bơi, muốn ăn gì Mính Trân Lâu ta đều có!")
    --self:AddNumText("购买食物", 7, 1111)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_jiangli:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oluoyang_jiangli:OnEventRequest(selfId, targetId, arg, index)
    if index == 1111 then
        --self:DispatchShopItem(selfId, targetId, self.g_ShopTabId)
    end
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId)
            return
        end
    end
    if self:CallScriptFunction(self.g_ControlScript, "IsMidAutumnPeriod", selfId) >
        0 then
        if index == 1 then
            local score = self:GetMissionData(selfId, define.MD_ENUM.MD_MIDAUTUMN_SCORE)
            if score < self.g_ExchangeList["cost"] then
                self:NotifyFailBox(selfId, targetId,
                                   "    Muốn đổi một phần." ..
                                       self.g_ExchangeList["name"] ..
                                       ", Yêu cầu tích phân" ..
                                       self.g_ExchangeList["cost"] ..
                                       "điểm, ngươi hiện tại chỉ có" .. score ..
                                       "điểm, hình như không đủ a.")
                return
            end
            self:BeginEvent(self.script_id)
            self:AddText("  Ngươi hiện tại của Trung Thu tích phân là" .. score ..
                             "điểm, đổi một phần" .. self.g_ExchangeList["name"] ..
                             ", Yêu cầu tích phân" .. self.g_ExchangeList["cost"] ..
                             "điểm, ngươi xác định muốn đổi không?")
            self:AddNumText("Xác định muốn đổi chứ?", -1, 3)
            self:AddNumText("Ta chỉ là đi ngang qua.", -1, 4)
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        elseif index == 2 then
            self:NotifyFailBox(selfId, targetId,
                               "    Tại Lạc Dương Khương Lý (127," ..
                                   "154), Tô Châu Bao Thế Vinh (190,168), Đại Lý Đỗ Tử Đằng (109,170) lần lượt đổi" ..
                                   "ba loại khác nhau của nguyên liệu nấu ăn, sau đó tìm Tô Châu (193,148) Nhạc Thường Viên truyền tống đến Tây Hồ để đổi Trung Thu" ..
                                   "vật phẩm đặc biệt.")
            return
        elseif index == 3 then
            local score = self:GetMissionData(selfId, define.MD_ENUM.MD_MIDAUTUMN_SCORE)
            if score < self.g_ExchangeList["cost"] then return end
            if not self:TryRecieveItem(selfId, self.g_ExchangeList["id"]) then
                self:NotifyFailBox(selfId, targetId, "    Túi đầy rồi!")
            end
            score = score - self.g_ExchangeList["cost"]
            self:SetMissionData(selfId, define.MD_ENUM.MD_MIDAUTUMN_SCORE, score)
            self:NotifyFailBox(selfId, targetId,
                               "    Điểm tích lũy còn lại:" .. score .. "。")
            return
        elseif index == 4 then
            self:BeginUICommand()
            self:EndUICommand()
            self:DispatchUICommand(selfId, 1000)
        end
        return
    end
end

function oluoyang_jiangli:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            local ret =
                self:CallScriptFunction(missionScriptId, "CheckAccept", selfId)
            if ret > 0 then
                self:CallScriptFunction(missionScriptId, "OnAccept", selfId)
            end
            return
        end
    end
end

function oluoyang_jiangli:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oluoyang_jiangli:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId,
                                    targetId)
            return
        end
    end
end

function oluoyang_jiangli:OnMissionSubmit(selfId, targetId, missionScriptId,
                                          selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId,
                                    targetId, selectRadioId)
            return
        end
    end
end

function oluoyang_jiangli:OnDie(selfId, killerId) end

function oluoyang_jiangli:NotifyFailBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oluoyang_jiangli
