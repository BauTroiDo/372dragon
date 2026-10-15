local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_liangdaoshi = class("osuzhou_liangdaoshi", script_base)
osuzhou_liangdaoshi.script_id = 001086
osuzhou_liangdaoshi.g_eventList = {808131}

function osuzhou_liangdaoshi:UpdateEventList(selfId, targetId)
    local PlayerName = self:GetName(selfId)
    local PlayerSex = self:GetSex(selfId)
    if PlayerSex == 0 then
        PlayerSex = "Cô nương"
    else
        PlayerSex = "Thiếu hiệp"
    end
    self:BeginEvent(self.script_id)
    self:AddText(" #{XCHQ_90601_1}")
    self:AddNumText("#{SQXY_09061_5}", 6,100)
    self:AddNumText("#{XCHQ_90609_2}", 6,200)
    self:AddNumText("#{SQXY_09061_6}", 11,5000)
    self:AddNumText("#{XCHQ_90609_4}", 11,5100)
    self:AddNumText("#{XCHQ_90609_3}", 11,5200)
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osuzhou_liangdaoshi:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function osuzhou_liangdaoshi:OnEventRequest(selfId, targetId, arg, index)
    local nNumText = index
    if nNumText == 100 then
        self:BeginEvent(self.script_id)
        self:AddNumText("Đổi Tinh Hoa Cường Hóa Thiên Cang", 6,101)
        self:AddNumText("Đổi Hồng Bảo Thạch(cấp 3)", 6,102)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
    if nNumText == 101 then
        self:BeginEvent(self.script_id)
        self:AddText("Đổi Thiên Cương Cường Hóa Tinh Hoa cần#G7#Wquả ước nguyện, chắc chắn đổi chứ?")
        self:AddNumText("Ta muốn đổi", 0,103)
        self:AddNumText("Rời đi", 0,1000)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif nNumText == 102 then
        self:BeginEvent(self.script_id)
        self:AddText("Đổi Hồng Bảo Thạch (cấp 3) cần#G20#Wquả ước nguyện, chắc chắn đổi chứ?")
        self:AddNumText("Ta muốn đổi", 0,104)
        self:AddNumText("Rời đi", 0,1000)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
    if nNumText == 103 then
        if self:LuaFnGetAvailableItemCount(selfId,20502010) < 7 then
            self:MsgBox(selfId,targetId," #{SQXY_09061_26}7#{SQXY_09061_27}")
            return
        end
        if not self:LuaFnDelAvailableItem(selfId,20502010,7) then
            self:MsgBox(selfId,targetId,"Trừ quả ước nguyện thất bại.")
            return
        end
        self:BeginAddItem()
        self:AddItem(30900006,1)
        if not self:EndAddItem(selfId) then
            self:MsgBox(selfId,targetId," #{SQXY_09061_20}")
            return
        end
        self:TryRecieveItem(selfId,30900006,true)
        self:MsgBox(selfId,targetId,"#{SQXY_09061_28}")
    elseif nNumText == 104 then
        if self:LuaFnGetAvailableItemCount(selfId,20502010) < 20 then
            self:MsgBox(selfId,targetId," #{SQXY_09061_26}20#{SQXY_09061_27}")
            return
        end
        if not self:LuaFnDelAvailableItem(selfId,20502010,20) then
            self:MsgBox(selfId,targetId,"Trừ quả ước nguyện thất bại.")
            return
        end
        self:BeginAddItem()
        self:AddItem(50313004,1)
        if not self:EndAddItem(selfId) then
            self:MsgBox(selfId,targetId," #{SQXY_09061_35}")
            return
        end
        self:TryRecieveItem(selfId,50313004,true)
        self:MsgBox(selfId,targetId,"#{SQXY_09061_28}")
    end
    if nNumText == 200 then
        self:BeginEvent(self.script_id)
        self:AddText(" #{XCHQ_90609_5}")
        self:AddNumText("#{XCHQ_90601_2}", 6,201)
        self:AddNumText("#{XCHQ_90601_3}", 6,202)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
    if nNumText == 201 then
        if self:LuaFnGetAvailableItemCount(selfId,20502011) < 10 then
            self:NotifyFailTips(selfId,"#{XCHQ_90601_5}")
            return
        end
        if not self:LuaFnDelAvailableItem(selfId,20502011,10) then
            self:NotifyFailTips(selfId,"#{XCHQ_90601_6}")
            return
        end
        self:BeginAddItem()
        self:AddItem(30005045,1)
        if not self:EndAddItem(selfId) then
            self:NotifyFailTips(selfId," #{XCHQ_90601_7}")
            return
        end
        self:TryRecieveItem(selfId,30005045,true)
        self:NotifyFailTips(selfId,"#{XCHQ_90601_8}")
    elseif nNumText == 202 then
        if self:LuaFnGetAvailableItemCount(selfId,20502011) < 120 then
            self:NotifyFailTips(selfId,"#{XCHQ_90601_9}")
            return
        end
        if not self:LuaFnDelAvailableItem(selfId,20502011,120) then
            self:NotifyFailTips(selfId,"#{XCHQ_90601_6}")
            return
        end
        self:BeginAddItem()
        self:AddItem(30005045,1)
        if not self:EndAddItem(selfId) then
            self:NotifyFailTips(selfId," #{XCHQ_90601_7}")
            return
        end
        self:TryRecieveItem(selfId,30005045,true)
        self:NotifyFailTips(selfId,"#{XCHQ_90601_10}")
    end
    if nNumText == 1000 then
        self:CloseMe(selfId)
    end
    if nNumText == 5000 then
        self:BeginEvent(self.script_id)
        self:AddText("#YNgười có đang ấp ủ một nguyện vọng mỹ lệ chăng?#W#r #r    Tương truyền#GThái Hồ#W nơi#G（159,187）#W có mọc một cây#GHứa Nguyện Thụ#W thần diệu, anh hùng đến#G30 cấp#W liền có thể nhận nhiệm vụ#G“Một ngàn lẻ một nguyện vọng”#W, tìm được#GNguyện Linh Tuyền#W, mang theo tấm chân tình của người mà tưới tắm cho nó, để cho tâm nguyện của người nở hoa kết trái vậy!")
        self:AddText("    Mỗi lần xong nhiệm vụ nhận một#Gquả ước nguyện#W. Gom#G7#Wquả đổi được một#GThiên Cương Cường Hóa Tinh Hoa#W; gom#G20#Wquả đổi được một#GHồng Bảo Thạch (cấp 3)#W!")
        self:AddText("    Ngoài ra, mỗi khi ta gom đủ#G1001#Wđiều ước, sẽ có kỳ tích không tưởng xảy ra! Mỗi ngày có#G3 lần#Wcơ hội kỳ tích, còn không mau tới xem?")
        self:AddText("    Người chơi đủ cấp 30 dự#Gkỳ cục#W,#Gtìm bảo Lâu Lan#W,#Gtặc binh xâm nhập#W,#Gtập kích môn phái#W,#Ghoạt động Tàng Kinh Các#W,#Grút May Mắn Khoái Hoạt Tam#W, mỗi ngày xong vòng#G20 nhiệm vụ sư môn#Wđều nhận cố định một#GNguyện Linh Tuyền#W.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
    if nNumText == 5100 then
        self:BeginEvent(self.script_id)
        self:AddText(" #{XCHQ_90601_12}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
    if nNumText == 5200 then
        self:BeginEvent(self.script_id)
        self:AddText(" #{ZXCM_090602_40}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
    for i, findId in pairs(self.g_eventList) do
        if arg== findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId,arg,index)
            return
        end
    end
end

function osuzhou_liangdaoshi:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            local ret = self:CallScriptFunction(missionScriptId, "CheckAccept", selfId)
            if ret > 0 then
                self:CallScriptFunction(missionScriptId, "OnAccept", selfId,targetId)
            end
            return
        end
    end
end

function osuzhou_liangdaoshi:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function osuzhou_liangdaoshi:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end
function osuzhou_liangdaoshi:OnDie(selfId, killerId)
end

function osuzhou_liangdaoshi:NotifyFailTips(selfId, Tip)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function osuzhou_liangdaoshi:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function osuzhou_liangdaoshi:OnMissionCheck(selfId, targetId, scriptId, index1, index2, index3, indexpet, missionIndex)
    for i, eventId in pairs(self.g_XunWuScriptId) do
        if eventId == scriptId then
            self:CallScriptFunction(
                scriptId,
                "OnMissionCheck",
                selfId,
                targetId,
                scriptId,
                index1,
                index2,
                index3,
                indexpet,
                missionIndex
            )
            return 1
        end
    end
end

function osuzhou_liangdaoshi:MsgBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osuzhou_liangdaoshi:CloseMe(selfId)
    self:BeginUICommand()
    self:EndUICommand()
    self:DispatchUICommand(selfId, 1000)
end

return osuzhou_liangdaoshi
