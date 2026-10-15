-- 时装点缀合成
-- 普通
local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local packet_def = require "game.packet"
local human_item_logic = require "human_item_logic"
local script_base = require "script_base"
local dress_gem_compose = class("dress_gem_compose", script_base)
local MAT_ITEM_INDEX = 30503137
local skynet = require "skynet"

-- self:CallScriptFunction(830015,"Dress_GemCompose",selfId,格位1,格位2,格位3,格位4,格位5,符的位置)


function dress_gem_compose:Dress_GemCompose(selfId, gem_pos_1, gem_pos_2, gem_pos_3,gem_pos_4, gem_pos_5, mat_index)
    print("dress_gem_compose:Dress_GemCompose =", selfId, gem_pos_1, gem_pos_2, gem_pos_3,gem_pos_4, gem_pos_5, mat_index)
    local gem_1 = self:GetBagItem(selfId, gem_pos_1)
    local gem_2 = self:GetBagItem(selfId, gem_pos_2)
    local gem_3 = self:GetBagItem(selfId, gem_pos_3)
    local gem_4 = self:GetBagItem(selfId, gem_pos_4)
    local gem_5 = self:GetBagItem(selfId, gem_pos_5)
    local gems = {}
    local gems_pos = {}
    if gem_1 then
        table.insert(gems, gem_1)
        table.insert(gems_pos, gem_pos_1)
    else
        assert(gem_pos_1 == define.INVAILD_ID)
    end
    if gem_2 then
        table.insert(gems, gem_2)
        table.insert(gems_pos, gem_pos_2)
    else
        assert(gem_pos_2 == define.INVAILD_ID)
    end
    if gem_3 then
        table.insert(gems, gem_3)
        table.insert(gems_pos, gem_pos_3)
    else
        assert(gem_pos_3 == define.INVAILD_ID)
    end
    if gem_4 then
        table.insert(gems, gem_4)
        table.insert(gems_pos, gem_pos_4)
    else
        assert(gem_pos_4 == define.INVAILD_ID)
    end
    if gem_5 then
        table.insert(gems, gem_5)
        table.insert(gems_pos, gem_pos_5)
    else
        assert(gem_pos_5 == define.INVAILD_ID)
    end
	local isbind,curbind = false
    for i = 1, #gems do
		curbind = gems[i]:is_bind()
		if curbind then
			isbind = true
		end
        if i > 1 then
            if gems[i]:get_index() ~= gems[i - 1]:get_index() then
                self:notify_tips(selfId, "#{SZPR_091023_61}")
                return
            end
        end
    end
	local isdel = false
	local ntype
	for i = 1,#gems do
		ntype = self:LuaFnGetItemType(gems[i]:get_index())
		if ntype ~= 31 and ntype ~= 32 and ntype ~= 33 then
			isdel = true
			break
			-- self:EraseItem(selfId, gems_pos[i])
		end
	end
	if isdel then
		local human = self:get_scene():get_obj_by_id(selfId)
		local guid = human:get_guid()
		local name = human:get_name()
		local obj = self.scene.objs[selfId]
		local level = obj:get_attrib("level")
		local _,accountname = skynet.call(".gamed", "lua", "query_roler_account", string.format("%x", guid))
		local date_time = os.date("%y-%m-%d %H:%M:%S")
		local collection_x = "log_newhuodong"
		local doc_x = {
			gm_name = name,
			gm_guid = guid,
			gm_level = level,
			gm_account = accountname,
			actname = "Bảo thạch thẻ hợp thành điểm xuyết",
			info1 = info1,
			info2 = info2,
			info3 = info3,
			date_time = os.date("%y-%m-%d %H:%M:%S")
		}
		local positemcount
		local del
		for i = 100,199 do
			local itemid = self:LuaFnGetItemTableIndexByIndex(selfId, i)
			if itemid and itemid > 50000000 then
				ntype = self:LuaFnGetItemType(itemid)
				if ntype ~= 31 and ntype ~= 32 and ntype ~= 33 then
					positemcount = self:GetBagItemLayCount(selfId, i)
					del = self:EraseItem(selfId, i)
					doc_x.info1 = "Xóa đạo cụ:"..self:GetItemName(itemid).."("..tostring(itemid)..")"
					doc_x.info2 = "Số lượng xóa:"..tostring(positemcount)
					if del then
						doc_x.info3 = "Kết quả xóa: thành công"
					else
						doc_x.info3 = "Kết quả xóa: thất bại"
					end
					skynet.send(".logdb", "lua", "insert", { collection = collection_x, doc = doc_x})
				end
			end
		end
		return
	end
    if #gems < 3 then
        self:notify_tips(selfId, "Thời trang phối sức đặt vào cần nhiều hơn 2")
        return
    end
    if gems[1]:get_base_config().quality >= 4 then
        self:notify_tips(selfId, "#{SZPR_091023_63}")
        return
    end
    local mat = self:GetBagItem(selfId, mat_index)
    if mat == nil or mat:get_index() ~= MAT_ITEM_INDEX then
        self:notify_tips(selfId, "#{SZPR_XML_41}")
        return
    end
    for i = 1, #gems_pos do
        if i > 1 then
            if gems_pos[i] == gems_pos[i - 1] then
                self:notify_tips(selfId, "Vị trí đá điểm xuyết trùng nhau, xin thao tác lại")
                return
            end
        end
    end
    local cost_money = 5000
    local HumanMoney = self:GetMoney(selfId) + self:GetMoneyJZ(selfId)
    if HumanMoney < cost_money then
        self:notify_tips(selfId, "Kim tệ không đủ")
        return
    end
    for i = 1, #gems_pos do
        del = self:LuaFnDecItemLayCount(selfId, gems_pos[i], 1)
		if not del then
			self:notify_tips(selfId, "Trừ đá điểm xuyết thất bại")
			return
		end
    end
    del = self:LuaFnDecItemLayCount(selfId, mat_index, 1)
	if not del then
		self:notify_tips(selfId, "Trừ đạo cụ thất bại")
		return
	end
    del = self:LuaFnCostMoneyWithPriority( selfId, cost_money)
	if not del then
		self:notify_tips(selfId, "Trừ tiền thất bại")
		return
	end
    local item_index = gems[1]:get_index()
    item_index = item_index + 100000
    local newpos = self:TryRecieveItem(selfId, item_index, false, 1)
	if newpos and newpos ~= -1 and isbind then
		self:LuaFnItemBind(selfId, newpos)
	end
end

return dress_gem_compose
