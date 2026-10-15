local skynet = require "skynet"
local class = require "class"
local define = require "define"
local attacker_or_pk_delaction_list = class("attacker_or_pk_delaction_list")

function attacker_or_pk_delaction_list:ctor(list)
    self:set_mt()
    list = list or {}
    self.list = {}
    for guid, time in pairs(list) do
        self.list[tonumber(guid)] = time
    end
    self.dirty = true
end

function attacker_or_pk_delaction_list:set_mt()
    local mt = getmetatable(self)
    mt.__eq = function(g1)
        return g1.dirty
    end
    setmetatable(self, mt)
end

function attacker_or_pk_delaction_list:add(guid)
    self.dirty = true
    self.list[guid] = 600000
end

function attacker_or_pk_delaction_list:on_heart_beat(delta_time)
    local need_removed = {}
    for guid, time in pairs(self.list) do
        time = time - delta_time
        if time <= 0  then
            table.insert(need_removed, guid)
        end
        self.list[guid] = time
    end
    for _, guid in ipairs(need_removed) do
        self.list[guid] = nil
    end
    if not self.dirty then
        self.dirty = #need_removed > 0
    end
end

function attacker_or_pk_delaction_list:is_dirty()
    return self.dirty
end

function attacker_or_pk_delaction_list:clear_dirty()
    self.dirty = false
end

function attacker_or_pk_delaction_list:get_save_data()
    local list = {}
    for guid, time in pairs(self.list) do
        list[tostring(guid)] = time
    end
    return list
end

function attacker_or_pk_delaction_list:is_exist(guid)
    return self.list[guid] ~= nil
end

function attacker_or_pk_delaction_list:get_list()
    return self.list
end

function attacker_or_pk_delaction_list:get_exist_count()
    local count = 0
    for guid in pairs(self.list) do
        if guid ~= define.INVALID_GUID then
            count = count + 1
        end
    end
    return count
end

return attacker_or_pk_delaction_list