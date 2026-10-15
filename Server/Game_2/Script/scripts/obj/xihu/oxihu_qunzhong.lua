local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oxihu_qunzhong = class("oxihu_qunzhong", script_base)
oxihu_qunzhong.script_id = 050202
oxihu_qunzhong.g_festivalwords = {
    "    Thế gian nơi nào thanh sảng mát mẻ, đứng đầu vẫn là Tây Hồ về đêm này a!",
    "    Hè năm nay không hóng mát, hóng mát còn phải đến Tây Hồ về đêm!",
    "    Gió nhẹ thổi đến thật là dễ chịu a!",
    "    Hè năm sau, ta còn đến Tây Hồ về đêm hóng mát.",
    "    Nhìn đây! Nhìn đây! Nhìn đây!",
    "    Tây Hồ về đêm thật là chốn tiên cảnh, bên ngoài đều là những ngày nóng nhất rồi, nghe nói ở đây còn có Người tuyết nữa!",
    "    Trở về ta sẽ nói với bằng hữu, đều đến Tây Hồ về đêm hóng mát!",
    "    Chỉ cần có núi có sông, vô sự mà trải qua một mùa hè này.",
    "    Lê hoa viện lạc dung dung nguyệt, liễu nhứ trì đường đạm đạm phong~~~",
    "    Nguyệt thượng liễu sao đầu, nhân ước hoàng hôn hậu...",
    "    Ta ở chỗ Tiểu thương kia mua một phần chè đậu xanh, uống vào không tệ, ngươi có muốn một bát không?",
    "    Chè đậu xanh của Tiểu thương kia không tệ, uống vào thật là mát lạnh thấu tim gan, ngươi có muốn một bát không?",
    "    Mùa hè tĩnh lặng, bầu trời đầy sao lấp lánh.",
    "    Trong lòng có chút nhớ nhung, nhớ nhung khuôn mặt của ngươi.",
    "    Mùa hè năm nay thật sảng khoái, mỗi ngày mười bát chè đậu xanh. Gió đêm thổi say cả người, đêm Tây Hồ thật tốt để hóng mát.",
    "    Mùa hè năm nay thật bảnh bao, cái nóng oi bức đều tan biến. Thiên Long Bát Bộ đêm Tây Hồ, có thể sánh ngang chốn đào nguyên tiên cảnh!",
    "    Nơi này là mùa hè, nơi này lại có Người tuyết, thật có thể gọi là Hạ Tuyết Nghi a.",
    "    Ngươi thích uống chè đậu xanh ướp lạnh, hay là nhiệt độ thường?",
    "    Ngươi xem, ngươi xem, biết bao nhiêu soái ca đến Tây Hồ hóng mát a!",
    "    Ngươi xem, ngươi xem, biết bao nhiêu mỹ nữ đến Tây Hồ hóng mát a!"
}

function oxihu_qunzhong:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    local strText = self.g_festivalwords[math.random(#(self.g_festivalwords))]
    self:AddText(strText)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oxihu_qunzhong
