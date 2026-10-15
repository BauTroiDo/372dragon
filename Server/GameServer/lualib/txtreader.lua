local class = require "class"
local gbk = require "gbk"
local skynet = require "skynet"
local reader = class("reader")

function reader:ctor() self.fs = {} end

local function split(str, sp)
    local result = {}
    local pos = 0
    for i = 1, string.len(str) do
        local c = string.sub(str, i, i)
        if c == sp then
            table.insert(result, string.sub(str, pos + 1, i - 1))
            pos = i
        end
    end
    if pos < string.len(str) then
        table.insert(result, string.sub(str, pos + 1))
    end
    return result
end

local function readline(line)
    line = gbk.toutf8(line)
    line = string.gsub(line, "\r", "")
    return split(line, "\t")
end

local function load(fn)
    local db = {}
    local config_path = skynet.getenv("config_path")
    local ffn = string.format(config_path, fn)
    local f = io.open(ffn)
    if f then
        local lines = f:lines()
        local i = 1
        local types = {}
        local keys = {}
        for line in lines do
            line = string.gsub(line, "\r", "")
            if #line > 0 and string.sub(line, 1, 1) ~= "#" then
                if i == 1 then
                    types = readline(line)
                elseif i == 2 then
                    keys = readline(line)
                else
                    local list = readline(line)
                    --print("line =", line, ";list =", table.tostr(list))
                    if #list < #types then
                        for i = 1, (#types - #list) do
                            table.insert(list, "")
                        end
                    end
                    local d = {}
                    for j, l in ipairs(list) do
                        local key = keys[j]
                        key = key or j
                        local filed_type = types[j]
                        if filed_type == "INT" or filed_type == "FLOAT" then
                            l = tonumber(l) or 0
                        end
                        if d[key] then
                            if type(d[key]) == "table" then
                                table.insert(d[key], l)
                            else
                                local pre = d[key]
                                d[key] = { pre, l }
                            end
                        else
                            d[key] = l
                        end
                    end
                    db[i - 2] = d
                end
                i = i + 1
            end
        end
        f:close()
    else
        print("load fail ffn =", ffn)
    end
    return db
end

function reader:load(fn)
    if self.fs[fn] == nil then self.fs[fn] = load(fn) end
    return self.fs[fn]
end

function reader:get(fn) return self.fs[fn] end

return reader
