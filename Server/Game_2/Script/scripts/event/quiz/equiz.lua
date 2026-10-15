local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local equiz = class("equiz", script_base)
equiz.script_id = 311100
equiz.g_Position_X = 147.4986
equiz.g_Position_Z = 146.2925
equiz.g_SceneID = 2
equiz.g_AccomplishNPC_Name = "钱龙"
equiz.g_MissionName = "Ta hỏi ngươi đáp"
equiz.g_Quiz_Hortation = {}
equiz.g_Quiz_Newbie_Hortation = {}
equiz.g_Quiz_Hortation[1] = 36
equiz.g_Quiz_Hortation[2] = 72
equiz.g_Quiz_Hortation[3] = 109
equiz.g_Quiz_Hortation[4] = 145
equiz.g_Quiz_Hortation[5] = 181
equiz.g_Quiz_Hortation[6] = 218
equiz.g_Quiz_Hortation[7] = 254
equiz.g_Quiz_Hortation[8] = 290
equiz.g_Quiz_Hortation[9] = 330
equiz.g_Quiz_Hortation[10] = 365
equiz.g_Quiz_Newbie_Hortation[1] = 4
equiz.g_Quiz_Newbie_Hortation[2] = 7
equiz.g_Quiz_Newbie_Hortation[3] = 10
equiz.g_Quiz_Newbie_Hortation[4] = 14
equiz.g_Quiz_Newbie_Hortation[5] = 18
equiz.g_Quiz_Newbie_Hortation[6] = 21
equiz.g_Quiz_Newbie_Hortation[7] = 25
equiz.g_Quiz_Newbie_Hortation[8] = 29
equiz.g_Quiz_Newbie_Hortation[9] = 33
equiz.g_Quiz_Newbie_Hortation[10] = 36
equiz.g_AccomplishCircumstance = 1
function equiz:OnDefaultEvent(selfId, targetId)
    self:BeginUICommand()
    self:UICommand_AddInt(1)
    self:UICommand_AddStr("#gFF0FA0Trí Tuệ Đoạt Quan")
    self:UICommand_AddStr("#{function_help_084}")
    self:UICommand_AddInt(targetId)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 2)
    self:SetMissionData(selfId, ScriptGlobal.MD_QUIZ_TARGET, targetId)
    return

end

function equiz:OnEnumerate(caller, selfId, targetId, arg, index)

end

function equiz:AskQuestion(selfId, Question_Sequence)
    if Question_Sequence == 1 and self:OnAccept_Quiz(selfId) <= 0 then return end
    if Question_Sequence > 5 then
        self:BeginUICommand()
        self:UICommand_AddInt(4)
        self:UICommand_AddStr(
            "Chúc mừng bằng hữu đã trả lời đúng toàn bộ câu hỏi!#rLần sau đừng quên tiếp tục tham gia ^_^")

        self:EndUICommand()
        self:DispatchUICommand(selfId, 2)
        if (self:IsHaveMission(selfId, 1419)) then
            local misIndex = self:GetMissionIndexByID(selfId, 1419)
            self:BeginEvent(self.script_id)
            local strText = "Trả lời đúng năm câu hỏi, nhiệm vụ hoàn thành."
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            self:SetMissionByIndex(selfId, misIndex, 0, 1)
            self:SetMissionByIndex(selfId, misIndex, 1, 1)
            local targetId = self:GetMissionData(selfId, ScriptGlobal.MD_QUIZ_TARGET)
            self:CallScriptFunction(002031, "OnDefaultEvent", selfId, targetId)
            return
        end
        return
    end
    local wenti = self:GetRandomQuestionsIndex(1)
    local con, opt0, opt1, opt2, opt3, opt4, opt5, key0, key1, key2, key3, key4, key5, sztype = self:GetQuestionsRecord(wenti)
    if con == "" then
        self:Msg2Player(selfId, "Không tìm thấy câu hỏi", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    end
    local key_position = {}
    self.g_rand = math.random(0, 2)
    if self.g_rand == 0 then
        key_position[0] = 1
        key_position[1] = 2
        key_position[2] = 0
        key_position[3] = -1
        key_position[4] = -1
        key_position[5] = -1
    elseif self.g_rand == 1 then
        key_position[0] = 2
        key_position[1] = 0
        key_position[2] = 1
        key_position[3] = -1
        key_position[4] = -1
        key_position[5] = -1
    else
        key_position[0] = 0
        key_position[1] = 1
        key_position[2] = 2
        key_position[3] = -1
        key_position[4] = -1
        key_position[5] = -1
    end
    local asktime = self:LuaFnGetCurrentTime()
    self:SetMissionData(selfId, ScriptGlobal.MD_QUIZ_ASKTIME, asktime)
    self:BeginUICommand()
    self:UICommand_AddInt(2)
    self:UICommand_AddInt(Question_Sequence)
    self:UICommand_AddInt(wenti)
    self:UICommand_AddStr(con)
    self:UICommand_AddStr(opt0)
    self:UICommand_AddStr(opt1)
    self:UICommand_AddStr(opt2)
    self:UICommand_AddStr(opt3)
    self:UICommand_AddStr(opt4)
    self:UICommand_AddStr(opt5)
    self:UICommand_AddInt(key_position[0])
    self:UICommand_AddInt(key_position[1])
    self:UICommand_AddInt(key_position[2])
    self:UICommand_AddInt(key_position[3])
    self:UICommand_AddInt(key_position[4])
    self:UICommand_AddInt(key_position[5])
    self:UICommand_AddInt(-1)
    self:UICommand_AddStr(sztype)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 2)
    return
end

function equiz:AnswerQuestion(selfId, Question, Answer1, Question_Sequence)
    local Answer_List = {}
    local Player_Level = self:GetLevel(selfId)
    local con, opt0, opt1, opt2, opt3, opt4, opt5, key0, key1, key2, key3, key4, key5 = self:GetQuestionsRecord(Question)
    Answer_List[0] = key0
    Answer_List[1] = key1
    Answer_List[2] = key2
    Answer_List[3] = key3
    Answer_List[4] = key4
    Answer_List[5] = key5
    if con == "" then
        self:Msg2Player(selfId, "Không tìm thấy câu hỏi", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    end
    local asktime = self:GetMissionData(selfId, ScriptGlobal.MD_QUIZ_ASKTIME)
    if Answer_List[Answer1 - 1] == 1 and self:LuaFnGetCurrentTime() - asktime <305 then
        if (not self:IsHaveMission(selfId, 1419)) then
            if Question_Sequence > 0 and Question_Sequence < 11 then
                if Player_Level > 9 then
                    self.g_Money = self.g_Quiz_Hortation[Question_Sequence]
                else
                    self.g_Money = self.g_Quiz_Newbie_Hortation[Question_Sequence]
                end
            else
                self.g_Money = 1
            end
        end
        self:AskQuestion(selfId, Question_Sequence + 1)
    else
        self:BeginUICommand()
        self:UICommand_AddInt(3)
        self:UICommand_AddStr(
            "Thật đáng tiếc, câu trả lời của ngươi là sai rồi. Đừng nản lòng, lần sau cố gắng hơn nhé.")
        self:EndUICommand()
        self:DispatchUICommand(selfId, 2)
    end
end

function equiz:OnAccept_Quiz(selfId)
    if (self:IsHaveMission(selfId, 1419)) then return 1 end
    local Max_Time_EveryDay = 5
    local iDayCount = self:GetMissionData(selfId, ScriptGlobal.MD_QUIZ_DAYCOUNT)
    local iTime = iDayCount % 100000
    local iDayTime = iTime
    local iDayHuan = math.floor(iDayCount / 100000)
    local CurDaytime = self:GetDayTime()
    if CurDaytime == iDayTime then
        if iDayHuan >= Max_Time_EveryDay then
            self:BeginEvent(self.script_id)
            local strText = string.format(   "Trí Lực Vấn Đáp một ngày Tối đa làm %d lần, ngươi đã làm %d lần.", Max_Time_EveryDay, iDayHuan)
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            return -1
        end
        iDayHuan = iDayHuan + 1
    else
        iDayTime = CurDaytime
        iDayHuan = 1
    end
    iDayCount = iDayHuan * 100000 + CurDaytime
    self:SetMissionData(selfId, ScriptGlobal.MD_QUIZ_DAYCOUNT, iDayCount)
    return 1
end

function equiz:OnOverTime(selfId)
    self:BeginUICommand()
    self:UICommand_AddInt(3)
    self:UICommand_AddStr(
        "Thật đáng tiếc, câu trả lời của ngươi là sai rồi. Đừng nản lòng, lần sau cố gắng hơn nhé.")
    self:EndUICommand()
    self:DispatchUICommand(selfId, 2)
end

return equiz
