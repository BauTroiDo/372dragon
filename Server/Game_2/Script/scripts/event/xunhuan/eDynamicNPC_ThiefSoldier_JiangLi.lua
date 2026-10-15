local class = require "class"
local define = require "define"
local script_base = require "script_base"
local eDynamicNPC_ThiefSoldier_JiangLi = class(
                                             "eDynamicNPC_ThiefSoldier_JiangLi",
                                             script_base)
eDynamicNPC_ThiefSoldier_JiangLi.script_id = 050015
eDynamicNPC_ThiefSoldier_JiangLi.ScoreMin = 100
eDynamicNPC_ThiefSoldier_JiangLi.TitleLevel1 = 131
eDynamicNPC_ThiefSoldier_JiangLi.TitleLevel2 = 132
eDynamicNPC_ThiefSoldier_JiangLi.TitleLevel3 = 133
eDynamicNPC_ThiefSoldier_JiangLi.TitleLevel4 = 134
eDynamicNPC_ThiefSoldier_JiangLi.TitleLevel5 = 135
eDynamicNPC_ThiefSoldier_JiangLi.g_TangJinMingTieID = 30505205
eDynamicNPC_ThiefSoldier_JiangLi.g_DelMingTieCount = 1
function eDynamicNPC_ThiefSoldier_JiangLi:OnDefaultEvent(selfId, targetId,arg,index)
    local SelNum = index
    if SelNum == 1 then
        self:DuiHuan(selfId, targetId)
    elseif SelNum == 2 then
        self:ChaXun(selfId, targetId)
    elseif SelNum == 3 then
        self:ZiDingYi(selfId, targetId)
    elseif SelNum == 22 then
        self:MsgBox(selfId, targetId, "#{TangJinMingTie_Help}")
    elseif SelNum == 255 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
    end
end

function eDynamicNPC_ThiefSoldier_JiangLi:OnEnumerate(caller,selfId,targetId)
    caller:AddNumTextWithTarget(self.script_id, "Ta muốn đổi danh hiệu của ta", 6, 1)
    caller:AddNumTextWithTarget(self.script_id, "Ta muốn tra cứu tích phân của ta", 6, 2)
    --caller:AddNumText(self.script_id, "领取帮会自订称号", 6, 3)
    --caller:AddNumText(self.script_id, "关于领取帮会自订称号", 11, 22)
    --caller:AddNumText(self.script_id, "离开......", 8, 255)
end

function eDynamicNPC_ThiefSoldier_JiangLi:GetCurTitleID(selfId)
    local Score = self:GetMissionData(selfId, define.MD_ENUM.MD_ThiefSoldierInvade)
    local Title = 0
    if Score >= 100 and Score < 500 then Title = self.TitleLevel1 end
    if Score >= 500 and Score < 5000 then Title = self.TitleLevel2 end
    if Score >= 5000 and Score < 30000 then Title = self.TitleLevel3 end
    if Score >= 30000 and Score < 65000 then Title = self.TitleLevel4 end
    if Score >= 65000 then Title = self.TitleLevel5 end
    return Title
end

function eDynamicNPC_ThiefSoldier_JiangLi:GetTitleName(Title)
    local TitleName = ""
    if Title == self.TitleLevel1 then
        TitleName = "Binh lính bình định giặc"
    elseif Title == self.TitleLevel2 then
        TitleName = "Đội trưởng bình tặc"
    elseif Title == self.TitleLevel3 then
        TitleName = "Thống lĩnh bình tặc"
    elseif Title == self.TitleLevel4 then
        TitleName = "Đãng khấu tướng quân"
    elseif Title == self.TitleLevel5 then
        TitleName = "Đãng khấu nguyên soái"
    elseif Title > self.TitleLevel5 then
        TitleName = "Đãng khấu nguyên soái"
    else
        TitleName = "Binh lính bình định giặc"
    end
    return TitleName
end

function eDynamicNPC_ThiefSoldier_JiangLi:DuiHuan(selfId, targetId)
    local score = self:GetMissionData(selfId, define.MD_ENUM.MD_ThiefSoldierInvade) 
    if score < 100 then
        self:MsgBox(selfId, targetId,
                    "  Đóng góp của các hạ vẫn chưa đủ để nhận được danh hiệu mới, xin hãy tiếp tục cố gắng.")
        return
    end
    local CurTitle = self:GetCurTitleID(selfId)
    local strText = ""
    if CurTitle > 0 then
        self:LuaFnAwardTitle(selfId,17,CurTitle)
        self:DispatchAllTitle(selfId)
        local TitleName = self:GetTitleName(CurTitle)
        strText = string.format(
                      "  Không tệ, không tệ, triều đình vô cùng hài lòng với sự đóng góp bình định tặc khấu của các chí sĩ, đặc biệt ủy thác ta trao danh hiệu %s. Mong rằng các hạ có thể tiếp tục cống hiến Cường lực của mình cho việc bình định tặc khấu.",
                      TitleName)
    else
        strText = string.format(
                      "  Đóng góp của các hạ vẫn chưa đủ để nhận được danh hiệu mới, xin hãy tiếp tục cố gắng.")
    end
    self:MsgBox(selfId, targetId, strText)
end

function eDynamicNPC_ThiefSoldier_JiangLi:ChaXun(selfId, targetId)
    local score = self:GetMissionData(selfId, define.MD_ENUM.MD_ThiefSoldierInvade)
    local strText = string.format(
                        " Tích phân hiện tại của các hạ là %d, xin hãy tiếp tục cố gắng.",
                        score)
    self:MsgBox(selfId, targetId, strText)
end

function eDynamicNPC_ThiefSoldier_JiangLi:ZiDingYi(selfId, targetId)
    local guildid = self:GetHumanGuildID(selfId)
    if (guildid == -1) then
        self:MsgBox(selfId, targetId,
                    "    Đổi thất bại, ngươi vẫn chưa gia nhập bất kỳ bang phái nào.#W")
        return
    end
    local count = self:GetItemCount(selfId, self.g_TangJinMingTieID)
    if (count < 1) then
        self:MsgBox(selfId, targetId,
                    "    Đổi thất bại, Yêu cầu #YThiếp Vàng Danh Dự.#W")
        return
    end
    --self:LuaFnDrawGuildPositionName(selfId, targetId)
end

function eDynamicNPC_ThiefSoldier_JiangLi:OnDrawPositonName_Succ(selfId)
    local ret = self:LuaFnDelAvailableItem(selfId, self.g_TangJinMingTieID,
                                           self.g_DelMingTieCount)
    if not ret then
        self:MsgBox(selfId, -1,
                    "    Đổi thất bại, xin kiểm tra #YThiếp Vàng Danh Dự#W của ngươi có bị khóa hay không.")
        return 0
    end
    return 1
end

function eDynamicNPC_ThiefSoldier_JiangLi:OnEventRequest(selfId, targetId, arg,
                                                         index)
    if index == 1 then
        self:DuiHuan(selfId, targetId)
    elseif index == 2 then
        self:ChaXun(selfId, targetId)
    elseif index == 3 then
        self:ZiDingYi(selfId, targetId)
    elseif index == 22 then
        self:MsgBox(selfId, targetId, "#{TangJinMingTie_Help}")
    elseif index == 255 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
    end
end

function eDynamicNPC_ThiefSoldier_JiangLi:CheckAccept(selfId) return end

function eDynamicNPC_ThiefSoldier_JiangLi:OnAccept(selfId) end

function eDynamicNPC_ThiefSoldier_JiangLi:OnAbandon(selfId) end

function eDynamicNPC_ThiefSoldier_JiangLi:MakeCopyScene(selfId, nearmembercount) end

function eDynamicNPC_ThiefSoldier_JiangLi:OnContinue(selfId, targetId) end

function eDynamicNPC_ThiefSoldier_JiangLi:CheckSubmit(selfId, selectRadioId) end

function eDynamicNPC_ThiefSoldier_JiangLi:OnSubmit(selfId, targetId,
                                                   selectRadioId) end

function eDynamicNPC_ThiefSoldier_JiangLi:OnKillObject(selfId, objdataId, objId) end

function eDynamicNPC_ThiefSoldier_JiangLi:OnEnterZone(selfId, zoneId) end

function eDynamicNPC_ThiefSoldier_JiangLi:OnItemChanged(selfId, itemdataId) end

function eDynamicNPC_ThiefSoldier_JiangLi:OnCopySceneReady(destsceneId) end

function eDynamicNPC_ThiefSoldier_JiangLi:OnPlayerEnter(selfId) end

function eDynamicNPC_ThiefSoldier_JiangLi:OnHumanDie(selfId, killerId) end

function eDynamicNPC_ThiefSoldier_JiangLi:OnCopySceneTimer(nowTime) end

function eDynamicNPC_ThiefSoldier_JiangLi:NotifyTip(selfId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function eDynamicNPC_ThiefSoldier_JiangLi:MsgBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:AddNumText("Rời khỏi...", 8, 255)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return eDynamicNPC_ThiefSoldier_JiangLi
