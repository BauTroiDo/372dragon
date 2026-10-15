--大驿站系统
--逍遥子

x990010_g_ScriptId = 990110

-- 称号配置表：{ 称号名称, 需要碎片数量, 称号ID, 兑换选项ID }
x990010_TitleConfig = {
    { name = "Hào Tình Vạn Trượng Tẩu Thiên Nhai",   times = 10,  titleId = 1407, cmdId = 16011 },
    { name = "Kiếm Chỉ Thương Sơn Đi Bốn Phương",   times = 20,  titleId = 1346, cmdId = 16012 },
    { name = "Kiếm Chém Hung Sát Trấn Ngũ Diệu",   times = 30,  titleId = 1347, cmdId = 16013 },
    { name = "Kiếm Diệt Yêu Tà Quét Lục Hợp",   times = 40,  titleId = 1348, cmdId = 16014 },
    { name = "Chẳng Nỡ Sớm Chiều·Giai Nhân Trong Mộng", times = 50,  titleId = 1367, cmdId = 16015 },
    { name = "Một Thoáng Vạn Năm·Anh Hùng Cái Thế", times = 80,  titleId = 1368, cmdId = 16016 },
    { name = "Sao Trăng Giao Huy·Ngưỡng Mộ Nghìn Thu", times = 100, titleId = 1284, cmdId = 16017 },
    { name = "Ngân Hà Gửi Mộng·Tương Tư Vạn Cổ", times = 140, titleId = 1285, cmdId = 16018 },
    { name = "Bá chủ thiên hạ·Thần quân cửu tiêu", times = 180, titleId = 1240, cmdId = 16019 },
}
x990010_TITLE_COUNT = 9 -- 称号总档数
x990010_TOTAL_FRAGMENTS = 650 -- 总共需要650个碎片兑换完

-- 传送配置表：{ cmdId, sceneId, x, y }
x990010_TransferConfig = {
	{ cmdId = 12334, sceneId = 434,   x = 98,  y = 35  }, -- 昆仑福地A点
	{ cmdId = 12335, sceneId = 434,   x = 24,  y = 24  }, -- 昆仑福地B点
	{ cmdId = 12336, sceneId = 17012, x = 167, y = 35 }, -- 跨区地宫A点
	{ cmdId = 12337, sceneId = 17012, x = 100, y = 100 }, -- 跨区地宫B点
	{ cmdId = 12338, sceneId = 432,   x = 90, y = 86 }, -- 汗血岭A点
	{ cmdId = 12339, sceneId = 432,   x = 100, y = 100 }, -- 汗血岭B点
	{ cmdId = 12340, sceneId = 202,   x = 27, y = 70 }, -- 圣火宫A点
	{ cmdId = 12341, sceneId = 202,   x = 100, y = 100 }, -- 圣火宫B点
	{ cmdId = 12342, sceneId = 427,   x = 34, y = 25 }, -- 塔克拉玛干A点
	{ cmdId = 12343, sceneId = 427,   x = 100, y = 100 }, -- 塔克拉玛干B点
}


--**********************************
--事件交互入口
--**********************************
function x990010_OnDefaultEvent( sceneId, selfId,targetId )
	
	local NPCName = GetName(sceneId,targetId)
	BeginEvent( sceneId )

        if NPCName == "称号兑换" then
			AddText( sceneId,"    Đại đạo thi hành, thiên hạ vi công. Tuyển hiền cử năng, giảng tín tu mục. Danh trác tuyệt không nằm trong chiêu thức võ nghệ, không ở chân trời góc bể, mà ở giữa lòng người. Chỉ ai được vạn người tin, mới là người lên đỉnh.")
			-- 显示当前修炼等级和属性加成
			local xiulianLv = GetMissionData(sceneId, selfId, MD_XIULIANLEVLE)
			local attrIA = GetMissionData(sceneId, selfId, MD_ATTRREFIX_IA)
			local attrFA = GetMissionData(sceneId, selfId, MD_ATTRREFIX_FA)
			local attrLA = GetMissionData(sceneId, selfId, MD_ATTRREFIX_LA)
			local attrPOA = GetMissionData(sceneId, selfId, MD_ATTRREFIX_POA)
			local attrHP = GetMissionData(sceneId, selfId, MD_ATTRREFIX_MAXHP)
			--AddText( sceneId, "#Y[修炼信息]#r#W当前等级: #G"..xiulianLv.."#W/100  每次消耗2亿经验")
			--AddText( sceneId, "#W属性加成: #r冰攻#c00FFFF+"..attrIA.."#W 火攻#cFF6600+"..attrFA.."#W 玄攻#c9900FF+"..attrLA.."#W 毒攻#c00FF00+"..attrPOA.."#r#W血量#cFF0000+"..attrHP)
			-- AddNumText( sceneId, x990010_g_ScriptId, "CDK激活", 6, 34553 )
			--AddNumText( sceneId, x990010_g_ScriptId, "领取月卡每日礼包", 6, 15118 )
			--AddNumText( sceneId, x990010_g_ScriptId, "兑换属性称号", 6, 15108 )
			--AddNumText( sceneId, x990010_g_ScriptId, "经验进阶", 6, 15120 )
			--AddNumText( sceneId, x990010_g_ScriptId, "经验修炼", 6, 15109 )
        		
		elseif NPCName == "宁采臣" then
			AddText( sceneId,"     Tương truyền Côn Lôn Phúc Địa linh khí nồng đậm, hoa điểu trùng ngư đều có linh tính, là thánh địa tu luyện người tu tiên hằng mơ. Đó cũng là nơi ở của Tây Vương Mẫu, được xem là \"thiên trụ\" nối trời đất.")
			AddText( sceneId,"     Mỗi lần vào Côn Lôn Phúc Địa trừ 1 Côn Lôn Lệnh, chỉ vào được 13-14h, 22-23h hằng ngày")
			AddNumText( sceneId, x990010_g_ScriptId, "Tới điểm A Côn Lôn Phúc Địa", 6, 12334 )
			AddNumText( sceneId, x990010_g_ScriptId, "Tới điểm B Côn Lôn Phúc Địa", 6, 12335 )
			AddNumText( sceneId, x990010_g_ScriptId, "Tới điểm A địa cung liên khu", 6, 12336 )	--sceneid =17012
			AddNumText( sceneId, x990010_g_ScriptId, "Tới điểm B địa cung liên khu", 6, 12337 )	--sceneid =17012
			AddNumText( sceneId, x990010_g_ScriptId, "Tới điểm A Hãn Huyết Lĩnh", 6, 12338 )	--sceneid =432
			AddNumText( sceneId, x990010_g_ScriptId, "Tới điểm B Hãn Huyết Lĩnh", 6, 12339 )	--sceneid =432
			AddNumText( sceneId, x990010_g_ScriptId, "Tới điểm A Thánh Hỏa Cung", 6, 12340 )	--sceneid =202
			AddNumText( sceneId, x990010_g_ScriptId, "Tới điểm B Thánh Hỏa Cung", 6, 12341 )	--sceneid =202
			AddNumText( sceneId, x990010_g_ScriptId, "Tới điểm A Taklamakan", 6, 12342 )--sceneid =427
			AddNumText( sceneId, x990010_g_ScriptId, "Tới điểm B Taklamakan", 6, 12343 )--sceneid =427
		elseif NPCName == "萧峰" then
			AddText( sceneId,"     Nếu ngươi có kim chuyên, có thể tới chỗ ta quyên góp nhận thưởng lớn")
			AddText( sceneId,"     Quyên nhẫn mỗi ngày lúc 23:00, 23:00-23:59 là giờ nhận thưởng.")
			AddNumText( sceneId, x990010_g_ScriptId, "Mở bảng quyên góp", 6, 23444 )
		elseif NPCName == "夏听澜" then
			AddText( sceneId,"     Mỗi ngày 19:00-19:30 là giờ treo máy. Mỗi phút nhận 5000 nguyên bảo và 50000 kinh nghiệm")
			AddNumText( sceneId, x990010_g_ScriptId, "Vào bản đồ treo máy", 6, 23445 )
        end			
	EndEvent( sceneId )
	DispatchEventList( sceneId, selfId, targetId )
end

--**********************************
--事件列表选中一项
--**********************************
function x990010_OnEventRequest( sceneId, selfId, targetId, eventId )
	local	arg	= GetNumText()
	local chenghaolevle = GetMissionData(sceneId, selfId, MD_chenghaolevel)
    local nTime = GetHour() * 100 + GetMinute()
	--=========================================================================
	-- 经验修炼功能
	--=========================================================================
	if arg == 15109 then
		local nExp = GetExp(sceneId,selfId)
		-- 经验值超过21.47亿会溢出为负数，负数说明经验足够
		if nExp >= 0 and nExp < 200000000 then
			x990010_MsgBox(sceneId,selfId,targetId,"Kinh nghiệm không đủ 200 triệu, đổi thất bại.")
			return
		end
		local curLevel = GetMissionData(sceneId, selfId, MD_XIULIANLEVLE)
		if curLevel >= 100 then
			x990010_MsgBox(sceneId,selfId,targetId,"Tu luyện tối đa tới cấp 100")
			return
		end
		
		AddExp(sceneId, selfId, -200000000)
		
		-- 等级+1
		local newLevel = curLevel + 1
		SetMissionData(sceneId, selfId, MD_XIULIANLEVLE, newLevel)
		
		-- 属性根据等级计算固定值（不累加）
		SetMissionData(sceneId, selfId, MD_ATTRREFIX_IA,    newLevel * 10)    -- 冰攻
		SetMissionData(sceneId, selfId, MD_ATTRREFIX_FA,    newLevel * 10)    -- 火攻
		SetMissionData(sceneId, selfId, MD_ATTRREFIX_LA,    newLevel * 10)    -- 玄攻
		SetMissionData(sceneId, selfId, MD_ATTRREFIX_POA,   newLevel * 10)    -- 毒攻
		SetMissionData(sceneId, selfId, MD_ATTRREFIX_MAXHP, newLevel * 1000)  -- 血上限
		
		x990010_MsgBox(sceneId, selfId, targetId, "Tu luyện thành công! Tốn 200 triệu kinh nghiệm")
		LuaFnRefreshEngine(sceneId, selfId)
		-- 武侠风格系统广播
		local str = format("#Y[Giang hồ đồn]#WHiệp sĩ#G#{_INFOUSR%s}#Wbế quan tu luyện, thổ nạp linh khí trời đất, công lực tinh tiến tới#Rtrùng thứ %d#W, võ học lên thêm một tầng!", GetName(sceneId, selfId), newLevel)
		--BroadMsgByChatPipe(sceneId, selfId, str, 4)
		return
	end
	
	--=========================================================================
	-- 经验进阶功能 - 显示信息
	--=========================================================================
	if arg == 15120 then
		local curLevel = GetMissionData(sceneId, selfId, MD_JingYanLevel)
		if curLevel >= 100 then
			x990010_MsgBox(sceneId, selfId, targetId, "Tiến giai kinh nghiệm đã tối đa cấp 100!")
			return
		end
		local curHP = 0
		local curAttr = 0
		if curLevel > 0 then
			curHP = 10000 + curLevel * 1000
			curAttr = 100 + curLevel * 10
		end
		local nextHP = 10000 + (curLevel + 1) * 1000
		local nextAttr = 100 + (curLevel + 1) * 10
		
		BeginEvent(sceneId)
			AddText(sceneId, "#Y[Tiến giai kinh nghiệm]#W Mỗi lần tốn 500 triệu kinh nghiệm lên 1 cấp, tối đa 100")
			AddText(sceneId, "#WCấp hiện tại: #G"..curLevel.."#W/100")
			AddText(sceneId, "#WCộng hiện tại: máu#cFF0000+"..curHP.." #WBăng công#c00FFFF+"..curAttr.." #WHỏa công#cFF6600+"..curAttr.." #WHuyền công#c9900FF+"..curAttr.." #WĐộc công#c00FF00+"..curAttr)
			AddText(sceneId, "#WCấp sau: máu#cFF0000+"..nextHP.." #WBăng công#c00FFFF+"..nextAttr.." #WHỏa công#cFF6600+"..nextAttr.." #WHuyền công#c9900FF+"..nextAttr.." #WĐộc công#c00FF00+"..nextAttr)
			AddNumText(sceneId, x990010_g_ScriptId, "#RXác nhận tiến giai (tốn 500 triệu kinh nghiệm)", 6, 15121)
		EndEvent(sceneId)
		DispatchEventList(sceneId, selfId, targetId)
		return
	end
	
	--=========================================================================
	-- 经验进阶功能 - 执行升级
	--=========================================================================
	if arg == 15121 then
		local curLevel = GetMissionData(sceneId, selfId, MD_JingYanLevel)
		if curLevel >= 100 then
			x990010_MsgBox(sceneId, selfId, targetId, "Tiến giai kinh nghiệm đã tối đa cấp 100!")
			return
		end
		local nExp = GetExp(sceneId, selfId)
		if nExp >= 0 and nExp < 500000000 then
			x990010_MsgBox(sceneId, selfId, targetId, "Kinh nghiệm không đủ 500 triệu, tiến giai thất bại.")
			return
		end
		
		AddExp(sceneId, selfId, -500000000)
		local newLevel = curLevel + 1
		SetMissionData(sceneId, selfId, MD_JingYanLevel, newLevel)
		
		CallScriptFunction(887802, "x887802_Obj_Human_Effect", sceneId, selfId)
		LuaFnRefreshEngine(sceneId, selfId)
		
		local newHP = 10000 + newLevel * 1000
		local newAttr = 100 + newLevel * 10
		x990010_MsgBox(sceneId, selfId, targetId, "Tiến giai thành công! Cấp:"..newLevel.."/100 máu+"..newHP.." Tứ thuộc tính+"..newAttr)
		return
	end
	
	--=========================================================================
	-- 泡点传送功能
	--=========================================================================
	if arg == 23445 then
		if (nTime >= 1900 and nTime <= 1930)  then
			-- 泡点地图坐标：sceneId=16902, x=100, y=100
			CallScriptFunction(400900, "TransferFunc", sceneId, selfId, 16902, 100, 100, 10)
		else	
			x990010_MsgBox( sceneId, selfId,targetId, "Ngoài giờ hoạt động, không vào được")
		end
		return
	end
	
	--=========================================================================
	-- 捐献榜功能
	--=========================================================================
	if arg == 23444 then
		CallScriptFunction( 927810, "OpenJuanZeng", sceneId,selfId)
		return
	end
	--=========================================================================
	-- 领取月卡每日礼包
	--=========================================================================
	if arg == 15118 then
		local currentDay = GetTime2Day()
		local lastRechargeDayZZ = GetMissionData(sceneId, selfId, MD_YUEKALQBJ) 
		if GetMissionFlag(sceneId, selfId, MF_Xueshengzhuang_flag) ~= 1 then
			x990010_MsgBox( sceneId, selfId,targetId, "Ngươi chưa mở lễ bao hằng ngày")
			return
		end
		if lastRechargeDayZZ ~= currentDay then
			BeginAddItem(sceneId)
			AddBindItem( sceneId, 38002397, 100 )	--高级宝石合成符
			AddBindItem( sceneId, 38000571, 250 )	--高级宝石合成符
			AddBindItem( sceneId, 30900016, 10 )	--高级宝石合成符
			AddBindItem( sceneId, 38002499, 100 )	--高级宝石合成符
			AddBindItem( sceneId, 38003165, 10 )	--高级宝石合成符
			AddBindItem( sceneId, 20310216, 5 )	--魔尊魂武
			AddBindItem( sceneId, 20310208, 10 )	--称号碎片
			EndAddItem(sceneId,selfId) 		
			AddItemListToHuman(sceneId,selfId)		
			SetMissionData(sceneId, selfId, MD_YUEKALQBJ, currentDay)
		else
			x990010_MsgBox( sceneId, selfId,targetId, "Hôm nay ngươi đã nhận rồi")
		end
		return
	end	
	--=========================================================================
	-- 传送功能（配置表驱动）
	--=========================================================================
	for _, cfg in x990010_TransferConfig do
		if arg == cfg.cmdId then
			-- if LuaFnGetAvailableItemCount(sceneId, selfId, 20310220) < 1 then
				-- x990010_MsgBox(sceneId, selfId, targetId, "需要[昆仑令]1个")
				-- return
			-- end
			-- if LuaFnDelAvailableItem(sceneId, selfId, 20310220, 1) ~= 1 then
				-- x990010_MsgBox(sceneId, selfId, targetId, "[昆仑令]扣取失败，请查看是否加锁了")
				-- return
			-- end
			CallScriptFunction(400900, "TransferFunc", sceneId, selfId, cfg.sceneId, cfg.x, cfg.y, 10)
			return
		end
	end
	--=========================================================================
	-- 兑换属性称号菜单
	--=========================================================================
	if arg == 15108 then
		local itemCount1 = LuaFnGetAvailableItemCount(sceneId, selfId, 20310208)
		local itemCount2 = LuaFnGetAvailableItemCount(sceneId, selfId, 20310209)
		local totalFragments = itemCount1 + itemCount2
		
		BeginEvent(sceneId)
			AddText(sceneId, "    #HDùng mảnh danh hiệu đổi danh hiệu thuộc tính, tổng cần 650 mảnh đổi hết")
			AddText(sceneId, "    #HMảnh đang có:#G" .. totalFragments .. "cái#H (khóa:"..itemCount1.."cái, không khóa:"..itemCount2.."cái)")

			-- 只显示下一个可兑换的称号（必须按顺序）
			if chenghaolevle < x990010_TITLE_COUNT then
				local nextLevel = chenghaolevle + 1
				local cfg = x990010_TitleConfig[nextLevel]
				AddNumText(sceneId, x990010_g_ScriptId, cfg.times.."cái đổi:"..cfg.name, 6, cfg.cmdId)
			end

			-- 顶级提示
			if chenghaolevle >= x990010_TITLE_COUNT then
				AddText(sceneId, "    Danh hiệu của ngươi đã tối đa!")
			end

			-- 友好提示
			if chenghaolevle < x990010_TITLE_COUNT then
				local nextLevel = chenghaolevle + 1
				if nextLevel <= x990010_TITLE_COUNT then
					local nextCfg = x990010_TitleConfig[nextLevel]
					local needMore = nextCfg.times - totalFragments
					if needMore > 0 then
						AddText(sceneId, "    #Pcòn cần #G" .. needMore .. " mảnh#P để mở danh hiệu giai đoạn sau #G[" .. nextCfg.name .. "]")
					else
						AddText(sceneId, "    #PMảnh đủ, đổi được danh hiệu giai đoạn sau #G[" .. nextCfg.name .. "]")
					end
				end
			end

		EndEvent(sceneId)
		DispatchEventList(sceneId, selfId, targetId)
		return
	end

	--=========================================================================
	-- 称号兑换处理 (通用逻辑)
	--=========================================================================
	-- 检查是否是称号兑换指令
	local i = 1
	for i = 1, x990010_TITLE_COUNT do
		local cfg = x990010_TitleConfig[i]
		if arg == cfg.cmdId then
			-- 检查是否按顺序兑换
			if chenghaolevle >= i then
				x990010_MsgBox( sceneId, selfId,targetId, "Ngươi đã đổi danh hiệu này rồi" )
				return
			end
			if chenghaolevle + 1 ~= i then
				x990010_MsgBox( sceneId, selfId,targetId, "Xin đổi danh hiệu mốc trước đã" )
				return
			end
			
			-- 检查碎片数量是否足够
			local itemCount1 = LuaFnGetAvailableItemCount(sceneId, selfId, 20310208)
			local itemCount2 = LuaFnGetAvailableItemCount(sceneId, selfId, 20310209)
			local totalFragments = itemCount1 + itemCount2
			
			if totalFragments < cfg.times then
				x990010_MsgBox( sceneId, selfId,targetId, "Không đủ mảnh danh hiệu, cần"..cfg.times.."cái, hiện chỉ có"..totalFragments.."cái" )
				return
			end
			
			-- 优先扣除20310208，不足再扣除20310209
			local needDel = cfg.times
			local del1 = 0
			local del2 = 0
			if itemCount1 >= needDel then
				del1 = needDel
			else
				del1 = itemCount1
				del2 = needDel - itemCount1
			end
			
			if del1 > 0 then
				if LuaFnDelAvailableItem(sceneId, selfId, 20310208, del1) ~= 1 then
					x990010_MsgBox( sceneId, selfId,targetId, "Khấu trừ Nguyên liệu thất bại" )
					return
				end
			end
			if del2 > 0 then
				if LuaFnDelAvailableItem(sceneId, selfId, 20310209, del2) ~= 1 then
					x990010_MsgBox( sceneId, selfId,targetId, "Khấu trừ Nguyên liệu thất bại" )
					return
				end
			end
			
			-- 发放称号
			LuaFnAwardCharTitle(sceneId,selfId, cfg.titleId)
			LuaFnSetCurTitleById(sceneId,selfId, cfg.titleId)
			LuaFnDispatchAllTitle(sceneId,selfId, cfg.titleId)	
			SetMissionData(sceneId, selfId, MD_chenghaolevel, i)
			
			-- 系统播报
			local str = format("#PGiang hồ đồn: hiệp sĩ".."#{_INFOUSR%s} dùng %d mảnh danh hiệu, đổi danh hiệu cực phẩm thành công, danh chấn tám phương!", GetName(sceneId, selfId), cfg.times)
			BroadMsgByChatPipe(sceneId, selfId, str, 4)
			LuaFnSendSpecificImpactToUnit(sceneId, selfId, selfId, selfId, 148, 0)

			return
		end
	end

	--=========================================================================
	-- CDK激活
	--=========================================================================
	if arg == 34553 then
		BeginUICommand(sceneId)
        UICommand_AddInt(sceneId, targetId)
		UICommand_AddString(sceneId, "CDK")
        EndUICommand(sceneId)
        DispatchUICommand(sceneId, selfId, 20170431)	
		return
	end		

end

--**********************************
--对话窗口信息提示
--**********************************
function x990010_MsgBox( sceneId, selfId, targetId, msg )
	BeginEvent( sceneId )
		AddText( sceneId, msg )
	EndEvent( sceneId )
	DispatchEventList( sceneId, selfId, targetId )
end
