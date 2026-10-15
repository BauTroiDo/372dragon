local laiscript = require "laiscript"
local class = require "class"
local skynet = require "skynet"
local configenginer = require "configenginer":getinstance()
local gametable = class("gametable")
function gametable:getinstance()
    if gametable.instance == nil then
        gametable.instance = gametable.new()
    end
    return gametable.instance
end

function gametable:ctor()
    self.ai_scripts = {}
    self.ai_script_dat = nil
    self.inited = false
end

function gametable:init()
    if self.inited then return end
    self.inited = true
    self.ai_script_dat = configenginer:get_config("ai_script_dat")
    skynet.logd("[gametable] init done, ai_script_dat entries =", self.ai_script_dat and #self.ai_script_dat or 0)
end

function gametable:get_ai_script(id)
    local script = self.ai_scripts[id]
    if script then return script end
    if script == false then return nil end   -- da biet la thieu, khong thu lai
    -- Lazy load: parse on first access
    if self.ai_script_dat then
        local file = self.ai_script_dat[id]
        if file then
            local config_path = skynet.getenv("config_path")
            local path = string.format(config_path, "AIScript/" .. file)
            local f = io.open(path, "r")
            if f then
                f:close()
                local as = laiscript.AIScript.new()
                local ok, err = pcall(as.ParseScript, as, path)
                if ok then
                    self.ai_scripts[id] = as
                    return as
                end
                skynet.loge("[AI] ParseScript loi: id=", id, " file=", path, " err=", tostring(err))
            else
                skynet.logw("[AI] thieu file AI script: id=", id, " path=", path)
            end
        else
            skynet.logw("[AI] AIScript.dat khong co id=", id)
        end
    end
    -- [audit 2026-09-11] ghi nho la thieu de chi log 1 lan; quai dung AI co ban thay vi assert moi tick
    self.ai_scripts[id] = false
    return nil
end

return gametable
