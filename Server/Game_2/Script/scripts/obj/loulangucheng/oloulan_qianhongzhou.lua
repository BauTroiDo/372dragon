local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_qianhongzhou = class("oloulan_qianhongzhou", script_base)
oloulan_qianhongzhou.g_strGongGaoInfo = {
    "#{_INFOUSR%s}#Hsau một phen nỗ lực, cuối cùng gom đủ nguyên liệu, mọi người cùng chúc mừng! Tại Lâu Lan (133,118) chỗ Tiền Hoành Trụ hợp thành #{_INFOMSG%%s}!",
    "#{_INFOUSR%s}#Hsau một phen nỗ lực, cuối cùng gom đủ nguyên liệu, mọi người cùng chúc mừng! Tại Lâu Lan (133,118) chỗ Tiền Hoành Trụ hợp thành #{_INFOMSG%%s}!",
    "#{_INFOUSR%s}#Hsau một phen nỗ lực, cuối cùng gom đủ nguyên liệu, mọi người cùng chúc mừng! Tại Lâu Lan (133,118) chỗ Tiền Hoành Trụ hợp thành #{_INFOMSG%%s}!",
    "#{_INFOUSR%s}#Hsau một phen nỗ lực, cuối cùng gom đủ nguyên liệu, mọi người cùng chúc mừng! Tại Lâu Lan (133,118) chỗ Tiền Hoành Trụ hợp thành #{_INFOMSG%%s}!"
}

function oloulan_qianhongzhou:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  #{AQSJ_090709_01}")
    self:AddNumText("#cffcc00Rèn Băng Phách Thần Châm", 6, 100)
    self:AddNumText("#cffcc00Đổi Hàn Băng Tinh Thạch", 6, 101)
    self:AddNumText("#cffcc00Giới thiệu Băng Phách Thần Châm", 11, 102)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oloulan_qianhongzhou:OnEventRequest(selfId, targetId, arg, index)
    if index == 4 then
        self:BeginUICommand()
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
    elseif index == 100 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 070825)
    elseif index == 101 then
        self:BeginEvent(self.script_id)
        self:AddText("#{AQSJ_090709_13}")
        self:AddNumText("#cffcc00Đổi Hàn Băng Tinh Thạch", 6, 155)
        self:AddNumText("#cffcc00Về trang trước", 14, 256)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 155 then
        local c0 = self:LuaFnGetAvailableItemCount(selfId, 20310113)
        local c1 = self:LuaFnGetAvailableItemCount(selfId, 20310114)
        if c0 + c1 < 20 then
            self:BeginEvent(self.script_id)
            local strText =
                "    #YTránh ra tránh ra,#GHàn Băng Tinh Tiết#Ykhông đủ, không hợp thành được!"
            self:AddText(strText)
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end
		local costtab = {}
		if c0 > 0 then
			table.insert(costtab,20310113)
		end
		if c1 > 0 then
			table.insert(costtab,20310114)
		end
        local del = self:LuaFnMtl_CostMaterial(selfId,20,costtab)
		if not del then
			self:BeginEvent(self.script_id)
			self:AddText("Trừ nguyên liệu thất bại.")
			self:EndEvent()
			self:DispatchEventList(selfId, targetId)
			return
		end
        self:BeginEvent(self.script_id)
        local bagpos01 = self:TryRecieveItem(selfId, 30008069, 1)
        local szItemTransfer = self:GetBagItemTransfer(selfId, bagpos01)
        self:ShowRandomSystemNotice(selfId, szItemTransfer)
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 148, 0)
        local strText = "    #YChúc mừng ngươi, cuối cùng hợp thành#b#GHàn Băng Tinh Thạch!"
        self:AddText(strText)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 256 then
        self:OnDefaultEvent(selfId, targetId)
    elseif index == 102 then
        self:BeginEvent(self.script_id)
        self:AddText("#{AQSJ_090709_19}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end
function oloulan_qianhongzhou:LuaFnMtl_CostMaterialData(selfId,nNum,nMaterial1,nMaterial2,nMaterial3,nMaterial4,nMaterial5)
	local ret = 0
	local nAllNum = nNum
	local nCostMaterial = {nMaterial1,nMaterial2,nMaterial3,nMaterial4,nMaterial5}
	for i = 1,#(nCostMaterial) do
		if nCostMaterial[i] ~= nil and nCostMaterial[i] > 0  then
			local nHaveNum = self:LuaFnGetAvailableItemCount(selfId, nCostMaterial[i])
			if nHaveNum > nAllNum then
				nHaveNum = nAllNum
			end
			self:LuaFnDelAvailableItem(selfId,nCostMaterial[i],nHaveNum)
			nAllNum = nAllNum - nHaveNum
			if nAllNum <= 0 then
				return 1
			end				
		end
	end
	return ret
end
function oloulan_qianhongzhou:NotifyFailBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oloulan_qianhongzhou:NotifyFailTips(selfId, Tip)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function oloulan_qianhongzhou:ShowRandomSystemNotice(selfId, strItemInfo)
    local PlayerName = self:GetName(selfId)
    local nMsgIndex = math.random(1, 4)
    local str
    if nMsgIndex == 1 then
        str = string.format(self.g_strGongGaoInfo[1], PlayerName)
    elseif nMsgIndex == 2 then
        str = string.format(self.g_strGongGaoInfo[2], PlayerName)
    elseif nMsgIndex == 3 then
        str = string.format(self.g_strGongGaoInfo[3], PlayerName)
    else
        str = string.format(self.g_strGongGaoInfo[4], PlayerName)
    end
    str = gbk.fromutf8(str)
    str = string.format(str, strItemInfo)
    self:BroadMsgByChatPipe(selfId, str, 4)
end

return oloulan_qianhongzhou
