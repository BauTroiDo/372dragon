local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oqiongzhou_lingyici = class("oqiongzhou_lingyici", script_base)
function oqiongzhou_lingyici:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Lão Tam luôn muốn ta đến Quỳnh Châu, nhưng dân chúng Lưu Cầu đang phải chịu khổ vì ôn dịch, ta thực sự không thể bỏ rơi họ mà đi.#r Lần này ta đến Quỳnh Châu, chủ yếu là nghe Tử Khâm nói ở Nam Hải có một vị Thần Y Nhạc Trọng Thu, dùng vỏ cây dị chủng chữa khỏi ôn dịch. Đợi ta nắm vững được kỹ thuật này, ta còn phải nhanh chóng trở về Lưu Cầu, chữa trị cho dân chúng nơi đó.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oqiongzhou_lingyici
