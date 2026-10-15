local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local gp_guild_collect = class("gp_guild_collect", script_base)
gp_guild_collect.g_NumOdds = {
    {["num"] = 1, ["odd"] = 85},
    {["num"] = 2, ["odd"] = 10},
    {["num"] = 3, ["odd"] = 5}
}

gp_guild_collect.g_weekDay = 0
gp_guild_collect.g_StartTime = 1900
gp_guild_collect.g_EndTime = 2000
gp_guild_collect.g_GPInfo = {}

gp_guild_collect.g_GPInfo[791] = {["name"] = "Sỏi đá", ["misId"] = 1140, ["itemId"] = 40004464}
gp_guild_collect.g_GPInfo[792] = {["name"] = "Lông Nhạn", ["misId"] = 1141, ["itemId"] = 40004462}
gp_guild_collect.g_GPInfo[793] = {["name"] = "Thất Diệp Liên", ["misId"] = 1142, ["itemId"] = 40004463}

function gp_guild_collect:OnCreate(growPointType, x, y)
    local item_id = self.g_GPInfo[growPointType]["itemId"]
    local ItemBoxId = self:ItemBoxEnterScene(x, y, growPointType, define.QUALITY_MUST_BE_CHANGE, 1, item_id)
    local rdm = math.random(100)
    local num = 0
    if rdm < self.g_NumOdds[1]["odd"] then
        num = self.g_NumOdds[1]["num"]
    elseif rdm < self.g_NumOdds[1]["odd"] + self.g_NumOdds[2]["odd"] then
        num = self.g_NumOdds[2]["num"]
    else
        num = self.g_NumOdds[3]["num"]
    end
    while num > 1 do
        self:AddItemToBox(ItemBoxId, define.QUALITY_MUST_BE_CHANGE, 1, item_id)
        num = num - 1
    end
end

function gp_guild_collect:OnOpen(selfId, targetId)
    local growPointType = self:LuaFnGetItemBoxGrowPointType(targetId)
    local misId = self.g_GPInfo[growPointType]["misId"]
    if not self:IsHaveMission(selfId, misId) then
        local msg = string.format("#{BHSJ_081014_15}%s#{BHSJ_081014_16}", self.g_GPInfo[growPointType]["name"])
        self:Tips(selfId, msg)
        return -29
    end
    local misIndex = self:GetMissionIndexByID(selfId, misId)
    if self:GetMissionParam(selfId, misIndex, 2) ~= self:GetWeekTime() then
        self:Tips(selfId, "#{BHSJ_081014_18}")
        return -29
    end
    local time = self:GetHour() * 100 + self:GetMinute()
    if self:GetTodayWeek() ~= self.g_weekDay then
        self:Tips(selfId, "#{BHSJ_081014_11}")
        return -29
    elseif time < self.g_StartTime then
        self:Tips(selfId, "#{BHSJ_081014_11}")
        return -29
    elseif time > self.g_EndTime then
        self:Tips(selfId, "#{BHSJ_081014_18}")
        return -29
    end
    if self:GetMissionParam(selfId, misIndex, 0) == 1 then
        self:Tips(selfId, "#{BHSJ_081014_17}")
        return -29
    end
    return 0
end

function gp_guild_collect:OnRecycle(selfId, targetId)
    local growPointType = self:LuaFnGetItemBoxGrowPointType(targetId)
    local misId = self.g_GPInfo[growPointType]["misId"]
    local count = self:LuaFnGetItemCount(selfId, self.g_GPInfo[growPointType]["itemId"])
    if count > 0 then
        local misIndex = self:GetMissionIndexByID(selfId, misId)
        self:SetMissionByIndex(selfId, misIndex, 0, 1)
        self:SetMissionByIndex(selfId, misIndex, 1, count)
        self:Tips(selfId, "#{YD_20080421_180}")
    end
    return 1
end

function gp_guild_collect:OnProcOver(selfId, targetId)
    return 0
end

function gp_guild_collect:OnTickCreateFinish(growPointType, tickCount)
end

function gp_guild_collect:Tips(selfId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return gp_guild_collect
