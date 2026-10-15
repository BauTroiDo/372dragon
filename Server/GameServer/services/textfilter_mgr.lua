local skynet = require "skynet"
local textfilter = require "textfilter"
local CMD = {}
local instance

function CMD.is_sensitive(text)
    return textfilter.is_sensitive(instance,text)
end

function CMD.replace_sensitive(text)
    return textfilter.replace_sensitive(instance,text)
end

skynet.start(function()
    local path = skynet.getenv "sensitive_words_path"
    instance = assert(textfilter.init(path))

    skynet.dispatch("lua",function(_,_,command,...)
        local f = assert(CMD[command], command)
        skynet.ret(skynet.pack(f(...)))
    end)
end)
