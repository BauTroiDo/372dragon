-- CYS-QUEST: unit tests of the proposed script_base:EndEvent (server-patch/script_base_EndEvent.lua), lua5.4.
-- Usage: lua5.4 test_EndEvent.lua <patch file>
script_base = {}
gbk = { fromutf8 = function(s) return s end }
dofile(arg[1])

local passed, failed = 0, 0
local function test(name, fn)
    local ok, err = pcall(fn)
    if ok then passed = passed + 1; print("PASS " .. name) else failed = failed + 1; print("FAIL " .. name .. ": " .. tostring(err)) end
end
local function check(v, msg) if not v then error(msg, 2) end end

local function run(items)
    local o = setmetatable({ size = 0, flags = {}, strs = {}, types = {}, indexs = {}, script_ids = {}, event = {}, script_id = 7 }, { __index = script_base })
    for _, it in ipairs(items) do
        o.size = o.size + 1
        o.flags[o.size] = it[1]; o.strs[o.size] = it[2]; o.types[o.size] = it[3] or 0; o.indexs[o.size] = it[4] or 0
        o.script_ids[o.size] = 7
    end
    o:EndEvent()
    return o.event
end
local function utf8_ok(s) return utf8.len(s) ~= nil end
local function join(events)
    local out, open = {}, false
    for _, e in ipairs(events) do
        local t = e.str
        local cont = e.flag ~= 1 and t:sub(-1) == "\31"
        if cont then t = t:sub(1, -2) end
        if open and e.flag ~= 1 and out[#out].flag == e.flag then out[#out].str = out[#out].str .. t
        else out[#out + 1] = { flag = e.flag, str = t } end
        open = cont
    end
    return out
end
local function viet(n) -- n bytes of 3-byte and 2-byte UTF-8 mixed with ASCII words
    local parts, len = {}, 0
    local words = { "Tr\u{01B0}\u{1EDB}c ", "khi ", "v\u{00E0}o ", "T\u{1EBF} \u{0110}\u{00E0}n, ", "ng\u{01B0}\u{01A1}i ", "#Gph\u{1EA3}i#W " }
    local i = 0
    while len < n do i = i % #words + 1; parts[#parts + 1] = words[i]; len = len + #words[i] end
    local s = table.concat(parts)
    while #s > n do s = s:sub(1, #s - 1) end
    while not utf8_ok(s) do s = s:sub(1, #s - 1) end
    return s
end

test("short_text_unchanged", function()
    local ev = run({ { 2, "  Ch\u{00E0}o $N" }, { 1, "V\u{1EC1} l\u{00F4}i \u{0111}\u{00E0}i", 11, 0 } })
    check(#ev == 2 and ev[1].str == "  Ch\u{00E0}o $N" and ev[2].flag == 1 and ev[2].type == 11, "unchanged")
end)
for _, n in ipairs({ 254, 255 }) do
    test("exact_" .. n .. "_bytes_one_item", function()
        local s = string.rep("a", n)
        local ev = run({ { 2, s } })
        check(#ev == 1 and ev[1].str == s and ev[1].len == n, "one item of " .. n)
    end)
end
test("256_bytes_two_items", function()
    local s = string.rep("a", 256)
    local ev = run({ { 2, s } })
    check(#ev == 2, "two items")
    check(#ev[1].str == 255 and ev[1].str:sub(-1) == "\31", "first 254 + mark")
    check(ev[2].str == "aa", "rest 2 bytes, no mark")
    check(join(ev)[1].str == s, "join restores")
end)
test("utf8_boundaries_and_lengths", function()
    for n = 250, 1300, 7 do
        local s = viet(n)
        local ev = run({ { 2, s } })
        for i, e in ipairs(ev) do
            check(#e.str <= 255 and e.len == #e.str, "chunk <= 255 at n=" .. n)
            local body = (i < #ev) and e.str:sub(1, -2) or e.str
            check(utf8_ok(body), "chunk is whole UTF-8 at n=" .. n)
            check((i < #ev) == (e.str:sub(-1) == "\31"), "mark only on non-last at n=" .. n)
        end
        local j = join(ev)
        check(#j == 1 and j[1].str == s, "join restores n=" .. n)
    end
end)
test("baichongyi_404_bytes", function()
    local s = "  #G$N#W anh h\u{00F9}ng! " .. viet(380)
    local ev = run({ { 2, s } })
    check(#ev == 2 and join(ev)[1].str == s, "404-ish restores")
end)
test("options_keep_fields_and_order", function()
    local long = viet(600)
    local ev = run({ { 2, long }, { 1, "A", 6, 1 }, { 2, "tail" }, { 1, "B", 11, 2 } })
    local j = join(ev)
    check(#j == 4 and j[1].str == long and j[2].str == "A" and j[3].str == "tail" and j[4].str == "B", "order")
    check(ev[#ev].type == 11 and ev[#ev].index == 2, "option fields")
end)
test("cap_16_items", function()
    local items = {}
    for i = 1, 14 do items[#items + 1] = { 1, "opt" .. i, 1, i } end
    items[#items + 1] = { 2, viet(1000) } -- needs 5 items, only 2 slots
    local ev = run(items)
    check(#ev == 16, "16 events, got " .. #ev)
    for i = 1, 14 do check(ev[i].flag == 1 and ev[i].str == "opt" .. i, "options kept") end
    check(ev[16].str:sub(-1) ~= "\31", "last kept chunk has no mark")
    check(#ev[15].str <= 255 and #ev[16].str <= 255, "chunks <= 255")
end)
test("full_list_long_text_first_uses_spare_only", function()
    local items = { { 2, viet(700) } }
    for i = 1, 15 do items[#items + 1] = { 1, "o" .. i, 1, i } end
    local ev = run(items)
    check(#ev == 16 and ev[1].flag == 2 and #ev[1].str <= 255 and ev[1].str:sub(-1) ~= "\31", "no spare: first chunk only")
end)
test("no_mark_in_normal_text", function()
    local ev = run({ { 2, string.rep("x", 255) }, { 2, "y" } })
    local j = join(ev)
    check(#j == 2, "exactly 255 bytes is not joined with the next text")
end)
print(string.format("RESULT passed=%d failed=%d", passed, failed))
os.exit(failed == 0 and 0 or 1)
