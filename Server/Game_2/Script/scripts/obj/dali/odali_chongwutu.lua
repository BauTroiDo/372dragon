local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_chongwutu = class("odali_chongwutu", script_base)
function odali_chongwutu:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    local roll = math.random(0, 2)
    if roll <= 0 then
        self:AddText("  Vân Phiêu Phiêu tỷ tỷ là thần tượng của tất cả Trân thú! Phiêu phiêu phiêu phiêu ta yêu ngươi, giống như chuột yêu gạo!")
    elseif roll <= 1 then
        self:AddText("  Đừng tưởng rằng ta không biết nói chuyện, Phiêu Phiêu tỷ tỷ sớm đã dạy chúng ta nói chuyện rồi. Không tin, chúng ta so thử so thử!")
    else
        self:AddText("  Ngươi có biết không? Nghe nói Phiêu Phiêu tỷ tỷ có một tỷ tỷ cùng một muội muội, cùng Phiêu Phiêu tỷ tỷ lớn lên giống nhau như đúc đó.")
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return odali_chongwutu
