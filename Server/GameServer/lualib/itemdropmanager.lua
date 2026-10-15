local skynet = require "skynet"
local define = require "define"
local class = require "class"
local itemdropmanager = class("itemdropmanager")

function itemdropmanager:getinstance()
    if itemdropmanager.instance == nil then
        itemdropmanager.instance = itemdropmanager.new()
    end
    return itemdropmanager.instance
end

function itemdropmanager:set_scene(scene) self.scene = scene end

function itemdropmanager:get_scene()
    return self.scene
end

function itemdropmanager:ctor() end

function itemdropmanager:caculate_drop_item_box(monster_id)
    local monster_drop_boxs = self:get_scene():get_config_enginer():get_config("monster_drop_boxs")
    local drop_box_content = self:get_scene():get_config_enginer():get_config("drop_box_content")
    --skynet.logi("[DROP] caculate_drop_item_box monster_id =", monster_id)
    local monster_drops = monster_drop_boxs[monster_id]
    local items = {}
    if monster_drops then
        local monster_value = monster_drops.value
        --skynet.logi("[DROP] found monster_drops, Mvalue =", monster_value, ", drops count =", #monster_drops.drops)
        local monster_boxs = {}
        for idx, id in ipairs(monster_drops.drops) do
            if id ~= define.INVAILD_ID then
                local box = drop_box_content[id]
                if box then
                    table.insert(monster_boxs, box)
                    --skynet.logi("[DROP] box", id, "found, BoxValue =", box.value)
                else
                    --skynet.logi("[DROP] WARNING: box", id, "NOT FOUND in drop_box_content!")
                end
            end
        end
        --skynet.logi("[DROP] valid monster_boxs count =", #monster_boxs)
        for _, b in ipairs(monster_boxs) do
            local bvalue = b.value
            local force_bind = b.force_bind == 1
            local current_rate = math.random()
            local base_drop_rate = monster_value / bvalue
            --skynet.logi("[DROP] bvalue =", bvalue, ", monster_value =", monster_value, ", base_drop_rate =", base_drop_rate, ", roll =", current_rate)
            if current_rate <= base_drop_rate then
                local broad_type = b.broad_type
                local bitems = {}
                for _, bi in ipairs(b.items) do
                    if bi.id ~= define.INVAILD_ID then
                        table.insert(bitems, bi)
                    end
                end
                --skynet.logi("[DROP] rate passed! valid items in box =", #bitems)
                if #bitems > 0 then
                    local i = math.random(#bitems)
                    local item = bitems[i]
                    if item then
                        --skynet.logi("[DROP] DROP item id =", item.id, ", broad_type =", broad_type)
                        table.insert(items, { id = item.id, drop_class = broad_type, count = 1, force_bind = force_bind})
                    else
                        --skynet.logi("[DROP] item not find at index", i)
                    end
                end
            end
        end
    else
        local count = 0
        for k, _ in pairs(monster_drop_boxs) do
            count = count + 1
            --if count <= 5 then
            --    skynet.logi("[DROP]   sample key:", k, "type:", type(k))
            --end
        end
        --skynet.logi("[DROP]   total monster_drop_boxs entries:", count)
    end
    --skynet.logi("[DROP] final items count =", #items)
    return items
end

return itemdropmanager