local cluster = require "skynet.cluster"
local class = require "class"
local human = require "scene.obj.human"
local span_human = class("span_human", human)

function span_human:ctor(...)
    local player_data = ...
    self.node_name = player_data.node_name
end

function span_human:get_node_name()
    return self.node_name
end

function span_human:get_relation_info()
    return cluster.call(self:get_node_name(), ".clusteragentproxy", self:get_guid(), "call_agent", "get_relation_list")
end

function span_human:set_relation_info(realtion_list)
    cluster.send(self:get_node_name(), ".clusteragentproxy", self:get_guid(), "send_agent", "set_realtion_list", realtion_list)
end

function span_human:relation_on_be_human_kill()

end

function span_human:inc_friend_point()

end

function span_human:check_right_limit_exchange()
    return cluster.call(self:get_node_name(), ".clusteragentproxy", self:get_guid(), "call_agent", "check_right_limit_exchange")
end

return span_human