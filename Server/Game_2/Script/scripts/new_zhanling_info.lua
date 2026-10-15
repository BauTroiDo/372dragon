local common_rewards = {
    [2] = { need_point = 800, item_id = 38002625, item_count = 10, is_bind = true },
    [3] = { need_point = 1200, item_id = 20310168, item_count = 15, is_bind = true },
    [4] = { need_point = 1600, item_id = 20310168, item_count = 15, is_bind = true },
    [5] = { need_point = 2000, item_id = 20310168, item_count = 20, is_bind = true },
    [6] = { need_point = 2400, item_id = 20501003, item_count = 1, is_bind = true },
    [7] = { need_point = 2800, item_id = 38002625, item_count = 10, is_bind = true },
    [8] = { need_point = 3200, item_id = 30900006, item_count = 6, is_bind = true },
    [9] = { need_point = 3600, item_id = 30900006, item_count = 7, is_bind = true },
    [10] = { need_point = 4000, item_id = 30900045, item_count = 1, is_bind = true },
    [11] = { need_point = 4400, item_id = 20502003, item_count = 1, is_bind = true },
    [12] = { need_point = 4800, item_id = 38002625, item_count = 10, is_bind = true },
    [13] = { need_point = 5200, item_id = 20600002, item_count = 2, is_bind = true },
    [14] = { need_point = 5600, item_id = 38003165, item_count = 1, is_bind = true },
    [15] = { need_point = 6000, item_id = 38002818, item_count = 1, is_bind = true },
    [16] = { need_point = 6400, item_id = 38002676, item_count = 1, is_bind = true },
    [17] = { need_point = 6800, item_id = 38002625, item_count = 10, is_bind = true },
    [18] = { need_point = 7200, item_id = 38002533, item_count = 10, is_bind = true },
    [19] = { need_point = 7600, item_id = 38002533, item_count = 12, is_bind = true },
    [20] = { need_point = 8000, item_id = 38002675, item_count = 1, is_bind = true },
}

local period_definitions = {
    { 20251201, 20251228, 38002135 },
    { 20251229, 20260125, 38002140 },
    { 20260126, 20260222, 38002141 },
    { 20260223, 20260322, 38002142 },
    { 20260323, 20260419, 38002143 },
    { 20260420, 20260517, 38002144 },
    { 20260518, 20260614, 38003167 },
    { 20260615, 20260712, 38003168 },
    { 20260713, 20260809, 38003169 },
    { 20260810, 20260906, 38003170 },
    { 20260907, 20261004, 38002136 },
    { 20261005, 20261101, 38002137 },
    { 20261102, 20261129, 38002134 },
    { 20261130, 20261227, 38002135 },
    { 20261228, 20270124, 38002140 },
    { 20270125, 20290101, 38002141 },
}

local periods = {}
for _, definition in ipairs(period_definitions) do
    local rewards = {
        [1] = {
            need_point = 400,
            item_id = definition[3],
            item_count = 1,
            is_bind = true,
        },
    }
    for level, reward in pairs(common_rewards) do
        rewards[level] = reward
    end
    periods[#periods + 1] = {
        begin_date = definition[1],
        end_date = definition[2],
        rewards = rewards,
    }
end

return periods
