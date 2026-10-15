local skynet = require "skynet"
local packet_def = require "game.packet"
local class = require "class"
local utils = require "utils"
local define = require "define"
local configenginer = require "configenginer":getinstance()
local scriptenginer = class("scriptenginer")
scriptenginer.not_raw_call_function = {
    ["OnDefaultEvent"] = true,
    ["OnEventRequest"] = true,
    ["OnActivateOnce"] = true,
    ["OnActivateEachTick"] = true,
    ["OnDie"] = true,
    ["OnLeaveCombat"] = true,
    ["OnEnterArea"] = true,
    ["OnLeaveArea"] = true,
    ["OnTimer"] = true,
}

-- 高频/批量触发的框架回调允许脚本缺省，避免刷屏日志淹没真实问题。
scriptenginer.silent_missing_function = {
    ["OnHeartBeat"] = true,
    ["OnCharacterTimer"] = true,
    ["OnEnterCombat"] = true,
    ["OnDie"] = true,
    ["OnImpactFadeOut"] = true,
    ["PickupItem"] = true,
    ["OnInit"] = true,
}

function scriptenginer:should_log_missing_call(func)
    return not self.silent_missing_function[func]
end
function scriptenginer:getinstance()
    if scriptenginer.instance == nil then
        scriptenginer.instance = scriptenginer.new()
    end
    return scriptenginer.instance
end

function scriptenginer:ctor()
    self.scripts = {}
    self._nil_id_logged = {}
    self._not_found_logged = {}
    self._load_error_logged = {}
    self._active_calls = 0
    self._reloading = false
end

function scriptenginer:set_scene(scene) self.scene = scene end

function scriptenginer:get_scene() return self.scene end

function scriptenginer:reload_scripts()
    if self._reloading then
        skynet.logw("[XSCRIPT] reload_scripts ignored: already reloading")
        return
    end

    self._reloading = true
    local wait_count = 0
    while (self._active_calls or 0) > 0 and wait_count < 100 do
        wait_count = wait_count + 1
        skynet.sleep(1)
    end

    local ok, err = xpcall(function()
        print("scriptenginer:reload_scripts =")
        -- [audit 2026-09-11] skynet cache chunk theo duong dan cho ca tien trinh: khong clear thi require lai van ra file CU
        pcall(function() require("skynet.codecache").clear() end)
        for _, path in pairs(self.dat or {}) do
            package.loaded[path] = nil
            print("reload_scripts =", path)
        end
        package.loaded["scripts.scripts"] = nil
        package.loaded["scripts.script_access"] = nil
        package.loaded["scripts.ScriptGlobal"] = nil
        self.scripts = {}
        self.dat = nil
        self._nil_id_logged = {}
        self._not_found_logged = {}
        self._load_error_logged = {}
        local r, script_access = xpcall(require, debug.traceback, "scripts.script_access")
        if r then
            self.script_access = script_access
        elseif not string.find(tostring(script_access), "module 'scripts.script_access' not found", 1, true) then
            skynet.logw("[XSCRIPT] reload script_access error =", script_access)
        end
    end, debug.traceback)

    self._reloading = false
    if not ok then
        skynet.logw("[XSCRIPT] reload_scripts error =", err)
    end
end

function scriptenginer:item_is_skill_like_script(human, script)
    return self:call(script, "IsSkillLikeScript", human:get_obj_id()) == 1
end

function scriptenginer:item_call_default_event(human, script, bag_index)
    return self:call(script, "OnDefaultEvent", human:get_obj_id(), bag_index)
end

function scriptenginer:script_cancle_impacts(human, script)
    return self:call(script, "CancelImpacts", human:get_obj_id()) == 1
end

function scriptenginer:have_function(id, func)
    local s = self.scripts[id]
    s = s and s or self:try_load(id)
    if s then
        local f = s[func]
        return f ~= nil
    end
end

function scriptenginer:try_load(id)
    if self._reloading then
        return
    end

    local dat = self.dat
    if dat == nil then
        local ok, loaded = xpcall(require, debug.traceback, "scripts.scripts")
        if not ok then
            if not self._load_error_logged["scripts.scripts"] then
                skynet.logw("[XSCRIPT] load scripts.scripts error =", loaded)
                self._load_error_logged["scripts.scripts"] = true
            end
            return
        end
        dat = loaded
    end
    self.dat = dat
    local path = dat[id]
    if path then
        local ok, f = xpcall(require, debug.traceback, path)
        if not ok then
            local key = tostring(id) .. "|" .. tostring(path)
            if not self._load_error_logged[key] then
                skynet.logw("[XSCRIPT] require script error: id=", id, " path=", path, " err=", f)
                self._load_error_logged[key] = true
            end
            return
        end
        if type(f) == "table" then
            if type(f.new) == "function" then
                local ok_new, script = xpcall(f.new, debug.traceback)
                if not ok_new then
                    local key = tostring(id) .. "|" .. tostring(path) .. "|new"
                    if not self._load_error_logged[key] then
                        skynet.logw("[XSCRIPT] script new() error: id=", id, " path=", path, " err=", script)
                        self._load_error_logged[key] = true
                    end
                    return
                end
                if type(script) ~= "table" or type(script.set_scene) ~= "function" then
                    local key = tostring(id) .. "|" .. tostring(path) .. "|bad_instance"
                    if not self._load_error_logged[key] then
                        skynet.logw("[XSCRIPT] script bad instance: id=", id, " path=", path)
                        self._load_error_logged[key] = true
                    end
                    return
                end
                script:set_scene(self.scene)
                script.script_id = id
                self.scripts[id] = script
                return script
            else
                local key = tostring(id) .. "|" .. tostring(path) .. "|missing_new"
                if not self._load_error_logged[key] then
                    skynet.logw("[XSCRIPT] script missing new(): id=", id, " path=", path)
                    self._load_error_logged[key] = true
                end
            end
        end
    end
end

function scriptenginer:call(id, func, ...)
    if self._reloading then
        return
    end
    if id == nil then
        if self:should_log_missing_call(func) then
            if self._nil_id_logged[func] == nil then
                skynet.logw("[XSCRIPT] scriptenginer:call id is nil, func=", func, "\n", debug.traceback())
                self._nil_id_logged[func] = true
            end
        end
        return
    end
    local s = self.scripts[id]
    s = s and s or self:try_load(id)
    if s then
        local f = s[func]
        if f then
            self._active_calls = (self._active_calls or 0) + 1
            local result = {xpcall(f, debug.traceback, s, ...)}
            self._active_calls = math.max((self._active_calls or 1) - 1, 0)
            local r = result[1]
            if r then
                table.remove(result, 1)
                return table.unpack(result)
            else
                skynet.logw("scriptenginer:call error =" .. result[2])
            end
        else
            if self:should_log_missing_call(func) then
                local key = tostring(id) .. "|" .. tostring(func)
                if self._not_found_logged[key] == nil then
                    skynet.logw("[XSCRIPT] scriptenginer:call func NOT FOUND: id=", id, " func=", func)
                    self._not_found_logged[key] = true
                end
            end
        end
    else
        if self:should_log_missing_call(func) then
            local key = tostring(id) .. "|" .. tostring(func)
            if self._not_found_logged[key] == nil then
                skynet.logw("[XSCRIPT] scriptenginer:call script NOT LOADED: id=", id)
                self._not_found_logged[key] = true
            end
        end
    end
end

function scriptenginer:raw_call(id, func, ...)
    local s = self.scripts[id]
    s = s and s or self:try_load(id)
    if s then
        if s.is_super_function(func) or self.not_raw_call_function[func] then
            skynet.loge(string.format("[XSCRIPT] raw_call BLOCKED: %s is super/not_raw function", tostring(func)))
        else
            if self:check_function_is_allow(id, func) then
                self:log_raw_call_function(id, func, ...)
                return self:call(id, func, ...)
            else
                skynet.loge(string.format("[XSCRIPT] raw_call NOT_ALLOWED: id=%d func=%s", id, tostring(func)))
            end
        end
    else
        skynet.logw("[XSCRIPT] raw_call script NOT LOADED: id=", id)
    end
end

function scriptenginer:check_function_is_allow(id, func)
    if self.script_access == nil then
        return true
    end
    local script = self.script_access[id]
    if script == nil then
        return false
    end
    return script[func] == true
end

function scriptenginer:log_raw_call_function(id, func, ...)
    local collection = "log_raw_call_function"
    local args = { ... }
    local data = table.tostr(args)
    local guid = define.INVAILD_ID
    local name = ""
    local human = self:get_scene():get_obj_by_id(args[1])
    if human then
        guid = human:get_guid()
        name = human:get_name()
    end
    local doc = { id = id, func = func, args = data, date_time = utils.get_day_time(), unix_time = os.time(), guid = guid, name = name}
    skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc})
end

function scriptenginer:dispatch(who, cmdid, event)
    local ret = packet_def.GCScriptCommand.new()
    ret.m_nCmdID = cmdid
    ret.event = event
    ret.unknow_1 = 0
    if type(event) == "table" then ret.size = #ret.event end
    self.scene:send2client(who, ret)
end

return scriptenginer
