local class = require "class"
local define = require "define"
local script_base = require "script_base"
local mantuo_wangyanzu = class("mantuo_wangyanzu", script_base)
mantuo_wangyanzu.script_id = 015046
function mantuo_wangyanzu:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{MPSD_220622_13}")
    self:AddNumText("#{MPSD_220622_123}", 12, 0)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function mantuo_wangyanzu:OnEventRequest(selfId, targetId, arg, index)
    local nIndex = index
    local nMenPai = self:GetMenPai(selfId)
    if nIndex == 0 then
        if self:HaveSkill(selfId, 110) then
            self:MsgBox(selfId, targetId, "Ngươi chẳng phải đã học được rồi sao?")
            return
        end
        if nMenPai ~= 16 then
            self:MsgBox(selfId, targetId, "#{XMPSH_220628_4}")
            return
        end
        if self:GetMoney(selfId) + self:GetMoneyJZ(selfId) < 100 then
            self:MsgBox(selfId, targetId, "   Thiếu hiệp, kim tiền mang theo không đủ, không thể học khinh công của Môn phái này.")
            return
        end
        self:LuaFnCostMoneyWithPriority(selfId, 100)
        self:AddSkill(selfId, 110)
        self:DelSkill(selfId, 34)
        self:MsgBox(selfId, targetId, "    Thiếu hiệp đã học được#YKhinh công Mạn Đà Sơn Trang#W, chúc mừng!")
    end
end

function mantuo_wangyanzu:MsgBox(selfId, targetId, Msg)
    self:BeginEvent(self.script_id)
    self:AddText(Msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return mantuo_wangyanzu
