local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local changehaircolor = class("changehaircolor", script_base)
changehaircolor.script_id = 80101101
function changehaircolor:OnEnumerate(caller, selfId, targetId, arg, index)
    self:BeginUICommand()
    self:UICommand_AddInt(targetId)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 80101101)
    return
end

function changehaircolor:SaveNewHairColor(selfId, ColorValue, check)
    local item = { 20307001, 20307002 }
    local itemCount = self:LuaFnGetAvailableItemCount(selfId, item[1])
    local itemCount2 = self:LuaFnGetAvailableItemCount(selfId, item[2])
    if (itemCount < 1) and (itemCount2 < 1) then
        self:SaveNewHairColor_YuanbaoPay(selfId, item[1], check)
        return
    end
    local money = self:GetMoney(selfId)
    local moneyJZ = self:GetMoneyJZ(selfId)
    if (money + moneyJZ) >= 50000 then
        self:LuaFnCostMoneyWithPriority(selfId, 50000)
        if (itemCount2 >= 1) then
            self:DelItem(selfId, item[2], 1)
        else
            self:DelItem(selfId, item[1], 1)
        end
        self:AddHumanHairColor(selfId, ColorValue)
        self:BeginEvent(self.script_id)
        self:AddText("Nhuộm tóc thành công.")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        local message
        local randMessage = math.random(3)
        local name = self:LuaFnGetName(selfId)
        name = gbk.fromutf8(name)
        if randMessage == 1 then
            message = string.format("#W#{_INFOUSR%s}#{FaSe_00}", name)
        elseif randMessage == 2 then
            message = string.format("#{FaSe_01}#W#{_INFOUSR%s}#{FaSe_02}", name)
        else
            message = string.format("#{FaSe_03}#W#{_INFOUSR%s}#{FaSe_04}", name)
        end
        self:BroadMsgByChatPipe(selfId, message, 4)
    else
        self:BeginEvent(self.script_id)
        self:AddText("Trên người ngươi mang theo không đủ tiền.")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return
    end
end

function changehaircolor:ChangeHairColor(selfId, HairIndex)
    self:SetHumanHairColor(selfId, HairIndex + 1)
end

function changehaircolor:SaveNewHairColor_YuanbaoPay(selfId, ItemIndex, check)
	local hint = "#{XFYH_20120221_18"
	local index, merchadise = self:GetMerchadiseByItemIndex(selfId, ItemIndex)
	if index == nil then
		return
	end
	self:BeginUICommand()
	self:UICommand_AddInt(6)
	self:UICommand_AddInt(5)
	self:UICommand_AddInt(merchadise.price)
	self:UICommand_AddInt(index - 1)
	self:UICommand_AddInt(0)
	self:UICommand_AddInt(self.script_id)
	self:UICommand_AddInt(check)
	self:UICommand_AddInt(-1)
	self:UICommand_AddInt(1)
	local str = self:ContactArgs(hint, merchadise.id, merchadise.price, "#{XFYH_20120221_10}", "#{XFYH_20120221_12}", merchadise.id) .. "}"
	self:UICommand_AddStr(str)
	self:EndUICommand()
	self:DispatchUICommand(selfId, 20120222)
end

return changehaircolor
