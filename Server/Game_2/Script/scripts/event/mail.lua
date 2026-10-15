local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local mail = class("mail", script_base)
mail.script_id = 888889
function mail:ExecuteMail(selfId, param0, param1, param2, param3, param4)
    if param0 == ScriptGlobal.MAIL_REPUDIATE then
        self:Mail_Repudiate(selfId, param0, param1, param2, param3)
    elseif param0 == ScriptGlobal.MAIL_BETRAYMASTER then
        self:Mail_BetrayMaster(selfId, param0, param1, param2, param3)
    elseif param0 == ScriptGlobal.MAIL_EXPELPRENTICE then
        self:Mail_ExpelPrentice(selfId, param0, param1, param2, param3)
    elseif param0 == ScriptGlobal.MAIL_UPDATE_ATTR then
        self:LuaFnUpdateAttr(selfId, param0, param1, param2, param3)
    elseif param0 == ScriptGlobal.MAIL_UNSWEAR then
        self:Mail_Unswear(selfId, param0, param1, param2, param3)
    elseif param0 == ScriptGlobal.MAIL_PRENTICE_EXP then
        self:Mail_PrenticeProfExp(selfId, param0, param1, param2, param3)
    elseif param0 == ScriptGlobal.MAIL_COMMISIONSHOP then
        self:Mail_CommisionShop(selfId, param0, param1, param2, param3)
    elseif param0 == ScriptGlobal.MAIL_HUASHANJIANGLI then
        self:Mail_HuaShanJiangLi(selfId, param0, param1, param2, param3)
    elseif param0 == ScriptGlobal.MAIL_SHITUPRIZE then
        self:Mail_ShiTuPrize(selfId, param0, param1, param2, param3)
    elseif param0 == ScriptGlobal.MAIL_SHITUPRIZE_GOODBAD then
        self:Mail_Prize_ExpAndGoodBad(selfId, param0, param1, param2, param3)
    elseif param0 == ScriptGlobal.MIAL_SHITU_CHUSHI then
        self:Mail_ShiTuChuShi(selfId, param0, param1, param2, param3)
    elseif param0 == ScriptGlobal.MAIL_FINDFRIEND_DELINFO then
        self:FindFriendDelInfo(selfId, param0, param1, param2, param3)
    elseif param0 == define.MAIL_JINGPAI_BACK_YUANBAO then
		-- local skynet = require "skynet"
		-- skynet.logi("define.MAIL_JINGPAI_BACK_YUANBAO")
		self:NotifyJingPaiYuanBaoRedPoint(selfId,param1, param2, param3, param4)
    elseif param0 == define.MAIL_UPDATE_MINGDONG_TOP then
		if self:LuaFnGetGUID(selfId) == param1 then
			self:UpdateMingDongTop(selfId)
		end
    end
end

function mail:NotifyJingPaiYuanBaoRedPoint(selfId,guid,money,itemid,count)
	-- local skynet = require "skynet"
		-- skynet.logi("guid = ",guid,"money = ",money,"itemid = ",itemid,"count = ",count)
	if self:LuaFnGetGUID(selfId) == guid then
		local add_clientyb = self:GetMissionData(selfId, ScriptGlobal.MD_JINGPAI_YUANBAO_CLIENT) + money
		if add_clientyb < 0 then
			add_clientyb = 0
		end
		self:SetMissionData(selfId, ScriptGlobal.MD_JINGPAI_YUANBAO_CLIENT,add_clientyb)
		self:BeginUICommand()
		self:EndUICommand()
		self:DispatchUICommand(selfId,88881801)
		local msg = self:ScriptGlobal_Format("#{SZPM_230913_79}",count,self:GetItemName(itemid),money)
		self:NotifySystemMsg(selfId,msg)
	end
	-- SZPM_230913_79
	-- #H您参与竞拍%s0个%s1（#H%s2#H）的出价已被其他人超过，因返还元宝后您的元宝会超过上限，请消费后在界面处领取竞拍元宝。
end

function mail:NoScriptTypeMail(selfId, scripttype)
    if scripttype == ScriptGlobal.MAIL_COMMISIONSHOP then
        self:NotifyFailBox(selfId, -1, "    Xin thứ lỗi, hiện tại ngài không có Nguyên bảo hoặc vàng để thu.")
    elseif scripttype == ScriptGlobal.MAIL_SHITUPRIZE then
        self:NotifyFailBox(selfId, -1, "    Ngươi không có phiếu thưởng để lĩnh, mau đi đốc thúc đồ đệ ngươi hảo hảo Thăng cấp đi!")
    elseif scripttype == ScriptGlobal.MAIL_HUASHANJIANGLI then
        self:NotifySystemMsg(selfId, "#{HSLJ20080221_01}")
    end
end

function mail:FindScriptTypeMail(selfId, scripttype)
    if scripttype == ScriptGlobal.MAIL_COMMISIONSHOP then
        self:NotifyFailBox(selfId, -1, "    Nguyên bảo và kim tệ của ngài đã thu thành công, xin hãy kiểm tra thư.")
    elseif scripttype == ScriptGlobal.MAIL_SHITUPRIZE then
    elseif scripttype == ScriptGlobal.MAIL_HUASHANJIANGLI then
        self:NotifySystemMsg(selfId, "#{HSLJ20080221_02}")
    end
end

function mail:NotifyFailBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function mail:Mail_ShiTuChuShi(selfId, command, PrenticeGuid, zero, zero)
    self:LuaFnExpelPrentice(selfId, PrenticeGuid)
end

function mail:Mail_Prize_ExpAndGoodBad(selfId, command, PrenticeGuid, Exps, GoodBad)
    if Exps > 0 then
        self:LuaAddPrenticeProExp(selfId, PrenticeGuid, Exps)
    end
    if GoodBad > 0 then
        local gb_value = self:LuaFnGetHumanGoodBadValue(selfId)
        self:LuaFnSetHumanGoodBadValue(selfId, gb_value + GoodBad)
    end
end

function mail:Mail_PrenticeProfExp(selfId, command, PrenticeGuid, Exps, zero)
    if Exps > 0 then
        self:LuaAddPrenticeProExp(selfId, PrenticeGuid, Exps)
    end
end

function mail:Mail_Unswear(selfId, command, betrayerGuid, alldismiss, zero)
    local FriendPoint = self:LuaFnGetFriendPointByGUID(selfId, betrayerGuid)
    if FriendPoint > 500 then
        self:LuaFnSetFriendPointByGUID(selfId, betrayerGuid, 500)
    end
    self:LuaFnUnswear(selfId, betrayerGuid)
    if tonumber(alldismiss) == 1 then
        self:AwardJieBaiTitle(selfId, "")
        self:DispatchAllTitle(selfId)
    end
end

function mail:Mail_Repudiate(selfId, param0, param1, param2, param3)
    if not param1 or param1 == -1 then
        return
    end
    if param1 < 0 then
        param1 = 4294967296 + param1
    end
    local SpouseGUID = self:LuaFnGetSpouseGUID(selfId)
    if param1 ~= 0 and param1 ~= SpouseGUID then
        return
    end
    self:LuaFnAwardSpouseTitle(selfId, "")
    self:DispatchAllTitle(selfId)
    local Skills = {260, 261, 262, 263, 264, 265, 266, 267, 268}
    for i, skillId in pairs(Skills) do
        self:DelSkill(selfId, skillId)
    end
    local NewSkill = {250, 251, 252, 253, 254, 255, 256, 257, 258, 259}
    for _, skillId in pairs(NewSkill) do
        self:DelSkill(selfId, skillId)
    end
    for _, skillId in pairs({269, 270, 271, 272, 273}) do
        self:DelSkill(selfId, skillId)
    end
    self:LuaFnSetFriendPointByGUID(selfId, SpouseGUID, 10)
    self:CallScriptFunction(250036, "OnAbandon", selfId)
    self:CallScriptFunction(250037, "OnAbandon", selfId)
    self:LuaFnDivorce(selfId)
end

function mail:Mail_BetrayMaster(selfId, param0, param1, param2, param3)
    self:LuaFnExpelPrentice(selfId, param1)
end

function mail:Mail_ExpelPrentice(selfId, param0, param1, param2, param3)
    self:AwardShiTuTitle(selfId, "")
    self:DispatchAllTitle(selfId)
    self:LuaFnBetrayMaster(selfId)
end

function mail:Mail_CommisionShop(selfId, param0, param1, param2, param3)
    if param1 == 1 then
        local ret = self:CSAddBankMoney(selfId, param3, "CSOP8")
        local strAppend = ""
        if ret == 0 then
            return
        else
            if ret == 1 then
                strAppend = ""
            elseif ret == 2 then
                strAppend = "#{Mail_TooMuchMoney}"
            end
        end
        local mailStr = string.format(
            "Vật phẩm ký gửi #{_MONEY%d} của ngài hết hạn chưa bán được, tiền hoàn trả đã được gửi vào tài khoản ngân hàng của ngài.%s", param3,
            strAppend)
        self:LuaFnSendSystemMail(self:GetName(selfId), mailStr)
        local logStr = string.format("Recvback type:1 sn:%d value:%d", param2, param3)
        self:LogCommisionDeal(selfId, logStr)
    elseif param1 == 0 then
        self:CSAddYuanbao(selfId, param3, "CSOP4")
        local mailStr = string.format("Ký gửi %d điểm Nguyên bảo của ngài hết hạn chưa bán được, cửa hàng đã hoàn trả điểm cho ngài.", param3)
        self:LuaFnSendSystemMail(self:GetName(selfId), mailStr)
        local logStr = string.format("Recvback type:0 sn:%d value:%d", param2, param3)
        self:LogCommisionDeal(selfId, logStr)
    elseif param1 == 2 then
        local ret = self:CSAddBankMoney(selfId, param3, "CSOP3")
        local strAppend = ""
        if ret == 0 then
            return
        else
            if ret == 1 then
                strAppend = ""
            elseif ret == 2 then
                strAppend = "#{Mail_TooMuchMoney}"
            end
        end
        local mailStr = string.format(
            "Nguyên bảo ký gửi của ngài đã bán thành công, ngài nhận được #{_MONEY%d} đã được gửi vào tài khoản ngân hàng của ngài.%s", param3,
            strAppend)
        self:LuaFnSendSystemMail(self:GetName(selfId), mailStr)
        local logStr = string.format("Gain type:1 sn:%d value:%d", param2, param3)
        self:LogCommisionDeal(selfId, logStr)
    elseif param1 == 3 then
        self:CSAddYuanbao(selfId, param3, "CSOP7")
        local mailStr = string.format(
            "Tiền ký gửi của ngài đã bán thành công, ngài nhận được %d điểm Nguyên bảo đã được cộng vào người.", param3)
        self:LuaFnSendSystemMail(self:GetName(selfId), mailStr)
        local logStr = string.format("Gain type:0 sn:%d value:%d", param2, param3)
        self:LogCommisionDeal(selfId, logStr)
    end
    self:DecCommisionNum(selfId)
end

function mail:Mail_HuaShanJiangLi(selfId, param0, param1, param2, param3)
    local strLogCheck = ""
    if param2 == 1 then
        if param3 == 1 then
            self:SetMissionFlag(selfId, ScriptGlobal.MF_LunjianJiangli01, 0)
            self:SetMissionFlag(selfId, ScriptGlobal.MF_LunjianJiangli02, 0)
            self:SetMissionFlag(selfId, ScriptGlobal.MF_LunjianJiangli03, 1)
            self:SetMissionData(selfId, ScriptGlobal.MD_HUASHANJIANGLI_TIME, param1)
            strLogCheck = string.format(
                "HuaShanLunJian_MissionData    FULL_NO.1=(id=%X, Param01=%d, Param02=%d, Param03=%d, Param04=%d)",
                self:LuaFnGetGUID(selfId), 0, 0, 1, param1)
            self:LuaFnLogCheck(strLogCheck)
        elseif param3 == 2 then
            self:SetMissionFlag(selfId, ScriptGlobal.MF_LunjianJiangli01, 0)
            self:SetMissionFlag(selfId, ScriptGlobal.MF_LunjianJiangli02, 1)
            self:SetMissionFlag(selfId, ScriptGlobal.MF_LunjianJiangli03, 0)
            self:SetMissionData(selfId, ScriptGlobal.MD_HUASHANJIANGLI_TIME, param1)
            strLogCheck = string.format(
                "HuaShanLunJian_MissionData    FULL_NO.2=(id=%X, Param01=%d, Param02=%d, Param03=%d, Param04=%d)",
                self:LuaFnGetGUID(selfId), 0, 1, 0, param1)
            self:LuaFnLogCheck(strLogCheck)
        elseif param3 == 3 then
            self:SetMissionFlag(selfId, ScriptGlobal.MF_LunjianJiangli01, 0)
            self:SetMissionFlag(selfId, ScriptGlobal.MF_LunjianJiangli02, 1)
            self:SetMissionFlag(selfId, ScriptGlobal.MF_LunjianJiangli03, 1)
            self:SetMissionData(selfId, ScriptGlobal.MD_HUASHANJIANGLI_TIME, param1)
            strLogCheck = string.format(
                "HuaShanLunJian_MissionData    FULL_NO.3=(id=%X, Param01=%d, Param02=%d, Param03=%d, Param04=%d)",
                self:LuaFnGetGUID(selfId), 0, 1, 1, param1)
            self:LuaFnLogCheck(strLogCheck)
        end
    elseif param2 == 2 then
        if param3 == 1 then
            self:SetMissionFlag(selfId, ScriptGlobal.MF_LunjianJiangli01, 1)
            self:SetMissionFlag(selfId, ScriptGlobal.MF_LunjianJiangli02, 0)
            self:SetMissionFlag(selfId, ScriptGlobal.MF_LunjianJiangli03, 0)
            self:SetMissionData(selfId, ScriptGlobal.MD_HUASHANJIANGLI_TIME, param1)
            strLogCheck = string.format(
                "HuaShanLunJian_MissionData    MenPai_NO.1=(id=%X, Param01=%d, Param02=%d, Param03=%d, Param04=%d)",
                self:LuaFnGetGUID(selfId), 1, 0, 0, param1)
            self:LuaFnLogCheck(strLogCheck)
        elseif param3 == 2 then
            self:SetMissionFlag(selfId, ScriptGlobal.MF_LunjianJiangli01, 1)
            self:SetMissionFlag(selfId, ScriptGlobal.MF_LunjianJiangli02, 0)
            self:SetMissionFlag(selfId, ScriptGlobal.MF_LunjianJiangli03, 1)
            self:SetMissionData(selfId, ScriptGlobal.MD_HUASHANJIANGLI_TIME, param1)
            strLogCheck = string.format(
                "HuaShanLunJian_MissionData    MenPai_NO.2=(id=%X, Param01=%d, Param02=%d, Param03=%d, Param04=%d)",
                self:LuaFnGetGUID(selfId), 1, 0, 1, param1)
            self:LuaFnLogCheck(strLogCheck)
        elseif param3 == 3 then
            self:SetMissionFlag(selfId, ScriptGlobal.MF_LunjianJiangli01, 1)
            self:SetMissionFlag(selfId, ScriptGlobal.MF_LunjianJiangli02, 1)
            self:SetMissionFlag(selfId, ScriptGlobal.MF_LunjianJiangli03, 0)
            self:SetMissionData(selfId, ScriptGlobal.MD_HUASHANJIANGLI_TIME, param1)
            strLogCheck = string.format(
                "HuaShanLunJian_MissionData    MenPai_NO.3=(id=%X, Param01=%d, Param02=%d, Param03=%d, Param04=%d)",
                self:LuaFnGetGUID(selfId), 1, 1, 0, param1)
            self:LuaFnLogCheck(strLogCheck)
        end
    end
end

function mail:Mail_ShiTuPrize(selfId, param0, param1, param2, param3)
    local plevel = param1
    local ct = self:GetMissionData(selfId, ScriptGlobal.MD_SHITU_PRIZE_COUNT)
    local c40 = ct % 100
    local c50 = math.floor(ct / 100)
    if 40 == plevel then
        if 10 < c40 + 1 then
            self:NotifySystemMsg(selfId, "Lĩnh thưởng phiếu Danh Sư thất bại, đã đạt đến giới hạn.")
            return
        end
    elseif 50 == plevel then
        if 10 < c50 + 1 then
            self:NotifySystemMsg(selfId, "Lĩnh thưởng phiếu Danh Sư Cao Cấp thất bại, đã đạt đến giới hạn.")
            return
        end
    end
    local itemId = param2
    local itemNum = param3
    self:LuaFnBeginAddItem()
    self:LuaFnAddItem(itemId, itemNum)
    local ret = self:LuaFnEndAddItem(selfId)
    if ret then
        self:AddItemListToHuman(selfId)
        self:NotifySystemMsg(selfId, "Lĩnh thưởng phiếu thành công.")
        local logstr = string.format("PL:%d,0x%X,%s,%d", ScriptGlobal.PRIZE_LOG_XINSHOUSHITU, self:LuaFnGetGUID(selfId),
            self:GetName(selfId), itemId)
        self:LuaFnLogPrize(logstr)
    else
        self:NotifySystemMsg(selfId, "Không đủ không gian Ô Đạo cụ nhiệm vụ, lĩnh thất bại.")
        return
    end
    if 40 == plevel then
        self:SetMissionData(selfId, ScriptGlobal.MD_SHITU_PRIZE_COUNT, ct + 1)
    elseif 50 == plevel then
        self:SetMissionData(selfId, ScriptGlobal.MD_SHITU_PRIZE_COUNT, (c50 + 1) * 100 + c40)
    end
end

function mail:NotifySystemMsg(selfId, tip)
    self:BeginEvent(self.script_id)
    self:AddText(tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function mail:FindFriendDelInfo(selfId, param0, param1, param2, param3)
    local nADType = param1
    local nDelInfoTime = param2
    if nADType > 4 or nADType < 1 then
        return
    end
    if nADType == 1 then
        self:SetMissionData(selfId, ScriptGlobal.MD_FINDFRIENDAD_DELTIME_MARRY, nDelInfoTime)
    elseif nADType == 2 then
        self:SetMissionData(selfId, ScriptGlobal.MD_FINDFRIENDAD_DELTIME_GUILD, nDelInfoTime)
    elseif nADType == 3 then
        self:SetMissionData(selfId, ScriptGlobal.MD_FINDFRIENDAD_DELTIME_TEACHER, nDelInfoTime)
    elseif nADType == 4 then
        self:SetMissionData(selfId, ScriptGlobal.MD_FINDFRIENDAD_DELTIME_BROTHER, nDelInfoTime)
    end
    self:Audit_FindFriendAD_DelInfo(selfId, nADType)
end

return mail
