local skynet = require "skynet"
require "skynet.manager"
local class = require "class"
local gbk = require "wire_charset"
local packet_def = require "game.packet"
local define = require "define"
local ranking_conf = require "ranking_conf"
local utils = require "utils"
local cluster = require "skynet.cluster"

local ranking_core = class("ranking_core")

ranking_core.time_rate = 100

function ranking_core:set_guid_value(guid,value)
	self.values = self.values or {}
	self.values[guid] = value

end
function ranking_core:get_guid_value()
	return self.values or {}
end


function ranking_core:getinstance()
    if ranking_core.instance == nil then
        ranking_core.instance = ranking_core.new()
    end
    return ranking_core.instance
end

function ranking_core:init()
	self.activity = {}
	self.mingdong_top = {}
	self.flower_top = {}
	self.jingpai = {}
	self.on_lines = {}
	self.limit_shops = {}
	-- 乱斗排行（杀神/炮灰）
	self.chaos_brawl = {} 
	self.today = tonumber(os.date("%Y%m%d"))
	local times = os.date("*t")
	self.minute_time = times.hour * 60 + times.min
	
	self:load_data()
	self.minute_ticktime = (60 - times.sec) * self.time_rate
	skynet.timeout(self.minute_ticktime, function()
		self:minute_tick()
	end)
end
function ranking_core:minute_tick()
	-- skynet.logi("ranking_core:minute_tick() = ",os.time())
	local times = os.date("*t")
	local nowtime = times.hour * 60 + times.min
    local r, err = xpcall(self.minute_update, debug.traceback, self, self.minute_ticktime * 10,nowtime)
    if not r then
        print("ranking_core:minute_update error =", err)
    end
	self.minute_ticktime = (60 - times.sec) * self.time_rate
    skynet.timeout(self.minute_ticktime, function() self:minute_tick() end)
end

function ranking_core:load_limit_shops()
	local collection = "limit_shops"
	local global_data = skynet.call(".char_db","lua","findAll",{collection = collection,query = nil,selector = {_id = 0}})
	if not global_data or #global_data == 0 then
		local data = {
			world_id = 0,
			shopid = -1,
			reset_date = -1,
			update_interval = -1,
			item_buy = {},
			save_time = self:get_save_time(),
		}
		skynet.send(".char_db", "lua", "insert", { collection = collection, doc = data})
	else
		for _,data in ipairs(global_data) do
			local world_id = data.world_id
			if world_id > 0 then
				self[collection][world_id] = self[collection][world_id] or {}
				local shopid = data.shopid
				self[collection][world_id][shopid] = data
			end
		end
	end
	skynet.logi("limit_shops = ",table.tostr(self[collection]))
end
function ranking_core:reset_limit_shops(today)
	local curtime = os.time()
	for wid,data in pairs(self.limit_shops) do
		for shopid,shop_data in pairs(data) do
			if shop_data.update_interval > 0 then
				if shop_data.reset_date == -1 or shop_data.reset_date <= today then
					shop_data.reset_date = tonumber(os.date("%Y%m%d",curtime + shop_data.update_interval * 86400))
					shop_data.item_buy = {}
					shop_data.save_time = 0
				end
			end
		end
	end
end

function ranking_core:get_limit_shop_buy_count(world_id,update_interval,shopid,itemid)
	if not self.limit_shops[world_id] then
		local data = {
			world_id = world_id,
			shopid = shopid,
			reset_date = -1,
			update_interval = update_interval,
			item_buy = {},
			save_time = 0,
		}
		if update_interval > 0 then
			data.reset_date = tonumber(os.date("%Y%m%d",os.time() + data.update_interval * 86400))
		end
		self.limit_shops[world_id] = {[shopid] = data}
	elseif not self.limit_shops[world_id][shopid] then
		local data = {
			world_id = world_id,
			shopid = shopid,
			reset_date = -1,
			update_interval = update_interval,
			item_buy = {},
			save_time = 0,
		}
		if update_interval > 0 then
			data.reset_date = tonumber(os.date("%Y%m%d",os.time() + data.update_interval * 86400))
		end
		self.limit_shops[world_id][shopid] = data
	end
	local index = tostring(itemid)
	return self.limit_shops[world_id][shopid].item_buy[index] or 0
end

function ranking_core:set_limit_shop_buy_count(world_id,shopid,itemid,count)
	if not self.limit_shops[world_id] then
		return
	end
	local limit_shops = self.limit_shops[world_id][shopid]
	if not limit_shops then
		return
	end
	local index = tostring(itemid)
	limit_shops.item_buy[index] = (limit_shops.item_buy[index] or 0) + count
	limit_shops.save_time = 0
	return limit_shops.item_buy
end

function ranking_core:update_limit_shop_buy_count(world_id,shopid)
	if not self.limit_shops[world_id] then
		return
	end
	local limit_shops = self.limit_shops[world_id][shopid]
	if not limit_shops then
		return
	end
	return limit_shops.item_buy
end

function ranking_core:fix_limit_shops(world_id,shopid,key,value)
	if not self.limit_shops[world_id] then
		return -1
	end
	if not self.limit_shops[world_id][shopid] then
		return -2
	end
	self.limit_shops[world_id][shopid][key] = value
	return 0
end


function ranking_core:load_activity()
	local collection = "activity"
	local global_data = skynet.call(".char_db","lua","findAll",{collection = collection,query = nil,selector = {_id = 0}})
	if not global_data or #global_data == 0 then
		local data = {
			world_id = 0,
			sceneid = -1,
			actid = -1,
			params = {},
			save_time = self:get_save_time(),
		}
		skynet.send(".char_db", "lua", "insert", { collection = collection, doc = data})
	else
		for _,data in ipairs(global_data) do
			local world_id = data.world_id
			if not self[collection][world_id] then
				self[collection][world_id] = {}
			end
			table.insert(self[collection][world_id],data)
		end
	end
	-- skynet.logi("load_activity = ",table.tostr(self[collection]))
end

function ranking_core:set_activity_key(world_id,sceneId,actId,key,value)
	if not self.activity[world_id] then
		local data = {
			world_id = world_id,
			sceneid = sceneId,
			actid = actId,
			params = {[key] = value},
			save_time = 0,
		}
		self.activity[world_id] = {data}
	else
		local find_true = false
		for _,data in ipairs(self.activity[world_id]) do
			if data.sceneid == sceneId and data.actid == actId then
				data.params[key] = value
				data.save_time = 0
				find_true = true
				break
			end
		end
		if not find_true then
			local data = {
				world_id = world_id,
				sceneid = sceneId,
				actid = actId,
				params = {[key] = value},
				save_time = 0,
			}
			table.insert(self.activity[world_id],data)
		end
	end
end
function ranking_core:get_activity_key(world_id,sceneId,actId,key)
	if self.activity[world_id] then
		for _,data in ipairs(self.activity[world_id]) do
			if data.sceneid == sceneId and data.actid == actId then
				return data.params[key] or 0
			end
		end
	end
	return 0
end
function ranking_core:get_activity(world_id)
	return self.activity[world_id] or {}
end
function ranking_core:get_activity_ex(world_id,sceneId,actId)
	local acts = {}
	if self.activity[world_id] then
		for _,data in ipairs(self.activity[world_id]) do
			if data.sceneid == sceneId and data.actid == actId then
				table.insert(acts,data)
			end
		end
	end
	return acts
end
function ranking_core:get_activity_for_scene(world_id,sceneId)
	local acts = {}
	if self.activity[world_id] then
		for _,data in ipairs(self.activity[world_id]) do
			if data.sceneid == sceneId then
				table.insert(acts,data)
			end
		end
	end
	return acts
end
function ranking_core:get_activity_for_act(world_id,actId)
	local acts = {}
	if self.activity[world_id] then
		for _,data in ipairs(self.activity[world_id]) do
			if data.actid == actId then
				table.insert(acts,data)
			end
		end
	end
	return acts
end


		

function ranking_core:minute_update(delta_time,minute_time)
	-- skynet.logi("ranking_core:minute_update() = ",minute_time)
	local today = tonumber(os.date("%Y%m%d"))
	self.minute_time = minute_time
	if today ~= self.today then
		self.today = today
		self:reset_limit_shops(today)
		self:addglobalcountnews("#{SJBW_130823_61}",define.UPDATE_CLIENT_ICON_SRIPTID,"GetNewDayRestData")
	end
	
	
	self:check_huabang()
	self:check_mingdong()
	
	local save_time = self:get_save_time()
	self:save_flower_top(save_time)
	self:save_jingpai(save_time)
	self:save_activity(save_time)
	self:save_mingdong_top(save_time)
	self:save_limit_shops(save_time)
	self:save_chaos_brawl(save_time)
	-- self.mingdong_top_save_tick = self.mingdong_top_save_tick - 1
	-- if self.mingdong_top_save_tick <= 0 then
		-- self.mingdong_top_save_tick = 6
		
	-- end
	
	-- self.flower_top_save_tick = self.flower_top_save_tick - 1
	-- if self.flower_top_save_tick <= 0 then
		-- self.flower_top_save_tick = 7
		-- self:save_flower_top()
	-- end
	
	-- self.jingpai_save_tick = self.jingpai_save_tick - 1
	-- if self.jingpai_save_tick <= 0 then
		-- self.jingpai_save_tick = 8
		
	-- end
	-- skynet.logi("ranking_core:minute_update() = ",os.time(),"delta_time = ",delta_time)
end


function ranking_core:get_save_time()
	return os.date("%y-%m-%d %H:%M:%S")
end
function ranking_core:closeserver(world_id)
	-- skynet.logi("save top world_id = ",world_id)
	self.on_lines[world_id] = nil
	local save_time = self:get_save_time()
	if self.flower_top[world_id] then
		local collection = "flower_top"
		for migration,data in pairs(self.flower_top[world_id]) do
			if migration ~= 0 then
				for _,topdata in ipairs(data) do
					topdata.save_time = save_time
					skynet.call(".char_db", "lua", "update", {
					collection = collection,
					selector = {world_id = world_id,migration = migration,topid = topdata.topid},
					update = {["$set"] = topdata},
					upsert = true,
					multi = false
					})
				end
			else
				data.save_time = save_time
				skynet.call(".char_db", "lua", "update", {
				collection = collection,
				selector = {world_id = world_id,migration = migration},
				update = {["$set"] = data},
				upsert = true,
				multi = false
				})
			end
		end
	end
	if self.jingpai[world_id] then
		local collection = "jingpai"
		for migration,data in pairs(self.jingpai[world_id]) do
			if migration ~= 0 then
				for _,topdata in pairs(data) do
					topdata.save_time = save_time
					skynet.call(".char_db", "lua", "update", {
					collection = collection,
					selector = {world_id = world_id,migration = migration,index = topdata.index},
					update = {["$set"] = topdata},
					upsert = true,
					multi = false
					})
				end
			else
				data.save_time = save_time
				skynet.call(".char_db", "lua", "update", {
				collection = collection,
				selector = {world_id = world_id,migration = migration},
				update = {["$set"] = data},
				upsert = true,
				multi = false
				})
			end
		end
	end
	if self.activity[world_id] then
		local collection = "activity"
		for _,data in ipairs(self.activity[world_id]) do
			data.save_time = save_time
			skynet.call(".char_db", "lua", "update", {
			collection = collection,
			selector = {world_id = world_id,sceneid = data.sceneid,actid = data.actid},
			update = {["$set"] = data},
			upsert = true,
			multi = false
			})
		end
	end
	if self.mingdong_top[world_id] then
		local collection = "mingdong_top"
		self.mingdong_top[world_id][0].save_time = save_time
		skynet.send(".char_db", "lua", "update", {
		collection = collection,
		selector = {world_id = world_id,topid = 0},
		update = {["$set"] = self.mingdong_top[world_id][0]},
		upsert = true,
		multi = false
		})
		for _,data in ipairs(self.mingdong_top[world_id]) do
			data.save_time = save_time
			skynet.send(".char_db", "lua", "update", {
			collection = collection,
			selector = {world_id = world_id,topid = data.topid},
			update = {["$set"] = data},
			upsert = true,
			multi = false
			})
		end
	end
	if self.limit_shops[world_id] then
		local collection = "limit_shops"
		for shopid,data in pairs(self.limit_shops[world_id]) do
			data.save_time = save_time
			skynet.send(".char_db", "lua", "update", {
			collection = collection,
			selector = {world_id = world_id,shopid = shopid},
			update = {["$set"] = data},
			upsert = true,
			multi = false
			})
		end
	end
	if self.chaos_brawl[world_id] then
		local collection = "ranking_chaos_brawl_players"
		for _, data in pairs(self.chaos_brawl[world_id].players) do
			data.save_time = save_time
			skynet.send(".char_db", "lua", "update", {
			collection = collection,
			selector = {world_id = world_id,guid = data.guid},
			update = {["$set"] = data},
			upsert = true,
			multi = false
			})
		end
	end
end
function ranking_core:close_ranking()
	-- skynet.logi("ranking_core:close_ranking()")
	local save_time = self:get_save_time()
	local collection = "flower_top"
	for wid,widtab in pairs(self.flower_top) do
		for migration,data in pairs(widtab) do
			if migration ~= 0 then
				for _,topdata in ipairs(data) do
					topdata.save_time = save_time
					skynet.call(".char_db", "lua", "update", {
					collection = collection,
					selector = {world_id = wid,migration = migration,topid = topdata.topid},
					update = {["$set"] = topdata},
					upsert = true,
					multi = false
					})
				end
			else
				data.save_time = save_time
				skynet.call(".char_db", "lua", "update", {
				collection = collection,
				selector = {world_id = wid,migration = migration},
				update = {["$set"] = data},
				upsert = true,
				multi = false
				})
			end
		end
	end
	collection = "jingpai"
	for wid,widtab in pairs(self.jingpai) do
		for migration,data in pairs(widtab) do
			if migration ~= 0 then
				for _,topdata in pairs(data) do
					topdata.save_time = save_time
					skynet.call(".char_db", "lua", "update", {
					collection = collection,
					selector = {world_id = wid,migration = migration,index = topdata.index},
					update = {["$set"] = topdata},
					upsert = true,
					multi = false
					})
				end
			else
				data.save_time = save_time
				skynet.call(".char_db", "lua", "update", {
				collection = collection,
				selector = {world_id = wid,migration = migration},
				update = {["$set"] = data},
				upsert = true,
				multi = false
				})
			end
		end
	end
	collection = "activity"
	for wid,widtab in pairs(self[collection]) do
		for _,data in ipairs(widtab) do
			data.save_time = save_time
			skynet.call(".char_db", "lua", "update", {
			collection = collection,
			selector = {world_id = wid,sceneid = data.sceneid,actid = data.actid},
			update = {["$set"] = data},
			upsert = true,
			multi = false
			})
		end
	end
	collection = "mingdong_top"
	for wid,widtab in pairs(self[collection]) do
		widtab[0].save_time = save_time
		skynet.send(".char_db", "lua", "update", {
		collection = collection,
		selector = {world_id = wid,topid = 0},
		update = {["$set"] = widtab[0]},
		upsert = true,
		multi = false
		})
		for _,data in ipairs(widtab) do
			data.save_time = save_time
			skynet.send(".char_db", "lua", "update", {
			collection = collection,
			selector = {world_id = wid,topid = data.topid},
			update = {["$set"] = data},
			upsert = true,
			multi = false
			})
		end
	end
	collection = "limit_shops"
	for wid,widtab in pairs(self[collection]) do
		for shopid,data in pairs(widtab) do
			data.save_time = save_time
			skynet.send(".char_db", "lua", "update", {
			collection = collection,
			selector = {world_id = wid,shopid = shopid},
			update = {["$set"] = data},
			upsert = true,
			multi = false
			})
		end
	end
	collection = "ranking_chaos_brawl_players"
	for wid,widtab in pairs(self.chaos_brawl) do
		for _, data in pairs(widtab.players) do
			data.save_time = save_time
			skynet.send(".char_db", "lua", "update", {
			collection = collection,
			selector = {world_id = wid,guid = data.guid},
			update = {["$set"] = data},
			upsert = true,
			multi = false
			})
		end
	end
end
function ranking_core:save_flower_top(save_time)
	-- skynet.logi("ranking_core:save_flower_top()")
	local collection = "flower_top"
	for wid,widtab in pairs(self[collection]) do
		for migration,data in pairs(widtab) do
			if migration ~= 0 then
				for _,topdata in ipairs(data) do
					if topdata.save_time == 0 then
						topdata.save_time = save_time
						skynet.send(".char_db", "lua", "update", {
						collection = collection,
						selector = {world_id = wid,migration = migration,topid = topdata.topid},
						update = {["$set"] = topdata},
						upsert = true,
						multi = false
						})
					end
				end
			else
				if data.save_time == 0 then
					data.save_time = save_time
					skynet.send(".char_db", "lua", "update", {
					collection = collection,
					selector = {world_id = wid,migration = migration},
					update = {["$set"] = data},
					upsert = true,
					multi = false
					})
				end
			end
		end
	end
end
function ranking_core:save_jingpai(save_time)
	-- skynet.logi("ranking_core:save_jingpai()")
	local collection = "jingpai"
	for wid,widtab in pairs(self[collection]) do
		for migration,data in pairs(widtab) do
			if migration ~= 0 then
				for _,topdata in pairs(data) do
					if topdata.save_time == 0 then
						topdata.save_time = save_time
						skynet.send(".char_db", "lua", "update", {
						collection = collection,
						selector = {world_id = wid,migration = migration,index = topdata.index},
						update = {["$set"] = topdata},
						upsert = true,
						multi = false
						})
					end
				end
			else
				if data.save_time == 0 then
					data.save_time = save_time
					skynet.send(".char_db", "lua", "update", {
					collection = collection,
					selector = {world_id = wid,migration = migration},
					update = {["$set"] = data},
					upsert = true,
					multi = false
					})
				end
			end
		end
	end
end
function ranking_core:save_activity(save_time)
	-- skynet.logi("ranking_core:save_activity()")
	local collection = "activity"
	for wid,widtab in pairs(self[collection]) do
		for _,data in ipairs(widtab) do
			if data.save_time == 0 then
				data.save_time = save_time
				skynet.send(".char_db", "lua", "update", {
				collection = collection,
				selector = {world_id = wid,sceneid = data.sceneid,actid = data.actid},
				update = {["$set"] = data},
				upsert = true,
				multi = false
				})
			end
		end
	end
end
function ranking_core:save_mingdong_top(save_time)
	-- skynet.logi("ranking_core:save_mingdong_top()")
	local collection = "mingdong_top"
	for wid,widtab in pairs(self[collection]) do
		if widtab[0].save_time == 0 then
			widtab[0].save_time = save_time
			skynet.send(".char_db", "lua", "update", {
			collection = collection,
			selector = {world_id = wid,topid = 0},
			update = {["$set"] = widtab[0]},
			upsert = true,
			multi = false
			})
		end
		for _,data in ipairs(widtab) do
			if data.save_time == 0 then
				data.save_time = save_time
				skynet.send(".char_db", "lua", "update", {
				collection = collection,
				selector = {world_id = wid,topid = data.topid},
				update = {["$set"] = data},
				upsert = true,
				multi = false
				})
			end
		end
	end
end
function ranking_core:save_limit_shops(save_time)
	-- skynet.logi("ranking_core:save_mingdong_top()")
	local collection = "limit_shops"
	for wid,widtab in pairs(self[collection]) do
		for shopid,data in pairs(widtab) do
			if data.save_time == 0 then
				data.save_time = save_time
				skynet.send(".char_db", "lua", "update", {
				collection = collection,
				selector = {world_id = wid,shopid = shopid},
				update = {["$set"] = data},
				upsert = true,
				multi = false
				})
			end
		end
	end
end
function ranking_core:load_data()
	self:load_huabang()
	self:load_jingpai()
	self:load_activity()
	self:load_mingdong()
	self:load_mingdong()
	self:load_limit_shops()
	self:load_chaos_brawl()
end


function ranking_core:get_celient_icon_display(sceneId,selfId,guid,world_id)
	-- if not self.on_lines[world_id] then
		-- self.on_lines[world_id] = {}
	-- end
	-- self.on_lines[world_id][guid] = {sceneId,selfId}
	if define.IS_KUAFU_SCENE[sceneId] then
		return
	end
	local today = self.today
	local hb_migration,hb_ui_flag
	if self.flower_top[world_id] then
		local flower_top = self.flower_top[world_id][0]
		local overdate = flower_top.overdate
		if today <= overdate then
			if flower_top.topid >= 1 and flower_top.topid <= 3 then
				hb_migration = flower_top.topid
			else
				hb_migration = flower_top.charguid
			end
			hb_ui_flag = flower_top.uiflag
		end
	end
	local jp_uiflag
	if self.jingpai[world_id] then
		local jingpai = self.jingpai[world_id][0]
		local overdate = jingpai.end_date
		if today <= overdate then
			jp_uiflag = jingpai.guid
		end
	end
	local md_date
	if self.mingdong_top[world_id] then
		local mingdong_top = self.mingdong_top[world_id][0]
		local overdate = mingdong_top.over_date
		if today <= overdate then
			md_date = overdate
		end
	end
	return hb_migration,hb_ui_flag,jp_uiflag,md_date
end
function ranking_core:get_mingdong_overdate(world_id)
	-- skynet.logi("get_mingdong_overdate::world_id = ",world_id)
	if self.mingdong_top[world_id] then
		local overdate = self.mingdong_top[world_id][0].over_date
		if self.today <= overdate then
			return overdate,self.mingdong_top[world_id][0].end_time
		end
	end
	return 0,0
end

function ranking_core:start_jingpai(world_id,open_params)
	if not open_params.special.lx then
		return
	end
	local today = self.today
	local nowtime = self.minute_time
	if today > open_params.overdate then
		return
	elseif nowtime >= open_params.endtime then
		return
	end
	local open_flag = 0
	if not self.jingpai[world_id] then
		local guildname = "区服["..tostring(world_id).."]竞拍"
		self.jingpai[world_id] = {
			[0] = {
				world_id = world_id,
				migration = 0,
				index = 0,
				itemid = 0,
				itemcount = 0,
				startmoney = 0,
				addmoney = 0,
				end_date = 0,
				end_time = 0,
				claim_award = 0,
				guid = 0,
				best_moeny = 0,
				charname = guildname,
				status = 0,
				modelindex = 0,
				save_time = self:get_save_time(),
			}
		}
		skynet.send(".char_db", "lua", "insert", { collection = "jingpai", doc = self.jingpai[world_id][0]})
		open_flag = 1
	else
		if self.jingpai[world_id][0].index == 0 then
			open_flag = 2
		else
			if today > self.jingpai[world_id][0].end_date then
				open_flag = 2
			else
				if self.minute_time > self.jingpai[world_id][0].end_time then
					open_flag = 2
				end
			end
		end
	end
	if open_flag > 0 then
		if not open_params.is_new then
			for i = 1,5 do
				if self.jingpai[world_id][i] then
					self.jingpai[world_id][i] = nil
					skynet.send(".char_db", "lua", "delete", { collection = "jingpai", selector = {world_id = world_id,migration = i}})
				end
			end
			if open_flag ~= 1 then
				local guildname = "区服["..tostring(world_id).."]竞拍"
				self.jingpai[world_id] = {
					[0] = {
						world_id = world_id,
						migration = 0,
						index = 0,
						itemid = 0,
						itemcount = 0,
						startmoney = 0,
						addmoney = 0,
						end_date = 0,
						end_time = 0,
						claim_award = 0,
						guid = 0,
						best_moeny = 0,
						charname = guildname,
						status = 0,
						modelindex = 0,
						save_time = self:get_save_time(),
					}
				}
			end
		end
		local migration = self.jingpai[world_id][0].best_moeny + 1
		if migration < 1 or migration > 5 then
			migration = 1
		end
		local status = "第["..tostring(migration).."]期竞拍"
		self.jingpai[world_id][migration] = {}
		local have_item
		local index = 0
		local ride_count = 0
		for i = 1,open_params.ridecount do
			have_item = open_params.item_list[i]
			if have_item then
				index = index + 1
				ride_count = ride_count + 1
				self.jingpai[world_id][migration][index] = {
					world_id = world_id,
					migration = migration,
					index = index,
					itemid = have_item.id,
					itemcount = have_item.num,
					startmoney = have_item.startmoney,
					addmoney = have_item.addmoney,
					end_date = open_params.overdate,
					end_time = open_params.endtime,
					claim_award = 0,
					guid = 0,
					best_moeny = 0,
					charname = "",
					status = status,
					modelindex = have_item.lx,
					save_time = 0,
				}
			else
				break
			end
		end
		local dress_count = 0
		self.jingpai[world_id][migration][100] = {
			world_id = world_id,
			migration = migration,
			index = 100,
			itemid = open_params.special.itemid,
			itemcount = open_params.special.count,
			startmoney = open_params.special.yuanbao,
			addmoney = ride_count,
			end_date = open_params.special.s_overdate,
			end_time = open_params.endtime,
			claim_award = open_params.uiflag,
			guid = 0,
			best_moeny = dress_count,
			charname = "",
			status = status,
			modelindex = open_params.special.lx,
			save_time = 0,
		}
		self.jingpai[world_id][0].charname = "migration = "..tostring(migration)
		self.jingpai[world_id][0].status = status
		self.jingpai[world_id][0].guid = open_params.uiflag
		self.jingpai[world_id][0].end_date = open_params.overdate
		self.jingpai[world_id][0].end_time = open_params.endtime
		self.jingpai[world_id][0].claim_award = open_params.endtime
		self.jingpai[world_id][0].index = migration
		self.jingpai[world_id][0].save_time = 0
		return migration
	end
end
function ranking_core:close_jingpai(world_id)
	if self.jingpai[world_id] then
		if self.jingpai[world_id][0] then
			self.jingpai[world_id][0].end_date = 0
			self.jingpai[world_id][0].end_time = 0
			self.jingpai[world_id][0].claim_award = 0
			local world_msg = "#BĐấu giá#Pđóng。"
			local migration = self.jingpai[world_id][0].index
			if migration > 0 then
				local status = "第["..tostring(migration).."]期竞拍关闭，不可领取奖励。"
				if self.jingpai[world_id][migration] then
					for _,data in ipairs(self.jingpai[world_id][migration]) do
						data.guid = 0
						data.status = status
						data.save_time = 0
					end
				end
				self.jingpai[world_id][0].status = status
				world_msg = string.format("#BĐợt thứ[%s] kỳ#P đấu giá đã đóng, không tiến hành kết toán phần thưởng.",migration)
			end
			self.jingpai[world_id][0].index = 0
			self.jingpai[world_id][0].save_time = 0
			self:addglobalcountnews(world_msg,define.UPDATE_CLIENT_ICON_SRIPTID,"OnPlayerUpdateIconDisplay",world_id)
			return true
		end
	end
end
function ranking_core:get_jingpai_state(world_id)
	if self.jingpai[world_id] then
		local jingpai = self.jingpai[world_id][0]
		if jingpai then
			return jingpai.end_date,jingpai.index,jingpai.end_time
		end
	end
	return 0,0
end
function ranking_core:get_jingpai_migration_data(world_id,migration)
	if self.jingpai[world_id] then
		if self.jingpai[world_id][migration] then
			return table.clone(self.jingpai[world_id][migration])
		end
	end
	return {}
end
function ranking_core:have_jingpai_award(world_id,migration,index,guid,haveyb)
	if haveyb < 1 or migration < 1 or index >= 100 then
		return -1
	end
	local today = self.today
	local nowtime = self.minute_time
	if self.jingpai[world_id] then
		if self.jingpai[world_id][migration] then
			local jingpai = self.jingpai[world_id][migration][index]
			if jingpai then
				if jingpai.guid == guid then
					if jingpai.claim_award == 0 then
						if jingpai.best_moeny > 0 and haveyb >= jingpai.best_moeny then
							if today > jingpai.end_date then
								return jingpai.best_moeny,jingpai.itemid,jingpai.itemcount
							elseif today == jingpai.end_date then
								if nowtime >= jingpai.end_time then
									return jingpai.best_moeny,jingpai.itemid,jingpai.itemcount
								else
									return -2
								end
							else
								return -2
							end
						else
							jingpai.guid = 0
							jingpai.best_moeny = 0
							jingpai.charname = ""
							jingpai.save_time = 0
							return -3
						end
					else
						return -4
					end
				else
					return -5
				end
			end
		end
	end
	return -6
end
function ranking_core:claim_jingpai_award(world_id,migration,index,guid)
	if self.jingpai[world_id] then
		if self.jingpai[world_id][migration] then
			if self.jingpai[world_id][migration][index] and self.jingpai[world_id][migration][index].guid == guid then
				self.jingpai[world_id][migration][index].state = "第"..tostring(migration).."期竞拍奖励:已领取"
				self.jingpai[world_id][migration][index].claim_award = "领取时间:"..os.date("%y-%m-%d %H:%M:%S")
				self.jingpai[world_id][migration][index].save_time = 0
				return true
			end
		end
	end
end
function ranking_core:jingpai_take_back_bid_yuanbao(world_id,guid,haveyb)
	if self.jingpai[world_id] then
		for migration,jptab in pairs(self.jingpai[world_id]) do
			if migration ~= 0 then
				for j,data in pairs(jptab) do
					if j < 100 then
						if data.guid == guid and data.claim_award == 0 then
							if data.best_moeny <= haveyb then
								haveyb = haveyb - data.best_moeny
								if haveyb <= 0 then
									break
								end
							else
								data.guid = 0
								data.best_moeny = 0
								data.charname = ""
								data.save_time = 0
								break
							end
						end
					end
				end
			end
		end
	end
	return haveyb
end
function ranking_core:get_jingpai_special_item(world_id,guid,haveyb)
	if self.jingpai[world_id] then
		if self.jingpai[world_id][0] then
			local migration = self.jingpai[world_id][0].index
			if migration > 0 and self.jingpai[world_id][migration] then
				local jingpai = self.jingpai[world_id][migration][100]
				if jingpai then
					return jingpai.end_date,jingpai.end_time,jingpai.itemid,jingpai.itemcount,jingpai.startmoney
				end
			end
		end
	end
end

function ranking_core:get_jingpai_item_config(world_id,index)
	if self.jingpai[world_id] then
		if self.jingpai[world_id][0] then
			local migration = self.jingpai[world_id][0].index
			if migration > 0 and self.jingpai[world_id][migration] then
				local jingpai = self.jingpai[world_id][migration][index]
				if jingpai then
					if index == jingpai.index then
						return jingpai.end_time,jingpai.itemid,jingpai.startmoney,jingpai.addmoney,jingpai.best_moeny
					end
				end
			end
		end
	end
end
function ranking_core:submit_jingpai_bid(world_id,index,prize,guid,name,end_time)
	if self.jingpai[world_id] then
		if self.jingpai[world_id][0] then
			local migration = self.jingpai[world_id][0].index
			if migration > 0 and self.jingpai[world_id][migration] then
				local jingpai = self.jingpai[world_id][migration][index]
				if jingpai then
					local old_name,old_guid,old_money
					if index == jingpai.index and prize > jingpai.best_moeny then
						if jingpai.guid > 0 then
							old_name = jingpai.charname
							old_guid = jingpai.guid
							old_money = jingpai.best_moeny
						end
						jingpai.best_moeny = prize
						jingpai.guid = guid
						jingpai.charname = name
						if end_time > jingpai.end_time then
							jingpai.end_time = end_time
							if end_time > self.jingpai[world_id][0].end_time then
								self.jingpai[world_id][0].end_time = end_time
								self.jingpai[world_id][0].save_time = 0
								if self.jingpai[world_id][migration][100].end_time then
									if end_time > self.jingpai[world_id][migration][100].end_time then
										self.jingpai[world_id][migration][100].end_time = end_time
										self.jingpai[world_id][migration][100].save_time = 0
									end
								end
							end
						end
						jingpai.save_time = 0
						if old_name and old_guid and old_money then
							local mail = {}
							mail.guid = define.INVAILD_ID
							mail.source = ""
							mail.portrait_id = define.INVAILD_ID
							mail.dest = old_name
							mail.content = ""
							mail.flag = define.MAIL_TYPE.MAIL_TYPE_SCRIPT
							mail.create_time = os.time()
							mail.param_1 = define.MAIL_JINGPAI_BACK_YUANBAO
							mail.param_2 = old_guid
							mail.param_3 = old_money
							mail.param_4 = jingpai.itemid
							mail.param_5 = jingpai.itemcount
							local node = define.WORLD_IDS[world_id]
							if node then
								cluster.send(node, ".world", "send_mail", mail)
							-- else
								-- skynet.send(".world", "lua", "send_mail", mail)
							end
						end
						return true
					end
				end
			end
		end
	end
end
function ranking_core:load_jingpai()
	local collection = "jingpai"
	-- self.jingpai[0].charname = "migration = "..tostring(migration)
	-- self.jingpai[0].status = status
	-- self.jingpai[0].guid = open_params.uiflag
	-- self.jingpai[0].end_date = open_params.overdate
	-- self.jingpai[0].end_time = open_params.endtime
	-- self.jingpai[0].claim_award = open_params.endtime
	-- self.jingpai[0].index = migration
	-- self.jingpai[0].best_moeny = migration  old
	
	-- self.jingpai[migration][100].claim_award   uiflag
	
	local global_data = skynet.call(".char_db","lua","findAll",{collection = collection,query = {migration = 0},selector = {_id = 0}})
	if not global_data or #global_data == 0 then
		local data = {
			world_id = 0,
			migration = 0,
			index = 0,
			itemid = 0,
			itemcount = 0,
			startmoney = 0,
			addmoney = 0,
			end_date = 0,
			end_time = 0,
			claim_award = 0,
			guid = 0,
			best_moeny = 0,
			charname = "",
			status = 0,
			modelindex = 0,
			save_time = os.time(),
		}
		skynet.send(".char_db", "lua", "insert", { collection = collection, doc = data})
	else
		for _,data in ipairs(global_data) do
			local world_id = data.world_id
			self[collection][world_id] = {[0] = data}
		end
	end
	for wid,widtab in pairs(self[collection]) do
		global_data = skynet.call(".char_db","lua","findAll",{collection = collection,query = {world_id = wid},selector = {_id = 0}})
		if global_data and #global_data > 0 then
			for _,data in ipairs(global_data) do
				local migration = data.migration
				if migration ~= 0 then
					widtab[migration] = widtab[migration] or {}
					local index = data.index
					widtab[migration][index] = data
				end
			end
		end
	end
	-- skynet.logi("load_jingpai = ",table.tostr(self[collection]))
end

function ranking_core:load_huabang()
	local collection = "flower_top"
	--0:
	--topid = migration  cur
	--claim_award = open award
	--charguid = migration  old
	local global_data = skynet.call(".char_db","lua","findAll",{collection = collection,query = {migration = 0},selector = {_id = 0}})
	if not global_data or #global_data == 0 then
		local data = {
			world_id = 0,
			migration = 0,
			overdate = 0,
			endtime = 0,
			topid = 0,
			charguid = 0,
			charname = "预设花榜",
			flower = 0,
			guildname = "区服[0]花榜",
			claim_award = 0,
			uiflag = 1,
			state = "花榜",
			save_time = self:get_save_time(),
		}
		skynet.send(".char_db", "lua", "insert", { collection = collection, doc = data})
	else
		for _,data in ipairs(global_data) do
			local world_id = data.world_id
			self[collection][world_id] = {[0] = data}
		end
	end
	for wid,widtab in pairs(self[collection]) do
		global_data = skynet.call(".char_db","lua","findAll",{collection = collection,query = {world_id = wid},selector = {_id = 0}})
		if global_data and #global_data > 0 then
			for _,data in ipairs(global_data) do
				local migration = data.migration
				if migration ~= 0 then
					widtab[migration] = widtab[migration] or {}
					table.insert(widtab[migration],data)
				end
			end
		end
	end
	-- skynet.logi("load_huabang = ",table.tostr(self[collection]))
end
function ranking_core:start_huabang(world_id,overdate,endtime,uiflag,is_new)
	local today = self.today
	local nowtime = self.minute_time
	if today > overdate then
		return -2
	elseif today == overdate then
		if nowtime >= endtime then
			return -2
		end
	end
	local open_flag = 0
	if not self.flower_top[world_id] then
		local guildname = "区服["..tostring(world_id).."]花榜"
		self.flower_top[world_id] = {
			[0] = {
				world_id = world_id,
				migration = 0,
				overdate = 0,
				endtime = 0,
				topid = 0,
				charguid = 0,
				charname = "预设花榜",
				flower = 0,
				guildname = guildname,
				claim_award = 0,
				uiflag = uiflag,
				save_time = self:get_save_time(),
				state = "花榜",
			}
		}
		skynet.send(".char_db", "lua", "insert", { collection = "flower_top", doc = self.flower_top[world_id][0]})
		open_flag = 1
	else
		if self.flower_top[world_id][0].topid == 0 then
			open_flag = 2
		else
			if today > self.flower_top[world_id][0].overdate then
				open_flag = 2
			elseif today == self.flower_top[world_id][0].overdate then
				if nowtime > self.flower_top[world_id][0].endtime then
					open_flag = 2
				end
			end
		end
	end
	if open_flag > 0 then
		if not is_new then
			for i = 1,6 do
				if self.flower_top[world_id][i] then
					self.flower_top[world_id][i] = nil
					skynet.send(".char_db", "lua", "delete", { collection = "flower_top", selector = {world_id = world_id,migration = i}})
				end
			end
			if open_flag ~= 1 then
				local guildname = "区服["..tostring(world_id).."]花榜"
				self.flower_top[world_id] = {
					[0] = {
						world_id = world_id,
						migration = 0,
						overdate = 0,
						endtime = 0,
						topid = 0,
						charguid = 0,
						charname = "预设花榜",
						flower = 0,
						guildname = guildname,
						claim_award = 0,
						uiflag = uiflag,
						save_time = 0,
						state = "花榜",
					}
				}
			end
		end
		local migration = self.flower_top[world_id][0].charguid
		if migration == 1 then
			migration = 2
		elseif migration == 2 then
			migration = 3
		else
			migration = 1
		end
		self.flower_top[world_id][migration] = self.flower_top[world_id][migration] or {}
		local state = "第"..tostring(migration).."期[收花]进行中"
		for i = 1,20 do
			self.flower_top[world_id][migration][i] = {
				world_id = world_id,
				migration = migration,
				overdate = overdate,
				endtime = endtime,
				topid = i,
				charguid = 0,
				charname = " ",
				flower = 0,
				guildname = " ",
				claim_award = 0,
				uiflag = uiflag,
				save_time = 0,
				state = state,
			}
		end
		state = "第"..tostring(migration).."期[送花]进行中"
		local migration_2 = migration + 3
		self.flower_top[world_id][migration_2] = self.flower_top[world_id][migration_2] or {}
		for i = 1,20 do
			self.flower_top[world_id][migration_2][i] = {
				world_id = world_id,
				migration = migration_2,
				overdate = overdate,
				endtime = endtime,
				topid = i,
				charguid = 0,
				charname = " ",
				flower = 0,
				guildname = " ",
				claim_award = 0,
				uiflag = uiflag,
				save_time = 0,
				state = state,
			}
		end
		-- if self.flower_top[0].charguid == migration then
			-- self.flower_top[0].charguid = 0
		-- end
		self.flower_top[world_id][0].state = "当前进行第"..tostring(migration).."期"
		self.flower_top[world_id][0].charname = "migration = "..tostring(migration)..","..tostring(migration_2)

		if self.flower_top[world_id][0].charguid == migration then
			self.flower_top[world_id][0].charguid = 0
		end
		self.flower_top[world_id][0].overdate = overdate
		self.flower_top[world_id][0].endtime = endtime
		self.flower_top[world_id][0].uiflag = uiflag
		self.flower_top[world_id][0].topid = migration
		self.flower_top[world_id][0].save_time = 0
		return migration
	end
	return -1
end
function ranking_core:close_huabang(world_id)
	if self.flower_top[world_id] then
		local migration = self.flower_top[world_id][0].topid
		self.flower_top[world_id][0].claim_award = 0
		self.flower_top[world_id][0].overdate = 0
		self.flower_top[world_id][0].endtime = 0
		self.flower_top[world_id][0].topid = 0
		local world_msg = "#BHoa bảng#Pđóng。"
		if migration ~= 0 then
			local uiflag = self.flower_top[world_id][0].uiflag
			uiflag = uiflag == 2 and uiflag or 1
			local topname = define.FLOWER_TOP_NAME[uiflag][migration] or "花榜"
			world_msg = string.format("#B%s#PĐóng, không kết toán phần thưởng.",topname)
			local state = "第"..tostring(migration).."期关闭，不可领取奖励。"
			self.flower_top[world_id][0].state = state
			if self.flower_top[world_id][migration] then
				for _,topdata in ipairs(self.flower_top[world_id][migration]) do
					topdata.state = state
					topdata.save_time = 0
				end
			end
			local migration_2 = migration + 3
			if self.flower_top[world_id][migration_2] then
				for _,topdata in ipairs(self.flower_top[world_id][migration_2]) do
					topdata.state = state
					topdata.save_time = 0
				end
			end
		end
		self.flower_top[world_id][0].save_time = 0
		self:addglobalcountnews(world_msg,define.UPDATE_CLIENT_ICON_SRIPTID,"OnPlayerUpdateIconDisplay",world_id)
		return true
	end
end
function ranking_core:get_huabang_rank_state(world_id,all_migration)
	if self.flower_top[world_id] then
		local flower_top = self.flower_top[world_id][0]
		if flower_top then
			if not all_migration then
				return flower_top.topid,flower_top.overdate,flower_top.uiflag,flower_top.charguid,flower_top.endtime,flower_top.claim_award
			else
				local today = self.today
				local nowtime = self.minute_time
				local back_flag = {1,1,1}
				for i = 1,3 do
					if self.flower_top[world_id][i] then
						if today > self.flower_top[world_id][i][1].overdate then
							back_flag[i] = 3
						elseif today == self.flower_top[world_id][i][1].overdate then
							if nowtime >= self.flower_top[world_id][i][1].endtime then
								back_flag[i] = 3
							else
								back_flag[i] = 2
							end
						else
							back_flag[i] = 2
						end
					end
				end
				return flower_top.topid,flower_top.overdate,flower_top.uiflag,flower_top.charguid,flower_top.endtime,flower_top.claim_award,back_flag
			end
		
		end
	end
	return -2,0,0,0,0,0
end
function ranking_core:get_huabang_migration_data(world_id,migration,migration_2)
	if self.flower_top[world_id] then
		return self.flower_top[world_id][migration],self.flower_top[world_id][migration_2]
	end
	return {},{}
end
function ranking_core:have_huabang_award(world_id,migration,guid)
	if self.flower_top[world_id] then
		local flower_top = self.flower_top[world_id][migration]
		if flower_top then
			for _,topdata in ipairs(flower_top) do
				if topdata.charguid == guid then
					if topdata.claim_award == 1 then
						return topdata.overdate,topdata.endtime,topdata.topid,topdata.flower,topdata.uiflag
					elseif topdata.claim_award == 0 then
						return -4
					else
						return -1
					end
				end
			end
			return -2
		end
	end
	return -3
end
function ranking_core:claim_huabang_award(world_id,migration,top,guid)
	if self.flower_top[world_id] then
		if self.flower_top[world_id][migration] then
			if self.flower_top[world_id][migration][top].claim_award == 1 then
				if self.flower_top[world_id][migration][top] and self.flower_top[world_id][migration][top].charguid == guid then
					if migration <= 3 then
						self.flower_top[world_id][migration][top].state = "第"..tostring(migration).."期[收花]奖励:已领取"
					else
						self.flower_top[world_id][migration][top].state = "第"..tostring(migration - 3).."期[送花]奖励:已领取"
					end
					self.flower_top[world_id][migration][top].claim_award = "领取时间:"..os.date("%y-%m-%d %H:%M:%S")
					self.flower_top[world_id][migration][top].save_time = 0
					return true
				end
			end
		end
	end
end
function ranking_core:check_huabang()
	for wid,widtab in pairs(self.flower_top) do
		local migration = widtab[0].topid
		if migration >= 1 and migration <= 3 then
			if self.today == widtab[0].overdate and self.minute_time == widtab[0].endtime then
				local topsort = function(t1,t2)
					return t1.flower > t2.flower
				end
				local uiflag
				local flower_name
				local msgs_song,msgs_shou
				if widtab[0].uiflag == 2 then
					uiflag = 2
					flower_name = "仙履奇缘花序榜·"
					local msg_tab = {
						{
							"#{QRZM_211119_55",
							"#{QRZM_211119_54",
							"#{QRZM_211119_53",
						},
						{
							"#{QRZM_211119_63",
							"#{QRZM_211119_62",
							"#{QRZM_211119_61",
						},
						{
							"#{QRZM_211119_71",
							"#{QRZM_211119_70",
							"#{QRZM_211119_69",
						},
					
					}
					msgs_song = msg_tab[migration]
					msg_tab = {
						{
							"#{QRZM_211119_233",
							"#{QRZM_211119_232",
							"#{QRZM_211119_231",
						},
						{
							"#{QRZM_211119_241",
							"#{QRZM_211119_240",
							"#{QRZM_211119_239",
						},
						{
							"#{QRZM_211119_249",
							"#{QRZM_211119_248",
							"#{QRZM_211119_247",
						},
					
					}
					msgs_shou = msg_tab[migration]
				else
					uiflag = 1
					flower_name = "璃梦花影相思曲·"
					local msg_tab = {
						{
							"#{QXHB_20210701_55",
							"#{QXHB_20210701_54",
							"#{QXHB_20210701_53",
						},
						{
							"#{QXHB_20210701_63",
							"#{QXHB_20210701_62",
							"#{QXHB_20210701_61",
						},
						{
							"#{QXHB_20210701_71",
							"#{QXHB_20210701_70",
							"#{QXHB_20210701_69",
						},
					
					}
					msgs_song = msg_tab[migration]
					msg_tab = {
						{
							"#{QXHB_20210701_233",
							"#{QXHB_20210701_232",
							"#{QXHB_20210701_231",
						},
						{
							"#{QXHB_20210701_241",
							"#{QXHB_20210701_240",
							"#{QXHB_20210701_239",
						},
						{
							"#{QXHB_20210701_249",
							"#{QXHB_20210701_248",
							"#{QXHB_20210701_247",
						},
					
					}
					msgs_shou = msg_tab[migration]
				end
				local topname = define.FLOWER_TOP_NAME[uiflag][migration]
				local mail_msg = "    #WChúc mừng người tại #Y%s#W đã Nhận được #Y%s Hoa bảng #W#G hạng thứ %d#W. Người Có thể trước khi #G%d ngày #W hoạt động kết thúc, Đến giao diện hoạt động #Y%s%s#W để nhận"
				local shou_hm_names = {}
				local song_hm_names = {}
				local curtime = os.time()
				local node = define.WORLD_IDS[wid]
				local state = "第"..tostring(migration).."期[收花]奖励:未领取"
				local flower_top = table.clone(widtab[migration])
				table.sort(flower_top,topsort)
				for topid,topdata in ipairs(flower_top) do
					topdata.topid = topid
					topdata.claim_award = 1
					topdata.state = state
					topdata.save_time = 0
					if topdata.flower > 0 and topdata.charguid > 0 then
						if topid <= 3 then
							table.insert(shou_hm_names,topdata.charname)
						end
						if node then
							local mail = {}
							mail.guid = define.INVAILD_ID
							mail.source = ""
							mail.portrait_id = define.INVAILD_ID
							mail.flag = define.MAIL_TYPE.MAIL_TYPE_SYSTEM
							mail.create_time = curtime
							mail.dest = topdata.charname
							mail.content = string.format(mail_msg,topname,"收",topid,self.today,flower_name,topname)
							-- skynet.logi("node = ",node,"mail.dest = ",mail.dest)
							cluster.send(node, ".world", "send_mail", mail)
						end
						-- skynet.send(".world", "lua", "send_mail", mail)
					end
				end
				widtab[migration] = flower_top
				
				state = "第"..tostring(migration).."期[送花]奖励:未领取"
				local migration_2 = migration + 3
				flower_top = table.clone(widtab[migration_2])
				table.sort(flower_top,topsort)
				for topid,topdata in ipairs(flower_top) do
					topdata.topid = topid
					topdata.claim_award = 1
					topdata.state = state
					topdata.save_time = 0
					if topdata.flower > 0 and topdata.charguid > 0 then
						if topid <= 3 then
							table.insert(song_hm_names,topdata.charname)
						end
						if node then
							local mail = {}
							mail.guid = define.INVAILD_ID
							mail.source = ""
							mail.portrait_id = define.INVAILD_ID
							mail.flag = define.MAIL_TYPE.MAIL_TYPE_SYSTEM
							mail.create_time = curtime
							mail.dest = topdata.charname
							mail.content = string.format(mail_msg,topname,"送",topid,self.today,flower_name,topname)
							-- skynet.logi("node = ",node,"mail.dest = ",mail.dest)
							cluster.send(node, ".world", "send_mail", mail)
						end
						-- skynet.send(".world", "lua", "send_mail", mail)
					end
				end
				widtab[migration_2] = flower_top
				widtab[0].topid = 0
				widtab[0].charguid = migration
				widtab[0].state = "第"..tostring(migration).."期结束，可领取奖励"

				widtab[0].claim_award = migration
				widtab[0].save_time = 0
				
				local max_hm = #song_hm_names
				if max_hm > 0 then
					local msg = string.contact_args(msgs_song[max_hm],table.unpack(song_hm_names))
					msg = msg.."}"
					self:addglobalcountnews(msg,false,false,wid)
				end
				max_hm = #shou_hm_names
				if max_hm > 0 then
					local msg = string.contact_args(msgs_shou[max_hm],table.unpack(shou_hm_names))
					msg = msg.."}"
					self:addglobalcountnews(msg,false,false,wid)
				end
			end
		end
	end
end

function ranking_core:update_flower_top(...)
	local me_flower,me_guid,me_name,tar_flower,tar_guid,tar_name,world_id = ...
	if self.flower_top[world_id] then
		local isend = false
		if self.today > self.flower_top[world_id][0].overdate then
			isend = true
		elseif self.today == self.flower_top[world_id][0].overdate then
			if self.minute_time >= self.flower_top[world_id][0].endtime then
				isend = true
			end
		end
		local migration = self.flower_top[world_id][0].topid
		if not isend and migration > 0 then
			local update_flag = false
			local flower_top = self.flower_top[world_id][migration]
			if flower_top then
				local istrue
				local low_pos
				local low_flower = 2100000000
				for i,j in ipairs(flower_top) do
					if j.charguid == tar_guid then
						j.charname = tar_name
						j.flower = tar_flower
						j.save_time = 0
						istrue = true
						update_flag = true
						break
					elseif j.flower < low_flower then
						low_pos = i
						low_flower = j.flower
					end
				end
				if not istrue then
					if low_pos and tar_flower > low_flower then
						flower_top[low_pos].charguid = tar_guid
						flower_top[low_pos].charname = tar_name
						flower_top[low_pos].flower = tar_flower
						flower_top[low_pos].save_time = 0
						update_flag = true
					end
				end
			else
				flower_top = {}
			end
			local migration_2 = migration + 3
			local flower_top_2 = self.flower_top[world_id][migration_2]
			if flower_top_2 then
				local istrue = nil
				local low_pos = nil
				local low_flower = 2100000000
				for i,j in ipairs(flower_top_2) do
					if j.charguid == me_guid then
						j.charname = me_name
						j.flower = me_flower
						j.save_time = 0
						istrue = true
						update_flag = true
						break
					elseif j.flower < low_flower then
						low_pos = i
						low_flower = j.flower
					end
				end
				if not istrue then
					if low_pos and me_flower > low_flower then
						flower_top_2[low_pos].charguid = me_guid
						flower_top_2[low_pos].charname = me_name
						flower_top_2[low_pos].flower = me_flower
						flower_top_2[low_pos].save_time = 0
						update_flag = true
					end
				end
			else
				flower_top_2 = {}
			end
			if update_flag then
				return flower_top,flower_top_2
			end
		end
	end
	return {},{}
end


function ranking_core:get_mingdong_top(world_id)
	if self.mingdong_top[world_id]
	and self.mingdong_top[world_id][0] then
		local over_date = self.mingdong_top[world_id][0].over_date
		if over_date > 0 then
			local today = self.today
			if today <= over_date then
				return self.mingdong_top[world_id]
			end
		end
	end
	return {}
end

function ranking_core:check_mingdong_top_claim_award(world_id,guid)
	if self.mingdong_top[world_id] and self.mingdong_top[world_id][0] then
		local mingdong_top = self.mingdong_top[world_id][0]
		local isend = false
		if self.today > mingdong_top.over_date then
			isend = true
		elseif self.today == mingdong_top.over_date then
			if self.minute_time >= mingdong_top.end_time then
				isend = true
			end
		end
		if isend and mingdong_top.claim_award == 3 then
			for topid,data in ipairs(self.mingdong_top[world_id]) do
				if data.char_guid == guid then
					if data.claim_award == 0 then
						return data.topid,1
					else
						return data.topid,0
					end
				end
			end
		end
	end
	return 0,0
end
function ranking_core:mingdong_top_claim_award(world_id,topid,guid)
	if topid and topid > 0 and self.mingdong_top[world_id]
	and self.mingdong_top[world_id][topid] then
		local mingdong_top = self.mingdong_top[world_id][0]
		local isend = false
		if self.today > mingdong_top.over_date then
			isend = true
		elseif self.today == mingdong_top.over_date then
			if self.minute_time >= mingdong_top.end_time then
				isend = true
			end
		end
		if isend and mingdong_top.claim_award == 3 then
			if self.mingdong_top[world_id][topid].claim_award == 0 then
				if self.mingdong_top[world_id][topid].char_guid == guid then
					self.mingdong_top[world_id][topid].state = "已领取奖励"
					self.mingdong_top[world_id][topid].claim_award = "领取时间:"..os.date("%y-%m-%d %H:%M:%S")
					self.mingdong_top[world_id][topid].save_time = 0
					return 0
				else
					return 3
				end
			else
				return 2
			end
		else
			return 4
		end
	else
		return 1
	end
end

function ranking_core:set_mingdong_top_limit(world_id,guid,name,is_add)
	if self.mingdong_top[world_id]
	and self.mingdong_top[world_id][0] then
		local mingdong_top = self.mingdong_top[world_id][0]
		local isend = false
		if self.today > mingdong_top.over_date then
			isend = true
		elseif self.today == mingdong_top.over_date then
			if self.minute_time >= mingdong_top.end_time then
				isend = true
			end
		end
		if not isend and mingdong_top.claim_award == 1 then
			if is_add then
				local have = false
				for i,j in ipairs(mingdong_top.limit) do
					if j.guid == guid then
						have = true
						break
					end
				end
				if not have then
					table.insert(mingdong_top.limit,{guid = guid,name = name})
					mingdong_top.save_time = 0
					for i,j in pairs(self.mingdong_top[world_id]) do
						if i > 0 then
							if j.char_guid == guid then
								j.char_name = ""
								j.money_yb = 0
								j.need_point = 0
								j.char_guid = 0
								j.save_time = 0
								return true
							end
						end
					end
				end
			else
				for i,j in ipairs(mingdong_top.limit) do
					if j.guid == guid then
						mingdong_top.limit[i] = nil
						mingdong_top.save_time = 0
						local mail = {}
						mail.guid = define.INVAILD_ID
						mail.source = ""
						mail.portrait_id = define.INVAILD_ID
						mail.dest = name
						mail.content = ""
						mail.flag = define.MAIL_TYPE.MAIL_TYPE_SCRIPT
						mail.create_time = os.time()
						mail.param_1 = define.MAIL_UPDATE_MINGDONG_TOP
						mail.param_2 = guid
						mail.param_3 = 0
						mail.param_4 = 0
						mail.param_5 = 0
						local node = define.WORLD_IDS[world_id]
						if node then
							cluster.send(node, ".world", "send_mail", mail)
						-- else
							-- skynet.send(".world", "lua", "send_mail", mail)
						end
						return true
					end
				end
			end
		end
	end
end

function ranking_core:update_mingdong_top(world_id,params)
	local update_flag = false
	local loading = 0
	local money_yb,need_point,over_date,end_time
	if self.mingdong_top[world_id] then
		local mingdong_top = self.mingdong_top[world_id][0]
		local isend = false
		if self.today > mingdong_top.over_date then
			isend = true
		elseif self.today == mingdong_top.over_date then
			if self.minute_time >= mingdong_top.end_time then
				isend = true
			end
		end
		if not isend and mingdong_top.claim_award == 1 then
			loading = 1
			money_yb = params.money_yb
			need_point = params.need_point
			if mingdong_top.over_date == params.over_date
			and mingdong_top.end_time == params.end_time then
				money_yb = money_yb + params.money_yb_old
				need_point = need_point + params.need_point_old
			else
				over_date = mingdong_top.over_date
				end_time = mingdong_top.end_time
			end
			local is_update = true
			local guid = params.guid
			for i,j in ipairs(mingdong_top.limit) do
				if j.guid == guid then
					is_update = false
					break
				end
			end
			if mingdong_top.money_yb <= money_yb and mingdong_top.need_point <= need_point then
				local name = params.name
				local menpai = params.menpai
				local istrue = nil
				local low_pos,low_pos_p
				local low_money_yb,low_need_point = 2100000000,2100000000
				for i,j in pairs(self.mingdong_top[world_id]) do
					if i > 0 then
						if j.char_guid == guid then
							if is_update then
								j.char_name = name
								j.men_pai = menpai
								j.money_yb = money_yb
								j.need_point = need_point
								j.save_time = 0
							else
								j.char_name = ""
								j.men_pai = 9
								j.money_yb = 0
								j.need_point = 0
								j.save_time = 0
							end
							istrue = true
							update_flag = true
							break
						elseif j.money_yb < low_money_yb then
							low_pos = i
							low_money_yb = j.money_yb
						elseif j.money_yb == low_money_yb then
							if j.need_point < low_need_point then
								low_pos_p = i
								low_need_point = j.need_point
							end
						end
					end
				end
				if is_update then
					if not istrue then
						if low_pos and money_yb > low_money_yb then
							self.mingdong_top[world_id][low_pos].char_guid = guid
							self.mingdong_top[world_id][low_pos].char_name = name
							self.mingdong_top[world_id][low_pos].men_pai = menpai
							self.mingdong_top[world_id][low_pos].money_yb = money_yb
							self.mingdong_top[world_id][low_pos].need_point = need_point
							self.mingdong_top[world_id][low_pos].save_time = 0
							update_flag = true
						elseif low_pos_p and need_point > low_need_point then
							self.mingdong_top[world_id][low_pos_p].char_guid = guid
							self.mingdong_top[world_id][low_pos_p].char_name = name
							self.mingdong_top[world_id][low_pos_p].men_pai = menpai
							self.mingdong_top[world_id][low_pos_p].money_yb = money_yb
							self.mingdong_top[world_id][low_pos_p].need_point = need_point
							self.mingdong_top[world_id][low_pos_p].save_time = 0
							update_flag = true
						end
					end
				end
			end
		end
	end
	-- if update_flag then
		-- return top_date,self.mingdong_top[world_id]
	-- else
		-- return top_date,{}
	-- end
	return loading,money_yb,need_point,over_date,end_time
end

function ranking_core:set_mingdong_condition(world_id,need_yb,need_point)
	if self.mingdong_top[world_id] then
		local mingdong_top = self.mingdong_top[world_id][0]
		local isend = false
		if self.today > mingdong_top.over_date then
			isend = true
		elseif self.today == mingdong_top.over_date then
			if self.minute_time >= mingdong_top.end_time then
				isend = true
			end
		end
		if not isend and mingdong_top.claim_award == 1 then
			mingdong_top.money_yb = need_yb
			mingdong_top.need_point = need_point
			mingdong_top.save_time = 0
			return true
		end
	end
end


function ranking_core:load_mingdong()
	-- limit = {{guid = 0,name = ""},{guid = 0,name = ""},{guid = 0,name = ""},}
	local collection = "mingdong_top"
	local global_data = skynet.call(".char_db","lua","findAll",{collection = collection,query = nil,selector = {_id = 0}})
	if not global_data or #global_data == 0 then
		local data = {
			world_id = 0,
			over_date = 0,
			end_time = 0,
			topid = 0,
			char_guid = 0,
			money_yb = 0,
			need_point = 0,
			char_name = "名动江湖",
			men_pai = "区服[0]名动江湖",
			claim_award = 0,
			limit = {},
			state = "状态",
			save_time = self:get_save_time(),
		}
		skynet.send(".char_db", "lua", "insert", { collection = collection, doc = data})
	else
		for _,data in ipairs(global_data) do
			local world_id = data.world_id
			if world_id > 0 then
				self[collection][world_id] = self[collection][world_id] or {}
				local topid = data.topid
				self[collection][world_id][topid] = data
			end
		end
	end
	-- skynet.logi("load_mingdong = ",table.tostr(self[collection]))
end
function ranking_core:close_mingdong(world_id)
	if self.mingdong_top[world_id] then
		self.mingdong_top[world_id][0].over_date = 0
		self.mingdong_top[world_id][0].end_time = 0
		self.mingdong_top[world_id][0].claim_award = 0
		self.mingdong_top[world_id][0].state = "手动关闭(不结算奖励)"
		local world_msg = "#BDanh chấn giang hồ#P đã đóng, không tiến hành kết toán phần thưởng."
		self.mingdong_top[world_id][0].save_time = 0
		for topid,topdata in ipairs(self.mingdong_top[world_id]) do
			if topid > 0 then
				topdata.over_date = 0
				topdata.end_time = 0
				topdata.char_guid = 0
				topdata.money_yb = 0
				topdata.need_point = 0
				topdata.save_time = 0
			end
		end
		self:addglobalcountnews(world_msg,define.UPDATE_CLIENT_ICON_SRIPTID,"OnPlayerUpdateIconDisplay",world_id)
		return true
	end
end
function ranking_core:start_mingdong(world_id,max_top,over_date,end_time,need_yb,need_point,limits)
	local today = self.today
	local nowtime = self.minute_time
	if today > over_date then
		return -2
	elseif today == over_date then
		if nowtime >= end_time then
			return -2
		end
	end
	local open_flag = 0
	if not self.mingdong_top[world_id] then
		open_flag = 1
	else
		if today > self.mingdong_top[world_id][0].over_date then
			open_flag = 2
		elseif today == self.mingdong_top[world_id][0].over_date then
			if nowtime > self.mingdong_top[world_id][0].end_time then
				open_flag = 2
			end
		end
	end
	if open_flag > 0 then
		if open_flag == 2 then
			skynet.send(".char_db", "lua", "delete", { collection = "mingdong_top", selector = {world_id = world_id}})
		end
		self.mingdong_top[world_id] = {
			[0] = {
				world_id = world_id,
				over_date = over_date,
				end_time = end_time,
				topid = 0,
				char_guid = 0,
				money_yb = need_yb,
				need_point = need_point,
				char_name = "名动江湖",
				men_pai = "区服["..world_id.."]名动江湖",
				claim_award = 1,
				limit = limits or {},
				state = "进行中",
				save_time = 0,
			}
		}
		max_top = max_top or 50
		for i = 1,max_top do
			self.mingdong_top[world_id][i] = {
				world_id = world_id,
				over_date = over_date,
				end_time = end_time,
				topid = i,
				char_guid = 0,
				money_yb = 0,
				need_point = 0,
				char_name = "",
				men_pai = 9,
				claim_award = 0,
				state = "进行中",
				save_time = 0,
			}
		end
		return 0
	end
	return -1
end


function ranking_core:check_mingdong()
	for wid,widtab in pairs(self.mingdong_top) do
		if self.today == widtab[0].over_date and self.minute_time == widtab[0].end_time then
			widtab[0].claim_award = 2
			local mail_msg = "#YLong Đằng Lăng Thiên Vân Hải Các, nhật chiếu kim lân rực khắp hoàn vũ!#r#r#WChúc mừng Thiếu Hiệp đã đạt #GThiên Tiêu Long Dược Bảng#W hạng thứ#G%d#W! Lễ lớn vốn nên ban tặng anh hùng, Thiếu Hiệp có thể mở giao diện hoạt động #GThiên Tiêu Long Dược Bảng#W để nhận phần thưởng hậu hĩnh!"
			local curtime = os.time()
			local node = define.WORLD_IDS[wid]
			local topsort = function(t1,t2)
				if t1.money_yb == t2.money_yb then
					return t1.need_point > t2.need_point
				end
				return t1.money_yb > t2.money_yb
			end
			local mingdong_top = table.clone(widtab)
			mingdong_top[0] = nil
			local state = "未领奖"
			table.sort(mingdong_top,topsort)
			for topid,topdata in ipairs(mingdong_top) do
				topdata.topid = topid
				topdata.state = state
				topdata.save_time = 0
				
				if topdata.char_guid > 0 then
					if node then
						local mail = {}
						mail.guid = define.INVAILD_ID
						mail.source = ""
						mail.portrait_id = define.INVAILD_ID
						mail.flag = define.MAIL_TYPE.MAIL_TYPE_SYSTEM
						mail.create_time = curtime
						mail.dest = topdata.char_name
						mail.content = string.format(mail_msg,topid)
						cluster.send(node, ".world", "send_mail", mail)
					end
				end
			end
			mingdong_top[0] = widtab[0]
			mingdong_top[0].state = "已结束:可领奖"
			mingdong_top[0].claim_award = 3
			mingdong_top[0].save_time = 0
			self.mingdong_top[wid] = mingdong_top
			for i = 1,3 do
				if mingdong_top[i].char_guid > 0 then
					local msg = string.contact_args("#{TXLY_240904_43_Ex",mingdong_top[i].char_name,i)
					msg = msg.."}"
					self:addglobalcountnews(msg,false,false,wid)
				end
			end
		end
	end
end











function ranking_core:addglobalcountnews(message,scriptid,funname,world_id)
	-- skynet.logi("message = ",message)
	-- skynet.logi("scriptid = ",scriptid)
	-- skynet.logi("funname = ",funname)
	-- skynet.logi("world_id = ",world_id)
	if type(message) == "string" then
		message = string.trim(message)
	end
	if not message or message == "" then
		return
	end
	local strText = ""
	if scriptid then
		if scriptid < 1 or scriptid > 999999 then
			return
		elseif not funname or funname == "" then
			return
		end
		local script_str = string.format("%06d",scriptid)
		message = gbk.fromutf8(message)
		strText = "@*;SrvMsg;SCA:#{_NEWMSG_"..script_str..funname.."}"..message
	else
		message = gbk.fromutf8(message)
		strText = "@*;SrvMsg;SCA:"..message
	end
	local msg = packet_def.GCChat.new()
	msg.ChatType = 4
	msg.Sourceid = define.INVAILD_ID
	msg.unknow_2 = 1
	msg:set_content(strText)
	if world_id then
		local node = define.WORLD_IDS[world_id]
		if node then
			cluster.send(node, ".world", "multicast", msg)
			return
		end
	end
	-- skynet.send(".world", "lua", "multicast", msg)
	local node_list = utils.get_cluster_specific_server_by_server_alias(".world")
	for n, node in pairs(node_list) do
		-- skynet.logi(n," = ",node)
		cluster.send(node, ".world", "multicast", msg)
	end
end

-- function ranking_core:safe_message_update()
    -- local r, err = xpcall(self.message_update, debug.traceback, self, self.delta_time * 10)
    -- if not r then
        -- print("ranking_core:safe_message_update error =", err)
    -- end
    -- skynet.timeout(self.delta_time, function() self:safe_message_update() end)
-- end

-- function ranking_core:message_update()
    -- self:make_ranking_list()
-- end

-- function ranking_core:make_ranking_list()
    -- for _, ranking in ipairs(ranking_conf) do
        -- self:make_one_ranking_list(ranking.world_id, ranking.ranking_id)
    -- end
-- end

-- function ranking_core:make_one_ranking_list(world_id, ranking_id)
    -- local query_tbl = { world_id = world_id, ranking_id = ranking_id }
    -- local group = {["$group"] = {
        -- _id = "$guid", ["count"] = {["$sum"] = "$value"}, ["record_time"] = {["$first"] = "$record_time"},
        -- ["name"] = {["$last"] = "$name"}}
    -- }
    -- local sort = {["$sort"] = {["count"] = -1, ["record_time"] = -1}}
    -- local limit = {["$limit"] = 100 }
    -- local group_2 = {["$group"] = {["_id"] = 0, ["tableA"] = {["$push"] = "$$ROOT"}}}
    -- local unwind = { ["$unwind"] = { ["path"] = "$tableA", ["includeArrayIndex"] = "arrayIndex"}}
    -- local project = {["$project"] = { ["_id"] = 0, ["name"] = '$tableA.name', ["guid"] = '$tableA.guid', ["count"] = '$tableA.count', ["record_time"] = '$tableA.record_time', ["arrayIndex"] = { ["$add"] = {'$arrayIndex', 1}} }}
    -- local pipeline = {{["$match"] = query_tbl}, group, sort, limit, group_2, unwind, project}
    -- local coll_name = "ranking"
    -- local ranking = skynet.call(".char_db", "lua", "runCommand", "aggregate", coll_name, "pipeline", pipeline, "cursor", {}, "allowDiskUse", false)
    -- local key = self:format_key(world_id, ranking_id)
    -- self.rankings[key] = ranking.cursor.firstBatch
-- end

-- function ranking_core:format_key(world_id, ranking_id)
    -- local key = string.format("%d-%d", world_id, ranking_id)
    -- return key
-- end

-- function ranking_core:get_ranking(world_id, ranking_id)
    -- local key = self:format_key(world_id, ranking_id)
    -- return self.rankings[key]
-- end

-- function ranking_core:get_my_ranking(world_id, ranking_id, guid)
    -- local ranking = self:get_ranking(world_id, ranking_id)
    -- if ranking then
        -- for _, r in ipairs(ranking) do
            -- if r.guid == guid then
                -- return r
            -- end
        -- end
    -- end
-- end

-- function ranking_core:save_value(world_id, ranking_id, guid, name, value)
    -- local coll_name = "ranking"
    -- local data = { world_id = world_id, ranking_id = ranking_id, guid = guid, name = name, value = value, record_time = os.time() }
    -- skynet.call(".char_db", "lua", "insert", { collection = coll_name, doc = data })
-- end

-- ==================== 乱斗排行模块（杀神/炮灰） ====================
-- 说明：
-- 1) 全部按 world_id 隔离，每个区服独立排行。
-- 2) key 含义：
--    key = 1 -> 杀神排行（按 kill_count 降序）
--    key = 2 -> 炮灰排行（按 death_count 降序）
-- 3) 本模块仅提供排行榜与领奖状态服务，不处理活动流程控制。
--
-- 玩家数据结构：
-- {
--     world_id = number,
--     guid = number,
--     name = string,
--     kill_count = number,
--     death_count = number,
--     reward_claim = { ["1"] = 0/1, ["2"] = 0/1 }, -- 对应 key 的领奖状态
--     save_time = number|string -- 0 表示脏数据，需落库
-- }

local CHAOS_RANK_KEY_KILL = 1
local CHAOS_RANK_KEY_DEATH = 2

local function chaos_create_player(world_id, guid, name, menpai)
	return {
		world_id = world_id,
		guid = guid,
		name = name or "",
		menpai = tonumber(menpai) or 9,
		kill_count = 0,
		death_count = 0,
		reward_claim = {["1"] = 0, ["2"] = 0},
		save_time = 0,
	}
end

local function chaos_normalize_player(player)
	player.name = player.name or ""
	player.menpai = tonumber(player.menpai) or 9
	player.kill_count = tonumber(player.kill_count) or 0
	player.death_count = tonumber(player.death_count) or 0
	player.reward_claim = player.reward_claim or {["1"] = 0, ["2"] = 0}
	player.reward_claim["1"] = tonumber(player.reward_claim["1"]) or 0
	player.reward_claim["2"] = tonumber(player.reward_claim["2"]) or 0
	player.save_time = player.save_time or 0
	return player
end

-- 初始化指定 world_id 的乱斗排行容器（幂等）
function ranking_core:init_chaos_brawl(world_id)
	if not self.chaos_brawl[world_id] then
		self.chaos_brawl[world_id] = {
			players = {},
			kill_ranklist = {},
			death_ranklist = {},
		}
	end
end

local function chaos_sort_by_guid(a, b)
	return a.guid < b.guid
end

-- 重建杀神排行（kill_count 降序，同分 guid 升序）
function ranking_core:rebuild_chaos_brawl_kill_ranklist(world_id)
	local world_data = self.chaos_brawl[world_id]
	if not world_data then return end
	local list = {}
	for _, player in pairs(world_data.players) do
		chaos_normalize_player(player)
		if player.kill_count > 0 then
			list[#list + 1] = player
		end
	end
	table.sort(list, function(a, b)
		if a.kill_count == b.kill_count then
			return chaos_sort_by_guid(a, b)
		end
		return a.kill_count > b.kill_count
	end)
	world_data.kill_ranklist = list
end

-- 重建炮灰排行（death_count 降序，同分 guid 升序）
function ranking_core:rebuild_chaos_brawl_death_ranklist(world_id)
	local world_data = self.chaos_brawl[world_id]
	if not world_data then return end
	local list = {}
	for _, player in pairs(world_data.players) do
		chaos_normalize_player(player)
		if player.death_count > 0 then
			list[#list + 1] = player
		end
	end
	table.sort(list, function(a, b)
		if a.death_count == b.death_count then
			return chaos_sort_by_guid(a, b)
		end
		return a.death_count > b.death_count
	end)
	world_data.death_ranklist = list
end

local function chaos_get_ranklist_by_key(world_data, key)
	if key == CHAOS_RANK_KEY_KILL then
		return world_data.kill_ranklist
	elseif key == CHAOS_RANK_KEY_DEATH then
		return world_data.death_ranklist
	end
	return nil
end

local function chaos_get_player_count_by_key(player, key)
	if key == CHAOS_RANK_KEY_KILL then
		return player.kill_count
	elseif key == CHAOS_RANK_KEY_DEATH then
		return player.death_count
	end
	return 0
end

local function chaos_get_or_create_player(self, world_id, guid, name, menpai)
	self:init_chaos_brawl(world_id)
	local guid_key = tostring(guid)
	local player = self.chaos_brawl[world_id].players[guid_key]
	if not player then
		player = chaos_create_player(world_id, guid, name, menpai)
		self.chaos_brawl[world_id].players[guid_key] = player
	else
		chaos_normalize_player(player)
		if name and name ~= "" then
			player.name = name
		end
		if menpai ~= nil then
			player.menpai = tonumber(menpai) or 9
		end
	end
	return player
end

-- 写入击杀/死亡增量，用于刷新乱斗排行
-- add_kill/add_death <= 0 时对应项不变
function ranking_core:update_chaos_brawl_score(world_id, guid, name, add_kill, add_death, menpai)
	if not world_id or world_id == 0 then
		skynet.logw("update_chaos_brawl_score: invalid world_id =", world_id)
		return false
	end
	if not guid or guid == 0 then
		skynet.logw("update_chaos_brawl_score: invalid guid =", guid)
		return false
	end

	local player = chaos_get_or_create_player(self, world_id, guid, name, menpai)
	add_kill = tonumber(add_kill) or 0
	add_death = tonumber(add_death) or 0
	if add_kill > 0 then
		player.kill_count = math.min((player.kill_count or 0) + add_kill, 2100000000)
	end
	if add_death > 0 then
		player.death_count = math.min((player.death_count or 0) + add_death, 2100000000)
	end
	player.save_time = 0

	self:rebuild_chaos_brawl_kill_ranklist(world_id)
	self:rebuild_chaos_brawl_death_ranklist(world_id)
	return true, player.kill_count or 0, player.death_count or 0
end

-- 查询玩家在指定榜单中的名次与计数，并同时返回该玩家击杀/死亡总计
-- 查询排行榜（key=1 杀神，key=2 炮灰）
function ranking_core:get_brawl_ranklist(world_id, key, max_count)
	local src = self:get_chaos_brawl_ranklist(world_id, key, max_count) or {}
	local list = {}
	for i, row in ipairs(src) do
		local item = {
			rank = row.rank,
			world_id = row.world_id,
			guid = row.guid,
			name = row.name,
			menpai = tonumber(row.menpai) or 9,
			count = row.count or 0,
		}
		if tonumber(key) == CHAOS_RANK_KEY_KILL then
			item.kill_count = item.count
		else
			item.dead_count = item.count
		end
		list[i] = item
	end
	return list
end


-- 查询排行榜
-- @param key number 1=杀神排行 2=炮灰排行
-- @param max_count number 返回条数，默认10
-- @return list table
function ranking_core:get_chaos_brawl_ranklist(world_id, key, max_count)
	if not world_id or world_id == 0 then
		skynet.logw("get_chaos_brawl_ranklist: invalid world_id =", world_id)
		return {}
	end
	key = tonumber(key) or 0
	max_count = math.max(tonumber(max_count) or 10, 1)
	if key ~= CHAOS_RANK_KEY_KILL and key ~= CHAOS_RANK_KEY_DEATH then
		skynet.logw("get_chaos_brawl_ranklist: invalid key =", key)
		return {}
	end

	local world_data = self.chaos_brawl[world_id]
	if not world_data then
		return {}
	end

	local ranklist = chaos_get_ranklist_by_key(world_data, key)
	local result = {}
	for i = 1, math.min(max_count, #ranklist) do
		local p = ranklist[i]
		result[#result + 1] = {
			rank = i,
			world_id = p.world_id,
			guid = p.guid,
			name = p.name,
			menpai = tonumber(p.menpai) or 9,
			count = chaos_get_player_count_by_key(p, key),
		}
	end
	return result
end

-- 查询领奖状态
-- @param key number 1=杀神 2=炮灰
-- @return claimed number 0未领奖 1已领奖（未找到玩家时返回0）
-- @return rank number 当前名次（未上榜返回0）
function ranking_core:get_chaos_brawl_reward_state(world_id, key, guid)
	if not world_id or world_id == 0 then return 0, 0 end
	if not guid or guid == 0 then return 0, 0 end
	key = tonumber(key) or 0
	if key ~= CHAOS_RANK_KEY_KILL and key ~= CHAOS_RANK_KEY_DEATH then return 0, 0 end

	local world_data = self.chaos_brawl[world_id]
	if not world_data then return 0, 0 end
	local player = world_data.players[tostring(guid)]
	if not player then return 0, 0 end
	chaos_normalize_player(player)

	local claimed = player.reward_claim[tostring(key)] or 0
	local rank = 0
	local ranklist = chaos_get_ranklist_by_key(world_data, key)
	for i, p in ipairs(ranklist) do
		if p.guid == guid then
			rank = i
			break
		end
	end
	return claimed, rank
end

-- 写入领奖状态
-- @param key number 1=杀神 2=炮灰
-- @param claimed number|boolean 0/false=未领, 1/true=已领
-- @return boolean 是否写入成功
function ranking_core:set_chaos_brawl_reward_state(world_id, key, guid, claimed)
	if not world_id or world_id == 0 then
		skynet.logw("set_chaos_brawl_reward_state: invalid world_id =", world_id)
		return false
	end
	if not guid or guid == 0 then
		skynet.logw("set_chaos_brawl_reward_state: invalid guid =", guid)
		return false
	end
	key = tonumber(key) or 0
	if key ~= CHAOS_RANK_KEY_KILL and key ~= CHAOS_RANK_KEY_DEATH then
		skynet.logw("set_chaos_brawl_reward_state: invalid key =", key)
		return false
	end

	local world_data = self.chaos_brawl[world_id]
	if not world_data then
		skynet.logw("set_chaos_brawl_reward_state: world not found, world_id =", world_id)
		return false
	end
	local player = world_data.players[tostring(guid)]
	if not player then
		skynet.logw("set_chaos_brawl_reward_state: player not found, guid =", guid)
		return false
	end
	chaos_normalize_player(player)

	player.reward_claim[tostring(key)] = (claimed == true or tonumber(claimed) == 1) and 1 or 0
	player.save_time = 0
	return true
end

-- 清理指定 world_id 的乱斗排行（内存 + DB）
-- @return boolean 是否成功
function ranking_core:clear_chaos_brawl_data(world_id)
	if not world_id or world_id == 0 then
		skynet.logw("clear_chaos_brawl_data: invalid world_id =", world_id)
		return false
	end

	self.chaos_brawl[world_id] = {
		players = {},
		kill_ranklist = {},
		death_ranklist = {},
	}
	skynet.send(".char_db", "lua", "delete", {
		collection = "ranking_chaos_brawl_players",
		selector = {world_id = world_id},
	})
	return true
end

-- 从 MongoDB 加载乱斗排行玩家数据并重建排行榜（在 load_data 中调用）
function ranking_core:load_chaos_brawl()
	local collection = "ranking_chaos_brawl_players"
	local all_players = skynet.call(".char_db", "lua", "findAll", {
		collection = collection,
		query = nil,
		selector = {_id = 0}
	})

	if not all_players or #all_players == 0 then
		local default_data = {
			world_id = 0,
			guid = 0,
			name = "",
			kill_count = 0,
			death_count = 0,
			reward_claim = {["1"] = 0, ["2"] = 0},
			save_time = self:get_save_time(),
		}
		skynet.send(".char_db", "lua", "insert", {
			collection = collection,
			doc = default_data
		})
	else
		for _, player in ipairs(all_players) do
			local wid = tonumber(player.world_id) or 0
			if wid > 0 then
				self:init_chaos_brawl(wid)
				chaos_normalize_player(player)
				self.chaos_brawl[wid].players[tostring(player.guid)] = player
			end
		end
	end

	for wid in pairs(self.chaos_brawl) do
		self:rebuild_chaos_brawl_kill_ranklist(wid)
		self:rebuild_chaos_brawl_death_ranklist(wid)
	end
end

-- 保存脏数据（save_time == 0）到 MongoDB
function ranking_core:save_chaos_brawl(save_time)
	local collection = "ranking_chaos_brawl_players"
	for wid, world_data in pairs(self.chaos_brawl) do
		for _, player in pairs(world_data.players) do
			if player.save_time == 0 then
				player.save_time = save_time
				skynet.send(".char_db", "lua", "update", {
					collection = collection,
					selector = {world_id = wid,guid = player.guid},
					update = {["$set"] = player},
					upsert = true,
					multi = false
				})
			end
		end
	end
end

-- 覆盖定义：查询个人在指定榜单的名次与计数
function ranking_core:get_brawl_rank(world_id, key, guid)
	if not world_id or world_id == 0 then return 0, 0 end
	if not guid or guid == 0 then return 0, 0 end
	key = tonumber(key) or 0
	if key ~= CHAOS_RANK_KEY_KILL and key ~= CHAOS_RANK_KEY_DEATH then return 0, 0 end

	local world_data = self.chaos_brawl[world_id]
	if not world_data then return 0, 0 end
	local player = world_data.players[tostring(guid)]
	if not player then return 0, 0 end
	chaos_normalize_player(player)

	local rank = 0
	local ranklist = chaos_get_ranklist_by_key(world_data, key) or {}
	for i, p in ipairs(ranklist) do
		if p.guid == guid then
			rank = i
			break
		end
	end
	return rank, chaos_get_player_count_by_key(player, key)
end

-- 覆盖定义：领奖状态统一返回字符串协议
function ranking_core:check_brawl_reward_status(world_id, key, guid, top_limit)
	local claimed, rank = self:get_chaos_brawl_reward_state(world_id, key, guid)
	top_limit = math.max(tonumber(top_limit) or 3, 1)
	if rank <= 0 or rank > top_limit then
		return "not_eligible", "not_eligible", rank
	end
	if tonumber(claimed) == 1 then
		return "claimed", "claimed", rank
	end
	return "can_claim", "can_claim", rank
end

-- 覆盖定义：写入领奖状态
function ranking_core:mark_brawl_reward(world_id, key, guid)
	local ok = self:set_chaos_brawl_reward_state(world_id, key, guid, 1)
	if ok then
		return true, "ok"
	end
	return false, "mark_failed"
end


return ranking_core
