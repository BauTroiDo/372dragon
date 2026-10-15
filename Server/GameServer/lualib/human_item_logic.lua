local inventory_guard = require "cys_inventory_guard"
local skynet = require "skynet"
local class = require "class"
local utils = require "utils"
local packet_def = require "game.packet"
local define = require "define"
local item_cls = require "item"
local item_operator = require "item_operator":getinstance()
local human_item_logic = class("human_item_logic")

function human_item_logic:dec_item_lay_count(logparam, human, bag_index, count, id)
    local container = human:get_prop_bag_container()
    local item = container:get_item(bag_index)
	if not item then
		human:notify_tips("非法道具。")
		assert(false,"human_item_logic:dec_item_lay_count == 非法道具")
		return false
	end
	local itemid = item:get_index()
	if id and id ~= itemid then
		human:notify_tips("扣除道具ID不符。")
		local msg = string.format("human_item_logic:dec_item_lay_count 将要扣除ID:%s,实际扣除ID:%d,不匹配断言",tostring(id),itemid)
		assert(false,msg)
		return false
	end
	
	
	local itemclass = itemid // 10000000
	local notequip = true
	if itemclass == define.ITEM_CLASS.ICLASS_EQUIP or itemclass == define.ITEM_CLASS.ICLASS_PET_EQUIP then
		notequip = false
	end
	if not notequip then
		human:notify_tips("装备不可在此扣除。")
		assert(false,"human_item_logic:dec_item_lay_count == 装备不可在此扣除")
		return false
	end
	if not count or count < 1 then
		local doc = { 
			logparam = "human_item_logic:dec_item_lay_count",
			logname = "扣除数量异常",
			name = human:get_name(),
			guid = human:get_guid(),
			item_index = item,
			count = count,
			date_time = utils.get_day_time()
		}
		skynet.send(".logdb", "lua", "insert", { collection = "call_bug_rec", doc = doc})
		human:notify_tips("扣除数量异常。")
		assert(false,"human_item_logic:dec_item_lay_count == 扣除数量异常")
		return false
	end
    if item:is_empty() or item:is_lock() then
		human:notify_tips("道具不可用。")
		assert(false,"human_item_logic:dec_item_lay_count == 道具不可用")
        return false
    end
    -- if item:is_lock() then
        -- return false
    -- end
    if item:get_lay_count() == 0 then
		human:notify_tips("道具数量异常。")
		assert(false,"human_item_logic:dec_item_lay_count == 道具数量异常")
        return false
    elseif item:get_lay_count() > 0 then
        local ret = item_operator:dec_item_lay_count(container, bag_index, count)
        if ret then
            local msg = packet_def.GCItemInfo.new()
            msg.bagIndex = bag_index
            if item:get_lay_count() == 0 then
                msg.unknow_1 = 1
                msg.item = item_cls.new():copy_raw_data()
            else
                msg.item = item:copy_raw_data()
            end
            human:get_scene():send2client(human, msg)
			if not logparam.logflag then
				local collection = "erase_prop_rec"
				local doc = {funname = "human_item_logic:dec_item_lay_count",
				logparam = logparam, name = human:get_name(), guid = human:get_guid(),
				item_index = itemid, count = count, time = os.time(), date_time = utils.get_day_time()}
				skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc})
            end
			-- utils.log_dec_item_lay_count(logparam, human, itemid, count)
            return true
        end
    end
	human:notify_tips("道具扣除失败。")
	assert(false,"human_item_logic:dec_item_lay_count == 道具扣除失败")
    return false
end

function human_item_logic:del_available_items(logparam, human, count, ids)
    if not inventory_guard.integer(count,1,65535) then return false,count end
    local bag=human:get_prop_bag_container()
    local parts,left,seen={},count,{}
    for _,item_index in ipairs(ids)do
        if not inventory_guard.integer(item_index,10000000,79999999)then return false,count end
        if not seen[item_index]then
            seen[item_index]=true
            local family=item_index//10000000
            local kind=(family==2 or family==5 or family==6) and "material" or family==4 and "task" or "prop"
            for p,item in bag:ipairs(kind)do
                if left>0 and item and not item:is_lock() and item:get_index()==item_index then
                    local take=math.min(left,item:get_lay_count())
                    if take>0 then parts[#parts+1]={p,take,item_index,family};left=left-take end
                end
            end
        end
    end
    if left>0 then return false,count end
    -- No yielding calls between the complete availability check and the debit.
    for _,part in ipairs(parts)do
        if part[4]==1 or part[4]==7 then
            assert(part[2]==1);assert(self:erase_item_by_bag_index(logparam,human,part[1]))
        else assert(self:dec_item_lay_count(logparam,human,part[1],part[2],part[3]))end
    end
    return true,0
end
function human_item_logic:del_available_item(logparam,human,item_index,count)
    return self:del_available_items(logparam,human,count,{item_index})
end

function human_item_logic:erase_material_item(logparam, human, item_index, item_count)
	logparam.logflag = true
    local delcount = human_item_logic:erase_item(logparam, human, "material", item_index, item_count)
    if delcount == item_count then
		local collection = "erase_prop_rec"
		local doc = {funname = "human_item_logic:erase_material_item", logparam = logparam, name = human:get_name(), guid = human:get_guid(), item_index = item_index, count = item_count, time = os.time(), date_time = utils.get_day_time() }
		skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc})
		return true
	end
	human:notify_tips("道具扣除失败。")
	assert(false,"human_item_logic:erase_material_item == 道具扣除失败")
	return false
end

function human_item_logic:erase_item(logparam, human, bag, item_index, item_count)
	if not item_count or item_count < 1 then
		local doc = { 
			logparam = "human_item_logic:dec_item_lay_count",
			logname = "扣除数量异常",
			name = human:get_name(),
			guid = human:get_guid(),
			item_index = item_index,
			count = item_count,
			date_time = utils.get_day_time()
		}
		skynet.send(".logdb", "lua", "insert", { collection = "call_bug_rec", doc = doc})
		human:notify_tips("扣除数量异常。")
		assert(false,"human_item_logic:erase_item == 扣除数量异常")
		return 0
	end
	local need_count = item_count
    local erased_count = 0
    local container = human:get_prop_bag_container()
	local poscount,delcount
    for i, item in container:ipairs(bag) do
        if need_count > 0 then
            if item then
                if item:get_index() == item_index then
					poscount = item:get_lay_count()
					if poscount > 0 then
						if poscount < need_count then
							delcount = poscount
						else
							delcount = need_count
						end
						self:dec_item_lay_count(logparam, human, i, delcount)
						need_count = need_count - delcount
						erased_count = erased_count + delcount
					end
                end
            end
		else
			break
        end
    end
    return erased_count
end

function human_item_logic:erase_item_by_bag_index(logparam, human, bag_index)
    local container = human:get_prop_bag_container()
    local item = container:get_item(bag_index)
    assert(item, item)
    local item_count = item:get_lay_count()
    local item_index = item:get_index()
    container:erase_item(bag_index)
    item = container:get_item(bag_index)
    if item == nil then
        local msg = packet_def.GCItemInfo.new()
        msg.bagIndex = bag_index
        msg.item = item_cls.new():copy_raw_data()
        msg.unknow_1 = 1
        human:get_scene():send2client(human, msg)
    end
    local collection = "erase_prop_rec"
    local doc = {
	funname = "human_item_logic:erase_item_by_bag_index",
	logparam = logparam,
	name = human:get_name(),
	guid = human:get_guid(),
	item_index = item_index,
	count = item_count,
	time = os.time(),
	date_time = utils.get_day_time()
	}
    skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc})
    return true
end

function human_item_logic:calc_bag_item_count(human, item_index)
    local container = human:get_prop_bag_container()
    return container:get_item_count_by_type(item_index)
end

function human_item_logic:calc_equip_item_count(human, item_index)
    local container = human:get_equip_container()
    return container:get_item_count_by_type(item_index)
end

function human_item_logic:create_multi_item_to_bag(logparam, human, item_index, item_count, is_bind, shop_type, quality, extra, precommit)
    if not inventory_guard.integer(item_count, 1, 65535) then return false, define.INVAILD_ID end
    is_bind = is_bind ~= nil and is_bind ~= false and is_bind ~= 0
    if not self:calc_item_space(human, item_index, item_count, is_bind) then return false, define.INVAILD_ID end
    -- GUID allocation yields. Prepare every new object BEFORE changing the bag;
    -- then plan against its current state and commit without any yields.
    local prepared = {}
    local sample = item_operator:gen_item(logparam, item_index, shop_type or 1, quality, extra)
    if not sample then return false, define.INVAILD_ID end
    sample:set_is_bind(is_bind)
    local maximum = sample:get_max_tile_count()
    if not inventory_guard.integer(maximum, 1, 65535) then return false, define.INVAILD_ID end
    prepared[1] = sample
    for i = 2, math.ceil(item_count / maximum) do
        local item = item_operator:gen_item(logparam, item_index, shop_type or 1, quality, extra)
        if not item then return false, define.INVAILD_ID end
        item:set_is_bind(is_bind)
        prepared[i] = item
    end
    local bag, left, changes = human:get_prop_bag_container(), item_count, {}
    local kind = sample:get_place_bag()
    for pos, item in bag:ipairs(kind) do
        if left > 0 and inventory_guard.stackable(sample, item) then
            local add = math.min(left, maximum - item:get_lay_count())
            if add > 0 then
                changes[#changes+1] = {pos=pos, item=item, count=item:get_lay_count()+add}
                left = left - add
            end
        end
    end
    local next_new = 1
    for pos, item in bag:ipairs(kind) do
        if left > 0 and not item then
            local add = math.min(left, maximum)
            changes[#changes+1] = {pos=pos, item=prepared[next_new], count=add}
            next_new, left = next_new + 1, left - add
        end
    end
    if left > 0 or (precommit and not precommit()) then return false, define.INVAILD_ID end
    for _, change in ipairs(changes) do
        change.item:set_lay_count(change.count)
        bag:set_item(change.pos, change.item)
    end
    for _, change in ipairs(changes) do
        -- Same two-stage contract as the live create_multi_item_to_bag:
        -- create/replace slot identity first, then apply detail/count.
        local notice = packet_def.GCNotifyEquip.new()
        notice.bag_index, notice.item = change.pos, change.item:copy_raw_data()
        human:get_scene():send2client(human, notice)
        local msg = packet_def.GCItemInfo.new()
        msg.bagIndex, msg.item = change.pos, change.item:copy_raw_data()
        human:get_scene():send2client(human, msg)
    end
    skynet.send(".logdb", "lua", "insert", {collection="create_item_to_bag_rec",doc={
        name=human:get_name(),guid=human:get_guid(),param=logparam,item_index=item_index,
        item_count=item_count,is_bind=is_bind,date_time=utils.get_day_time()}})
    return true, changes[#changes].pos
end

function human_item_logic:create_item_to_bag(logparam, human, item_index, is_bind, way, quality, extra)
	-- skynet.logi("create_item_to_bag", item_index, is_bind, way)
	-- print("human_item_logic:create_item_to_bag =", item_index, is_bind, way)
    assert(human)
    assert(item_index and item_index ~= define.INVAILD_ID)
    local container = human:get_prop_bag_container()
    way = way or 1
    local ret, bag_index = item_operator:create_item_with_quality(logparam, item_index, container, is_bind, way, quality, extra)
    if ret then
		if not logparam.logflag then
			logparam.fun_name = "human_item_logic:create_item_to_bag"
            local collection = "create_item_to_bag_rec"
            local doc = { 
			name = human:get_name(),
			guid = human:get_guid(),
			param = logparam,
			item_index = item_index,
			item_count = 1,
			is_bind = is_bind,
			-- unix_time = os.time(),
			date_time = utils.get_day_time()
			}
            skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc })
		end
    else
        bag_index = define.INVAILD_ID
    end
    return bag_index
end

function human_item_logic:get_items_in_need(human, item_index, need)
    local items = human:get_prop_bag_container():get_items_by_type_class_with_bind(item_index)
    local count = 0
    local bag_indexs = {}
	local isbind = false
    for bag_index, item in pairs(items.bind) do
        if need - count > 0 then
            local diff = need - count - item:get_lay_count()
            local add
            if diff < 0 then
                add = need - count
            else
                add = item:get_lay_count()
            end
            table.insert(bag_indexs, { bag_index = bag_index, count = add})
            count =  count + add
			isbind = true
        end
    end
    for bag_index, item in pairs(items.not_bind) do
        if need - count > 0 then
            local diff = need - count - item:get_lay_count()
            local add
            if diff < 0 then
                add = need - count
            else
                add = item:get_lay_count()
            end
            table.insert(bag_indexs, { bag_index = bag_index, count = add})
            count =  count + add
        end
    end
    if need == count then
        return bag_indexs,isbind
    end
end

function human_item_logic:gem_compound_item_index(item_index)
	local env = skynet.getenv("env")
	local max_gem_level = define.MAX_GEM_QUALITY[env] or 7
    local quality = self:get_serial_quality(item_index)
    quality = quality + 1
	if quality > max_gem_level then
		return 0,quality
	end
	local gem_index = item_index % 1000
	local new_item_index
	if gem_index >= 100 + quality - 1 then
		-- 冥晶石：琢刻满级或第二色系，合成后GemIndex也递增
		new_item_index = item_index + 100001
	else
		new_item_index = item_index + 100000
	end
	return new_item_index,quality
end

function human_item_logic:move_item_from_bag_to_container(logparam, human, destcontainer, index)
	--skynet.logi("move_item_from_bag_to_container")
	local dest_index = destcontainer:get_empty_item_index()
    if dest_index == define.INVAILD_ID then
        return false
    end
    local item = human:get_prop_bag_container():get_item(index)
    assert(item)
    local dest_item = destcontainer:get_item(dest_index)
    if dest_item then
        return false
    end
    human:get_prop_bag_container():erase_item(index)
    destcontainer:set_item(dest_index, item)
    return true, dest_index
end

function human_item_logic:move_pet_from_bag_to_container(logparam, human, destcontainer, index)
    local dest_index = destcontainer:get_empty_item_index()
    if dest_index == define.INVAILD_ID then
        return false
    end
    local item = human:get_pet_bag_container():get_item(index)
    assert(item)
    local dest_item = destcontainer:get_item(dest_index)
    if dest_item then
        return false
    end
    human:get_pet_bag_container():erase_item(index)
    destcontainer:set_item(dest_index, item)
    return true, dest_index
end

function human_item_logic:move_item_from_bag_to_container_expect_index(logparam, human, destcontainer, index, expect_index)
	--skynet.logi("move_item_from_bag_to_container_expect_index")
	local dest_index = destcontainer:get_empty_item_index_expect_index(expect_index)
    if dest_index == define.INVAILD_ID then
		human:notify_tips("衣柜已满，可打开易容阁整理一下您的时装。")
        return
    end
	local bag_container = human:get_prop_bag_container()
    local item = bag_container:get_item(index)
	if not item then
		human:notify_tips("您是要把时装放进衣柜吗，您的时装呢？")
        return
    end
	local point = item:get_item_point()
	if point ~= define.HUMAN_EQUIP.HEQUIP_FASHION then
		human:notify_tips("您是要把时装放进衣柜吗，您选择的不是时装。")
        return
    end
    local dest_item = destcontainer:get_item(dest_index)
    if dest_item then
		human:notify_tips("error。")
        return
    end
    bag_container:erase_item(index)
    destcontainer:set_item(dest_index, item)
    return true,dest_index
end

function human_item_logic:move_item_from_bag_to_container_with_index(logparam, human, destcontainer, from_index, dest_index)
    -- CYS-INV transfer boundaries
    local src, dst = human:get_prop_bag_container(), destcontainer
    local item = inventory_guard.accepts(src, from_index) and src:get_item(from_index)
    if not item or item:is_lock() or not inventory_guard.accepts(dst, dest_index, item)
        or dst:get_item(dest_index) then return false end
	--skynet.logi("move_item_from_bag_to_container_with_index")
	if dest_index == define.INVAILD_ID then
        return false
    end
    local item = human:get_prop_bag_container():get_item(from_index)
    assert(item)
    local dest_item = destcontainer:get_item(dest_index)
    assert(dest_item == nil, dest_index)
    human:get_prop_bag_container():erase_item(from_index)
    destcontainer:set_item(dest_index, item)
    return true, dest_index
end

function human_item_logic:move_item_from_container_to_bag_with_index(logparam, human, fromcontainer, from_index, dest_index, isstall)
    -- CYS-INV transfer boundaries
    local src, dst = fromcontainer, human:get_prop_bag_container()
    local item = inventory_guard.accepts(src, from_index) and src:get_item(from_index)
    if not item or item:is_lock() or not inventory_guard.accepts(dst, dest_index, item)
        or dst:get_item(dest_index) then return false end
	--skynet.logi("move_item_from_container_to_bag_with_index")
	if dest_index == define.INVAILD_ID then
        return false
    end
    local item = fromcontainer:get_item(from_index)
    assert(item)
    local dest_item = human:get_prop_bag_container():get_item(dest_index)
    if dest_item then
        return false
    end
    fromcontainer:erase_item(from_index)
    human:get_prop_bag_container():set_item(dest_index, item)
	if isstall then
		local collection = "new_create_item_to_bag_rec"
		local doc = { 
		name = human:get_name(),
		guid = human:get_guid(),
		param = {act_name = "摊位购买道具",fun_name = "human_item_logic:move_item_from_container_to_bag_with_index",},
		item_index = item:get_index(),
		item_count = item:get_lay_count(),
		is_bind = item:is_bind(),
		date_time = utils.get_day_time()
		}
		skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc })
	end
	
    return true, dest_index
end

function human_item_logic:split_item(src_container, src_index, count, dest_container, dest_index)
    local item = src_container:get_item(src_index)
    if item == nil then
        return false
    end
    if item:is_empty() then
        return false
    end
    local logparam = {}
    local ret = item_operator:split_item(logparam, src_container, src_index, count, dest_container, dest_index)
    return ret == define.ITEM_OPERATOR_ERROR.ITEMOE_SUCCESS
end

function human_item_logic:get_serial_class(item_index)
    return math.floor(item_index / 10000000)
end

function human_item_logic:get_serial_quality(item_index)
    return math.floor((item_index % 10000000) / 100000)
end


function human_item_logic:get_place_bag(item_index)
    local cls = self:get_serial_class(item_index)
    if cls == 1 or cls == 3 then
        return "prop"
    elseif cls == 4 then
        return "task"
    else
        return "material"
    end
end

function human_item_logic:get_item(human, bag_index)
    local container = human:get_prop_bag_container()
    return container:get_item(bag_index)
end
function human_item_logic:check_items_space_is_enough(human, item_list)
    item_list = item_list or {}
    local need_empty_count = {}
    need_empty_count.prop = 0
    need_empty_count.material = 0
    need_empty_count.task = 0
    for _, il in ipairs(item_list) do
        local item = item_cls.new()
        item:set_index(il.item_index)
        local max_tile_count = item:get_max_tile_count()
        local place_bag = item:get_place_bag()
        local need_space = math.ceil(il.count / max_tile_count)
        need_empty_count[place_bag] = need_empty_count[place_bag] + need_space
    end
    local prop_bag_container = human:get_prop_bag_container()
    local prop_can_recive = need_empty_count.prop <= prop_bag_container:get_empty_index_count("prop")
    local material_can_recive = need_empty_count.material <= prop_bag_container:get_empty_index_count("material")
    local task_can_recive = need_empty_count.task <= prop_bag_container:get_empty_index_count("task")
    return prop_can_recive and material_can_recive and task_can_recive
end

function human_item_logic:calc_item_space(human, item_index, need_count, is_bind)
    -- CYS-INV space quantity
    if not inventory_guard.integer(need_count, 1, 2147483647) then return false end
    is_bind = is_bind ~= nil and is_bind ~= false and is_bind ~= 0
    assert(need_count > 0)
    assert(item_index and item_index ~= define.INVAILD_ID)
    local count = 0
    local tile_count = 0

    local temp = item_cls.new()
    temp:set_index(item_index)
    local max_tile_count = temp:get_max_tile_count()
    local bag = temp:get_place_bag()
    local container = human:get_prop_bag()
    for _, item in container:ipairs(bag) do
        if item == nil then
            count = count + max_tile_count
        else
            if item:get_index() == item_index and item:is_bind() == is_bind and not item:is_lock() then
                if max_tile_count == 1 then
                else
                    tile_count = tile_count + max_tile_count - item:get_lay_count()
                end
            end
        end
    end
    if (count + tile_count) < need_count then
        return false
    else
        need_count = need_count - tile_count
        if need_count < 0 then
            return true, 0
        else
            return true, math.ceil(need_count / max_tile_count)
        end
    end
end

function human_item_logic:get_item_pos_by_type(human, item_index)
    local container = human:get_prop_bag_container()
    return container:get_item_pos_by_type(item_index)
end

function human_item_logic:get_bag_pos_by_item_sn_available_bind(human, item_index, is_bind)
    local container = human:get_prop_bag_container()
    return container:get_bag_pos_by_item_sn_available_bind(item_index, is_bind)
end

function human_item_logic:get_item_by_guid(human, guid)
    local prop_bag_container = human:get_prop_bag_container()
    local item = prop_bag_container:get_item_by_guid(guid)
    if item == nil then
        local equipcontainer = human:get_equip_container()
        item = equipcontainer:get_item_by_guid(guid)
    end
    return item
end

function human_item_logic:is_item_can_exchange(human, contaner, bag_index)
    return true
end

function human_item_logic:is_pet_can_exchange(human, contaner, bag_index)
    return true
end

function human_item_logic:can_recive_exchange_item_list(human, item_list, pet_list)
    local can_recive_items = self:can_recive_item_list(human, item_list)
    local can_recive_pets = self:can_recive_pet_list(human, pet_list)
    return can_recive_items and can_recive_pets
end

function human_item_logic:can_recive_item_list(human, item_list)
    item_list = item_list or {}
    local need_empty_count = {}
    need_empty_count.prop = 0
    need_empty_count.material = 0
    need_empty_count.task = 0
    for _, item in ipairs(item_list) do
        local place_bag = item:get_place_bag()
        need_empty_count[place_bag] = need_empty_count[place_bag] + 1
    end
    local prop_bag_container = human:get_prop_bag_container()
    local prop_can_recive = need_empty_count.prop <= prop_bag_container:get_empty_index_count("prop")
    local material_can_recive = need_empty_count.material <= prop_bag_container:get_empty_index_count("material")
    local task_can_recive = need_empty_count.task <= prop_bag_container:get_empty_index_count("task")
    return prop_can_recive and material_can_recive and task_can_recive
end

function human_item_logic:can_recive_pet_list(human, pet_list)
    pet_list = pet_list or {}
    local pet_bag_container = human:get_pet_bag_container()
    return #pet_list <= pet_bag_container:get_empty_index_count()
end

return human_item_logic