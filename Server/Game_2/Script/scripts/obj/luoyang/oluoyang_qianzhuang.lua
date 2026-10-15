--钱庄脚本
--普通
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_qianzhuang = class("oluoyang_qianzhuang", script_base)
function oluoyang_qianzhuang:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
		self:AddNumText("Mở ngân hàng",5, 1)
        local size = self:GetBankBagSize(selfId)
        if size < define.MAX_BANK_BAG_SIZE then
            self:AddNumText("Mua rương chứa đồ mới",5, 6)
        end
        self:AddNumText("#{ZSYH_120503_03}",11, 2)
        self:AddNumText("#{JZBZ_081031_02}",11, 3)
        self:AddNumText("#{ZSYH_120503_01}",5, 4)
        self:AddNumText("#{JBJZ_090407_1}",5, 5)
        size = self:GetPetBankBagSize(selfId)
        if size < define.MAX_PET_BANK_BAG_SIZE then
            self:AddNumText("#{ZSYH_120503_02}",5, 7)
        end
	self:EndEvent()
	self:DispatchEventList(selfId,targetId)
end

function oluoyang_qianzhuang:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
        self:BankBegin(selfId, targetId)
        return
    end
    if index == 2 then
        self:BeginEvent(self.script_id)
        self:AddText("#{ZSYH_120503_04}")
	    self:EndEvent()
	    self:DispatchEventList(selfId,targetId)
    end
    if index == 3 then
        self:BeginEvent(self.script_id)
        self:AddText("#{JZBZ_081031_01}")
	    self:EndEvent()
	    self:DispatchEventList(selfId,targetId)
    end
    if index == 4 then
        self:PetBankBegin(selfId, targetId)
        return
    end
    if index == 5 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 800119)
        return
    end
    if index == 6 then
        self:BeginUICommand()
        self:UICommand_AddInt(self.script_id)
        self:UICommand_AddInt(targetId)
        self:UICommand_AddInt(8)
        self:UICommand_AddStr("BuyNewBankBox")
        self:UICommand_AddStr("Muốn mua rương chứa mới, cần tốn#{_EXCHG1000000}.#r")
        self:EndUICommand()
        self:DispatchUICommand(selfId, 24)
        return
    end
    if index == 7 then
        self:BeginEvent(self.script_id)
        local str = self:ContactArgs("#{ZSYH_120503_10", 1)
        self:AddText(str .. "}")
        self:AddNumText("#{INTERFACE_XML_557}", -1, 114)
        self:AddNumText("#{FBSJ_081209_12}", -1, 113)
	    self:EndEvent()
	    self:DispatchEventList(selfId,targetId)
        return
    end
    if index == 114 then
        local size = self:GetPetBankBagSize(selfId)
        if size >= define.MAX_PET_BANK_BAG_SIZE then
            self:notify_tips(selfId, "#{ZSYH_120503_05}")
            return
        end
        local item_count = self:LuaFnGetAvailableItemCount(selfId, 30606025)
        if item_count < 1 then
            self:notify_tips(selfId, "#{ZSYH_120503_12}")
            return
        end
        self:LuaFnDelAvailableItem(selfId, 30606025, 1)
        size = size + 1
        self:SetPetBankBagSize(selfId, size)
        if size == define.MAX_PET_BANK_BAG_SIZE then
            self:notify_tips(selfId, "#{ZSYH_120503_13}")
        else
            self:notify_tips(selfId, "#{ZSYH_120503_14}")
        end
        return
    end
    if index == 113 then
        self:OnDefaultEvent(selfId, targetId)
        return
    end
    if arg == 8 then
        local my_money = self:GetMoney(selfId) + self:GetMoneyJZ(selfId)
        if my_money < 1000000 then
            self:notify_tips(selfId, "Kim tiền không đủ")
            return
        end
        local size = self:GetBankBagSize(selfId)
        if size >= define.MAX_BANK_BAG_SIZE then
            self:notify_tips(selfId, "Rương chứa đã tối đa")
            return
        end
        self:LuaFnCostMoneyWithPriority(selfId, 1000000)
        size = size + 20
        self:SetBankBagSize(selfId, size)
        self:notify_tips(selfId, "Mua rương ngân hàng thành công!")
    end
end

function oluoyang_qianzhuang:DoMoneyToJiaozi(selfId, count)
    if count <= 0 then
        return
    end
    self:MoneyToJiaozi(selfId, count)
end

function oluoyang_qianzhuang:BuyNewBankBox(selfId)
    local my_money = self:GetMoney(selfId) + self:GetMoneyJZ(selfId)
    if my_money < 1000000 then
        self:notify_tips(selfId, "Kim tiền không đủ")
        return
    end
    local size = self:GetBankBagSize(selfId)
    if size >= define.MAX_BANK_BAG_SIZE then
        self:notify_tips(selfId, "Rương chứa đã tối đa")
        return
    end
    self:LuaFnCostMoneyWithPriority(selfId, 1000000)
    size = size + 20
    self:SetBankBagSize(selfId, size)
    self:notify_tips(selfId, "Mua rương ngân hàng thành công!")
end

return oluoyang_qianzhuang