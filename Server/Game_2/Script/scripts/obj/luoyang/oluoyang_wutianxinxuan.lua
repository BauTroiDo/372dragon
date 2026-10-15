local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_wutianxinxuan = class("oluoyang_wutianxinxuan", script_base)
function oluoyang_wutianxinxuan:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(
        "  Đại Tống quốc có rất nhiều điều đáng để chúng ta học hỏi, đặc biệt là \"Tôn Tử Binh Pháp\", nhân dịp đại hội đá cầu lần này, mong rằng hai nước chúng ta có thể giao lưu thật tốt.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oluoyang_wutianxinxuan
