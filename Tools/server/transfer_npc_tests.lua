-- Kiểm NGOẠI TUYẾN script NPC dịch chuyển `scripts/chuan_song_system.lua` (script_id 990010).
-- Không cần server: stub `script_base`, `skynet`, `define`, `class`, rồi so menu và lệnh
-- truyền tống với bảng mong đợi.
--
--   lua5.4 Tools/server/transfer_npc_tests.lua <duong-dan-chuan_song_system.lua>
--
-- Mong đợi lấy từ hành vi ĐÃ ĐO LIVE ngày 17/09 (Build/Logs/2026-09-17-transfer-npc):
--   崔逢九 (Đại Lý)  -> menu KHÔNG có 1010;   chọn 1001 -> TransferFunc(0, 235, 322, 10)
--   吴德昌 (Lạc Dương) -> menu KHÔNG có 1001/1006; chọn 1002 -> TransferFunc(1, 204, 256, 10)
--   李乘风 (Tô Châu) -> menu KHÔNG có 1002/1007; chọn 1010 -> TransferFunc(2, 253, 121, nil)

local target = ...
if not target then
    io.stderr:write('can duong dan toi chuan_song_system.lua\n')
    os.exit(2)
end

-- ------------------------------------------------------------------ stub
local running = {}          -- tập cảnh "đang chạy" cho lượt kiểm hiện tại
local calls, tips, menu     -- ghi lại thứ script làm

package.preload['wire_charset'] = function()
    return { fromutf8 = function(s) return s end, toutf8 = function(s) return s end }
end
package.preload['define'] = function()
    return { MENPAI_ATTRIBUTE = { MATTRIBUTE_ERENGU = 1, MATTRIBUTE_MANTUOSHANZHUANG = 2,
        MATTRIBUTE_GUSU = 3, MATTRIBUTE_XINGXIU = 4, MATTRIBUTE_XIAOYAO = 5, MATTRIBUTE_SHAOLIN = 6,
        MATTRIBUTE_TIANSHAN = 7, MATTRIBUTE_DALI = 8, MATTRIBUTE_EMEI = 9, MATTRIBUTE_WUDANG = 10,
        MATTRIBUTE_MINGJIAO = 11, MATTRIBUTE_GAIBANG = 12 } }
end
package.preload['scripts.ScriptGlobal'] = function()
    return { MD_CHANGE_POINTCOUNT = 1 }
end
package.preload['skynet'] = function()
    return { localname = function(name)
        local id = tonumber(name:match('^%.SCENE_(%-?%d+)$'))
        return (id and running[id]) and ('addr' .. id) or nil
    end }
end

local script_base = {}
script_base.__index = script_base
function script_base:GetName(id) return self._names[id] end
function script_base:get_scene_id() return self._scene end
function script_base:BeginEvent(sid) menu = { script = sid, texts = {}, nums = {} } end
function script_base:AddText(t) table.insert(menu.texts, t) end
function script_base:AddNumText(t, ty, idx) table.insert(menu.nums, { text = t, type = ty, index = idx }) end
function script_base:EndEvent() end
function script_base:DispatchEventList() end
function script_base:notify_tips(_, t) table.insert(tips, t) end
function script_base:GetMissionData() return 0 end
function script_base:GetMenPai() return 0 end
function script_base:LuaFnGetDestSceneHumanCount(scene) return self._human[scene] or 0 end
function script_base:CallScriptFunction(sid, fn, ...)
    table.insert(calls, { script = sid, func = fn, args = { ... } })
    return 0
end
package.preload['script_base'] = function() return script_base end

package.preload['class'] = function()
    return function(_, base)
        local c = {}
        c.__index = c
        setmetatable(c, { __index = base })
        return c
    end
end

-- ------------------------------------------------------------------ nạp script thật
local chunk, err = loadfile(target)
if not chunk then
    io.stderr:write('khong nap duoc: ' .. tostring(err) .. '\n')
    os.exit(2)
end
local CSS = chunk()

local function instance(npcName, sceneId, humans)
    local o = setmetatable({}, CSS)
    o.script_id = 990010
    o._names = { [7] = npcName }
    o._scene = sceneId
    o._human = humans or {}
    return o
end

local function reset()
    calls, tips, menu = {}, {}, nil
end

local function indexes()
    local t = {}
    for _, e in ipairs(menu.nums) do table.insert(t, e.index) end
    return t
end

local function has(list, v)
    for _, x in ipairs(list) do if x == v then return true end end
    return false
end

local fails, checks = 0, 0
local function ok(cond, what)
    checks = checks + 1
    if not cond then
        fails = fails + 1
        print('FAIL  ' .. what)
    else
        print('ok    ' .. what)
    end
end

local function join(list)
    local t = {}
    for _, v in ipairs(list) do table.insert(t, tostring(v)) end
    return table.concat(t, ',')
end

-- ------------------------------------------------------------------ 1. menu của từng NPC
-- 5 thành + 汴京 755 + 唐家堡 495 đang chạy; 186/420/1349 (楼兰/束河/昆吾) tắt.
running = { [0] = true, [1] = true, [2] = true, [495] = true, [755] = true, [1007] = true }

local cases = {
    { npc = '崔逢九',  scene = 2,   thieu = { 1010 },       co = { 1001, 1002, 1020, 1021, 1022, 1006, 1007 } },
    { npc = '吴德昌',  scene = 0,   thieu = { 1001, 1006 }, co = { 1002, 1010, 1020, 1021, 1022, 1007 } },
    { npc = '汪旱',    scene = 0,   thieu = { 1001, 1006 }, co = { 1002, 1010, 1020, 1021, 1022, 1007 } },
    { npc = '李乘风',  scene = 1,   thieu = { 1002, 1007 }, co = { 1001, 1010, 1020, 1021, 1022, 1006 } },
    { npc = '邓茂',    scene = 1,   thieu = { 1002, 1007 }, co = { 1001, 1010, 1020, 1021, 1022, 1006 } },
    { npc = '冰小舞',  scene = 1007, thieu = { 1021 },       co = { 1001, 1002, 1010, 1020, 1022, 1006, 1007 } },
    { npc = '唐松',    scene = 755, thieu = { 1020 },       co = { 1001, 1002, 1010, 1021, 1022, 1006, 1007 } },
    { npc = '唐予诚',  scene = 495, thieu = { 1022 },       co = { 1001, 1002, 1010, 1020, 1021, 1006, 1007 } },
}
for _, c in ipairs(cases) do
    reset()
    instance(c.npc, c.scene):OnDefaultEvent(1, 7)
    local idx = indexes()
    for _, v in ipairs(c.thieu) do ok(not has(idx, v), c.npc .. ': menu KHONG co ' .. v) end
    for _, v in ipairs(c.co) do ok(has(idx, v), c.npc .. ': menu co ' .. v) end
    ok(has(idx, 1000) and has(idx, 1012), c.npc .. ': van co 1000 + 1012')
    ok(not has(idx, 1011) and not has(idx, 1014) and not has(idx, -999),
       c.npc .. ': an 1011/1014/-999 vi canh dang tat')
    ok(#menu.nums + #menu.texts <= 16, c.npc .. ': <= 16 muc goi (' .. (#menu.nums + #menu.texts) .. ')')
    ok(#menu.nums >= 1, c.npc .. ': menu = [' .. join(idx) .. ']')
end

-- ------------------------------------------------------------------ 2. lệnh truyền tống
local want = {
    { npc = '崔逢九', scene = 2,   index = 1001, args = { 0, 235, 322, 10 } },
    { npc = '崔逢九', scene = 2,   index = 1002, args = { 1, 204, 256, 10 } },
    { npc = '崔逢九', scene = 2,   index = 1021, args = { 1007, 160, 290, 10 } },
    { npc = '崔逢九', scene = 2,   index = 1020, args = { 755, 530, 937, 10 } },
    { npc = '崔逢九', scene = 2,   index = 1022, args = { 495, 126, 68, 10 } },
    { npc = '吴德昌', scene = 0,   index = 1010, args = { 2, 253, 121 } },
    { npc = '吴德昌', scene = 0,   index = 1007, args = { 1, 335, 225, 10 } },
    { npc = '李乘风', scene = 1,   index = 1006, args = { 0, 326, 269, 10 } },
    { npc = '冰小舞', scene = 1007, index = 1010, args = { 2, 253, 121 } },
    { npc = '唐松',   scene = 755, index = 1021, args = { 1007, 160, 290, 10 } },
    { npc = '唐予诚', scene = 495, index = 1020, args = { 755, 530, 937, 10 } },
}
for _, w in ipairs(want) do
    reset()
    instance(w.npc, w.scene):OnEventRequest(1, 7, 0, w.index)
    local c = calls[1]
    local good = c and c.script == 400900 and c.func == 'TransferFunc' and c.args[1] == 1
    if good then
        for i, v in ipairs(w.args) do good = good and c.args[i + 1] == v end
        good = good and c.args[#w.args + 2] == nil
    end
    ok(good, string.format('%s chon %d -> TransferFunc(%s)%s', w.npc, w.index, join(w.args),
        good and '' or ('  [thuc te: ' .. (c and (c.func .. '(' .. join(c.args) .. ')') or 'khong goi gi') .. ']')))
end

-- ------------------------------------------------------------------ 3. cảnh tắt thì không truyền
reset()
running = { [0] = true, [1] = true, [2] = true }     -- 1007 tat
instance('崔逢九', 2):OnDefaultEvent(1, 7)
ok(not has(indexes(), 1021), 'canh 1007 tat -> menu khong co 1021')
reset()
instance('崔逢九', 2):OnEventRequest(1, 7, 0, 1021)
ok(#calls == 0 and #tips == 1, 'canh 1007 tat -> khong TransferFunc, chi bao tips')

-- ------------------------------------------------------------------ 4. ngưỡng số người của 1001
reset()
running = { [0] = true, [1] = true, [2] = true, [495] = true, [755] = true, [1007] = true }
local o = instance('崔逢九', 2, { [0] = 700 })
o:OnEventRequest(1, 7, 0, 1001)
ok(#calls == 0 and #tips == 1, 'canh 0 du 700 nguoi -> chi bao tips, khong TransferFunc')

-- ------------------------------------------------------------------ 5. các nhánh cũ còn nguyên
reset()
instance('崔逢九', 2):OnEventRequest(1, 7, 0, 2001)
ok(calls[1] and calls[1].args[2] == 1311, 'muc cu 2001 -> canh 1311 giu nguyen')
reset()
instance('崔逢九', 2):OnEventRequest(1, 7, 0, 3011)
ok(calls[1] and calls[1].args[2] == 71, 'muc cu 3011 -> canh 71 giu nguyen')
reset()
instance('崔逢九', 2):OnEventRequest(1, 7, 0, 1012)
ok(menu and #menu.nums == 12, 'muc 1012 -> van liet ke 12 mon phai')
reset()
instance('崔逢九', 2):OnEventRequest(1, 7, 0, 1000)
ok(#tips == 1, 'muc 1000 khi chua vao mon phai -> bao "Ban chua vao mon phai."')

-- ------------------------------------------------------------------ 6. 恶人谷 da doi 1063 -> 987
-- g_mpInfo[1] = Ac Nhan Coc; mục 1012 liệt kê theo chỉ số, chọn 1 = đi Ác Nhân Cốc.
reset()
instance('崔逢九', 2):OnEventRequest(1, 7, 0, 1)
local c = calls[1]
ok(c and c.func == 'TransferFunc' and c.args[2] == 987 and c.args[3] == 125 and c.args[4] == 152,
   'mon phai 1 (Ac Nhan Coc) -> canh 987 (khong con 1063)')
reset()
instance('崔逢九', 2):OnEventRequest(1, 7, 0, 3)
c = calls[1]
ok(c and c.args[2] == 1358, 'mon phai 3 (Mo Dung Son Trang) van la canh 1358')

-- ------------------------------------------------------------------ 7. chia trang khi menu dai
-- Bat HET moi canh dich trong g_Cities (ke ca 186/420/1349) -> 11 muc, 崔逢九 chua 2 cho cho
-- OnEnumerate nen ngan sach chi con 16-3-2 = 11 => vua du MOT trang, chua co "Trang sau".
reset()
running = {}
for _, s in ipairs({ 0, 1, 2, 186, 420, 495, 755, 1007, 1349 }) do running[s] = true end
local o2 = instance('崔逢九', 2)
o2:OnDefaultEvent(1, 7)
local n1 = #menu.nums + #menu.texts
ok(n1 <= 16, 'menu day du o 崔逢九: ' .. n1 .. ' muc <= 16')
local hasNext = false
for _, e in ipairs(menu.nums) do if e.index > 1900 then hasNext = true end end
ok(not hasNext, '11 muc vua ngan sach cua 崔逢九 -> chua can "Trang sau"')

-- NPC khac khong bi tru 2 cho, nhung neu bang dai hon ngan sach thi phai co "Trang sau".
-- Gia lap bang dai: them 6 dong tam vao g_Cities qua chinh doi tuong menu la khong duoc, nen
-- kiem bang cach ha ngan sach: dung 崔逢九 va bat them canh -> da phu o tren. Thay vao do kiem
-- rang mục "Trang sau" dung dan duoc xu ly khi client gui len.
reset()
o2 = instance('吴德昌', 0)
o2:OnEventRequest(1, 7, 0, 1902)
ok(menu ~= nil and #calls == 0,
   'muc "Trang sau" (1902) dung lai menu, KHONG goi TransferFunc')
reset()
o2 = instance('吴德昌', 0)
o2:OnEventRequest(1, 7, 0, 1901)
local idx2 = indexes()
ok(#idx2 > 0 and has(idx2, 1000) and has(idx2, 1012), 'trang 1 (1901) van co 1000 + 1012')

-- Bang that chi co 11 dong nen chua bao gio tran; ep tran bang cach thay VisibleCities cua
-- MOT the hien (day la ly do BuildCityMenu goi self:VisibleCities chu khong lap thang g_Cities).
local N = 30
local fake = {}
for i = 1, N do fake[i] = { index = 3000 + i, text = 'thanh ' .. i, scene = 9000 + i, x = 1, z = 1 } end
local paged = instance('吴德昌', 0)
paged.VisibleCities = function() return fake end
paged.SceneRunning = function() return true end
local seen, guard, page = {}, 0, 1
repeat
    reset()
    paged:BuildCityMenu(1, 7, page)
    local tong = #menu.nums + #menu.texts
    ok(tong <= 16, string.format('bang %d thanh, trang %d: %d muc <= 16', N, page, tong))
    local nxt = nil
    for _, e in ipairs(menu.nums) do
        if e.index > 3000 and e.index <= 3000 + N then
            ok(seen[e.index] == nil, 'thanh ' .. e.index .. ' chi xuat hien mot lan')
            seen[e.index] = true
        elseif e.index > 1900 and e.index <= 1999 then
            nxt = e.index - 1900
        end
    end
    guard = guard + 1
    page = nxt
until page == 1 or page == nil or guard > 10
local du = 0
for i = 1, N do if seen[3000 + i] then du = du + 1 end end
ok(du == N, string.format('di het %d trang thi thay du %d/%d thanh', guard, du, N))
ok(guard >= 3, 'bang ' .. N .. ' thanh phai chia >= 3 trang (thuc te ' .. guard .. ')')

print(string.format('\n%d/%d ok', checks - fails, checks))
os.exit(fails == 0 and 0 or 1)
