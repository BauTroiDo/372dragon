local class = require "class"
local define = require "define"
local script_base = require "script_base"
local erengu_yunzhonghe = class("erengu_yunzhonghe", script_base)
erengu_yunzhonghe.script_id = 018038
function erengu_yunzhonghe:OnDefaultEvent(selfId, targetId)
    local nMenPai = self:GetMenPai(selfId)
    self:BeginEvent(self.script_id)
    if nMenPai == 15 then
		self:AddText("#{ERMP_240620_04}")
		self:AddNumText("#{ERMP_240620_131}", 12, 0)
	else
		self:AddText("#{ERMP_240620_26}")
    end

    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function erengu_yunzhonghe:OnEventRequest(selfId, targetId, arg, index)
    local nIndex = index
    local nMenPai = self:GetMenPai(selfId)
    if nIndex == 0 then
        if self:HaveSkill(selfId, 111) then
            self:MsgBox(selfId, targetId, "Ngươi chẳng phải đã học được rồi sao?")
            return
        end
        if nMenPai ~= 15 then
            self:MsgBox(selfId, targetId, "#{XMPSH_220628_4}")
            return
        end
        if self:GetMoney(selfId) + self:GetMoneyJZ(selfId) < 100 then
            self:MsgBox(selfId, targetId, "   Thiếu hiệp, kim tiền mang theo không đủ, không thể học khinh công của Môn phái này.")
            return
        end
        self:LuaFnCostMoneyWithPriority(selfId, 100)
        self:AddSkill(selfId, 111)
        self:DelSkill(selfId, 34)
        self:MsgBox(selfId, targetId, "    Thiếu hiệp đã thành công học được #YKhinh công Ác Nhân Cốc#W, chúc mừng Thiếu hiệp!")
    end
end

function erengu_yunzhonghe:MsgBox(selfId, targetId, Msg)
    self:BeginEvent(self.script_id)
    self:AddText(Msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return erengu_yunzhonghe
