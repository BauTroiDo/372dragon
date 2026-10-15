local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oxiaoyao_gongzhizichang = class("oxiaoyao_gongzhizichang", script_base)
oxiaoyao_gongzhizichang.script_id = 014035
function oxiaoyao_gongzhizichang:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Gần đây ta vô ý tìm được một quyển kỳ thư của xảo tượng, y theo sách mà làm, lại làm ra được Thiên Cơ Khôi Lỗi. Chúng có công năng phi thường, dường như còn có thể suy tư, muốn đi kiến thức một phen chăng?")
    self:AddNumText("Đi kiến thức Thiên Cơ Khôi Lỗi", 10, 0)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oxiaoyao_gongzhizichang:OnEventRequest(selfId, targetId, arg, index)
    if index == 0 then
        if self:GetLevel(selfId) < 81 then
            self:BeginEvent(self.script_id)
            local strText = "Đừng xem thường bản lĩnh của ta, Công Dã Tử Trưởng, Cấp độ chưa đạt cấp 81, ta sẽ không cho ngươi kiến Thiên Cơ Khôi Lỗi đâu."
            self:AddText(strText)
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        else
            self:CallScriptFunction((400900), "TransferFunc", selfId, 144, 59, 112)
        end
    end
end

return oxiaoyao_gongzhizichang
