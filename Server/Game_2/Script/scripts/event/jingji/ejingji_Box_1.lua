local gbk = require "wire_charset"
local ScriptGlobal = require "scripts.ScriptGlobal"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ejingji_Box_1 = class("ejingji_Box_1", script_base)
ejingji_Box_1.script_id = 125022
ejingji_Box_1.g_LimitiBuffCollectionID = 75
ejingji_Box_1.g_LootItem_1 = {
    10124009, 10124010, 10124011, 10124012, 10124013, 10124014, 10124015,
    10124016, 10124017
}
ejingji_Box_1.g_LootItem_2 = {
    10510005, 10510006, 10510008, 10510012, 10510013, 10510017, 10510023,
    10510026, 10510035, 10510036, 10510038, 10510042, 10510043, 10510047,
    10510053, 10510056, 10510065, 10510066, 10510068, 10510072, 10510073,
    10510077, 10510083, 10510086, 10511004, 10511007, 10511012, 10511014,
    10511016, 10511018, 10511025, 10511028, 10511034, 10511037, 10511042,
    10511044, 10511046, 10511048, 10511055, 10511058, 10511064, 10511067,
    10511072, 10511074, 10511076, 10511078, 10511085, 10511088, 10512003,
    10512008, 10512012, 10512015, 10512017, 10512023, 10512026, 10512033,
    10512038, 10512042, 10512045, 10512047, 10512053, 10512056, 10512063,
    10512068, 10512072, 10512075, 10512077, 10512083, 10512086, 10513004,
    10513008, 10513014, 10513018, 10513022, 10513024, 10513028, 10513034,
    10513038, 10513044, 10513048, 10513052, 10513054, 10513058, 10513064,
    10513068, 10513074, 10513078, 10513082, 10513084, 10513088, 10514003,
    10514007, 10514015, 10514017, 10514022, 10514025, 10514028, 10514033,
    10514037, 10514045, 10514047, 10514052, 10514055, 10514058, 10514063,
    10514067, 10514075, 10514077, 10514082, 10514085, 10514088, 10515004,
    10515006, 10515014, 10515016, 10515022, 10515025, 10515027, 10515034,
    10515036, 10515044, 10515046, 10515052, 10515055, 10515057, 10515064,
    10515066, 10515074, 10515076, 10515082, 10515085, 10515087, 10520002,
    10520005, 10520006, 10520013, 10520018, 10520024, 10520027, 10520028,
    10520032, 10520035, 10520036, 10520043, 10520048, 10520054, 10520057,
    10520058, 10520062, 10520065, 10520066, 10520073, 10520078, 10520084,
    10520087, 10520088, 10521002, 10521004, 10521007, 10521014, 10521017,
    10521025, 10521027, 10521028, 10521032, 10521034, 10521037, 10521044,
    10521047, 10521055, 10521057, 10521058, 10521062, 10521064, 10521067,
    10521074, 10521077, 10521085, 10521087, 10521088, 10522002, 10522003,
    10522007, 10522015, 10522018, 10522023, 10522026, 10522032, 10522033,
    10522037, 10522045, 10522048, 10522053, 10522056, 10522062, 10522063,
    10522067, 10522075, 10522078, 10522083, 10522086, 10523005, 10523006,
    10523013, 10523017, 10523024, 10523026, 10523035, 10523036, 10523043,
    10523047, 10523054, 10523056, 10523065, 10523066, 10523073, 10523077,
    10523084, 10523086, 10552005, 10552008, 10552015, 10552016, 10552024,
    10552027, 10552035, 10552038, 10552045, 10552046, 10552054, 10552057,
    10552065, 10552068, 10552075, 10552076, 10552084, 10552087, 10553007,
    10553008, 10553016, 10553018, 10553027, 10553037, 10553038, 10553046,
    10553048, 10553057, 10553067, 10553068, 10553076, 10553078, 10553087,
    10500009, 10500019, 10501009, 10502009, 10503009, 10503019, 10504009,
    10504019, 10505009, 10510009, 10510019, 10510029, 10510039, 10510049,
    10510059, 10510069, 10510079, 10510089, 10511009, 10511019, 10511029,
    10511039, 10511049, 10511059, 10511069, 10511079, 10511089, 10512009,
    10512019, 10512029, 10512039, 10512049, 10512059, 10512069, 10512079,
    10512089, 10513009, 10513019, 10513029, 10513039, 10513049, 10513059,
    10513069, 10513079, 10513089, 10514009, 10514019, 10514029, 10514039,
    10514049, 10514059, 10514069, 10514079, 10514089, 10515009, 10515019,
    10515029, 10515039, 10515049, 10515059, 10515069, 10515079, 10515089,
    10520009, 10520019, 10520029, 10520039, 10520049, 10520059, 10520069,
    10520079, 10520089, 10521009, 10521019, 10521029, 10521039, 10521049,
    10521059, 10521069, 10521079, 10521089, 10522009, 10522019, 10522029,
    10522039, 10522049, 10522059, 10522069, 10522079, 10522089, 10523009,
    10523019, 10523029, 10523039, 10523049, 10523059, 10523069, 10523079,
    10523089, 10552009, 10552019, 10552029, 10552039, 10552049, 10552059,
    10552069, 10552079, 10552089, 10553009, 10553019, 10553029, 10553039,
    10553049, 10553059, 10553069, 10553079, 10553089
}
ejingji_Box_1.g_LootItem_3 = {10421018}
ejingji_Box_1.g_BuffId_1 = 54
ejingji_Box_1.g_BuffId_2 = 8046
ejingji_Box_1.g_BuffId_3 = 8055
ejingji_Box_1.g_BuffId_4 = 8056
function ejingji_Box_1:OnDefaultEvent(selfId, targetId) end
function ejingji_Box_1:OnActivateConditionCheck(selfId, activatorId)
    local bOk = self:IsCanOpenBox(activatorId)
    if bOk == 0 then
        self:BeginEvent(self.script_id)
        self:AddText("Ngươi hiện tại không thể mở rương báu này.")
        self:EndEvent()
        self:DispatchMissionTips(activatorId, selfId)
    end

    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, activatorId, self.g_BuffId_3, 0)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, activatorId, self.g_BuffId_4, 0)
    if self:GetUnitCampID(activatorId) < 500 then
        self:BeginEvent(self.script_id)
        self:AddText("Trận doanh Chiến đấu của ngươi hiện tại không chính xác, không thể mở bảo tương.")
        self:EndEvent()
        self:DispatchMissionTips(activatorId, selfId)
        bOk = 0
    end
    if bOk == 1 then
        local str = "#G[Phong Thiền Đài]#W" .. self:GetName(activatorId) .. "#Pđang cố gắng mở bảo tương!"
        self:CallScriptFunction((200060), "Duibai", "", "", str)
    end
    return bOk
end

function ejingji_Box_1:IsCanOpenBox(activatorId)
    if self:LuaFnHaveImpactOfSpecificDataIndex(activatorId, self.g_BuffId_2) then return 0 end
    return not self:LuaFnHaveImpactInSpecificCollection(activatorId, self.g_LimitiBuffCollectionID)
end

function ejingji_Box_1:OnActivateDeplete(selfId, activatorId) return 1 end

function ejingji_Box_1:OnActivateEffectOnce(selfId, activatorId)
    local x, z = self:GetWorldPos(selfId)
    local nCount = self:GetMonsterCount()
    local bDelOk = 0
    for i = 1, nCount do
        local nObjId = self:GetMonsterObjID(i)
        if self:GetName(nObjId) == "黄色宝箱" then
            bDelOk = 1
            self:LuaFnDeleteMonster(nObjId)
        end
    end
    local nItemCount = 2
    local nItemId_1
    local nItemId_2
    local nItemId_3
    if math.random <= 125 then
        nItemCount = 3
        nItemId_1 = self.g_LootItem_1[math.random(#(self.g_LootItem_1))]
    end
    nItemId_2 = self.g_LootItem_2[math.random(#(self.g_LootItem_2))]
    nItemId_3 = self.g_LootItem_3[1]
    if bDelOk == 1 then
        local nBoxId = self:DropBoxEnterScene(x, z)
        if nBoxId > -1 then
            if nItemCount == 3 then
                self:AddItemToBox(nBoxId, ScriptGlobal.QUALITY_CREATE_BY_BOSS, 3, nItemId_1, nItemId_2, nItemId_3)
            elseif nItemCount == 2 then
                self:AddItemToBox(nBoxId, ScriptGlobal.QUALITY_CREATE_BY_BOSS, 2, nItemId_2, nItemId_3)
            end
            self:SetItemBoxOwner(nBoxId, self:LuaFnGetGUID(activatorId))
            local nCurHour = self:GetHour()
            if nCurHour == 0 or nCurHour == 2 or nCurHour == 4 or nCurHour == 6 or
                nCurHour == 8 or nCurHour == 10 or nCurHour == 12 or nCurHour ==
                14 or nCurHour == 16 or nCurHour == 18 or nCurHour == 20 or
                nCurHour == 22 then
                nCurHour = nCurHour + 2
            else
                nCurHour = nCurHour + 1
            end
            if nCurHour >= 2 and nCurHour < 10 then nCurHour = 10 end
            if nCurHour == 24 then nCurHour = 0 end
            local name = self:GetName(activatorId)
            local str = string.format( "#YVu Cửu Liên#Phét lên: Anh hùng thiên hạ! #{_INFOUSR%s}#P hùng mạnh đã mở ra rương báu của Minh chủ Võ Lâm! Kính mời mọi người #Y%s giờ 45 phút#P trở lại #GPhong Thiện Đài#P tranh đoạt ngôi vị Minh chủ Võ Lâm!", name, nCurHour)
            str = gbk.fromutf8(str)
            self:BroadMsgByChatPipe(0, str, 4)
        end
    end
    self:LuaFnAuditPlayerBehavior(activatorId, "Mở rương báu Minh chủ.")
    self:LuaFnSendSpecificImpactToUnit(activatorId, activatorId, activatorId, self.g_BuffId_1, 100)
    self:LuaFnSendSpecificImpactToUnit(activatorId, activatorId, activatorId, self.g_BuffId_2, 100)
    self:DealExp(activatorId)
    return 1
end

function ejingji_Box_1:OnActivateEffectEachTick(selfId, activatorId) return 1 end
function ejingji_Box_1:OnActivateActionStart(selfId, activatorId) return 1 end
function ejingji_Box_1:OnActivateCancel(selfId, activatorId)
    local str = "#G[Phong Thiền Đài]#W" .. self:GetName(activatorId) .. "#P Mở bảo rương của nỗ lực uổng phí!"
    self:CallScriptFunction((200060), "Duibai", "", "", str)
    return 0
end

function ejingji_Box_1:OnActivateInterrupt(selfId, activatorId) return 0 end
function ejingji_Box_1:OnActivateInterrupt(selfId, activatorId) end
function ejingji_Box_1:DealExp(activatorId)
    local nPlayerCamp = self:GetUnitCampID(activatorId)
    local nHumanIdList = {}
    for i = 1, 10 do nHumanIdList[i] = -1 end
    local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
    local j = 1
    for i = 1, nHumanCount do
        local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
        if self:GetUnitCampID(nHumanId) == nPlayerCamp then
            nHumanIdList[j] = nHumanId
            j = j + 1
        end
    end
    j = j - 1
    for i = 1, j do
        if nHumanIdList[i] ~= -1 then
            self:AddExp(nHumanIdList[i], math.floor(100000 / j))
        end
    end
    for i = 1, nHumanCount do
        local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
        if self:GetUnitCampID(nHumanId) ~= nPlayerCamp then
            self:AddExp(nHumanId, math.floor(100000 / (nHumanCount - j)))
        end
    end
end

return ejingji_Box_1
