-- CY study request: the stored level is authoritative; a repeated packet cannot
-- buy an old level again or grant skills from an unowned/foreign xinfa.
local M = {}
local MAX_LEVEL = 119 -- CY SendStudySkillEvent; client CysSkillNet::CYS_XINFA_MAX_LEVEL

function M.handle(scene, me, req, configs, packets)
    local human = scene.objs[me]
    if not human or not human.get_xinfa or type(req) ~= "table" then return false end
    local id = req.xinfa
    if type(id) ~= "number" or id % 1 ~= 0 then return false end
    local owned = human:get_xinfa(id)
    local config = configs:get_config("xinfa_v1")[id]
    if not owned or not config or config.menpai ~= human:get_menpai() then
        human:notify_tips("Bạn chưa học tâm pháp này hoặc không đúng môn phái.")
        return false
    end
    local level = owned.m_nXinFaLevel
    local msg = packets.GCStudyXinfa.new()
    msg.xinfa, msg.now_level = id, level
    local function reply()
        msg.spare_exp, msg.spare_money = human:get_exp(), human:get_money()
        scene:send2client(human, msg)
    end
    if req.now_level ~= level then reply(); return false end
    if type(level) ~= "number" or level < 1 or level >= MAX_LEVEL or level % 1 ~= 0 then
        human:notify_tips("Tâm pháp đã đạt giới hạn cấp học.")
        reply(); return false
    end
    local row = configs:get_config("xinfa_study_speed_v1")[level + 1]
    local exp = row and row.cost_exp and tonumber(row.cost_exp[id + 1])
    local money = row and row.cost_money and tonumber(row.cost_money[id + 1])
    if not exp or not money or exp < 0 or money < 0 or exp % 1 ~= 0 or money % 1 ~= 0 then
        human:notify_tips("Chưa có dữ liệu chi phí hợp lệ cho cấp tâm pháp tiếp theo.")
        reply(); return false
    end
    if human:get_exp() < exp or not human:check_money_with_priority(money) then reply(); return false end
    human:set_exp(human:get_exp() - exp)
    human:cost_money_with_priority(money, "心法学习")
    human:study_xinfa(id, level + 1)
    msg.now_level = level + 1
    reply()
    return true
end

return M
