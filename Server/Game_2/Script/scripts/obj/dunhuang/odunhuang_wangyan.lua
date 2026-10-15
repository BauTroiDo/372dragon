local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odunhuang_wangyan = class("odunhuang_wangyan", script_base)
odunhuang_wangyan.script_id = 008112
odunhuang_wangyan.g_Transport = 400900
odunhuang_wangyan.g_Impact_Transport_Mission = 113
function odunhuang_wangyan:OnDefaultEvent(selfId, targetId)
    local nam = self:GetName(selfId)
    self:BeginEvent(self.script_id)
    self:AddText(nam ..  ", một khi vào Dương Quan đại mạc cát bay, đi về phía tây nữa, chính là Hỏa Diệm Sơn! Đi qua Hỏa Diệm Sơn có thể đến được những nơi như Cao Xương Cổ Quốc. Trên đường đi hung hiểm dị thường, chỉ có anh hùng #Gtrên cấp 90#W mới có tư cách mạo hiểm.")
    self:AddNumText("Truyền tống đến Hỏa Diệm Sơn", 9, 0)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function odunhuang_wangyan:OnEventRequest(selfId, targetId, arg, index)
    if self:GetLevel(selfId) < 90 then
        self:BeginEvent(self.script_id)
        self:AddText("  Lần này lên đường hung hiểm dị thường, mà Cấp độ của ngươi còn chưa đủ cấp 90, vì sự an toàn của ngươi, hãy luyện tập thêm thời gian rồi hãy đến tìm ta.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    else
        local haveImpact = self:LuaFnHaveImpactOfSpecificDataIndex(selfId, self.g_Impact_Transport_Mission)
        if haveImpact then
            self:BeginEvent(self.script_id)
            self:AddText("#{Transfer_090304_1}")
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            return
        end
        self:CallScriptFunction((self.g_Transport), "TransferFunc", selfId, 423,   223, 29, 90, 1000)
    end
end

return odunhuang_wangyan
