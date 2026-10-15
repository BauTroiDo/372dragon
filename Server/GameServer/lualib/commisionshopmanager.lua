local skynet = require "skynet"
local class = require "class"
local define = require "define"
local commisionshopmanager = class("commisionshopmanager")
local CONTAINER_SIZE = 20
function commisionshopmanager:getinstance()
    if commisionshopmanager.instance == nil then
        commisionshopmanager.instance = commisionshopmanager.new()
    end
    return commisionshopmanager.instance
end

function commisionshopmanager:set_scene(scene)
    self.scene = scene
end

function commisionshopmanager:get_scene()
    return self.scene
end

function commisionshopmanager:get_merchadise_list_by_grade(grade)
    grade = tostring(grade)
    return self.shops.grades[grade] or {}
end

function commisionshopmanager:get_merchadise_by_serial(serial)
    for _, grade in pairs(self.shops.grades) do
        for _, merchadise in pairs(grade) do
            if merchadise.serial == serial then
                return merchadise
            end
        end
    end
end

function commisionshopmanager:mark_merchadise_sold_out_by_serial(serial)
    self.shops.sold_out = self.shops.sold_out or {}
    for _, grade in pairs(self.shops.grades) do
        for key, merchadise in pairs(grade) do
            if merchadise.serial == serial then
                grade[key] = nil
                table.insert(self.shops.sold_out, merchadise)
                self:save_to_db()
                return
            end
        end
    end
end

function commisionshopmanager:get_sold_out_merchadise_by_name(seller)
    local merchadises = {}
    self.shops.sold_out = self.shops.sold_out or {}
    for i = #self.shops.sold_out, 1, -1 do
        local merchadise = self.shops.sold_out[i]
        if merchadise.seller == seller then
            table.insert(merchadises, table.remove(self.shops.sold_out, i))
        end
    end
    self:save_to_db()
    return merchadises
end

function commisionshopmanager:get_time_out_merchadise_by_name(seller)
    local merchadises = {}
    self.shops.time_out = self.shops.time_out or {}
    for i = #self.shops.time_out, 1, -1 do
        local merchadise = self.shops.time_out[i]
        if merchadise.seller == seller then
            table.insert(merchadises, table.remove(self.shops.time_out, i))
        end
    end
    self:save_to_db()
    return merchadises
end

function commisionshopmanager:get_empty_index_by_grade(grade)
    grade = tostring(grade)
    local grades = self.shops.grades or {}
    local this_grade = grades[grade] or {}
    for i = 1, CONTAINER_SIZE do
        if this_grade[tostring(i)] == nil then
            return i
        end
    end
end

function commisionshopmanager:set_item_by_grade_with_index(grade, index, item)
    grade = tostring(grade)
    index = tostring(index)
    local grades = self.shops.grades or {}
    local this_grade = grades[grade] or {}
    assert(this_grade[index] == nil, index)
    item.serial = self:inc_serial()
    item.timeout_time = os.time() + 6 * 60 * 60
    this_grade[index] = item
    self.shops.grades[grade] = this_grade
    self:save_to_db()
end

function commisionshopmanager:inc_serial()
    self.shops.serial = self.shops.serial + 1
    return self.shops.serial
end

function commisionshopmanager:save_to_db()
    local updater = {}
    updater["$set"] = self.shops
    skynet.call(".db", "lua", "update", {
        collection = "commisionshop",
        update = updater,
        upsert = true,
        multi = false
    })
end

function commisionshopmanager:load()
    local shops = skynet.call(".db", "lua", "findOne", {
        collection = "commisionshop"
    })
    return shops or { grades = { ["0"] = {}, ["1"] = {}, ["2"] = {}}, serial = 0}
end

function commisionshopmanager:init(scene)
    self.shops = self:load()
    self:set_scene(scene)
end

function commisionshopmanager:heart_beat()
    if self.scene == nil then
        return
    end
    local scene = self:get_scene()
    if scene:get_id() ~= 0 then
        return
    end
    local now = os.time()
    local dirty = false
    self.shops.time_out = self.shops.time_out or {}
    for _, grade in pairs(self.shops.grades) do
        for key, merchadise in pairs(grade) do
            if merchadise.timeout_time < now then
                self:get_scene():get_script_engienr():call(define.COMMISION_SHOP_SCRIPT_ID, "TimeOutCommission", 0, merchadise.serial)
                table.insert(self.shops.time_out, merchadise)
                grade[key] = nil
                dirty = true
            end
        end
    end
    if dirty then
        self:save_to_db()
    end
end

return commisionshopmanager