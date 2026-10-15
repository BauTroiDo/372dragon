local skynet = require "skynet"
local CMD = {}

function CMD.init()
    local player_data = require "player_data"
    local db_data = player_data[1]
    local human_db_attr = require "db.human_attrib"
    local ai_human = require "scene.obj.human"
    local h = ai_human.new(db_data, {id = 1})
    local data = h:get_detail_attribs()
    print("a")
end

skynet.start(function()
    skynet.dispatch("lua", function(_, _, command, ...)
        print(...)
        local f = assert(CMD[command], command)
        skynet.ret(skynet.pack(f(...)))
    end)
end)
