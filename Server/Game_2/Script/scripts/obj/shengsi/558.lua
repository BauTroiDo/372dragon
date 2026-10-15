local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local shaxing_title = class("shaxing_title", script_base)
shaxing_title.script_id = 760558
shaxing_title.g_gotoact = 2
shaxing_title.g_leave = 20
function shaxing_title:OnDefaultEvent(selfId, targetId)
    local nam = self:LuaFnGetName(selfId)
    if self:LuaFnGetAvailableItemCount(selfId, 59910051) < 1 then
        self:BeginEvent(self.script_id)
        self:AddText("#{SXRW_090119_043}")
        self:AddNumText("Nhận danh hiệu Sát Tinh", 6, 100)
        self:AddNumText("Lĩnh nhận trợ giúp danh hiệu", 11, 200)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    else
        self:BeginEvent(self.script_id)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

function shaxing_title:OnEventRequest(selfId, targetId, arg, index)
    if index == 100 then
        self:BeginEvent(self.script_id)
        self:AddNumText("Quảng Mục Thiên Vương", 1, 1000)
        self:AddNumText("Đa Văn Thiên Vương", 1, 1001)
        self:AddNumText("Tăng Trưởng Thiên Vương", 1, 1002)
        self:AddNumText("Trì Quốc Thiên Vương", 1, 1003)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 200 then
        self:BeginEvent(self.script_id)
        self:AddText("#{SXRW_090119_109}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 1000 then
        local c0 = self:LuaFnGetAvailableItemCount(selfId, 59910051)
        if c0 < 1 then
            self:BeginEvent(self.script_id)
            self:LuaFnAwardSpouseTitle(selfId, "Quảng Mục Thiên Vương")
            self:LuaFnDelAvailableItem(selfId, 59910051, 1)
            self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, -1, 0)
            self:DispatchAllTitle(selfId)
            self:BeginEvent(self.script_id)
            self:AddText("#GChúc mừng, bạn nhận danh hiệu Quảng Mục Thiên Vương.")
            local nam = self:LuaFnGetName(selfId)
            local strText = "#gff00f0Chúc mừng người chơi#gffff00" .. nam .. "#gff00f0Nhận danh hiệu Quảng Mục Thiên Vương thành công"
            strText = gbk.fromutf8(strText)
            self:BroadMsgByChatPipe(selfId, strText, 4)
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        else
            local strNotice = "#GXin kiểm chứng nhận danh hiệu thuộc tính trong túi!!"
            self:ShowNotice(selfId, targetId, strNotice)
        end
    elseif index == 1001 then
        local c0 = self:LuaFnGetAvailableItemCount(selfId, 59910051)
        if c0 < 1 then
            self:BeginEvent(self.script_id)
            self:LuaFnAwardSpouseTitle(selfId, "Đa Văn Thiên Vương")
            self:LuaFnDelAvailableItem(selfId, 59910051, 1)
            self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, -1, 0)
            self:DispatchAllTitle(selfId)
            self:BeginEvent(self.script_id)
            self:AddText("#GChúc mừng, bạn nhận danh hiệu Đa Văn Thiên Vương.")
            local nam = self:LuaFnGetName(selfId)
            local strText = "#gff00f0Chúc mừng người chơi#gffff00" .. nam .. "#gff00f0Nhận danh hiệu Đa Văn Thiên Vương thành công"
            strText = gbk.fromutf8(strText)
            self:BroadMsgByChatPipe(selfId, strText, 4)
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        else
            local strNotice = "#GXin kiểm chứng nhận danh hiệu thuộc tính trong túi!!"
            self:ShowNotice(selfId, targetId, strNotice)
        end
    elseif index == 1002 then
        local c0 = self:LuaFnGetAvailableItemCount(selfId, 59910051)
        if c0 < 1 then
            self:BeginEvent(self.script_id)
            self:LuaFnAwardSpouseTitle(selfId, "Tăng Trưởng Thiên Vương")
            self:LuaFnDelAvailableItem(selfId, 59910051, 1)
            self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, -1, 0)
            self:DispatchAllTitle(selfId)
            self:BeginEvent(self.script_id)
            self:AddText("#GChúc mừng, bạn nhận danh hiệu Tăng Trưởng Thiên Vương.")
            local nam = self:LuaFnGetName(selfId)
            local strText = "#gff00f0Chúc mừng người chơi#gffff00" .. nam .. "#gff00f0Nhận danh hiệu Tăng Trưởng Thiên Vương thành công"
            strText = gbk.fromutf8(strText)
            self:BroadMsgByChatPipe(selfId, strText, 4)
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        else
            local strNotice = "#GXin kiểm chứng nhận danh hiệu thuộc tính trong túi!!"
            self:ShowNotice(selfId, targetId, strNotice)
        end
    elseif index == 1003 then
        local c0 = self:LuaFnGetAvailableItemCount(selfId, 59910051)
        if c0 < 1 then
            self:BeginEvent(self.script_id)
            self:LuaFnAwardSpouseTitle(selfId, "Trì Quốc Thiên Vương")
            self:LuaFnDelAvailableItem(selfId, 59910051, 1)
            self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, -1, 0)
            self:DispatchAllTitle(selfId)
            self:BeginEvent(self.script_id)
            self:AddText("#GChúc mừng, bạn nhận danh hiệu Trì Quốc Thiên Vương.")
            local nam = self:LuaFnGetName(selfId)
            local strText = "#gff00f0Chúc mừng người chơi#gffff00" .. nam .. "#gff00f0Nhận danh hiệu Trì Quốc Thiên Vương thành công"
            strText = gbk.fromutf8(strText)
            self:BroadMsgByChatPipe(selfId, strText, 4)
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        else
            local strNotice = "#GXin kiểm chứng nhận danh hiệu thuộc tính trong túi!!"
            self:ShowNotice(selfId, targetId, strNotice)
        end
    end
end

function shaxing_title:TalkMsg(selfId, targetId, str)
    self:BeginEvent(self.script_id)
    self:AddText(str)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function shaxing_title:NotifyFailTips(selfId, Tip)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function shaxing_title:Restore_hpmp(selfId, targetId)
    self:RestoreHp(selfId)
    self:RestoreMp(selfId)
    self:RestoreRage(selfId)
end

return shaxing_title
