--装备打孔
--普通
local gbk = require "wire_charset"
local class = require "class"
local script_base = require "script_base"
local stiletto = class("stiletto", script_base)
local tEquipGemTable	= {
    [0] = true, [1] = true, [2] = true, [3] = true, [4] = true,
    [5] = true, [6] = true, [7] = true, [11] = true, [12] = true,
    [13] = true, [14] = true, [15] = true, [17] = true, [18] = true,[37] = true, 
}


function stiletto:StilettoEx_3(selfId, idBagPos, idBagPosStuff )
    -- print("stiletto:StilettoEx_3 =", selfId, idBagPos, idBagPosStuff)
	local BagItem = self:GetBagItem(selfId, idBagPos)
    if not BagItem then
        self:notify_tips(selfId, "Trang bị đục lỗ thất bại")
        return
	elseif BagItem:get_index() == -1 or BagItem:get_index() // 10000000 ~= 1 then
        self:notify_tips(selfId, "Trang bị đục lỗ thất bại")
        return
    end
    local Bore_Count = BagItem:get_equip_data():get_slot_count()
	if Bore_Count >= 3 then
        self:notify_tips(selfId, "Chỗ này chỉ có thể đục 3 lỗ đầu")
        return
	end
	local nLevel = BagItem:get_level()
	local EquipType =  BagItem:get_equip_data():get_equip_point()
    if not tEquipGemTable[EquipType] then
        self:notify_tips(selfId, "Trang bị này không hỗ trợ đục lỗ")
        return
    end
    local ret = self:LuaFnStilettoCostExe(selfId, nLevel*100+1+Bore_Count, idBagPosStuff, 1,idBagPos )
    if ret == 1 then
        self:notify_tips(selfId, "Trang bị đục lỗ thành công")
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 49, 0)
	elseif ret == -99 then
		self:notify_tip(selfId, "Đối tượng sai." )
		return
	elseif ret == -98 then
        self:notify_tips(selfId, "Cần phải đặt một Trang bị.")
        return
	elseif ret == -97 then
        self:notify_tips(selfId, "Chỗ này chỉ có thể đục 3 lỗ đầu")
        return
	elseif ret == -1 then
		self:notify_tip(selfId, "Lỗi tra bảng, hỏi người thiết kế." )
		return
	elseif ret == -2 then
		self:notify_tip(selfId, "Ngươi không có Nguyên liệu phù hợp, không thể tiến hành Thao tác này." )
		return
	elseif ret == -3 then
		self:notify_tip(selfId,  "Ngươi không đủ tiền bạc, không thể tiến hành Thao tác này." )
		return
	elseif ret == -4 then
		self:notify_tip(selfId, "Ngươi không đủ Nguyên liệu, không thể tiến hành Thao tác này." )
		return
	elseif ret == -5 then
		self:notify_tip(selfId, "Trang bị đục lỗ thất bại" )
		return
	elseif ret == 0 then
		self:notify_tip(selfId, "Trừ tiền thất bại!" );
		return
	end
    -- ret = self:AddBagItemSlot(selfId, idBagPos)
    -- if ret == 1 then
        -- self:notify_tips(selfId, "装备打孔成功")
        -- self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 49, 0)
    -- end
end

function stiletto:StilettoEx_Yuanbao_Pay(selfId, ItemIndex, check)
	local index, merchadise = self:GetMerchadiseByItemIndex(selfId, ItemIndex)
	if index == nil then
		return
	end
	local item_name = self:GetItemName(merchadise.id)
	self:BeginUICommand()
	self:UICommand_AddInt(check)
	self:UICommand_AddInt(10)
	self:UICommand_AddInt(5)
	self:UICommand_AddInt(merchadise.price)
	self:UICommand_AddInt(index - 1)
	self:UICommand_AddInt(0)
	self:UICommand_AddInt(-1)
	local str = self:ContactArgs("#{BSLCYH_130529_29", item_name, merchadise.price, item_name) .. "}"
	self:UICommand_AddStr(str)
	self:EndUICommand()
	self:DispatchUICommand(selfId, 2013060604)
end

function stiletto:StilettoEx_4(selfId, idBagPos, idBagPosStuff, type)


	if not idBagPos or idBagPos < 0 or idBagPos > 99 then
	    self:notify_tips(selfId, "Vị trí trang bị bất thường." )
		return
	elseif not idBagPosStuff or idBagPosStuff < 0 or idBagPosStuff > 199 then
	    self:notify_tips(selfId, "Vị trí nguyên liệu bất thường." )
		return
	elseif type ~= 1 and type ~= 2 then
	    self:notify_tips(selfId, "Lỗi của loại tiêu hao." )
		return
	 end
	local Equip = self:GetBagItem(selfId, idBagPos)
	if not Equip then
	    self:notify_tips(selfId, "Vị trí trang bị sai." )
		return
	elseif Equip:get_index() == -1 or Equip:get_index() // 10000000 ~= 1 then
	    self:notify_tips(selfId, "Vị trí trang bị sai." )
		return
	 end
	 local Item = self:GetBagItem(selfId, idBagPosStuff)
	 if not Item then
	    self:notify_tips(selfId, "Vị trí nguyên liệu sai." )
		return
	 end
	local point = Equip:get_base_config().equip_point
    if not tEquipGemTable[point] then
        self:notify_tips(selfId, "Trang bị này không hỗ trợ đục lỗ")
        return
    end
	-- if point == define.HUMAN_EQUIP.HEQUIP_RIDER
	-- or point == define.HUMAN_EQUIP.HEQUIP_UNKNOW1
	-- or point == define.HUMAN_EQUIP.HEQUIP_UNKNOW2
	-- or point == define.HUMAN_EQUIP.HEQUIP_FASHION
	-- or point == define.HUMAN_EQUIP.HEQUIP_WUHUN
	-- or point == define.HUMAN_EQUIP.LINGWU_JING
	-- or point == define.HUMAN_EQUIP.LINGWU_CHI
	-- or point == define.HUMAN_EQUIP.LINGWU_JIA
	-- or point == define.HUMAN_EQUIP.LINGWU_GOU
	-- or point == define.HUMAN_EQUIP.LINGWU_DAI
	-- or point == define.HUMAN_EQUIP.LINGWU_DI then
	-- -- or point == define.HUMAN_EQUIP.SHENBING
	-- -- or point == define.HUMAN_EQUIP.HEQUIP_ALL
	    -- self:notify_tips(selfId, "该装备不支持打孔。" )
		-- return
	-- end
	local itemid = Item:get_index()
	if itemid ~= 20109101 and itemid ~= 20310111 then
        self:notify_tips(selfId, "Đặt nguyên liệu bất thường")
        return
    end
    --可打孔的装备
	--0武器，1帽子，2衣服，3手套，4鞋
	--5腰带，6戒指，7项链，12护符，14护腕
	--15护肩
	local szCailiao = self:GetBagItemTransfer(selfId, idBagPosStuff)

	--装备是否是绑定
	local isequipbind = self:LuaFnGetItemBindStatus(selfId, idBagPos )
	--材料是否是绑定
	local isstuffbind = self:LuaFnGetItemBindStatus(selfId, idBagPosStuff )
	local Bore_Count = self:GetBagGemCount(selfId, idBagPos)
	if Bore_Count ~= 3 then
        self:notify_tips(selfId, "Xin đặt trang bị sắp mở lỗ thứ tư vào")
		return
	end
	local nLevel = self:GetBagItemLevel(selfId, idBagPos)
	--打孔消耗
	local ret	= self:LuaFnStilettoCostExe(selfId, nLevel*100+1+Bore_Count, idBagPosStuff, type,idBagPos)
	
	if ret == 1 then
        self:notify_tips(selfId, "Trang bị đục lỗ thành công" )
        --成功公告
        local transfer = self:GetBagItemTransfer(selfId,idBagPos)
        local str = ""
		local name = self:GetName(selfId)
		name = gbk.fromutf8(name)
        if type == 1 then
			str = string.format( "#{_INFOUSR%s}#{AQ_11}#{_INFOMSG%s}#{AQ_32}#{_INFOMSG%s}#{AQ_12}", name, szCailiao,transfer )
		    --self:CostMoney(selfId, 30000000)
        else
            str = string.format( "#{_INFOUSR%s}#{AQ_11}#{_INFOMSG%s}#{AQ_31}#{_INFOMSG%s}#{AQ_12}", name, szCailiao,transfer )
        end
        self:BroadMsgByChatPipe(selfId, str, 4 )

		--增加特效
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 49, 0);
	elseif ret == -99 then
		self:notify_tip(selfId, "Đối tượng sai." )
		return
	elseif ret == -98 then
        self:notify_tips(selfId, "Cần phải đặt một Trang bị.")
        return
	elseif ret == -97 then
		self:notify_tips(selfId, "#{XQC_20080509_04}" )
        return
	elseif ret == -1 then
        self:notify_tips(selfId, "Lỗi tra bảng, hỏi người thiết kế." )
		return
	elseif ret == -2 then
		if type == 1 then
            self:notify_tips(selfId, "#{XQC_20080509_07}" )
		else
            self:notify_tips(selfId, "#{JCDK_80905_07}" )
		end
		return
	elseif ret == -3 then
		if type == 1 then
			self:notify_tips(selfId, "#{XQC_20080509_08}" )
		else
			self:notify_tips(selfId, "#{JCDK_80905_08}" )
		end
		return
	elseif ret == -4 then
		if type == 1 then
			self:notify_tips(selfId, "#{XQC_20080509_07}" )
		else
			self:notify_tips(selfId, "#{JCDK_80905_07}" )
		end
		return
	elseif ret == 0 then --zchw
		self:notify_tips(selfId, selfId, "Trừ tiền thất bại!" );
		return
	end

	--打孔执行
	-- ret	= self:AddBagItemSlotFour(selfId, idBagPos )
	-- if ret == -1 then
		-- self:notify_tips(selfId, "装备打孔失败" )
	-- elseif ret == -2 then
		-- self:notify_tips(selfId, "严重错误" )
	-- elseif ret == -3 then
		-- self:notify_tips(selfId, "#{XQC_20080509_06}" )
	-- elseif ret == -4 then
		-- self:notify_tips(selfId, "#{XQC_20080509_04}" )
	-- elseif ret == 1 then
        -- self:notify_tips(selfId, "装备打孔成功" )
		-- --if isequipbind == 0 and isstuffbind == 1 and type == 2 then
			-- self:LuaFnItemBind(selfId,idBagPos)
		-- --end

        -- --成功公告
        -- local transfer = self:GetBagItemTransfer(selfId,idBagPos)
        -- local str = ""
		-- local name = self:GetName(selfId)
		-- name = gbk.fromutf8(name)
        -- if type == 1 then
			-- str = string.format( "#{_INFOUSR%s}#{AQ_11}#{_INFOMSG%s}#{AQ_32}#{_INFOMSG%s}#{AQ_12}", name, szCailiao,transfer )
		    -- --self:CostMoney(selfId, 30000000)
        -- else
            -- str = string.format( "#{_INFOUSR%s}#{AQ_11}#{_INFOMSG%s}#{AQ_31}#{_INFOMSG%s}#{AQ_12}", name, szCailiao,transfer )
        -- end
        -- self:BroadMsgByChatPipe(selfId, str, 4 )

		-- --增加特效
        -- self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 49, 0);
	-- end
end

function stiletto:notify_tip(selfId, msg)
	self:BeginEvent()
        self:AddText(msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return stiletto