local class = require "class"
local pet_guid = require "pet_guid"
local pet_detail = require "pet_detail"
local item_container = require "item_container"
local pet_container = class("pet_container", item_container)

function pet_container:init(size, item_data_list,container_flag, owner)
    assert(self.initd == false, "pet_container::init need not initd")
    self.size = size
    if item_data_list then
        for i, data in pairs(item_data_list) do
            local item = pet_detail.new()
            item:init_from_data(data, owner)
            self:set_item(i - 1, item)
        end
    end
    self.initd = true
	-- self:set_container_flag(container_flag)
end

function pet_container:get_pet_by_guid(guid)
    for i = 0, (self.size - 1) do
        local pet = self.item_list[i]
        if pet then
            local pg = pet:get_attrib("guid")
            local p_guid = pet_guid.new()
            p_guid:set(pg.m_uHighSection, pg.m_uLowSection)
            if p_guid == guid then
                return pet
            end
        end
    end
end

return pet_container