--洛阳NPC
--神医
--普通
local ScriptGlobal = require "scripts.ScriptGlobal"
local class = require "class"
local script_base = require "script_base"
local oluoyang_longbatian = class("oluoyang_longbatian", script_base)
oluoyang_longbatian.eventlist = {701603}
function oluoyang_longbatian:OnDefaultEvent(selfId, targetId)


    self:BeginEvent(self.script_id)
        self:AddText(" #{OBJ_luoyang_BaTian}")
        --self:AddNumText("传送到-天外-长春-不老殿", 9, 5000)
        --self:AddNumText("#{SJBW_130823_49}", 6, 10)
        self:AddNumText("Xem thi đấu Thao Trường", 6, -999)
        self:AddNumText("Mãn Nộ Trị Liệu", 6, 0)
        --self:AddNumText("给珍兽恢复气血", 6, -995)
        -- self:AddNumText("前往藏经阁校场", 9, -997)
		--if not self:CallDestSceneFunction(1303, 3000003, "IsClose") then
			self:AddNumText("Truyền tống - Địa Cung 4", 9, 6001)
			self:AddNumText("Truyền tống - đỉnh Thánh Thú Sơn", 9, 6011)
			self:AddNumText("Truyền tống - Long Quy", 9, 6021)
			self:AddNumText("Truyền tống - Kính Hồ", 9, 6031)
		--end
        -- self:AddNumText("前往藏经阁校场", 9, 5001)
        -- self:AddNumText("关于擂台挑战", 11, 999)
        -- self:AddNumText("关于藏经阁校场", 11, -996)
        --self:AddNumText("#{TFXC_20220921_02}", 11, 5003)
        --self:AddNumText("传送到-天外-乌衣巷", 9, 7001)
       -- self:AddNumText("传送到-天外-江湖茶馆", 9, 7002)
        self:CallScriptFunction( 701603, "OnEnumerate", self,selfId, targetId)
    self:EndEvent()
    self:DispatchEventList(selfId,targetId)
end

function oluoyang_longbatian:OnEventRequest(selfId, targetId, arg, index)
    if index == 5000 then
        -- if self:GetLevel(selfId) < 50 then
            -- self:BeginEvent(self.script_id)
            -- self:AddText("您的等级过低，50级以后才能前往不老殿")
            -- self:EndEvent()
            -- self:DispatchEventList(selfId,targetId)
            -- return
        -- end
        -- if ScriptGlobal.is_internal_test then
            -- self:BeginEvent(self.script_id)
            -- self:AddText("内测中,不能参加天外~")
            -- self:EndEvent()
            -- self:DispatchEventList(selfId,targetId)
        -- else
            -- self:CallScriptFunction((400900), "TransferFunc", selfId, 1297, 40, 174, 50)
        -- end
        return
    end
    if index == 5001 then
        if ScriptGlobal.is_internal_test then
            self:BeginEvent(self.script_id)
            self:AddText("Đang test, không tham gia Thiên Ngoại được~")
            self:EndEvent()
            self:DispatchEventList(selfId,targetId)
        else
            -- CYS-NAVMIN 19/09: dich (95,95) canh 1303 nam trong tam giac BI CHAN cua navmesh (sau 7.86 o). Nhanh nay hien KHONG toi duoc — cua chan: C1 (NPC 龙霸天 la `[monster185_off]` trong luoyang_new_monster.ini:4075). MUON MO LAI: SUA TOA DO TRUOC, lay tu nguon co tham quyen (vi tri quai/NPC trong <map>_monster.ini, diem hoi sinh, hay mot dich da kiem), KHONG tu tinh tu .path. Chi tiet: Timeline/handoff/transfer-navmesh.md muc 3.6 + Build/Logs/2026-09-19-transfer-navmesh/97-bai-min.tsv
            self:CallScriptFunction((400900), "TransferFunc", selfId, 1303, 95, 95)
        end
        return
    end
    if index == 5003 then
        self:BeginEvent(self.script_id)
        self:AddText("#{TFXC_20220921_11}")
        self:EndEvent()
        self:DispatchEventList(selfId,targetId)
        return
    end
    -- if index == 5002 then
        -- self:BeginEvent(self.script_id)
        -- self:AddNumText("传送到-西北", 9, 6001)
        -- self:AddNumText("传送到-东北", 9, 6002)
        -- self:AddNumText("传送到-中部", 9, 6003)
        -- self:AddNumText("传送到-西南", 9, 6004)
        -- self:AddNumText("传送到-东南", 9, 6005)
        -- self:EndEvent()
        -- self:DispatchEventList(selfId,targetId)
        -- return
    -- end
    if index == 6001 then
        -- if self:CallDestSceneFunction(1303, 3000003, "IsClose") then
            -- self:BeginEvent(self.script_id)
            -- self:AddText("地宫四层关闭中")
            -- self:EndEvent()
            -- self:DispatchEventList(selfId,targetId)
        -- else
            self:CallScriptFunction((400900), "TransferFunc", selfId, 538, 34, 37)
        -- end
        -- return
    end
    if index == 6011 then
        -- if self:CallDestSceneFunction(1303, 3000003, "IsClose") then
            -- self:BeginEvent(self.script_id)
            -- self:AddText("地宫四层关闭中")
            -- self:EndEvent()
            -- self:DispatchEventList(selfId,targetId)
        -- else
            self:CallScriptFunction((400900), "TransferFunc", selfId, 158, 139,115)
        -- end
        -- return
    end
    if index == 6021 then
            self:CallScriptFunction((400900), "TransferFunc", selfId, 158, 139,49)
    end
    if index == 6031 then
            self:CallScriptFunction((400900), "TransferFunc", selfId, 5, 113,156)
    end
    if index == 6002 then
        if self:CallDestSceneFunction(1303, 3000003, "IsClose") then
            self:BeginEvent(self.script_id)
            self:AddText("Địa Cung tầng 4 đang đóng")
            self:EndEvent()
            self:DispatchEventList(selfId,targetId)
        else
            self:CallScriptFunction((400900), "TransferFunc", selfId, 1299, 214, 87)
        end
        return
    end
    if index == 6003 then
        if self:CallDestSceneFunction(1303, 3000003, "IsClose") then
            self:BeginEvent(self.script_id)
            self:AddText("Địa Cung tầng 4 đang đóng")
            self:EndEvent()
            self:DispatchEventList(selfId,targetId)
        else
            self:CallScriptFunction((400900), "TransferFunc", selfId, 1299, 89, 127)
        end
        return
    end
    if index == 6004 then
        if self:CallDestSceneFunction(1303, 3000003, "IsClose") then
            self:BeginEvent(self.script_id)
            self:AddText("Địa Cung tầng 4 đang đóng")
            self:EndEvent()
            self:DispatchEventList(selfId,targetId)
        else
            self:CallScriptFunction((400900), "TransferFunc", selfId, 1299, 80, 205)
        end
        return
    end
    if index == 6005 then
        if self:CallDestSceneFunction(1303, 3000003, "IsClose") then
            self:BeginEvent(self.script_id)
            self:AddText("Địa Cung tầng 4 đang đóng")
            self:EndEvent()
            self:DispatchEventList(selfId,targetId)
        else
            self:CallScriptFunction((400900), "TransferFunc", selfId, 1299, 209, 166)
        end
        return
    end
    if index == 7001 then
        --self:CallScriptFunction((400900), "TransferFunc", selfId, 1300, 95, 95)
        return
    end
    if index == 7002 then
        if self:CallDestSceneFunction(1301, 3000008, "IsClose") and self:GetName(selfId) ~= "ui"  then
            self:BeginEvent(self.script_id)
            self:AddText("Quán trà giang hồ đang đóng, 9 giờ tối mở")
            self:EndEvent()
            self:DispatchEventList(selfId,targetId)
        else
            local ItemNum = self:GetItemCount(selfId, 38008157)
            if ItemNum >= 0 then
                self:CallScriptFunction((400900), "TransferFunc", selfId, 1301, 46, 53)
            else
                self:BeginEvent(self.script_id)
                self:AddText("Có Thiên Ngoại Tệ mới vào được")
                self:EndEvent()
                self:DispatchEventList(selfId,targetId)
            end
        end
        return
    end
    local gld = math.floor(self:CallScriptFunction(64, "CalcMoney_hpmp", selfId, targetId )* 0.01)
    if index == 0 then
		if self:GetHp(selfId ) == self:GetMaxHp(selfId ) and
            self:GetRage(selfId ) == self:GetMaxRage(selfId ) and
            self:GetMp(selfId ) == self:GetMaxMp(selfId ) then
                self:BeginEvent(self.script_id)
                    self:AddText("Bạn hiện rất khỏe mạnh, không Yêu cầu trị liệu!")
                self:EndEvent()
                self:DispatchEventList(selfId,targetId)
                return
        end
        if gld <= 0 then
            self:CallScriptFunction(64, "Restore_hpmp", selfId, targetId)
        else
            self:BeginEvent( targetId )
                self:AddText("  Ngươi có thể tiêu hao #G#{_EXCHG"..gld.."}#W, để khôi phục khí huyết và nộ khí, xác định muốn trị liệu không?" )
                self:AddNumText("là", -1, 1001 )
                self:AddNumText("không", -1, 1000 )
            self:EndEvent()
            self:DispatchEventList(selfId, targetId )
        end
    else
        self:CallScriptFunction( 701603, "OnDefaultEvent", selfId, targetId, index)
    end
    if index == 1001 then	--确认要治疗
		-- 调用“江湖游医”脚本中计算金钱的函数
		-- 得到交子和金钱数目
		local nMoneyJZ = self:GetMoneyJZ (selfId )
		local nMoney = self:GetMoney (selfId )

		--检查玩家是否有足够的现金
		if (nMoneyJZ + nMoney >= gld) then
			--扣钱
			self:LuaFnCostMoneyWithPriority (selfId, gld)
			-- 调用“江湖游医”脚本
			self:CallScriptFunction(64, "Restore_hpmp", selfId, targetId )
			return
		else
			self:BeginEvent( targetId )
				self:AddText("tiền của ngươi không đủ!" )
			self:EndEvent()
			self:DispatchMissionTips(selfId )
		end
	end
end

function oluoyang_longbatian:CallDestSceneFunction(dest_scene_id, script_id, func, ...)
    local skynet = require "skynet"
    local scene = string.format(".SCENE_%d", dest_scene_id)
    local ok, ret = pcall(skynet.call, scene, "lua", "char_excute_Script", script_id, func, ...)
    if not ok then
        return nil
    end
    return ret
end

return oluoyang_longbatian