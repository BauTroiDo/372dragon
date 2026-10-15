local skynet = require "skynet"
local cluster = require "skynet.cluster"
local define = require "define"

return function(router)
    router:post("/worlds", function(c)
        local worlds = skynet.call(".admin_db", "lua", "findAll", {collection = "game_world",query = nil, selector = nil, skip = 0 })
        c:send_json({
            code = "OK",
            data = {
                worlds = worlds,
            },
        })
    end)
    router:post("/game_online", function(c)
        local world_id = c.req.body.world_id
        local from_time = c.req.body.from_time
        local to_time = c.req.body.to_time
        local query = {
            world_id = world_id,
            from_time = from_time,
            to_time = to_time
        }
        local game_online = skynet.call(".web_admin", "lua", "findall", {collection = "game_online",query = query })
        c:send_json({
            code = "OK",
            data = {
                game_online = game_online,
            },
        })
    end)
    router:post("/online_users", function(c)
        local online_flag = c.req.body.online_flag
        local position = c.req.body.position
        local process = c.req.body.process
        local name = c.req.body.name
        local finger = { type = define.FINGER_REQUEST_TYPE.FREQ_NAME,
            finger_by_name = { online_flag = online_flag, name = name, position = position },  }
        local online_users, finger_flag, new_position = cluster.call(process, ".world", "finger", define.INVAILD_ID, finger)
        c:send_json({
            code = "OK",
            data = {
                online_users = online_users,
                finger_flag = finger_flag,
                position = new_position
            },
        })
    end)
    router:post("/change_user_nickname", function(c)
        local process = c.req.body.process
        local guid = c.req.body.guid
        local new_nickname = c.req.body.new_nickname
        local msg = cluster.call(process, ".world", "change_user_nickname", guid, new_nickname)
        c:send_json({
            code = "ok",
            data = {
                msg = msg
            },
        })
    end)
    router:post("/award_item", function(c)
        local process = c.req.body.process
        local guid = c.req.body.guid
        local item_id = c.req.body.item_id
        local item_count = c.req.body.item_count
        local is_bind = c.req.body.is_bind
        local msg = cluster.call(process, ".world", "award_item", guid, item_id, item_count, is_bind)
        c:send_json({
            code = "ok",
            data = {
                msg = msg
            },
        })
    end)
    router:post("/change_user_level", function(c)
        local process = c.req.body.process
        local guid = c.req.body.guid
        local new_level = c.req.body.new_level
        local msg = cluster.call(process, ".world", "change_user_level", guid, new_level)
        c:send_json({
            code = "ok",
            data = {
                msg = msg
            },
        })
    end)
    router:post("/change_user_money", function(c)
        local process = c.req.body.process
        local guid = c.req.body.guid
        local new_money = c.req.body.new_money
        local msg = cluster.call(process, ".world", "change_user_money", guid, new_money)
        c:send_json({
            code = "ok",
            data = {
                msg = msg
            },
        })
    end)
end