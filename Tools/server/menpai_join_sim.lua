-- menpai-join (20/09/2026): MO PHONG NGOAI TUYEN duong nhap phai qua NPC - CHI DOC, khong can server chay.
--
--   lua5.4 menpai_join_sim.lua <goc-server> [--overlay <staging>]... [--json <tep>]
--     <goc-server>        thu muc chua GameServer/ Game_2/ configs/   (vd /home/ubuntu  hoac  /home/ubuntu/cys-test-20260913)
--     --overlay <staging> thu muc chi chua cac tep DA VA (Game_2/Script/..., GameServer/lualib/...), PHU LEN <goc-server>
--
-- CHAY MA THAT, chi gia lop van chuyen:
--   THAT : Game_2/Script/scripts/obj/**  (script NPC nguyen van)  ·  lualib/menpai_registry.lua  ·  lualib/menpai_extensions.lua
--          lualib/define.lua  ·  lualib/cfghelper.lua + txtreader/inireader + luaclib/gbk.so  ·  configs/*.txt (bang that)
--   GIA  : script_base (ghi lai doi so cua LuaFnJoinMenpai / LuaFnSetXinFaLevel / DispatchXinfaLevelInfo), skynet (getenv + log cam)
--
-- Moi NPC: goi OnEventRequest dung nhu client bam "xac nhan gia nhap", lay SO PHAI ma script dua cho LuaFnJoinMenpai, roi
-- dua so do qua menpai_registry.check_join THAT + bang THAT de tinh dung thu script_base.lua:194-228 se cap.
-- Doi chung DUONG (hieu chuan): chay tren cay GOC phai ra 6 tam phap + chieu cho CA 4 phai CY (cap dang chay dung).

local root, json_out
local overlays = {}
do
    local i = 1
    while arg[i] do
        if arg[i] == "--json" then json_out = arg[i + 1]; i = i + 2
        elseif arg[i] == "--overlay" then overlays[#overlays + 1] = arg[i + 1]; i = i + 2
        elseif not root then root = arg[i]; i = i + 1
        else error("tham so la: " .. tostring(arg[i])) end
    end
end
assert(root, "can <goc-server>")
-- --overlay <staging>: thu muc chi chua cac tep DA DOI (Game_2/Script/..., GameServer/lualib/...), PHU LEN <goc-server>.
-- Overlay dung TRUOC trong package.path nen tep da va thang; tep khong co trong overlay roi ve cay goc-server.
local script_root = (#overlays > 0 and (table.concat(overlays, "+") .. " + ") or "") .. root .. "/Game_2/Script"
local paths = {}
for _, o in ipairs(overlays) do
    paths[#paths + 1] = o .. "/Game_2/Script/?.lua"
    paths[#paths + 1] = o .. "/GameServer/lualib/?.lua"
end
paths[#paths + 1] = root .. "/Game_2/Script/?.lua"
paths[#paths + 1] = root .. "/GameServer/lualib/?.lua"
paths[#paths + 1] = root .. "/GameServer/services/?.lua"
package.path = table.concat(paths, ";") .. ";" .. package.path
package.cpath = root .. "/GameServer/luaclib/?.so;" .. package.cpath

local quiet = function() end
package.preload["skynet"] = function()
    return { getenv = function(k) if k == "config_path" then return root .. "/configs/%s" end end,
             logd = quiet, logi = quiet, logw = quiet, loge = quiet, error = quiet, log = quiet }
end
package.preload["skynet.manager"] = function() return {} end
package.preload["skynet.sharetable"] = function() return {} end
if not table.tostr then table.tostr = function() return "" end end

-- ---- script_base GIA: chi ghi lai cac loi goi mang SO PHAI / ID TAM PHAP ------------------------------
local class = require "class"
local REC
local fake = class("script_base")
local STATE = { menpai = 9, level = 15 }
function fake:GetMenPai() return STATE.menpai end
function fake:GetLevel() return STATE.level end
function fake:GetSex() return 0 end
function fake:LuaFnJoinMenpai(selfId, menpai)
    REC.join[#REC.join + 1] = menpai
    local ok = STATE.join_result(menpai)
    REC.join_result[#REC.join_result + 1] = ok
    if ok then STATE.menpai = menpai end
    return ok
end
function fake:LuaFnSetXinFaLevel(selfId, xinfa, level) REC.set_xinfa[#REC.set_xinfa + 1] = { xinfa, level, STATE.menpai } end
function fake:DispatchXinfaLevelInfo(selfId, targetId, menpai) REC.xinfa_info[#REC.xinfa_info + 1] = menpai end
function fake:EndAddItem() return true end
function fake:GetItemName() return "" end
function fake:GetMissionDataEx() return 0 end
function fake:get_scene_id() return 0 end
-- Moi ham KHAC cua script_base (AddText, BeginEvent, MsgBox, notify_tips, CallScriptFunction...) phai bi nuot im lang.
-- class.lua ke thua bang CHEP HAM (pairs(super)), khong qua metatable => fallback dat tren lop gia se KHONG toi lop con.
-- Vi vay fallback duoc gan len LOP LA sau khi require (xem with_fallback). Truong du lieu `g_*` thi de nguyen nil.
local function noop() end
local function with_fallback(cls)
    if getmetatable(cls) == nil then
        setmetatable(cls, { __index = function(_, k)
            if type(k) == "string" and (k:sub(1, 2) == "g_" or k == "super" or k == "ctor") then return nil end
            return noop
        end })
    end
    return cls
end
package.preload["script_base"] = function() return fake end
package.preload["cy_four_crafting_config"] = function() return { material_shop = 0 } end

-- ---- bang + registry THAT ---------------------------------------------------------------------------
local define = require "define"
local registry = require "menpai_registry"
local cfg = require("cfghelper").new()
local cache = {}
local function get_config(name)
    if cache[name] == nil then
        local reader = cfg["read_" .. name]
        assert(reader, "cfghelper khong co read_" .. name)
        reader(cfg)
        cache[name] = cfg["get_" .. name](cfg)
        assert(type(cache[name]) == "table", "khong nap duoc " .. name)
    end
    return cache[name]
end

local BASE_SKILLS = { 0, 1, 2, 3, 21, 22, 34, 35, 43 }   -- nhan vat chua vao phai (dung 9 chieu cua test00 trong log nguoi dung)

local function grant(menpai)
    -- dung logic script_base.lua:186-223 (GIONG nhau o ca hai cay - bang vi sai V7)
    local ok, reason = registry.check_join(define, menpai, BASE_SKILLS, get_config)
    local out = { check_join = ok, reason = reason, xinfa = {}, skills = {} }
    if not ok then return out end
    local xinfa_v1 = get_config("xinfa_v1")
    for _, id in ipairs(registry.xinfa_ids(xinfa_v1, menpai)) do
        if id ~= define.MENPAI_7_XINFA[menpai] and id ~= define.MENPAI_8_XINFA[menpai] then
            out.xinfa[#out.xinfa + 1] = id
        end
    end
    for id, t in pairs(get_config("skill_template")) do
        if t.menpai == menpai and t.direct_study_up then out.skills[#out.skills + 1] = id end
    end
    table.sort(out.skills)
    out.yuangong = define.MENPAI_JINZHAN_YUANGONG_SKILL[menpai]
    return out
end

local NPCS = {
    { "Duong Mon (唐门)",        "scripts.obj.cy4.cy4_tangmen_join",          "唐门",   3 },
    { "Quy Coc (鬼谷)",          "scripts.obj.cy4.cy4_guigu_join",            "鬼谷",   3 },
    { "Dao Hoa Dao (桃花岛)",    "scripts.obj.cy4.cy4_taohuadao_join",        "桃花岛", 3 },
    { "Tuyet Tinh Coc (绝情谷)", "scripts.obj.cy4.cy4_congren_join",          "绝情谷", 3 },
    { "Ac Nhan Coc (恶人谷)",    "scripts.obj.erengu.erengu_duanyanqing",     "恶人谷", 3 },
    { "Mo Dung (慕容)",          "scripts.obj.gusu.ogusu_murongjie",          "慕容",   3 },
    { "Man Da (曼陀) [TAT o ta]", "scripts.obj.mantuo.omantuo_wangsushang",   "曼陀",   3 },
    { "Vo Dang (武当) doi chung", "scripts.obj.wudang.owudang_zhangxuansu",   "武当",   3 },
}

local function esc(s) return (tostring(s):gsub('\\', '\\\\'):gsub('"', '\\"')) end
local function arr(t) local o = {} for i, v in ipairs(t) do o[i] = tostring(v) end return "[" .. table.concat(o, ",") .. "]" end

local rows, bad = {}, 0
print(string.format("%-26s %-6s %-10s %-10s %-26s %-7s %s", "NPC nhap phai", "so", "ten(so)", "check_join", "tam phap cap", "chieu", "PHAN QUYET"))
for _, n in ipairs(NPCS) do
    local label, mod, want_name, index = n[1], n[2], n[3], n[4]
    REC = { join = {}, join_result = {}, set_xinfa = {}, xinfa_info = {} }
    STATE.menpai, STATE.level = 9, 15
    local g
    STATE.join_result = function(menpai) g = grant(menpai); return g.check_join end
    local okload, npc = pcall(require, mod)
    local row = { npc = label, module = mod, want = want_name }
    if not okload then
        row.verdict = "KHONG NAP DUOC: " .. tostring(npc):sub(1, 120)
    else
        with_fallback(npc)
        local inst = npc.new and npc.new() or npc
        local okrun, err = pcall(inst.OnEventRequest, inst, 1, 2, nil, index)
        if not okrun then row.error = tostring(err):sub(1, 160) end
        row.passed = REC.join[1]
        row.name_of_passed = row.passed and define.ENUM_MENPAI_CHN[row.passed] or nil
        if g then
            row.check_join, row.reason, row.xinfa, row.skills, row.yuangong = g.check_join, g.reason, g.xinfa, #g.skills, g.yuangong
            row.first_skills = { g.skills[1], g.skills[2], g.skills[3] }
        end
        row.set_xinfa = {}
        for _, s in ipairs(REC.set_xinfa) do row.set_xinfa[#row.set_xinfa + 1] = s[1] end
        -- tam phap ma script tu nang cap co thuoc phai vua vao khong?
        local foreign = {}
        if row.passed and g and g.check_join then
            local xv = get_config("xinfa_v1")
            for _, s in ipairs(REC.set_xinfa) do
                if not xv[s[1]] or xv[s[1]].menpai ~= row.passed then foreign[#foreign + 1] = s[1] end
            end
        end
        row.foreign_xinfa = foreign
        local set_after_refusal = (g and not g.check_join and #REC.set_xinfa > 0)
        if row.passed == nil then
            row.verdict = "KHONG GOI LuaFnJoinMenpai"
        elseif row.name_of_passed ~= want_name then
            row.verdict = "SAI PHAI: NPC cua " .. want_name .. " dua so " .. row.passed .. " = " .. tostring(row.name_of_passed)
        elseif not g.check_join then
            row.verdict = set_after_refusal and "TU CHOI nhung VAN nang tam pháp (ro ri)" or ("TU CHOI dung: " .. tostring(g.reason))
        elseif #g.xinfa ~= 6 or #g.skills == 0 then
            row.verdict = "VAO PHAI RONG: " .. #g.xinfa .. " tam phap, " .. #g.skills .. " chieu"
        elseif #foreign > 0 then
            row.verdict = "DUNG PHAI nhung nang tam phap NGOAI phai: " .. arr(foreign)
        else
            row.verdict = "DAT"
        end
    end
    local expect_refuse = (want_name == "曼陀" and define.MENPAI_ATTRIBUTE.MATTRIBUTE_MANTUOSHANZHUANG == 16)
    row.ok = (row.verdict == "DAT") or (expect_refuse and tostring(row.verdict):find("^TU CHOI dung") ~= nil)
    if not row.ok then bad = bad + 1 end
    rows[#rows + 1] = row
    print(string.format("%-26s %-6s %-10s %-10s %-26s %-7s %s", label, tostring(row.passed), tostring(row.name_of_passed),
        tostring(row.check_join), row.xinfa and arr(row.xinfa) or "-", tostring(row.skills or "-"), row.verdict))
    if row.error then print("      loi khi chay script: " .. row.error) end
end
print(string.format("TONG: %d NPC, %d KHONG DAT   (goc=%s  script=%s)", #rows, bad, root, script_root))

if json_out then
    local f = assert(io.open(json_out, "w"))
    f:write('{"root":"' .. esc(root) .. '","script_root":"' .. esc(script_root) .. '","bad":' .. bad .. ',"rows":[\n')
    for i, r in ipairs(rows) do
        f:write(string.format('{"npc":"%s","module":"%s","want":"%s","passed":%s,"name_of_passed":"%s","check_join":%s,"reason":"%s","xinfa":%s,"skills":%s,"set_xinfa":%s,"foreign_xinfa":%s,"ok":%s,"verdict":"%s"}%s\n',
            esc(r.npc), esc(r.module), esc(r.want), tostring(r.passed or "null"), esc(r.name_of_passed or ""),
            tostring(r.check_join == true), esc(r.reason or ""), r.xinfa and arr(r.xinfa) or "[]", tostring(r.skills or 0),
            arr(r.set_xinfa or {}), arr(r.foreign_xinfa or {}), tostring(r.ok == true), esc(r.verdict), i < #rows and "," or ""))
    end
    f:write("]}\n"); f:close()
end
os.exit(bad == 0 and 0 or 1)
