local skynet = require "skynet"

return function ()
    return function(c)
        local method = c.req.method
        if method == "OPTIONS" then
            c:set_res_header('X-Powered-By', 'wlua framework')
            c:set_res_header('Access-Control-Allow-Origin', 'http://localhost:9528')
            c:set_res_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
            c:set_res_header('Access-Control-Allow-Credentials', 'true')
            c:set_res_header('Access-Control-Allow-Headers', 'DNT,X-Mx-ReqToken,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Authorization,x-token')
            c:send("", 204, "text/plain")
        end
    end
end

