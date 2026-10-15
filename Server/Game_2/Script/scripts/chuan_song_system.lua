local gbk = require "wire_charset"
local define = require "define"
local class = require "class"
local script_base = require "script_base"
local skynet = require "skynet"
local chuan_song_system = class("chuan_song_system", script_base)
local ScriptGlobal = require "scripts.ScriptGlobal"
local enum_menpai = define.MENPAI_ATTRIBUTE
local  g_mpInfo	= {
	-- 2026-09-17 transfer-npc: 恶人谷 đổi cảnh 1063 -> 987 theo `maps-sect` (DBC client dòng 1063 là
	-- 凌云窟, dòng 987 mới là `erengu.Scene`; 1063 nay active=0). Toạ độ giữ nguyên — NPC dịch chuyển
	-- 孙三霸 của bản đồ đứng ở (123,150), đi được, cách (125,152) 2,8 ô.
	{ "Môn phái - Ác Nhân Cốc", 987, 125, 152, 703, enum_menpai.MATTRIBUTE_ERENGU},
	{ "Môn phái - Mạn Đà", 184, 139, 162, 592, enum_menpai.MATTRIBUTE_MANTUOSHANZHUANG},
	{ "Môn phái - Mộ Dung Sơn Trang", 1358, 28, 133, 1358, enum_menpai.MATTRIBUTE_GUSU},
	{ "Môn phái - Tinh Tú", 16,  96, 152, 16, enum_menpai.MATTRIBUTE_XINGXIU },
	{ "Môn phái - Tiêu Dao", 14,  67, 145, 14, enum_menpai.MATTRIBUTE_XIAOYAO },
	{ "Môn phái - Thiếu Lâm",  9,  96, 127, 9, enum_menpai.MATTRIBUTE_SHAOLIN },
	{ "Môn phái - Thiên Sơn", 17,  95, 120, 17, enum_menpai.MATTRIBUTE_TIANSHAN },
	{ "Môn phái - Thiên Long", 13,  96, 120, 13, enum_menpai.MATTRIBUTE_DALI },
	{ "Môn phái - Nga Mi", 15,  89, 139, 15, enum_menpai.MATTRIBUTE_EMEI },
	{ "Môn phái - Võ Đang", 12, 103, 140, 12, enum_menpai.MATTRIBUTE_WUDANG },
	{ "Môn phái - Minh Giáo", 11,  98, 167, 11, enum_menpai.MATTRIBUTE_MINGJIAO },
	{ "Môn phái - Cái Bang", 10,  91, 116, 10, enum_menpai.MATTRIBUTE_GAIBANG },
}
-- g_mpInfo[0]	= { "少林",  9,  96, 127, 9, enum_menpai.MATTRIBUTE_SHAOLIN }
-- g_mpInfo[1]	= { "明教", 11,  98, 167, 11, enum_menpai.MATTRIBUTE_MINGJIAO }
-- g_mpInfo[2]	= { "丐帮", 10,  91, 116, 10, enum_menpai.MATTRIBUTE_GAIBANG }
-- g_mpInfo[3]	= { "武当", 12, 103, 140, 12, enum_menpai.MATTRIBUTE_WUDANG }
-- g_mpInfo[4]	= { "峨嵋", 15,  89, 139, 15, enum_menpai.MATTRIBUTE_EMEI }
-- g_mpInfo[5]	= { "星宿", 16,  96, 152, 16, enum_menpai.MATTRIBUTE_XINGXIU }
-- g_mpInfo[6]	= { "天龙", 13,  96, 120, 13, enum_menpai.MATTRIBUTE_DALI }
-- g_mpInfo[7]	= { "天山", 17,  95, 120, 17, enum_menpai.MATTRIBUTE_TIANSHAN }
-- g_mpInfo[8]	= { "逍遥", 14,  67, 145, 14, enum_menpai.MATTRIBUTE_XIAOYAO }
-- g_mpInfo[10] = { "曼陀山庄", 184, 139, 162, 592, enum_menpai.MATTRIBUTE_MANTUOSHANZHUANG}
-- g_mpInfo[11] = { "恶人谷", 1063, 125, 152, 703, enum_menpai.MATTRIBUTE_ERENGU}

-- ============================================================================================
-- 2026-09-17 transfer-npc: bảng điểm đến của NPC dịch chuyển (驿站老板, script 990010).
--
-- Mỗi dòng gom ĐÚNG những gì trước đây nằm rải trong OnDefaultEvent + OnEventRequest:
--   index : số mục menu — GIỮ NGUYÊN số cũ để không phá client, log hay thói quen người chơi.
--   text  : chữ hiện trong hộp thoại (AddNumText).
--   scene, x, z, level : tham số của team:TransferFunc(selfId, scene, x, z, minLevel).
--   limit : chỉ đặt ở mục vốn có sẵn LuaFnGetDestSceneHumanCount (1001 và -999, ngưỡng 700).
--   skip  : tên NPC KHÔNG được chào mục này (NPC đứng ngay tại đích). Tên lấy từ khoá `name=`
--           của từng mục trong `<map>_monster.ini`, KHÔNG phải tên của type trong
--           MonsterAttrExTable — cả 5 驿站老板 đều cùng type nhưng khác tên riêng.
--
-- Mục chỉ hiện khi cảnh đích ĐANG CHẠY trên máy chủ (SceneRunning). Nhờ vậy khi một agent khác
-- bật thêm bản đồ thì menu tự có thêm, và các cảnh đang `active=0` (楼兰 186, 束河古镇 420,
-- 昆吾 1349) không còn chào mời rồi báo lỗi.
--
-- GIỚI HẠN GÓI: GCScriptCommand nhận tối đa 16 mục (`size <= 0x10`). Bảng này **muốn dài bao nhiêu
-- cũng được** — menu tự chia trang (xem `BuildCityMenu` phía dưới), thêm mục "Trang sau" khi cần.
-- ============================================================================================
local g_Cities = {
	-- Năm thành chính (người dùng 17/09: "câu thông 5 thành với nhau").
	{ index = 1001, text = "Thành thị - Lạc Dương",                   scene = 0,    x = 235, z = 322, level = 10, limit = 700,
	  skip = { ["吴德昌"] = true, ["汪旱"] = true } },
	{ index = 1002, text = "Thành thị - Tô Châu",                     scene = 1,    x = 204, z = 256, level = 10,
	  skip = { ["李乘风"] = true, ["邓茂"] = true } },
	{ index = 1010, text = "Thành thị - Đại Lý",                      scene = 2,    x = 253, z = 121,
	  skip = { ["崔逢九"] = true } },
	-- 汴京 (cảnh 755 theo DBC client): NPC 唐松 (530,937) — CY `TransportDefine` dòng 1038,
	-- `MonsterAttrExTable` 49068. Năm 传送NPC còn lại của 汴京 (金阅楼/余繁/梁民/许行之/杨中川)
	-- KHÔNG có dòng trong MonsterAttrExTable nên không dùng được.
	{ index = 1020, text = "Thành thị - Biện Kinh",                   scene = 755,  x = 530, z = 937, level = 10,
	  skip = { ["唐松"] = true } },
	-- 冰雪不夜城: NPC 冰小舞 (160,290) — TransportDefine dòng 939, MonsterAttrExTable 52273.
	{ index = 1021, text = "Thành thị - Bất Dạ Thành",                scene = 1007,  x = 160, z = 290, level = 10,
	  skip = { ["冰小舞"] = true } },
	-- 唐家堡 (cảnh 495 theo quyết định người điều phối; DBC client có dòng 495, KHÔNG có 2220):
	-- NPC 唐予诚 "唐门传送人" type 16461 (126,68) đã có sẵn trong `tangmen_monster.ini` `[monster10]`
	-- với chính script 990010 này, nên chiều về đã chạy sẵn; dòng này mở chiều ĐI.
	{ index = 1022, text = "Thành thị - Đường Gia Bảo",               scene = 495,  x = 126, z = 68,  level = 10,
	  skip = { ["唐予诚"] = true } },
	-- Điểm phụ trong thành, giữ y như trước.
	{ index = 1006, text = "Thành - Lạc Dương - Cửu Châu Thương Hội", scene = 0,    x = 326, z = 269, level = 10,
	  skip = { ["吴德昌"] = true, ["汪旱"] = true } },
	{ index = 1007, text = "Thành thị - Tô Châu - Tiệm Thợ rèn",      scene = 1,    x = 335, z = 225, level = 10,
	  skip = { ["李乘风"] = true, ["邓茂"] = true } },
	-- Ba thành cũ hiện `active=0`; để nguyên trong bảng, SceneRunning tự ẩn cho tới khi bật lại.
	{ index = 1011, text = "Thành thị - Lâu Lan",                     scene = 186,  x = 288, z = 136, level = 75,
	  skip = { ["艾尼瓦尔"] = true } },
	{ index = 1014, text = "Thành thị - Thúc Hà Cổ Trấn",             scene = 420,  x = 200, z = 211, level = 10,
	  skip = { ["徐霞客"] = true } },
	{ index = -999, text = "Thành thị - Côn Ngô",                     scene = 1349, x = 104, z = 191, level = 10, limit = 700,
	  skip = {} },
}

-- Cảnh đích đã có service chưa. `skynet.localname` chỉ tra bảng tên cục bộ, không gọi sang
-- service khác nên không làm nghẽn hộp thoại. Phép kiểm đầy đủ (ensure_scene, số người, cấp,
-- tổ đội, song nhân cưỡi…) vẫn do team:TransferFunc làm khi người chơi bấm chọn.
function chuan_song_system:SceneRunning(sceneId)
	sceneId = tonumber(sceneId)
	if not sceneId or sceneId < 0 then
		return false
	end
	if sceneId == self:get_scene_id() then
		return true
	end
	return skynet.localname(string.format(".SCENE_%d", sceneId)) ~= nil
end

-- ============================================================================================
-- CHIA TRANG. `GCScriptCommand` chỉ chuyển được **16 mục** (`size > 0 and size <= 0x10`,
-- services/game/packet_domains/mission.lua:71); quá số đó thì client bỏ lặng phần cuối, không
-- báo lỗi gì. Vì `maps-all` còn mở thêm hàng trăm cảnh nên bảng `g_Cities` chắc chắn sẽ dài hơn
-- một trang — menu tự chia trang từ bây giờ, không phải sửa lại lúc đó.
--
-- Cách đếm chỗ: 1 dòng chữ + mục "Trở về Môn phái" + mục "Môn phái khác" = 3 chỗ cố định;
-- riêng 崔逢九 còn gọi `OnEnumerate` của 210279 (thêm mục nhiệm vụ) nên chừa thêm 2 chỗ.
-- Nếu số thành hiện được vẫn còn dư chỗ thì KHÔNG hiện mục "Trang sau" (giữ y như một trang).
local MAX_EVENT   = 16   -- giới hạn cứng của gói
local FIXED_SLOTS = 3    -- AddText + 1000 + 1012
local QUEST_SLOTS = 2    -- chừa cho OnEnumerate của 崔逢九
local PAGE_BASE   = 1900 -- mục "Trang sau" mang index PAGE_BASE + <số trang muốn xem>
local PAGE_MAX    = 99   -- PAGE_BASE+1 … PAGE_BASE+99; không đụng dải 1000-1022 hay 2001-4006

function chuan_song_system:VisibleCities(npcName)
	local out = {}
	for _, city in ipairs(g_Cities) do
		if not city.skip[npcName] and self:SceneRunning(city.scene) then
			out[#out + 1] = city
		end
	end
	return out
end

function chuan_song_system:BuildCityMenu(selfId, targetId, page)
	local npcName = self:GetName(targetId)
	local shown = self:VisibleCities(npcName)
	local budget = MAX_EVENT - FIXED_SLOTS
	if npcName == "崔逢九" then
		budget = budget - QUEST_SLOTS
	end
	local perPage, pages = #shown, 1
	if #shown > budget then
		perPage = budget - 1          -- chừa một chỗ cho mục "Trang sau"
		pages = math.ceil(#shown / perPage)
		if pages > PAGE_MAX then
			pages = PAGE_MAX          -- quá 99 trang thì thôi, phần dư không hiện
		end
	end
	page = tonumber(page) or 1
	if page < 1 or page > pages then
		page = 1
	end
	local first = (page - 1) * perPage + 1
	local last = math.min(#shown, page * perPage)
	self:BeginEvent(self.script_id)
		self:AddText("#{XIYU_20071228_01}")
		self:AddNumText("Trở về Môn phái", 9, 1000)
		for i = first, last do
			self:AddNumText(shown[i].text, 9, shown[i].index)
		end
		self:AddNumText("Đưa ta đến Môn phái khác.", 9, 1012)
		if pages > 1 then
			local nxt = page % pages + 1   -- hết trang cuối thì vòng về trang 1
			self:AddNumText(string.format("Trang sau  (%d/%d)", page, pages), 9, PAGE_BASE + nxt)
		end
		if page == 1 and npcName == "崔逢九" then
			self:CallScriptFunction(210279, "OnEnumerate", self, selfId, targetId)
		end
	self:EndEvent()
	self:DispatchEventList(selfId, targetId)
end

function chuan_song_system:OnDefaultEvent(selfId, targetId)
    print("selfId, targetId =", selfId, targetId)
    print("npcName =", self:GetName(targetId))
    self:BuildCityMenu(selfId, targetId, 1)
end

function chuan_song_system:OnEventRequest(selfId, targetId, arg, index)
	local nExYuanBao = self:GetMissionData(selfId,ScriptGlobal.MD_CHANGE_POINTCOUNT)

	-- Mục "Trang sau": dựng lại menu ở trang được chọn, không truyền tống gì.
	if index > PAGE_BASE and index <= PAGE_BASE + PAGE_MAX then
		self:BuildCityMenu(selfId, targetId, index - PAGE_BASE)
		return
	end

	-- 2026-09-17 transfer-npc: mọi mục "đi tới thành" đi qua bảng g_Cities (thay cho các khối
	-- `if index == 1001/1002/1006/1007/1010/1011/1014/-999` cũ, cùng tham số, cùng thứ tự kiểm).
	for _, city in ipairs(g_Cities) do
		if index == city.index then
			if not self:SceneRunning(city.scene) then
				self:notify_tips(selfId, "Bản đồ đích chưa mở trên máy chủ.")
				return
			end
			if city.limit and self:LuaFnGetDestSceneHumanCount(city.scene) >= city.limit then
				self:notify_tips(selfId, "Cảnh đích đã đủ người")
				return
			end
			self:CallScriptFunction((400900), "TransferFunc", selfId, city.scene, city.x, city.z, city.level)
			return
		end
	end
    -- 返回门派
    if index == 1000 then
        local menpai = self:GetMenPai(selfId)
        local con = nil
        -- 遍历查找匹配的门派
        for _, mpinfo in ipairs(g_mpInfo) do
            if mpinfo[6] == menpai then
                con = mpinfo
                break
            end
        end
		if not con then
			self:notify_tips(selfId,"Bạn chưa vào môn phái.")
			return
		end
        if self:LuaFnGetDestSceneHumanCount(con[2]) < 130 then
            self:CallScriptFunction((400900), "TransferFunc", selfId, con[2], con[3], con[4])
        else
            self:notify_tips(selfId,"Cảnh đích đã đủ người")
        end
        return
    end
    if index == 2001 then
        -- CYS-NAVMIN 19/09: dich (132,183) canh 1311 nam trong tam giac BI CHAN cua navmesh (sau 1.84 o). Nhanh nay hien KHONG toi duoc — cua chan: C3 (nhanh index 2001/2020/3001/4001/2006/3006/4006, menu KHONG phat cac index nay). MUON MO LAI: SUA TOA DO TRUOC, lay tu nguon co tham quyen (vi tri quai/NPC trong <map>_monster.ini, diem hoi sinh, hay mot dich da kiem), KHONG tu tinh tu .path. Chi tiet: Timeline/handoff/transfer-navmesh.md muc 3.6 + Build/Logs/2026-09-19-transfer-navmesh/97-bai-min.tsv
        self:CallScriptFunction((400900), "TransferFunc", selfId, 1311, 132, 183,10)
        return
    end
    if index == 2020 then
        -- CYS-NAVMIN 19/09: dich (132,183) canh 1315 nam trong tam giac BI CHAN cua navmesh (sau 1.84 o). Nhanh nay hien KHONG toi duoc — cua chan: C3 (nhanh index 2001/2020/3001/4001/2006/3006/4006, menu KHONG phat cac index nay). MUON MO LAI: SUA TOA DO TRUOC, lay tu nguon co tham quyen (vi tri quai/NPC trong <map>_monster.ini, diem hoi sinh, hay mot dich da kiem), KHONG tu tinh tu .path. Chi tiet: Timeline/handoff/transfer-navmesh.md muc 3.6 + Build/Logs/2026-09-19-transfer-navmesh/97-bai-min.tsv
        self:CallScriptFunction((400900), "TransferFunc", selfId, 1315, 132, 183,10)
        return
    end
    if index == 2021 then
        --self:CallScriptFunction((400900), "TransferFunc", selfId, 1316, 132, 183,10)
        --return
    end
    if index == 3001 then
        -- CYS-NAVMIN 19/09: dich (132,183) canh 1315 nam trong tam giac BI CHAN cua navmesh (sau 1.84 o). Nhanh nay hien KHONG toi duoc — cua chan: C3 (nhanh index 2001/2020/3001/4001/2006/3006/4006, menu KHONG phat cac index nay). MUON MO LAI: SUA TOA DO TRUOC, lay tu nguon co tham quyen (vi tri quai/NPC trong <map>_monster.ini, diem hoi sinh, hay mot dich da kiem), KHONG tu tinh tu .path. Chi tiet: Timeline/handoff/transfer-navmesh.md muc 3.6 + Build/Logs/2026-09-19-transfer-navmesh/97-bai-min.tsv
        self:CallScriptFunction((400900), "TransferFunc", selfId, 1315, 132, 183,10)
        return
    end
    if index == 4001 then
        -- CYS-NAVMIN 19/09: dich (132,183) canh 1316 nam trong tam giac BI CHAN cua navmesh (sau 1.84 o). Nhanh nay hien KHONG toi duoc — cua chan: C3 (nhanh index 2001/2020/3001/4001/2006/3006/4006, menu KHONG phat cac index nay). MUON MO LAI: SUA TOA DO TRUOC, lay tu nguon co tham quyen (vi tri quai/NPC trong <map>_monster.ini, diem hoi sinh, hay mot dich da kiem), KHONG tu tinh tu .path. Chi tiet: Timeline/handoff/transfer-navmesh.md muc 3.6 + Build/Logs/2026-09-19-transfer-navmesh/97-bai-min.tsv
        self:CallScriptFunction((400900), "TransferFunc", selfId, 1316, 132, 183,10)
        return
    end
    if index == 2002 then
        --self:CallScriptFunction((400900), "TransferFunc", selfId, 1312, 114, 162,10)
        --return
    end
    if index == 2006 then
        -- CYS-NAVMIN 19/09: dich (234,132) canh 1311 nam trong tam giac BI CHAN cua navmesh (sau 0.26 o). Nhanh nay hien KHONG toi duoc — cua chan: C3 (nhanh index 2001/2020/3001/4001/2006/3006/4006, menu KHONG phat cac index nay). MUON MO LAI: SUA TOA DO TRUOC, lay tu nguon co tham quyen (vi tri quai/NPC trong <map>_monster.ini, diem hoi sinh, hay mot dich da kiem), KHONG tu tinh tu .path. Chi tiet: Timeline/handoff/transfer-navmesh.md muc 3.6 + Build/Logs/2026-09-19-transfer-navmesh/97-bai-min.tsv
        self:CallScriptFunction((400900), "TransferFunc", selfId, 1311, 234, 132,10)
        return
    end
    if index == 3006 then
        -- CYS-NAVMIN 19/09: dich (234,132) canh 1315 nam trong tam giac BI CHAN cua navmesh (sau 0.26 o). Nhanh nay hien KHONG toi duoc — cua chan: C3 (nhanh index 2001/2020/3001/4001/2006/3006/4006, menu KHONG phat cac index nay). MUON MO LAI: SUA TOA DO TRUOC, lay tu nguon co tham quyen (vi tri quai/NPC trong <map>_monster.ini, diem hoi sinh, hay mot dich da kiem), KHONG tu tinh tu .path. Chi tiet: Timeline/handoff/transfer-navmesh.md muc 3.6 + Build/Logs/2026-09-19-transfer-navmesh/97-bai-min.tsv
        self:CallScriptFunction((400900), "TransferFunc", selfId, 1315, 234, 132,10)
        return
    end
    if index == 4006 then
        -- CYS-NAVMIN 19/09: dich (234,132) canh 1316 nam trong tam giac BI CHAN cua navmesh (sau 0.26 o). Nhanh nay hien KHONG toi duoc — cua chan: C3 (nhanh index 2001/2020/3001/4001/2006/3006/4006, menu KHONG phat cac index nay). MUON MO LAI: SUA TOA DO TRUOC, lay tu nguon co tham quyen (vi tri quai/NPC trong <map>_monster.ini, diem hoi sinh, hay mot dich da kiem), KHONG tu tinh tu .path. Chi tiet: Timeline/handoff/transfer-navmesh.md muc 3.6 + Build/Logs/2026-09-19-transfer-navmesh/97-bai-min.tsv
        self:CallScriptFunction((400900), "TransferFunc", selfId, 1316, 234, 132,10)
        return
    end
    if index == 2007 then
        self:CallScriptFunction((400900), "TransferFunc", selfId, 1312, 235, 132,10)
        return
    end
    -- 大理
    if index == 3011 then
        -- CYS-NAVMIN 19/09: dich (242,137) canh 71 nam trong tam giac BI CHAN cua navmesh (sau 5.96 o). Nhanh nay hien KHONG toi duoc — cua chan: C3 (nhanh `index == 3011`, menu chi phat g_Cities + 1000 + 1012 + trang sau). MUON MO LAI: SUA TOA DO TRUOC, lay tu nguon co tham quyen (vi tri quai/NPC trong <map>_monster.ini, diem hoi sinh, hay mot dich da kiem), KHONG tu tinh tu .path. Chi tiet: Timeline/handoff/transfer-navmesh.md muc 3.6 + Build/Logs/2026-09-19-transfer-navmesh/97-bai-min.tsv
        self:CallScriptFunction((400900), "TransferFunc", selfId, 71, 242, 137)
        return
    end
    -- 带我去其他门派
    if index == 1012 then
        self:BeginEvent(self.script_id)
			for idx,mpinfo in ipairs(g_mpInfo) do
				self:AddNumText(mpinfo[1], 9, idx)
			end
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
    if index >= 0 and index <= 1000 then
        local info = g_mpInfo[index]
		if info then
			if self:LuaFnGetDestSceneHumanCount(info[2]) < 130 then
				self:CallScriptFunction((400900), "TransferFunc", selfId, info[2], info[3], info[4])
			else
				self:notify_tips(selfId,"Cảnh đích đã đủ người")
			end
		end
        return
    end
    if index == 2010 then
        self:CallScriptFunction((400900), "TransferFunc", selfId, 2, 253, 121)
    end
	if self:GetName(targetId) == "崔逢九" then
		self:CallScriptFunction(210279, "OnDefaultEvent", selfId, targetId, arg, index)
	end
end
function chuan_song_system:OnMissionAccept(selfId, targetId, missionScriptId)
	if self:GetName(targetId) == "崔逢九" then
		local ret = self:CallScriptFunction(210279, "CheckAccept", selfId)
		if ret > 0 then
			self:CallScriptFunction(210279, "OnAccept", selfId)
		end
	end
end

function chuan_song_system:OnMissionContinue(selfId, targetId, missionScriptId)
	if self:GetName(targetId) == "崔逢九" then
		self:CallScriptFunction(210279, "OnContinue", selfId, targetId)
	end
end

function chuan_song_system:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
	if self:GetName(targetId) == "崔逢九" then
		self:CallScriptFunction(210279, "OnSubmit", selfId, targetId, selectRadioId)
	end
end

return chuan_song_system
