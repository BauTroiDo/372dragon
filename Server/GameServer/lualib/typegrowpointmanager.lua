local skynet = require "skynet"
local define = require "define"
local class = require "class"
local typegrowpointmanager = class("typegrowpointmanager")
function typegrowpointmanager:ctor()
    self.data = {}
    self.add_offset = 1
    self.type_offset = 1
    self.current_count = 0
    self.max_appera_count = 0
    self.type_count = 0
    self.interval_per_seed = 0
    self.enable = false
end

function typegrowpointmanager:add_data(ref_data)
    self.data[self.add_offset] = ref_data
    self.add_offset = self.add_offset + 1
end

function typegrowpointmanager:create_grow_point_pos()
    if self.current_count >= self.max_appera_count then
        return false
    end
    for i = 1, self.max_appera_count do
        if not self.data[i].used then
            self.data[i].used = true
            self.type_offset = self.type_offset + 1
            if self.type_offset == self.type_count then
                self.type_offset = 1
            end
            self:inc_current_count()
            return true, self.data[i].x, self.data[i].y
        else
            self.type_offset = self.type_offset + 1
            if self.type_offset == self.type_count then
                self.type_offset = 1
            end
        end
    end
    return false
end

function typegrowpointmanager:release_grow_point_pos(x, y)
    for i = 1, self.type_count do
        local data = self.data[i]
        if math.abs(data.x - x) < 0.01 and math.abs(data.y - y) < 0.01 then
            data.used = false
            self:dec_current_count()
            return true
        end
    end
    return false
end

function typegrowpointmanager:set_current_count(count)
    self.current_count = count
end

function typegrowpointmanager:set_count(count)
    self.type_count = count
end

function typegrowpointmanager:inc_count()
    self.type_count = self.type_count + 1
end

function typegrowpointmanager:inc_current_count()
    self.current_count = self.current_count +  1
end

function typegrowpointmanager:dec_current_count()
    self.current_count = self.current_count - 1
end

function typegrowpointmanager:get_grow_point_type()
    return self.grow_point_type
end

function typegrowpointmanager:set_grow_point_type(type)
    self.grow_point_type = type
end

function typegrowpointmanager:set_interval_time(interval)
    self.interval_per_seed = interval
end

function typegrowpointmanager:set_max_appera_count(count)
    self.max_appera_count = count
end

function typegrowpointmanager:do_ticks()
    if not self.enable then
        return false
    end
    local utime = skynet.time() * 1000
    if self.start_count then
        if self.current_count == self.max_appera_count then
            self.start_count = false
            self.current_elapse = 0
        else
            self.current_elapse = self.current_elapse + utime - self.last_update_time
        end
    else
        if self.current_count < self.max_appera_count then
            self.start_count = true
            self.last_update_time = utime
            self.current_elapse = 0
        end
        return false
    end
    if self.current_elapse > self.interval_per_seed then
        self.current_elapse = 0
        return true
    end
    return false
end

function typegrowpointmanager:rand_sort()
    if self.type_count > 1 then
        table.sort(self.data, function(d1, d2)
            return d1.rand > d2.rand
        end)
    end
end


return typegrowpointmanager
