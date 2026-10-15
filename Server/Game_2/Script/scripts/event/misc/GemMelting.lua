--宝石熔炼
--普通
local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local human_item_logic = require "human_item_logic"
local configenginer = require "configenginer":getinstance()
local script_base = require "script_base"
local GemMelting = class("GemMelting", script_base)
function GemMelting:OnGemMelting(selfId, GemItemIndex, MatItemPos)
    local space_count = self:LuaFnGetMaterialBagSpace(selfId)
    if space_count <= 0 then
        self:notify_tips(selfId, "Ô nguyên liệu thiếu chỗ, không điêu trác được, xin chừa ít nhất một ô")
        return
    end
    local obj = self.scene:get_obj_by_id(selfId)
    local need = 3
    local gem_melting = configenginer:get_config("gem_melting")
    local this_gem_melting = gem_melting[GemItemIndex]
    if this_gem_melting == nil then
        obj:notify_tips("Bảo thạch này không thể dung luyện, dung luyện Bảo thạch thất bại.")
        return
    end
    local MatItem = self:GetBagItem(selfId, MatItemPos)
    if MatItem == nil or MatItem:get_index() ~= this_gem_melting.need_item and (MatItem:get_index() ~= 30900057)  then
        obj:notify_tips("Vật phẩm luyện yêu cầu sai, Luyện Bảo thạch thất bại, hãy kiểm tra xem Cấp độ Phù Luyện có chính xác không.")
        return
    end
    local NeedItemInfo = self:GetBagItemTransfer(selfId, MatItemPos)
    local bag_indexs = human_item_logic:get_items_in_need(obj, GemItemIndex, need)
    if not bag_indexs then
        obj:notify_tip("Số lượng Bảo thạch không đủ 3 hạt, Luyện Bảo thạch thất bại.")
        return
    end
    local product_id = this_gem_melting.product_id
    local fisrt_item_index = bag_indexs[1].bag_index
    local item = obj:get_prop_bag_container():get_item(fisrt_item_index)
	local isbind = item:is_bind()
        for _, bi in pairs(bag_indexs) do
            local logparam = {}
            local ret = human_item_logic:dec_item_lay_count(logparam, obj, bi.bag_index, bi.count)
			if not ret then
				return
			end
        end
        local logparam = {}
        local del = human_item_logic:dec_item_lay_count(logparam, obj, MatItemPos, 1)
		if not del then
			return
		end
	
    local param = {}
    local _, bag_index = human_item_logic:create_multi_item_to_bag(param, obj, product_id, 1, isbind, 0)
    if bag_index ~= define.INVAILD_ID then
        self:notify_tips(selfId, "3 viên(#{_ITEM"..GemItemIndex.."})đã được dung luyện thành công thành 1 viên(#{_ITEM"..product_id.."}）")
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 49, 0)
        --公告....
	    if self:GetItemQuality(product_id) >= 5 then
		    local MeltingNPCTbl =
		    {
			    [0]   = "Lạc Dương(178,185)Bành Hoài Ngọc",
			    [420] = "Thúc Hà Cổ Trấn (134,84) Kính Khảm Thật",
                [186] = "Lâu Lan (74,161) Khắc Lý Mộc",
		    }
			local NPCInfo = MeltingNPCTbl[self:GetSceneID()]
			if NPCInfo ==nil then
				NPCInfo = MeltingNPCTbl[0]
			end
			local PlayerName = self:GetName(selfId)
			local ProductItemInfo = self:GetBagItemTransfer(selfId, bag_index)
			local strText = string.format("#{JKBS_081021_016}#{_INFOUSR%s}#{JKBS_081021_017}#{_ITEM%s}#{JKBS_081021_018}#{_INFOMSG%s}#{JKBS_081021_019}%s#{JKBS_081021_020}#{_INFOMSG%s}#{JKBS_081021_021}",
				gbk.fromutf8(PlayerName), tostring(GemItemIndex), NeedItemInfo, gbk.fromutf8(NPCInfo), ProductItemInfo)
			self:BroadMsgByChatPipe(selfId, strText, 4)
		end
    else
        obj:send_operate_result_msg(define.OPERATE_RESULT.OR_BAG_OUT_OF_SPACE)
    end
end

return GemMelting