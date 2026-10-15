-- 洛阳NPC
-- 刘健明
-- 普通
local class = require "class"
local script_base = require "script_base"
local oluoyang_liujianming = class("oluoyang_liujianming", script_base)
oluoyang_liujianming.script_id = 311002
local g_eventAddDETimeBegin = 200
local g_eventUpdateList = 100
local g_eventDETime_1 = 0
local g_eventDETime_2 = 1
local g_eventDETime_4 = 2
local g_eventDETime_Lock = 3
local g_eventDETime_Unlock = 4
local g_eventDETime_Ask = 5
local g_Abandon_Unlock = 7
local g_Do_Unlock = 6
local TIME_2000_01_03_ = 946828868

local g_BuffPalyer_25 = 60
local g_BuffAll_15 = 62
local g_BuffPet_25 = 61
local g_BuffPet_2 = 53
function oluoyang_liujianming:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oluoyang_liujianming:OnEventRequest(selfId, targetId, arg, index)
    if index == 10 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_079}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if self:GetLevel(selfId) < 10 then
        self:BeginEvent(self.script_id)
        self:AddText("  Cấp độ của ngươi còn chưa đạt cấp 10, hãy luyện thêm đi.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end

    local nCurTime = self:LuaFnGetCurrentTime()
    -- 上次刷新数据的时间
    local nPreTime = self:DEGetPreTime(selfId)
    if (nCurTime - nPreTime >= 3600 * 24 * 7) or
        (math.floor((nCurTime - TIME_2000_01_03_) / (3600 * 24 * 7)) ~=
            math.floor((nPreTime - TIME_2000_01_03_) / (3600 * 24 * 7))) then
        self:DEResetWeeklyFreeTime(selfId)
    end
    local nNowGetTime = 0
    if index == g_eventDETime_1 then
        nNowGetTime = 1
        self:AddDETime(selfId, targetId, 1, nCurTime, nPreTime)
    elseif index == g_eventDETime_2 then
        nNowGetTime = 2
        self:AddDETime(selfId, targetId, 2, nCurTime, nPreTime)
    elseif index == g_eventDETime_4 then
        nNowGetTime = 4
        self:AddDETime(selfId, targetId, 4, nCurTime, nPreTime)
    elseif index == g_eventDETime_Lock then
        -- 先检测一下是不是冻结状态，如果是，就返回，并直接提示
        if self:DEIsLock(selfId) then
            self:BeginEvent(self.script_id)
            self:AddText(
                "Ngươi thời giancủa song bội kinh nghiệm dĩ kinh xử vu đống kết trạng thái liễu.")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end
        -- 冻结的时候，
        local nCurHave = self:DEGetFreeTime(selfId)
        nCurHave = nCurHave + self:DEGetMoneyTime(selfId)

        -- 先计算下当前玩家身上剩下的时间
        local nTrueTime = nCurHave
        if nTrueTime <= 0 then
            self:BeginEvent(self.script_id)
            self:AddText("Ngươi hiện tại một hữu dĩ lĩnh thủcủa song bội thời gian a?!?")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end
        self:BeginUICommand()
        self:UICommand_AddInt(self.script_id)
        self:UICommand_AddInt(targetId)
        self:UICommand_AddInt(50)
        self:UICommand_AddStr("LockTime")
        local str = string.format(
                        "\\0Ngươi đang có %d phút x2, chắc chắn đóng băng chứ?",
                        math.floor(nTrueTime / 60))
        self:UICommand_AddStr(str)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 24)
    elseif index == g_eventDETime_Unlock then
        -- 解冻的时候，
        -- 先判断是不是有双倍经验时间可以解除
        if not self:DEIsLock(selfId) then
            self:BeginEvent(self.script_id)
            self:AddText(
                "Ngươi chưa có đóng băng thời gian kinh nghiệm gấp đôi ở chỗ ta sao?!")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end

        -- 如果玩家身上有药水的BUFF，需要给玩家一个提示
        if self:LuaFnHaveImpactOfSpecificDataIndex(selfId, g_BuffPalyer_25) or
            self:LuaFnHaveImpactOfSpecificDataIndex(selfId, g_BuffAll_15) == 1 then
            self:BeginEvent(self.script_id)
            self:AddText(
                "  Trên người ngài đã có thời gian kinh nghiệm bội số, có xác nhận giải đóng băng không?")
            self:AddNumText("Xác nhận giải đóng băng", 6, g_Do_Unlock)
            self:AddNumText("Từ bỏ giải đóng băng", 6, g_eventUpdateList)
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end

        self:DESetLock(selfId, false)
        self:BeginEvent()
        self:AddText("  Thời gian kinh nghiệm gấp đôi ngươi đóng băng đã được giải đóng băng.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)

        -- 同步数据到客户端
        self:SendDoubleExpToClient(selfId)
    elseif index == g_Do_Unlock then
        self:DESetLock(selfId, false)
        self:BeginEvent(self.script_id)
        self:AddText("  Thời gian kinh nghiệm gấp đôi ngươi đóng băng đã được giải đóng băng.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        -- 同步数据到客户端
        self:SendDoubleExpToClient(selfId)
    elseif index == g_Abandon_Unlock then
        return
    elseif index == g_eventDETime_Ask then
        local nCount = self:DEGetCount(selfId)
        self:BeginEvent(self.script_id)
        if nCount and nCount > 0 then
            self:AddText(
                "Có thể ta ở đây lĩnh của ngươi thời gian gấp đôi kinh nghiệm của tuần này là #R" ..
                    tostring(math.floor(nCount)) ..
                    "giờ#W, mau tận dụng tốt đi.")
        else
            self:AddText(
                "Thật là đáng tiếc, ta có thể cung cấp ngươi thời gian kinh nghiệm gấp đôi của tuần này là((R_CAP))0giờ#W rồi.")
        end
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)

    elseif index == g_eventUpdateList then
        self:UpdateEventList(selfId, targetId)
    elseif index >= g_eventAddDETimeBegin then
        -- 验证并且增加
        local nPoint = index - g_eventAddDETimeBegin
        local nCount = self:DEGetCount(selfId)
        if nCount < nPoint then return end
        local nCurHave = self:DEGetFreeTime(selfId)
        nCurHave = nCurHave + self:DEGetMoneyTime(selfId)
        -- 先计算下当前玩家身上剩下的时间
        local nTrueTime = nCurHave;
        if nTrueTime < 0 then nTrueTime = 0 end
        self:WithDrawFreeDoubleExpTime(selfId, nPoint, 0, 0)
        self:BeginEvent(self.script_id)
        self:AddText("  Ngươi đã thành công lĩnh #R" .. nPoint ..
                         "giờ #Wcủa song bội kinh nghiệm thời gian. Hiện tại ngươi tổng cộng có #Y" ..
                         tostring(math.floor((nTrueTime + nPoint * 3600) / 60)) ..
                         "phút #Wcủa song bội kinh nghiệm thời gian")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)

        self:notify_tips(selfId, "  Ngươi đã thành công lĩnh #R" .. nPoint ..
                             "giờ #Wcủa song bội kinh nghiệm thời gian. Hiện tại ngươi tổng cộng có #Y" ..
                             tostring(
                                 math.floor((nTrueTime + nPoint * 3600) / 60)) ..
                             "phút #Wcủa song bội kinh nghiệm thời gian")
        -- 同步数据到客户端
        self:SendDoubleExpToClient(selfId)
    end
end

function oluoyang_liujianming:AddDETime(selfId, targetId, nPoint, nCurTime,
                                        nPreTime)
    local nCurHave = self:DEGetFreeTime(selfId)
    nCurHave = nCurHave + self:DEGetMoneyTime(selfId)

    local nFreeTime = self:DEGetFreeTime(selfId)
    -- 先计算下当前玩家身上剩下的时间
    local nTrueTime = nCurHave;

    if nTrueTime < 0 then nTrueTime = 0 end

    -- 看还有没有时间可以领取
    local nCount = self:DEGetCount(selfId)

    if (nCount <= 0) then
        self:BeginEvent(self.script_id)
        self:AddText(
            "Thời gian kinh nghiệm gấp đôi mà ngươi có thể lĩnh từ chỗ ta tuần này đã dùng hết rồi.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end

    if nCount < nPoint then
        self:BeginEvent(self.script_id)
        self:AddText("  Ngươi không có nhiều thời gian như vậy để lĩnh đâu.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    -- 看身上是不是已经有比较多的时间了，2小时
    if nFreeTime >= 120 * 60 then
        self:BeginEvent(self.script_id)
        self:AddText(
            "Ngươi nhận thời gian kinh nghiệm gấp đôi tại tam đại thành thị và Tự kiến thành thị đã đạt đến giới hạn có thể lĩnh")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    -- 检测玩家不能拥有超过4个小时的时间
    if nFreeTime + nPoint * 3600 > 3600 * 4 then
        self:BeginEvent()
        self:AddText(
            "Ngươi nhận thời gian kinh nghiệm gấp đôi tại tam đại thành thị và Tự kiến thành thị đã đạt đến giới hạn có thể lĩnh")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    -- 看身上是不是有冻结了的时间
    if self:DEIsLock(selfId) then
        self:BeginEvent(self.script_id)
        self:AddText(
            "Ngươi còn thời gian kinh nghiệm gấp đôi bị đóng băng, hay là giải đóng băng rồi lĩnh thời gian kinh nghiệm gấp đôi mới đi.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end

    self:BeginEvent(self.script_id)
    if (nTrueTime / 60) > 0 then
        self:AddText("Thời gian gấp đôi kinh nghiệm trong tuần này của ngươi còn #R" ..
                         tostring(math.floor(nCount)) ..
                         "giờ#W, hiện đã có thời gian gấp đôi kinh nghiệm #Y" ..
                         tostring(math.floor(nTrueTime / 60)) ..
                         "phút#W, ngươi xác nhận muốn lĩnh #Y" ..
                         tostring(math.floor(nPoint * 60)) ..
                         "phút#W thời gian gấp đôi kinh nghiệm sao?");
    else
        self:AddText("Thời gian gấp đôi kinh nghiệm trong tuần này của ngươi còn #R" ..
                         tostring(math.floor(nCount)) ..
                         "Giờ#W, ngươi xác nhận muốn lĩnh#Y" ..
                         tostring(math.floor(nPoint * 60)) ..
                         "phút#W thời gian gấp đôi kinh nghiệm sao?");
    end
    -- 如果这个时候玩家身上有双倍经验药水效果，需要给玩家提示
    if self:LuaFnHaveImpactOfSpecificDataIndex(selfId, g_BuffPalyer_25) == 1 or
        self:LuaFnHaveImpactOfSpecificDataIndex(selfId, g_BuffAll_15) == 1 then
        self:AddText(
            "  #r  #RXin chú ý: Trên người ngài đã có thời gian kinh nghiệm bội số, có xác nhận lĩnh hay không?");
    end
    self:AddNumText("Vâng, ta muốn lĩnh.", -1,
                    g_eventAddDETimeBegin + nPoint)
    self:AddNumText("Không cần, ta bấm nhầm rồi.", -1, g_eventUpdateList)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_liujianming:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  #{LS_20080303}");
    self:AddNumText("Ta muốn lĩnh một giờ thời gian kinh nghiệm gấp đôi", 6, 0)
    self:AddNumText("Ta muốn lĩnh hai giờ thời gian kinh nghiệm gấp đôi", 6, 1)
    self:AddNumText("Ta muốn lĩnh bốn giờ thời gian kinh nghiệm gấp đôi", 6, 2)
    self:AddNumText("Ta muốn đóng băng thời gian kinh nghiệm gấp đôi", 6, 3)
    self:AddNumText("Ta muốn giải băng thời gian kinh nghiệm gấp đôi", 6, 4)
    self:AddNumText("Ta muốn tra thời gian kinh nghiệm gấp đôi của ta trong tuần này", 6, 5)
    self:AddNumText("Lĩnh tửu quán song", 11, 10)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_liujianming:LockTime(selfId, targetId)
    -- 获得服务器记录的实际的真实时间
    local nCurTime = self:LuaFnGetCurrentTime()
    local nCurHave = self:DEGetFreeTime(selfId)
    nCurHave = nCurHave + self:DEGetMoneyTime(selfId)
    -- 先计算下当前玩家身上剩下的时间
    local nTrueTime = nCurHave

    if nTrueTime < 0 then nTrueTime = 0 end

    self:DESetLock(selfId, true)

    local str = "  Đã đóng băng rồi" .. tostring(math.floor(nTrueTime / 60)) ..
                    "phút thời gian kinh nghiệm gấp đôi"
    self:BeginEvent(self.script_id)
    self:AddText(str)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)

    self:notify_tips(selfId, str)

    -- 同步数据到客户端
    self:SendDoubleExpToClient(selfId)
end

return oluoyang_liujianming
