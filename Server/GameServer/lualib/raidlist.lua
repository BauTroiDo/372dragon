local class = require "class"
local raid = require "raid"
local raidlist = class("raidlist")
raidlist.MAX_RAIDS = 3000
function raidlist:ctor()
    self:clean_up()
end

function raidlist:clean_up()
    self.raids = {}
    self.create_offset = 1
end

function raidlist:init()
    for i = 1, self.MAX_RAIDS do
        self.raids[i] = raid.new()
        self.raids[i]:set_raid_id(i)
    end
end

function raidlist:get_raid(id)
    return self.raids[id]
end

function raidlist:create_raid()
    local start = self.create_offset
    local loop = false
    while true do
        local t = self:get_raid(self.create_offset)
        assert(t, self.create_offset)
        if t:is_empty() then
            return self.create_offset
        else
            self.create_offset = self.create_offset + 1
        end
        if self.create_offset > self.MAX_RAIDS then
            self.create_offset = 1
            loop = true
        end
        if loop and self.create_offset >= start then
            break
        end
    end
end

function raidlist:destory_raid(tid)
    local t = self:get_raid(tid)
    if t then
        t:clean_up()
        return true
    end
    return false
end

return raidlist