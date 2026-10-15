local class = require "class"
local define = require "define"
local script_base = require "script_base"
local edali_0239 = class("edali_0239", script_base)
edali_0239.script_id = 210239
edali_0239.g_Position_X = 160.0895
edali_0239.g_Position_Z = 156.9309
edali_0239.g_SceneID = 2
edali_0239.g_AccomplishNPC_Name = "赵天师"
edali_0239.g_MissionId = 719
edali_0239.g_MissionIdPer = 718
edali_0239.g_Name = "赵天师"
edali_0239.g_MissionKind = 13
edali_0239.g_MissionLevel = 10
edali_0239.g_IfMissionElite = 0
edali_0239.g_MissionName = "Danh Môn Chính Phái"
edali_0239.g_MissionInfo = ""
edali_0239.g_MissionInfo1 = "    $N, ngươi cuối cùng cũng đến rồi.#r    Không tệ không tệ, căn cơ của ngươi hiện tại đã đánh rất vững chắc, đi thập đại Môn phái học võ công cao thâm đã là chuyện đương nhiên rồi."
edali_0239.g_MissionInfo2 = "    Đúng, ngươi không nghe lầm đâu, chính là thập đại Môn phái trong truyền thuyết. Tinh Túc phái là đại tông của Tây Vực, Thiên Sơn phái là kỳ hoa của Tây Bắc, Thiên Long phái là trụ cột của trời Nam, Tiêu Dao phái thần xuất quỷ một, Nga My phái vạn phật triều tông, Võ Đang phái đạo cốt tiên phong, Minh Giáo là thiên hạ đệ nhất đại giáo, Cái Bang là thiên hạ đệ nhất đại bang, Thiếu Lâm phái lại càng là Thái Sơn Bắc Đẩu của võ lâm thiên hạ."
edali_0239.g_MissionInfo3 = "    Bất luận ngươi bái nhập Môn phái nào, đều là bước lên một con đường rộng mở rồi, mấy lão già chúng ta đây cũng được nở mày nở mặt."
edali_0239.g_MissionInfo4 = "    Vậy đi, ngươi đi tìm người thu nhận của thập đại Môn phái nói chuyện, nghe bọn họ giảng về đặc sắc của các Môn phái lớn, sau đó chọn một Môn phái gia nhập. Đợi ngươi trở thành đệ tử của thập đại Môn phái, ngươi lại đến tìm ta, chúng ta sẽ mở một tiệc ăn mừng cho ngươi."
edali_0239.g_MissionTarget = "#{MIS_dali_ZTS_001}"
edali_0239.g_ContinueInfo = "    Đã trở thành đệ tử của thập đại Môn phái rồi sao?"
edali_0239.g_MissionComplete = "    Xem ra ngươi đã chọn được con đường nhân sinh đúng đắn, hãy hướng tới tương lai mà chạy đi!"
edali_0239.g_ItemBonus = {}
edali_0239.g_IsMissionOkFail = 0
edali_0239.g_Custom = { { ["id"] = "已加入门派", ["num"] = 1 }
}
function edali_0239:GetExpByMenpaiIndex(MenPaiIndex)
    local ReturnVal = 0
    if (0 == MenPaiIndex) then
        ReturnVal = 3000
    end
    if (1 == MenPaiIndex) then
        ReturnVal = 2900
    end
    if (2 == MenPaiIndex) then
        ReturnVal = 2600
    end
    if (3 == MenPaiIndex) then
        ReturnVal = 2500
    end
    if (4 == MenPaiIndex) then
        ReturnVal = 2200
    end
    if (5 == MenPaiIndex) then
        ReturnVal = 2000
    end
    if (6 == MenPaiIndex) then
        ReturnVal = 1200
    end
    if (7 == MenPaiIndex) then
        ReturnVal = 1000
    end
    if (8 == MenPaiIndex) then
        ReturnVal = 900
    end
    if (10 == MenPaiIndex) then
        ReturnVal = 800
    end
    return ReturnVal
end
function edali_0239:GetMenpaiName(Menpai)
    local Name = "无门派"
    if (0 == Menpai) then
        Name = "Thiếu Lâm phái"
    elseif (1 == Menpai) then
        Name = "明教"
    elseif (2 == Menpai) then
        Name = "丐帮"
    elseif (3 == Menpai) then
        Name = "Võ Đang phái"
    elseif (4 == Menpai) then
        Name = "Nga My phái"
    elseif (5 == Menpai) then
        Name = "Tinh Túc phái"
    elseif (6 == Menpai) then
        Name = "Thiên Long phái"
    elseif (7 == Menpai) then
        Name = "Thiên Sơn phái"
    elseif (8 == Menpai) then
        Name = "Tiêu Dao phái"
    elseif (10 == Menpai) then
        Name = "曼陀山庄"
    end
    return Name
end
function edali_0239:MenpaiSort()
    local MenpaiArray = {}
    local ZeroCount = 0
    for i = 1, 10 do
        MenpaiArray[i] = 0
        if (0 == MenpaiArray[i]) then
            ZeroCount = ZeroCount + 1
        end
    end
    if (9 == ZeroCount) then
        MenpaiArray[1] = 6
        MenpaiArray[2] = 2
        MenpaiArray[3] = 7
        MenpaiArray[4] = 5
        MenpaiArray[5] = 8
        MenpaiArray[6] = 0
        MenpaiArray[7] = 3
        MenpaiArray[8] = 4
        MenpaiArray[9] = 1
        MenpaiArray[10] = 10
    end
    return MenpaiArray
end

function edali_0239:OnDefaultEvent(selfId, targetId)
    if self:IsMissionHaveDone(selfId, self.g_MissionId) then
        return
    elseif self:IsHaveMission(selfId, self.g_MissionId) then
        self:BeginEvent(self.script_id)
        self:AddText(self.g_MissionName)
        self:AddText(self.g_ContinueInfo)
        self:EndEvent()
        local bDone = self:CheckSubmit(selfId)
        self:DispatchMissionDemandInfo(selfId, targetId, self.script_id, self.g_MissionId, bDone)
    elseif self:CheckAccept(selfId) > 0 then
        local MenpaiArray = self:MenpaiSort()
        self:BeginEvent(self.script_id)
        self:AddText(self.g_MissionName)
        self:AddText(self.g_MissionInfo1)
        self:AddText(self.g_MissionInfo2)
        self:AddText(self.g_MissionInfo3)
        self:AddText(self.g_MissionInfo4)
        self:AddText("#{M_MUBIAO}#r" .. self.g_MissionTarget)
        self:EndEvent()
        self:DispatchMissionDemandInfo(selfId, targetId, self.script_id, self.g_MissionId, 0)
        self:DirectAccept(selfId, MenpaiArray)
    end
end

function edali_0239:DirectAccept(selfId, MenpaiArray)
    if self:IsMissionHaveDone(selfId, self.g_MissionId) then
        return
    end
    local ret = self:AddMission(selfId, self.g_MissionId, self.script_id, 1, 0, 0)
    if not ret then
        self:Msg2Player(selfId, "#YNhật ký nhiệm vụ của ngươi đã đầy", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        return
    end
    self:Msg2Player(selfId, "Tiếp nhận nhiệm vụ:#Y" .. self.g_MissionName, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    local misIndex = self:GetMissionIndexByID(selfId, 719)
    local Menpai = self:GetMenPai(selfId)
    if (Menpai >= 0 and Menpai < 9) or Menpai == 10 then
        self:SetMissionByIndex(selfId, misIndex, 1, 1)
        self:SetMissionByIndex(selfId, misIndex, 0, 1)
    end
end

function edali_0239:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:IsMissionHaveDone(selfId, self.g_MissionId) then
        return
    elseif self:IsHaveMission(selfId, self.g_MissionId) then
        local bDone = self:CheckSubmit(selfId)
        if (1 == bDone) then
            caller:AddNumTextWithTarget(self.script_id,self.g_MissionName, 2, -1)
        else
            caller:AddNumTextWithTarget(self.script_id,self.g_MissionName, 1, -1)
        end
    elseif self:CheckAccept(selfId) > 0 then
        caller:AddNumTextWithTarget(self.script_id,self.g_MissionName, 1, -1)
    end
end

function edali_0239:CheckAccept(selfId)
    if not self:IsMissionHaveDone(selfId, self.g_MissionIdPer) then
        return 0
    end
    return 1
end

function edali_0239:OnAccept(selfId)
    if self:IsMissionHaveDone(selfId, self.g_MissionId) then
        return
    end
    local ret = self:AddMission(selfId, self.g_MissionId, self.script_id, 1, 0, 0)
    if not ret then
        self:Msg2Player(selfId, "#YNhật ký nhiệm vụ của ngươi đã đầy", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        return
    end
    self:Msg2Player(selfId, "Tiếp nhận nhiệm vụ:#Y" .. self.g_MissionName, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    local misIndex = self:GetMissionIndexByID(selfId, 719)
    local Menpai = self:GetMenPai(selfId)
    if (Menpai >= 0 and Menpai < 9) or Menpai == 10 then
        self:SetMissionByIndex(selfId,misIndex,1,1)
        self:SetMissionByIndex(selfId,misIndex,0,1)
    end
end

function edali_0239:OnAbandon(selfId)
    self:DelMission(selfId, self.g_MissionId)
end

function edali_0239:OnContinue(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText(self.g_MissionComplete)
    for i, item in pairs(self.g_ItemBonus) do
        self:AddItemBonus(item["id"], item["num"])
    end
    self:EndEvent()
    self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end

function edali_0239:CheckSubmit(selfId)
    local MenPai = self:GetMenPai(selfId)
    if (MenPai == 9) then
        return 0
    end
    if (MenPai < 0) then
        return 0
    end
    return 1
end

function edali_0239:OnSubmit(selfId, targetId, selectRadioId)
    if not self:IsHaveMission(selfId, self.g_MissionId) then
        return
    end
    if self:CheckSubmit(selfId) <= 0 then
        return
    end
    local nPlayerExp = 1000
    self:AddExp(selfId, nPlayerExp)
    self:DelMission(selfId, self.g_MissionId)
    self:MissionCom(selfId, self.g_MissionId)
end

function edali_0239:OnKillObject(selfId, objdataId, objId)
end

function edali_0239:OnEnterArea(selfId, zoneId)
end

function edali_0239:OnItemChanged(selfId, itemdataId)
end

return edali_0239