local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local odali_azi = class("odali_azi", script_base)
odali_azi.script_id = 2115
odali_azi.g_ModifyMenpaibookID = 38002427
local nMenPaiName = {"少林","明教","丐帮","武当","峨眉","星宿","天龙","天山","逍遥","无门派","曼陀山庄","恶人谷","慕容"}
local nMenPaiAttr = {
					"Thuộc tính huyền",
					"Thuộc tính hỏa",
					"Thuộc tính độc, thuộc tính hỏa",
					"Thuộc tính băng, thuộc tính huyền",
					"Thuộc tính băng, thuộc tính huyền",
					"Thuộc tính độc",
					"Thuộc tính Băng, Hỏa, Huyền, Độc",
					"Thuộc tính băng",
					"Thuộc tính hỏa, thuộc tính độc",
					"Không Thuộc tính",
					"Huyền #Thuộc tính#, Độc #Thuộc tính#",
					"ĐộcThuộc tính, BăngThuộc tính",
					"Thuộc tính huyền"}
function odali_azi:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{MPZH_180719_01}")
    self:AddNumText("#{MPZH_180719_02}", 6, 0)
    -- local nCurrentTime = self:GetTime2Day()
    -- local nLastTime = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_LAST_MODIFYMENPAI_TIME)
    -- if nCurrentTime < nLastTime then
        -- local nMenPaiID = self:GetMissionDataEx(selfId, ScriptGlobal.MD_LAST_MODIFYMENPAI_OLDID)
        -- if nMenPaiID ~= self:GetMenPai(selfId) and nMenPaiID ~= 9 then
            -- self:AddNumText("转回原门派", 6, 3)
        -- end
    -- end
    self:AddNumText("Lĩnh Chuyển đổi môn phái bảo điển", 6, 1)
    self:AddNumText("Về Chuyển đổi môn phái", 11, 2)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function odali_azi:OnEventRequest(selfId, targetId, arg, index)
    local Operation = index
    if Operation == 0 then
        self:BeginUICommand()
        self:UICommand_AddInt(22)
        self:UICommand_AddInt(self:GetMenPai(selfId))
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 2115)
    end
    if Operation == 1 then
        local nNum = self:LuaFnGetAvailableItemCount(selfId, self.g_ModifyMenpaibookID)
        if nNum >= 1 then
            self:NotifyTip(selfId, "#HTrong túi của ngài đã có Cẩm nang hướng dẫn chuyển Môn phái, không thể nhận trùng lặp.")
            return
        end
        if self:LuaFnGetPropertyBagSpace(selfId) < 1 then
            self:NotifyTip(selfId, "#HĐạo cụ trong túi của ngài không đủ 1 chỗ trống, không thể nhận.")
            return
        end
        self:TryRecieveItem(selfId, self.g_ModifyMenpaibookID, 1)
        self:NotifyTip(selfId, "#HNgài đã nhận thành công Chuyển đổi môn phái bảo điển.")
    end
    if Operation == 2 then
        self:BeginEvent(self.script_id)
        self:AddText("#{MPZH_180719_104}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if Operation == 3 then
        --self:CallScriptFunction(900030, "OnRegretCheck", selfId, targetId)
        return
    end
end

function odali_azi:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

local yigudan = { 38002426, 38002428 }
function odali_azi:OnContinueCheck(selfId, targetId, menpai)
	
	--self:notify_tips(selfId, "menpai="..menpai)
	
	if menpai > 15 then -- CS3b: ≤15 = 15 phái CY
		return
	end
    if self:LuaFnMtl_GetCostNum(selfId, yigudan) < 1 then
        self:notify_tips(selfId, "Không có Di Cốt Đan")
        return
    end
    self:BeginUICommand()
    self:UICommand_AddInt(44)
    self:UICommand_AddInt(targetId)
    self:UICommand_AddInt(menpai)
    self:UICommand_AddStr(string.format("    #cfff263Môn phái ngươi đã đổi là: #G%s#cfff263, thuộc tính chính của môn phái này là: #G%s#cfff263, xác nhận muốn đổi môn phái chứ?#r    Nếu muốn chuyển đổi sang môn phái này, sau khi xác nhận, hãy lại bấm nút “#GĐã quyết tâm#cfff263” trong giao diện Chuyển đổi môn phái, sẽ đổi môn phái cho ngươi. Nếu không thì có thể bấm nút “#GTa lại nghĩ xem#cfff263”, kết thúc lần Chuyển đổi môn phái này.",nMenPaiName[menpai + 1],nMenPaiAttr[menpai + 1]))
    self:EndUICommand()
    self:DispatchUICommand(selfId, 2115)
end

function odali_azi:OnConfirmSwitch(selfId, targetId, menpai)
	if menpai > 15 then -- CS3b: ≤15 = 15 phái CY
		return
	end
    if self:GetLevel(selfId) < 60 then
        self:NotifyTip(selfId,"#{MPZH_180719_38}")
        return
    end
	local c0 = self:LuaFnGetAvailableItemCount(selfId, 38002426)
	local c1 = self:LuaFnGetAvailableItemCount(selfId, 38002428)
	if c0 + c1 < 1 then
		self:notify_tips(selfId, "Không có Di Cốt Đan")
		return
	end
	local costtab = {}
	if c0 > 0 then
		table.insert(costtab,38002426)
	end
	if c1 > 0 then
		table.insert(costtab,38002428)
	end
	local del = self:LuaFnMtl_CostMaterial(selfId,1,costtab)
	if not del then
		 self:notify_tips(selfId, "Trừ Di Cốt Đan thất bại.")
		return
	end

	
    -- if self:LuaFnMtl_GetCostNum(selfId, yigudan) < 1 then
        -- self:notify_tips(selfId, "没有移骨丹")
        -- return
    -- end
    local oldMenPai = self:GetMenPai(selfId)
    self:LuaFnCancelImpactInSpecificImpact(selfId, 308)
    -- self:LuaFnMtl_CostMaterial(selfId, 1, { 38002426, 38002428 })
    self:LuaFnChangeMenPai(selfId, menpai)
    -- 转峨眉时删除清心普善咒(技能ID 424)
    if menpai == 4 then
        self:DelSkill(selfId, 424)
    end
    self:SetMissionDataEx(selfId,ScriptGlobal.MDEX_LAST_MODIFYMENPAI_TIME,oldMenPai) --记录转换前的上一次门派
	--self:CallScriptFunction(888899, "UpdateRechargeMenPaiTitle", selfId, oldMenPai)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 49, 0)
end

function odali_azi:NotifyTip(selfId, Msg)
    self:BeginEvent(self.script_id)
    self:AddText(Msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return odali_azi
