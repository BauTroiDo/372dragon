local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odigong_chuandisi = class("odigong_chuandisi", script_base)
odigong_chuandisi.script_id = 044605
function odigong_chuandisi:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(
        "    Tại hạ nhận lời nhờ cậy của huyện thừa nơi đây, đến đây dò xét tình hình. Tuy có phát hiện, nhưng tại hạ lực có chỗ không với tới, cần Thiếu Hiệp ra tay tương trợ. #r    Hôm qua tại hạ tiến vào địa cung tầng bốn thăm dò, phát hiện nhiều đài tế cổ xưa, oán niệm sâu nặng, dường như là nhãn trận của một loại linh trận nào đó. Nếu đặt vào vật triệu linh là phù lục triệu linh, ắt có thể dẫn ra nguồn dị tượng. Đến lúc ấy ngươi hãy tìm cơ hội trừ diệt nó, trận này tự phá!")
    self:AddNumText("Tới Địa Cung 4 server này", 9, 1)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function odigong_chuandisi:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
        if self:GetLevel(selfId) < 50 then
            self:NotifyTips(selfId,targetId,"   Thiếu hiệp chưa đủ cấp 50, ta khuyên đừng mạo hiểm thì hơn.")
            return
        end
        --self:NotifyTips(selfId,targetId, "地宫四层暂不开放")
        --return
		--本服
		if not self:CallDestSceneFunction(1303, 3000003, "IsClose") then
			self:CallScriptFunction((400900), "TransferFunc", selfId, 1303, 34, 37,50)
        --self:CallScriptFunction((400900), "TransferFunc", selfId, 1299, 34, 37,50)
		else
			self:NotifyTips(selfId,targetId, "Địa Cung tầng 4 đang đóng")
		end
    end
end

function odigong_chuandisi:NotifyTips(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function odigong_chuandisi:NotifyFailBox(selfId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return odigong_chuandisi
