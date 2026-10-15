local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local city0_building12 = class("city0_building12", script_base)
city0_building12.script_id = 805019
city0_building12.g_BuildingID14 = 1
city0_building12.g_SavvyToExp = {
    0, 6000, 12730, 18898, 31156, 46811, 82992, 172059, 236185, 827077, 837599
}
city0_building12.g_GrowRateToExp = {0, 7791, 14744, 70492, 251189}
city0_building12.g_hugeExp = 1500000
city0_building12.g_safeNum = 600000000
city0_building12.g_maxExp = 30000000

function city0_building12:OnDefaultEvent(selfId, targetId)
    local guildid = self:GetHumanGuildID(selfId)
    local cityguildid = self:GetCityGuildID(selfId)
    local strText
    if (guildid ~= cityguildid) then
        self:BeginEvent(self.script_id)
        strText = "    Tất cả huynh đệ trong bang này ta đều nhớ tên, vừa nhìn đã biết các hạ không phải người của chúng ta."
        self:AddText(strText)
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return
    end
    self:BeginEvent(self.script_id)
    strText = "#{ZSKSSJ_081113_01}"
    self:AddText(strText)
    self:AddNumText("Sương phòng tửu quán", 8, 1)
    self:AddNumText("#{ZSKSSJ_081113_04}", 6, 2)
    -- self:AddNumText("寄练珍兽", 6, 4)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function city0_building12:OnEventRequest(selfId, targetId, arg, index)
    if index == 3 then
    elseif index == 1 then
        self:BeginEvent(self.script_id)
        self:AddText("#{City_Intro_XiangFang}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif (index == 2) then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:UICommand_AddInt(2)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 8050191)
    elseif index == 4 then
        self:BeginEvent(self.script_id)
        self:AddText("Chức năng này sắp được mở")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

function city0_building12:PetShelizi(selfId, PetGuidH, PetGuidL)
	local ret = self:LuaFnCheckPetShelizi(selfId, PetGuidH, PetGuidL)
	if not self:HandlePetSheliziCheckResult(selfId, ret) then return end
	local nAllExp = self:CalcExp(selfId, PetGuidH, PetGuidL)
    self:BeginUICommand()
    self:UICommand_AddInt(nAllExp)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 8050192)
end

function city0_building12:PetShelizi_Done(selfId, PetGuidH, PetGuidL)
	if self:LuaFnGetPropertyBagSpace(selfId) < 1 then
		self:notify_tips(selfId,"Ô đạo cụ không đủ chỗ.")
		return
	end
	local ret = self:LuaFnCheckPetShelizi(selfId, PetGuidH, PetGuidL)
	if not self:HandlePetSheliziCheckResult(selfId, ret) then return end
	local nAllExp,t_growLevel,t_savvy,t_petLevel = self:CalcExp(selfId, PetGuidH, PetGuidL)
	local needmoney = math.floor(nAllExp / 100)
	if needmoney <= 0 then needmoney = 1 end
	local selfMoney = self:GetMoney(selfId) + self:GetMoneyJZ(selfId)
	if selfMoney < needmoney then
		self:notify_tips(selfId, "#{no_money}")
		return
	end
	self:LuaFnCostMoneyWithPriority(selfId, needmoney)
	if self:LuaFnDeletePetByGUID(selfId, PetGuidH, PetGuidL) then
		local newpos = self:TryRecieveItem(selfId,30900059)
		if newpos ~= -1 then
			self:SetBagItemParam(selfId, newpos, 4, nAllExp, "int", true)
			self:notify_tips(selfId, "#{ZSKSSJ_081126_1}")
			self:ShowObjBuffEffect(selfId,selfId,-1,18)
			if nAllExp > self.g_hugeExp then
				local PlayerName = self:GetName(selfId)
				local growstr = ""
				if t_growLevel == 1 then
					growstr = "#{ZSKSSJ_PT}"
				elseif t_growLevel == 2 then
					growstr = "#{ZSKSSJ_YX}"
				elseif t_growLevel == 3 then
					growstr = "#{ZSKSSJ_JC}"
				elseif t_growLevel == 4 then
					growstr = "#{ZSKSSJ_ZY}"
				elseif t_growLevel == 5 then
					growstr = "#{ZSKSSJ_WM}"
				else
					growstr = "#{ZSKSSJ_PT}"
				end
				local ProductItemInfo = self:GetBagItemTransfer(selfId,newpos)
				local strText = string.format( "#{_INFOUSR%s}#{ZSKSSJ_081113_12}%s#{ZSKSSJ_081113_13}%d#{ZSKSSJ_081113_14}%d#{ZSKSSJ_081113_15}%d#{ZSKSSJ_081113_16}#{_INFOMSG%s}#{ZSKSSJ_081113_17}", PlayerName, growstr, t_savvy, t_petLevel, nAllExp, ProductItemInfo)
				self:AddGlobalCountNews(strText)
				self:BeginUICommand()
				self:UICommand_AddInt(100)
				-- self:UICommand_AddInt(2)
				self:EndUICommand()
				self:DispatchUICommand(selfId, 8050193)
			end
		end
	else
		self:notify_tips(selfId, "Trừ trân thú thất bại.")
	end
    -- local pgH, pgL = self:LuaFnGetCurrentPetGUID(selfId)
    -- if PetGuidH == pgH and PetGuidL == pgL then
        -- self:Notify(selfId, "#{ZSKSSJ_081113_05}")
        -- return
    -- end
    -- if self:LuaFnIsPetLockedByGUID(selfId, PetGuidH, PetGuidL) then
        -- self:Notify(selfId, "#{ZSKSSJ_081113_06}")
        -- return
    -- end
    -- if not self:IsPilferLockFlag(selfId) then return end
    -- if not self:LuaFnCheckPetShelizi(selfId, PetGuidH, PetGuidL) then return end
    -- local nAllExp = self:CalcExp(selfId, PetGuidH, PetGuidL)
    -- local needmoney = math.floor(nAllExp / 100)
    -- if needmoney <= 0 then needmoney = 1 end
    -- local selfMoney = self:GetMoney(selfId) + self:GetMoneyJZ(selfId)
    -- if selfMoney < needmoney then
        -- self:Notify(selfId, "#{no_money}")
        -- return
    -- end
    -- if self:LuaFnGetPropertyBagSpace(selfId) == 0 then
        -- self:Notify(selfId, "#{QRJ_81009_05}")
        -- return
    -- end
    -- if nAllExp > self.g_hugeExp then
		-- local PlayerName = self:GetName(selfId)
        -- local growstr = ""
        -- if t_growLevel == 1 then
            -- growstr = "#{ZSKSSJ_PT}"
        -- elseif t_growLevel == 2 then
            -- growstr = "#{ZSKSSJ_YX}"
        -- elseif t_growLevel == 3 then
            -- growstr = "#{ZSKSSJ_JC}"
        -- elseif t_growLevel == 4 then
            -- growstr = "#{ZSKSSJ_ZY}"
        -- elseif t_growLevel == 5 then
            -- growstr = "#{ZSKSSJ_WM}"
        -- else
            -- growstr = "#{ZSKSSJ_PT}"
        -- end
        -- local ProductItemInfo = self:GetBagItemTransfer(selfId, BagIndex)
        -- local strText = string.format( "#{_INFOUSR%s}#{ZSKSSJ_081113_12}%s#{ZSKSSJ_081113_13}%d#{ZSKSSJ_081113_14}%d#{ZSKSSJ_081113_15}%d#{ZSKSSJ_081113_16}#{_INFOMSG%s}#{ZSKSSJ_081113_17}", PlayerName, growstr, t_savvy, t_petLevel, nAllExp, ProductItemInfo)
        -- self:AddGlobalCountNews(strText)
    -- end
end

function city0_building12:Notify(selfId, str)
    self:BeginEvent(self.script_id)
    self:AddText(str)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function city0_building12:HandlePetSheliziCheckResult(selfId, ret)
	if ret == 1 then
		return true
	elseif ret == 0 then
		self:notify_tips(selfId, "Không tìm thấy trân thú.")
	elseif ret == -1 then
		self:notify_tips(selfId, "#{ZSKSSJ_081113_05}")
	elseif ret == -2 then
		self:notify_tips(selfId, "#{ZSKSSJ_081113_08}")
	elseif ret == -3 then
		self:notify_tips(selfId, "#{ZSKSSJ_081113_09}")
	elseif ret == -4 then
		self:notify_tips(selfId, "Trân thú huyễn hóa không luyện Xá Lợi Tử được.")
	elseif ret == -5 then
		self:notify_tips(selfId, "Trân thú đang mang trang bị.")
	elseif ret == -6 then
		self:notify_tips(selfId, "#{ZSKSSJ_081113_07}")
	else
		self:notify_tips(selfId, "Lỗi không xác định.")
	end
	return false
end

function city0_building12:CalcExp(selfId, PetGuidH, PetGuidL)
    local t_growLevel = self:LuaFnGetPetGrowRateByGUID(selfId, PetGuidH, PetGuidL)
    if t_growLevel < 1 then t_growLevel = 1 end
    local t_savvy = self:GetPetSavvy(selfId, PetGuidH, PetGuidL)
    if t_savvy < 0 then t_savvy = 0 end
    local t_petLevel = self:LuaFnGetPetLevelByGUID(selfId, PetGuidH, PetGuidL)
    local nAllExp = self.g_SavvyToExp[tonumber(t_savvy) + 1] + self.g_GrowRateToExp[tonumber(t_growLevel)]
    local levelToExp = self:GetPetLevelAllExperience(selfId,t_petLevel,self.g_safeNum)
    nAllExp = nAllExp + levelToExp * 0.05
    if nAllExp > self.g_maxExp then
        nAllExp = self.g_maxExp
    end
	return nAllExp,t_growLevel,t_savvy,t_petLevel
end

return city0_building12
