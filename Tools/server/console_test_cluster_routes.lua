-- COMMANDX.run requires table.tostr, which this console does not initialize.
-- Install a one-shot result formatter only after all potentially yielding RPCs.
-- The pinned caller immediately invokes it; restore identity before returning.
local codes = {
    ["process mismatch"] = "process",
    ["Tool identity mismatch"] = "tool_identity",
    ["Tool name mismatch"] = "tool_name",
    ["authoritative Tool metadata mismatch"] = "tool_metadata",
    ["duplicate cluster endpoint"] = "duplicate_endpoint",
    ["private cluster endpoint mismatch"] = "endpoint",
    ["filter identity mismatch"] = "filter_identity",
    ["public filter missing or duplicate"] = "filter_public",
    ["local filter unavailable"] = "filter_local",
    ["Game identity mismatch"] = "game_identity",
    ["replay refused"] = "replay_refused",
    ["replay not visible"] = "replay_visibility",
    ["routed filter mismatch"] = "filter_remote",
}
local stages = {
    module_skynet = true, module_cluster = true, identity_env = true,
    tool_process = true, tool_name = true, tool_metadata = true, tool_public = true,
    filter_local = true, game_process = true, game_nodes_before = true,
    replay = true, game_nodes_after = true, filter_remote = true, complete = true,
}
local stage = "load"
local function progress(value)
    stage = stages[value] and value or "unknown"
end
local function diagnose(value)
    local text = type(value) == "string" and value or ""
    local code = codes[text:match("CYS route: ([a-zA-Z ]+)$")] or "unclassified"
    if code == "unclassified" then
        for _, pair in ipairs({
            {"call to invalid address", "call_to_invalid_address"},
            {"call failed", "call_failed"},
            {"attempt to call a nil value", "attempt_call_nil"},
            {"attempt to index a nil value", "attempt_index_nil"},
            {"attempt to", "lua_type_error"},
            {"not found", "module_not_found"},
            {"cannot open", "file_open"},
        }) do
            if text:find(pair[1], 1, true) then code = pair[2]; break end
        end
    end
    local source, line = "none", 0
    for _, base in ipairs({"activate_test_cluster_routes.lua", "skynet.lua", "cluster.lua",
                          "console_test_cluster_routes.lua", "debug_console.lua"}) do
        local pattern = base:gsub("%.", "%%.") .. ":(%d+):"
        local found = tonumber(text:match(pattern))
        if found and found < 10000 then source, line = base, found; break end
    end
    -- Capture while xpcall still owns the failed stack, retaining only numeric
    -- activation-script lines. No arguments, message, paths, or other frames.
    local trace, seen = {}, {}
    for found in debug.traceback("", 2):gmatch("activate_test_cluster_routes%.lua:(%d+):") do
        local n = tonumber(found)
        if n < 10000 and not seen[n] and #trace < 6 then
            seen[n] = true; trace[#trace + 1] = tostring(n)
        end
    end
    return {code = code, source = source, line = line,
            trace = #trace > 0 and table.concat(trace, ",") or "none"}
end
local path = "/mnt/c/TLBB/085/CY-Source/Tools/server/activate_test_cluster_routes.lua"
local file = io.open(path, "rb")
local fn
if file then
    local source = file:read(131073)
    file:close()
    if source and #source <= 131072 then fn = load(source, "@" .. path, "t") end
end
local message
if not fn then
    message = "CYS_ROUTE_FAIL phase=load code=script_load line=0"
else
    local ok, result = xpcall(fn, diagnose, progress)
    if ok and type(result) == "string" and
       result:match("^CYS_ROUTE_OK had_tool=[01] has_tool=1 public_count=%d+ filter_equal=1$") then
        message = result
    else
        local info = not ok and type(result) == "table" and result or
                     {code = "unexpected_result", source = "none", line = 0, trace = "none"}
        message = string.format("CYS_ROUTE_FAIL phase=activation code=%s line=%d step=%s source=%s trace=%s",
                                info.code, info.line, stage, info.source, info.trace)
    end
end
local previous = table.tostr
table.tostr = function(_)
    table.tostr = previous
    return message
end
