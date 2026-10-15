-- server-impact: test Lua đơn vị (lua5.4) cho logic impact CY mới + skill_cy_generic, không cần skynet.
--   lua5.4 Tools/server/server_impact_tests.lua <gốc_server_riêng> [<gốc_lua_staging>]
-- Module thật nạp từ <gốc_lua_staging>/GameServer (nếu có) rồi <gốc_server_riêng>/GameServer; skynet/actionenginer/game.packet/define/
-- impactenginer/skill_0 được giả lập. Thoát 0 khi mọi test đạt.
local root = assert(arg[1], "cần đường dẫn gốc server riêng")
local staging = arg[2]
local paths = {}
for _, r in ipairs(staging and {staging, root} or {root}) do
    paths[#paths + 1] = r .. "/GameServer/lualib/?.lua"
    paths[#paths + 1] = r .. "/GameServer/services/?.lua"
end
package.path = table.concat(paths, ";") .. ";" .. package.path

-- ---------------------------------------------------------------- giả lập
package.preload["skynet"] = function() return {error = print, logi = print, loge = print, logd = function() end} end
package.preload["actionenginer"] = function() return {getinstance = function() return {} end} end
package.preload["game.packet"] = function() return {} end
package.preload["define"] = function()
    return {INVAILD_ID = -1, ENUM_BEHAVIOR_TYPE = {BEHAVIOR_TYPE_HOSTILITY = -1, BEHAVIOR_TYPE_NEUTRALITY = 0, BEHAVIOR_TYPE_AMITY = 1},
            MISS_FLAG = {FLAG_ABSORB = 3}, MissFlag_T = {FLAG_IMMU = 2}}
end
local ENGINE = {std_impact_config = {}, sent = {}, collections = {}}
function ENGINE:get_data_by_data_index(i) return self.std_impact_config[i] end
function ENGINE:init_impact_from_data(i, imp)
    local d = self.std_impact_config[i]
    if not d then return false end
    imp.data_index = i
    imp.params = {}
    return true
end
function ENGINE:is_impact_in_collection(imp, c) return self.collections[c] and self.collections[c][imp.data_index] or false end
function ENGINE:send_impact_to_unit(rec, i, sender) self.sent[#self.sent + 1] = {rec = rec, id = i, sender = sender} return true end
package.preload["impactenginer"] = function() return {getinstance = function() return ENGINE end} end
local SKILL_COLL = {}   -- [skill_id][collection_id] = true
package.preload["skillenginer"] = function()
    return {getinstance = function() return {is_skill_in_collection = function(_, sid, cid) return SKILL_COLL[sid] and SKILL_COLL[sid][cid] or false end} end}
end
package.preload["scene.skill.combat_core"] = function() return {new = function() return {get_result_impact = function() end} end} end
local class = require "class"
local SKILL0_CALLS = {}
package.preload["scene.skill.human.skill_0"] = function()
    local s0 = class("skill_0_mock")
    s0.IMPACT_NUMBER = 17 -- menpai-fix: như skill_0 thật (trường số, class.lua không chép cho lớp con)
    s0.SkillInfoDescriptorIndex = {IDX_ACTIVATE_ONCE_IMPACT = 0, IDX_ACTIVATE_EACH_TICK_IMPACT = 1}
    function s0:effect_on_unit_once(obj_me, obj_tar) SKILL0_CALLS[#SKILL0_CALLS + 1] = {obj_me, obj_tar} end
    function s0:register_impact_event(rec, sender, imp) self.events = self.events or {}; self.events[#self.events + 1] = {rec = rec, id = imp.data_index} end
    return s0
end
package.preload["scene.skill.impact"] = function()
    return {new = function()
        local o = {params = {}}
        function o:clean_up() end
        function o:set_skill_id(v) self.skill_id = v end
        function o:set_skill_level(v) self.skill_level = v end
        function o:mark_critical_hit_flag() self.crit = true end
        function o:get_logic_id() return self.logic_id or 0 end
        return o
    end}
end

local function imp_with(params)
    return {params = params, get_caster_obj_id = function() return 7 end, is_critical_hit = function() return false end,
            get_skill_id = function() return 11 end, get_skill_level = function() return 1 end, data_index = params.__data_index}
end

local function obj_with(o)
    o = o or {}
    local obj = {hp = o.hp or 800, max_hp = o.max_hp or 1000, alive = true, damages = {}, faded = 0, removed = 0, type = o.type or "human"}
    function obj:get_max_hp() return self.max_hp end
    function obj:get_hp() return self.hp end
    function obj:is_alive() return self.alive end
    function obj:on_damages(d, caster) self.damages[#self.damages + 1] = {d = d, caster = caster} end
    function obj:on_impact_fade_out() self.faded = self.faded + 1 end
    function obj:remove_impact() self.removed = self.removed + 1 end
    function obj:get_obj_type() return self.type end
    function obj:get_obj_id() return 1 end
    function obj:get_logic_count() return 0 end
    function obj:get_scene() return {get_impact_enginer = function() return ENGINE end, get_obj_by_id = function(_, id) return o.objs and o.objs[id] end} end
    return obj
end

local RATE_KEYS = {"wg_rate", "ng_rate", "bg_rate", "hg_rate", "xg_rate", "dg_rate", "damage_rate"}
local function damages()
    local d = {back_impact = {}, back_talent = {}, recover_dmg_rate = {}, recover_hp_rate = {}}
    for _, k in ipairs(RATE_KEYS) do d[k] = 100 end
    for _, k in ipairs({"wg_point", "ng_point", "bg_point", "hg_point", "xg_point", "dg_point", "damage_point"}) do d[k] = 0 end
    return d
end

local pass, fail = 0, 0
local function test(name, fn)
    local ok, e = pcall(fn)
    if ok then pass = pass + 1; print("PASS " .. name) else fail = fail + 1; print("FAIL " .. name .. ": " .. string.sub(tostring(e), 1, 300)) end
end
local function eq(a, b, msg) if a ~= b then error((msg or "") .. " expected " .. tostring(b) .. " got " .. tostring(a), 2) end end

-- ---------------------------------------------------------------- test
test("002: % máu tối đa, sát thương trực tiếp", function()
    local L = require("scene.skill.impact_logic.std_impact_002").new()
    local o = obj_with({max_hp = 2000})
    L:on_active(imp_with({["伤害百分率"] = 30}), o)
    eq(#o.damages, 1); eq(o.damages[1].d.hp_damage, 600); eq(o.damages[1].d.direcht_rate, true); eq(o.damages[1].caster, 7)
    L:on_active(imp_with({}), o)
    eq(#o.damages, 1, "tham số rỗng không gây sát thương")
end)

test("067: xác suất + % máu hiện tại + tối thiểu", function()
    local L = require("scene.skill.impact_logic.std_impact_067").new()
    local o = obj_with({hp = 500})
    eq(L:calc_damage(imp_with({["发生几率"] = 50, ["当前生命值的百分比伤害"] = 10, ["伤害最小值"] = 80}), o, 30), 80)
    eq(L:calc_damage(imp_with({["发生几率"] = 50, ["当前生命值的百分比伤害"] = 40, ["伤害最小值"] = 80}), o, 30), 200)
    eq(L:calc_damage(imp_with({["发生几率"] = 50, ["当前生命值的百分比伤害"] = 40}), o, 90), 0)
end)

test("016: % 5 thuộc tính", function()
    local L = require("scene.skill.impact_logic.std_impact_016").new()
    local args = {}
    L:get_refix_dex(imp_with({["DEX修正%(0为无效)"] = -30}), args); eq(args.rate, -30)
    args = {}; L:get_refix_str(imp_with({}), args); eq(args.rate, nil, "nil-safe")
end)

test("043: kháng + hệ số nộ", function()
    local L = require("scene.skill.impact_logic.std_impact_043").new()
    local imp = imp_with({["冰抗性修正"] = -6, ["毒抗性修正"] = 0, ["怒气增长修正"] = 20})
    local a = {}; L:get_refix_def_cold(imp, a); eq(a.point, -6)
    a = {}; L:get_refix_def_poison(imp, a); eq(a.point, nil)
    eq(L:get_refix_rage_regenerate(imp), 1.2)
    eq(L:get_refix_rage_regenerate(imp_with({})), nil)
end)

test("091/109: % công", function()
    local L = require("scene.skill.impact_logic.std_impact_091").new()
    local a = {}; L:get_refix_attrib_att_magic(imp_with({["内功攻击修正率"] = 40}), a); eq(a.rate, 40)
    a = {}; L:get_refix_attrib_att_physics(imp_with({["物理攻击修正率"] = 15}), a); eq(a.rate, 15)
end)

test("114/122/145/162: tỉ lệ trúng/né/hội tâm", function()
    local L = require("scene.skill.impact_logic.std_impact_114").new()
    local imp = imp_with({["命中率调整百分比"] = 5, ["闪避率调整百分比"] = 30, ["会心一击率调整百分比"] = 7})
    eq(L:refix_miss_rate(imp), 30)
    assert(math.abs(L:refix_critical_rate(imp, .10) - .17) < 0.000001)
    local si = {up = 2}; function si:get_accuracy_rate_up() return self.up end; function si:set_accuracy_rate_up(v) self.up = v end
    L:refix_skill(imp, nil, si); eq(si.up, 7)
    local a = {}; L:get_refix_attrib_miss(imp_with({["闪避修正"] = 90, ["闪避修正率"] = 10}), a); eq(a.point, 90); eq(a.rate, 10)
    ENGINE.sent = {}
    local o = obj_with()
    L:on_hit_target(imp_with({["给目标的效果"] = 1331}), o, "TARGET"); eq(#ENGINE.sent, 1); eq(ENGINE.sent[1].id, 1331)
end)

test("149/150/116: % sát thương gây ra", function()
    local L = require("scene.skill.impact_logic.std_impact_149").new()
    local d = damages()
    L:on_damage_target(imp_with({["基础伤害增强"] = 10, ["冰系伤害修正率"] = 5}), obj_with(), obj_with(), d)
    eq(d.wg_rate, 110); eq(d.bg_rate, 115); eq(d.damage_rate, 110)
    d = damages()
    L:on_damage_target(imp_with({["血量左值百分比"] = 50, ["伤害增幅%"] = 20}), obj_with(), obj_with({hp = 400, max_hp = 1000}), d); eq(d.ng_rate, 120)
    d = damages()
    L:on_damage_target(imp_with({["血量左值百分比"] = 30, ["伤害增幅%"] = 20}), obj_with(), obj_with({hp = 400, max_hp = 1000}), d); eq(d.ng_rate, 100)
end)

test("170/156/187/110: miễn + phản đòn, nil-safe", function()
    local L = require("scene.skill.impact_logic.std_impact_170").new()
    local d = damages()
    L:on_damages(imp_with({["免疫率"] = 0, ["反射率"] = 13, ["反射伤害上限"] = 50000}), obj_with(), d, 7)
    eq(#d.recover_dmg_rate, 1); eq(d.recover_dmg_rate[1].rate, 13); eq(d.imm_dmg_rate, nil)
    d = damages(); L:on_damages(imp_with({["免疫率"] = 40}), obj_with(), d, 7); eq(d.imm_dmg_rate, 40)
    d = damages(); L:on_damages(imp_with({["免疫率"] = 100}), obj_with(), d, 7); eq(d.flag_immu, true)
    d = damages(); L:on_damages(imp_with({}), obj_with(), d, 7); eq(d.imm_dmg_rate, nil)
    local pet = obj_with({type = "pet"})
    d = damages(); L:on_damages(imp_with({["伤害降低百分比"] = 25}), obj_with({objs = {[7] = pet}}), d, 7); eq(d.imm_dmg_rate, 25)
    local hm = {imm_dmg_rate = 0}; L:on_health_increment(imp_with({["免疫率"] = 30}), hm); eq(hm.imm_dmg_rate, 30)
end)

test("076: cộng sát thương khi trúng impact thuộc tập", function()
    local L = require("scene.skill.impact_logic.std_impact_076").new()
    ENGINE.collections[374] = {[5555] = true}
    local d = damages()
    local p = {["目标效果集合ID"] = 374, ["附加伤害的类型(0~5:外、内、冰、火、玄、毒)"] = 4, ["附加伤害数值"] = 4800}
    L:on_damages(imp_with(p), obj_with(), d, 7, false, 11, {data_index = 5555}); eq(d.xg_point, 4800)
    d = damages(); L:on_damages(imp_with(p), obj_with(), d, 7, false, 11, {data_index = 1}); eq(d.xg_point, 0)
end)

test("113: khiên hút + tan", function()
    local L = require("scene.skill.impact_logic.std_impact_113").new()
    local o = obj_with()
    o.show_skill_missed = function() end
    local imp = imp_with({["护盾生命值"] = 100, ["伤害吸收率"] = 50})
    eq(L:on_damages_back(imp, o, 120), 60); eq(imp.params["护盾生命值"], 40); eq(o.removed, 0)
    eq(L:on_damages_back(imp, o, 200), 40); eq(o.removed, 1)
end)

test("130: giới hạn dưới giảm kháng", function()
    local L = require("scene.skill.impact_logic.std_impact_130").new()
    local a = {}; L:get_refix_reduce_def_light_low_limit(imp_with({["玄减抗下限"] = 12}), a); eq(a.point, 12)
end)

test("mọi module mới: getter không lỗi với params rỗng", function()
    for _, m in ipairs({"002", "016", "043", "067", "076", "091", "113", "114", "130", "149", "170"}) do
        local L = require("scene.skill.impact_logic.std_impact_" .. m).new()
        for k, f in pairs(getmetatable(L).class or getmetatable(L)) do
            if type(f) == "function" and type(k) == "string" and k:match("^get_refix_") then
                f(L, imp_with({}), {})
            end
        end
        if L.on_damages then L:on_damages(imp_with({}), obj_with(), damages(), 7) end
        if L.on_damage_target then L:on_damage_target(imp_with({}), obj_with(), obj_with(), damages()) end
    end
end)

test("skill_cy_generic: phân loại nhãn", function()
    local G = require("scene.skill.human.skill_cy_generic")
    eq(G.is_impact_label("附加效果1"), true); eq(G.is_impact_label("附加效果2的概率"), false); eq(G.is_impact_label("溅射效果陷阱id"), false)
    eq(G.is_impact_label("变身男buff"), true); eq(G.is_self_label("激活二式buff"), true); eq(G.is_self_label("伤害效果"), false)
    eq(G.prob_base("附加效果2的概率"), "附加效果2"); eq(G.prob_base("给目标的效果的发生几率"), "给目标的效果")
    local known = require("scene.skill.human.skill_cy_generic_known")
    eq(known["|生效一次的附加效果1"], true, "nhãn cfghelper phải có trong danh sách sinh máy")
    local cfg = {[56899] = {stand_flag = -1}, [56915] = {stand_flag = -1}, [57157] = {stand_flag = 1}}
    local raw = {{"附加效果1", 56899}, {"附加效果2的概率", 10}, {"附加效果2", 56915}, {"激活二式buff", 57157}, {"|生效一次的附加效果1", 56899}, {"伤害效果", 99999}}
    local ex = G.extra_impacts(raw, cfg)
    eq(#ex, 3); eq(ex[1].data_index, 56899); eq(ex[2].chance, 10); eq(ex[3].to_self, true)
end)

test("skill_cy_generic: kế thừa trường không phải hàm của skill_0 (IMPACT_NUMBER) qua class.lua thật", function()
    local G = require("scene.skill.human.skill_cy_generic")
    eq(G.IMPACT_NUMBER, 17, "IMPACT_NUMBER")
    eq(G.new().IMPACT_NUMBER, 17, "IMPACT_NUMBER qua instance (self.IMPACT_NUMBER trong skill_0.lua:72)")
    eq(G.SkillInfoDescriptorIndex.IDX_ACTIVATE_ONCE_IMPACT, 0)
    eq(G.classname, "skill_cy_generic", "không ghi đè trường riêng của lớp con")
end)

test("skill_cy_generic: đích áp impact", function()
    local G = require("scene.skill.human.skill_cy_generic")
    ENGINE.std_impact_config = {[1] = {stand_flag = -1}, [2] = {stand_flag = 1}, [3] = {stand_flag = 0}}
    local me, tar = obj_with(), obj_with()
    local enemy = true
    function me:is_enemy() return enemy end
    function me:get_skill_info() return {cy_raw_params = {{"伤害效果", 1}, {"目标获得效果", 2}, {"自身获得效果", 3}}} end
    function me:get_targeting_and_depleting_params() return {get_delay_time = function() return 0 end} end
    local L = G.new()
    L:effect_on_unit_once(me, tar, false)
    eq(#SKILL0_CALLS, 1, "gọi skill_0 trước")
    eq(#L.events, 3); eq(L.events[1].rec, tar); eq(L.events[2].rec, me, "buff tích cực + mục tiêu là địch → bản thân"); eq(L.events[3].rec, me)
    L.events = {}; enemy = false
    L:effect_on_unit_once(me, tar, false)
    eq(#L.events, 2, "impact tiêu cực lên đồng minh bị bỏ"); eq(L.events[1].rec, tar)
end)

-- ---------------------------------------------------------------- test logic mới impact-logic (15/09)
local function scene_with(objs, owner)
    return {
        get_impact_enginer = function() return ENGINE end,
        get_obj_by_id = function(_, id) return objs and objs[id] end,
        get_event_enginer = function() return {register_impact_event = function(_, rec, sender, imp) ENGINE.sent[#ENGINE.sent + 1] = {rec = rec, id = imp.data_index, ev = true} end} end,
        scan = function(_, op) return objs and objs.__scan or {} end,
    }
end

local function combat_obj(o)
    o = o or {}
    local obj = obj_with(o)
    obj.healed, obj.mana = 0, 0
    function obj:health_increment(v) self.healed = self.healed + v end
    function obj:mana_increment(v) self.mana = self.mana + v end
    function obj:get_max_mp() return o.max_mp or 500 end
    function obj:is_enemy(other) return other and other.__enemy == true end
    function obj:is_character_obj() return true end
    function obj:get_world_pos() return o.pos or {x = 0, y = 0} end
    function obj:get_skill_level() return 1 end
    function obj:get_skill_id() return 11 end
    return obj
end

test("169: hồi máu/khí mỗi nhịp + miễn %", function()
    local L = require("scene.skill.impact_logic.std_impact_169").new()
    local o = combat_obj({max_hp = 2000, max_mp = 1000})
    L:on_interval_over(imp_with({["回复千分比"] = 50, ["蓝量回复千分比"] = 20, ["扣血"] = 0}), o)
    eq(o.healed, 100, "hồi 5%% máu"); eq(o.mana, 20, "hồi 2%% khí")
    local d = damages()
    L:on_damages(imp_with({["免疫率"] = 40}), o, d); eq(d.imm_dmg_rate, 40)
    d = damages(); L:on_damages(imp_with({["免疫率"] = 100}), o, d); eq(d.flag_immu, true)
    local hm = {}; L:on_health_increment(imp_with({["免疫率"] = 30}), hm); eq(hm.imm_dmg_rate, 30)
    L:on_interval_over(imp_with({}), o); eq(o.healed, 100, "tham số rỗng không hồi thêm")
end)

test("101: mỗi cast một đao, sát thương lũy tiến trong giới hạn", function()
    local L = require("scene.skill.impact_logic.std_impact_101").new()
    SKILL_COLL[11] = {[117] = true}
    ENGINE.sent = {}
    local o = combat_obj()
    local p = imp_with({["加速BUFF"] = 32410, ["生效技能集合"] = 117, ["刀数上限"] = 2})
    local d = damages()
    local cast = {get_caster_logic_count=function()return 1 end}
    L:on_damage_target(p, o, combat_obj(), d, 11, cast); eq(p.params["刀数"], 1); eq(#ENGINE.sent, 1); eq(ENGINE.sent[1].id, 32410)
    eq(d.cys_nuhuo_rate, 1.5, "đao 1 tăng 1.5 phần trăm")
    d = damages()
    cast.get_caster_logic_count=function()return 2 end
    L:on_damage_target(p, o, combat_obj(), d, 11, cast); eq(p.params["刀数"], 2); eq(#ENGINE.sent, 1, "只phát加速一次")
    eq(d.cys_nuhuo_rate, 4.5, "đao 2 tăng 1.5+3 phần trăm")
    d = damages()
    L:on_damage_target(imp_with({["生效技能集合"] = 117}), o, combat_obj(), d, 99); eq(d.damage_rate, 100, "kỹ năng ngoài tập bỏ qua")
end)

test("102/103/155: tải + chạy không lỗi với scene giả", function()
    local objs = {__scan = {}}
    local target = combat_obj(); target.__enemy = true
    objs.__scan = {target}
    local caster = combat_obj(); caster.get_scene = function() return scene_with(objs) end
    objs[7] = caster
    for _, m in ipairs({"102", "103", "155"}) do
        local L = require("scene.skill.impact_logic.std_impact_" .. m).new()
        local o = combat_obj()
        o.get_scene = function() return scene_with(objs) end
        ENGINE.std_impact_config[555] = {logic_id = 0}
        local p = imp_with({["扫描半径"] = 10, ["影响目标人数"] = 6, ["子效果1"] = 555, ["死亡效果"] = 555, ["消散效果"] = 555,
            ["激活产生效果"] = 555, ["死亡触发"] = 555, ["一魂"] = 555, ["目标选择标记：-1:敌人,0:中立,1:友好,2:友好+队友;"] = -1})
        if L.on_active then L:on_active(p, o) end
        if L.on_interval_over then L:on_interval_over(p, o) end
        if L.on_fade_out then L:on_fade_out(p, o) end
        if L.on_die then L:on_die(p, o) end
    end
end)

test("098: giảm sát thương cho chủ buff", function()
    local L = require("scene.skill.impact_logic.std_impact_098").new()
    local owner = combat_obj()
    local o = combat_obj()
    o.get_scene = function() return scene_with({[7] = owner}) end
    local d = damages()
    L:on_damages(imp_with({["减伤率(自己)"] = 30, ["减伤率(他人)"] = 10}), owner, d, 7); eq(d.imm_dmg_rate, 30)
end)

print(string.format("server_impact_tests: %d đạt, %d lỗi", pass, fail))
os.exit(fail == 0 and 0 or 1)
