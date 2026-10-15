local class = require "class"
local base = require "scene.skill.impact_logic.base"
local null_logic_buff = class("null_logic_buff", base)
--514

function null_logic_buff:is_over_timed()
    return true
end

function null_logic_buff:is_intervaled()
    return false
end
-- function null_logic_buff:on_active(imp,obj)
	-- if imp.params["是否神兵"] == 1 then
		-- self:change_shenbing(obj,imp)
	-- end
-- end
-- function null_logic_buff:on_fade_out(imp, obj)
	-- if imp.params["是否神兵"] == 1 then
		-- self:empty_shenbing(obj)
	-- end
-- end

return null_logic_buff