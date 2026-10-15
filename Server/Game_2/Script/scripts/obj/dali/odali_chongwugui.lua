local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_chongwugui = class("odali_chongwugui", script_base)
function odali_chongwugui:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    local roll = math.random(0, 2)
    if roll <= 0 then
        self:AddText("  Vân Miểu Miểu tỷ tỷ là thần tượng của tất cả Trân thú! Miểu Miểu Miểu Miểu, ta yêu tỷ, như chuột yêu gạo!")
    elseif roll <= 1 then
        self:AddText("  Đừng tưởng ta không biết nói chuyện, tỷ tỷ Miểu Miểu đã sớm dạy chúng ta nói chuyện rồi. Không tin, chúng ta so thử so thử!")
    else
        self:AddText("  Ngươi biết không? Nghe nói Miểu Miểu tỷ tỷ có hai người tỷ tỷ, cùng Miểu Miểu tỷ tỷ lớn lên giống nhau như đúc đó.")
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return odali_chongwugui
