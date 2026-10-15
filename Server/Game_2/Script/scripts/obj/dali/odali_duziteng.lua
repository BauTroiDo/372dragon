local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_duziteng = class("odali_duziteng", script_base)
odali_duziteng.script_id = 002028
odali_duziteng.g_shoptableindex = 5
odali_duziteng.g_eventList = {210201, 210202, 210203}

odali_duziteng.g_ControlScript = 050009
odali_duziteng.g_ExchangeList = {["id"] = 40004305, ["name"] = "Đường mía hảo hạng", ["cost"] = 55}

function odali_duziteng:UpdateEventList(selfId, targetId)
    local PlayerName = self:GetName(selfId)
    local PlayerSex = self:GetSex(selfId)
    if PlayerSex == 0 then
        PlayerSex = "Cô nương"
    else
        PlayerSex = "Thiếu hiệp"
    end
    self:BeginEvent(self.script_id)
    self:AddText("  " .. PlayerName .. PlayerSex .. ", có muốn nếm thử món ăn vặt nổi tiếng của Đại Lý chúng ta không? Đảm bảo ngươi ăn tám bát rồi lại tám bát, đi cũng không muốn đi.")
    --self:AddNumText("购买食品", 7, 0)
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function odali_duziteng:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function odali_duziteng:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
    if index == 0 then
        --self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
    end
    if self:CallScriptFunction(self.g_ControlScript, "IsMidAutumnPeriod", selfId) > 0 then
        if index == 1 then
            local score = self:GetMissionData(selfId, define.MD_ENUM.MD_MIDAUTUMN_SCORE)
            if score < self.g_ExchangeList["cost"] then
                self:NotifyFailBox(
                    selfId,
                    targetId,
                    "    Muốn đổi một phần." ..
                        self.g_ExchangeList["name"] ..
                            ", Yêu cầu tích phân" .. self.g_ExchangeList["cost"] .. "điểm, ngươi hiện tại chỉ có" .. score .. "điểm, hình như không đủ a."
                )
                return
            end
            self:BeginEvent(self.script_id)
            self:AddText(
                "  Ngươi hiện tại của Trung Thu tích phân là" ..
                    score ..
                        "điểm, đổi một phần" .. self.g_ExchangeList["name"] .. ", Yêu cầu tích phân" .. self.g_ExchangeList["cost"] .. "điểm, ngươi xác định muốn đổi không?"
            )
            self:AddNumText("Xác định muốn đổi chứ?", -1, 3)
            self:AddNumText("Ta chỉ là đi ngang qua.", -1, 4)
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        elseif index == 2 then
            self:NotifyFailBox(
                selfId,
                targetId,
                "    Tại Lạc Dương Khương Lý (127," ..
                    "154), Tô Châu Bao Thế Vinh (190,168), Đại Lý Đỗ Tử Đằng (109,170) lần lượt đổi" .. "ba loại khác nhau của nguyên liệu nấu ăn, sau đó tìm Tô Châu (193,148) Nhạc Thường Viên truyền tống đến Tây Hồ để đổi Trung Thu" .. "vật phẩm đặc biệt."
            )
            return
        elseif index == 3 then
            local score = self:GetMissionData(selfId, define.MD_ENUM.MD_MIDAUTUMN_SCORE)
            if score < self.g_ExchangeList["cost"] then
                return
            end
            if not self:LuaFnTryRecieveItem(selfId, self.g_ExchangeList["id"]) then
                self:NotifyFailBox(selfId, targetId, "    Túi đầy rồi!")
            end
            score = score - self.g_ExchangeList["cost"]
            self:SetMissionData(selfId, define.MD_ENUM.MD_MIDAUTUMN_SCORE, score)
            self:NotifyFailBox(selfId, targetId, "    Điểm tích lũy còn lại:" .. score .. "。")
            return
        elseif index == 4 then
            self:BeginUICommand()
            self:EndUICommand()
            self:DispatchUICommand(selfId, 1000)
        end
        return
    end
end

function odali_duziteng:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            local ret = self:CallScriptFunction(missionScriptId, "CheckAccept", selfId)
            if ret > 0 then
                self:CallScriptFunction(missionScriptId, "OnAccept", selfId)
            end
            return
        end
    end
end

function odali_duziteng:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function odali_duziteng:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function odali_duziteng:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function odali_duziteng:OnDie(selfId, killerId)
end

function odali_duziteng:NotifyFailBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return odali_duziteng
