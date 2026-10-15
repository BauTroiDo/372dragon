local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_lunjian = class("osuzhou_lunjian", script_base)
osuzhou_lunjian.script_id = 001064
osuzhou_lunjian.g_eventList = {001230}

function osuzhou_lunjian:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(
        "  Tục ngữ có câu, văn vô đệ nhất, võ vô đệ nhị, nhân sĩ võ lâm đều muốn tranh đoạt danh hiệu đệ nhất thiên hạ tại Hoa Sơn Luận Kiếm. Nếu ngươi cũng muốn tham gia Hoa Sơn Luận Kiếm, ta có thể báo danh và đưa ngươi đến Hoa Sơn. Người chơi tham gia Hoa Sơn Luận Kiếm nếu tích phân đứng đầu ba trong Môn phái, Có thể sử dụng tại ta nơi này để nhận một phần bạc lễ do triều đình ban tặng, chư vị cố gắng nhé!"
    )
    self:AddNumText("Tửu quán Hoa Sơn Luận Kiếm", 11, 10)
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osuzhou_lunjian:OnEventRequest(selfId, targetId, arg, index)
    if index == 10 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_064}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    for i, findId in pairs(self.g_eventList) do
        if arg== findId then
            self:CallScriptFunction(findId, "OnDefaultEvent", selfId, targetId)
            return
        end
    end
end

return osuzhou_lunjian
