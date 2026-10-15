-- [FIX] std_talent_771: 断臂渡生（峨嵋武道771）
-- 激活时注册主动技能5386（断臂渡生），移除时删除
-- 技能5386 logic_id=269，释放后对自身施加StdImpact010护盾
local class = require "class"
local base = require "scene.skill.talent_logic.base"
local std_talent_771 = class("std_talent_771", base)
local skill_id = 5386 -- [FIX] 断臂渡生主动技能ID

-- [FIX] 武道激活时给玩家添加技能5386
function std_talent_771:on_active(talent, level, human)
    if not human:have_skill(skill_id) then
        human:add_skill(skill_id)
        human:send_skill_list()
    end
end

-- [FIX] 武道移除时删除技能5386
function std_talent_771:on_remove(talent, level, human)
    if human:have_skill(skill_id) then
        human:del_skill(skill_id)
    end
end

-- [FIX] 注册附加主动技能5386
function std_talent_771:get_add_skill()
    return skill_id
end

return std_talent_771
