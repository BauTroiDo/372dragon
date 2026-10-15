local skynet = require "skynet"
local mysql = require "skynet.db.mysql"
local server_conf = require "server_conf"
local class = require "class"
local mysql_core = class("mysql_core")

function mysql_core:getinstance()
    if mysql_core.instance == nil then
        mysql_core.instance = mysql_core.new()
    end
    return mysql_core.instance
end

function mysql_core:ctor()
end

function mysql_core:init()
    local function on_connect(db)
        skynet.error("on_connect")
    end
    local mysqldb = table.clone(server_conf.mysqldb)
    mysqldb.max_packet_size = 1024 * 1024
    mysqldb.on_connect = on_connect
    local ok, db = pcall(mysql.connect, mysqldb)
    if not ok or not db then
        skynet.error("failed to connect to mysql:", tostring(db))
        self.db = nil
        return
    else
        skynet.error("success to connect to mysql server")
    end
    --设置utf8字符集
    db:query("set charset utf8")
    self.db = db
end

function mysql_core:query(sql)
    if not self.db then
        return {err = "mysql not connected"}
    end
    return self.db:query(sql)
end

return mysql_core