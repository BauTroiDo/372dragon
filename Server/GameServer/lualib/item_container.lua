local skynet = require "skynet"
local class = require "class"
local define = require "define"
local item_cls = require "item"
local guid_cls = require "guid"
local pet_guid_cls = require "pet_guid"
local configenginer = require "configenginer":getinstance()
local item_container = class("item_container")

function item_container:ctor()
    self.size = 0
    self.item_list = {}
    self.initd = false
	self.container_flag = 0
end

function item_container:init(size,item_data_list,container_flag)
    self.size = size
	self.container_flag = container_flag or 0
    if item_data_list then
		local item_index,expiration_date
        for i, data in pairs(item_data_list) do
            i = tonumber(i)
            local item = item_cls.new()
            item:init_from_data(data)
            self:set_item(i - 1, item)
        end
    end
end

function item_container:set_container_flag(container_flag)
	self.container_flag = container_flag or 0
end

function item_container:get_container_flag()
	return self.container_flag or 0
end

function item_container:on_line_check_item_valid_timer()
	local delitempos = {}
	local deltime_tip = {}
	if define.CONTAINER_NAME[self.container_flag] then
		local curtime = os.time()
		local equip_extra_attr = configenginer:get_config("equip_extra_attr")
		for i = 0, (self.size - 1) do
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
								if deltime - curtime < 86400 then
									-- self:item_deltime_mail(name,item_index)
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


function item_container:check_item_valid_timer()
	local delitempos = {}
	if define.CONTAINER_NAME[self.container_flag] then
		local curtime = os.time()
		local equip_extra_attr = configenginer:get_config("equip_extra_attr")
		for i = 0, (self.size - 1) do
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



function item_container:get_empty_index_count()
    local count = 0
    for i = 0, (self.size - 1) do
        local item = self.item_list[i]
        if not item then
            count = count + 1
        end
    end
    return count
end

function item_container:get_size()
    return self.size
end

function item_container:resize(size)
    if size == self.size then
        return true
    end
    if size > self.size then
        self.size = size
        return true
    else
        for i = 0, (self.size - 1) do
            local item = self.item_list[i]
            if item then
                if i >= size then
                    return false
                end
            end
        end
        self.size = size
        return true
    end
end

function item_container:clean_up()
    self.item_list = {}
end

function item_container:get_index_by_guid(guid)
    for i = 0, (self.size - 1) do
        local item = self.item_list[i]
        if item and item.guid == guid then
            return i
        end
    end
end

function item_container:get_index_by_pet_guid(pet_guid)
    local pg = pet_guid_cls.new()
    pg:set(pet_guid.m_uHighSection, pet_guid.m_uLowSection)
    for i = 0, (self.size - 1) do
        local item = self.item_list[i]
        if item then
            if pg == item:get_guid() then
                return i
            end
        end
    end
end

function item_container:get_item_by_type(utype)
    for i = 0, (self.size - 1) do
        local item = self.item_list[i]
        if item and item:get_index() == utype then
            return item
        end
    end
end


function item_container:get_item_count_by_type(item_index)
    local count = 0
    for i = 0, (self.size - 1) do
        local item = self.item_list[i]
        if item and item:get_index() == item_index then
            count = count + item:get_lay_count()
        end
    end
    return count
end


function item_container:get_items_by_type_class_with_bind (utype)
    local items = { bind = {}, not_bind = {}}
    for i = 0, (self.size - 1) do
        local item = self.item_list[i]
        if item and item:get_index() == utype then
            if item:is_bind() then
                table.insert(items.bind, item)
            else
                table.insert(items.not_bind, item)
            end
        end
    end
    return items
end

function item_container:get_item(index)
	if not index or index < 0 then return end
	return self.item_list[index]
end

function item_container:copy_raw_data()
    local raw_data = {}
    for pos = 0, (self.size - 1) do
        local item = self.item_list[pos]
        if item then
            raw_data[pos] = item:copy_raw_data()
        end
    end
    return raw_data
end

function item_container:get_save_data()
    local raw_data = {}
    for pos = 0, (self.size - 1) do
        local item = self.item_list[pos]
        if item then
            local key = tostring(pos + 1)
            raw_data[key] = item:copy_raw_data()
        end
    end
    return raw_data
end

function item_container:get_item_data()
    return self.item_list
end

function item_container:get_no_full_item_index(item_index,is_bind)
	if not is_bind or is_bind == 0 then
		is_bind = false
	else
		is_bind = true
	end
    for i = 0, (self.size - 1) do
        local item = self.item_list[i]
        if item and item:get_index() == item_index and item:can_lay() and item:is_bind() == is_bind then
            if not item:is_full() then
                return i
            end
        end
    end
    return define.INVAILD_ID
end

function item_container:con_index_2_bag_index()

end

function item_container:bag_index_2_item_index()

end

function item_container:is_in_container(bagindex)
    return bagindex >= 0 and bagindex < self.size
end

function item_container:cal_item_space()
    local count = 0
    for i = 0, (self.size - 1) do
        local item = self.item_list[i]
        if not item then
            count = count + 1
        end
    end
    return count
end

function item_container:get_empty_item_index()
    for i = 0, (self.size - 1) do
        local item = self.item_list[i]
        if not item then
            return i
        end
    end
    return define.INVAILD_ID
end

function item_container:get_empty_item_index_expect_index(index)
    for i = 0, (self.size - 1) do
        if i ~= index then
            local item = self.item_list[i]
            if not item then
                return i
            end
        end
    end
    return define.INVAILD_ID
end

function item_container:get_count()
    local count = 0
    for i = 0, (self.size - 1) do
        local item = self.item_list[i]
        if item then
            count = count + 1
        end
    end
    return count
end

function item_container:get_container_size()
    return self.size
end

function item_container:set_item_pw_lock(index, lock)
    local item = self:get_item(index)
    if not item then
        return false
    end
    item:set_item_pw_lock(lock)
end

function item_container:set_item(index, item)
    if index >= 0 and index < self.size then
        self.item_list[index] = item
	else
        self.item_list[index] = nil
    end
end

function item_container:change_size(size)
    self.size = size
end

function item_container:set_item_lay_count(index, count)
    local item = self:get_item(index)
    if not item then
        return false
    end
    item:set_item_lay_count(count)
end

function item_container:dec_item_lay_count(index, count)
    local item = self:get_item(index)
    if not item then
        return false
    end
    local ret = item:dec_lay_count(count)
    if item:get_lay_count() < 1 then
        self:set_item(index, nil)
    end
    return ret
end

function item_container:inc_item_lay_count(index, count)
    local item = self:get_item(index)
    if not item then
        return false
    end
    return item:inc_lay_count(count)
end

function item_container:erase_item(index)
    self.item_list[index] = nil
end

function item_container:remove_item(index)
    self:erase_item(index)
    if self.size > index + 1 then
        for i = index + 1, self.size do
            assert(self:get_item(i - 1) == nil, i)
            local item = self:get_item(i)
            self:set_item(i - 1, item)
            self:set_item(i, nil)
        end
    end
end

function item_container:set_item_dur(index, dur)
    local item = self:get_item(index)
    if not item then
        return false
    end
    local cls = item:get_class()
    if cls ~= define.ITEM_CLASS.ICLASS_EQUIP then
        return false
    end
    local data =item:get_equip_data()
    data.cur_dur_point = dur
    return true
end

function item_container:set_item_damage_point(index, point)
    local item = self:get_item(index)
    if not item then
        return false
    end
    local cls = item:get_class()
    if cls ~= define.ITEM_CLASS.ICLASS_EQUIP then
        return false
    end
    local data =item:get_equip_data()
    data.cur_damage_point = point
end

function item_container:set_item_max_dur(index, max_dur)
    local item = self:get_item(index)
    if not item then
        return false
    end
    local cls = item:get_class()
    if cls ~= define.ITEM_CLASS.ICLASS_EQUIP then
        return false
    end
    local data =item:get_equip_data()
    assert(max_dur <= 255, "equip max dur 255")
    data.max_dur_point = max_dur
    return true
end

function item_container:set_item_bind(index)
    local item = self:get_item(index)
    if not item then
        return false
    end
    item:set_is_bind(true)
    return true
end

function item_container:set_item_ident(index)
    local item = self:get_item(index)
    if not item then
        return false
    end
    item:set_ident(true)
end

function item_container:set_item_fail_times(index, times)
    local item = self:get_item(index)
    if not item then
        return false
    end
    local cls = item:get_class()
    if cls ~= define.ITEM_CLASS.ICLASS_EQUIP then
        return false
    end
    item:set_item_fail_times(times)
    return true
end

function item_container:add_item_attr(index, ia)
    local item = self:get_item(index)
    if not item then
        return false
    end
    local data = item:get_equip_data()
    table.insert(data.attr, ia)
    return true
end

function item_container:set_item_guid(index, guid)
    local item = self:get_item(index)
    if not item then
        return false
    end
    item:set_guid(guid)
    return true
end

function item_container:set_item_pet_guid(index, guid)
    local item = self:get_item(index)
    if not item then
        return false
    end
    item:set_guid(guid)
end

function item_container:set_item_creator(index, creator)
    local item = self:get_item(index)
    if not item then
        return false
    end
    item:set_creator(creator)
end

function item_container:set_item_param(index, start, utype, value)
    local item = self:get_item(index)
    if not item then
        return false
    end
    item:set_param(start, utype, value)
end

function item_container:get_item_by_guid(guid)
    for i = 0, (self.size - 1) do
        local item = self.item_list[i]
        if item and item:get_guid() == guid then
            return item
        end
    end
end

function item_container:get_index_by_type(item_index)
    for i = 0, (self.size - 1) do
        local item = self.item_list[i]
        if item:get_index() == item_index then
            return i
        end
    end
end

return item_container