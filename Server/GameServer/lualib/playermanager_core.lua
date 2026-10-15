local skynet = require "skynet"
require "skynet.manager"
local gbk = require "wire_charset"
local define = require "define"
local class = require "class"
local utils = require "utils"
local default_char = require "default_char"
local configenginer = require "configenginer":getinstance()
local playermanager_core = class("playermanager_core")
local CDATACENTER_GUID_KEY = "CDATACENTER_GUID_KEY"

function playermanager_core:getinstance()
    if playermanager_core.instance == nil then
        playermanager_core.instance = playermanager_core.new()
    end
    return playermanager_core.instance
end

function playermanager_core:ctor()

end

function playermanager_core:init()
    -- 不再 loadall，依赖 get_config 按需自动加载
    local guid = skynet.call(".CDATACENTERD", "lua", "QUERY", CDATACENTER_GUID_KEY)
    if guid == nil then
        local response = skynet.call(".char_db", "lua", "findAll",  {collection = "character",query = nil, selector = {["attrib.guid"] = 1}, skip = 0, limit = 1, sorter = { {["attrib.guid"] = -1} }})
        print("playermanager_core:init response =", table.tostr(response))
        local max_guid = response and response[1].attrib.guid or 100000
        max_guid = max_guid < 200000 and 200000 or max_guid
        skynet.call(".CDATACENTERD", "lua", "UPDATE", CDATACENTER_GUID_KEY, max_guid)
    end
end

function playermanager_core:check_name_vaild(name,server_id)
    if string.find(name, "#") then
        return define.ASKCREATECHAR_RESULT.ASKCREATECHAR_INVALID_NAME
    end
    if string.find(name, "*") then
        return define.ASKCREATECHAR_RESULT.ASKCREATECHAR_INVALID_NAME
    end
    local is_sensitive = skynet.call(".textfilter", "lua", "is_sensitive", name)
    if is_sensitive then
        return define.ASKCREATECHAR_RESULT.ASKCREATECHAR_INVALID_NAME
    end
    local exist = skynet.call(".char_db", "lua", "findOne",  {collection = "character", query = {["attrib.name"] = name, server_id = server_id}})
    if exist then
        return define.ASKCREATECHAR_RESULT.ASKCREATECHAR_SAME_NAME
    end
    return define.ASKCREATECHAR_RESULT.ASKCREATECHAR_SUCCESS
end

function playermanager_core:create_char(uuid, server_id, req,uid)
    assert(uuid)
    assert(uid)
    local response = skynet.call(".char_db", "lua", "findOne",  {collection = "account",query = {uuid = uuid,uid = uid},selector = {char_list = 1}})
    assert(response)
	local char_guids = response.char_list
    if self:check_character_full(server_id, char_guids) then
        return define.ASKCREATECHAR_RESULT.ASKCREATECHAR_FULL
    end
    local name = string.match(gbk.toutf8(req.nickname), "([^%c]+)")
    local result = self:check_name_vaild(name,server_id)
    if result ~= define.ASKCREATECHAR_RESULT.ASKCREATECHAR_SUCCESS then
        return result
    end
    local char = table.clone(default_char)
    char.server_id = server_id
    local attrib = char.attrib
    attrib.model = req.model
    attrib.name = name
    attrib.hair_style = req.hair_style
    attrib.face_style = req.face_style
    attrib.portrait_id = req.portrait_id
    attrib.new_player_set = req.new_player_set or 0
    if type(attrib.sceneid) == "table" then
        local n = math.random(1, #attrib.sceneid)
        attrib.sceneid = attrib.sceneid[n]
    end
    char.sceneid = attrib.sceneid
    attrib.guid = skynet.call(".CDATACENTERD", "lua", "INC", CDATACENTER_GUID_KEY)
    self:reset_lv1_attr(char)
    print("create_char char =", table.tostr(char))
    skynet.call(".char_db", "lua", "safe_insert", { collection = "character", doc = char})
    table.insert(char_guids, attrib.guid)
    local updater = {}
    updater["$set"] = { char_list = char_guids }
    skynet.call(".char_db", "lua", "safe_update", { collection = "account", selector = {uuid = uuid, uid = uid},update = updater,upsert = false,multi = false})
    return define.ASKCREATECHAR_RESULT.ASKCREATECHAR_SUCCESS, char_guids
end

function playermanager_core:get_level_up_point_remain_add(level)
    for i = #define.LEVEL_POINT_REMAIN, 1, -1 do
        local p = define.LEVEL_POINT_REMAIN[i]
        if level >= p.level then
            return p.add_point
        end
    end
    return 0
end

function playermanager_core:reset_lv1_attr(char)
    local attrib = char.attrib
    local lv1_attrib = char.lv1_attrib
    local attr_level_up = configenginer:get_config("attr_level_up_table")
    local menpai = attrib.menpai
    local chn = define.ENUM_MENPAI_CHN[menpai]
    local level = attrib.level
    local lv1_attrs = {}
    for i = 0, level do
        local attr_up = attr_level_up[i]
		--attr_up[力量][恶人谷] = value
        for attr, v in pairs(attr_up) do
            if v[chn] then
                local v_chn = v[chn]
                local key = attr
                local add
                if type(v_chn) == "table" then
                    add = v_chn[1]
                else
                    add = v_chn
                end
                local e = lv1_attrs[key] or 0
                local new = e + add
                lv1_attrs[key] = new
            end
        end
        local key = "point_remain"
        local add_point_remain = self:get_level_up_point_remain_add(i)
        local e = lv1_attrs[key] or 0
        local new = e + add_point_remain
        lv1_attrs[key] = new
    end
    for attr, value in pairs(lv1_attrs) do
        lv1_attrib[attr] = value
    end
end
function playermanager_core:check_character_full(server_id, char_guids)
    local char_list = {}
    for _, guid in ipairs(char_guids) do
        local char = skynet.call(".char_db", "lua", "findOne", {
            collection = "character",
            query = {["attrib.guid"] = guid, server_id = server_id}
        })
        table.insert(char_list, char)
    end
    return #char_list >= define.MAX_CREATE_PLAYER_NUM
end




function playermanager_core:delete_char(uuid, req,uid)
    assert(uuid and uid)
    assert(req.guid)
    local response = skynet.call(".char_db", "lua", "findOne",  {collection = "account",query = {uuid = uuid,uid = uid},selector = {char_list = 1}})
    assert(response)
	local char_guids = response.char_list
    for i = #char_guids, 1, -1 do
        if char_guids[i] == req.guid then
            table.remove(char_guids, i)
            break
        end
    end
    local updater = {}
    updater["$set"] = { char_list = char_guids }
    skynet.call(".char_db", "lua", "update", { collection = "account", selector = {uuid = uuid},update = updater,upsert = false,multi = false})

    local collection = "log_delete_char"
    local process_id = tonumber(skynet.getenv "process_id")
    local doc = { process_id = process_id, uuid = uuid, guid = req.guid, date_time = utils.get_day_time(), unix_time = os.time()}
    skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc})

    return 0, char_guids
end


function playermanager_core:check_change_name(name)
    local result = self:check_name_vaild(name)
    return result == define.ASKCREATECHAR_RESULT.ASKCREATECHAR_SUCCESS
end

function playermanager_core:change_player_name(guid, name, old_name)
    local updater = { ["$set"] = {["attrib.name"] = name}}
    skynet.call(".char_db", "lua", "update", { collection = "character", selector = {["attrib.guid"] = guid},update = updater,upsert = false,multi = false})
	local collection = "log_player_change_name"
	local doc = { 
	newname = name,
	guid = guid,
	old_name = old_name,
	date_time = utils.get_day_time()
	}
	skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc })
end

return playermanager_core
