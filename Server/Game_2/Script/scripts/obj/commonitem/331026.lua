local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local common_item = class("common_item", script_base)
common_item.g_itemList = {}
common_item.g_itemList[30509029] = {effect=2, time=60,
	msg1="#W#{_INFOUSR%s}#H thấy hạn hán kéo dài, ruộng đồng nứt nẻ, cây cối khô héo, trong lòng không đành lòng, bèn lấy ra một %s#H, miệng lẩm bẩm, nhất thời chỉ thấy bầu trời mây đen giăng kín, gió mưa nổi lên.",
	msg2="#W#{_INFOUSR%s}#H thấy #G%s#H hạn hán kéo dài, ruộng đồng nứt nẻ, cây cối khô héo, trong lòng không đành lòng, bèn lấy ra một %s#H, miệng lẩm bẩm, nhất thời chỉ thấy bầu trời mây đen giăng kín, gió mưa nổi lên."}
common_item.g_itemList[30509030] = {effect=3, time=60,
	msg1="#W#{_INFOUSR%s}#H đang trước mặt người yêu thề thốt, nếu phụ bạc đối phương sau này ắt bị trời đánh. Không ngờ vừa dứt lời, quả nhiên sấm sét vang dội, chớp giật liên hồi, nhất thời sợ đến mặt mày xám xịt, sau mới phát hiện là do %s#H trên người gây ra, bấy giờ mới thở phào nhẹ nhõm.",
	msg2="#W#{_INFOUSR%s}#H đang trước mặt người yêu thề thốt, nếu phụ bạc đối phương sau này ắt bị trời đánh. Không ngờ vừa dứt lời, #G%s#H quả nhiên sấm sét vang dội, chớp giật liên hồi, nhất thời sợ đến mặt mày xám xịt, sau mới phát hiện là do %s#H trên người gây ra, bấy giờ mới thở phào nhẹ nhõm."}
common_item.g_itemList[30509031] = {effect=4, time=60,
	msg1="#W#{_INFOUSR%s}#H bị mấy đứa nhóc nghịch ngợm muốn chơi đánh trận tuyết quấy rầy đến hết cách, đành phải lấy ra %s#H trân tàng bấy lâu, lớn tiếng kêu \"Oan!\", bầu trời lập tức đổ xuống tuyết lớn như lông ngỗng, đám nhóc tì mới reo hò chạy đi.",
	msg2="#W#{_INFOUSR%s}#H tại #G%s#H bị mấy đứa nhóc nghịch ngợm muốn chơi đánh trận tuyết quấy rầy đến hết cách, đành phải lấy ra %s#H trân tàng bấy lâu, lớn tiếng kêu \"Oan!\", bầu trời lập tức đổ xuống tuyết lớn như lông ngỗng, đám nhóc tì mới reo hò chạy đi."}
common_item.g_itemList[30509032] = {effect=5, time=60,
	msg1="#W#{_INFOUSR%s}#H vì muốn tăng thêm không khí lãng mạn dưới ánh trăng bên người yêu, đành đau lòng sử dụng %s#H khó có được.",
	msg2="#W#{_INFOUSR%s}#H vì muốn tăng thêm không khí lãng mạn dưới ánh trăng tại #G%s#H bên người yêu, đành đau lòng sử dụng %s#H khó có được."}
common_item.g_itemList[30509033] = {effect=6, time=60,
	msg1="#W#{_INFOUSR%s}#H đang muốn cùng cao thủ võ lâm nào đó tỷ võ, trong lòng chợt động, dùng trước một cái %s#H, chỉ thấy lá trúc bay đầy trời, lập tức trở nên khí thế bức người.",
	msg2="#W#{_INFOUSR%s}#H đang định cùng cao thủ võ lâm nào đó #G%s#H tỷ võ, trong lòng chợt động, bèn dùng trước một %s#H, chỉ thấy trúc diệp đầy trời bay múa, lập tức trở nên khí thế bức người."}
common_item.g_itemList[30509034] = {effect=7, time=60,
	msg1="#W#{_INFOUSR%s}#H khi tản bộ, bỗng nhiên hứng thơ dâng trào, tùy tay dùng một %s#H, ngắm nhìn lá phong đầy trời bay múa, bèn ngâm nga ra câu hay \"Sương diệp hồng vu nhị nguyệt hoa\", khiến người đi đường phải nhìn bằng con mắt khác.",
	msg2="#W#{_INFOUSR%s}#H khi tản bộ ở #G%s#H, bỗng nhiên hứng thơ dâng trào, tùy tay dùng một %s#H, ngắm nhìn lá phong đầy trời bay múa, bèn ngâm nga ra câu hay \"Sương diệp hồng vu nhị nguyệt hoa\", khiến người đi đường phải nhìn bằng con mắt khác."}
common_item.g_itemList[30509035] = {effect=8, time=60,
	msg1="#W#{_INFOUSR%s}#H luôn bị người chê cười mặt còn non, trong lòng không phục, giận quá hóa liều dùng một %s#H, từ trong Bụi cát mịt mù bước ra, hài lòng phát hiện bản thân đã từng trải hơn rất nhiều.",
	msg2="#W#{_INFOUSR%s}#H luôn bị người chê cười mặt còn non, trong lòng không phục, giận quá hóa liều dùng một %s#H ở #G%s#H, từ trong Bụi cát mịt mù bước ra, hài lòng phát hiện bản thân đã từng trải hơn rất nhiều."}
common_item.g_itemList[30509036] = {effect=9, time=60,
	msg1="#W#{_INFOUSR%s}#H nằm mộng cũng muốn phát tài, bèn sử dụng một %s#H, lập tức Nguyên bảo từ trên trời giáng xuống như mưa, mọi người hoan hô nhảy nhót.",
	msg2="#W#{_INFOUSR%s}#H nằm mộng cũng muốn phát tài, bèn tại #G%s#H sử dụng một %s#H, lập tức Nguyên bảo từ trên trời giáng xuống như mưa, mọi người hoan hô nhảy nhót."}
common_item.g_itemList[30509052] = {effect=10, time=60,
	msg1="#HTháng năm, là một trận mưa lớn sau tiếng sấm rền vang, ngày mà chim nhạn bay về phương nam vượt núi băng sông trở về nhà; trong mùa lãng mạn này#W#{_INFOUSR%s}#H đã sử dụng một #W%s#H, để ca ngợi cảnh tượng tốt đẹp lúa mì mùa đông trổ bông, nông dân mồ hôi nhễ nhại vác cuốc, cần cù cày cấy.",
	msg2="#HLao động thật diệu kỳ, lao động thật vĩ đại. Những người lao động dùng đôi bàn tay cần cù và trí tuệ, dệt nên thế giới muôn màu muôn vẻ này, tạo nên nền văn minh của nhân loại.#W#{_INFOUSR%s}#HTrong ngày đặc biệt này, tại #G%s#H đã sử dụng một #W%s#H để hướng tới những người lao động trên toàn thế giới bày tỏ lòng kính trọng!"}
common_item.g_itemList[30509066] = {effect=20, time=60,
	msg1="#HThất Tịch sắp đến, #W#{_INFOUSR%s}#H đêm qua mộng thấy Ngưu Lang Chức Nữ gặp nhau trên cầu Ô Thước, ngưỡng mộ khôn so, bèn sử dụng một #W%s#H, để hướng tới tất cả những người độc thân phát đi tín hiệu của tình yêu!",
	msg2="#HThất Tịch, cầu Ô Thước, Ngân Hà, Ngưu Lang Chức Nữ......#W#{_INFOUSR%s}#HTrong ngày đặc biệt này, bỗng dưng tâm có cảm khái, hướng về bầu trời #G%s#H ném đi một nắm #W%s#H, lập tức hoa bay tán loạn."}
common_item.g_itemList[30509071] = {effect=21, time=60,
	msg1="#{AOYYH_8804_01}#W#{_INFOUSR%s}#H vô cùng nhiệt tình #{AOYYH_8804_03}%s#{AOYYH_8804_04}",
	msg2="#{AOYYH_8804_01}#W#{_INFOUSR%s}#H vô cùng nhiệt tình tại #G%s#{AOYYH_8804_03}%s#{AOYYH_8804_04}"}
common_item.g_itemList[30509083] = {effect=22, time=60,
	msg1="#HĐến ngày sinh nhật bạn chí cốt, #W#{_INFOUSR%s}#H cũng vui mừng khôn xiết, bèn dùng một cái #W%s#H, để bày tỏ lời chúc sinh nhật chân thành nhất đến bạn bè!",
	msg2="#W#{_INFOUSR%s}#H nhân dịp sinh nhật bạn chí cốt, đã đốt một cái #W%s#H ở #G%s#H, và chúc rằng: Nguyện mọi niềm vui, mọi hạnh phúc, mọi ấm áp, mọi may mắn đều vây quanh bên bạn, sinh nhật vui vẻ!"}

function common_item:IsSkillLikeScript()
    return 1
end

function common_item:CancelImpacts()
    return 0
end

function common_item:OnConditionCheck(selfId)
	--校验使用的物品
	if not self:LuaFnVerifyUsedItem(selfId) then
		return 0
	end

	local itemTblIndex = self:LuaFnGetItemIndexOfUsedItem(selfId );
	local curItem = self.g_itemList[itemTblIndex];
	if not curItem then
		self:notify_tips(selfId, "Đạo cụ chưa mở, không thể sử dụng.");
		return 0;
	end
	local curWeather = self:LuaFnGetSceneWeather();
	if not curWeather or curWeather ~= -1 then
		self:notify_tips(selfId, "Trong điều kiện thời tiết đặc biệt không thể sử dụng vật phẩm này.");
		return 0;
	end

	return 1; --不需要任何条件，并且始终返回1。
end 

function common_item:OnDeplete(selfId)
	local itemTblIndex = self:LuaFnGetItemIndexOfUsedItem( selfId );
	local curItem = self.g_itemList[itemTblIndex];
	if not curItem then
		self:notify_tips(selfId, "Đạo cụ chưa mở, không thể sử dụng.");
		return 0;
	end
	local itemBagIndex = self:LuaFnGetBagIndexOfUsedItem(selfId);
	local szTransferItem = self:GetBagItemTransfer(selfId, itemBagIndex);
	local selfName = self:GetName(selfId);
	if(self:LuaFnDepletingUsedItem(selfId)) then
		if szTransferItem and selfName then
			local sceneType = self:LuaFnGetSceneType()
			local strMsg
			selfName = gbk.fromutf8(selfName)
			if sceneType and sceneType == 0 then
				local sceneName = self:GetSceneName()
				sceneName = gbk.fromutf8(sceneName)
				local msg2 = gbk.fromutf8(curItem.msg2)
				strMsg = string.format(msg2, selfName, sceneName, "#{_INFOMSG"..szTransferItem.."}")
			else
				local msg1 = gbk.fromutf8(curItem.msg1)
				strMsg = string.format(msg1, selfName, "#{_INFOMSG"..szTransferItem.."}")
			end
			self:BroadMsgByChatPipe(selfId, strMsg, 4)
		end
		return 1
	end
	return 0
end

function common_item:OnActivateOnce(selfId)
	local itemTblIndex = self:LuaFnGetItemIndexOfUsedItem(selfId)
	local curItem = self.g_itemList[itemTblIndex];
	if not curItem then
		self:notify_tips(selfId, "Đạo cụ chưa mở, không thể sử dụng.");
		return 0;
	end
	self:LuaFnSetSceneWeather(curItem.effect, curItem.time * 1000 );
	return 1;
end

return common_item