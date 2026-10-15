local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ogaibang_songzhanglao = class("ogaibang_songzhanglao", script_base)
ogaibang_songzhanglao.script_id = 010005
ogaibang_songzhanglao.g_eventList = {229009, 229012, 808092}

function ogaibang_songzhanglao:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Cái Bang muốn Phát triển lớn mạnh, thật không thể chỉ thu nhận ăn mày. Ta gần đây thu nhận một đệ tử, hắn trước đây là một hòa thượng.")
    for i, findId in pairs(self.g_eventList) do
        self:CallScriptFunction(self.g_eventList[i], "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function ogaibang_songzhanglao:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg== findId then
            self:CallScriptFunction(
                index,
                "OnDefaultEvent",
                selfId,
                targetId,
                define.MENPAI_ATTRIBUTE.MATTRIBUTE_GAIBANG
            )
            return
        end
    end
end

return ogaibang_songzhanglao
