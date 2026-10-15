local class = require "class"
local define = require "define"
local script_base = require "script_base"
local owudang_chengruoqing = class("owudang_chengruoqing", script_base)
function owudang_chengruoqing:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Võ Đang sơn dạo gần đây giáo Pháttriển hưng long, rất có xu thế vượt qua Long Hổ Sơn, trở thành đệ nhất danh sơn đạo giáo của Trung Hoa.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return owudang_chengruoqing
