local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oxingxiu_dingchunqiu = class("oxingxiu_dingchunqiu", script_base)
oxingxiu_dingchunqiu.script_id = 016000
oxingxiu_dingchunqiu.g_eventList = {229009, 229012, 808092}

function oxingxiu_dingchunqiu:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Lão phu vẫn luôn cảm thấy, người trong võ lâm dùng Đao Phủ Thương Bổng đánh giết lẫn nhau, thật sự là chuyện tàn nhẫn vô cùng. Nếu dùng độc công làm bị thương người, mới có thể khiến người ta trong bình tĩnh, an nhàn, hạnh phúc, vui vẻ mà Tử vong. Cho nên độc công này thật là võ công công đức vô lượng.")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oxingxiu_dingchunqiu:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(
                arg,
                "OnDefaultEvent",
                selfId,
                targetId,
                define.MENPAI_ATTRIBUTE.MATTRIBUTE_XINGXIU
            )
            return
        end
    end
end

return oxingxiu_dingchunqiu
