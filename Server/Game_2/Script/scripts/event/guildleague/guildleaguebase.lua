local class = require "class"
local define = require "define"
local script_base = require "script_base"
local guildleaguebase = class("guildleaguebase", script_base)
guildleaguebase.script_id = 650000
function guildleaguebase:OnDefaultEvent(selfId, targetId, arg, index)
    local num = index
    if num == 5 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1206)
    elseif num == 6 then
        -- if self:GetGuildPos(selfId) ~= define.GUILD_POSITION_CHIEFTAIN then
            -- self:BeginEvent(self.script_id)
            -- self:AddText("#{TM_20080311_01}")
            -- self:EndEvent()
            -- self:DispatchEventList(selfId, targetId)
        -- elseif self:LuaFnGetHumanGuildLeagueID(selfId) >= 0 then
            -- self:BeginEvent(self.script_id)
            -- self:AddText("#{TM_20080311_02}")
            -- self:EndEvent()
            -- self:DispatchEventList(selfId, targetId)
        -- else
            -- self:BeginUICommand()
            -- self:UICommand_AddInt(targetId)
            -- self:EndUICommand()
            -- self:DispatchUICommand(selfId, 1207)
        -- end
    elseif num == 3 then
        if self:LuaFnGetHumanGuildLeagueID(selfId) >= 0 then
            self:BeginUICommand()
            self:UICommand_AddInt(targetId)
            self:EndUICommand()
            self:DispatchUICommand(selfId, 1208)
        else
            self:BeginEvent(self.script_id)
            self:AddText("#{TM_20080311_13}")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        end
    elseif num == 4 then
        self:BeginEvent(self.script_id)
        self:AddText("#{TM_20080320_02}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif num == 7 then
        local guild_id = self:GetHumanGuildID(selfId)
        local guid = self:LuaFnGetGUID(selfId)
        local is_chief = self:GetGuildPos(selfId) == define.GUILD_POSITION_CHIEFTAIN
        if is_chief then
            local skynet = require "skynet"
            skynet.call(".Guildmanager", "lua", "guild_league_quit", guid, guild_id)

            self:BeginEvent(self.script_id)
            self:AddText("Rời đồng minh thành công")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        else
            self:BeginEvent(self.script_id)
            self:AddText("Chỉ bang chủ mới rời đồng minh được")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        end
    end
end

function guildleaguebase:OnEnumerate(caller, selfId, targetId, arg, index)
    caller:AddNumTextWithTarget(self.script_id, "Xem danh sách đồng minh.", 6, 5)
    --caller:AddNumTextWithTarget(self.script_id, "创建同盟", 6, 6)
    caller:AddNumTextWithTarget(self.script_id, "Rời khỏi Liên minh", 6, 7)
    caller:AddNumTextWithTarget(self.script_id, "Xem thông tin chi tiết của liên minh này.", 6, 3)
    caller:AddNumTextWithTarget(self.script_id, "Giới thiệu Đồng minh", 11, 4)
end

return guildleaguebase
