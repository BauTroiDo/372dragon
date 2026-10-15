local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_daobaifeng = class("odali_daobaifeng", script_base)
function odali_daobaifeng:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Ai, Dự nhi đi lâu như vậy rồi vẫn chưa về, ta vừa lo lắng vừa tức giận, giang hồ hiểm ác, đấu đá lẫn nhau, đâu phải là nơi một thằng nhóc như nó có thể ứng phó được.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return odali_daobaifeng
