-- Compile only. Never execute a gameplay chunk or contact a running service.
-- lua check_lua_syntax.lua <newline-separated file manifest> <report TSV>
local manifest = assert(io.open(assert(arg[1]), "r"))
local report = assert(io.open(assert(arg[2]), "w"))
local count, failed = 0, 0
for path in manifest:lines() do
    count = count + 1
    local chunk, err = loadfile(path, "t", {})
    if not chunk then
        failed = failed + 1
        report:write(path, "\t", tostring(err):gsub("[\r\n\t]", " "), "\n")
    end
end
manifest:close()
report:close()
print(string.format("Lua %s: compiled=%d failed=%d", _VERSION, count, failed))
os.exit(failed == 0 and 0 or 1)
