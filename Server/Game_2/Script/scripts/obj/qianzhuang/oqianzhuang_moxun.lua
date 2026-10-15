local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oqianzhuang_moxun = class("oqianzhuang_moxun", script_base)
oqianzhuang_moxun.script_id = 181004
function oqianzhuang_moxun:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("    Nguyên liệu trân kỳ, các loại Đả Tạo Đồ, khách quan cứ tự nhiên chọn lựa!")
    self:AddNumText("Đả Tạo Đồ", 2, 1)
    self:AddNumText("Nguyên bảotửu quán", 11, 2)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oqianzhuang_moxun:OnEventRequest(selfId, targetId, arg, index)
    local key = index
    if key == 1 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:UICommand_AddInt(8)
        self:UICommand_AddInt(1)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 888902)
    elseif key == 2 then
        self:BeginEvent(self.script_id)
        self:AddText("#{INTRO_YUANBAO}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

function oqianzhuang_moxun:OnOpenShop(selfId, targetId, lstShop) end

return oqianzhuang_moxun
