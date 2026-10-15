local define = require "define"
local class = require "class"
local configenginer = require "configenginer":getinstance()
local scriptenginer = require "scriptenginer":getinstance()
local typegrowpointmanager = require "typegrowpointmanager"
local growpointenginer = class("growpointenginer")
function growpointenginer:getinstance()
    if growpointenginer.instance == nil then
        growpointenginer.instance = growpointenginer.new()
    end
    return growpointenginer.instance
end

function growpointenginer:ctor()
    self.scene = nil
    self.type_of_growpoints = {}
end

function growpointenginer:set_scene(scene)
    self.scene = scene
end

function growpointenginer:get_scene()
    return self.scene
end

function growpointenginer:loadall()
    local scn = self:get_scene():get_scn()
    if scn and scn.System then
        local data_file = scn.System.growpointdata
        local setup_file = scn.System.growpointsetup
        self:load_data(data_file)
        self:load_set_up(setup_file)
        if self.grow_up_config and self.set_up_config then
            self:load()
        end
    end
end

function growpointenginer:load_data_and_set_up(growpointdata, growpointsetup)
    local data_file = growpointdata
    local setup_file = growpointsetup
    self:load_data(data_file)
    self:load_set_up(setup_file)
    if self.grow_up_config and self.set_up_config then
        self:load()
    end
end

function growpointenginer:load()
    self.type_of_growpoints = {}
    self.grow_point_type_count = 0
    for _, gp in ipairs(self.grow_up_config) do
        local type = gp.type
        gp.rand = math.random(0x7fff)
        if self.type_of_growpoints[type] == nil then
            self.type_of_growpoints[type] = typegrowpointmanager.new()
            self.type_of_growpoints[type]:set_grow_point_type(type)
            self.grow_point_type_count = self.grow_point_type_count + 1
        end
        self.type_of_growpoints[type]:add_data(gp)
        self.type_of_growpoints[type]:inc_count()
    end
    for _, type_of_grow_point in pairs(self.type_of_growpoints) do
        type_of_grow_point:set_current_count(0)
        local setup = self:get_type_grow_point_set_up(type_of_grow_point:get_grow_point_type())
        type_of_grow_point:set_max_appera_count(setup["数量"])
        type_of_grow_point.enable = true
        local type_info = self:get_type_info_of_grow_point(type_of_grow_point:get_grow_point_type())
        type_of_grow_point.script_id = type_info["脚本ID"]
        type_of_grow_point.interval_per_seed = setup["种子补充的间隔时间"]
        type_of_grow_point:rand_sort()
    end
end

function growpointenginer:get_type_grow_point_set_up(type)
    for _, setup in ipairs(self.set_up_config) do
        if setup["类型"] == type then
            return setup
        end
    end
end

function growpointenginer:get_type_info_of_grow_point(type)
    local grow_point = configenginer:get_config("grow_point")
    return grow_point[type]
end

function growpointenginer:load_data(data_file)
    self.grow_up_config = {}
    local read = require "txtreader".new()
    local configs = read:load(string.format("scene/%s", data_file))
    for _, config in ipairs(configs) do
        local id = config["INT"][1]
        local type = config["INT"][2]
        local x = config["FLOAT"][1]
        local y = config["FLOAT"][2]
        local grow_up = { id = id, type = type,  x = x, y =y }
        table.insert(self.grow_up_config, grow_up)
    end
end

function growpointenginer:load_set_up(setup_file)
    local read = require "txtreader".new()
    local configs = read:load(string.format("scene/%s", setup_file))
    self.set_up_config = configs
end

function growpointenginer:dec_grow_point_type_count(type, x, y)
    if self.type_of_growpoints[type] then
        self.type_of_growpoints[type]:release_grow_point_pos(x, y)
    end
end

function growpointenginer:heart_beat()
    for _, type_of_grow_point in pairs(self.type_of_growpoints) do
        if type_of_grow_point:do_ticks() then
            local r, x, y = type_of_grow_point:create_grow_point_pos()
            if r then
                if type_of_grow_point.script_id then
                    if not self:call_script_create_func(type_of_grow_point.script_id, x, y, type_of_grow_point:get_grow_point_type()) then
                        type_of_grow_point:release_grow_point_pos(x, y)
                    end
                end
            end
        end
    end
end

function growpointenginer:call_script_create_func(script_id, x, y, item_box_type)
    scriptenginer:call(script_id, "OnCreate", item_box_type, x, y, 10 * 60 * 1000)
    return true
end

function growpointenginer:call_script_open_box_func(script_id, selfId, targetId)
    return scriptenginer:call(script_id, "OnOpen", selfId, targetId) or define.OPERATE_RESULT.OR_OK
end

function growpointenginer:call_script_recycle_func(script_id, selfId, targetId)
    return scriptenginer:call(script_id, "OnRecycle", selfId, targetId)
end

function growpointenginer:call_script_proc_over_func(script_id, selfId, targetId)
    return scriptenginer:call(script_id, "OnProcOver", selfId, targetId)
end

return growpointenginer
