local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oyuxi_gulula = class("oyuxi_gulula", script_base)
function oyuxi_gulula:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Tên lão quỷ đó trước giờ chẳng đoái hoài gì đến vợ con, một lòng một dạ đều đặt lên người Củ cải kia.#r   Hỡi ôi, nhớ lại năm xưa những trang nam tử theo đuổi ta nhiều như hàng vạn, ta sao lại có thể để mắt tới một tên lão quỷ như thế chứ!")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oyuxi_gulula
