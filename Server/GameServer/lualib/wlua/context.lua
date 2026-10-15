local skynet = require "skynet"
local wlua_request = require "wlua.request"
local wlua_response = require "wlua.response"
local util_file = require "file_util"
local puremagic = require "puremagic"

local M = {}
local mt = { __index = M }

function M:new(app, id, interface, addr)
    local req = wlua_request:new(id, interface)
    if not req then
        return
    end

    local res = wlua_response:new(id, interface)

    local handlers, params = app.router:match(req.path, req.method)
    skynet.logd("wlua context new. path:", req.path, ", method:", req.method, ", params:", params)

    app.router:dump()

    local found = false
    if handlers then
        found = true
    end
    local instance = {
        app = app,
        req = req,
        res = res,
        index = 0,
        handlers = handlers or {},
        params = params,
        found = found,
        addr = addr,
    }
    return setmetatable(instance, mt)
end

function M:next()
    self.index = self.index + 1
    while self.index <= #self.handlers do
        self.handlers[self.index](self)
        self.index = self.index + 1
    end
end

--中断调用,比如中间件验证失败
function M:abort()
    self.index = #self.handlers + 1
end

-- M:send(text, status, content_type)
function M:send(...)
    self.res:send(...)
end

-- M:send_json({AA="BB"})
function M:send_json(...)
    self.res:send_json(...)
end

function M:file(filepath)
    local static_file_map = util_file.static_file
    local ret = static_file_map and static_file_map[filepath]
    if not ret then
        local ok, content = pcall(util_file.readallfile, filepath)
        if ok and content then
            local mimetype = puremagic.via_content(content, filepath)
            skynet.logw("wlua static_file cache unavailable, fallback to disk. filepath:", filepath)
            skynet.logd("file fallback read. filepath:", filepath, ", mimetype:", mimetype)
            self:send(content, 200, mimetype)
            return
        end
        self.found = false
        self.res.status = 404
        self:send("404 Not Found: " .. tostring(filepath), 404, "text/plain")
        if not static_file_map then
            skynet.logw("wlua static_file cache unavailable and fallback failed. filepath:", filepath)
        else
            skynet.logd("file not exist:", filepath)
        end
        return
    end
    local content = ret[1]
    local mimetype = ret[2]
    if not content then
        self.found = false
        self.res.status = 404
        self:send("404 Not Found: " .. tostring(filepath), 404, "text/plain")
        skynet.logd("file not exist:", filepath)
        return
    end
    skynet.logd("file. filepath:", filepath, ", mimetype:", mimetype)
    self:send(content, 200, mimetype)
end

function M:set_res_header(header_key, header_value)
    self.res:set_header(header_key, header_value)
end

return M
