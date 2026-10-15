local class = require "class"
local ScriptGlobal = require "scripts.ScriptGlobal"
local define = require "define"
local script_base = require "script_base"
local odali_youxituiguang = class("odali_youxituiguang", script_base)
odali_youxituiguang.script_id = 002084
-- 10级：低级熔炼符*7  1000*绑元  彻底符箓*1
-- 30级：暗器：飞蝗石  1000*绑元  顶变老虎宝宝*1
-- 50级：1000*绑元  红宝石6级*1    3级秘银*5  3级棉布*5
-- 70级：琉璃焰*1   御瑶盘*1          3级秘银*5  3级棉布*5
-- 80级：至尊强化*50  武道丹*50    4级秘银*5  4级棉布*5   称号：五岳独尊  4属性+20
-- 90级：至尊强化*50  武道丹*50    残缺的神界6级*1   92神器自选图样礼包*1    称号：剑影凌绝意  4属性+30
-- 100级：至尊强化*200  武道丹*200    金蚕丝*200  灵蚕丝*200   称号：长啸震天穹 血上线+5000
-- 110级：至尊强化*300  武道丹*300    金蚕丝*300  灵蚕丝*300   称号：雪海疑冰问虎啸 血上限+%5
-- 115级：至尊强化*400  武道丹*400    金蚕丝*400  灵蚕丝*400   称号：千金走天涯 增伤+%2
-- 119级：至尊强化*500  武道丹*500    金蚕丝*500  灵蚕丝*500   称号：万惯任我行 增伤+%3

local LevelGiftInfo = {
    { level = 10 , prize = { { itemid = 30900056, num = 7  }, { itemid = 38008005, num = 1  }, { itemid = 30008121, num = 1 } } },           -- 低级熔炼符*7  绑元*1000  彻底符箓*1
    { level = 30 , prize = { { itemid = 10155001, num = 1  }, { itemid = 38008005, num = 1  }, { itemid = 30505293, num = 1 } } },           -- 暗器：飞蝗石*1  绑元*1000  顶变老虎宝宝*1
    { level = 50 , prize = { { itemid = 38008005, num = 1  }, { itemid = 50613004, num = 1  }, { itemid = 20502003, num = 5 }, { itemid = 20501003, num = 5 } } }, -- 绑元*1000  红宝石6级*1  3级秘银*5  3级棉布*5
    { level = 70 , prize = { { itemid = 10156001, num = 1  }, { itemid = 10156002, num = 1  }, { itemid = 20502003, num = 5 }, { itemid = 20501003, num = 5 } } },   -- 琉璃焰*1  御瑶盘*1  3级秘银*5  3级棉布*5
    { level = 80 , prize = { { itemid = 38008160, num = 50 }, { itemid = 38002397, num = 50 }, { itemid = 20502004, num = 5 }, { itemid = 20501004, num = 5 }, { titleid = 1366, titlename = "Ngũ Nhạc Độc Tôn", attr_bonus = "4 thuộc tính+20" } } },  -- 至尊强化*50  武道丹*50  4级秘银*5  4级棉布*5  称号：五岳独尊 4属性+20
    { level = 90 , prize = { { itemid = 38008160, num = 50 }, { itemid = 38002397, num = 50 }, { itemid = 30505705, num = 1 }, { itemid = 38008203, num = 1 }, { titleid = 1391, titlename = "Kiếm Ảnh Lăng Tuyệt Ý", attr_bonus = "4 thuộc tính+30" } } }, -- 至尊强化*50  武道丹*50  残缺的神界6级*1  92神器自选图样礼包*1  称号：剑影凌绝意 4属性+30
    { level = 100, prize = { { itemid = 38008160, num = 200}, { itemid = 38002397, num = 200}, { itemid = 20310168, num = 200 }, { itemid = 20310174, num = 200 }, { titleid = 1373, titlename = "Tiếng hú dài chấn động trời cao", attr_bonus = "Giới hạn máu+5000" } } }, -- 至尊强化*200  武道丹*200  金蚕丝*200  灵蚕丝*200  称号：长啸震天穹 血上限+5000
    { level = 110, prize = { { itemid = 38008160, num = 300}, { itemid = 38002397, num = 300}, { itemid = 20310168, num = 300 }, { itemid = 20310174, num = 300 }, { titleid = 1376, titlename = "Biển tuyết ngưng băng nghe hổ gầm", attr_bonus = "Giới hạn máu+5%" } } }, -- 至尊强化*300  武道丹*300  金蚕丝*300  灵蚕丝*300  称号：雪海凝冰闻虎啸 血上限+5%
    { level = 115, prize = { { itemid = 38008160, num = 400}, { itemid = 38002397, num = 400}, { itemid = 20310168, num = 400 }, { itemid = 20310174, num = 400 }, { titleid = 1395, titlename = "Ngàn vàng đi chân trời", attr_bonus = "Thân pháp+100" } } }, -- 至尊强化*400  武道丹*400  金蚕丝*400  灵蚕丝*400  称号：千金走天涯 增伤+2%
    { level = 119, prize = { { itemid = 38008160, num = 500}, { itemid = 38002397, num = 500}, { itemid = 20310168, num = 500 }, { itemid = 20310174, num = 500 }, { titleid = 1396, titlename = "Vạn Quan Tùy Ta Đi", attr_bonus = "Chính xác+5000" } } }  -- 至尊强化*500  武道丹*500  金蚕丝*500  灵蚕丝*500  称号：万贯任我行 增伤+3%
}
function odali_youxituiguang:UpdateEventList(selfId, targetId)
	local npcName = self:GetName(targetId)
    self:BeginEvent(self.script_id)
	if self:GetName(targetId) == "都大爽" then
    self:AddText("#{TLWS_20200908_01}")
    if self:GetMissionDataEx(selfId,132) == 0 then
        self:AddNumText("#{TLWS_20200908_02}", 2, 200)
    end
    self:AddNumText("#{TLWS_20200908_03}", 2, 300)
    self:AddNumText("#{TLWS_20200908_04}", 11, 400)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
	else
		self:AddText("#{RLYZ_20240516_67}")
		if self:GetMissionDataEx(selfId,712) < 1 then
		self:AddNumText("#GĐại lễ bao khu đầu", 2, 971)
		end
		self:AddNumText("Kích hoạt quà đặt trước", 11, 972)
		self:EndEvent()
		self:DispatchEventList(selfId, targetId)
	end
end

function odali_youxituiguang:OnEventRequest(selfId, targetId, arg, index)
    if index == 200 then
        self:SetMissionDataEx(selfId, 132, 12020)
        self:notify_tips(selfId,"Kích hoạt thành công, xin đổi lại với ta để nhận thưởng thẻ tài phú.")
        return
    end
    if index == 300 then
        if self:GetMissionDataEx(selfId,132) > 0 then
            self:BeginEvent(self.script_id)
            for i = 1, #(LevelGiftInfo) do
                self:AddNumText("Lĩnh thưởng" .. tostring(LevelGiftInfo[i].level) .. "thưởng cấp", 6, 1000 + i)
            end
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        else
            self:notify_tips(selfId, "Chưa kích hoạt thẻ tài phú")
        end
        return
    end
	if index == 971 then
		-- ScriptGlobal.MDEX_XINFULIBAO = 230 --陈星福大礼包
        if self:GetMissionDataEx(selfId,712) > 0 then
			self:notify_tips(selfId, "Bạn đã nhận thưởng này rồi.")
			return
        end
		--检测背包够不够
        self:BeginAddItem()
		self:AddItem(38003625,1,true)	-- 玄灵丹  
		self:AddItem(20501003,30,true)  -- 3级棉布    
		self:AddItem(20502003,30,true)  -- 3级秘银     
		self:AddItem(20500003,30,true)  -- 3级精铁    
		self:AddItem(10125116,1,true)   -- 白露为霜    
		self:AddItem(10142440,1,true)   -- 封霜仙客    
		--self:AddItem(38008207,288,true) -- 幸运盲盒    
		self:AddItem(30008118,1,true)	-- 工资卡
		if not self:EndAddItem(selfId) then
            self:notify_tips(selfId, "Túi đồ không đủ chỗ trống.")
            return
        end
        self:AddItemListToHuman(selfId)
		self:SetMissionDataEx(selfId, 712, 1)
		self:notify_tips(selfId, "Nhận đại lễ bao khu đầu thành công, xem túi.")
    end
	if index == 972 then
		self:BeginUICommand()
		self:UICommand_AddInt(targetId)
		self:UICommand_AddInt(1)
		self:EndUICommand()
		self:DispatchUICommand(selfId,20100118)
	end
    if index > 1000 and index < 1100 then
        local nFlag = self:GetMissionDataEx(selfId,132)
        if nFlag < 1 then
            self:notify_tips(selfId, "Chưa kích hoạt thẻ tài phú")
            return
        end
        local nSelect = index - 1000
        local nStateIdx = (nSelect % 10)
        if LevelGiftInfo[nSelect] == nil then
            return
        end
        local nLevel = self:GetLevel(selfId)
        if nLevel < LevelGiftInfo[nSelect].level then
            self:notify_tips(selfId, string.format("Chưa đủ cấp %s, không nhận thưởng này được.",
                LevelGiftInfo[nSelect].level))
            return
        end
        local nStateData = self:GetMissionDataEx(selfId, 131);
		-- self:notify_tips(selfId, "nStateData:"..nStateData)
        local tState = self:MathCilCompute_1_InEx(nStateData);
        if tState[nStateIdx + 1] == 1 then
            self:notify_tips(selfId, "Thưởng này đã nhận rồi.")
            return
        end
        local PropSpace = self:LuaFnGetMaterialBagSpace(selfId)
        local MaterialSpace = self:LuaFnGetMaterialBagSpace(selfId)
        if PropSpace < 5 then
            self:notify_tips(selfId, "Ô đạo cụ cần 5 ô trống")
            return
        end
        if MaterialSpace < 5 then
            self:notify_tips(selfId, "Ô nguyên liệu cần 5 ô trống")
            return
        end
        --检测背包够不够
        self:BeginAddItem()
        for i = 1, #(LevelGiftInfo[nSelect].prize) do
            local item = LevelGiftInfo[nSelect].prize[i]
            if item.itemid then
                self:AddItem(item.itemid, item.num, true)
            elseif item.titleid then
                  -- 处理称号奖励
                    if not self:LuaFnHaveAgname(selfId, title_id) then
                    self:LuaFnAddNewAgname(selfId, item.titleid)
                    self:notify_tips(selfId, string.format("Nhận danh hiệu: %s (%s)", item.titlename, item.attr_bonus))
                end
            end
        end
        if not self:EndAddItem(selfId) then
            self:notify_tips(selfId, "Túi đồ không đủ chỗ trống.")
            return
        end
        self:AddItemListToHuman(selfId)
        --标记兑换
        tState[nStateIdx + 1] = 1;
        nStateData = self:MathCilCompute_1_OutEx(tState)
        self:SetMissionDataEx(selfId, 131, nStateData)
        self:notify_tips(selfId, "Nhận thưởng thẻ tài phú thành công, xem túi.")
    end
    if index == 400 then
        self:BeginEvent(self.script_id)
        self:AddText("#{TLWS_20200908_05}")
        self:AddNumText("#{TLWS_20200908_06}", 11, 402)
        self:AddNumText("#{TLWS_20200908_07}", 11, 403)
        self:AddNumText("#{TLWS_20200908_08}", 11, 404)
        self:AddNumText("#{TLWS_20200908_09}", 11, 405)
        self:AddNumText("#{TLWS_20200908_10}", 11, 406)
        self:AddNumText("#{TLWS_20200908_81}", 11, 407)
        self:AddNumText("#{INTERFACE_XML_602}", -1, 401)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 402 then
        self:BeginEvent(self.script_id)
        self:AddText("#{TLWS_20200908_11}")
        self:AddNumText("#{INTERFACE_XML_602}", -1, 400)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 403 then
        self:BeginEvent(self.script_id)
        self:AddText("#{TLWS_20200908_12}")
        self:AddNumText("#{INTERFACE_XML_602}", -1, 400)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 404 then
        self:BeginEvent(self.script_id)
        self:AddText("#{TLWS_20200908_13}")
        self:AddNumText("#{INTERFACE_XML_602}", -1, 400)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 405 then
        self:BeginEvent(self.script_id)
        self:AddText("#{TLWS_20200908_14}")
        self:AddNumText("#{INTERFACE_XML_602}", -1, 400)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 406 then
        self:BeginEvent(self.script_id)
        self:AddText("#{TLWS_20200908_15}")
        self:AddNumText("#{INTERFACE_XML_602}", -1, 400)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 407 then
        self:BeginEvent(self.script_id)
        self:AddText("#{TLWS_20200908_16}")
        self:AddNumText("#{INTERFACE_XML_602}", -1, 400)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
end

function odali_youxituiguang:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function odali_youxituiguang:NotifyTip(selfId, Msg)
    self:BeginEvent(self.script_id)
    self:AddText(Msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return odali_youxituiguang
