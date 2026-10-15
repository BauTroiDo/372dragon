local class = require "class"
local define = require "define"
local skynet = require "skynet"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.special_obj.base"
local trap = class("trap", base)
trap.type = base.eSpecailObjType.TRAP_OBJ
trap.MASK_ACTIVATE_WHEN_FADE_OUT = 1
trap.MASK_TRIGGER_BY_CHARACTER = 2
trap.MASK_TRIGGER_BY_TRAP = 4

function trap:ctor()
end

function trap:get_type()
    return self.type
end

function trap:get_impact(obj, key)
    -- 优先使用 per-instance 描述符覆盖（由 std_impact_543 等外部逻辑动态设置）
    if obj._custom_descriptor and obj._custom_descriptor[key] then
        return obj._custom_descriptor[key]
    end
    local data = obj:get_data_record()
    return data.descriptor[key]
end

function trap:impact_activate_odds(obj, key)
    if obj._custom_descriptor and obj._custom_descriptor[key] then
        return obj._custom_descriptor[key]
    end
    local data = obj:get_data_record()
    return data.descriptor[key]
end

function trap:force_activate(obj)
    if not obj:is_fade_out() then
        self:activate(obj)
        self:force_fade_out(obj)
    end
end

function trap:force_fade_out(obj)
    if self:activate_when_fade_out(obj) then
        self:activate(obj)
    end
    obj:mark_fade_out_flag()
end

function trap:on_tick(obj)
    if self:trigger_check(obj) then
        self:activate(obj)
    end
end

function trap:trigger_check(obj)
    local scene = obj:get_scene()
    local data = obj:get_data_record()
    if data == nil then
        return false
    end
    if not self:can_be_character_activate(obj) then
        return false
    end
    local position = obj:get_world_pos()
    local radious = data.trigger_radious
    local affect_count = data.affect_count
    local owner_obj_id = obj:get_owner_obj_id()
    local owner = obj:get_scene():get_obj_by_id(owner_obj_id)
    if owner then
        local operate = {scaner = obj, obj = owner, x = position.x, y = position.y, target_logic_by_stand = 1, radious = radious, count = affect_count}
        local targets= scene:scan(operate)
        if #targets > 0 then
            return true
        end
    end
    return false
end

function trap:activate(obj)
    if obj:is_fade_out() then
        return
    end
    local scene = obj:get_scene()
    if scene == nil then
        return
    end
    local data = obj:get_data_record()
    if data == nil then
        return
    end
    if obj:get_active_times() == 0 then
        obj:mark_fade_out_flag()
        return
    end
    local times = obj:get_active_times()
    if times > 0 then
        obj:set_active_times(times - 1)
    end
    local position = obj:get_world_pos()
    local radious = data.effect_radious
    local affect_count = data.affect_count
    local owner_obj_id = obj:get_owner_obj_id()
    local owner = obj:get_scene():get_obj_by_id(owner_obj_id)
	if not owner then
		return
	end
    local operate = {scaner = obj, obj = owner, x = position.x, y = position.y, target_logic_by_stand = 1, radious = radious, count = affect_count}
    local targets = scene:scan(operate)
    obj:on_trigger(targets)
    for _, obj_tar in ipairs(targets) do
        if obj_tar:is_character_obj() then
            self:effect_on_char(obj, obj_tar)
        end
    end
end

function trap:effect_on_char(obj_me, obj_tar)
    local scene = obj_me:get_scene()
    local owner = scene:get_obj_by_id(obj_me:get_owner_obj_id())
	local refix_by_rate = obj_me:get_power_refix_by_rate()
	local skill_id = obj_me:get_skill_id()
    scene:get_event_enginer():register_be_skill_event(obj_tar, owner, define.ENUM_BEHAVIOR_TYPE.BEHAVIOR_TYPE_HOSTILITY, 500)
    -- 触发命中事件，使天赋 on_hit_target 回调能被飞剑正确触发
    scene:get_event_enginer():register_skill_hit_event(owner, obj_tar, skill_id, 0)
	-- [2026-09-17] CYS: tat log moi lan bay danh trung (mot dong / muc tieu) — bat lai khi can go loi bay.
	-- skynet.error("[TRAP] register_skill_hit_event: owner=", owner and owner:get_obj_id() or "nil", " target=", obj_tar:get_obj_id(), " skill_id=", skill_id)
	local extra_ng_rate = obj_me._potianshi_rate or 0
	local impact_data_index = self:get_impact(obj_me, "效果1") or define.INVAILD_ID
    if impact_data_index ~= define.INVAILD_ID then
        impactenginer:send_impact_to_unit(obj_tar,impact_data_index,owner,500,false,refix_by_rate,skill_id,extra_ng_rate)
    end
    impact_data_index = self:get_impact(obj_me, "效果2") or define.INVAILD_ID
    if impact_data_index ~= define.INVAILD_ID then
        impactenginer:send_impact_to_unit(obj_tar,impact_data_index,owner,500,false,refix_by_rate,skill_id)
    end
    impact_data_index = self:get_impact(obj_me, "效果4") or define.INVAILD_ID
    if impact_data_index ~= define.INVAILD_ID then
        impactenginer:send_impact_to_unit(obj_tar,impact_data_index,owner,500,false,refix_by_rate,skill_id)
    end
    local rand = math.random(100)
    local odds = self:impact_activate_odds(obj_me, "效果3几率") or define.INVAILD_ID
    if rand < odds then
        impact_data_index = self:get_impact(obj_me, "效果3") or define.INVAILD_ID
        if impact_data_index ~= define.INVAILD_ID then
			impactenginer:send_impact_to_unit(obj_tar,impact_data_index,owner,500,false,refix_by_rate,skill_id)
        end
    end
    return true
end

function trap:effect_on_trap(obj_me)
end

function trap:on_time_over(obj_me)
    if self:activate_when_fade_out(obj_me) then
        self:activate(obj_me)
    end
end

function trap:activate_when_fade_out(obj_me)
    local data_record = obj_me:get_data_record()
    local trap_used_flag = data_record.trap_used_flag
    return trap_used_flag & trap.MASK_ACTIVATE_WHEN_FADE_OUT == trap.MASK_ACTIVATE_WHEN_FADE_OUT
end

function trap:can_be_character_activate(obj_me)
    local data_record = obj_me:get_data_record()
    local trap_used_flag = data_record.trap_used_flag
    return trap_used_flag & trap.MASK_TRIGGER_BY_CHARACTER == trap.MASK_TRIGGER_BY_CHARACTER
end

function trap:is_scaned_target_vaild()

end


-- skill-logic-4 (17/09/2026): ô `是否即刻生效一次` của SpecialObjData (110 dòng có ô này, 64 dòng đặt 1).
-- Bẫy 3064 「万箭齐发」 (bẫy của 2901, logic kỹ năng 736) có `陷阱专用标记 = 0` ⇒ `can_be_character_activate`
-- và `activate_when_fade_out` đều sai ⇒ không có đường nổ nào khác; chỉ ô này mới làm nó chạy.
-- Không gắn vào vòng đời chung của special_obj: NGƯỜI TẠO bẫy gọi `activate_at_once` ngay sau khi tạo,
-- nên các bẫy đang chạy (đặt bởi skill_260/261, std_impact_*, cy_four_combat) giữ nguyên hành vi cũ.
function trap:activate_at_once_flag(obj)
    local ok, data = pcall(obj.get_data_record, obj)
    if not ok or type(data) ~= "table" or type(data.descriptor) ~= "table" then
        return false
    end
    return (tonumber(data.descriptor["是否即刻生效一次"]) or 0) == 1
end

-- có mục tiêu hợp lệ trong 影响半径 chưa. Quét RIÊNG (không gọi `activate`) để không tiêu mất một lượt
-- `可激活次数` của những bẫy sống lâu như 2166/3022/3058 荡千军 khi quanh đó chưa có ai.
function trap:has_target_in_range(obj)
    local scene = obj:get_scene()
    local data = obj:get_data_record()
    if scene == nil or data == nil then
        return false
    end
    local owner = scene:get_obj_by_id(obj:get_owner_obj_id())
    if not owner then
        return false
    end
    local position = obj:get_world_pos()
    local targets = scene:scan({scaner = obj, obj = owner, x = position.x, y = position.y,
                                target_logic_by_stand = 1, radious = data.effect_radious,
                                count = data.affect_count})
    return type(targets) == "table" and #targets > 0
end

function trap:activate_at_once(obj)
    if obj == nil or obj._cy_trap_acted_now then
        return false
    end
    obj._cy_trap_acted_now = true          -- chỉ một lần cho mỗi vật thể, kể cả khi gọi lại
    local okf, flag = pcall(self.activate_at_once_flag, self, obj)
    if not okf or not flag then
        return false
    end
    local okt, has = pcall(self.has_target_in_range, self, obj)
    if not okt or not has then
        return false
    end
    local oka, err = pcall(self.activate, self, obj)
    if not oka then
        skynet.error("[trap] activate_at_once loi", err)
        return false
    end
    return true
end

return trap