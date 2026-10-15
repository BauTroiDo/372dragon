local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local marry_skill = class("marry_skill", script_base)
marry_skill.script_id = 806016
marry_skill.g_skillList_XXXY = {
    {["id"] = 133, ["name"] = "Tâm Tâm Tương Ấn (cấp 1)", ["firendPt"] = 1000, ["lvM"] = 0, ["lvF"] = 0, ["exp"] = 0, ["money"] = 0},
    {["id"] = 134, ["name"] = "Tâm Tâm Tương Ấn (cấp 2)", ["firendPt"] = 2000, ["lvM"] = 0, ["lvF"] = 0, ["exp"] = 0, ["money"] = 442},
    {["id"] = 135, ["name"] = "Tâm Tâm Tương Ấn (cấp 3)", ["firendPt"] = 3000, ["lvM"] = 0, ["lvF"] = 0, ["exp"] = 0, ["money"] = 967},
    {["id"] = 136, ["name"] = "Tâm Tâm Tương Ấn (cấp 4)", ["firendPt"] = 4000, ["lvM"] = 0, ["lvF"] = 0, ["exp"] = 0, ["money"] = 1800},
    {["id"] = 137, ["name"] = "Tâm Tâm Tương Ấn (cấp 5)", ["firendPt"] = 5000, ["lvM"] = 0, ["lvF"] = 0, ["exp"] = 0, ["money"] = 3009},
    {["id"] = 138, ["name"] = "Tâm Tâm Tương Ấn (cấp 6)", ["firendPt"] = 6000, ["lvM"] = 0, ["lvF"] = 0, ["exp"] = 0, ["money"] = 4660},
    {["id"] = 139, ["name"] = "Tâm Tâm Tương Ấn (cấp 7)", ["firendPt"] = 7000, ["lvM"] = 0, ["lvF"] = 0, ["exp"] = 0, ["money"] = 6825},
    {["id"] = 140, ["name"] = "Tâm Tâm Tương Ấn (cấp 8)", ["firendPt"] = 8000, ["lvM"] = 0, ["lvF"] = 0, ["exp"] = 0, ["money"] = 13322},
    {["id"] = 141, ["name"] = "Tâm Tâm Tương Ấn (cấp 9)", ["firendPt"] = 9000, ["lvM"] = 0, ["lvF"] = 0, ["exp"] = 0, ["money"] = 23449}
}

marry_skill.g_skillList_TQLZ = {
    {
        ["id"] = 123,
        ["name"] = "Đồng Khí Liên Chi (cấp 1)",
        ["firendPt"] = 1000,
        ["lvM"] = 35,
        ["lvF"] = 20,
        ["exp"] = 24739,
        ["money"] = 10000
    },
    {
        ["id"] = 124,
        ["name"] = "Đồng Khí Liên Chi (cấp 2)",
        ["firendPt"] = 3000,
        ["lvM"] = 45,
        ["lvF"] = 30,
        ["exp"] = 53745,
        ["money"] = 40000
    },
    {
        ["id"] = 125,
        ["name"] = "Đồng Khí Liên Chi (cấp 3)",
        ["firendPt"] = 5000,
        ["lvM"] = 55,
        ["lvF"] = 40,
        ["exp"] = 116762,
        ["money"] = 100000
    },
    {
        ["id"] = 126,
        ["name"] = "Đồng Khí Liên Chi (cấp 4)",
        ["firendPt"] = 7000,
        ["lvM"] = 65,
        ["lvF"] = 50,
        ["exp"] = 253665,
        ["money"] = 200000
    },
    {
        ["id"] = 127,
        ["name"] = "Đồng Khí Liên Chi (cấp 5)",
        ["firendPt"] = 9999,
        ["lvM"] = 75,
        ["lvF"] = 60,
        ["exp"] = 551086,
        ["money"] = 500000
    }
}

marry_skill.g_skillList_TCDJ = {
    {
        ["id"] = 128,
        ["name"] = "Thiên Trường Địa Cửu (cấp 1)",
        ["firendPt"] = 1000,
        ["lvM"] = 35,
        ["lvF"] = 20,
        ["exp"] = 24739,
        ["money"] = 10000
    },
    {
        ["id"] = 129,
        ["name"] = "Thiên Trường Địa Cửu (cấp 2)",
        ["firendPt"] = 3000,
        ["lvM"] = 45,
        ["lvF"] = 30,
        ["exp"] = 53745,
        ["money"] = 40000
    },
    {
        ["id"] = 130,
        ["name"] = "Thiên Trường Địa Cửu (cấp 3)",
        ["firendPt"] = 5000,
        ["lvM"] = 55,
        ["lvF"] = 40,
        ["exp"] = 116762,
        ["money"] = 100000
    },
    {
        ["id"] = 131,
        ["name"] = "Thiên Trường Địa Cửu (cấp 4)",
        ["firendPt"] = 7000,
        ["lvM"] = 65,
        ["lvF"] = 50,
        ["exp"] = 253665,
        ["money"] = 200000
    },
    {
        ["id"] = 132,
        ["name"] = "Thiên Trường Địa Cửu (cấp 5)",
        ["firendPt"] = 9999,
        ["lvM"] = 75,
        ["lvF"] = 60,
        ["exp"] = 551086,
        ["money"] = 500000
    }
}

marry_skill.g_skillList_XYBL = {
    {
        ["id"] = 142,
        ["name"] = "Hình Ảnh Bất Ly (cấp 1)",
        ["firendPt"] = 1000,
        ["lvM"] = 35,
        ["lvF"] = 20,
        ["exp"] = 24739,
        ["money"] = 10000
    },
    {
        ["id"] = 143,
        ["name"] = "Hình Ảnh Bất Ly (cấp 2)",
        ["firendPt"] = 3000,
        ["lvM"] = 45,
        ["lvF"] = 30,
        ["exp"] = 53745,
        ["money"] = 40000
    },
    {
        ["id"] = 144,
        ["name"] = "Hình Ảnh Bất Ly (cấp 3)",
        ["firendPt"] = 5000,
        ["lvM"] = 55,
        ["lvF"] = 40,
        ["exp"] = 116762,
        ["money"] = 100000
    },
    {
        ["id"] = 145,
        ["name"] = "Hình Ảnh Bất Ly (cấp 4)",
        ["firendPt"] = 7000,
        ["lvM"] = 65,
        ["lvF"] = 50,
        ["exp"] = 253665,
        ["money"] = 200000
    },
    {
        ["id"] = 146,
        ["name"] = "Hình Ảnh Bất Ly (cấp 5)",
        ["firendPt"] = 9999,
        ["lvM"] = 75,
        ["lvF"] = 60,
        ["exp"] = 551086,
        ["money"] = 500000
    }
}

marry_skill.g_xybl_SkillID = 269
marry_skill.g_xybl_ItemID = 30308059
marry_skill.g_MaxMarrySkill_T = {141, 126, 127, 131, 132, 145, 146}

function marry_skill:OnDefaultEvent(selfId, targetId, index)
    local selectEventId = index
    if selectEventId == 0 then
        self:BeginEvent(self.script_id)
        self:AddNumText("Học Tâm Tâm Tương Ấn", 12, 11)
        self:AddNumText("Học Đồng Khí Liên Chi", 12, 12)
        self:AddNumText("Học Thiên Trường Địa Cửu", 12, 13)
        self:AddNumText("Học Hình Ảnh Bất Ly", 12, 14)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif selectEventId == 11 then
        local ret, nextLevel, maleId, femaleId = self:CheckStudySkill(selfId, targetId, self.g_skillList_XXXY)
        if ret > 0 then
            local skill = self.g_skillList_XXXY[nextLevel + 1]
            self:BeginEvent(self.script_id)
            self:AddText("  Tâm Tâm Tương Ấn có thể tăng Thể lực của phối ngẫu, Kỹ năng Cấp độ càng cao Thể lực tăng càng nhiều.")
            if skill["money"] > 0 then
                self:AddText("  Nam phương Yêu cầu tốn #{_EXCHG" .. skill["money"] .. "} học tập" .. skill["name"] .. "。")
            end
            if nextLevel > 0 then
                self:AddNumText("Thăng cấp Kỹ năng", 12, 21)
            else
                self:AddNumText("Học Kỹ năng", 12, 21)
            end
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        end
    elseif selectEventId == 12 then
        local ret, nextLevel, maleId, femaleId = self:CheckStudySkill(selfId, targetId, self.g_skillList_TQLZ)
        if ret > 0 then
            local skill = self.g_skillList_TQLZ[nextLevel + 1]
            self:BeginEvent(self.script_id)
            self:AddText("  Đồng Khí Liên Chi có thể hồi phục huyết của phối ngẫu, Kỹ năng Cấp độ càng cao, huyết hồi phục càng nhiều.")
            self:AddText("  Học tập" .. skill["name"] .. "Yêu cầu nam phương tốn" .. skill["exp"] .. "kinh nghiệm và #{_EXCHG" .. skill["money"] .. "}。")
            self:AddText(
                "  Đồng thời Yêu cầu hảo cảm độ của phu thê đạt #G" ..
                    skill["firendPt"] .. "#W, Cấp độ của nam phương đạt" .. skill["lvM"] .. "cấp, Cấp độ của nữ phương đạt" .. skill["lvF"] .. "cấp."
            )
            if nextLevel > 0 then
                self:AddNumText("Thăng cấp Kỹ năng", 12, 22)
            else
                self:AddNumText("Học Kỹ năng", 12, 22)
            end
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        end
    elseif selectEventId == 13 then
        local ret, nextLevel = self:CheckStudySkill(selfId, targetId, self.g_skillList_TCDJ)
        if ret > 0 then
            local skill = self.g_skillList_TCDJ[nextLevel + 1]
            self:BeginEvent(self.script_id)
            self:AddText("  Thiên Trường Địa Cửu có thể phục hoạt phu thê và hồi phục một lượng huyết khí nhất định, Kỹ năng Cấp độ càng cao, Kỹ năng Thời gian hồi chiêu càng ít.")
            self:AddText("  Học tập" .. skill["name"] .. "Yêu cầu nam phương tốn" .. skill["exp"] .. "kinh nghiệm và #{_EXCHG" .. skill["money"] .. "}。")
            self:AddText(
                "  Đồng thời Yêu cầu hảo cảm độ của phu thê đạt #G" ..
                    skill["firendPt"] .. "#W, Cấp độ của nam phương đạt" .. skill["lvM"] .. "cấp, Cấp độ của nữ phương đạt" .. skill["lvF"] .. "cấp."
            )
            if nextLevel > 0 then
                self:AddNumText("Thăng cấp Kỹ năng", 12, 23)
            else
                self:AddNumText("Học Kỹ năng", 12, 23)
            end
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        end
    elseif selectEventId == 14 then
        local ret, nextLevel = self:CheckStudySkill(selfId, targetId, self.g_skillList_XYBL)
        if ret > 0 then
            local skill = self.g_skillList_XYBL[nextLevel + 1]
            self:BeginEvent(self.script_id)
            self:AddText("  Hình Ảnh Bất Ly có thể tức thời di chuyển đến vị trí của bạn đời trong cùng bản đồ, Kỹ năng Cấp độ càng cao, Kỹ năng Thời gian hồi chiêu càng ít.")
            if skill["id"] == self.g_xybl_SkillID then
                self:AddText(
                    "  Học tập" .. skill["name"] .. "Yêu cầu nam nhân phải có #G#{_ITEM" .. tostring(self.g_xybl_ItemID) .. "}#W。"
                )
            else
                self:AddText(
                    "  Học tập" .. skill["name"] .. "Yêu cầu nam phương tốn" .. skill["exp"] .. "kinh nghiệm và #{_EXCHG" .. skill["money"] .. "}。"
                )
            end
            self:AddText(
                "  Đồng thời Yêu cầu hảo cảm độ của phu thê đạt #G" ..
                    skill["firendPt"] .. "#W, Cấp độ của nam phương đạt" .. skill["lvM"] .. "cấp, Cấp độ của nữ phương đạt" .. skill["lvF"] .. "cấp."
            )
            if nextLevel > 0 then
                self:AddNumText("Thăng cấp Kỹ năng", 12, 24)
            else
                self:AddNumText("Học Kỹ năng", 12, 24)
            end
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        end
    elseif selectEventId == 21 then
        self:StudySkill(selfId, targetId, self.g_skillList_XXXY)
    elseif selectEventId == 22 then
        self:StudySkill(selfId, targetId, self.g_skillList_TQLZ)
    elseif selectEventId == 23 then
        self:StudySkill(selfId, targetId, self.g_skillList_TCDJ)
    elseif selectEventId == 24 then
        self:StudySkill(selfId, targetId, self.g_skillList_XYBL)
    end
end

function marry_skill:OnEnumerate(caller, selfId, targetId, arg, index)
    local isMarried = self:LuaFnIsMarried(selfId)
    if isMarried then
        caller:AddNumTextWithTarget(self.script_id, "Học tập Phu Thê Kỹ năng", 12, 0)
    end
end

function marry_skill:CheckStudySkill(selfId, targetId, SkillList)
    local szMsg = "Nếu muốn học Kỹ năng phu thê, xin mời hai người nam nữ tổ đội rồi đến tìm ta."
    if not self:LuaFnHasTeam(selfId) then
        self:MessageBox(selfId, targetId, szMsg)
        return 0
    end
    szMsg = "Đội ngũ chỉ được do phu thê hai người tạo thành, trong đội không được có người Khác."
    if self:LuaFnGetTeamSize(selfId) ~= 2 then
        self:MessageBox(selfId, targetId, szMsg)
        return 0
    end
    szMsg = "Chỉ khi cả hai cùng đến bên ta mới có thể học Kỹ năng."
    local nearNum = self:GetNearTeamCount(selfId)
    if nearNum ~= 2 then
        self:MessageBox(selfId, targetId, szMsg)
        return 0
    end
    szMsg = "Không phải phu thê thì không thể học Phu Thê Kỹ năng."
    local maleId = -1
    local femaleId = -1
    for nearIndex = 1, nearNum do
        local memId = self:GetNearTeamMember(selfId, nearIndex)
        local sexType = self:LuaFnGetSex(memId)
        if sexType == 1 then
            maleId = memId
        else
            femaleId = memId
        end
    end
    if maleId == -1 or femaleId == -1 then
        self:MessageBox(selfId, targetId, szMsg)
        return 0
    end
    local isSpouses = self:LuaFnIsSpouses(maleId, femaleId)
    if isSpouses then
    else
        self:MessageBox(selfId, targetId, szMsg)
        return 0
    end
    if not self:LuaFnIsCanDoScriptLogic(maleId) then
        return 0
    end
    if not self:LuaFnIsCanDoScriptLogic(femaleId) then
        return 0
    end
    szMsg = "Song phương phải là bạn bè thì mới có thể học Kỹ năng phu thê."
    local maleIsFirend, femaleIsFirend
    maleIsFirend = self:LuaFnIsFriend(maleId, femaleId)
    femaleIsFirend = self:LuaFnIsFriend(femaleId, maleId)
    if maleIsFirend and femaleIsFirend then
    else
        self:MessageBox(selfId, targetId, szMsg)
        return 0
    end
    local maleSkillLevel
    maleSkillLevel = -1
    local skillLevel = 0
    for _, skill in pairs(SkillList) do
        local maleHaveSkill = self:HaveSkill(maleId, skill["id"])
        if maleHaveSkill and maleHaveSkill > 0 then
            maleSkillLevel = skillLevel
        end
        skillLevel = skillLevel + 1
    end
    local maxSkillLevel = skillLevel - 1
    szMsg = "Kỹ năng này của ngài đã Thăng cấp đến tối đa, không thể tiếp tục Thăng cấp."
    if maleSkillLevel >= maxSkillLevel then
        self:MessageBox(selfId, targetId, szMsg)
        return 0
    end
    return 1
end

function marry_skill:StudySkill(selfId, targetId, SkillList)
    local ret, nextLevel, maleId, femaleId = self:CheckStudySkill(selfId, targetId, SkillList)
    if ret == 0 then
        return
    end
    local skill = SkillList[nextLevel + 1]
    local szMsg = "Độ hữu hảo của song phương phải đạt %d mới có thể học được Kỹ năng phu thê tiếp theo."
    local maleFirendPt, femaleFirendPt, needFirendPt
    maleFirendPt = self:LuaFnGetFriendPoint(maleId, femaleId)
    femaleFirendPt = self:LuaFnGetFriendPoint(femaleId, maleId)
    needFirendPt = skill["firendPt"]
    if maleFirendPt >= needFirendPt and femaleFirendPt >= needFirendPt then
    else
        szMsg = string.format(szMsg, needFirendPt)
        self:MessageBox(selfId, targetId, szMsg)
        return
    end
    szMsg = "Cấp độ của nam giới phải đạt %d mới có thể học được Kỹ năng phu thê tiếp theo."
    if self:GetLevel(maleId) < skill["lvM"] then
        szMsg = string.format(szMsg, skill["lvM"])
        self:MessageBox(selfId, targetId, szMsg)
        return
    end
    szMsg = "Cấp độ của nữ giới phải đạt %d mới có thể học được Kỹ năng phu thê tiếp theo."
    if self:GetLevel(femaleId) < skill["lvF"] then
        szMsg = string.format(szMsg, skill["lvF"])
        self:MessageBox(selfId, targetId, szMsg)
        return
    end
    if skill["id"] == self.g_xybl_SkillID then
        if not self:HaveItemInBag(maleId, self.g_xybl_ItemID) then
            self:MessageBox(selfId, targetId, "Nam giới Yêu cầu phải có #G#{_ITEM" .. tostring(self.g_xybl_ItemID) .. "}#W mới có thể học Kỹ năng này!")
            return
        end
        if self:LuaFnGetAvailableItemCount(maleId, self.g_xybl_ItemID) <= 0 then
            self:MessageBox(selfId, targetId, "Vật phẩm Yêu cầu#G#{_ITEM" .. tostring(self.g_xybl_ItemID) .. "}#Wđã khóa, xin hãy mở khóa rồi học!")
            return
        end
        self:LuaFnDelAvailableItem(maleId, self.g_xybl_ItemID, 1)
    else
        szMsg = "kinh nghiệm của nam nhân phải đạt %d mới có thể học được Kỹ năng phu thê tiếp theo."
        if self:GetExp(maleId) < skill["exp"] then
            szMsg = string.format(szMsg, skill["exp"])
            self:MessageBox(selfId, targetId, szMsg)
            return
        end
        szMsg = "Nam nhân Yêu cầu mang theo #{_EXCHG%d} mới có thể học Kỹ năng."
        local maleMoney, needMoney
        maleMoney = self:LuaFnGetMoney(maleId)
        needMoney = skill["money"]
        if maleMoney and maleMoney + self:GetMoneyJZ(maleId) >= needMoney then
        else
            szMsg = string.format(szMsg, needMoney)
            self:MessageBox(selfId, targetId, szMsg)
            return
        end
        self:LuaFnCostMoneyWithPriority(maleId, needMoney)
        if skill["exp"] > 0 then
            self:LuaFnAddExp(maleId, -skill["exp"])
        end
    end
    self:MyAddSkill(maleId, SkillList, nextLevel)
    self:MyAddSkill(femaleId, SkillList, nextLevel)
    self:SendWorldMsg(maleId, femaleId, SkillList, nextLevel)
    self:LogCoupleAction(maleId, femaleId, SkillList, nextLevel)
    self:BeginUICommand()
    self:EndUICommand()
    self:DispatchUICommand(selfId, 1000)
    return
end

function marry_skill:MyAddSkill(selfId, SkillList, nextLevel)
    for _, tempSkill in pairs(SkillList) do
        local haveSkill = self:HaveSkill(selfId, tempSkill["id"])
        if haveSkill and haveSkill > 0 then
            self:DelSkill(selfId, tempSkill["id"])
        end
    end
    local skill = SkillList[nextLevel + 1]
    self:AddSkill(selfId, skill["id"])
    if skill["id"] == self.g_xybl_SkillID then
        self:SendSkillMsg_XYBL(selfId, skill["name"])
    else
        self:SendSkillMsg(selfId, skill["exp"], skill["money"], skill["name"])
    end
end

function marry_skill:MessageBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function marry_skill:SendSkillMsg_XYBL(selfId, skname)
    if skname then
        local str =
            string.format(
            "#IQuý phu phụ đồng tâm hiệp lực, vượt qua muôn vàn khó khăn, khi nam nhân hao phí #Y#{_ITEM" .. tostring(self.g_xybl_ItemID) .. "}#I sau, cuối cùng đã học được Kỹ năng phu thê #Y%s.",
            skname
        )
        self:BeginEvent(self.script_id)
        self:AddText(str)
        self:EndEvent()
        self:DispatchMissionTips(selfId)
    end
end

function marry_skill:SendSkillMsg(selfId, exp, money, skname)
    if exp and money and skname then
        local moneyt = string.format("#{_EXCHG%d}", money)
        local str = string.format("#IQuý phu thê đồng tâm hiệp lực, vượt qua muôn vàn khó khăn, sau khi nam nhân hao tốn #Y%dkinh nghiệm và %skim tiền#I, cuối cùng đã học được phu thê Kỹ năng #Y%s.", exp, moneyt, skname)
        self:BeginEvent(self.script_id)
        self:AddText(str)
        self:EndEvent()
        self:DispatchMissionTips(selfId)
    end
end

function marry_skill:SendWorldMsg(maleId, femaleId, SkillList, nextLevel)
    local skill = SkillList[nextLevel + 1]
    if maleId and femaleId and skill then
        for _, tempId in pairs(self.g_MaxMarrySkill_T) do
            if tempId == skill["id"] then
                local uname = string.format("#{_INFOUSR%s}", self:GetName(maleId))
                local oname = string.format("#{_INFOUSR%s}", self:GetName(femaleId))
                local str = string.format("#W%s#I cùng #W%s#I phu thê đồng lòng, cuối cùng khổ tận cam lai, học được #cff66cc%s#I, quả không hổ là tấm gương cho tất cả phu thê.", uname, oname, skill["name"])
                str = gbk.fromutf8(str)
                self:BroadMsgByChatPipe(maleId, str, 4)
                return
            end
        end
    end
end

function marry_skill:LogCoupleAction(tid1, tid2, SkillList, nextLevel)
    local skill = SkillList[nextLevel + 1]
    local logid = ScriptGlobal.COUPLE_LOG_LEVELUPSKILL
    if nextLevel == 0 then
        logid = ScriptGlobal.COUPLE_LOG_LEARNSKILL
    end
    if skill and logid and ScriptGlobal.COUPLE_LOG_DETAIL[logid] then
        local logstr =
            string.format(
            "CPL:%d,%s,0x%X,0x%X,%d,%s",
            logid,
            ScriptGlobal.COUPLE_LOG_DETAIL[logid],
            self:LuaFnGetGUID(tid1),
            self:LuaFnGetGUID(tid2),
            skill["id"],
            skill["name"]
        )
        self:LogCouple(logstr)
    end
end

return marry_skill
