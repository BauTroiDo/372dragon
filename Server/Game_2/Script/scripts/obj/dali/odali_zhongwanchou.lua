local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_zhongwanchou = class("odali_zhongwanchou", script_base)
function odali_zhongwanchou:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Phu nhân ta mắng hay lắm. Đoàn Chính Thuần tên ác đồ này tự cho mình phong lưu, gây nhiều nghiệp chướng, đến cuối cùng con cái ruột thịt lại yêu nhau phạm tội, thật là vô liêm sỉ hết chỗ nói.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return odali_zhongwanchou
