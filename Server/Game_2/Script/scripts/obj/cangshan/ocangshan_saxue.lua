local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ocangshan_saxue = class("ocangshan_saxue", script_base)

function ocangshan_saxue:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Mỗi năm mùa đông, tuyết nơi đây mênh mông vô tận, cuồn cuộn tràn tới. Nó đang ám chỉ điều gì vậy? Ha! Đúng là một thế giới kỳ diệu nhưng cũng đầy rẫy đáng sợ!")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return ocangshan_saxue
