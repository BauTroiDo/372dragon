local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_lileshi = class("osuzhou_lileshi", script_base)
osuzhou_lileshi.script_id = 001055
osuzhou_lileshi.g_shoptableindex = 104
function osuzhou_lileshi:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Tại chỗ ta, ngươi có thể dùng Thiện Ác Trị để đổi lấy Đả Tạo Đồ và Giám Định Phù.")
    self:AddNumText("Thiện Ác Trị đổi Đả Tạo Đồ và Giám Định Phù", 7, 0)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osuzhou_lileshi:OnEventRequest(selfId, targetId, arg, index)
    if index == 0 then
        self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
    end
end

return osuzhou_lileshi
