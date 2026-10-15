-- Pure CY rules. Tables are supplied by the runtime config service, not copied
-- from client input. No mutations occur until a complete plan is returned.
local M = {}
function M.integer(n, lo, hi)
    return type(n) == 'number' and n == math.floor(n) and n >= lo and n <= hi
end

function M.points(manual, remaining)
    if type(manual) ~= 'table' or not M.integer(remaining, 0, 2147483647) then return nil end
    local total = 0
    for _, key in ipairs({'str','con','dex','spr','int'}) do
        local n = manual[key .. '_increment'] or 0
        if not M.integer(n, 0, remaining) then return nil end
        total = total + n
    end
    return total <= remaining and total or nil
end

-- The two player-controlled slots precede ten automatic slots in GC512.
-- Group identity/operate mode come from SkillTemplate, probabilities from CY
-- PetStudySkllTable. A missing table row is an error, never free success.
function M.study(pet, skillid, template_of, study_rows, need_owner, random)
    local wanted = template_of(skillid)
    if not wanted then return nil end
    for i = 0, 11 do
        if pet:get_skill_by_index(i) == skillid then return nil end
    end
    local manual = wanted.operate_mode == need_owner
    local first, last = manual and 0 or 2, manual and 1 or 11
    local empty, occupied = {}, {}
    for i = first, last do
        local id = pet:get_skill_by_index(i)
        if not id or id == -1 then
            empty[#empty + 1] = i
        else
            occupied[#occupied + 1] = i
            local old = template_of(id)
            if not old then return nil end -- retain unknown legacy data
            if old.group_id == wanted.group_id then return i, false end
        end
    end
    if manual then return empty[1], #occupied == 1 end
    local row
    for _, candidate in pairs(study_rows or {}) do
        if candidate.max_skill_count == 10 and candidate.non_skill_count == #empty then
            row = candidate; break
        end
    end
    if not row or not M.integer(row.odd, 0, 1000) then return nil end
    local draw = random(1000)
    if draw <= row.odd and #empty > 0 then return empty[1], false end
    if #occupied == 0 then return nil end
    return occupied[random(#occupied)], false
end

function M.lingxing_row(rows, main_perception)
    if type(main_perception) ~= 'number' then return nil end
    for _, row in ipairs(rows or {}) do
        if row[1] <= main_perception and main_perception < row[2] then return row end
    end
end
function M.lingxing_bonus(rows, main_perception, encoded_level)
    if not M.integer(encoded_level, 101, 110) then return 0 end
    local row = M.lingxing_row(rows, main_perception)
    return row and row[2 + encoded_level - 100] or 0
end
function M.lingxing_chance(rows, main_perception, current_level)
    if not M.integer(current_level, 0, 9) then return nil end
    local row = M.lingxing_row(rows, main_perception)
    return row and row[13 + current_level] or nil
end

return M
