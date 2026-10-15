-- skill-logic: test Lua đơn vị (lua5.4) cho skill_cy_spec + cy_skill_extra + bảng cy_skill_logic_spec.
--   lua5.4 Tools/server/skill_logic_tests.lua <gốc GameServer hoặc gốc server riêng>
-- skynet/define/class được giả lập; skill_0 giả lập (chỉ ghi lại lời gọi). Thoát 0 khi mọi test đạt.
-- arg[1] = gốc ưu tiên (staging), arg[2] = gốc dự phòng (server riêng) — module chưa vá lấy ở đây
local roots = {}
for i = 1, 2 do
    local b = arg[i]
    if b then
        if not b:match("GameServer$") then b = b .. "/GameServer" end
        roots[#roots + 1] = b .. "/lualib/?.lua"
        roots[#roots + 1] = b .. "/services/?.lua"
    end
end
assert(#roots > 0, "cần đường dẫn GameServer (hoặc gốc server riêng)")
package.path = table.concat(roots, ";") .. ";" .. package.path

-- skill-logic-3: hàng hẹn giờ giả lập — skynet.timeout đẩy vào TIMERS, test tự gọi run_timers()
TIMERS = {}
package.preload["skynet"] = function()
    return {error = print, logi = function() end, loge = print, logd = function() end,
            timeout = function(ti, fn) TIMERS[#TIMERS + 1] = {ti = ti, fn = fn} end}
end
function run_timers()
    local list = TIMERS
    TIMERS = {}
    for _, t in ipairs(list) do
        t.fn()
    end
    return #list
end
package.preload["game.packet"] = function() return {} end
package.preload["actionenginer"] = function() return {getinstance = function() return {} end} end
-- skill-logic-4: define đủ cho cy_collection_bridge (tập ID) + scene.special_obj.trap
package.preload["define"] = function()
    return {
        INVAILD_ID = -1,
        CollectionIdType = {TYPE_BUFF_ID = 0, TYPE_IMPACT_MUTEX_ID = 1, TYPE_IMPACT_LOGIC_ID = 2,
                            TYPE_SKILL_ID = 3, TYPE_SKILL_LOGIC_ID = 4, TYPE_DIRECT_IMPACT_ID = 5},
        ConditionAndDepleteID = {CD_INVALID = -1, C_UNIT_MUST_HAVE_IMPACT = 0,
                                 C_TARGET_MUST_HAVE_IMPACT = 2, D_CANCEL_SPECIFIC_IMPACT = 9},
        OPERATE_RESULT = {OR_OK = 0, OR_U_CANNT_DO_THIS_RIGHT_NOW = 5},
        ENUM_BEHAVIOR_TYPE = {BEHAVIOR_TYPE_HOSTILITY = 1, BEHAVIOR_TYPE_AMITY = 2},
        MissFlag_T = {FLAG_IMMU = 1},
    }
end
-- skill-logic-4: bảng tập ID của CY (giả lập đúng ba dòng cần cho test; bản thật ở lualib/cy_idcollections.lua)
CY_COLLECTIONS = {
    [388] = {type = 1, ids = {[105] = true, [3651] = true, [3653] = true}},   -- 所有门派姿态buff
    [499] = {type = 0, ids = {[2631] = true}},                               -- 回天术九阳状态
    [376] = {type = 0, ids = {[151] = true}},                                -- 斩情诀BUFF
}
package.preload["cy_idcollections"] = function() return CY_COLLECTIONS end
package.preload["scene.special_obj.base"] = function()
    -- luaclass đọc super.Get / super.Set nên lớp cha giả lập phải có hai bảng này
    return {eSpecailObjType = {TRAP_OBJ = 1}, Get = {}, Set = {}}
end
TRAP_IMPACTS = {}
package.preload["impactenginer"] = function()
    return {getinstance = function()
        return {send_impact_to_unit = function(_, tar, id, owner)
            TRAP_IMPACTS[#TRAP_IMPACTS + 1] = {tar = tar, id = id, owner = owner}
        end}
    end}
end
package.preload["scene.skill.impact_logic.std_impact_003"] = function()
    local m = {ID = 3, enum_DAMAGE_TYPE_RATE = {"wg_rate", "ng_rate", "damage_rate"}}
    function m.refix_power_by_rate(_, imp, rate)
        imp.__rate = rate
        return true
    end
    function m.on_active(_, imp, obj)
        DMG_CALLS[#DMG_CALLS + 1] = {id = imp.data_index, dmg = imp.params and imp.params["物理伤害"],
                                     rate = imp.__rate, caster = imp.caster, skill = imp.skill_id, obj = obj}
        -- skill-summon: mục tiêu có trường __hp thì trừ máu thật để đo "hồi máu cho chủ"
        if obj and type(obj.__hp) == "number" then
            obj.__hp = obj.__hp - (obj.__dmg_per_hit or 100)
        end
    end
    return m
end

-- skill-logic-5: skillenginer giả lập — chỉ ba hàm mà `skill_cy_spec:child_skill_impact` dùng để đọc
-- ô 附加效果1 của CHIÊU CON ở đúng cấp (208 中冲剑·刃影). Bản thật ở lualib/skillenginer.lua.
CHILD_SKILLS = {}      -- [skill_id] = {[cấp] = {cy_raw_params = {{nhãn, giá trị}, …}}}
package.preload["skillenginer"] = function()
    local m = {}
    function m:getinstance() return self end
    function m:get_skill_template(id) return CHILD_SKILLS[id] and {__id = id} or nil end
    function m:get_skill_info_id_by_level(tmpl, lv)
        local per = CHILD_SKILLS[tmpl.__id]
        return (per and per[lv]) and (tmpl.__id .. ":" .. lv) or nil
    end
    function m:get_skill_info(iid)
        local sid, lv = string.match(tostring(iid), "^(%d+):(%d+)$")
        local per = sid and CHILD_SKILLS[tonumber(sid)]
        return per and per[tonumber(lv)]
    end
    return m
end

local class = require "class"

-- ---- skill_0 giả lập (như bản thật: IMPACT_NUMBER là TRƯỜNG, class.lua không chép cho lớp con)
local S0 = {once = {}, tick = {}}
package.preload["scene.skill.human.skill_0"] = function()
    local s0 = class("skill_0_mock")
    s0.IMPACT_NUMBER = 17
    s0.SkillInfoDescriptorIndex = {IDX_ACTIVATE_ONCE_IMPACT = 0, IDX_ACTIVATE_EACH_TICK_IMPACT = 1}
    function s0:effect_on_unit_once(obj_me, obj_tar, crit)
        local si = obj_me:get_skill_info()
        for i = 1, self.IMPACT_NUMBER do
            local v = self:get_activate_once_impact_by_index(si, i)
            if v ~= -1 then S0.once[#S0.once + 1] = {idx = i, id = v, tar = obj_tar} end
        end
    end
    function s0:effect_on_unit_each_tick(obj_me, obj_tar)
        local si = obj_me:get_skill_info()
        for i = 1, 2 do
            local v = self:get_activate_each_tick_impact_by_index(si, i)
            if v ~= -1 then S0.tick[#S0.tick + 1] = {idx = i, id = v, tar = obj_tar} end
        end
    end
    function s0:get_activate_once_impact_by_index(si, i) return si:get_activate_once_impact_by_index(i) or -1 end
    function s0:get_activate_each_tick_impact_by_index(si, i) return si:get_activate_each_tick_impact_by_index(i) or -1 end
    function s0:activate_once(obj_me)
        for _, t in ipairs(obj_me.__targets or {}) do self:effect_on_unit_once(obj_me, t, obj_me.__crit or false) end
        return true
    end
    function s0:activate_each_tick(obj_me)
        for _, t in ipairs(obj_me.__targets or {}) do self:effect_on_unit_each_tick(obj_me, t, false) end
        return true
    end
    function s0:is_character_obj(t) return t == "human" or t == "monster" or t == "pet" end
    function s0:register_impact_event(rec, sender, imp, delay, crit)
        SENT[#SENT + 1] = {rec = rec, id = imp.data_index, pos = imp.__pos, dur = imp.__dur, rate = imp.__rate}
    end
    function s0:register_active_obj() end
    return s0
end

package.preload["scene.skill.impact"] = function()
    return {new = function()
        local o = {params = {}}
        function o:clean_up() end
        function o:get_logic_id() return self.logic_id or 0 end
        function o:set_continuance(v) self.__dur = v end
        function o:add_rate_params(_, v) self.__rate = v end
        function o:set_caster_obj_id(v) self.caster = v end
        function o:get_caster_obj_id() return self.caster end
        function o:set_skill_id(v) self.skill_id = v end
        function o:set_skill_level(v) self.skill_level = v end
        function o:is_critical_hit() return self.crit == true end
        function o:mark_critical_hit_flag() self.crit = true end
        return o
    end}
end

SENT = {}
local ENGINE = {std_impact_config = {}}
function ENGINE:init_impact_from_data(i, imp)
    if not self.std_impact_config[i] then return false end
    imp.data_index = i
    imp.logic_id = self.std_impact_config[i].logic_id or 0
    return true
end
function ENGINE:get_logic(imp)
    return {set_impact_x = function(_, im, x) im.__pos = im.__pos or {}; im.__pos.x = x end,
            set_impact_y = function(_, im, y) im.__pos = im.__pos or {}; im.__pos.y = y end}
end

-- ---- skill-summon: eventenginer + thực thể triệu hồi giả lập
EVENT_SENT = {}
EVENT = {}
function EVENT:register_impact_event(reciver, sender, imp, delay, skill_id)
    EVENT_SENT[#EVENT_SENT + 1] = {rec = reciver, sender = sender, id = imp.data_index, skill = skill_id}
end

function SUMMON_MOCK(scene, oid, mid, x, y)
    local o = {mid = mid, pos = {x = x, y = y}, oid = oid, ticks = 0, attribs = {}}
    function o:update(delta) self.ticks = self.ticks + 1 end
    function o:get_obj_id() return self.oid end
    function o:get_obj_type() return "monster" end
    function o:get_scene() return scene end
    function o:is_alive() return true end
    function o:get_logic_count() return 0 end
    function o:get_world_pos() return self.pos end
    function o:set_die_time(v) self.die_time = v end
    function o:set_temp_camp_id(v) self.camp = v end
    function o:set_attrib(t) for k, v in pairs(t) do self.attribs[k] = v end end
    function o:set_hp(v) self.hp = v end
    function o:get_hp() return self.hp or 1 end
    function o:set_name(v) self.name = v end
    function o:mark_unbreakable_flag() self.unbreakable = true end
    function o:set_unconstrained_monster(v) self.unconstrained = v end
    return o
end

local COLL = {}    -- [obj][collection_id] = true
package.preload["scene.skill.condition_cy"] = function()
    return {count_impacts = function(obj, c)
        local v = COLL[obj] and COLL[obj][c]
        if v == true then return 1 end
        return tonumber(v) or 0
    end}
end
package.preload["cy_four_combat.callbacks"] = function() return {get_doll_id = function() return 99 end} end


-- ---- giả lập cho std_impact_115 (logic impact "N % đòn đánh thường")
CC_CALLS, DMG_CALLS = {}, {}   -- toàn cục: các mock package.preload ở trên tham chiếu tới chúng
package.preload["scene.skill.impact_logic.base"] = function()
    local b = class("impact_base_mock")
    return b
end
package.preload["scene.skill.combat_core"] = function()
    return {new = function()
        return {get_result_impact = function(_, atk, def, imp)
            CC_CALLS[#CC_CALLS + 1] = {atk = atk, def = def, id = imp.data_index}
            imp.params = imp.params or {}
            imp.params["物理伤害"] = 200          -- kết quả đòn đánh thường giả lập
        end}
    end}
end

local spec_table = require "cy_skill_logic_spec"
local extra = require "cy_skill_extra"
local S = require("scene.skill.human.skill_cy_spec")

-- ---------------------------------------------------------------- tiện ích test
local pass, fail = 0, 0
local function test(name, fn)
    SENT = {}; S0.once = {}; S0.tick = {}
    local ok, e = pcall(fn)
    if ok then pass = pass + 1; print("PASS " .. name)
    else fail = fail + 1; print("FAIL " .. name .. ": " .. string.sub(tostring(e), 1, 400)) end
end
local function eq(a, b, msg) if a ~= b then error((msg or "") .. " expected " .. tostring(b) .. " got " .. tostring(a), 2) end end

local function make(opt)
    opt = opt or {}
    local si = {cy_raw_params = opt.raw or {}, once = opt.once or {}, tick = opt.tick or {}}
    function si:get_logic_id() return opt.logic end
    function si:get_skill_id() return opt.skill or 1 end
    function si:get_cool_down_id() return opt.cd_id or 77 end
    function si:get_activate_once_impact_by_index(i) return self.once[i] end
    function si:get_activate_each_tick_impact_by_index(i) return self.tick[i] end
    function si:get_activate_once_impacts() return self.once end
    local params = {}
    function params:get_delay_time() return 0 end
    function params:get_target_position() return opt.dest or {x = 0, y = 0} end
    function params:get_target_obj() return opt.target_id or -1 end
    function params:get_target_count() return opt.target_count or 1 end
    local scan = opt.scan or {}
    -- skill-summon: cảnh giả lập đủ API cho cy_skill_summon (create_temp_monster/get_obj_by_id/event/broadcast)
    local scene = {objs = {}, made = {}}
    function scene:get_impact_enginer() return ENGINE end
    function scene:scan() return scan end
    function scene:get_obj_by_id(id) return self.objs[id] end
    function scene:get_event_enginer() return EVENT end
    function scene:broadcast() end
    function scene:create_temp_monster(mid, x, y, base_ai, ai_script, script_id)
        if (opt.no_monster_row or {})[mid] then return nil end
        local oid = 1000 + #self.made
        local sm = SUMMON_MOCK(self, oid, mid, x, y)
        self.objs[oid] = sm
        self.made[#self.made + 1] = sm
        return oid
    end
    local me = {__targets = {}, traps = {}, cd = {}, model = opt.model or 0, heals = {}}
    function me:get_skill_info() return si end
    function me:get_targeting_and_depleting_params() return params end
    function me:get_scene() return scene end
    function me:get_obj_id() return 1 end
    function me:get_obj_type() return "human" end
    function me:is_alive() return true end
    function me:is_enemy(o) return o.__enemy == true end
    function me:get_world_pos() return {x = 10, y = 20} end
    function me:get_model() return self.model end
    function me:get_specific_obj_in_same_scene_by_id(id) return (opt.objs or {})[id] or scene.objs[id] end
    -- skill-logic-5: giữ luôn ĐỐI TƯỢNG bẫy trong bản ghi để test đọc được `_custom_descriptor`
    function me:skill_create_obj_specail(pos, id)
        local o = {get_obj_id = function() return 5 end}
        self.traps[#self.traps + 1] = {pos = pos, id = id, obj = o}
        return o
    end
    function me:update_cool_down_by_cool_down_id(id, ms) self.cd[#self.cd + 1] = {id = id, ms = ms} end
    function me:get_hp() return opt.hp or 1000 end
    function me:get_max_hp() return 1000 end
    function me:get_camp_id() return opt.camp or 3 end
    function me:health_increment(v) self.heals[#self.heals + 1] = v end
    -- skill-logic-5 (208 中冲剑·刃影): bốn cặp kháng/giảm kháng mà combat_core dùng.
    -- `opt.no_resist_api = true` để đo nhánh "thiếu API" (quái/thú không có các hàm này).
    if not opt.no_resist_api then
        for _, k in ipairs({"cold", "fire", "light", "posion"}) do
            me["get_defence_" .. k] = function() return (opt.resist or {})[k] end
            me["get_reduce_def_" .. k] = function() return (opt.reduce or {})[k] end
        end
    end
    local tar = {__enemy = true}
    for k, v in pairs(me) do if type(v) == "function" and k ~= "get_skill_info" then tar[k] = v end end
    function tar:get_obj_id() return 2 end
    function tar:get_hp() return self.__hp or opt.tar_hp or 1000 end
    function tar:get_max_hp() return 1000 end
    function tar:get_world_pos() return opt.tar_pos or {x = 30, y = 40} end
    me.__targets = {tar}
    scene.objs[1] = me
    scene.objs[2] = tar
    CUR_SCENE = scene          -- skill-summon: các mục tiêu giả lập dùng chung cảnh này
    return S.new(), me, tar, si
end

local function ids()
    local out = {}
    for _, e in ipairs(SENT) do out[#out + 1] = tostring(e.id) .. "@" .. tostring(e.rec and e.rec:get_obj_id()) end
    table.sort(out)
    return table.concat(out, ",")
end

local function cfg(...)
    for _, v in ipairs({...}) do ENGINE.std_impact_config[v] = {logic_id = 0} end
end
-- impact sát thương (logic 3) — hệ số nhân chỉ áp cho loại này, như bản thật
local function cfg3(...)
    for _, v in ipairs({...}) do ENGINE.std_impact_config[v] = {logic_id = 3} end
end

-- ---------------------------------------------------------------- test
test("bảng đặc tả: mọi dòng có src + note", function()
    local n = 0
    for id, sp in pairs(spec_table) do
        n = n + 1
        assert(type(id) == "number", "id phải là số")
        assert(sp.src == 'native' or sp.src == 'label' or sp.src == 'partial', "src lạ ở logic " .. id)
        assert(type(sp.note) == "string" and #sp.note > 10, "thiếu note ở logic " .. id)
        for _, key in ipairs({'impacts', 'tick', 'aoe', 'trap'}) do
            for _, e in ipairs(sp[key] or {}) do
                assert(type(e.label) == "string", key .. " thiếu label ở logic " .. id)
            end
        end
    end
    assert(n >= 60, "quá ít dòng: " .. n)
end)

test("consumed_labels gom đủ nhãn của một dòng", function()
    local c = S.consumed_labels(spec_table[864])
    eq(c['自身获得效果'], true); eq(c['目标获得效果'], true); eq(c['减少冷却时间id'], true); eq(c['减少时间（ms）'], true)
    c = S.consumed_labels(spec_table[865])
    eq(c['基础伤害效果'], true); eq(c['天魂集合id'], true); eq(c['一魂倍率百分比'], true); eq(c['失魂集合id'], true)
end)

test("864 拘魂: 自身获得效果 → bản thân, 目标/伤害 → mục tiêu, giảm hồi chiêu", function()
    cfg(100, 101, 102)
    local L, me, tar = make({logic = 864, raw = {{'自身获得效果', 100}, {'目标获得效果', 101}, {'伤害效果', 102},
                                                {'减少冷却时间id', 59}, {'减少时间（ms）', 2000}}})
    L:activate_once(me)
    eq(ids(), "100@1,101@2,102@2")
    eq(#me.cd, 1); eq(me.cd[1].id, 59); eq(me.cd[1].ms, 2000)
end)

test("171 毒螯势: 中毒buff theo 中毒几率% (0 % → không áp, 100 % → áp)", function()
    cfg(200)
    local L, me = make({logic = 171, raw = {{'加毒攻%', 10}, {'中毒几率%', 0}, {'中毒buff', 200}}})
    L:activate_once(me)
    eq(#SENT, 0, "xác suất 0")
    SENT = {}
    local L2, me2 = make({logic = 171, raw = {{'加毒攻%', 10}, {'中毒几率%', 100}, {'中毒buff', 200}}})
    L2:activate_once(me2)
    eq(ids(), "200@2")
end)

test("170 神蝎百相: chọn buff theo model (0 = nam, 1 = nữ)", function()
    cfg(300, 301, 302)
    local L, me = make({logic = 170, model = 0, raw = {{'变身男buff', 300}, {'变身女buff', 301}, {'免控buff', 302}}})
    L:activate_once(me)
    eq(ids(), "300@1,302@1")
    SENT = {}
    local L2, me2 = make({logic = 170, model = 1, raw = {{'变身男buff', 300}, {'变身女buff', 301}, {'免控buff', 302}}})
    L2:activate_once(me2)
    eq(ids(), "301@1,302@1")
end)

test("147 佛光普照: trị liệu tối đa 6 đồng đội quanh mình, không lên địch", function()
    cfg(400)
    local ally = {__enemy = false, get_obj_id = function() return 3 end, get_obj_type = function() return "human" end,
                  is_alive = function() return true end}
    local foe = {__enemy = true, get_obj_id = function() return 4 end, get_obj_type = function() return "human" end,
                 is_alive = function() return true end}
    local L, me = make({logic = 147, scan = {ally, foe},
                        raw = {{'|基础治疗buff', 400}, {'|额外治疗量千分比', 11}, {'|治疗队友时为自身治疗buf', -1}}})
    L:activate_once(me)
    eq(ids(), "400@3")
end)

test("803 高唐云散: số mục tiêu AOE lấy từ ô 对周围生效目标人数", function()
    cfg(500)
    local function foe(id) return {__enemy = true, get_obj_id = function() return id end,
                                   get_obj_type = function() return "human" end, is_alive = function() return true end} end
    local L, me = make({logic = 803, scan = {foe(11), foe(12), foe(13)},
                        raw = {{'生效一次的效果(目标)桃花岛怨复怨兮专用', 500}, {'对周围生效目标人数', 1}}})
    L:activate_once(me)
    eq(ids(), "500@11")
end)

test("12 燃烧陷阱 (mã CY CommonSkill003): tạo vật thể bẫy tại chỗ", function()
    local L, me = make({logic = 12, raw = {{'陷阱Data', 2101}}})
    L:activate_once(me)
    eq(#me.traps, 1); eq(me.traps[1].id, 2101); eq(me.traps[1].pos.x, 10)
end)

test("794 秦皇东遣 (mã CY SkillLogic794): thuấn di tới điểm chỉ định + 2 ô tự thân", function()
    cfg(600, 601, 602)
    local L, me = make({logic = 794, dest = {x = 55, y = 66},
                        raw = {{'|生效一次自己附加效果1', 600}, {'|生效一次自己附加效果2', 601}, {'|生效一次自己附加效果3', 602}}})
    L:activate_once(me)
    eq(ids(), "600@1,601@1,602@1")
    local tp
    for _, e in ipairs(SENT) do if e.id == 600 then tp = e end end
    eq(tp.pos.x, 55); eq(tp.pos.y, 66)
end)

test("792 谋动干戈 (mã CY SkillLogic792): điểm đến = con rối, ô 1 không bị skill_0 gửi thẳng", function()
    cfg(700, 701)
    local doll = {get_world_pos = function() return {x = 7, y = 8} end}
    local L, me = make({logic = 792, once = {700, 701}, objs = {[99] = doll}})
    L:activate_once(me)
    eq(#S0.once, 1, "skill_0 chỉ gửi ô 2"); eq(S0.once[1].idx, 2)
    local tp
    for _, e in ipairs(SENT) do if e.id == 700 then tp = e end end
    eq(tp.pos.x, 7); eq(tp.pos.y, 8)
end)

test("149 金顶绵掌·九阴: ô 2 chuyển sang bản thân", function()
    cfg(800, 801)
    local L, me = make({logic = 149, once = {800, 801}, raw = {{'|回血百分比', 50}}})
    L:activate_once(me)
    eq(#S0.once, 1); eq(S0.once[1].idx, 1)
    eq(ids(), "801@1")
end)

test("865 百倍奉还: hệ số theo số loại 丧魂 của mục tiêu", function()
    cfg3(900)
    local L, me, tar = make({logic = 865, raw = {{'基础伤害效果', 900}, {'天魂集合id', 413}, {'地魂集合id', 415},
                                                {'命魂集合id', 417}, {'一魂倍率百分比', 135}, {'二魂倍率百分比', 170},
                                                {'三魂倍率百分比', 220}}})
    COLL[tar] = {[413] = true, [415] = true}
    L:activate_once(me)
    eq(#SENT, 1); eq(SENT[1].rate, 70, "170 % → +70")
    SENT = {}; COLL[tar] = {}
    L:activate_once(me)
    eq(#SENT, 1); eq(SENT[1].rate, nil, "0 魂 → không nhân")
end)

test("868 判指阴阳: đếm 魂 trên BẢN THÂN, cần ≥ 2 mới phát", function()
    cfg(1000, 1001)
    local raw = {{'基础伤害效果', 1000}, {'天魂集合id', 412}, {'地魂集合id', 414}, {'命魂集合id', 416},
                 {'燃烧两魂伤害百分比', 150}, {'燃烧三魂伤害百分比', 200}, {'天魂对应目标获得效果', 1001},
                 {'清除冷却id', 59}}
    local L, me, tar = make({logic = 868, raw = raw})
    COLL[me] = {[412] = true}; COLL[tar] = {[412] = true, [414] = true}
    L:activate_once(me)
    eq(#SENT, 0, "bản thân mới 1 魂 → không phát")
    SENT = {}; COLL[me] = {[412] = true, [414] = true}
    L:activate_once(me)
    eq(ids(), "1000@2,1001@2", "impact vẫn gửi cho MỤC TIÊU")
end)

test("867 魂离魄散: đếm SỐ impact trong một tập gộp (count_by = each)", function()
    cfg3(1500)
    local raw = {{'基础伤害效果', 1500}, {'失魂集合id', 420}, {'一魂倍率百分比', 111},
                 {'二魂倍率百分比', 135}, {'三魂倍率百分比', 174}, {'斩杀效果', -1}}
    local L, me, tar = make({logic = 867, raw = raw})
    COLL[tar] = {[420] = 2}
    L:activate_once(me)
    eq(#SENT, 1); eq(SENT[1].rate, 35, "2 丧魂 → 135 %")
end)

test("732 九天揽月: hội tâm mới giảm hồi chiêu", function()
    cfg(1100)
    local raw = {{'生效一次的效果(目标)', 1100}, {'暴击时减少冷却时间的下限', 5}, {'暴击时减少冷却时间的上限', 15}}
    local L, me = make({logic = 732, raw = raw})
    L:activate_once(me)
    eq(#me.cd, 0, "không hội tâm")
    local L2, me2 = make({logic = 732, raw = raw})
    me2.__crit = true
    L2:activate_once(me2)
    eq(#me2.cd, 1)
    assert(me2.cd[1].ms >= 5000 and me2.cd[1].ms <= 15000, "ms = " .. me2.cd[1].ms)
end)

test("801 雅颂之音: (自己) → bản thân, (目标) → mục tiêu, bẫy dưới chân", function()
    cfg(1200, 1201)
    local L, me = make({logic = 801, raw = {{'生效一次的效果(自己)', 1200}, {'生效一次的效果(目标)', 1201},
                                           {'脚下生成陷阱ID', 1450}}})
    L:activate_once(me)
    eq(ids(), "1200@1,1201@2")
    eq(#me.traps, 1); eq(me.traps[1].id, 1450)
end)

test("ô tự thân chỉ áp MỘT lần dù nhiều mục tiêu", function()
    cfg(1300, 1301)
    local function foe(id) return {__enemy = true, get_obj_id = function() return id end,
                                   get_obj_type = function() return "human" end, is_alive = function() return true end} end
    local L, me = make({logic = 801, raw = {{'生效一次的效果(自己)', 1300}, {'生效一次的效果(目标)', 1301}}})
    me.__targets = {foe(21), foe(22), foe(23)}
    L:activate_once(me)
    local n_self = 0
    for _, e in ipairs(SENT) do if e.id == 1300 then n_self = n_self + 1 end end
    eq(n_self, 1)
end)

test("logic không có đặc tả → hành vi generic cũ", function()
    cfg(1400)
    local L, me = make({logic = 99999, raw = {{'附加效果1', 1400}}})
    L:activate_once(me)
    eq(ids(), "1400@2")
end)

-- ---------------------------------------------------------------- skill-summon (thực thể triệu hồi)
local summon = require "cy_skill_summon"

local function foe_hp(id, hp)
    return {__enemy = true, __hp = hp or 1000,
            get_obj_id = function() return id end, get_obj_type = function() return "human" end,
            is_alive = function() return true end, get_hp = function(self) return self.__hp end,
            get_scene = function() return CUR_SCENE end,
            get_world_pos = function() return {x = 10, y = 20} end}
end

test("886 狂猿凌峰: triệu hồi 蜀山狂猿 1499 tại chỗ chủ, 15 s, không bị đánh", function()
    local L, me = make({logic = 886})
    L:activate_once(me)
    local sc = me:get_scene()
    eq(#sc.made, 1, "phải tạo đúng 1 thực thể")
    local ape = sc.made[1]
    eq(ape.mid, 1499)
    eq(ape.die_time, 15000)
    eq(ape.unbreakable, true)
    eq(ape.unconstrained, true)
    eq(ape.camp, 3, "cùng phe với chủ")
    eq(ape.pos.x, 10); eq(ape.pos.y, 20)
end)

test("886: mỗi nhịp gây 20 % đòn đánh thường của CHỦ rồi hồi máu chủ đúng số máu đã trừ", function()
    CC_CALLS, DMG_CALLS = {}, {}
    cfg3(0)                                     -- dòng 0 = 普通攻击的伤害效果
    local foe = foe_hp(11, 1000)
    local L, me = make({logic = 886, scan = {foe}})
    L:activate_once(me)
    local ape = me:get_scene().made[1]
    ape:update(600)                             -- chưa tới 1200 ms
    eq(#DMG_CALLS, 0)
    ape:update(700)                             -- 1300 ms → một nhịp
    eq(#DMG_CALLS, 1)
    eq(DMG_CALLS[1].id, 0, "dựng từ StandardImpact DataIndex 0")
    eq(DMG_CALLS[1].rate, -80, "20 % → RefixPowerByRate(-80)")
    eq(DMG_CALLS[1].caster, 1, "sát thương ghi cho CHỦ")
    eq(#CC_CALLS, 1); eq(CC_CALLS[1].atk, me, "CombatCore tính theo chỉ số của chủ")
    eq(#me.heals, 1); eq(me.heals[1], 100, "hồi đúng 100 máu đã trừ của mục tiêu")
end)

test("886: chủ rời cảnh → thực thể tự xoá (die_time 1), không ném lỗi", function()
    local L, me = make({logic = 886})
    L:activate_once(me)
    local sc = me:get_scene()
    local ape = sc.made[1]
    sc.objs[1] = {}                              -- obj_id 1 nay là đối tượng khác ⇒ chủ đã đi
    ape:update(100)
    eq(ape.die_time, 1)
end)

test("886: tung lại chỉ còn MỘT thực thể (khoá theo logic)", function()
    local L, me = make({logic = 886})
    L:activate_once(me)
    L:activate_once(me)
    local sc = me:get_scene()
    eq(#sc.made, 2, "vẫn tạo con mới")
    eq(sc.made[1].die_time, 1, "con cũ bị thu hồi ngay")
    eq(sc.made[2].die_time, 15000)
end)

test("730 诸葛神弩: 图腾id + 图腾血量 + 无敌效果id áp lên CHÍNH tháp, đặt ở điểm client gửi", function()
    EVENT_SENT = {}
    cfg(37922)
    local L, me = make({logic = 730, dest = {x = 77, y = 88},
                        raw = {{'图腾id', 16935}, {'图腾血量', 9000}, {'无敌效果id', 37922}}})
    L:activate_once(me)
    local t = me:get_scene().made[1]
    eq(t.mid, 16935); eq(t.die_time, 15000)
    eq(t.attribs.hp_max, 9000); eq(t.hp, 9000)
    eq(t.pos.x, 77); eq(t.pos.y, 88)
    eq(#EVENT_SENT, 1); eq(EVENT_SENT[1].id, 37922)
    eq(EVENT_SENT[1].rec, t, "无敌 áp lên tháp, không phải người chơi")
end)

test("730: mỗi 0,4 s bắn 1 địch quanh THÁP với 25 % đòn đánh thường", function()
    CC_CALLS, DMG_CALLS = {}, {}
    cfg3(0); cfg(37922)
    local L, me = make({logic = 730, dest = {x = 77, y = 88},
                        scan = {foe_hp(11), foe_hp(12), foe_hp(13)},
                        raw = {{'图腾id', 16935}, {'图腾血量', 9000}, {'无敌效果id', 37922}}})
    L:activate_once(me)
    local t = me:get_scene().made[1]
    t:update(400)
    eq(#DMG_CALLS, 1, "mỗi nhịp đúng 1 mục tiêu")
    eq(DMG_CALLS[1].rate, -75, "25 %")
    t:update(400)
    eq(#DMG_CALLS, 2)
end)

test("731 千机变: chọn ngẫu nhiên 1 trong 3 枢甲造物, máu và hệ số đi đúng theo chỉ số", function()
    CC_CALLS, DMG_CALLS = {}, {}
    cfg3(0); cfg(37912, 37920)
    local raw = {{'延迟buff', 37912}, {'免疫控制buff', 37920},
                 {'图腾id1', 16936}, {'图腾id2', 16937}, {'图腾id3', 16938},
                 {'图腾血量1', 9000}, {'图腾血量2', 9000}, {'图腾血量3', 16000}}
    -- hệ số 80/100/150 % → RefixPowerByRate(hệ số − 100) = −20 / (không nhân) / +50
    local want = {[16936] = {9000, -20}, [16937] = {9000, 0}, [16938] = {16000, 50}}
    local seen = {}
    for _ = 1, 40 do
        DMG_CALLS = {}
        local L, me = make({logic = 731, raw = raw, target_id = 2, scan = {foe_hp(11)}})
        L:activate_once(me)
        local t = me:get_scene().made[1]
        local w = want[t.mid]
        assert(w, "ID lạ: " .. tostring(t.mid))
        eq(t.attribs.hp_max, w[1], "máu của " .. t.mid)
        eq(t.pos.x, 30, "đặt cạnh mục tiêu")
        t:update(2000)
        eq(#DMG_CALLS, 0, "3 s đầu chưa kích hoạt")
        t:update(1000)
        eq(#DMG_CALLS, 1)
        eq(DMG_CALLS[1].rate, w[2] ~= 0 and w[2] or nil, "hệ số của " .. t.mid)
        seen[t.mid] = true
    end
    assert(seen[16936] and seen[16937] and seen[16938], "40 lượt phải gặp đủ 3 con")
end)

test("174 毒蟾功: 失明buff lên mục tiêu + triệu hồi 毒蟾 tại mục tiêu", function()
    cfg(1652)
    local L, me = make({logic = 174, target_id = 2, raw = {{'失明buff', 1652}, {'召唤物', 16944}}})
    L:activate_once(me)
    eq(ids(), "1652@2")
    local t = me:get_scene().made[1]
    eq(t.mid, 16944); eq(t.die_time, 9000); eq(t.pos.x, 30)
end)

test("thiếu dòng MonsterAttrEx → bỏ qua, không ném lỗi, không có thực thể", function()
    local L, me = make({logic = 886, no_monster_row = {[1499] = true}})
    L:activate_once(me)
    eq(#me:get_scene().made, 0)
end)

test("nhãn 图腾id/图腾血量 bị đặc tả tiêu thụ nên generic không áp làm impact", function()
    local c = S.consumed_labels(spec_table[730])
    eq(c['图腾id'], true); eq(c['图腾血量'], true); eq(c['无敌效果id'], true)
    c = S.consumed_labels(spec_table[731])
    eq(c['图腾id1'], true); eq(c['图腾血量3'], true)
    c = S.consumed_labels(spec_table[174])
    eq(c['召唤物'], true)
end)

test("cy_skill_summon: quét địch theo góc nhìn của CHỦ, giới hạn số lượng", function()
    local ally = {__enemy = false, get_obj_id = function() return 21 end,
                  get_obj_type = function() return "human" end, is_alive = function() return true end}
    local _, me = make({logic = 886, scan = {ally, foe_hp(22), foe_hp(23), foe_hp(24)}})
    eq(#summon.scan_enemies(me, {x = 0, y = 0}, 15, 2), 2)
    eq(#summon.scan_enemies(me, {x = 0, y = 0}, 15, 99), 3, "đồng đội bị loại")
    eq(#summon.scan_enemies(me, nil, 15, 1), 0, "toạ độ hỏng → rỗng, không lỗi")
end)

test("cy_skill_summon: ID quái sai/không có cảnh → trả lỗi có tên, không ném", function()
    local _, me = make({logic = 886})
    local obj, err = summon.spawn(me, {monster_id = 0})
    eq(obj, nil); eq(err, "bad_monster_id")
    obj, err = summon.spawn(me, {monster_id = 70000})
    eq(obj, nil); eq(err, "bad_monster_id")
    obj, err = summon.spawn(nil, {monster_id = 1499})
    eq(obj, nil); eq(err, "no_owner")
end)

test("cy_skill_summon: vòng đời bị kẹp bởi MAX_LIFE_MS", function()
    local _, me = make({logic = 886})
    local obj = summon.spawn(me, {monster_id = 1499, life_ms = 10 * 60 * 1000})
    eq(obj.die_time, summon.MAX_LIFE_MS)
end)

test("cy_skill_summon: nhịp ném lỗi thì đếm và ngắt, KHÔNG làm hỏng update gốc", function()
    local _, me = make({logic = 886})
    local obj, tag = summon.spawn(me, {monster_id = 1499, interval = 100,
                                       on_tick = function() error("hong") end})
    for _ = 1, 10 do obj:update(100) end
    eq(tag.interval, nil, "quá ngưỡng lỗi → ngắt nhịp")
    eq(obj.ticks, 10, "update gốc vẫn chạy đủ 10 lần")
end)

-- ---------------------------------------------------------------- cy_skill_extra (20 ô nhãn CY)
test("cy_skill_extra: đích của 5 nhãn", function()
    local si = {cy_raw_params = {{'|生效一次的附加效果（对自己）', 21733}}, get_logic_id = function() return 0 end}
    local l = extra.list(si)
    eq(#l, 1); eq(l[1].to, 'self'); eq(l[1].data_index, 21733)
    si = {cy_raw_params = {{'|生效一次的附加效果', 21634}}, get_logic_id = function() return 80 end}
    eq(extra.list(si)[1].to, 'target')
    si = {cy_raw_params = {{'给自己的buff', 54899}}, get_logic_id = function() return 260 end}
    eq(extra.list(si)[1].to, 'self')
    si = {cy_raw_params = {{'新增效果id', 32700}, {'效果作用对象', 1}}, get_logic_id = function() return 704 end}
    eq(extra.list(si)[1].to, 'self')
    si = {cy_raw_params = {{'新增效果id', 32700}, {'效果作用对象', 0}}, get_logic_id = function() return 704 end}
    eq(extra.list(si)[1].to, 'target')
    si = {cy_raw_params = {{'瞬移BUFFid', 49583}}, get_logic_id = function() return 840 end}
    eq(extra.list(si)[1].to, 'teleport')
end)

test("cy_skill_extra: logic có đặc tả riêng thì KHÔNG áp thêm (tránh gấp đôi 841/206)", function()
    local si = {cy_raw_params = {{'瞬移BUFFid', 49584}}, get_logic_id = function() return 841 end}
    eq(#extra.list(si), 0)
    si = {cy_raw_params = {{'给自己的buff', 1}}, get_logic_id = function() return 206 end}
    eq(#extra.list(si), 0)
end)

test("cy_skill_extra.value đọc đúng ô", function()
    local si = {cy_raw_params = {{'瞬移BUFFid', 49583}, {'khac', 1}}, get_logic_id = function() return 840 end}
    eq(extra.value(si, '瞬移BUFFid'), 49583)
    eq(extra.value(si, 'khong_co'), nil)
end)


-- ---------------------------------------------------------------- skill-logic-3 (17/09): 769/204/144/149/736/799
local chain_mod = require "cy_skill_chain"

-- đối tượng địch dùng chung cho các test dưới (cùng cảnh với chủ)
local function FOE(scene, id, x, y)
    local o = {__enemy = true, pos = {x = x or 11, y = y or 21}, __hp = 1000}
    function o:get_obj_id() return id end
    function o:get_obj_type() return "human" end
    function o:is_alive() return self.__dead ~= true end
    function o:get_scene() return scene end
    function o:get_world_pos() return self.pos end
    function o:get_hp() return self.__hp end
    return o
end

test("769 火烧连营: nấc sát thương đi theo THỨ TỰ NỐI, mỗi nhịp nối thêm một mắt", function()
    cfg(690, 691, 700, 701, 702, 703, 704, 705, 706)
    local raw = {{'主目标连线', 690}, {'其它目标连线', 691}, {'主目标断线距离', 15}, {'其它目标断线距离', 7},
                 {'主目标伤害', 700}, {'二目标伤害', 701}, {'三目标伤害', 702}, {'四目标伤害', 703},
                 {'五目标伤害', 704}, {'六目标伤害', 705}, {'七目标伤害', 706}}
    local scan = {}
    local L, me, tar = make({logic = 769, raw = raw, scan = scan, tar_pos = {x = 12, y = 22}})
    L:activate_once(me)
    eq(ids(), "690@2,700@2", "lúc tung: dây chính + nấc 1 cho mục tiêu")
    local scene = me:get_scene()
    local f1, f2 = FOE(scene, 11, 13, 23), FOE(scene, 12, 13, 23)
    scan[1], scan[2] = f1, f2
    SENT = {}
    L:activate_each_tick(me)
    eq(ids(), "691@11,700@2,701@11", "nhịp 1: nối f1 (dây phụ) + nấc 1 cho chính, nấc 2 cho f1")
    SENT = {}
    L:activate_each_tick(me)
    eq(ids(), "691@12,700@2,701@11,702@12", "nhịp 2: thêm f2 → ba mắt, ba nấc")
end)

test("769: mục tiêu chính rời quá 主目标断线距离 → ĐỨT cả chuỗi", function()
    cfg(700, 701)
    local raw = {{'主目标断线距离', 15}, {'其它目标断线距离', 7}, {'主目标伤害', 700}, {'二目标伤害', 701}}
    local L, me, tar = make({logic = 769, raw = raw, tar_pos = {x = 500, y = 500}})
    L:activate_once(me)
    SENT = {}
    L:activate_each_tick(me)
    eq(#SENT, 0, "chuỗi đứt, không gây gì")
    eq(chain_mod.chain_get(me, "cychain769"), nil, "trạng thái đã xoá")
end)

test("769: mắt xích rời mục tiêu chính quá 其它目标断线距离 thì rời chuỗi", function()
    cfg(700, 701, 702)
    local raw = {{'主目标断线距离', 15}, {'其它目标断线距离', 7},
                 {'主目标伤害', 700}, {'二目标伤害', 701}, {'三目标伤害', 702}}
    local scan = {}
    local L, me = make({logic = 769, raw = raw, scan = scan, tar_pos = {x = 12, y = 22}})
    local scene = me:get_scene()
    local f1 = FOE(scene, 11, 13, 23)
    scan[1] = f1
    L:activate_once(me)
    L:activate_each_tick(me)
    f1.pos = {x = 300, y = 300}                 -- chạy ra xa mục tiêu chính
    scan[1] = nil
    SENT = {}
    L:activate_each_tick(me)
    eq(ids(), "700@2", "chỉ còn mục tiêu chính")
end)

test("769: quá số nhịp trần thì tự dừng", function()
    cfg(700)
    local L, me = make({logic = 769, raw = {{'主目标断线距离', 15}, {'其它目标断线距离', 7}, {'主目标伤害', 700}},
                        tar_pos = {x = 12, y = 22}})
    L:activate_once(me)
    for _ = 1, 12 do L:activate_each_tick(me) end
    SENT = {}
    L:activate_each_tick(me)
    eq(#SENT, 0, "nhịp 13 > max_ticks 12")
end)

test("204 少商剑·刃影: 6 đòn, cùng mục tiêu thì hệ số giảm dần 15 %/lần", function()
    cfg3(800)
    local L, me = make({logic = 204, raw = {{'附加伤害（逻辑3）', 800}, {'衰减系数百分比', 15},
                                            {'驱散二式buff集合', 490}}})
    L:activate_once(me)
    eq(#SENT, 6, "sáu phi kiếm")
    local r = {}
    for i, e in ipairs(SENT) do r[i] = tostring(e.rate) end
    eq(table.concat(r, ","), "nil,-15,-28,-39,-48,-56", "100 × 0,85^(n−1) − 100")
end)

test("204: mỗi mục tiêu có bộ đếm RIÊNG", function()
    cfg3(800)
    local hits = {}
    local a = {get_obj_id = function() return 7 end}
    local b = {get_obj_id = function() return 8 end}
    eq(chain_mod.decay_rate(hits, a, 15), 100)
    eq(chain_mod.decay_rate(hits, b, 15), 100, "mục tiêu khác bắt đầu lại từ 100")
    eq(chain_mod.decay_rate(hits, a, 15), 85)
    eq(chain_mod.decay_rate(hits, a, 0), 100, "không có ô 衰减系数百分比 → không giảm")
end)

test("144 回天术: phát trạng thái 九阳炽脉/九阴煞魄 theo ô |替换一段技能id1", function()
    cfg(900, 901, 13058, 13059)
    local function run(first_id)
        SENT = {}
        local L, me = make({logic = 144, raw = {{'|变身buff', 900}, {'|效果1', 901}, {'|给自己的效果', -1},
                                                {'|替换一段技能id1', first_id}, {'|替换一段技能id2', 424},
                                                {'|替换一段技能id3', 426}, {'|替换一段技能id4', 406}}})
        L:activate_once(me)
        return ids()
    end
    eq(run(411), "13058@1,900@1", "411 回天术 → 九阳炽脉")
    eq(run(417), "13059@1,900@1", "417 斩情诀 → 九阴煞魄")
    eq(run(999), "900@1", "ô lạ → không phát trạng thái nào")
end)

test("149 金顶绵掌·九阴: hút |回血百分比 % SÁT THƯƠNG THỰC (đo chênh lệch HP) cho chủ", function()
    cfg(1390, 1402, 57604)
    TIMERS = {}
    local L, me, tar = make({logic = 149, raw = {{'|生效一次的附加效果1', 1390}, {'|引导周期的附加效果1', 1402},
                                                 {'|生效一次的附加效果2', 57604}, {'|回血百分比', 50}},
                             once = {1390, 57604}, tick = {1402}})
    tar.__hp = 1000
    L:activate_each_tick(me)
    eq(#me.heals, 0, "chưa đo xong thì chưa hồi")
    tar.__hp = 800
    eq(run_timers() > 0, true, "có hẹn giờ đo lại")
    eq(#me.heals, 1); eq(me.heals[1], 100, "nửa của 200 máu đã mất")
end)

test("149: mục tiêu không mất máu → không hồi; ô |回血百分比 = 0 → không hẹn giờ", function()
    cfg(1402)
    TIMERS = {}
    local L, me, tar = make({logic = 149, raw = {{'|引导周期的附加效果1', 1402}, {'|回血百分比', 50}}, tick = {1402}})
    tar.__hp = 1000
    L:activate_each_tick(me)
    run_timers()
    eq(#me.heals, 0)
    TIMERS = {}
    local L2, me2 = make({logic = 149, raw = {{'|引导周期的附加效果1', 1402}, {'|回血百分比', 0}}, tick = {1402}})
    L2:activate_each_tick(me2)
    eq(#TIMERS, 0, "0 % thì không đo")
end)

test("736 万箭齐发: tối đa 3 lần tóe, mức xác suất theo thứ tự", function()
    cfg(1000)
    local raw = {{'伤害效果', 1000}, {'触发1次溅射几率（百分比）', 100}, {'触发2次溅射几率（百分比）', 100},
                 {'触发3次溅射几率（百分比）', 100}, {'溅射效果陷阱id', 3064}}
    local L, me, tar = make({logic = 736, raw = raw})
    local scene = me:get_scene()
    me.__targets = {tar, FOE(scene, 21), FOE(scene, 22), FOE(scene, 23), FOE(scene, 24)}
    L:activate_once(me)
    eq(#me.traps, 3, "5 mục tiêu trúng nhưng trần là 3")
    eq(me.traps[1].id, 3064, "ID bẫy đọc từ ô 参数值 lúc chạy (trap-recollide đổi 1980 → 3064)")
end)

test("736: mức 1 = 0 % thì không có bẫy nào; mức 2 = 0 % thì chỉ một bẫy", function()
    cfg(1000)
    local function run(p1, p2, p3)
        local raw = {{'伤害效果', 1000}, {'触发1次溅射几率（百分比）', p1}, {'触发2次溅射几率（百分比）', p2},
                     {'触发3次溅射几率（百分比）', p3}, {'溅射效果陷阱id', 3064}}
        local L, me, tar = make({logic = 736, raw = raw})
        me.__targets = {tar, FOE(me:get_scene(), 21), FOE(me:get_scene(), 22)}
        L:activate_once(me)
        return #me.traps
    end
    eq(run(0, 100, 100), 0)
    eq(run(100, 0, 100), 1)
end)

-- skill-logic-5 (17/09): ô `descriptor` của khối trap — hiệu ứng bẫy lấy theo CẤP của chiêu
test("736: bẫy mang _custom_descriptor['效果1'] = ô 伤害效果 của chính cấp đang dùng", function()
    cfg(37331)
    local raw = {{'伤害效果', 37331}, {'触发1次溅射几率（百分比）', 100}, {'触发2次溅射几率（百分比）', 0},
                 {'触发3次溅射几率（百分比）', 0}, {'溅射效果陷阱id', 3064}}
    local L, me, tar = make({logic = 736, raw = raw})
    me.__targets = {tar}
    L:activate_once(me)
    eq(#me.traps, 1)
    eq(me.traps[1].obj._custom_descriptor['效果1'], 37331,
       "tip: 100 % 万箭齐发伤害 = dòng 伤害效果 của cấp đó, không phải ô 效果1 của bảng")
end)

test("736: cấp khác → ID khác (một dòng bẫy dùng chung cho cả 16 cấp)", function()
    cfg(37316)
    local raw = {{'伤害效果', 37316}, {'触发1次溅射几率（百分比）', 100}, {'触发2次溅射几率（百分比）', 0},
                 {'触发3次溅射几率（百分比）', 0}, {'溅射效果陷阱id', 3064}}
    local L, me, tar = make({logic = 736, raw = raw})
    me.__targets = {tar}
    L:activate_once(me)
    eq(me.traps[1].obj._custom_descriptor['效果1'], 37316)
end)

test("736: ô 伤害效果 = −1 ⇒ KHÔNG đặt _custom_descriptor (để bảng quyết định như cũ)", function()
    cfg(37331)
    local raw = {{'伤害效果', -1}, {'触发1次溅射几率（百分比）', 100}, {'触发2次溅射几率（百分比）', 0},
                 {'触发3次溅射几率（百分比）', 0}, {'溅射效果陷阱id', 3064}}
    local L, me, tar = make({logic = 736, raw = raw})
    me.__targets = {tar}
    L:activate_once(me)
    eq(#me.traps, 1)
    eq(me.traps[1].obj._custom_descriptor, nil)
end)

test("khối trap không khai `descriptor` thì vật thể không bị gắn gì (12 燃烧陷阱)", function()
    cfg(1)
    local L, me = make({logic = 12, raw = {{'陷阱Data', 701}}})
    L:activate_once(me)
    eq(#me.traps, 1); eq(me.traps[1].id, 701)
    eq(me.traps[1].obj._custom_descriptor, nil)
end)

test("799 棹歌中流: hai ô 生效一次给傀儡加效果 đều đi tới CON RỐI; hiệu ứng 1 nhân theo ô修正", function()
    cfg(45443, 45493)
    cfg3(45444)
    local doll = {get_obj_id = function() return 99 end, get_obj_type = function() return "monster" end,
                  is_alive = function() return true end, get_world_pos = function() return {x = 50, y = 60} end}
    local foe = {__enemy = true, get_obj_id = function() return 31 end,
                 get_obj_type = function() return "human" end, is_alive = function() return true end}
    local L, me = make({logic = 799, objs = {[99] = doll}, scan = {foe},
                        raw = {{'生效一次的效果1(傀儡周围敌人)', 45444}, {'生效一次的效果2(傀儡周围敌人)', -1},
                               {'生效一次给傀儡加效果', 45493}, {'傀儡周围生效人数', 6},
                               {'对效果1伤害的修正，效果1必须用3号伤害类BUFF', 10},
                               {'生效一次给傀儡加效果', 45443}}})
    L:activate_once(me)
    eq(ids(), "45443@99,45444@31,45493@99")
    for _, e in ipairs(SENT) do
        if e.id == 45444 then eq(e.rate, 10, "rate_add: 100 + 10 = 110 → delta 10") end
    end
end)

test("799: chưa có con rối thì ô 给傀儡加效果 rơi về BẢN THÂN như trước", function()
    cfg(45443, 45493)
    local L, me = make({logic = 799, objs = {},
                        raw = {{'生效一次给傀儡加效果', 45493}, {'生效一次给傀儡加效果', 45443},
                               {'傀儡周围生效人数', 6}}})
    L:activate_once(me)
    eq(ids(), "45443@1,45493@1")
end)

test("consumed_labels gom đủ nhãn của các khối mới", function()
    local c = S.consumed_labels(spec_table[769])
    eq(c['七目标伤害'], true); eq(c['主目标断线距离'], true); eq(c['其它目标连线'], true)
    c = S.consumed_labels(spec_table[204])
    eq(c['附加伤害（逻辑3）'], true); eq(c['衰减系数百分比'], true)
    c = S.consumed_labels(spec_table[144])
    eq(c['|替换一段技能id1'], true)
    c = S.consumed_labels(spec_table[149])
    eq(c['|回血百分比'], true)
    c = S.consumed_labels(spec_table[736])
    eq(c['触发3次溅射几率（百分比）'], true)
    c = S.consumed_labels(spec_table[799])
    eq(c['对效果1伤害的修正，效果1必须用3号伤害类BUFF'], true)
end)

test("cy_skill_chain: chủ rời cảnh / chết thì chuỗi dừng, không ném lỗi", function()
    cfg(700)
    local L, me = make({logic = 769, raw = {{'主目标断线距离', 15}, {'其它目标断线距离', 7}, {'主目标伤害', 700}},
                        tar_pos = {x = 12, y = 22}})
    L:activate_once(me)
    me:get_scene().objs[1] = nil                -- chủ không còn trong cảnh
    SENT = {}
    L:activate_each_tick(me)
    eq(#SENT, 0)
end)

-- ---------------------------------------------------------------- std_impact_115
local L115 = require("scene.skill.impact_logic.std_impact_115")

local function imp115(scale, caster_id)
    return {params = {["伤害量缩放系数"] = scale}, caster = caster_id or 7,
            get_caster_obj_id = function(self) return self.caster end,
            get_skill_id = function() return 4538 end,
            get_skill_level = function() return 3 end,
            is_critical_hit = function() return false end}
end

local function obj115(objs)
    local scene = {get_impact_enginer = function() return ENGINE end,
                   get_obj_by_id = function(_, id) return objs[id] end}
    return {is_alive = function() return true end, get_scene = function() return scene end,
            get_obj_type = function() return "monster" end}
end

test("115: dựng impact đòn đánh thường (DataIndex 0) qua CombatCore rồi gây sát thương", function()
    CC_CALLS, DMG_CALLS = {}, {}
    cfg3(0)                                    -- dòng 0 = 普通攻击的伤害效果, logic 3
    local caster = {get_obj_type = function() return "human" end}
    local o = obj115({[7] = caster})
    local L = L115.new()
    L:on_active(imp115(100), o)
    eq(#CC_CALLS, 1); eq(CC_CALLS[1].id, 0); eq(CC_CALLS[1].atk, caster)
    eq(#DMG_CALLS, 1); eq(DMG_CALLS[1].dmg, 200); eq(DMG_CALLS[1].rate, nil, "hệ số 100 → không nhân")
    eq(DMG_CALLS[1].skill, 4538, "chép ID kỹ năng như native newImp[+8] = imp[+8]")
end)

test("115: hệ số ≠ 100 nhân đúng như RefixPowerByRate (delta = hệ số − 100)", function()
    CC_CALLS, DMG_CALLS = {}, {}
    cfg3(0)
    local caster = {get_obj_type = function() return "human" end}
    local L = L115.new()
    L:on_active(imp115(170), obj115({[7] = caster}))
    eq(#DMG_CALLS, 1); eq(DMG_CALLS[1].rate, 70)
    DMG_CALLS = {}
    L:on_active(imp115(70), obj115({[7] = caster}))
    eq(DMG_CALLS[1].rate, -30)
end)

test("115: thiếu người gây / sai loại đối tượng → không gây gì (như native)", function()
    CC_CALLS, DMG_CALLS = {}, {}
    cfg3(0)
    local L = L115.new()
    L:on_active(imp115(100), obj115({}))                       -- không tìm thấy người gây
    eq(#DMG_CALLS, 0)
    L:on_active(imp115(100), obj115({[7] = {get_obj_type = function() return "itembox" end}}))
    eq(#DMG_CALLS, 0)
end)

test("115: dòng 0 không có trong StandardImpact → bỏ qua, không lỗi", function()
    CC_CALLS, DMG_CALLS = {}, {}
    ENGINE.std_impact_config[0] = nil
    local L = L115.new()
    L:on_active(imp115(100), obj115({[7] = {get_obj_type = function() return "human" end}}))
    eq(#DMG_CALLS, 0)
end)

test("115: cờ tức thời khớp native (IsOverTimed/IsIntervaled đều trả 0)", function()
    local L = L115.new()
    eq(L:is_over_timed(), false); eq(L:is_intervaled(), false)
end)

-- ---------------------------------------------------------------- skill-logic-4 (17/09/2026)
-- (A) cy_collection_bridge — điều kiện/驱散 tra tập ID theo bảng CY
local BR = require "cy_collection_bridge"

-- impact giả lập: 互斥ID, 瞬发效果ID (impact_id), 逻辑ID, là hiệu ứng duy trì hay không
local function impc(mutex, seid, over, logic, skill)
    return {get_mutex_id = function() return mutex end,
            get_impact_id = function() return seid end,
            get_logic_id = function() return logic or 0 end,
            get_skill_id = function() return skill or -1 end,
            get_is_over_timed = function() return over ~= false end}
end

local function holder(list)
    local o = {list = list, faded = {}}
    function o:get_impact_list() return self.list end
    function o:on_impact_fade_out(imp) self.faded[#self.faded + 1] = imp end
    function o:remove_impact(imp)
        for i, v in ipairs(self.list) do
            if v == imp then table.remove(self.list, i); return end
        end
    end
    return o
end

test("bridge: tập kiểu 互斥 khớp 互斥ID (催箭式/震箭式 cùng 互斥 105)", function()
    local o = holder({impc(105, 2617, true)})
    eq(BR.has(o, 388), true)
    eq(BR.has(o, 499), false)
end)

test("bridge: tập kiểu 互斥 khớp THÊM 瞬发效果ID (意纵横 互斥 150 / SEid 3653)", function()
    local o = holder({impc(150, 3653, true)})
    eq(BR.has(o, 388), true, "dòng CY giữ 互斥ID cũ của GL, ID CY nằm ở cột 瞬发效果ID")
    -- hiệu ứng KHÔNG duy trì thì không so bằng 瞬发效果ID (như is_impact_in_collection)
    local o2 = holder({impc(150, 3653, false)})
    eq(BR.has(o2, 388), false)
end)

test("bridge: tập kiểu 0 (瞬发效果ID) — 13058 九阳炽脉 ∈ 499, 13059 九阴煞魄 ∈ 376", function()
    eq(BR.has(holder({impc(2631, 2631, true)}), 499), true)
    eq(BR.has(holder({impc(151, 151, true)}), 376), true)
    eq(BR.has(holder({impc(2631, 2631, true)}), 376), false)
end)

test("bridge: tập không có trong bảng CY → không khớp, không lỗi", function()
    eq(BR.has(holder({impc(105, 105, true)}), 9999), false)
    eq(BR.cancel(holder({impc(105, 105, true)}), 9999), 0)
end)

test("bridge: cancel gỡ đúng impact thuộc tập và gọi on_impact_fade_out", function()
    local keep = impc(777, 888, true)
    local o = holder({impc(105, 2617, true), keep, impc(150, 3651, true)})
    eq(BR.cancel(o, 388), 2)
    eq(#o.list, 1); eq(o.list[1], keep); eq(#o.faded, 2)
end)

test("bridge: install bọc logic 0/2/9, GL đúng thì giữ nguyên, GL sai thì thử bảng CY", function()
    local gl_calls = {}
    local function gl(name, ret)
        return {ConditionCheck = function(_, _, _) gl_calls[#gl_calls + 1] = name .. ":cond"; return ret end,
                Deplete = function(_, _, _) gl_calls[#gl_calls + 1] = name .. ":dep"; return true end}
    end
    local core = {logics = {[0] = gl("have", false), [2] = gl("tarhave", false), [9] = gl("cancel", true)}}
    BR.install(core)
    eq(core.__cy_collection_bridge, true)
    BR.install(core)                                  -- idempotent: không bọc hai lần

    local errcode
    local o = holder({impc(2631, 2631, true)})
    function o:get_targeting_and_depleting_params()
        return {set_errcode = function(_, v) errcode = v end, get_target_obj = function() return -1 end}
    end
    -- logic 0: GL trả false, bảng CY có 499 ⇒ ĐẠT
    eq(core.logics[0]:ConditionCheck(o, {params = {499}}), true)
    eq(errcode, 0)
    -- tập không có ở bảng CY ⇒ vẫn theo GL (false)
    eq(core.logics[0]:ConditionCheck(o, {params = {9999}}), false)
    -- logic 9: chạy phép gỡ của GL rồi gỡ thêm theo bảng CY
    local o2 = holder({impc(105, 2617, true)})
    eq(core.logics[9]:Deplete(o2, {params = {388}}), true)
    eq(#o2.list, 0)
    assert(#gl_calls >= 3, "vẫn phải gọi bản GL")
end)

test("bridge: ENABLED = false trả đúng hành vi cũ", function()
    local core = {logics = {[0] = {ConditionCheck = function() return false end, Deplete = function() return true end},
                            [9] = {ConditionCheck = function() return true end, Deplete = function() return true end}}}
    BR.install(core)
    BR.ENABLED = false
    local o = holder({impc(2631, 2631, true)})
    function o:get_targeting_and_depleting_params()
        return {set_errcode = function() end, get_target_obj = function() return -1 end}
    end
    eq(core.logics[0]:ConditionCheck(o, {params = {499}}), false)
    local o2 = holder({impc(105, 2617, true)})
    core.logics[9]:Deplete(o2, {params = {388}})
    eq(#o2.list, 1)
    BR.ENABLED = true
end)

-- (B) scene.special_obj.trap — ô 是否即刻生效一次
local TRAP = require "scene.special_obj.trap"

local function trap_obj(desc, targets)
    local o = {desc = desc, fade = false, times = 1, triggered = nil}
    local scene = {}
    function scene:get_obj_by_id(id) return (id == 9) and {get_obj_id = function() return 9 end} or nil end
    function scene:scan() return targets or {} end
    function scene:get_event_enginer()
        return {register_be_skill_event = function() end, register_skill_hit_event = function() end}
    end
    function o:get_data_record()
        return {descriptor = desc, effect_radious = 5, trigger_radious = 5, affect_count = 3, trap_used_flag = 0}
    end
    function o:get_scene() return scene end
    function o:get_owner_obj_id() return 9 end
    function o:get_world_pos() return {x = 1, y = 2} end
    function o:is_fade_out() return self.fade end
    function o:mark_fade_out_flag() self.fade = true end
    function o:get_active_times() return self.times end
    function o:set_active_times(v) self.times = v end
    function o:on_trigger(t) self.triggered = #t end
    function o:get_power_refix_by_rate() return 0 end
    function o:get_skill_id() return 2901 end
    return o
end

local function char_target()
    local t = {}
    function t:is_character_obj() return true end
    function t:get_obj_id() return 4 end
    return t
end

test("trap: ô 是否即刻生效一次 = 1 + có mục tiêu ⇒ nổ ngay một lần", function()
    TRAP_IMPACTS = {}
    local o = trap_obj({["是否即刻生效一次"] = 1, ["效果1"] = 60001}, {char_target()})
    eq(TRAP:activate_at_once(o), true)
    eq(o.triggered, 1)
    eq(o.times, 0, "đã tiêu một lượt kích hoạt")
    eq(#TRAP_IMPACTS, 1); eq(TRAP_IMPACTS[1].id, 60001)
    eq(TRAP:activate_at_once(o), false, "chỉ một lần cho mỗi vật thể")
end)

test("trap: 3064 万箭齐发 (效果1 = −1) nổ nhưng không gửi impact nào", function()
    TRAP_IMPACTS = {}
    local o = trap_obj({["是否即刻生效一次"] = 1, ["效果1"] = -1, ["效果2"] = -1, ["效果3几率"] = -1}, {char_target()})
    eq(TRAP:activate_at_once(o), true)
    eq(#TRAP_IMPACTS, 0, "bảng SpecialObjData còn thiếu 效果1 — việc của trap-impacts")
end)

-- skill-logic-5: `_custom_descriptor` (trap.lua:19-33) thắng `data.descriptor` — đường mà logic 736 dùng
test("trap: _custom_descriptor thắng ô 效果1 = −1 của bảng (3064 万箭齐发 nay gây sát thương)", function()
    TRAP_IMPACTS = {}
    local o = trap_obj({["是否即刻生效一次"] = 1, ["效果1"] = -1, ["效果2"] = -1, ["效果3几率"] = -1},
                       {char_target()})
    o._custom_descriptor = {["效果1"] = 37331}
    eq(TRAP:activate_at_once(o), true)
    eq(#TRAP_IMPACTS, 1); eq(TRAP_IMPACTS[1].id, 37331)
end)

test("trap: không có ô 是否即刻生效一次 (hoặc = 0) ⇒ KHÔNG đổi hành vi", function()
    TRAP_IMPACTS = {}
    local a = trap_obj({["效果1"] = 60001}, {char_target()})
    eq(TRAP:activate_at_once(a), false); eq(a.times, 1)
    local b = trap_obj({["是否即刻生效一次"] = 0, ["效果1"] = 60001}, {char_target()})
    eq(TRAP:activate_at_once(b), false); eq(b.times, 1)
    eq(#TRAP_IMPACTS, 0)
end)

test("trap: quanh đó chưa có ai ⇒ KHÔNG tiêu lượt kích hoạt (2166/3022 荡千军 sống 10 s)", function()
    TRAP_IMPACTS = {}
    local o = trap_obj({["是否即刻生效一次"] = 1, ["效果1"] = 60001}, {})
    eq(TRAP:activate_at_once(o), false)
    eq(o.times, 1); eq(o.fade, false)
end)

-- (C) 761–765 星阵 (鬼谷): impact MẦM cho chính người tung + phép kẹp 12 mức
local function make_seed(logic, level)
    local L, me, tar = make({logic = logic, raw = {}})
    local params = me:get_targeting_and_depleting_params()
    params.get_skill_level = function() return level end
    return L, me, tar
end

test("761 聚星阵·长生: gửi mầm 4067 + (cấp − 1) cho CHÍNH người tung", function()
    for i = 4067, 4082 do cfg(i) end
    local L, me = make_seed(761, 1)
    L:activate_once(me)
    eq(ids(), "4067@1")
    SENT = {}
    local L4, me4 = make_seed(761, 4)
    L4:activate_once(me4)
    eq(ids(), "4070@1")
end)

test("761: KẸP về 12 mức — cấp 13..16 vẫn ra 4078, không tràn sang dải 破军 (4080+)", function()
    for i = 4067, 4091 do cfg(i) end
    for _, lv in ipairs({12, 13, 16, 99}) do
        SENT = {}
        local L, me = make_seed(761, lv)
        L:activate_once(me)
        eq(ids(), "4078@1", "cấp " .. lv)
    end
end)

test("761: cấp không đọc được / < 1 thì về cấp 1", function()
    for i = 4067, 4078 do cfg(i) end
    for _, lv in ipairs({nil, 0, -5}) do
        SENT = {}
        local L, me = make_seed(761, lv)
        L:activate_once(me)
        eq(ids(), "4067@1")
    end
end)

test("762–765: đúng đầu dải của từng trận", function()
    for i = 4067, 4260 do cfg(i) end
    for logic, first in pairs({[762] = 4080, [763] = 4166, [764] = 4226, [765] = 4238}) do
        SENT = {}
        local L, me = make_seed(logic, 1)
        L:activate_once(me)
        eq(ids(), tostring(first) .. "@1", "logic " .. logic)
    end
end)

test("761: mầm KHÔNG gửi cho mục tiêu nào khác (một 星阵 cho mỗi lần tung)", function()
    for i = 4067, 4078 do cfg(i) end
    local L, me, tar = make_seed(761, 1)
    tar.__enemy = true
    L:activate_once(me)
    eq(#SENT, 1)
    eq(SENT[1].rec:get_obj_id(), 1, "người nhận phải là người tung")
end)

test("bảng đặc tả: 761–765 có khối seed đúng dải, tiers = 12", function()
    local want = {[761] = 4067, [762] = 4080, [763] = 4166, [764] = 4226, [765] = 4238}
    for id, first in pairs(want) do
        local sp = spec_table[id]
        assert(sp and sp.seed, "thiếu khối seed ở logic " .. id)
        eq(sp.seed.first, first, "logic " .. id)
        eq(sp.seed.tiers, 12, "logic " .. id)
    end
end)

-- ---------------------------------------------------------------- skill-logic-5 (17/09)
-- (C2) 208 中冲剑·刃影 — mỗi hệ có 抗性 ≤ 减抗 thì thêm một đòn 六脉神剑 của hệ đó
local function child(skill, level, id)
    CHILD_SKILLS[skill] = CHILD_SKILLS[skill] or {}
    CHILD_SKILLS[skill][level] = {cy_raw_params = {{'附加效果1', id}}}
end

local function setup_liumai()
    CHILD_SKILLS = {}
    child(471, 1, 56899); child(471, 16, 56914)     -- 关冲剑 冰
    child(463, 1, 56834); child(463, 16, 56849)     -- 少商剑 火
    child(481, 1, 56963); child(481, 16, 56978)     -- 少泽剑 电 (玄)
    child(487, 1, 57075); child(487, 16, 57090)     -- 商阳剑 毒
    for _, v in ipairs({56899, 56914, 56834, 56849, 56963, 56978, 57075, 57090}) do cfg3(v) end
end

test("208 中冲剑·刃影: hệ nào có 抗性 ≤ 减抗 thì gửi ô 附加效果1 của chiêu 六脉神剑 hệ đó", function()
    setup_liumai()
    local L, me = make({logic = 208, raw = {{'驱散二式buff集合', 495}},
                        resist = {cold = 10, fire = 50, light = 90, posion = 0},
                        reduce = {cold = 10, fire = 20, light = 90, posion = -5}})
    L:activate_once(me)
    -- 冰 10 ≤ 10 ✔; 火 50 > 20 ✘; 电 90 ≤ 90 ✔; 毒 0 > −5 ✘
    eq(ids(), "56899@2,56963@2")
end)

-- Số THẬT của bàn đo: MonsterAttrExTable đặt 冰/火/电/毒防御 = 60 cho 400/400 dòng đã kiểm, còn
-- 降低目标X抵抗 của người chơi mặc định = 0 ⇒ 60 > 0 ở cả bốn hệ ⇒ ĐÚNG LUẬT là không phát chiêu nào.
-- Đây là lý do đo 826 bằng quái không bao giờ thấy nó nổ (đặc tả mục 17.8), KHÔNG phải mã hỏng.
test("208: kháng quái 60 vs 减抗 0 ở cả bốn hệ ⇒ không thêm đòn nào (đúng luật CY)", function()
    setup_liumai()
    local L, me = make({logic = 208, raw = {{'驱散二式buff集合', 495}},
                        resist = {cold = 60, fire = 60, light = 60, posion = 60},
                        reduce = {cold = 0, fire = 0, light = 0, posion = 0}})
    L:activate_once(me)
    eq(ids(), "")
end)

test("208: người chơi chưa mặc trang bị kháng (0) ⇒ 0 ≤ 0 đạt, phát đủ bốn hệ", function()
    setup_liumai()
    local L, me = make({logic = 208, raw = {{'驱散二式buff集合', 495}},
                        resist = {cold = 0, fire = 0, light = 0, posion = 0},
                        reduce = {cold = 0, fire = 0, light = 0, posion = 0}})
    L:activate_once(me)
    eq(ids(), "56834@2,56899@2,56963@2,57075@2")
end)

test("208: đủ bốn hệ ⇒ bốn đòn, lấy ID của ĐÚNG cấp đang tung", function()
    setup_liumai()
    local L, me = make({logic = 208, raw = {{'驱散二式buff集合', 495}},
                        resist = {cold = 0, fire = 0, light = 0, posion = 0},
                        reduce = {cold = 0, fire = 0, light = 0, posion = 0}})
    me:get_targeting_and_depleting_params().get_skill_level = function() return 16 end
    L:activate_once(me)
    eq(ids(), "56849@2,56914@2,56978@2,57090@2")
end)

test("208: không đọc được cấp ⇒ về cấp 1 (không ném)", function()
    setup_liumai()
    local L, me = make({logic = 208, raw = {{'驱散二式buff集合', 495}},
                        resist = {cold = 0}, reduce = {cold = 0}})
    L:activate_once(me)
    eq(ids(), "56899@2")
end)

test("208: mục tiêu thiếu API kháng (quái/thú) ⇒ bỏ qua, không ném lỗi", function()
    setup_liumai()
    local L, me = make({logic = 208, raw = {{'驱散二式buff集合', 495}}, no_resist_api = true,
                        resist = {cold = 0}, reduce = {cold = 0}})
    L:activate_once(me)
    eq(ids(), "")
end)

test("208: chiêu con không có trong bảng ⇒ bỏ hệ đó, các hệ khác vẫn chạy", function()
    setup_liumai()
    CHILD_SKILLS[471] = nil                       -- 关冲剑 biến mất khỏi bảng
    local L, me = make({logic = 208, raw = {{'驱散二式buff集合', 495}},
                        resist = {cold = 0, fire = 0}, reduce = {cold = 0, fire = 0}})
    L:activate_once(me)
    eq(ids(), "56834@2")
end)

test("bảng đặc tả: [208] có đủ 4 hệ, đúng cặp getter của combat_core", function()
    local sp = spec_table[208]
    assert(sp and sp.resist_cast, "thiếu khối resist_cast")
    eq(sp.resist_cast.impact_label, '附加效果1')
    local want = {[471] = "cold", [463] = "fire", [481] = "light", [487] = "posion"}
    local n = 0
    for _, e in ipairs(sp.resist_cast.by_elem) do
        eq(e.defence, "get_defence_" .. want[e.skill], "chiêu " .. e.skill)
        eq(e.reduce, "get_reduce_def_" .. want[e.skill], "chiêu " .. e.skill)
        n = n + 1
    end
    eq(n, 4, "server chỉ có bốn get_reduce_def_* ⇒ ánh xạ 4↔4")
end)

-- (D) lớp gói GCCharDoAction (`xy_id = 786`) — hoạt ảnh con rối 离人偶 của 桃花岛.
-- Dùng iostream THẬT của server để chuỗi byte là chuỗi byte thật, không phải bản giả lập.
local iostream = require "iostream"
local ok_cypk, CYPK = pcall(require, "game.packet_domains.cy_combat")

local function bind_packet()
    local p = {}
    CYPK.bind(p, iostream.bistream, iostream.bostream, {}, require "define")
    return p
end

test("gói 786: bind đúng một lớp mang xy_id = 786 và một hằng XYID", function()
    assert(ok_cypk, "thiếu services/game/packet_domains/cy_combat.lua: " .. tostring(CYPK))
    local p = bind_packet()
    eq(p.XYID_GC_CHAR_DO_ACTION, 786)
    local n = 0
    for _, v in pairs(p) do
        if type(v) == "table" and v.xy_id == 786 then n = n + 1 end
    end
    eq(n, 1, "net:register_packets ghi self.packets[xy_id] — trùng xy_id là đè nhau")
    eq(p.GCCharDoAction.xy_id, 786)
end)

test("gói 786: bos = ba <i4 theo thứ tự obj_id/action_id/target_id (12 byte)", function()
    local p = bind_packet()
    local msg = p.GCCharDoAction.new()
    msg.obj_id, msg.action_id, msg.target_id = 367, 167, 99
    local buf = msg:bos()
    eq(#buf, 12)
    eq(buf, string.pack('<i4i4i4', 367, 167, 99), "khuôn byte của action_packet.M.bytes")
end)

test("gói 786: khớp TỪNG BYTE với cy_four_combat.action_packet.bytes", function()
    local ok, AP = pcall(require, "cy_four_combat.action_packet")
    if not ok then
        eq(true, true, "không có cy_four_combat trên gốc này — bỏ qua")
        return
    end
    local p = bind_packet()
    for _, case in ipairs({{367, 167, 99}, {1, 0, 2}, {2147483647, 165, 7}, {5, 166, 2147483647}}) do
        local data = AP.new(case[1], case[2], case[3])
        -- đúng cách net:send2client làm: gắn metatable của lớp đã đăng ký rồi gọi bos trên CHÍNH bảng đó
        local inst = p.GCCharDoAction.new()
        setmetatable(data, {__index = inst})
        eq(data:bos(), AP.bytes(data), string.format("obj=%d action=%d target=%d", case[1], case[2], case[3]))
    end
end)

test("gói 786: bảng của action_packet là dữ liệu THUẦN (skynet.pack không nhận function)", function()
    local ok, AP = pcall(require, "cy_four_combat.action_packet")
    if not ok then
        eq(true, true, "không có cy_four_combat trên gốc này — bỏ qua")
        return
    end
    local data = AP.new(367, 167, 99)
    for k, v in pairs(data) do
        eq(type(v) ~= "function" and type(v) ~= "userdata", true, "trường " .. tostring(k))
    end
    eq(rawget(data, "bos"), nil, "bos phải do lớp gói gắn lại, không nằm trong bảng gửi liên dịch vụ")
end)

test("gói 786: bis đọc lại đúng ba số đã ghi", function()
    local p = bind_packet()
    local out = p.GCCharDoAction.new()
    out.obj_id, out.action_id, out.target_id = 12, 165, 34
    local inp = p.GCCharDoAction.new()
    inp:bis(out:bos())
    eq(inp.obj_id, 12); eq(inp.action_id, 165); eq(inp.target_id, 34)
end)

test("gói 786: writer_registered() thấy lớp khi game.packet đã có nó", function()
    local ok, AP = pcall(require, "cy_four_combat.action_packet")
    if not ok then
        eq(true, true, "không có cy_four_combat trên gốc này — bỏ qua")
        return
    end
    AP._registered = nil
    package.loaded["game.packet"] = bind_packet()
    eq(AP.writer_registered(), true)
    AP._registered = nil
    package.loaded["game.packet"] = {}
    eq(AP.writer_registered(), false, "chưa đăng ký thì từ chối gửi, không ném")
end)

print(string.format("skill_logic_tests: %d đạt, %d lỗi", pass, fail))
os.exit(fail == 0 and 0 or 1)
