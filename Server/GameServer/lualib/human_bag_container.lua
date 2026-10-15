local inventory_guard = require "cys_inventory_guard"
local skynet = require "skynet"
local class = require "class"
local define = require "define"
local configenginer = require "configenginer":getinstance()
local item_container = require "item_container"
local human_item_logic = require "human_item_logic"
local human_bag_container = class("human_bag_container", item_container)
local bag_start = {
    prop = 0,
    material = 100,
    task = 200
}

function human_bag_container:set_size(size)
    if not inventory_guard.resize_ok(self, size) then return nil end
    self.size = {prop=size.prop, material=size.material, task=size.task}
    return {}
end

function human_bag_container:on_line_check_item_valid_timer()
	local delitempos = {}
	local deltime_tip = {}
	if self.container_flag < 10 then
		local curtime = os.time()
		local equip_extra_attr = configenginer:get_config("equip_extra_attr")
		for i = 0,199 do
			local item = self.item_list[i]
			if item then
				item_index = item:get_index()
				if equip_extra_attr[item_index] then
					expiration_date = equip_extra_attr[item_index].expiration_date
					if expiration_date and expiration_date ~= define.INVAILD_ID then
						local acttime = item:get_param(0,"uint")
						if acttime > 0 then
							local dt = {}
							dt.year, dt.month, dt.day, dt.hour, dt.min = string.match(tostring(acttime), "(%d%d)(%d%d)(%d%d)(%d%d)(%d%d)")
							dt.year = dt.year + 2000
							local deltime = os.time(dt)
							deltime = deltime + expiration_date * 3600
							item:set_item_record_data_forindex("deltime",deltime)
							if curtime < deltime then
								-- item:set_item_record_data_forindex("deltime",deltime)
								if deltime - curtime < 86400 then
									table.insert(deltime_tip,i)
								end
							else
								table.insert(delitempos,i)
							end
						end
					end
				end
			end
		end
	end
	return delitempos,deltime_tip
end
function human_bag_container:check_item_valid_timer()
	local delitempos = {}
	if define.CONTAINER_NAME[self.container_flag] then
		local curtime = os.time()
		local equip_extra_attr = configenginer:get_config("equip_extra_attr")
		for i = 0,199 do
			local item = self.item_list[i]
			if item then
				local deltime = item:get_item_record_data_forindex("deltime")
				if deltime and deltime < curtime then
					table.insert(delitempos,i)
				end
			end
		end
	end
	return delitempos
end


function human_bag_container:get_empty_item_index(bag)
    local start = bag_start[bag]
    local size = self.size[bag] - 1
    for i = start, start + size do
        if not self.item_list[i] then
            return i
        end
    end
    return define.INVAILD_ID
end

function human_bag_container:get_empty_index_count(bag)
    local count = 0
    local start = bag_start[bag]
    local size = self.size[bag] - 1
    for i = start, start + size do
        if self.item_list[i] == nil then
            count = count + 1
        end
    end
    return count
end

function human_bag_container:get_item_pos_by_type(utype)
    local bag = "task"
    local start = bag_start[bag]
    local size = self.size[bag]
    for i = 0, (start + size - 1) do
        local item = self.item_list[i]
        if item and item:get_index() == utype then
            return i
        end
    end
    return define.INVAILD_ID
end

function human_bag_container:get_bag_pos_by_item_sn_available_bind(itemsn, is_bind)
    local bag = "task"
    local start = bag_start[bag]
    local size = self.size[bag]
    for i = 0, (start + size - 1) do
        local item = self.item_list[i]
        if item and item:get_index() == itemsn and item:is_bind() == is_bind then
            return i
        end
    end
    return define.INVAILD_ID
end

function human_bag_container:get_item_count_by_type(item_index)
    local bag = "task"
    local start = bag_start[bag]
    local size = self.size[bag]
    local count = 0
    for i = 0, (start + size - 1) do
        local item = self.item_list[i]
        if item and item:get_index() == item_index then
            count = count + item:get_lay_count()
        end
    end
    return count
end

function human_bag_container:get_items_by_type_class_with_bind(utype)
    local items = { bind = {}, not_bind = {}}
    local bag = "task"
    local start = bag_start[bag]
    local size = self.size[bag]
    for i = 0, (start + size - 1) do
        local item = self.item_list[i]
        if item and item:get_index() == utype then
            if item:is_bind() then
                items.bind[i] = item
            else
                items.not_bind[i] = item
            end
        end
    end
    return items
end

function human_bag_container:get_no_full_item_index(item_index, is_bind)
	if not is_bind or is_bind == 0 then
		is_bind = false
	else
		is_bind = true
	end
    local bag = human_item_logic:get_place_bag(item_index)
    for i, item in self:ipairs(bag) do
        if item then
            if item:get_index() == item_index and item:can_lay() and item:is_bind() == is_bind then
                if not item:is_full() and not item:is_lock() then
                    return i
                end
            end
        end
    end
    return define.INVAILD_ID
end

function human_bag_container:copy_raw_data()
    local raw_data = {}
    local bag = "task"
    local start = bag_start[bag]
    local size = self.size[bag]
    for pos = 0, (start + size - 1) do
        local item = self.item_list[pos]
        if item then
            raw_data[pos] = item:copy_raw_data()
        end
    end
    return raw_data
end

function human_bag_container:get_save_data()
    local raw_data = {}
    local bag = "task"
    local start = bag_start[bag]
    local size = self.size[bag]
    for pos = 0, (start + size - 1) do
        local item = self.item_list[pos]
        if item then
            local key = tostring(pos + 1)
            raw_data[key] = item:copy_raw_data()
        end
    end
    return raw_data
end

function human_bag_container:ipairs(bag)
    local start = bag_start[bag]
    local size = self.size[bag]
    local i = start
    return function()
        i = i + 1
        if i > (start + size) then
            return
        else
            return i - 1, self.item_list[i - 1]
        end
    end
end

function human_bag_container:get_container_size(bag)
    return self.size[bag]
end

function human_bag_container:set_item(index, item)
    local checked_item = item
    if self._cys_loading then checked_item = nil end
    if not inventory_guard.accepts(self, index, checked_item) then return false end
    self.item_list[index] = item
    return true
end

function human_bag_container:cal_item_space(bag)
    local size = self.size[bag]
    local start = bag_start[bag]
    local count = 0
    for i = start, (start + size - 1) do
        if self.item_list[i] == nil then
            count = count + 1
        end
    end
    return count
end

function human_bag_container:get_count(bag)
    local size = self.size[bag]
    local start = bag_start[bag]
    local count = 0
    for i = start, (start + size - 1) do
        if self.item_list[i] then
            count = count + 1
        end
    end
    return count
end

function human_bag_container:get_item_by_guid(guid)
    local raw_data = {}
    local bag = "task"
    local start = bag_start[bag]
    local size = self.size[bag]
    for pos = 0, (start + size - 1) do
        local item = self.item_list[pos]
        if item and item:get_guid() == guid then
            return item
        end
    end
end

function human_bag_container:get_index_by_guid(guid)
    local raw_data = {}
    local bag = "task"
    local start = bag_start[bag]
    local size = self.size[bag]
    for pos = 0, (start + size - 1) do
        local item = self.item_list[pos]
        if item and item:get_guid() == guid then
            return pos
        end
    end
end

function human_bag_container:test_can_change_size(bag, change)
    local start = bag_start[bag]
    local size = self.size[bag] - 1
    local new_size = start + size + change
    for i = start, start + size do
        if self.item_list[i] and i > new_size  then
            return false
        end
    end
    return true
end

function human_bag_container:check_place_index_legally(place_index, bag)
    local start = bag_start[bag]
    local stop = self.size[bag] - 1 + start
    return place_index >= start and place_index <= stop
end

function human_bag_container:get_rand_not_expensive_item_pos()
    local poss = {}
    local pos = define.INVAILD_ID
    for i = 0, bag_start.task - 1 do
        local item = self.item_list[i]
        if item then
            if not item:is_expensive() then
                table.insert(poss, i)
            end
        end
    end
    if #poss > 0 then
        return poss[math.random(#poss)]
    end
    return pos
end

-- CYS-INV load all persisted CY slots before applying equipment capacity.
-- Overflow stays in the saved record, inaccessible until the proper bag is worn.
function human_bag_container:init(size, data, flag)
    self._cys_loading = true
    item_container.init(self, {prop=100, material=100, task=20}, data, flag)
    self._cys_loading = nil
    self.size = size
end

return human_bag_container