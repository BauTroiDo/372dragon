local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local gbk = require "wire_charset"
local skynet = require "skynet"
local configenginer = require "configenginer":getinstance()
-- local packet_def = require "game.packet"
local webcall = class("webcall", script_base)
webcall.script_id = 700490

--webGMTools 调整角色MissionData数据
function webcall:SetPlayerMissionData(selfId,params)
	skynet.logw("webcall:SetPlayerMissionData called, selfId =", selfId, "params =", table.tostr(params))

	local playerguid = self:LuaFnGetGUID(selfId)
	local playername = self:GetName(selfId)
	if not playerguid or not playername then
		local err_msg = "Xử lý thất bại! Không lấy được thông tin, người chơi có thể offline"
		skynet.loge("webcall:SetPlayerMissionData error: Cannot get player info. selfId =", selfId)
		return err_msg
	end

	local mdtype = tonumber(params.mdtype) --类型 (MissionData = 0 MissionDataEx = 1)
	if not mdtype or mdtype < 0 or mdtype > 1 then
		local err_msg = "Xử lý thất bại! Tham số sai: mdtype không hợp lệ hoặc nhỏ hơn 0"
		skynet.loge("webcall:SetPlayerMissionData error: mdtype invalid. mdtype =", params and params.mdtype)
		return err_msg
	end

	local missiondataindex = tonumber(params.missiondataindex) --索引
	if not missiondataindex or missiondataindex < 0 then
		local err_msg = "Xử lý thất bại! Tham số sai: missiondataindex không hợp lệ hoặc nhỏ hơn 0"
		skynet.loge("webcall:SetPlayerMissionData error: missiondataindex invalid. missiondataindex =", params and params.missiondataindex)
		return err_msg
	end

	local mdnum = tonumber(params.mdnum) --有数据就行,可以是负数
	if not mdnum then
		local err_msg = "Xử lý thất bại! Tham số sai: mdnum không hợp lệ"
		skynet.loge("webcall:SetPlayerMissionData error: mdnum invalid. mdnum =", params and params.mdnum)
		return err_msg
	end

	if mdtype == 0 then
		local missiondata = self:GetMissionData(selfId,missiondataindex)
		self:SetMissionData(selfId,missiondataindex,missiondata+mdnum)
		return "Xử lý thành công! Người chơi["..playername..":"..playerguid.."]dữ liệu MissionData do"..missiondata.."điều chỉnh thành"..missiondata+mdnum
	elseif mdtype == 1 then
		local missiondataex = self:GetMissionDataEx(selfId,missiondataindex)
		self:SetMissionDataEx(selfId,missiondataindex,missiondataex+mdnum)
		return "Xử lý thành công! Người chơi["..playername..":"..playerguid.."]dữ liệu MissionDataEx do"..missiondataex.."điều chỉnh thành"..missiondataex+mdnum
	else
		local err_msg = "Xử lý thất bại! Tham số sai: giá trị mdtype bất thường"
		skynet.loge("webcall:SetPlayerMissionData error: mdtype unexpected value. mdtype =", mdtype)
		return err_msg
	end
end

function webcall:SetPlayerXinFa(selfId,params)
	skynet.logw("webcall:SetPlayerXinFa called, selfId =", selfId, "params =", table.tostr(params))
	
	local playerguid = self:LuaFnGetGUID(selfId)
	local playername = self:GetName(selfId)
	
	-- 验证玩家是否存在
	if not playerguid or not playername then
		local err_msg = "Xử lý thất bại! Không lấy được thông tin, người chơi có thể offline"
		skynet.loge("webcall:SetPlayerXinFa error: Cannot get player info. selfId =", selfId)
		return err_msg
	end
	
	-- 验证心法等级参数
	local level = tonumber(params and params.level)
	if not level or level < 1 then
		local err_msg = "Xử lý thất bại! Tham số sai: level không hợp lệ hoặc nhỏ hơn 1"
		skynet.loge("webcall:SetPlayerXinFa error: level invalid. level =", params and params.level)
		return err_msg
	end
	
	-- 获取玩家等级
	local player_level = self:GetLevel(selfId)
	if not player_level or player_level <= 0 then
		local err_msg = "Xử lý thất bại! Không lấy được cấp người chơi"
		skynet.loge("webcall:SetPlayerXinFa error: Cannot get player level. selfId =", selfId)
		return err_msg
	end
	
	-- 验证心法等级不能超过人物等级
	if level > player_level + 10 then
		local err_msg = string.format("Xử lý thất bại! Cấp tâm pháp (%d) không vượt cấp nhân vật (%d+10) được", level, player_level)
		skynet.loge("webcall:SetPlayerXinFa error: XinFa level exceeds player level. level =", level, "player_level =", player_level)
		return err_msg
	end
	
	-- 获取心法配置和玩家门派
	local xinfa_v1 = configenginer:get_config("xinfa_v1")
	if not xinfa_v1 then
		local err_msg = "Xử lý thất bại! Không lấy được cấu hình tâm pháp"
		skynet.loge("webcall:SetPlayerXinFa error: Cannot get xinfa_v1 config")
		return err_msg
	end
	
	local menpai = self:GetMenPai(selfId)
	if not menpai then
		local err_msg = "Xử lý thất bại! Không lấy được môn phái người chơi"
		skynet.loge("webcall:SetPlayerXinFa error: Cannot get player menpai. selfId =", selfId)
		return err_msg
	end
	
	-- 遍历所有心法，找到属于玩家门派且已领悟的心法，设置等级
	local set_count = 0
	local xinfa_list = {}
	
	for id, v1 in ipairs(xinfa_v1) do
		if v1.menpai == menpai then
			-- 只处理已领悟的心法
			if self:HaveXinFa(selfId, id) ~= define.INVAILD_ID then
				self:LuaFnSetXinFaLevel(selfId, id, level)
				set_count = set_count + 1
				table.insert(xinfa_list, id)
				skynet.logi("webcall:SetPlayerXinFa: Set XinFa level. xinfa_id =", id, "level =", level)
			end
		end
	end
	
	if set_count == 0 then
		local err_msg = "Xử lý thất bại! Người chơi chưa lĩnh ngộ tâm pháp môn phái"
		skynet.loge("webcall:SetPlayerXinFa error: Player has no learned XinFa. PlayerName =", playername, "GUID =", playerguid, "menpai =", menpai)
		return err_msg
	end
	
	local success_msg = string.format("Xử lý thành công! Người chơi [%s:%s] đã nâng %d tâm pháp môn phái đã lĩnh ngộ lên cấp %d", 
		playername, playerguid, set_count, level)
	skynet.logi("webcall:SetPlayerXinFa success: PlayerName =", playername, "GUID =", playerguid, 
		"set_count =", set_count, "level =", level, "xinfa_ids =", table.concat(xinfa_list, ","))
	
	return success_msg
end

function webcall:kickPlayer(selfId,params)
	skynet.logw("webcall:kickPlayer called, selfId =", selfId, "params =", table.tostr(params))
	
	local playerguid = self:LuaFnGetGUID(selfId)
	local playername = self:GetName(selfId)
	
	-- 验证玩家是否存在
	if not playerguid or not playername then
		local err_msg = "Xử lý thất bại! Không lấy được thông tin, người chơi có thể offline"
		skynet.loge("webcall:kickPlayer error: Cannot get player info. selfId =", selfId)
		return err_msg
	end
	
	-- 获取踢出原因（可选参数）
	local reason = params and params.reason or "maintenance"
	if type(reason) ~= "string" then
		reason = "maintenance"
	end
	
	-- 执行踢出操作
	skynet.send(".gamed", "lua", "kick", playerguid, 0, reason)
	
	skynet.logi("webcall:kickPlayer success: PlayerName =", playername, "GUID =", playerguid, "Reason =", reason)
	return "Xử lý thành công! Người chơi["..playername..":"..playerguid.."]đã bị đá khỏi mạng! Lý do:"..reason
end
--webGMTools 调整角色限制交易
function webcall:SetPlayerLimitExchange(selfId,params)
	skynet.logw("webcall:SetPlayerLimitExchange called, selfId =", selfId, "params =", table.tostr(params))
	local open_params = {}
	open_params.limit = tonumber(params.limit) or 188 --防止出错默认 188限制交易
	if open_params.limit == 0 then
		skynet.loge("webcall:SetPlayerLimitExchange error: limit  must not be 0")
		return "Xử lý thất bại! Đặt 0 sẽ cho nhận lặp CDK, xin chỉnh lại giá trị quyền!"
	end
	self:SetHumanGameFlag(selfId,"def_player_flag",open_params.limit)
	local playerguid = self:LuaFnGetGUID(selfId)
	local playername = self:GetName(selfId)
	skynet.logi("webcall:SetPlayerLimitExchange success: PlayerName = ",playername,"GUID =",playerguid," limit = ",open_params.limit)

	local limit_map = {[188] = "[Hạn chế giao dịch nhân vật]", [189] = "[Không hạn chế giao dịch nhân vật]"}
	local test = limit_map[open_params.limit] or "Chưa rõ:"..open_params.limit
	local ntext = "Xử lý thành công! Người chơi["..playername..":"..playerguid.."]quyền đã chỉnh thành"..test
	return ntext
end

--在线发放道具 玩家需在线
function webcall:GivePlayerItems(selfId,params)
	skynet.logw("webcall:GivePlayerItems called, selfId =", selfId, "params =", table.tostr(params))
	
	local playerguid = self:LuaFnGetGUID(selfId)
	local playername = self:GetName(selfId)
	
	-- 验证 item_list 参数
	if not params or not params.item_list then
		local err_msg = "Xử lý thất bại! Tham số sai: item_list không được rỗng"
		skynet.loge("webcall:GivePlayerItems error: item_list is nil or empty. PlayerName =", playername, "GUID =", playerguid)
		return err_msg
	end
	
	if type(params.item_list) ~= "table" then
		local err_msg = "Xử lý thất bại! Tham số sai: item_list phải là mảng"
		skynet.loge("webcall:GivePlayerItems error: item_list is not a table. PlayerName =", playername, "GUID =", playerguid)
		return err_msg
	end
	
	if #params.item_list == 0 then
		local err_msg = "Xử lý thất bại! Tham số sai: item_list không được là mảng rỗng"
		skynet.loge("webcall:GivePlayerItems error: item_list is empty. PlayerName =", playername, "GUID =", playerguid)
		return err_msg
	end
	
	-- 验证每个物品的数据
	local valid_items = {}
	local error_items = {}
	
	for i, item in ipairs(params.item_list) do
		-- 验证 itemid
		local itemid = tonumber(item.itemid)
		if not itemid or itemid <= 0 then
			table.insert(error_items, {index = i, reason = "itemid không hợp lệ hoặc <= 0", item = item})
			skynet.loge("webcall:GivePlayerItems error: item[", i, "] itemid invalid. itemid =", item.itemid)
		else
			-- 验证 num
			local num = tonumber(item.num)
			if not num or num <= 0 then
				table.insert(error_items, {index = i, reason = "num không hợp lệ hoặc <= 0", item = item})
				skynet.loge("webcall:GivePlayerItems error: item[", i, "] num invalid. num =", item.num)
			else
				-- 验证 isBind
				local isBind = tonumber(item.isBind)
				if isBind == nil or (isBind ~= 0 and isBind ~= 1) then
					table.insert(error_items, {index = i, reason = "isBind phải là 0 hoặc 1", item = item})
					skynet.loge("webcall:GivePlayerItems error: item[", i, "] isBind invalid. isBind =", item.isBind)
				else
					-- 转换为布尔值 (0=false, 1=true)
					local is_bind = (isBind == 1)
					
					-- 添加到有效物品列表
					table.insert(valid_items, {
						itemid = itemid,
						num = num,
						is_bind = is_bind
					})
				end
			end
		end
	end
	
	-- 如果有无效物品，记录并返回错误
	if #error_items > 0 then
		local err_msg = "Xử lý thất bại! Phát hiện " .. #error_items .. " dữ liệu vật phẩm không hợp lệ:\\n"
		for _, err_item in ipairs(error_items) do
			err_msg = err_msg .. string.format("  Vật phẩm [%d]: %s (itemid=%s, num=%s, isBind=%s)\\n", 
				err_item.index, err_item.reason, 
				tostring(err_item.item.itemid), 
				tostring(err_item.item.num), 
				tostring(err_item.item.isBind))
		end
		skynet.loge("webcall:GivePlayerItems error: Invalid items found. PlayerName =", playername, "GUID =", playerguid, "ErrorCount =", #error_items)
		return err_msg
	end
	
	-- 如果没有有效物品，返回错误
	if #valid_items == 0 then
		local err_msg = "Xử lý thất bại! Không có dữ liệu vật phẩm hợp lệ"
		skynet.loge("webcall:GivePlayerItems error: No valid items. PlayerName =", playername, "GUID =", playerguid)
		return err_msg
	end
	
	-- 开始发放物品
	self:BeginAddItem()
	
	-- 添加所有有效物品
	for _, item in ipairs(valid_items) do
		self:AddItem(item.itemid, item.num, item.is_bind)
		skynet.logi("webcall:GivePlayerItems adding item: itemid =", item.itemid, "num =", item.num, "is_bind =", item.is_bind)
	end
	
	-- 检查背包空间
	if not self:EndAddItem(selfId) then
		local err_msg = "Xử lý thất bại! Túi người chơi thiếu chỗ, không phát được"
		skynet.loge("webcall:GivePlayerItems error: Not enough bag space. PlayerName =", playername, "GUID =", playerguid)
		self:BeginAddItem() -- 清空物品列表
		return err_msg
	end
	
	-- 实际发放物品
	self:AddItemListToHuman(selfId)
	
	-- 构建成功消息
	local success_msg = "Xử lý thành công! Người chơi[" .. playername .. ":" .. playerguid .. "]đã phát thành công " .. #valid_items .. " loại vật phẩm:\\n"
	for _, item in ipairs(valid_items) do
		local item_name = self:GetItemName(item.itemid) or ("Vật phẩm ID:" .. item.itemid)
		local bind_text = item.is_bind and "Trói buộc" or "Không khóa"
		success_msg = success_msg .. string.format("  - %s x%d (%s)\n", item_name, item.num, bind_text)
	end
	
	skynet.logi("webcall:GivePlayerItems success: PlayerName =", playername, "GUID =", playerguid, "ItemCount =", #valid_items)
	
	return success_msg
end

return webcall
