local class = require "class"
local configs = class("configs")

function configs:get_fluctuation()
    return 1.2
end

function configs:get_menpai_fluctuation()
    return 1.2
end

return configs