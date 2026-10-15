-- Container invariants shared by packet handlers and item operators.
-- No network, database calls or yields: validation completes before mutations.
local M = {}
local starts = {prop=0, material=100, task=200}
local limits = {prop=100, material=100, task=20}

function M.integer(n, low, high)
    return type(n) == 'number' and n == math.floor(n) and n >= low and n <= high
end

function M.accepts(container, index, item)
    if not container or not M.integer(index, 0, 65535) then return false end
    local size = container:get_size()
    if type(size) == 'table' then
        local bag = item and item:get_place_bag()
        if bag then
            return starts[bag] ~= nil and M.integer(size[bag], 0, limits[bag])
                and index >= starts[bag] and index < starts[bag] + size[bag]
        end
        for kind, start in pairs(starts) do
            if index >= start and index < start + (size[kind] or 0) then return true end
        end
        return false
    end
    return M.integer(size, 0, 65536) and index < size
end

function M.resize_ok(container, sizes)
    if type(sizes) ~= 'table' then return false end
    local old = container:get_size()
    for kind, start in pairs(starts) do
        if not M.integer(sizes[kind], 1, limits[kind]) then return false end
        -- Preserve previously quarantined, persisted overflow too. Never erase
        -- an item merely because its expansion equipment is absent/expired.
        for i = start + sizes[kind], start + old[kind] - 1 do
            if container:get_item(i) then return false end
        end
    end
    return true
end

local function same(a, b, depth)
    if type(a) ~= type(b) then return false end
    if type(a) ~= 'table' then return a == b end
    if depth > 16 then return false end
    for k, v in pairs(a) do if not same(v, b[k], depth + 1) then return false end end
    for k in pairs(b) do if a[k] == nil then return false end end
    return true
end

function M.stackable(a, b)
    if not a or not b or a == b or a:is_lock() or b:is_lock()
        or not a:can_lay() or not b:can_lay()
        or a:get_index() ~= b:get_index() or a:is_bind() ~= b:is_bind()
        or a:get_max_tile_count() ~= b:get_max_tile_count() then return false end
    -- A different timer/creator/quality/record must not vanish into a stack.
    local ar, br = a:copy_raw_data(), b:copy_raw_data()
    for _, k in ipairs({'guid','count','lay_count'}) do ar[k]=nil; br[k]=nil end
    -- item.lua keeps count in the packed union too (material/storemap/gem/task).
    for k, pos in pairs({unknow_19=1, unknow_20=1, unknow_22=49, unknow_21=1}) do
        for _, raw in ipairs({ar,br}) do
            if type(raw[k]) == 'table' then
                local copy={};for i,v in pairs(raw[k]) do copy[i]=v end
                copy[pos]=0;raw[k]=copy
            end
        end
    end
    return same(ar, br, 0)
end

function M.swap_ok(bag, from, to)
    local source = M.accepts(bag, from) and bag:get_item(from)
    local dest = M.accepts(bag, to) and bag:get_item(to)
    return from ~= to and source ~= nil and not source:is_lock()
        and (not dest or not dest:is_lock())
        and M.accepts(bag, from, source) and M.accepts(bag, to, source)
        and (not dest or M.accepts(bag, from, dest))
end

-- The pick acknowledgement removes a whole loot row on the client. Only merge
-- when that entire row fits; otherwise the caller must choose an empty slot.
function M.pick_stack_index(bag, item)
    if not item or item:is_lock() then return -1 end
    local kind = item:get_place_bag()
    for pos, dest in bag:ipairs(kind) do
        if M.stackable(item, dest)
            and item:get_lay_count() + dest:get_lay_count() <= dest:get_max_tile_count() then
            return pos
        end
    end
    return -1
end

-- Sort only the selected CY region; keep every GUID, attribute and stack size.
-- Deliberately does not merge stacks with potentially different metadata.
function M.pack(bag, tab)
    if not M.integer(tab, 0, 2) then return false end
    local kind = ({'prop','material','task'})[tab+1]
    local first, size = starts[kind], bag:get_size()[kind]
    local rows = {}
    for i = first, first + size - 1 do
        local item = bag:get_item(i)
        if item then
            if item:is_lock() or not M.accepts(bag, i, item) then return false end
            rows[#rows+1] = {item=item, pos=i}
        end
    end
    table.sort(rows, function(a,b)
        if a.item:get_index() ~= b.item:get_index() then return a.item:get_index() < b.item:get_index() end
        if a.item:is_bind() ~= b.item:is_bind() then return a.item:is_bind() end
        return a.pos < b.pos
    end)
    for i = first, first + size - 1 do bag:set_item(i, nil) end
    for i, row in ipairs(rows) do bag:set_item(first + i - 1, row.item) end
    return true
end

return M
