local class = require "class"
local define = require "define"
local impact = require "scene.skill.impact"
local impact_data = class("impact_data")

function impact_data:ctor()
    self.list = {}
end

function impact_data:init_from_db_data(data)
    local impacts = data.impact_list
	for i = #impacts,1,-1 do
        local imp_data = impacts[i]
		local logic_id = imp_data.logic_id
		-- skill-logic guard: CY ImpactCore_T::InitImpactFromData @0xa87fee — không có dòng StandardImpact cho
		-- data_index thì trả 0 và người gọi bỏ qua. Buff lưu trong DB trỏ tới dòng đã biến mất
		-- (bảng impact đổi) sẽ làm nhân vật không đăng nhập được, nên bỏ ở đây luôn.
		local di = imp_data.data_index
		local has_row = true
		if di then
			local ok_cfg, eng = pcall(function() return require("impactenginer"):getinstance() end)
			if ok_cfg and eng and type(eng.std_impact_config) == "table" then
				has_row = eng.std_impact_config[di] ~= nil
			end
		end
		if not has_row then
			require("skynet").logi("[impact_data] bo qua buff luu san khong con dong StandardImpact, data_index =", di)
			table.remove(impacts,i)
		elseif not logic_id
		or logic_id < 0
		or logic_id == 86 then
			table.remove(impacts,i)
		else
			local imp = impact.new()
			imp:init_from_data(imp_data)
			imp:set_caster_obj_id(define.INVAILD_ID)
			self:get_obj():register_impact(imp)
		end
	end
    -- for i = 1, #impacts do
        -- local imp_data = impacts[i]
		-- local logic_id = imp_data.logic_id
		-- if not logic_id
		-- or logic_id < 0
		-- or logic_id == 86 then
			-- table.insert(del_imp,i)
		-- else
			-- local imp = impact.new()
			-- imp:init_from_data(imp_data)
			-- imp:set_caster_obj_id(define.INVAILD_ID)
			-- self:get_obj():register_impact(imp)
		-- end
    -- end
	-- for i = #del_imp,1,-1 do
		-- table.remove(data.impact_list,i)
	-- end
end

function impact_data:set_obj(obj)
    self.obj = obj
end

function impact_data:get_obj()
    return self.obj
end

function impact_data:get_list()
    return self.list
end

return impact_data