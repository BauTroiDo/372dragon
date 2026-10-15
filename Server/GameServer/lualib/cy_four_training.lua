-- Training is committed in the character service; no yielding calls between
-- checking balances and changing the learned level. Existing DB fields persist it.
local config = require "cy_four_training_config"
local engine = require "configenginer":getinstance()
local define = require "define"
local M = {}

local function integer(v, lo, hi)
    return type(v) == "number" and v == math.floor(v) and v >= lo and v <= hi
end

function M.quote(human, faction, kind, id)
    local school = config.factions[faction]
    if not school or human:get_menpai() ~= faction then
        return nil, "Ta chỉ truyền dạy cho đệ tử bổn phái."
    end
    if kind == "qinggong" then
        if id ~= school.qinggong then return nil, "Kỹ năng không hợp lệ." end
        if human:have_skill(id) then return nil, "Bạn đã học khinh công này." end
        if #human:get_total_skills_list() >= 127 then return nil, "Danh sách kỹ năng đã đầy." end
        if human:get_level() < 10 then return nil, "Bạn cần đạt cấp 10." end
        return {kind=kind, id=id, previous=0, level=1, name="Khinh công "..school.name,
            money=define.STUDY_MENPAI_QINGGONG_SPEND, exp=0}
    end
    if kind ~= "ability" then return nil, "Nội dung học không hợp lệ." end
    local selected
    for _, row in ipairs(school.abilities) do if row.id == id then selected = row end end
    if not selected then return nil, "Nghề không thuộc môn phái của bạn." end
    local current = human:get_ability(id)
    local previous = current and current.level or 0
    if not integer(previous, 0, selected.max_level) then return nil, "Cấp nghề không hợp lệ." end
    if previous >= selected.max_level then return nil, "Nghề này đã đạt cấp tối đa." end
    local costs = engine:get_config(selected.cost_table)
    local row = costs and costs[previous + 1]
    if not row then return nil, "Chưa có dữ liệu cho cấp nghề tiếp theo." end
    local money, exp = row["需求金钱"], row["需求经验"]
    local minimum, proficiency = row["等级限制"], row["技能熟练度限制"]
    if not integer(money,0,2147483647) or not integer(exp,0,2147483647)
        or not integer(minimum,0,1000) or not integer(proficiency,0,2147483647) then
        return nil, "Dữ liệu chi phí nghề không hợp lệ."
    end
    minimum = math.max(10, minimum) -- membership and existing donor training minimum
    if human:get_level() < minimum then return nil, "Bạn cần đạt cấp "..minimum.."." end
    if (current and current.exp or 0) < proficiency then return nil, "Độ thành thạo nghề chưa đủ." end
    return {kind=kind,id=id,previous=previous,level=previous+1,name=selected.name,money=money,exp=exp}
end

function M.perform(human, faction, kind, id, previous)
    local q, reason = M.quote(human, faction, kind, id)
    if not q then return false, reason end
    if q.previous ~= previous then return false, "Cấp đã thay đổi, hãy mở lại menu học." end
    if human:get_money() + human:get_jiaozi() < q.money then return false, "Bạn không đủ tiền và giao tử." end
    if human:get_exp() < q.exp then return false, "Bạn không đủ kinh nghiệm." end
    if q.money > 0 then human:cost_money_with_priority(q.money, "CY4 faction training") end
    if q.exp > 0 then human:set_exp(human:get_exp() - q.exp) end
    if kind == "ability" then
        human:study_ability(id, 0, q.level)
        require("cy_four_crafting").learn(human, faction)
    else
        human:add_skill(id)
        human:del_skill(34) -- replace the basic jump, as the legacy faction teachers do
        human:send_skill_list()
    end
    return true, "Đã học "..q.name.." cấp "..q.level.."."
end

return M
