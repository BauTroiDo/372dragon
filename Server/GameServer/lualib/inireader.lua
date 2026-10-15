local class = require "class"
local gbk = require "gbk"
local skynet = require "skynet"
local reader = class("reader")

function reader:ctor()
    self.fs = {}
end

local function load(fileName)
	assert(type(fileName) == 'string', 'Parameter "fileName" must be a string.')
    -- Smart routing: absolute paths or paths with "/" pass through directly
    -- Bare filenames (e.g. "SceneInfo.ini") get config_path applied
    local fullFilName
    if fileName:sub(1, 1) == "/" or fileName:find("/") then
        fullFilName = fileName
    else
        local config_path = skynet.getenv("config_path")
        fullFilName = string.format(config_path, fileName)
    end
	local file = assert(io.open(fullFilName, 'r'), 'Error loading file : ' .. fullFilName)
	local data = {}
	local section
	for line in file:lines() do
        line = gbk.toutf8(line)
		local tempSection = line:match('%[([_%w]+)%]')
		if(tempSection)then
			section = tonumber(tempSection) and tonumber(tempSection) or tempSection
			data[section] = data[section] or {}
        else
            local param, value = line:match("([_%w]+)=([^%;-%\r-%\t]+)")
            if(param and value)then
                if(tonumber(value))then
                    value = tonumber(value)
                elseif(value == 'true')then
                    value = true
                elseif(value == 'false')then
                    value = false
                end
                if(tonumber(param))then
                    param = tonumber(param)
                end
                data[section][param] = value
            else
                param, value = line:match("([_%w]+):([^%;-%\r-%\t]+)")
                if param and value then
                    if(tonumber(param))then
                        param = tonumber(param)
                    end
                    data[section][param] = value
                end
            end
		end
	end
	file:close()
	return data
end

function reader:load(fn)
    if self.fs[fn] == nil then
        self.fs[fn] = load(fn)
    end
    return self.fs[fn]
end

function reader:get(fn)
    return self.fs[fn]
end

return reader