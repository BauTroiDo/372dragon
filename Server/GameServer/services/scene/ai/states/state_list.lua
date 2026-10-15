local class = require "class"
local state_list = class("state_list")

function state_list:getinstance()
    if state_list.instance == nil then
        state_list.instance = state_list.new()
    end
    return state_list.instance
end

function state_list:ctor()
    self.states = {}
    local states = {"dead", "idle", "sit", "stall", "team_follow", "terror", "combat", "approach", "go_home", "patrol", "by_bus"}
    for _, s in ipairs(states) do
        local p = string.format("scene.ai.states.%s", s)
        local state = require(p).new()
        self.states[s] = state
    end
end

function state_list:get_state(s)
    --print("get_state name =", s)
    return self.states[s]
end

return state_list