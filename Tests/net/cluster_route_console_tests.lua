-- Actual pinned debug_console.lua docmd/COMMANDX.run, without live sockets.
local console_path, wrapper_path = ...
local activation_path = "/mnt/c/TLBB/085/CY-Source/Tools/server/activate_test_cluster_routes.lua"
local total = 0
local function check(value, message)
    assert(value, message)
    total = total + 1
end
local function upvalues(f)
    local result = {}
    for i = 1, 100 do
        local name, value = debug.getupvalue(f, i)
        if not name then break end
        result[name] = value
    end
    return result
end
local function execute(wrapper, previous, mode)
    local start, calls, lines = nil, 0, {}
    local loadfile_calls, opened, closed = 0, 0, 0
    local tbl = {}
    for k, v in pairs(table) do tbl[k] = v end
    tbl.tostr = previous
    local env = setmetatable({table = tbl}, {__index = _G})
    env.require = function(name)
        if name == "skynet" then return {start = function(f) start = f end} end
        return {}
    end
    env.load = function(source, name, encoding, specific)
        return load(source, name, encoding, specific or env)
    end
    env.CYS_TEST_CALL = function() calls = calls + 1 end
    local function activation_source()
        if mode == "rpc_invalid" then
            return [[local progress = ...
progress("tool_process")
error("skynet.lua:619: call to invalid address secret_fixture_must_not_escape", 0)
]]
        elseif mode == "require_nil" then
            return [[local progress = ...
progress("module_cluster")
error("cluster.lua:20: attempt to call a nil value (field 'secret_fixture')", 0)
]]
        end
        local prefix = 'local progress = ...; CYS_TEST_CALL(); if progress then progress("replay") end; '
        if mode == "assert" then
            return prefix .. 'error("activate_test_cluster_routes.lua:39: CYS route: replay refused", 0)'
        elseif mode == "secret" then
            return prefix .. 'error("secret_fixture_must_not_escape", 0)'
        elseif mode == "bad_result" then
            return prefix .. 'return "secret_fixture_must_not_escape"'
        elseif mode == "oversize" then
            return string.rep(" ", 131073)
        elseif mode == "syntax" then
            return "invalid("
        elseif mode == "bytecode" then
            return string.dump(function() error("must not execute") end)
        end
        return prefix .. 'return "CYS_ROUTE_OK had_tool=0 has_tool=1 public_count=23 filter_equal=1"'
    end
    env.loadfile = function(path)
        loadfile_calls = loadfile_calls + 1
        if mode == "stale" then
            return function() return "CYS_ROUTE_FAIL phase=activation code=unclassified line=0" end
        end
        assert(path == activation_path, "unexpected cached script path")
        return load(activation_source(), "@" .. activation_path, "t", env)
    end
    env.io = {open = function(path, access)
        assert(access == "rb" and (path == activation_path or path == wrapper_path), "unexpected disk read")
        if path == activation_path and mode == "load_fail" then return nil end
        local source
        if path == wrapper_path then
            local f = assert(io.open(path, "rb")); source = f:read("*a"); f:close()
        else source = activation_source() end
        opened = opened + 1
        return {
            read = function(_, limit) assert(limit == 131073); return source:sub(1, limit) end,
            close = function() closed = closed + 1 end,
        }
    end}
    assert(loadfile(console_path, "t", env))(16006)
    local loop = upvalues(start).console_main_loop
    local docmd = upvalues(loop).docmd
    local command
    if wrapper then
        command = 'run local f=assert(io.open("' .. wrapper_path .. '","rb")); ' ..
                  'local s=f:read(131073); f:close(); assert(s and #s<=131072); ' ..
                  'return assert(load(s,"@' .. wrapper_path .. '","t"))()'
    else command = 'run return assert(loadfile("' .. activation_path .. '"))()' end
    docmd(command, function(v)
        table.insert(lines, tostring(v))
    end, 0)
    return table.concat(lines, "\n"), calls, tbl.tostr, loadfile_calls, opened, closed
end

local original, called = execute(false, nil, "ok")
check(called == 1, "original console executes activation before formatting failure")
check(original:find("<CMD Error>", 1, true) and original:find("tostr", 1, true),
      "original real console reproduces missing formatter")
check(not original:find("CYS_ROUTE_OK", 1, true), "old reply cannot establish action outcome")

for _, prior in ipairs({false, function() return "existing formatter" end}) do
    local previous = prior or nil
    local reply, count, restored = execute(true, previous, "ok")
    check(count == 1 and reply:find("CYS_ROUTE_OK", 1, true), "new wrapper reports one action")
    check(reply:find("<CMD OK>", 1, true), "actual docmd accepts one-shot formatter")
    check(restored == previous, "formatter original identity restored including nil")
end
for _, case in ipairs({
    {"assert", "phase=activation code=replay_refused line=39", 1},
    {"secret", "phase=activation code=unclassified line=0", 1},
    {"bad_result", "phase=activation code=unexpected_result line=0", 1},
    {"load_fail", "phase=load code=script_load line=0", 0},
}) do
    local reply, count, restored = execute(true, nil, case[1])
    check(count == case[3] and reply:find("CYS_ROUTE_FAIL " .. case[2], 1, true),
          "failure must preserve phase and bounded allowlist")
    check(reply:find("<CMD OK>", 1, true) and not reply:find("secret_fixture", 1, true),
          "activation failure is distinct from formatting and never leaks raw error")
    check(restored == nil, "failure restores absent formatter")
end
local fresh, count, restored, stale_calls, opened, closed = execute(true, nil, "stale")
check(count == 1 and fresh:find("CYS_ROUTE_OK", 1, true), "fresh disk code wins over stale cached bytecode")
check(stale_calls == 0, "neither wrapper nor activation invokes loadfile")
check(opened == 2 and closed == 2 and restored == nil, "both bounded reads close and formatter restores")
for _, mode in ipairs({"oversize", "syntax", "bytecode"}) do
    local reply, executions, formatter, cached, reads, closes = execute(true, nil, mode)
    check(reply:find("CYS_ROUTE_FAIL phase=load code=script_load line=0", 1, true) and executions == 0,
          "invalid/oversized/nontext input fails before activation")
    check(reads == closes and cached == 0 and formatter == nil, "load failure closes handles without global changes")
end
for _, case in ipairs({
    {"rpc_invalid", "code=call_to_invalid_address line=619 step=tool_process source=skynet.lua trace=3"},
    {"require_nil", "code=attempt_call_nil line=20 step=module_cluster source=cluster.lua trace=3"},
}) do
    local reply, _, restored = execute(true, nil, case[1])
    check(reply:find(case[2], 1, true), "actual xpcall retains step and activation frame")
    check(not reply:find("secret_fixture", 1, true), "diagnostic never exposes raw RPC/module error")
    check(restored == nil, "RPC failure still restores nil formatter")
end
print(string.format("PASS %d real-console assertions; old post-action formatting failure reproduced", total))
