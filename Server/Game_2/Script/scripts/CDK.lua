local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ScriptGlobal = require "scripts.ScriptGlobal"
local CDK = class("CDK", script_base)
CDK.script_id = 900067

CDK.cdk_file_path = "/home/ubuntu/cys-test-20260913/CDK/CDK.txt"
CDK.cdk_claimed_dir = "/home/ubuntu/cys-test-20260913/CDK/"

--[[CDK.create_cdk_ini = {
	{item_id = 38008168,item_num = 1,cdk_count = 500,cdk_price = 20},
	{item_id = 38008169,item_num = 1,cdk_count = 286,cdk_price = 20},
	{item_id = 38008170,item_num = 1,cdk_count = 150,cdk_price = 20},
	{item_id = 38008172,item_num = 1,cdk_count = 30,cdk_price = 20},
	{item_id = 38008174,item_num = 1,cdk_count = 15,cdk_price = 20},
	{item_id = 38008179,item_num = 1,cdk_count = 10,cdk_price = 20},
	{item_id = 38008180,item_num = 1,cdk_count = 5,cdk_price = 20},
	{item_id = 38008181,item_num = 1,cdk_count = 3,cdk_price = 20},
	{item_id = 38008183,item_num = 1,cdk_count = 1,cdk_price = 20},
	{item_id = 38002834,item_num = 1,cdk_count = 1000,cdk_price = 1},
}--]]
CDK.create_cdk_ini = {
	{item_id = 38008170,item_num = 1,cdk_count = 100,cdk_price = 50},
	{item_id = 38008172,item_num = 1,cdk_count = 60,cdk_price = 50},
	{item_id = 38008173,item_num = 1,cdk_count = 20,cdk_price = 50},
	{item_id = 38008174,item_num = 1,cdk_count = 10,cdk_price = 50},
	{item_id = 38008179,item_num = 1,cdk_count = 5,cdk_price = 50},
	{item_id = 38008180,item_num = 1,cdk_count = 2,cdk_price = 50},
	{item_id = 38008181,item_num = 1,cdk_count = 2,cdk_price = 50},
	{item_id = 38008184,item_num = 1,cdk_count = 1,cdk_price = 50},
}

--新增  CDK
function CDK:AddMoneyCardCount(selfId,count)
	
	
	local isgm = self:CallScriptFunction(900066, "IsGM", selfId)
	if isgm >= 3 then
		if #self.create_cdk_ini < 1 then
			return 0
		end
		local createstr = function()
			local value = math.random(6666)
			if value % 2 == 1 then
				value = math.random(65,90)
			else
				value = math.random(97,122)
			end
			return string.char(value)
		end
		local ndate = os.date("%Y-%m-%d %H:%M:%S")

		-- 从 CDK.txt 读取已有CDK到内存 table 做查重
		local existing_cdks = {}
		local ok_read, _ = pcall(function()
			local rfile = io.open(self.cdk_file_path, "r")
			if rfile then
				for line in rfile:lines() do
					local cdk_code = line:match("^([^\t]+)")
					if cdk_code then
						existing_cdks[cdk_code] = true
					end
				end
				rfile:close()
			end
		end)

		local ok_msg = {"Tệp (",self.cdk_file_path,")kết quả tạo:"}

		local add = 0
		local export_lines = {}  -- 收集导出数据
		local num,str = 0,0
		local index,cdkinfo,istrue
		local datalx = {"","","","","",""}

		for _,ct_info in ipairs(self.create_cdk_ini) do

			local ct_num = ct_info.cdk_count
			local ct_num_ing = 0
			local item_name = self:GetItemName(ct_info.item_id)
			table.insert(ok_msg,"\n")
			table.insert(ok_msg,item_name)
			table.insert(ok_msg," X ")
			table.insert(ok_msg,ct_num)
			table.insert(ok_msg,"(Giá:")
			table.insert(ok_msg,ct_info.cdk_price)
			table.insert(ok_msg,")")
			for ct_load = 1,ct_num do
				for n_error = 1,20 do
					num,str = 0,0
					for i = 1,6 do
						index = math.random(6666) % 2
						if index == 1 then
							if num < 3 then
								num = num + 1
							else
								str = str + 1
								index = 0
							end
						else
							if str < 3 then
								str = str + 1
							else
								num = num + 1
								index = 1
							end
						end
						if index == 1 then
							index = math.random(111111,999999)
							datalx[i] = tostring(index)
						else
							datalx[i] = createstr()
						end
					end
					if num == 3 and str == 3 then
						cdkinfo = table.concat(datalx)
						-- 查重：内存 table + 已兑换文件
						if not existing_cdks[cdkinfo] then
							-- 写入 CDK.txt（Tab分隔）
							local ok_w, err_w = pcall(function()
								local wfile = io.open(self.cdk_file_path, "a")
								if wfile then
									wfile:write(string.format("%s\t%d\t%d\t%d\t%s\n",
										cdkinfo, ct_info.item_id, ct_info.item_num, ct_info.cdk_price, ndate))
									wfile:close()
								end
							end)
							if ok_w then
								existing_cdks[cdkinfo] = true
								ct_num_ing = ct_num_ing + 1
								add = add + 1
								table.insert(export_lines, string.format("%s,%s,%d,%d", cdkinfo, item_name, ct_info.item_num, ct_info.cdk_price))
								break
							end
						end
					end
				end
			end
			table.insert(ok_msg,"  ")
			table.insert(ok_msg,ct_num_ing)
			table.insert(ok_msg,"Điều")
		end
		local msg = table.concat(ok_msg)
		-- 自动导出CDK到txt文件
		if #export_lines > 0 then
			local ok, err = pcall(function()
				local home = os.getenv("HOME") or "/root"
				local export_time = os.date("%Y%m%d_%H%M%S")
				local export_path = home .. "/cdk_export_" .. export_time .. ".txt"
				local file = io.open(export_path, "w")
				if file then
					file:write("Mã CDK, tên vật phẩm, số lượng, giá\\n")
					for _, line in ipairs(export_lines) do
						file:write(line .. "\n")
					end
					file:close()
					msg = msg .. "\\n\\n[Đã tự xuất tới: " .. export_path .. "]"
				end
			end)
			if not ok then
				msg = msg .. "\\n\\n[Xuất tệp thất bại: " .. tostring(err) .. "]"
			end
		end
		self:BeginUICommand()
		self:UICommand_AddInt(426042021)
		self:UICommand_AddStr(msg)
		self:EndUICommand()
		self:DispatchUICommand(selfId,426042021)
		return -1
	end
	return 0,"Tệp tin "..self.cdk_file_path
end

function CDK:DelLimitChange(selfId,params)
	if not params.str or params.str ~= "limit_change" then
		self:notify_tips(selfId, "Có lỗi.")
		return
	-- elseif params.guid ~= self:LuaFnGetGUID(selfId) then
		-- self:notify_tips(selfId, "出错。。")
		-- return
	end
	self:SetHumanGameFlag(selfId,"un_limit_change",1)
	--self:SetHumanGameFlag(selfId,"limit_change",0)
	self:SetHumanGameFlag(selfId,params.str,0)
end
function CDK:ReceiveCdkAward(selfId, ... )
	if ScriptGlobal.is_internal_test then
		self:notify_tips(selfId, "Thời gian test không mở đổi CDK, xin dùng sau open beta.")
		return
	end
	local curtime = os.time()
	local datatime = self:GetMissionDataEx(selfId,ScriptGlobal.MDEX_CDK_CD)
	if datatime >= curtime then
		local msg = "Thao tác quá dồn dập ("..(datatime - curtime + 1).."sau mới thao tác tiếp）."
		self:notify_tips(selfId, msg)
		return
	end
	self:SetMissionDataEx(selfId,ScriptGlobal.MDEX_CDK_CD,curtime + 1)
	local paramx = { ... }
	if #paramx < 1 then
		self:notify_tips(selfId, "CDK bất thường.")
		return
	end
	local chars = {}
	for i = 1, #paramx do
		if not paramx[i] or paramx[i] < 33 or paramx[i] > 126 then
			self:notify_tips(selfId, "CDK bất thường..")
			return
		end
		chars[i] = string.char(paramx[i])
	end
	local ServerID = self:LuaFnGetServerID(selfId)
	local cdkinfo = "TL" .. table.concat(chars)

	-- 从 CDK.txt 查找匹配的CDK行
	local found_record = nil
	local ok_find, err_find = pcall(function()
		local rfile = io.open(self.cdk_file_path, "r")
		if rfile then
			for line in rfile:lines() do
				local parts = {}
				for part in line:gmatch("([^\t]+)") do
					table.insert(parts, part)
				end
				if parts[1] == cdkinfo then
					found_record = {
						docindex   = parts[1],
						item_id    = tonumber(parts[2]) or 0,
						item_num   = tonumber(parts[3]) or 0,
						cdk_price  = tonumber(parts[4]) or 0,
						createtimer= parts[5] or "",
					}
					break
				end
			end
			rfile:close()
		end
	end)
	if not found_record then
		self:notify_tips(selfId, "CDK không tồn tại.")
		return
	end

	-- 检查已兑换记录（CDK_ysy.txt）
	local already_claimed = false
	local ok_claimed, _ = pcall(function()
		local cf = io.open(self.cdk_claimed_dir .. "CDK_ysy.txt", "r")
		if cf then
			for line in cf:lines() do
				local code = line:match("^([^\t]+)")
				if code == cdkinfo then
					already_claimed = true
					break
				end
			end
			cf:close()
		end
	end)
	if already_claimed then
		self:notify_tips(selfId, "CDK đã nhận rồi.")
		return
	end

	local istrue = found_record

	-- 新增 检查一下是否领取过了 188卡
	if istrue.cdk_price == 188 then
		local nFlag = self:GetHumanGameFlag(selfId,"def_player_flag") or 0
		if nFlag ~= 0 then
			self:notify_tips(selfId, "Loại CDK này chỉ nhận một lần.")
			return
		end
	end
	if istrue.cdk_price == 1 then
		if ServerID == 20  then --这里限制老区是否开放 10是1区 依次类推
			self:notify_tips(selfId, "Khu này tạm chưa mở.")
			return
		elseif self:GetMissionDataEx(selfId, ScriptGlobal.MD_TUIGUANG) ~= 0 then
			self:notify_tips(selfId, "Loại CDK này chỉ kích hoạt một lần.")
			return
		elseif self:GetHumanGameFlag(selfId,"un_limit_change") ~= 0 then
			--self:notify_tips(selfId, "该类型CDK只能激活一次。")
			--return
		end
	end

	self:BeginAddItem()
	self:AddItem(istrue.item_id,istrue.item_num,true)
	if not self:EndAddItem(selfId,true) then
		return
	end
	local playerguid = self:LuaFnGetGUID(selfId)
	local playername = self:GetName(selfId)
	local skynet = require "skynet"
	local _,accountname = skynet.call(".gamed", "lua", "query_roler_account", string.format("%x", playerguid))
	local claim_time = os.date("%Y-%m-%d %H:%M:%S")

	-- 从 CDK.txt 中移除该CDK（读全部行，过滤后重写）
	local remove_ok = false
	local ok_rm, err_rm = pcall(function()
		local lines = {}
		local rfile = io.open(self.cdk_file_path, "r")
		if rfile then
			for line in rfile:lines() do
				local code = line:match("^([^\t]+)")
				if code ~= cdkinfo then
					table.insert(lines, line)
				end
			end
			rfile:close()
		end
		local wfile = io.open(self.cdk_file_path, "w")
		if wfile then
			for _, line in ipairs(lines) do
				wfile:write(line .. "\n")
			end
			wfile:close()
			remove_ok = true
		end
	end)
	if not remove_ok then
		local skynet_log = require "skynet"
		skynet_log.logi(string.format("[CDK] Xóa ghi chép CDK thất bại: ok_rm=%s, err_rm=%s, cdkinfo=%s", tostring(ok_rm), tostring(err_rm), tostring(cdkinfo)))
		-- 不阻断兑换，已兑换记录靠 claimed 文件防重复
	end

	-- 追加到已兑换记录文件
	local claimed_file = self.cdk_claimed_dir .. "CDK_ysy.txt"
	local ok_claim, err_claim = pcall(function()
		local afile = io.open(claimed_file, "a")
		if afile then
			local playerguid_str = tostring(playerguid or 0)
			afile:write(string.format("%s\t%d\t%d\t%d\t%s\t%s\t%s\t%s\t%s\n",
				cdkinfo, istrue.item_id, istrue.item_num, istrue.cdk_price,
				istrue.createtimer, playerguid_str, playername or "",
				accountname or "", claim_time))
			afile:close()
		else
			error("io.open returned nil for: " .. claimed_file)
		end
	end)
	if not ok_claim then
		local skynet_c = require "skynet"
		skynet_c.logi(string.format("[CDK] Ghi lịch sử đổi thất bại: %s", tostring(err_claim)))
	end

	if istrue.cdk_price == 666 then
		self:SetHumanGameFlag(selfId,"zhu_bo_flag",istrue.cdk_price)
	elseif istrue.cdk_price == 188 then
		self:SetHumanGameFlag(selfId,"def_player_flag",istrue.cdk_price)
	end
	self:BeginAddItem()
	self:AddItem(istrue.item_id,istrue.item_num,true)
	self:EndAddItem(selfId)
	self:AddItemListToHuman(selfId)
	self:notify_tips(selfId,"Kích hoạt thành công.")
end

function CDK:MoveCdk(selfId)
	self:notify_tips(selfId, "Phương án lưu tệp khỏi cần di trú.")
end

function CDK:XuKaJiHuo(selfId, ...)
	return self:ReceiveCdkAward(selfId, ...)
end

--第一次激活奖励
--cdk奖励配置 (至少给一种道具) isbind = true 给予绑定  isbind = false 给予不绑定
--不给称号 把 Titleid TitleName TitleFlag 注掉
--不给绑元把 BindYuanBao 注掉
CDK.AwardInfo = 
{
	--[[称号注释：有 Titleid 时 TitleName 与 TitleFlag 必带
	TitleFlag = 逻辑类型(程序用)  适用于char_title.txt 的称号
	TitleFlag = -1 适用于 char_title_new.txt 的称号]]
	 Titleid = 1073,
	 TitleName = "Danh hiệu: Trúc Giản Khinh Thương Hội Tri Giao",
	 TitleFlag = -1,
	--BindYuanBao = 500000,
	{itemid = 10124519,count = 1,isbind = true},
	{itemid = 10142793,count = 1,isbind = true},
	{itemid = 38000220,count = 1,isbind = true},
	{itemid = 38008160,count = 666,isbind = true},


}
--第二次激活奖励
--cdk奖励配置 (至少给一种道具) isbind = true 给予绑定  isbind = false 给予不绑定
--不给称号 把 Titleid TitleName TitleFlag 注掉就好
--不给绑元把 BindYuanBao 注掉
CDK.AwardInfoTwo = 
{
	--[[称号注释：有 Titleid 时 TitleName 与 TitleFlag 必带
	TitleFlag = 逻辑类型(程序用)  适用于char_title.txt 的称号
	TitleFlag = -1 适用于 char_title_new.txt 的称号]]
	--BindYuanBao = 1000000,
	--{itemid = 38000205,count = 1,isbind = true},
	--{itemid = 38003135,count = 10,isbind = true},
}


function CDK:ReceiveCdkAward_bff(selfId, ...)
	self:notify_tips(selfId, "Chức năng đã ngừng, xin dùng đổi CDK bản mới.")
end
function CDK:AddMoneyCardCount_bff(selfId,count)
	if not count or count < 1 then return 0 end
	local isgm = self:CallScriptFunction(900066, "IsGM", selfId)
	if isgm >= 3 then
		local createstr = function()
			local value = math.random(6666)
			if value % 2 == 1 then
				value = math.random(65,90)
			else
				value = math.random(97,122)
			end
			return string.char(value)
		end
		local ndate = os.date("%Y-%m-%d/%X")
		local addData = {
					docindex = "moneycard",
					createtimer = ndate.."(Tạo)",
					cardguid = "",
					playerguid = 0,
					playername = "",
					awardtimer = "",
					awardtimer_two = "",
					awardinfo = "Vẫn chưa kích hoạt"
		}
		local add = 0
		local num,str = 0,0
		local index,cdkinfo,istrue
		local datalx = {"","","","","",""}
		for m = 1,count do
			for j = 1,20 do
				num,str = 0,0
				for i = 1,6 do
					index = math.random(6666) % 2
					if index == 1 then
						if num < 3 then
							num = num + 1
						else
							str = str + 1
							index = 0
						end
					else
						if str < 3 then
							str = str + 1
						else
							num = num + 1
							index = 1
						end
					end
					if index == 1 then
						index = math.random(111111,999999)
						datalx[i] = tostring(index)
					else
						datalx[i] = createstr()
					end
				end
				if num > 3 or str > 3 then
					return add,"bất thường rồi"
				end
				cdkinfo = table.concat(datalx)
				istrue = self:LuaFnGetDocData(".char_db","money_card","moneycard","findOne","cardguid",cdkinfo)
				if not istrue then
					addData.cardguid = cdkinfo
					add = add + 1
					self:LuaFnSetAddDocData(".char_db","money_card",addData)
					break
				end
			end
		end
		return add,"DB tlbb bảng money_card"
	end
	return 0,"DB tlbb bảng money_card"
end
return CDK