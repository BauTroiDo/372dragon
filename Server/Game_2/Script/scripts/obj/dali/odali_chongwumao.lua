local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_chongwumao = class("odali_chongwumao", script_base)
function odali_chongwumao:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    local roll = math.random(0, 2)
    if roll <= 0 then
        self:AddText("  Vân Phi Phi tỷ tỷ là thần tượng của tất cả trân thú chúng ta! Vân Phi Phi, Vân Phi Phi, muội yêu tỷ, giống như chuột yêu gạo!")
    elseif roll <= 1 then
        self:AddText("  Đừng tưởng ta không biết nói chuyện, Vân Phi Phi tỷ tỷ đã dạy chúng ta nói chuyện từ lâu rồi. Không tin, chúng ta so thử so thử!")
    else
        self:AddText("  Ngươi có biết không? Nghe nói Phi Phi tỷ tỷ có hai muội muội, cùng Phi Phi tỷ tỷ lớn lên giống nhau như đúc đó.")
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return odali_chongwumao
