local class = require "class"
local action_params = class("action_params")
action_params.type = {
    skill = 0,
    script = 1,
    active_monster = 2,
}

function action_params:ctor()
    self:reset()
end

function action_params:reset()
    self.continuance = 0
    self.interval = 0
    self.interval_elapsed = 0
    self.actor = nil
    self.callback = nil
	self.percentage_of_distraction = 0
	self.chance_of_interference = 0
	self.percentage_of_disturbance_time_floats = 0
	self.charge_time = 0
    self.action_type = self.type.skill
end

function action_params:on_damages()
	if not self.continuance or self.continuance <= 0
	or not self.charge_time or self.charge_time <= 0 then
		return
	elseif math.random(100) > self.chance_of_interference then
		return
	end
	local percentage_of_disturbance_time_floats = self.percentage_of_disturbance_time_floats / 100
	if math.random(1,2) == 2 then
		percentage_of_disturbance_time_floats = -1 * percentage_of_disturbance_time_floats
	end
	if self.percentage_of_distraction > 0 then
		local charge_time = self.charge_time * self.percentage_of_distraction
		local charge_time_2 = charge_time * percentage_of_disturbance_time_floats
		charge_time = math.ceil(charge_time + charge_time_2)
		local continuance = self.continuance + charge_time
		if continuance > self.charge_time then
			continuance = self.charge_time
			charge_time = continuance - self.continuance
		end
		self.continuance = continuance
		return charge_time
	end
end

function action_params:set_charge_time(value)
    self.charge_time = value
end

function action_params:set_percentage_of_distraction(value)
    self.percentage_of_distraction = value
end

function action_params:set_chance_of_interference(value)
    self.chance_of_interference = value
end

function action_params:set_percentage_of_disturbance_time_floats(value)
    self.percentage_of_disturbance_time_floats = value
end


function action_params:get_action_type()
    return self.action_type
end

function action_params:set_action_type(action_type)
    self.action_type = action_type
end

function action_params:get_continuance()
    return self.continuance
end

function action_params:get_interval()
    return self.interval
end

function action_params:get_interval_elapsed()
    return self.interval_elapsed
end

function action_params:get_actor()
    return self.actor
end

function action_params:get_callback()
    return self.callback
end

function action_params:set_continuance(continuance)
    self.continuance = math.ceil(continuance)
end

function action_params:set_interval(interval)
    self.interval = interval
end

function action_params:set_interval_elapsed(interval_elapsed)
    self.interval_elapsed = interval_elapsed
end

function action_params:set_actor(actor)
    self.actor = actor
end

function action_params:set_callback(callback)
    self.callback = callback
end

return action_params