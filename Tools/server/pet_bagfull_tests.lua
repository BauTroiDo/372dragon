-- Kiểm NGOẠI TUYẾN ba hàm trân thú của `services/scene/obj/human.lua` sau bản vá `pet_bagfull.py`.
-- KHÔNG cần server, KHÔNG làm hỏng scene nào: rút đúng ba hàm ra khỏi file thật rồi nạp bằng `load`
-- với một `human` giả, một container giả hành xử như `item_container` (`get_empty_item_index`,
-- `cal_item_space`) và các hàm gửi gói được ghi lại thay vì gửi đi.
--
--   lua5.4 Tools/server/pet_bagfull_tests.lua <duong-dan-human.lua>
--
-- Mong đợi:
--   1. Túi thú CÒN CHỖ  -> capture_pet trả true, thú vào ô trống, không notify_tips, không lỗi.
--   2. Túi thú ĐẦY      -> capture_pet trả false, KHÔNG ném lỗi, có notify_tips,
--                          send_operate_result_msg = OR_BAG_OUT_OF_SPACE (-15), túi không đổi.
--   3. add_pet túi đầy  -> trả false (lưới an toàn cuối cho mọi người gọi), không ném lỗi.
--   4. add_pet_by_data_id túi đầy -> trả false (trước bản vá luôn trả true).

local target = ...
if not target then
    io.stderr:write('can duong dan toi services/scene/obj/human.lua\n')
    os.exit(2)
end

local src = assert(io.open(target, 'rb')):read('a')

-- ------------------------------------------------------------------ rút hàm
local function grab(name)
    local pat = '\nfunction human:' .. name .. '%(.-\nend\n'
    local chunk = src:match(pat)
    if not chunk then
        io.stderr:write('khong tim thay function human:' .. name .. '\n')
        os.exit(3)
    end
    return chunk
end

local body = grab('add_pet') .. grab('add_pet_by_data_id') .. grab('capture_pet')

-- ------------------------------------------------------------------ môi trường giả
local log = { tips = {}, results = {}, sent = 0, added = 0 }

local function new_container(size, filled)
    local c = { size = size, items = {} }
    for i = 0, filled - 1 do c.items[i] = { fake = true } end
    function c:get_size() return self.size end
    function c:get_empty_item_index()
        for i = 0, self.size - 1 do
            if self.items[i] == nil then return i end
        end
        return -1                                   -- define.INVAILD_ID
    end
    function c:cal_item_space()
        local n = 0
        for i = 0, self.size - 1 do
            if self.items[i] == nil then n = n + 1 end
        end
        return n
    end
    function c:set_item(i, v) self.items[i] = v end
    function c:count()
        local n = 0
        for i = 0, self.size - 1 do
            if self.items[i] ~= nil then n = n + 1 end
        end
        return n
    end
    return c
end

local function new_human(size, filled)
    local h = { container = new_container(size, filled) }
    function h:get_pet_bag_container() return self.container end
    function h:get_guid() return 200015 end
    function h:notify_tips(text) table.insert(log.tips, text) end
    function h:send_operate_result_msg(code) table.insert(log.results, code) end
    function h:send_pets_detail() log.sent = log.sent + 1 end
    function h:on_add_pet() log.added = log.added + 1 end
    return h
end

local function new_pet(owner)
    local p = { detail = { attrib = { guid = { m_uHighSection = 200015, m_uLowSection = 42 } } } }
    function p:get_owner() return owner end
    function p:get_detail() return self.detail end
    return p
end

-- upvalue mà ba hàm dùng
local env = setmetatable({
    human = nil,                                     -- đặt lại cho mỗi ca
    define = {
        INVAILD_ID = -1,
        OPERATE_RESULT = { OR_INVALID_TARGET = -8, OR_BAG_OUT_OF_SPACE = -15 },
    },
    skynet = { loge = function() end, now = function() return 12345 end },
    petmanager = {
        create_guid_of_pet = function() return true end,
        -- add_pet_by_data_id gọi hàm này trước add_pet; ở đây chỉ cần nó không nổ.
        make_capture_pet_attrib = function() end,
    },
    pet_guid = { new = function()
        local g = { m_uHighSection = 0, m_uLowSection = 0 }
        function g:set(h, l) self.m_uHighSection = h; self.m_uLowSection = l end
        return g
    end },
    pet_detail = { new = function()
        local d = { attrib = { guid = { m_uHighSection = 200015, m_uLowSection = 7 } } }
        function d:init_from_data() end
        function d:get_attrib(k) return self.attrib[k] end
        return d
    end },
}, { __index = _G })

-- get_attrib cho pet_detail của add_pet
local function attach(pet)
    if type(pet) == 'table' and not pet.get_attrib then
        pet.attrib = pet.attrib or { guid = { m_uHighSection = 200015, m_uLowSection = 42 } }
        function pet:get_attrib(k) return self.attrib[k] end
    end
    return pet
end

local fails, checks = 0, 0
local function check(cond, what)
    checks = checks + 1
    if not cond then
        fails = fails + 1
        io.write('FAIL  ', what, '\n')
    else
        io.write('PASS  ', what, '\n')
    end
end

local function load_case(size, filled)
    log.tips, log.results, log.sent, log.added = {}, {}, 0, 0
    env.human = {}
    local chunk = assert(load(body, '@human-pet-fns', 't', env))
    chunk()
    local h = new_human(size, filled)
    setmetatable(h, { __index = env.human })
    return h
end

-- ---------------------------------------------------------------- ca 1: còn chỗ
do
    local h = load_case(3, 1)
    local pet = new_pet(nil)
    attach(pet.detail)
    local ok, res = pcall(function() return h:capture_pet({}, pet) end)
    check(ok, 'ca 1 tui con cho: capture_pet KHONG nem loi')
    check(ok and res == true, 'ca 1: capture_pet tra true')
    check(h.container:count() == 2, 'ca 1: thu da vao tui (1 -> 2)')
    check(#log.tips == 0, 'ca 1: khong co notify_tips')
end

-- ---------------------------------------------------------------- ca 2: túi đầy
do
    local h = load_case(3, 3)
    local pet = new_pet(nil)
    attach(pet.detail)
    local ok, res = pcall(function() return h:capture_pet({}, pet) end)
    check(ok, 'ca 2 tui DAY: capture_pet KHONG nem loi (truoc ban va: assert)')
    check(ok and res == false, 'ca 2: capture_pet tra false')
    check(#log.tips == 1, 'ca 2: co notify_tips cho nguoi choi')
    check(log.results[1] == -15, 'ca 2: gui OR_BAG_OUT_OF_SPACE (-15), thay vi -15 nhan duoc ' .. tostring(log.results[1]))
    check(h.container:count() == 3, 'ca 2: tui khong doi')
end

-- ---------------------------------------------------------------- ca 3: add_pet trực tiếp
do
    local h = load_case(2, 2)
    local ok, res = pcall(function() return h:add_pet(attach({})) end)
    check(ok, 'ca 3 add_pet tui DAY: KHONG nem loi')
    check(ok and res == false, 'ca 3: add_pet tra false')
end

-- ---------------------------------------------------------------- ca 4: add_pet_by_data_id
do
    local h = load_case(2, 2)
    local ok, res = pcall(function() return h:add_pet_by_data_id(3009, true, nil, nil) end)
    if not ok then io.write('      loi: ', tostring(res), '\n') end
    check(ok, 'ca 4 add_pet_by_data_id tui DAY: KHONG nem loi')
    check(ok and res == false, 'ca 4: tra false (truoc ban va luon tra true)')
end

io.write(string.format('RESULT checks=%d failed=%d status=%s\n', checks, fails, fails == 0 and 'PASS' or 'FAIL'))
os.exit(fails == 0 and 0 or 1)
