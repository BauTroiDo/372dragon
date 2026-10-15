local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odunhuang_songbing = class("odunhuang_songbing", script_base)
function odunhuang_songbing:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    local nRet = math.random(5)
    if nRet <= 1 then
        self:AddText("  Ba năm trước, trận chiến Ngọc Môn Quan, chúng ta bại dưới tay quân Tây Hạ, đánh mất Ngọc Môn Quan. Đến nay chúng ta đã đánh lớn đánh nhỏ hơn mười trận, vẫn không thể khôi phục Ngọc Môn Quan.")
    elseif nRet <= 2 then
        self:AddText("  Mấy ngày trước, Dương tư lệnh từ Tây Kinh Quốc Tử Giám mời đến một Cá nhân, nghe nói là em trai của Thái thú Ngọc Môn Quan Tào Diên Huệ, tên là Tào Diên Thọ. Dạo gần đây Dương tư lệnh ngày nào cũng bàn bạc quân cơ bí mật với hắn.")
    elseif nRet <= 3 then
        self:AddText("  Ta nghe trung quân quan nói, không lâu trước đây, hắn khi ở #GTam Nguy Sơn#W xem xét địa hình, đã thấy một vị nữ tử tựa như thần tiên trên trời. Ừm, hình như là ở gần #G[220,100]#W.")
    elseif nRet <= 4 then
        self:AddText("  Ta nghe Trung Quân Quan nói, trước đó không lâu, hắn ở #GKhe Chiết Liễu#W gặp phải Tây Hạ Binh, hoảng hốt mất đường, trốn vào một sơn động thần bí mới có thể thoát thân. Ừm, hình như ở gần #G[149,42]#W.")
    else
        self:AddText("  Dọc theo #GTriết Liễu Hạp#W mà đi, sẽ đến #GNgọc Môn Quan#W, ừm, ở gần #G[66,91]#W. Ngươi phải cẩn thận, Hạ Binh rất hung tàn, bọn chúng giết người không chớp mắt đâu.")
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return odunhuang_songbing
