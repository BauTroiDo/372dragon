local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local murongfu = class("murongfu", script_base)
murongfu.TBL = {
    ["IDX_TimerPrepare"] = 1,
    ["IDX_TimerInterval"] = 2,
    ["IDX_FlagCombat"] = 1,
    ["BossSkill"] = 1002,
    ["PrepareTime"] = 60000,
    ["SkillInterval"] = 60000,
    ["BossBuff"] = 9998
}
murongfu.g_bWangyuyanSpeak = 24
murongfu.g_DuanAndWangFlag = 29
function murongfu:OnDie(selfId, killerId)
    self:LuaFnNpcChat(selfId, 0, "Lẽ nào nghiệp lớn phục quốccủa ta, chung quy chỉ là giấc mộng kê vàng?")
    self:MonsterAI_SetIntParamByIndex(selfId, self.TBL["IDX_TimerPrepare"], 0)
    self:MonsterAI_SetIntParamByIndex(selfId, self.TBL["IDX_TimerInterval"], 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.TBL["IDX_FlagCombat"], 0)
    self:LuaFnSetCopySceneData_Param(self.g_bWangyuyanSpeak, 0)
    self:LuaFnSetCopySceneData_Param(self.g_DuanAndWangFlag, 0)
    self:CallScriptFunction((401040), "ClearMonsterByName", "王语嫣")
    self:CallScriptFunction((401040), "ClearMonsterByName", "段誉")
    self:CallScriptFunction((401040), "ClearMonsterByName", "巴天石")
    self:CallScriptFunction((401040), "ClearMonsterByName", "范骅")
    self:CallScriptFunction((401040), "ClearMonsterByName", "褚万里")
    self:CallScriptFunction((401040), "ClearMonsterByName", "古笃诚")
    self:CallScriptFunction((401040), "ClearMonsterByName", "傅思归")
    self:CallScriptFunction((401040), "ClearMonsterByName", "朱丹臣")
    self:TipAllHuman("Mộ Dung Phục đã bị đánh bại, Tảo Phạt Yến Tử Ổ thành công, xin hãy từ lối ra trở về Thái Hồ.")
    local playerID = killerId
    local objType = self:GetCharacterType(killerId)
    if objType == "pet" then playerID = self:GetPetCreator(killerId) end
    local nLeaderId = self:GetTeamLeader(playerID)
    if nLeaderId < 1 then nLeaderId = playerID end
    local str = ""
    local ran = math.random(3)
    if ran == 1 then
        str = string.format("#W#{_INFOUSR%s}#P cùng #{_BOSS0} đơn đấu, lại ngấm ngầm sai đồng đội ở sau lưng ném gạch, ngáng chân, đánh lén, rắc vôi... không từ thủ đoạn nào, cuối cùng đánh cho #{_BOSS0} đại bại, bỏ chạy thục mạng, một hơi công hạ Yến Tử Ổ.",  self:GetName(nLeaderId))
    elseif ran == 2 then
        str = string.format("#W#{_INFOUSR%s}#P dẫn dắt đồng đội cùng #{_BOSS0} kịch chiến nửa ngày, chợt lĩnh ngộ chân lý võ học, lập tức võ công tăng mạnh, #{_BOSS0} không địch lại, chỉ đành bỏ chạy, Yến Tử Ổ bèn thất thủ.", self:GetName(nLeaderId))
    else
        str = string.format("#W#{_INFOUSR%s}#Pở Yến Tử Ổ điều binh khiển tướng, bày mưu tính kế, sau khi dùng hết ba mươi sáu kế như \"Man Thiên Quá Hải\", \"Ám Độ Trần Thương\", đánh cho #{_BOSS0}chỉ còn nước dùng đến kế thứ ba mươi bảy \"chuồn là thượng sách\" mà thôi.",self:GetName(nLeaderId))
    end
    str = gbk.fromutf8(str)
    self:BroadMsgByChatPipe(nLeaderId, str, 4)
end

function murongfu:OnHeartBeat(selfId, nTick)
    if (self:LuaFnIsCharacterLiving(selfId)) then
        if (1 == self:MonsterAI_GetBoolParamByIndex(selfId, self.TBL["IDX_FlagCombat"])) then
            if self:LuaFnGetCopySceneData_Param(self.g_bWangyuyanSpeak) == 0 then
                if self:GetHp(selfId) * 2 <= self:GetMaxHp(selfId) then
                    self:LuaFnSetCopySceneData_Param(self.g_bWangyuyanSpeak, 1)
                end
            end
        end
    end
end

function murongfu:OnInit(selfId)
    self:MonsterAI_SetIntParamByIndex(selfId, self.TBL["IDX_TimerPrepare"], 0)
    self:MonsterAI_SetIntParamByIndex(selfId, self.TBL["IDX_TimerInterval"], 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.TBL["IDX_FlagCombat"], 0)
end

function murongfu:OnKillCharacter(selfId, targetId) end

function murongfu:OnEnterCombat(selfId, enmeyId)
    if (0 < self.TBL["BossBuff"]) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.TBL["BossBuff"], 0)
    end
    self:LuaFnNpcChat(selfId, 0, "Vô danh tiểu tốt, dám cả gan phá hỏng đại kế phục quốc của ta! Thật là tự tìm đường chết!")
    self:MonsterAI_SetIntParamByIndex(selfId, self.TBL["IDX_TimerPrepare"], self.TBL["PrepareTime"])
    self:MonsterAI_SetIntParamByIndex(selfId, self.TBL["IDX_TimerInterval"], 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.TBL["IDX_FlagCombat"], 1)
    self:CallScriptFunction((200060), "Paopao", "段誉", "燕子坞", "Vương cô nương, thấy nơi này binh mã hung hiểm, chi bằng ta hộ tống nàng rời đi trước thì hơn?")
    self:CallScriptFunction((200060), "Paopao", "王语嫣", "燕子坞", "Biểu ca không đi, thiếp thân cũng sẽ không đi, thiếp thân muốn ở lại giúp biểu ca.")
end

function murongfu:OnLeaveCombat(selfId)
    self:MonsterAI_SetIntParamByIndex(selfId, self.TBL["IDX_TimerPrepare"], 0)
    self:MonsterAI_SetIntParamByIndex(selfId, self.TBL["IDX_TimerInterval"], 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.TBL["IDX_FlagCombat"], 0)
    self:CallScriptFunction((401040), "ClearMonsterByName", "王语嫣")
    self:CallScriptFunction((401040), "ClearMonsterByName", "段誉")
    self:CallScriptFunction((401040), "ClearMonsterByName", "巴天石")
    self:CallScriptFunction((401040), "ClearMonsterByName", "范骅")
    self:CallScriptFunction((401040), "ClearMonsterByName", "褚万里")
    self:CallScriptFunction((401040), "ClearMonsterByName", "古笃诚")
    self:CallScriptFunction((401040), "ClearMonsterByName", "傅思归")
    self:CallScriptFunction((401040), "ClearMonsterByName", "朱丹臣")
    self:CallScriptFunction((401040), "CreateMonster_11")
    self:LuaFnSetCopySceneData_Param(self.g_bWangyuyanSpeak, 0)
    self:LuaFnSetCopySceneData_Param(self.g_DuanAndWangFlag, 0)
end

function murongfu:TipAllHuman(Str)
    local nHumanNum = self:LuaFnGetCopyScene_HumanCount()
    if nHumanNum < 1 then return end
    for i = 1, nHumanNum do
        local PlayerId = self:LuaFnGetCopyScene_HumanObjId(i)
        self:BeginEvent(self.script_id)
        self:AddText(Str)
        self:EndEvent()
        self:DispatchMissionTips(PlayerId)
    end
end

return murongfu
