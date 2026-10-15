local skynet = require "skynet"
local utils = {}

function utils.my_sqrt(cur, tar)
    return math.sqrt((cur.x - tar.x) * (cur.x - tar.x) + (cur.y - tar.y) * (cur.y - tar.y))
end

function utils.my_angle(cur, tar)
    local sqrt = utils.my_sqrt(cur, tar)
    if sqrt <= 0 then
        return 0
    end
    local acos = (tar.y - cur.y) / sqrt
    acos = acos > 1 and 0 or acos
    acos = acos < -1 and math.pi or acos
    acos = math.acos(acos)
    if tar.x >= cur.x then
        return acos
    else
        return (2 * math.pi - acos)
    end
end

local idir2angle = {
    [0] = 0,
    [5] = 135,
    [9] = 270,
    [14] = 315,
    [18] = 180,
    [23] = 45,
    [27] = 90,
    [32] = 225,
}

function utils.idir2fdir(idir)
	if idir >= 100 then
		return idir
	end
    local angle = idir2angle[idir]
    angle = angle or 90
	local rd = angle / 360 * 2 * math.pi
	return math.pi / 2 - rd
end



function utils.get_node_by_world_id(world_id)
	local node_list = skynet.call(".cluster_agent", "lua", "get_node_list")
	for _, N in pairs(node_list) do
		for _, S in pairs(N.servers) do
			if S.name == "gamed" then
                local cluster = require "skynet.cluster"
                local node_world_id = cluster.call(N.name, ".gamed", "lua", "get_world_id")
                if node_world_id == world_id then
                    return N.name
                end
			end
		end
    end
end

function utils.get_cluster_specific_server_by_server_alias(name)
    local nodes = {}
	local node_list = skynet.call(".cluster_agent", "lua", "get_node_list")
	for _, N in pairs(node_list) do
		for _, S in pairs(N.servers) do
			if S.alias == name then
                table.insert(nodes, N.name)
			end
		end
    end
    return nodes
end

function utils.get_node_name()
    return skynet.call(".cluster_agent", "lua", "get_self_node_name")
end

function utils.remote_world_call(world_id, ...)
    local cluster = require "skynet.cluster"
    local node_name = utils.get_node_by_world_id(world_id)
    return cluster.call(node_name, ...)
end

function utils.get_day_time()
    return os.date("%y-%m-%d %H:%M:%S")
end

function utils.latency_call(f, ...)
    local ts_s = skynet.now()
    local result = { f(...)}
    local ts_e = skynet.now()
    local ts = ts_e - ts_s
    if ts > 100 then
        skynet.logw("warning slow log ts =", ts, "stack =", debug.traceback())
    end
    return table.unpack(result)
end

function utils.random_array(array)
    local sort_array = {}
    for _, a in ipairs(array) do
        table.insert(sort_array, { v = math.random(1, 10000), e = a })
    end
    table.sort(sort_array, function(s1, s2)
        return s1.v < s2.v
    end)
    array = {}
    for _, s in ipairs(sort_array) do
        table.insert(array, s.e)
    end
    return array
end

function utils.log_dec_item_lay_count(logparam, human, item_index, count)
    local collection = "dec_item_lay_count"
    local doc = { logparam = logparam, name = human:get_name(), guid = human:get_guid(), item_index = item_index, count = count, time = os.time(), date_time = utils.get_day_time() }
    skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc})
end

return utils