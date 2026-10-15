local class = require "class"
local team = require "team"
local teamlist = class("teamlist")
teamlist.MAX_TEAMS = 3000
function teamlist:ctor()
    self:clean_up()
end

function teamlist:clean_up()
    self.teams = {}
    self.create_offset = 1
end

function teamlist:init()
    for i = 1, self.MAX_TEAMS do
        self.teams[i] = team.new()
        self.teams[i]:set_team_id(i)
    end
end

function teamlist:get_team(id)
    return self.teams[id]
end

function teamlist:create_team()
    local start = self.create_offset
    local loop = false
    while true do
        local t = self:get_team(self.create_offset)
        assert(t, self.create_offset)
        if t:is_empty() then
            return self.create_offset
        else
            self.create_offset = self.create_offset + 1
        end
        if self.create_offset > self.MAX_TEAMS then
            self.create_offset = 1
            loop = true
        end
        if loop and self.create_offset >= start then
            break
        end
    end
end

function teamlist:destory_team(tid)
    local t = self:get_team(tid)
    if t then
        t:clean_up()
        return true
    end
    return false
end

return teamlist