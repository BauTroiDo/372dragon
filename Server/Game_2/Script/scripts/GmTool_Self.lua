local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ScriptGlobal = require "scripts.ScriptGlobal"
local GmTool_Self = class("GmTool_Self", script_base)
local skynet = require "skynet"
local packet_def = require "game.packet"
local item_cls = require "item"
local item_operator = require "item_operator":getinstance()
local gbk = require "wire_charset"
local configenginer = require "configenginer":getinstance()
local clusteragentproxy_core = require "clusteragentproxy_core"
local utils = require "utils"


GmTool_Self.script_id = 900066
--self:BroadMsgByChatPipe( selfId, "Tip:"..tostring(Tip), 0);111  
GmTool_Self.ZS_LevelMax = 3
GmTool_Self.CS_LevelMax = 98


-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
--		GM工具配置区 【请及时更新GM配置信息】
-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
--【GM工具是否开启 false=关闭（所有角色都不可以用GM工具），true=开启（配置里的角色可使用GM工具）】
GmTool_Self.GmToolIsOpen = true; --false;
-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
--【测试权限，正式的不要加入到这里面】 对应 WorldOperation、TargetOperation、SelfOperation    值1、2、3均可使用  最大权限 
GmTool_Self.GmCeshi = {
    {user = "test00"},
    {user = "test01"},
    {user = "test02"},
    {user = "test03"},
    {user = "test04"},
    {user = "test05"},
    {user = "test06"},
    {user = "test07"},
    {user = "test08"},
    {user = "test09"},
    {user = "test10"},
    {user = "test11"},
    {user = "test12"},
    {user = "test13"},
    {user = "test14"},
    {user = "test15"},
};


-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
--【拥有所有权限的GM加到这里，所有GM请不要出现重复】 对应 WorldOperation、TargetOperation、SelfOperation    值1、2、3均可使用  最大权限 
GmTool_Self.GmRootLarge = {
"chen00",
					};
-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
--【拥有部分权限的GM加到这里，所有GM请不要出现重复】对应 WorldOperation、TargetOperation、SelfOperation    值1、2均可使用  中等权限 
GmTool_Self.GmRootIn = {
						
					};
-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
--【拥有最少权限的GM加到这里，所有GM请不要出现重复】对应 WorldOperation、TargetOperation、SelfOperation    仅值1可使用  最小权限 
GmTool_Self.GmRootSmall = {
						
					};
-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
--【root lv 1=最低权限 2=中等权限 3=最高权限】
--操作影响游戏数据的内容不要乱放权限  如MD,EX,FLAG,WORLD等变量设置   BUFF删给等   
--此类如果乱操作到相关功能的内容,能联想到>>那些角色出问题,无厘头的问题
-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
GmTool_Self.GiveSelfGmBuff = 2;					--自身领取GMBUFF 权限
-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
--所有对象    	不开放的项目 权限设置为 >= 4 即可
GmTool_Self.WorldOperation_max = 17
GmTool_Self.WorldOperation = {
					[1]  = {rootlv = 99,selectname = "Mở kỳ đấu giá mới"},
					[2]  = {rootlv = 99,selectname = "Đóng đấu giá"},
					[3]  = {rootlv = 99,selectname = "Cập nhật cấu hình vật phẩm đấu giá kỳ này"},
					[4]  = {rootlv = 99,selectname = "Mở bảng hoa"},
					[5]  = {rootlv = 99,selectname = "Mở chiến Phượng Hoàng"},
					[6]  = {rootlv = 99,selectname = "Đóng chiến Phượng Hoàng (không kết toán)"},
					[7]  = {rootlv = 99,selectname = "Kết thúc chiến Phượng Hoàng (kết toán)"},
					[8]  = {rootlv = 3,selectname = "Cấu hình chiến trường BOSS"},
					[9]  = {rootlv = 3,selectname = "Thêm CDK"},
					[10]  = {rootlv = 98,selectname = "Tạo quái vật"},
					[11]  = {rootlv = 3,selectname = "Xóa quái đã tạo"},
					[12]  = {rootlv = 3,selectname = "Tạo BOSS"},
					[13]  = {rootlv = 3,selectname = "Số phiên bản hiệu chỉnh"},
					[14]  = {rootlv = 3,selectname = "Tạo quái vật"},
					[15]  = {rootlv = 3,selectname = "Xóa quái đã tạo"},
					[16]  = {rootlv = 3,selectname = "Tạo BOSS"},
					[17]  = {rootlv = 3,selectname = "Số phiên bản hiệu chỉnh"},

				};
--单个对象    	不开放的项目 权限设置为 >= 4 即可
GmTool_Self.TargetOperation_max = 0
GmTool_Self.TargetOperation = {
					
				};
--自身    		不开放的项目 权限设置为 >= 4 即可
GmTool_Self.SelfOperation_max = 36
GmTool_Self.SelfOperation = {
					[1]  = {rootlv = 2,selectname = "Nhận đạo cụ"},
					[2]  = {rootlv = 3,selectname = "Phát danh hiệu"},
					[3]  = {rootlv = 3,selectname = "Nhận kinh nghiệm võ cảnh"},
					[4]  = {rootlv = 2,selectname = "Tăng 4 kháng mỗi loại 50"},
					[5]  = {rootlv = 3,selectname = "Tăng thân pháp 1000"},
					[6]  = {rootlv = 2,selectname = "Nhận Giao Tử"},
					[7]  = {rootlv = 3,selectname = "Trừ Giao Tử"},
					[8]  = {rootlv = 2,selectname = "Nhận Nguyên bảo"},
					[9]  = {rootlv = 3,selectname = "Khấu trừ Nguyên bảo"},
					[10] = {rootlv = 2,selectname = "Nhận nguyên bảo khóa"},
					[11] = {rootlv = 3,selectname = "Trừ nguyên bảo khóa"},
					[12] = {rootlv = 2,selectname = "Nhận kinh nghiệm"},
					[13] = {rootlv = 3,selectname = "Trừ kinh nghiệm"},
					[14] = {rootlv = 1,selectname = "Thiết lập Cấp độ"},
					[15] = {rootlv = 1,selectname = "加入门派"},
					[16] = {rootlv = 2,selectname = "Một nút tu luyện đầy"},
					[17] = {rootlv = 2,selectname = "Đặt tâm pháp"},
					[18] = {rootlv = 1,selectname = "Tra BUFF"},
					[19] = {rootlv = 3,selectname = "Tra dữ liệu MD"},
					[20] = {rootlv = 3,selectname = "Tra dữ liệu EX"},
					[21] = {rootlv = 3,selectname = "Tra dữ liệu FLAG"},
					[22] = {rootlv = 3,selectname = "Tra dữ liệu WORLD"},

					--root权限 不要乱开放给其它权限  限定为3   这个是避免不懂数据的乱设把角色数据给设置乱套了
					[23] = {rootlv = 3,selectname = "Học Kỹ năng"},
					[24] = {rootlv = 3,selectname = "Xóa Kỹ năng"},
					[25] = {rootlv = 3,selectname = "Nhận BUFF"},
					[26] = {rootlv = 3,selectname = "Xóa BUFF"},
					[27] = {rootlv = 3,selectname = "Tra cứu dữ liệu #Ycảnh#W"},
					[28] = {rootlv = 3,selectname = "Chuyển cảnh"},
					[29] = {rootlv = 3,selectname = "Đặt dữ liệu MD"},
					[30] = {rootlv = 3,selectname = "Đặt dữ liệu EX"},
					[31] = {rootlv = 3,selectname = "Đặt dữ liệu FLAG"},
					[32] = {rootlv = 3,selectname = "Đặt dữ liệu WORLD"},
					
					[33] = {rootlv = 1,selectname = "Xóa bỏ thời gian hồi Kỹ năng"},
					[34] = {rootlv = 3,selectname = "xxx"},
					[35] = {rootlv = 3,selectname = "xxx"},
					[36] = {rootlv = 3,selectname = "xxx"},
				};
-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
--		GM工具配置区 【请及时更新GM配置信息】
-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>--
--权限
function GmTool_Self:IsGM( selfId,selfIdEx )
	if self.GmToolIsOpen then
		local MaxGmCount = 10
		local human = self:get_scene():get_obj_by_id(selfId)
		local guid = human:get_guid()
		local _,accountname = skynet.call(".gamed", "lua", "query_roler_account", string.format("%x", guid))
		--开放并检测测试者的权限
		local env = skynet.getenv("env")
		for i = 1,#self.GmCeshi do
			if MaxGmCount <= 10 then
				if self.GmCeshi[i].user == accountname
				 then
					return 98
				end
			else
				break
			end
		end
		for i = 1,#self.GmRootLarge do
			if MaxGmCount <= 10 then
				if self.GmRootLarge[i] == accountname then
					return 3
				end
			else
				break
			end
		end
		for i = 1,#self.GmRootIn do
			if MaxGmCount <= 10 then
				if self.GmRootIn[i] == accountname then
					return 2
				end
			else
				break
			end
		end
		for i = 1,#self.GmRootSmall do
			if MaxGmCount <= 10 then
				if self.GmRootSmall[i] == accountname then
					return 1
				end
			else
				break
			end
		end
	end
	return 0;
end
--打开GM工具
function GmTool_Self:OpenGmTool( selfId )
	local rootlv = self:IsGM( selfId );
	-- [audit 2026-09-10] notify_tips can chuoi; truyen so lam iostream:write nem loi (mission.lua:300)
	self:notify_tips( selfId, "GM level: " .. tostring(rootlv) )
	if rootlv == 0 then
		--普通角色不开启  这里可附加其它操作  联系客服
		
		return
	end
	local rootid
	local backinfo = {}
	for i = 1,self.WorldOperation_max do
		if self.WorldOperation[i] then
			rootid = self.WorldOperation[i].rootlv;
			if rootid then
				if rootlv >= rootid then
					table.insert(backinfo,"1")
				else
					table.insert(backinfo,"0")
				end
			else
				table.insert(backinfo,"0")
			end
		else
			table.insert(backinfo,"0")
		end
	end
	local worldinfo = table.concat(backinfo)
	backinfo = {}
	for i = 1,self.TargetOperation_max do
		if self.TargetOperation[i] then
			rootid = self.TargetOperation[i].rootlv;
			if rootid then
				if rootlv >= rootid then
					table.insert(backinfo,"1")
				else
					table.insert(backinfo,"0")
				end
			else
				table.insert(backinfo,"0")
			end
		else
			table.insert(backinfo,"0")
		end
	end
	local targetinfo = table.concat(backinfo)
	backinfo = {}
	for i = 1,self.SelfOperation_max do
		if self.SelfOperation[i] then
			rootid = self.SelfOperation[i].rootlv;
			if rootid then
				if rootlv >= rootid then
					table.insert(backinfo,"1")
				else
					table.insert(backinfo,"0")
				end
			else
				table.insert(backinfo,"0")
			end
		else
			table.insert(backinfo,"0")
		end
	end
	local selfinfo = table.concat(backinfo)
	self:BeginUICommand()
    self:UICommand_AddInt(316022021)
    self:UICommand_AddStr("..\\Patch\\GmTool.ini")
    self:UICommand_AddStr(selfinfo)
    self:UICommand_AddStr(targetinfo)
    self:UICommand_AddStr(worldinfo)
    self:EndUICommand()
    self:DispatchUICommand(selfId,316022021)
	self:notify_tips( selfId,"open gmtool!" )
end

function GmTool_Self:SetTip(selfId,msg)
	self:BeginEvent()
    self:AddText(msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
	self:BeginUICommand()
    self:UICommand_AddInt(426042021)
    self:UICommand_AddStr(msg)
    self:EndUICommand()
    self:DispatchUICommand(selfId,426042021)
end
function GmTool_Self:OverWarNotAward( selfId )
	if self.GmToolIsOpen then
		local rootlv = self:IsGM( selfId );
		--开放并检测测试者的权限
		local env = skynet.getenv("env")
		-- skynet.logi("env = ",env)
		if env == "local" or env == "debug" then
			if rootlv < self.CS_LevelMax then
				self:notify_tips( selfId,"Quyền GM của bạn không đủ cho mục này." )
				return
			end
		else
			if rootlv < self.ZS_LevelMax then
				self:notify_tips( selfId,"Quyền GM của bạn không đủ cho mục này." )
				return
			end
		end
		local sceneId = self:GetSceneID()
		local warflag = self:LuaFnGetCopySceneData_Param(0,69)
		if warflag == 1 then
			
		elseif warflag == 2 then
			local warscene = self:LuaFnGetCopySceneData_Param(0,66)
			if warscene > 0 then
				local warscenename = self:GetSceneName(warscene)
				if warscene ~= sceneId then
					self:notify_tips( selfId,"Xin tới cảnh chiến trường BOSS:["..warscenename.."]rồi hãy thao tác trong đó." )
					return
				end
				local isstart = self.scene:get_param(1)
				local isopen = self.scene:get_param(2)
				if isstart > 0 or isopen > 0 then
					self:StopOneActivity(394)
					self.scene:set_param(1,0)
					self.scene:set_param(2,0)
					self.scene:set_param(32,2147483647)
					local boxpos = 
					{ 
						--第一个水晶
						[1] = 
						{
							world_pos = {x = -1, y = -1}, --水晶位置
							league_id = -1, --占领水晶同盟id
							guild_id = -1, --占领水晶帮会id
							league_name = "", --占领水晶同盟名称
							hp = 0, -- 写死传0
						},
						--第二个水晶
						[2] = 
						{
							world_pos = {x = -1, y = -1}, --水晶位置
							league_id = -1, --占领水晶同盟id
							guild_id = -1, --占领水晶帮会id
							league_name = "", --占领水晶同盟名称
							hp = 0, -- 写死传0
						},
						--第三个水晶
						[3] = 
						{
							world_pos = {x = -1, y = -1}, --水晶位置
							league_id = -1, --占领水晶同盟id
							guild_id = -1, --占领水晶帮会id
							league_name = "", --占领水晶同盟名称
							hp = 0, -- 写死传0
						},
						--第四个水晶
						[4] = 
						{
							world_pos = {x = -1, y = -1}, --水晶位置
							league_id = -1, --占领水晶同盟id
							guild_id = -1, --占领水晶帮会id
							league_name = "", --占领水晶同盟名称
							hp = 0, -- 写死传0
						},
					}
					self:DispatchPhoenixPlainWarCrystalPos(boxpos)
					local msg = "#B"..warscenename.."#PChiến BOSS kết thúc sớm, không kết toán thưởng!"
					self:SetTip( selfId,msg )
					if isopen > 0 then
						self:SceneBroadcastMsg(msg)
						local bossid = self.scene:get_param(28)
						local mostercount = self:GetMonsterCount()
						local objId,dataId,obj
						for i = 1,mostercount do
							objId = self:GetMonsterObjID(i)
							obj = self.scene:get_obj_by_id(objId)
							if obj then
								dataId = obj:get_model()
								if dataId == bossid
								or dataId == 99998
								or dataId == 99999
								or dataId == 52338 then
									self.scene:delete_temp_monster(obj)
								end
							end
						end
					end
					
				else
					self:notify_tips( selfId,"Chiến trường BOSS hiện chưa mở, khỏi đóng." )
					return
				end
			else
				self:SetTip( selfId,"error warscene:"..tostring(warscene) )
			end
		end
	end
end
function GmTool_Self:OverWarOnAward( selfId )
	if self.GmToolIsOpen then
		local rootlv = self:IsGM( selfId );
		if env == "local" or env == "debug" then
			if rootlv < self.CS_LevelMax then
				self:notify_tips( selfId,"Quyền GM của bạn không đủ cho mục này." )
				return
			end
		else
			if rootlv < self.ZS_LevelMax then
				self:notify_tips( selfId,"Quyền GM của bạn không đủ cho mục này." )
				return
			end
		end
		local sceneId = self:GetSceneID()
		local warflag = self:LuaFnGetCopySceneData_Param(0,69)
		if warflag == 1 then
			
		elseif warflag == 2 then
			local warscene = self:LuaFnGetCopySceneData_Param(0,66)
			if warscene > 0 then
				local warscenename = self:GetSceneName(warscene)
				if warscene ~= sceneId then
					self:notify_tips( selfId,"Xin tới cảnh chiến trường BOSS:["..warscenename.."]rồi hãy thao tác trong đó." )
					return
				end
				local isstart = self.scene:get_param(1)
				local isopen = self.scene:get_param(2)
				if isstart > 0 or isopen > 0 then
					self.scene:set_param(4,0)
					local msg = "#B"..warscenename.."#PChiến BOSS kết thúc sớm, kết toán thưởng chiến trường!"
					self:SetTip( selfId,msg )
					if isopen > 0 then
						self:SceneBroadcastMsg(msg)
					end
					
				else
					self:notify_tips( selfId,"Chiến trường BOSS hiện chưa mở, khỏi đóng." )
					return
				end
			else
				self:SetTip( selfId,"error warscene:"..tostring(warscene) )
			end
		end
	end
end

function GmTool_Self:SetBossWar( selfId, warflag, param1,param2,param3,param4 )
	if not warflag or warflag < 0 or warflag > 20 then
		return
	end
	if self.GmToolIsOpen then
		local rootlv = self:IsGM( selfId );
		if env == "local" or env == "debug" then
			if rootlv < self.CS_LevelMax then
				self:notify_tips( selfId,"Quyền GM của bạn không đủ cho mục này." )
				return
			end
		else
			if rootlv < self.ZS_LevelMax then
				self:notify_tips( selfId,"Quyền GM của bạn không đủ cho mục này." )
				return
			end
		end
		local sceneId = self.scene:get_id()
		local waring = false
		local warscene = self:LuaFnGetCopySceneData_Param(0,66)
		if warscene > 0 then
			if self:LuaFnGetCopySceneData_Param(warscene,2) > 0 then
				waring = true
			end
		end
		if waring then
			if warflag == 0 then
				self:notify_tips( selfId,"Hiện tại:"..tostring(warscene).."cảnh số đang chiến tranh, không đặt mục này được" )
				return
			end
		end
		local yexihu_boss = self:GetActivityWar("yexihu_boss",false,false,"findOne",{_id = 0})
		if not yexihu_boss then
			self:notify_tips( selfId,"Lấy dữ liệu bất thường." )
			return
		end
		if warflag == 0 then
			if sceneId == 0
			or sceneId == 1
			or sceneId == 2 then
				self:notify_tips( selfId,"Không mở chiến trường trong chủ thành được." )
				return
			end
			if not param1 or param1 < 0 or param1 > 11111111 then
				self:notify_tips( selfId,"week error。" )
				return
			elseif not param2 or param2 < 0 or param2 > 23 then
				self:notify_tips( selfId,"hour error。" )
				return
			elseif not param3 or param3 < 0 or param3 > 59 then
				self:notify_tips( selfId,"minue error。" )
				return
			elseif not param4 or param4 < 0 or param4 > 72000 then
				self:notify_tips( selfId,"longtime error。" )
				return
			end
			local timer = os.date("*t")
			local curminue = timer.hour * 60 + timer.min
			local needminue = param2 * 60 + param3
			if curminue + 2 >= needminue then
				local msg = string.format("Xin chừa hơn hai phút cho giờ mở chiến (ví dụ muốn mở %02d:%02d thì đặt %d giờ %d phút).",
				param2,param3,param2,param3 + 3)
				self:SetTip( selfId,msg )
				return
			end
			
			local scenename = "Chiến trường tại:"..self:GetSceneName()
			local weekstr = string.format("%08d",param1)
			local  warini = yexihu_boss.warini
			warini.needscene = sceneId
			warini.startminue = needminue
			warini.longtime = param4
			for i = 1,7 do
				warini["week"..i] = tonumber(string.sub(weekstr,i + 1,i + 1))
			end
			local updatedata = {
				playername = scenename,
				warini = warini,
			}
			self:UpdateActivityWar("yexihu_boss",false,false,updatedata)
			local isok = self:get_scene():get_script_engienr():call(999998, "LoadActivity", "load",true)
			if isok == 1 then
				self:GetActivityWar_ini( selfId, 2 )
				self:StartOneActivity(394,2100000000)
				local msg = string.format("Chiến trường BOSS %s mở thành công: %02d giờ %02d phút chính thức.",scenename,param2,param3)
				self:SetTip( selfId,msg )
			else
				self:notify_tips( selfId,"Đặt thất bại, xin thử lại." )
				return
			end
		else
			local paramid = 
			{
			"bossid",
			"bossposx",
			"bossposz",
			"bossmaxhp",
			"needlevel",
			"needmaxhp",
			"paodiantime",
			"paodianluckhuman",
			"paodianlx",
			"paodiancount",
			"paodianlucklx",
			"paodianluckcount",
			"dieboxcount",
			"playerboxcount",
			"playerboxprotecttime",
			"dieboxdeltime",
			"backsceneid",
			"backposx",
			"backposz",
			}
			local idx = paramid[warflag]
			if not idx then
				self:notify_tips( selfId,"warflag error。。" )
				return
			end
			if not param1 or param1 < 0 or param1 > 2100000000 then
				self:notify_tips( selfId,"param1 error。。" )
				return
			end
			if waring then
				if idx == "bossid" then
					self:notify_tips( selfId,"Chiến BOSS đang diễn ra, không đổi BOSSID được" )
					return
				end
			end
			local warini = yexihu_boss.warini
			warini[idx] = param1
			local updatedata = {warini = warini}
			self:UpdateActivityWar("yexihu_boss",false,false,updatedata)
			paramid = {28,29,30, 6,8,9,10,11, 12,13,14,15, 33,35,36,34, 37,38,39}
			local parid = paramid[warflag]
			if warscene > 0 and parid then
				self:LuaFnSetCopySceneData_Param(warscene,parid,param1)
			end
			self:BeginUICommand()
			self:UICommand_AddInt(828042022)
			self:UICommand_AddInt(warflag)
			self:UICommand_AddInt(param1)
			self:EndUICommand()
			self:DispatchUICommand(selfId,828042022)
			self:notify_tips( selfId,"Cài đặt thành công." )
		end
	end
end
function GmTool_Self:GetActivityWar_ini( selfId, warflag )
	if self.GmToolIsOpen then
		local rootlv = self:IsGM( selfId );
		if env == "local" or env == "debug" then
			if rootlv < self.CS_LevelMax then
				self:notify_tips( selfId,"Quyền GM của bạn không đủ cho mục này." )
				return
			end
		else
			if rootlv < self.ZS_LevelMax then
				self:notify_tips( selfId,"Quyền GM của bạn không đủ cho mục này." )
				return
			end
		end
		local sceneId = self:GetSceneID()
		local backtab = {}
		for i = 1,200 do
			backtab[i] = {
				name = "",
				rank_value_1 = 0,
				level = 0,
				menpai = 0,
				total = 117,
				win = 0,
				rank_value_2 = 0,
				rank_value_3 = 0,
				server_id = 0,
			}
		end
		local sceneId = self.scene:get_id()
		-- if sceneId == 0
		-- or sceneId == 1
		-- or sceneId == 2 then
			-- self:notify_tips( selfId,"主城不可操作此项目。" )
			-- return
		-- end
		local warscene = self:LuaFnGetCopySceneData_Param(0,66)
		local uiid
		if warflag == 1 then
			-- 凤凰
		elseif warflag == 2 then
			local scenename = self:GetSceneName()
			backtab[103].name = scenename.."Chiến BOSS"
			uiid = 828042021
			backtab[102].rank_value_1 = self.script_id
			backtab[102].name = "SetBossWar"
			local paramid = 
			{
			"bossid",
			"bossposx",
			"bossposz",
			"bossmaxhp",
			"needlevel",
			"needmaxhp",
			"paodiantime",
			"paodianluckhuman",
			"paodianlx",
			"paodiancount",
			"paodianlucklx",
			"paodianluckcount",
			"dieboxcount",
			"playerboxcount",
			"playerboxprotecttime",
			"dieboxdeltime",
			"backsceneid",
			"backposx",
			"backposz",
			}
			-- local paramid = {28,29,30, 6,8,9,10,11, 12,13,14,15, 33,35,36,34, 37,38,39}
			backtab[101].win = #paramid
			
			backtab[1 ].name = "ID bảng quái BOSS"
			backtab[2 ].name = "Vị trí tạo BOSS X"
			backtab[3 ].name = "Vị trí tạo BOSS Z"
			backtab[4 ].name = "Máu tối đa BOSS"
			backtab[5 ].name = "Cấp yêu cầu tham gia"
			backtab[6 ].name = "Máu yêu cầu tham gia"
			backtab[7 ].name = "Khoảng cách treo máy (không đặt ghi 0)"
			backtab[8 ].name = "Số người treo máy may mắn"
			backtab[9 ].name = "Loại nhận treo máy thường"
			backtab[10].name = "Số lượng nhận treo máy thường"
			backtab[11].name = "Loại nhận treo máy may mắn"
			backtab[12].name = "Số lượng nhận treo máy may mắn"
			backtab[13].name = "Số gói rơi khi BOSS chết"
			backtab[14].name = "Số gói riêng đòn kết liễu BOSS"
			backtab[15].name = "Thời gian bảo hộ gói riêng (giây)"
			backtab[16].name = "Thời gian tồn tại mọi gói rơi (giây)"
			backtab[17].name = "Xin rời chiến trường về cảnh số"
			backtab[18].name = "Xin rời chiến trường về vị trí cảnh X"
			backtab[19].name = "Xin rời chiến trường về vị trí cảnh Z"
			local yexihu_boss = self:GetActivityWar("yexihu_boss",false,false,"findOne",{_id = 0})
			if not yexihu_boss then
				local isok = self:get_scene():get_script_engienr():call(999998, "LoadActivity", "load")
				if isok ~= 2 then
					self:notify_tips( selfId,"Nạp dữ liệu bất thường." )
					return
				end
				yexihu_boss = self:GetActivityWar("yexihu_boss",false,false,"findOne",{_id = 0})
				if not yexihu_boss then
					self:notify_tips( selfId,"Nạp dữ liệu bất thường.." )
					return
				end
			end
			local warini = yexihu_boss.warini
			local startminue = warini.startminue
			local weekflag = "1"..tostring(warini.week7)
			for i = 1,6 do
				weekflag = weekflag..tostring(warini["week"..i])
			end
			backtab[101].name = weekflag
			backtab[101].rank_value_1 = startminue // 60
			backtab[101].rank_value_2 = startminue % 60
			backtab[101].rank_value_3 = warini.longtime
			for i,j in ipairs(paramid) do
				backtab[i].rank_value_1 = warini[j]
			end
		else
			return
		end
		local human = self:get_scene():get_obj_by_id(selfId)
		local guid = human:get_guid()
		local msg = packet_def.WGCRetQueryXBWRankCharts.new()
		msg.status = 2
		msg.type = 1
		msg.guid = guid
		msg.rank_count = 200
		msg.top_list = backtab
		self:get_scene():send2client(human, msg)
		self:BeginUICommand()
		self:EndUICommand()
		self:DispatchUICommand(selfId,uiid)
		-- self:DispatchUICommand(selfId,uiid)
		local msg = "Loại treo máy cấp:\\n0 = không mở\\n1 = kim tệ\\n2 = Giao Tử\\n3 = nguyên bảo\\n4 = nguyên bảo khóa"
		self:BeginEvent(self.script_id)
		self:AddText(msg)
		self:EndEvent()
		self:DispatchEventList(selfId,selfId)
	end
end
		
function GmTool_Self:BackInfoToUI( selfId,backinfo )
	self:BeginUICommand()
    self:UICommand_AddInt(426042021)
    self:UICommand_AddStr(backinfo)
    self:EndUICommand()
    self:DispatchUICommand(selfId,426042021)
end

GmTool_Self.PhoenixPlainWarSceneId = 191					--凤凰战争场景
GmTool_Self.PhoenixPlainWarOverTime = 1200				--凤凰战争时长  单位:秒
GmTool_Self.PhoenixPlainWarStartTime = 10				--凤凰战争GM开启后延时10秒正式开始  单位:秒
GmTool_Self.PhoenixPlainWarAwardTime = 100				--凤凰战争参与时长达100秒以上方可领取奖励  单位:秒
GmTool_Self.PhoenixPlainWarNeedLevel = 10				--凤凰战争参与需求等级
GmTool_Self.PhoenixPlainWarNeedHp = 10000				--凤凰战争参与需求最低血量 
function GmTool_Self:DebugXX( selfId )
	skynet.logi(self:GetName(selfId))
end
--GM代码测试或执行区1
function GmTool_Self:DebugA( selfId )
	if self.GmToolIsOpen then
		local rootlv = self:IsGM( selfId );
		if rootlv < self.CS_LevelMax then
			self:notify_tips( selfId,"Quyền GM của bạn không đủ cho mục này." )
			return
		end
		local scene = self:get_scene()
		local sceneId = scene:get_id()
		local human = scene:get_obj_by_id(selfId)
		if not human then return end
		local guid = human:get_guid()
		local agent = human:get_agent()
		local posx,posz = self:GetWorldPos(selfId)
		self:RestoreHp(selfId)
		self:RestoreMp(selfId)
		self:RestoreRage(selfId)
		for i = 1,200 do
			human:set_cool_down(i, 0)
		end
		local ts_id = 50
		if ts_id == 50 then
			local value = human:get_game_flag_key("zhu_bo_flag")
			skynet.logi("value = ",value)
			return
		end
		if 44 == ts_id then
			local name = human:get_name()
			local msg = self:ScriptGlobal_Format("#{QRZM_211119_53}",name,name,name)
			self:AddGlobalCountNews(msg)
			return
		end
		if 43 == ts_id then
			local ret = packet_def.GCDetailAttrib.new()
			ret.m_objID = selfId
			ret.flags = { 
			0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0}--这里
			ret.flags[16] =  ret.flags[16] | 0x10
			ret.unknow_127 = 2
			scene:send2client(239, ret)
			return
		end
		if 42 == ts_id then
			self:notify_tips( selfId,"11。" )
			local msg = packet_def.GCWuhunWG.new()
			msg.type = 0
			msg.wg = 1
			local unlocked = table.clone(human:get_wuhun_wg())
			local huanhun_unlock_count = 0
			msg.unlockd = {}
			for i = 1, 6 do
				i = tostring(i)
				if unlocked[i] then
					unlocked[i].id = tonumber(i)
					table.insert(msg.unlockd, unlocked[i])
					huanhun_unlock_count = huanhun_unlock_count + 1
				end
			end
			msg.huanhun_id = 1
			msg.huanhun_unlock_count = huanhun_unlock_count
			scene:send2client(239, msg)
		
			return
		end
		if 41 == ts_id then
			local ret = self:CallDestSceneFunction(1297,808002,"GetDataValidator")
			-- local ret = self:CallScriptFunction(808002, "GetDataValidator")
			skynet.logi("ret = ",ret)
			-- self:CallScriptFunction(808002, "OnDefaultEvent",365,1,2,3,4,5,ret)
			self:CallDestSceneFunction(1297,808002,"OnDefaultEvent",365,1,2,3,4,5,ret)
			return
		end
		if 40 == ts_id then
			skynet.logi("cur load_date = ",self:GetActivityKey(398,"load_date",713))

			return
		end
		if 39 == ts_id then
			local world_id = self:LuaFnGetServerID(selfId)
			if self:CloseJingPaiEx(world_id) then
				local msg = "Đấu giá đóng thành công"
				self:notify_tips(selfId, msg)
			else
				self:notify_tips(selfId, "Đóng đấu giá thất bại, kiểm có mở không, có ở cảnh liên server không")
			end
			return
		end
		if 38 == ts_id then
			if self:CloseHuaBangEx(selfId) then
				self:notify_tips( selfId,"Bảng hoa đóng." )
			else
				self:notify_tips( selfId,"Bảng hoa chưa mở, nếu không ẩn icon xin để ý thông báo có ra chưa." )
			end
			return
		end
		
		if 37 == ts_id then
			local node_list = skynet.call(".cluster_agent", "lua", "get_node_list")
			for i,j in pairs(node_list) do
				skynet.logi(i," = ",table.tostr(j))
			end
		
			local world_id = self:LuaFnGetServerID(selfId)
			skynet.logi("world_id = ",world_id)
			return
		end
		
		if 36 == ts_id then
			skynet.call(".ranking", "lua", "set_guid_value",guid,math.random(1,2100000000))
			return
		end
		
		
		if 36 == ts_id then
			local objId = self:GetMissionData(selfId,888)
			skynet.logi("objId = ",objid)
			if objid == 0 then return end
			self:get_scene():reset_dmg_top_monid(objId)
			return
		end
		
		if 35 == ts_id then
			local monsterid = self:LuaFnCreateMonster(52346,posx,posz,15,0,808067)
			
			self:SetCharacterDieTime(monsterid, 10000)
			self:SetCharacterName(monsterid, "In danh sách quái")
			
			skynet.logi("monsterid = ",monsterid)
			return
		end
		if 34 == ts_id then
			local phid,plid = self:LuaFnGetCurrentPetGUID(selfId)
			if phid and plid then
				self:LuaFnSetPetData(selfId, phid, plid, "level", 50)
			end
		
			return
		end
		if 33 == ts_id then
			self:BeginUICommand()
			self:UICommand_AddInt(selfId)
			self:EndUICommand()
			self:DispatchUICommand(selfId,20100118)
			-- self:UseDiaoWenFeatures(selfId,1,15)
			return
		end
		if 32 == ts_id then
			local skill_id = 760
				local tabgetId = 325
			self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 21439, 0)
			self:change_state("combat")
				local targetObj = scene:get_obj_by_id(tabgetId)
			local ret = packet_def.GCCharSkill_Send.new()
			ret.m_objID = human:get_obj_id()
			ret.logic_count = human:get_logic_count()
			ret.skill_id = skill_id
			ret.target_id = tabgetId
			ret.target_pos = targetObj:get_world_pos()
			human:get_scene():broadcast(human, ret, true)
			human:send_operate_result_msg(result)

			local targetObj = scene:get_obj_by_id(tabgetId)
			if targetObj then
				local ret = packet_def.GCCharSkill_Send.new()
				ret.m_objID = selfId
				ret.logic_count = human:get_logic_count()
				ret.skill_id = skill_id
				ret.target_id = tabgetId
				ret.target_pos = targetObj:get_world_pos()
				scene:broadcast(human, ret, true)
			end
			return
		end	
		if 31 == ts_id then
			self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 43536, 0)
			local ret = packet_def.GCCharBaseAttrib.new()
            ret.m_objID = selfId
            ret:set_ride_model(human:get_attrib("ride_model"))
            scene:send2client(human, ret)
			return
		end
		if 30 == ts_id then
			local tab = {
			5952,
			11008,
			5956,
			5957,
			31684,
			50002,
			5953,
			45557,
			48962,
			21180,
			21244,
			10266,
			10263,
			48817,
			48865,
			7749,
			43768,
			54,
			}
			for i,j in ipairs(tab) do
				skynet.logi("buff:",j)
				self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, j, 0)
			end
			
			return
		end
		if 29 == ts_id then
			local tabgetId = 24
			self:LuaFnSendSpecificImpactToUnit(selfId, selfId, tabgetId, 1265, 0)--std_impact_066
			return
		end
		if 28 == ts_id then
			local msg = packet_def.GCAddSkill.new()
			msg.skill = 760
			return
		end
		if 27 == ts_id then
			local function print_memory_usage()
				skynet.logi("Memory usage (KB):", collectgarbage("count"))
			end
			print_memory_usage() 
			local configenginer = require "configenginer":getinstance()
			print_memory_usage() 
			local skillenginer = require "skillenginer":getinstance()
			print_memory_usage() 
			local actionenginer = require "actionenginer":getinstance()
			print_memory_usage() 
			local impactenginer = require "impactenginer":getinstance()
			print_memory_usage()
			local sss = require "script_base"
			print_memory_usage()
			return
		end
		if 26 == ts_id then
			local tabgetId = 240
			local obj = scene:get_obj_by_id(tabgetId)
			if obj then
				self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 21439, 0)
			
				local msg = packet_def.GCTargetListAndHitFlags.new()
				msg.data_type = 0
				msg.m_objID = selfId
				msg.target_pos = obj:get_world_pos()
				msg.target_list = {tabgetId,241,243,242,244,245}
				msg.logic_count = human:get_logic_count()
				msg.skill_or_special_obj_id = 760
				msg.unknow_1 = 1
				msg.size = #(msg.target_list)
				self.shenme = 1
				scene:broadcast(human, msg, true)
				
			end
			return
		end

		if 25 == ts_id then
			local key = define.SETTING_TYPE
			local skill = {281,291,295}
			
			for i = 1,3 do
				local keyx = human:get_empty_setting(key.SETTING_TYPE_K1, key.SETTING_TYPE_K9, {data = 0, type = 1})
				skynet.logi("keyx = ",keyx)
				human:modify_setting(keyx, skill[i])
			end
			human:send_setting()
			return
		end
		if 24 == ts_id then
			self:LuaFnGmKillObj(selfId, selfId)
			return
		end
		
		if 23 == ts_id then
			human:features_effect_notify_client(999)
			return
		end
		
		if 22 == ts_id then
			for i = 1,60 do
				self:LuaFnAddMissionHuoYueZhi(selfId, i)
			end
			return
		end
		if 21 == ts_id then
			skynet.logi("GmTool_Self = ", selfId, "stack =", debug.traceback())
			
			return
		end
		if 20 == ts_id then
			self:LuaFnSendSpecificImpactToUnit(-1, -1, -1, 556, 0)
		
			return
		end
		if 19 == ts_id then
			skynet.logi("Hữu hiệu???")
		
			local scenename = scene:get_name()
			local scene_type = scene:get_type()
			skynet.logi("scenename = ",scenename)
			skynet.logi("scene_type = ",scene_type)
		
		
			local scenename = skynet.call(".SCENE_1300", "lua", "get_name")
			local scene_type = skynet.call(".SCENE_1300", "lua", "get_type")
			skynet.logi("scenename = ",scenename)
			skynet.logi("scene_type = ",scene_type)
			local utils = require "utils"
			local node_name = utils.get_node_name()
			skynet.logi("node_name = ",node_name)
			local nn = skynet.self()
			skynet.logi("nn = ",nn)
			return
		end
		if 18 == ts_id then
		
			local level = human:get_level()
			local wash_point_level = define.DEFAULT_WASHPOINT_LEVEL
			local attr_level_up = configenginer:get_config("attr_level_up_table")
			local menpai = human:get_attrib("menpai")
			local chn = define.ENUM_MENPAI_CHN[menpai]
			local lv1_attrs = {}
			for i = 0, level do
				local attr_up = attr_level_up[i]
				--attr_up[力量][恶人谷] = value
				for attr, v in pairs(attr_up) do
					if v[chn] then
						local v_chn = v[chn]
						local key = attr
						local add = 0
						if type(v_chn) == "table" then
							add = v_chn[1]
						else
							add = v_chn
						end
						local e = lv1_attrs[key] or 0
						local new = e + add
						lv1_attrs[key] = new
					end
				end
				local key = "point_remain"
				local add_point_remain = human:get_level_up_point_remain_add(i)
				local e = lv1_attrs[key] or 0
				local new = e + add_point_remain
				lv1_attrs[key] = new
			end
			for i,j in pairs(lv1_attrs) do
				skynet.logi("[",i,"] = ",j)
			end
			local str = human:get_attrib("str")
			skynet.logi("[str] = ",str)
			str = human.db:get_lv1_attrib()["str"]
			skynet.logi("[str] = ",str)
			return
		end

		if 17 == ts_id then
			local equip_base = configenginer:get_config("equip_base")
			equip_base = equip_base[10101009]
			if equip_base then
				for i,j in pairs(equip_base.base_attrs) do
					skynet.logi(i," = ",j)
				end
			end
			
			
			return
		end
		
		if 16 == ts_id then
			local msg = packet_def.GCDiaowenFeatureSkill.new()
			msg.objId = selfId
			msg.effect_id = 5
			scene:broadcast(human, msg, true)
			return
		end
		
		
		if 15 == ts_id then
						local dw_jinjie_info = configenginer:get_config("dw_jinjie_info")
				dw_jinjie_info = dw_jinjie_info[1]
				skynet.logi("dw_jinjie_info.skill_value = ",dw_jinjie_info.skill_value)
				
			return
		end
		local world_pos = human:get_world_pos()
		if 14 == ts_id then
			local msg = packet_def.GCCharSkill_Missed.new()
			msg.reciver = selfId
			msg.sender = selfId
			msg.flag = 20
			msg.skill_id = -1
			msg.sender_logic_count = 0
			scene:broadcast(human, msg, true)
			return
		end
		
		if 13 == ts_id then
		
			local msg = packet_def.GCTargetListAndHitFlags.new()
			msg.data_type = msg.enum_type.UNIT_USE_SKILL
			-- msg.data_type = msg.enum_type.SPECIAL_OBJ_ACTIVATE
			msg.unknow_1  = 16
			msg.m_objID = human:get_obj_id()
			msg.target_pos = human:get_world_pos()
			msg.target_list = {human:get_obj_id()}
			msg.logic_count = human:get_logic_count()
			msg.skill_or_special_obj_id = -1
			msg.shenme = 0
			msg.size = #(msg.target_list)
			scene:broadcast(human, msg, true)
		
			return
		end
		
		
		if 12 == ts_id then
			local target_id = 240
			local obj = scene:get_obj_by_id(target_id)
			if obj then
				local ret = packet_def.GCCharSkill_Send.new()
				ret.m_objID = selfId
				-- ret.logic_count = human:get_logic_count()
				ret.logic_count = human:get_logic_count()
				ret.skill_id = 4428
				ret.target_id = obj:get_obj_id()
				ret.target_pos = obj:get_world_pos()
				-- ret.unknow_1 = 0
				-- ret.unknow_2 = 6
				ret.unknow_1 = 0
				ret.unknow_2 = 1
				scene:broadcast(human, ret, true)
				self:notify_tips( selfId,"ss。" )
			end
			return
		end
		
		
		if 11 == ts_id then
		
			local kfs_wg_attack_rate = human:item_value(define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_ADD_ATTACK_PHYSIC_DAMAGE_RATE)
			skynet.logi("kfs_wg_attack_rate = ",kfs_wg_attack_rate)
			return
		end
		
		
		if 10 == ts_id then
			if sceneId == 0 then
				scene:set_mingdong_data(guid,guid * 2)
			else
				-- local my_scene = string.format(".SCENE_%d",sceneId)
				skynet.send(".SCENE_0", "lua", "set_mingdong_data",guid,guid * 2)
			end
		
			return
		end
		
		if 9 == ts_id then
			self:LuaFnAddNewAgname(selfId, 1382)
			return
		end

		if 8 == ts_id then
			local exchange_guid = human:get_guid()
			skynet.send(".logdb", "lua", "update", {
				collection = "log_yuanbaopiao_value",
				selector = {guid = exchange_guid},
				-- update = {["$inc"] = {change_yuanbao = 100}},
				update = {["$inc"] = {use_yuanbao = 100}},
				upsert = true,
				multi = false,
			})
			return
		end
	
		if 7 == ts_id then
			local equip_container = human:get_equip_container()
			local prop_bag_container = human:get_prop_bag_container()
			local item_cls = require "item"
			local notice_detail_equip = packet_def.GCDetailEquipList.new()
			notice_detail_equip.m_objID = selfId
			notice_detail_equip.m_mode = 1
			notice_detail_equip.itemList = {}
			for i = 0,18 do
				local equip = equip_container:get_item(i)
				if not equip then
					if i ~= 0 and i ~= 9 and i ~= 10 then
						equip = item_cls.new()
					else
						equip = prop_bag_container:get_item(i)
					end
				else
					equip_container:set_item(i,nil)
					skynet.logi("equip.guid = ",equip.guid,"equip:get_index() = ",equip:get_index())
					local ret = packet_def.GCUnEquipResult.new()
					ret.equipPoint = i
					ret.result = 1
					ret.item_guid = equip.guid
					ret.item_index = equip.item_index
					ret.bagIndex = 255
					scene:send2client(human, ret)
				end
			end
			return
		end
	
		if 6 == ts_id then
		
			local configenginer = require "configenginer":getinstance()
			local shenbing_common_skill = configenginer:get_config("shenbing_common_skill")
			if shenbing_common_skill[10158012] then
				skynet.logi("shenbing_common_skill[10158012].id = ",shenbing_common_skill[10158012].id)
				skynet.logi("shenbing_common_skill[10158012].up[1][1] = ",shenbing_common_skill[10158012].up[1][1])
			else
				skynet.logi("Không có dữ liệu",shenbing_common_skill)
			end
			return
		end
		if 5 == ts_id then
				local posx,posz = self:GetWorldPos(selfId)
				local monsterid = self:LuaFnCreateMonster(0,posx + 2,posz + 2,3,0,809272)
				if monsterid and monsterid ~= -1 then
					self:SetCharacterName(monsterid, "张伏虎")
				end
				local monsterid = self:LuaFnCreateMonster(0,posx - 2,posz - 2,3,0,809272)
				if monsterid and monsterid ~= -1 then
					self:SetCharacterName(monsterid, "张笑师")
				end
			return
		end
		if 4 == ts_id then
			self:SetDiaoWenFineDraw(selfId, 0)
			return
		end
		if 3 == ts_id then
			local newpos = self:TryRecieveItem(selfId, 38000959)
			if newpos ~= -1 then
				-- if 0 == 0 then return end
				local container = human:get_prop_bag_container()
				local item = container:get_item(newpos)
				if item then
					item:set_param(4, 2100000000,"int")
					local msg = packet_def.GCItemInfo.new()
					msg.bagIndex = newpos
					msg.item = item:copy_raw_data()
					skynet.send(agent, "lua", "send2client", msg.xy_id, msg)
					-- self.scene:send2client(obj, msg)
					
				end
			end
			return
		end	
		if 2 == ts_id then
			local newpos = self:TryRecieveItem(selfId, 10124521)
			if newpos ~= -1 then
				-- if 0 == 0 then return end
				local obj = self.scene:get_obj_by_id(selfId)
				if not obj then
					return define.INVAILD_ID
				end
				local container = human:get_prop_bag_container()
				local item = container:get_item(newpos)
				if item then
					local curdate = self:GetDiffTime2Day2(-86400 * 30)
					item:set_param(0, curdate,"uint")
					local msg = packet_def.GCItemInfo.new()
					msg.bagIndex = newpos
					msg.item = item:copy_raw_data()
					skynet.send(agent, "lua", "send2client", msg.xy_id, msg)	
				end
			end
			return
		end
		if 1 == ts_id then
			self:notify_tips( selfId,"GG" )
			return
		end
	end
end
--GM代码测试或执行区2
function GmTool_Self:DebugB( selfId )
	if self.GmToolIsOpen then
		local rootlv = self:IsGM( selfId );
		if rootlv < self.CS_LevelMax then
			self:notify_tips( selfId,"Quyền GM của bạn không đủ cho mục này." )
			return
		end
		local human = self.scene:get_obj_by_id(selfId)
		if not human then return end
		local agent = human:get_agent()
		local scene = self:get_scene()
		local sceneId = scene:get_id()
		self:RestoreHp(selfId)
		self:RestoreMp(selfId)
		self:RestoreRage(selfId)
		for i = 1,200 do
			human:set_cool_down(i, 0)
		end
		local ts_id = -99   
		if 27 == ts_id then
			--1297
			local ret = self:CallDestSceneFunction(1297,808002,"StartActivity_Ex",365)
			if ret then
				skynet.logi("365 hoạt động đang mở")
			else
				skynet.logi("365 chưa mở")
			end
			
			return
		end
		if 26 == ts_id then
			local hour = self:GetHour()
			local minute = self:GetMinute() + 3
			if minute == 60 then
				hour = hour + 1
				minute = 0
			elseif minute > 60 then
				hour = hour + 1
				minute = minute - 60
			end
			
			local overdate = tonumber(os.date("%Y%m%d"))
			local params = {
				startmoney = 1000,     -- 起拍价(默认取self.startmoney)
				addmoney = 50,         -- 每次加价幅度(默认取self.addmoney)
				dresscount = 3,        -- 参与竞拍的时装数量(默认取#self.dressid)
				ridecount = 3,         -- 参与竞拍的坐骑数量(默认取#self.rideid)
				overdate = overdate,   -- 结束日期(默认当天日期)
				uiflag = 1,            -- 界面标识(1普通/2特殊，默认1)
				-- is_new = 0             -- 是否新拍卖(0否/1是[新拍卖则清空所有期数从第一期开始]，默认0)
				end_hour = hour,
				end_minute = minute,
			}
			self:CallScriptFunction(700489, "OpenJingPai", selfId, params)
			return
		end
		
		if 25 == ts_id then
			local timex = os.date("*t")
			local todaytime = os.time({year = timex.year, month = timex.month, day = timex.day, hour = 0, min = 0, sec = 0})  
			local curtime = os.time()
			local subtime = 86400 - (curtime - todaytime)
			skynet.logi("subtime = ",subtime,"curtime = ",curtime,"todaytime = ",todaytime)
			
			
		
			return
		end
		if 24 == ts_id then
			local node_list = utils.get_cluster_specific_server_by_server_alias(".world")
			for n, node in pairs(node_list) do
				skynet.logi(n," = ",node)
				-- cluster.call(node, ".gamed", "ban_user", account)
			end

		
			return
		end
		if 23 == ts_id then
			skynet.send(".ranking", "lua", "init")
			local tab = skynet.call(".ranking", "lua", "get_guid_value")
			if tab then
				for i,j in pairs(tab) do
					skynet.logi("[",i,"] = ",j)
				end
			else
				skynet.logi("Không có dữ liệu")
			
			end
			
			
			return
		end
		if 22 == ts_id then
			local endtime = self:GetHour() * 60 + self:GetMinute() + 2
			local overdate = tonumber(os.date("%Y%m%d"))
			local uiflag = 2
			
			local is_new = 0             -- 是否新花榜(0否/1是[新拍卖则清空所有期数从第一期开始]，默认0)
			is_new = is_new == 1
			local migration = self:ResetHuaBang(selfId,overdate,endtime,uiflag,is_new)
			if migration >= 1 and migration <= 3 then
				local topname = define.FLOWER_TOP_NAME[uiflag][migration] or "Bảng hoa"
				local msg = "#B"..topname.."#PBảng hoa mở ngay."
				self:AddGlobalCountNews_Fun(define.UPDATE_CLIENT_ICON_SRIPTID,"OnPlayerUpdateIconDisplay",msg)
				self:notify_tips( selfId,msg )
			else
				self:notify_tips( selfId,"Mở bảng hoa thất bại, xin kiểm có bảng hoa đang chạy hoặc đang ở cảnh liên server." )
			end
			
			return
		end
		if 21 == ts_id then
			skynet.logi("GmTool_Self:DebugB")
			skynet.call(".SCENE_123", "lua", "save_flower_top")
			return
		end
		if 20 == ts_id then
			skynet.logi("GmTool_Self:DebugB")
			local dmg_top_list = scene:get_dmg_top_list(100)
			for i,j in ipairs(dmg_top_list) do
				skynet.logi("dmg_top_list thứ",i,"tên:guid = ",j.guid,",damage = ",j.damage)
			end
			return
		end
		if 19 == ts_id then
			human:send_operate_result_msg(-102)
			skynet.logi("selfId = ",selfId)
			-- self:LuaFnGmKillObj(selfId, selfId)
			return
		end
		if 18 == ts_id then
			self:LuaFnResetWeekActiveDay(selfId)
		
			return
		end
		if 17 == ts_id then
			local mingdong
			if sceneId == 0 then
				mingdong = scene:get_mingdong_data()
			else
				-- local my_scene = string.format(".SCENE_0",sceneId)
				mingdong = skynet.call(".SCENE_0", "lua", "get_mingdong_data")
			end
			if mingdong then
				for i,j in pairs(mingdong) do
					skynet.logi("[",i,"] = ",j)
				end
			end
			return
		end
		
		
		if 16 == ts_id then
			local obj = self.scene:get_obj_by_id(selfId)
					local ret = packet_def.GCCharEquipment.new()
					ret.m_objID = selfId
					ret.flag = 0
					local equip_container = obj:get_equip_container()
					local item_index = define.INVAILD_ID
					local gemid = define.INVAILD_ID
					local visual = 0
					local equip = equip_container:get_item(define.HUMAN_EQUIP.HEQUIP_WEAPON)
					if equip then
						local weap_exterior_visual,weapon_id = obj:get_exterior_weapon_visual()
						if weap_exterior_visual then
							item_index = weapon_id
							visual = weap_exterior_visual
						else
							item_index = equip:get_index()
							local equip_data = equip:get_equip_data()
							local gem1 = equip_data:get_slot_gem(1)
							if gem1 > 0 then
								gemid = gem1
							end
							visual = equip_data:get_visual()
						end
					end
					ret:set_weapon(item_index,gemid,visual)
					item_index = define.INVAILD_ID
					gemid = define.INVAILD_ID
					visual = 0
					equip = equip_container:get_item(define.HUMAN_EQUIP.HEQUIP_CAP)
					if equip then
						item_index = equip:get_index()
						local equip_data = equip:get_equip_data()
						local gem1 = equip_data:get_slot_gem(1)
						if gem1 > 0 then
							gemid = gem1
						end
						visual = equip_data:get_visual()
					end
					ret:set_cap(item_index,gemid,visual)
					item_index = define.INVAILD_ID
					gemid = define.INVAILD_ID
					visual = 0
					equip = equip_container:get_item(define.HUMAN_EQUIP.HEQUIP_ARMOR)
					if equip then
						item_index = equip:get_index()
						local equip_data = equip:get_equip_data()
						local gem1 = equip_data:get_slot_gem(1)
						if gem1 > 0 then
							gemid = gem1
						end
						visual = equip_data:get_visual()
					end
					ret:set_armour(item_index,gemid,visual)
					item_index = define.INVAILD_ID
					gemid = define.INVAILD_ID
					visual = 0
					equip = equip_container:get_item(define.HUMAN_EQUIP.HEQUIP_CUFF)
					if equip then
						item_index = equip:get_index()
						local equip_data = equip:get_equip_data()
						local gem1 = equip_data:get_slot_gem(1)
						if gem1 > 0 then
							gemid = gem1
						end
						visual = equip_data:get_visual()
					end
					ret:set_cuff(item_index,gemid,visual)
					ret:set_unknow_6(-1,-1,0)
					item_index = define.INVAILD_ID
					gemid = define.INVAILD_ID
					visual = define.INVAILD_ID
					local gem2id,gem3id = define.INVAILD_ID,define.INVAILD_ID
					equip = equip_container:get_item(define.HUMAN_EQUIP.HEQUIP_FASHION)
					if equip then
						item_index = equip:get_index()
						local equip_data = equip:get_equip_data()
						local gem = equip_data:get_slot_gem(1)
						if gem > 0 then
							gemid = gem
						end
						gem = equip_data:get_slot_gem(2)
						if gem > 0 then
							gem2id = gem
						end
						gem = equip_data:get_slot_gem(3)
						if gem > 0 then
							gem3id = gem
						end
						visual = equip_data:get_visual()
					end
					ret:set_fasion(item_index,gemid,gem2id,gem3id,visual)
					item_index = define.INVAILD_ID
					gemid = define.INVAILD_ID
					visual = 0
					equip = equip_container:get_item(define.HUMAN_EQUIP.HEQUIP_WUHUN)
					if equip then
						item_index = equip:get_index()
						visual = obj:get_wuhun_visual()
					end
					ret:set_wuhun(item_index,visual)
					ret.flag = ret.flag | 0x80000000
					scene:send2client(obj, ret)
					scene:broadcast(obj, ret, true)
			
		
		
		
			return
		end
		
		
		
		
		if 15 == ts_id then
			-- local msg = self:ScriptGlobal_Format("#{YXQ_221123_01}","#{_ITEM10141004}")
			-- local msg = self:ScriptGlobal_Format("你背包内#{DLZH_20220120_22}","#{_ITEM10141004}")
			-- DLZH_20220120_22	#H%s0已过期，系统已自动删除
			local msg = string.contact_args("#{YXQ_221123_01","#{_ITEM10141004}").."}"
			local mail = {}
			mail.guid = define.INVAILD_ID
			mail.source = ""
			mail.portrait_id = define.INVAILD_ID
			mail.dest = human:get_name()
			mail.flag = define.MAIL_TYPE.MAIL_TYPE_SYSTEM
			mail.create_time = os.time()
			mail.content = msg
			skynet.send(".world", "lua", "send_mail", mail)
			self:notify_tips( selfId,msg )
			return
		end
		local world_pos = human:get_world_pos()
		if 14 == ts_id then
			local ma_func = require "ma_func"
			local value = ma_func:get_my_guid()
			skynet.logi("value = ",value)
		
			return
		end
		if 13 == ts_id then
			local str = string.format("scenecore:leave lưu dữ liệu không do nhân vật kích hoạt %s_%d",human:get_name(),human:get_guid())
			assert(false,str)
			return
		end
		if 12 == ts_id then
			local source_container = human:get_fasion_bag_container()
			for i = 0,100 do
				local item = source_container:get_item(i)
				if item then
					skynet.logi("[",i,"] = ",self:GetItemName(item.item_index),"(",item.item_index,")")
				end
			end
			local equip_container = human:get_equip_container()
			local equip = equip_container:get_item(16)
			if equip then
				skynet.logi("[Ô thời trang] = ",self:GetItemName(equip.item_index),"(",equip.item_index,")")
			end
			local select_index = human:get_fashion_depot_index()
			skynet.logi("[select_index] = ",select_index)
			return
		end
		
		
		
		if 11 == ts_id then
			human:send_refresh_attrib()
			return
		end
		if 10 == ts_id then
			-- self:get_scene():broad_char_equioment(human)
			
			local ret = packet_def.GCCharEquipment.new()
			ret.m_objID = selfId
			ret.flag = 0
			local item_index = define.INVAILD_ID
			local gemid = define.INVAILD_ID
			local visual = 0
			local gem2id,gem3id = define.INVAILD_ID,define.INVAILD_ID
			local equip_container = human:get_equip_container()
			local equip = equip_container:get_item(define.HUMAN_EQUIP.HEQUIP_FASHION)
			if equip then
				item_index = equip:get_index()
				local equip_data = equip:get_equip_data()
				local gem = equip_data:get_slot_gem(1)
				if gem > 0 then
					gemid = gem
				end
				gem = equip_data:get_slot_gem(2)
				if gem > 0 then
					gem2id = gem
				end
				gem = equip_data:get_slot_gem(3)
				if gem > 0 then
					gem3id = gem
				end
				visual = equip_data:get_visual()
			end
			ret:set_fasion(item_index,gemid,gem2id,gem3id,visual)
			self:get_scene():send2client(human, ret)
			self:get_scene():broadcast(human, ret, true)
			
			
			return
		end
		if 9 == ts_id then
			-- self:ActivateExteriorBackID(selfId,1,0)
				local posx,posz = self:GetWorldPos(selfId)
					local monsterid = self:LuaFnCreateMonster(50819,posx,posz,15,0,-1)
					if monsterid and monsterid ~= -1 then
						self:SetCharacterDieTime(monsterid, 3600000)
						  local human = self:get_scene():get_obj_by_id(selfId)
						  local name = human:get_name()
						self:SetCharacterName(monsterid, "Mộc trang ("..name..")")
					end
			return
		end
		if 8 == ts_id then
			local szItemTransfer = self:GetBagItemTransfer(selfId, 0)
			-- skynet.logi("szItemTransfer = ",szItemTransfer)
			
			local name = self:GetName(selfId)
			
			local msg = self:ScriptGlobal_Format("#{BGTS_220125_54}",name)
			
			
			self:BroadMsgByChatPipe(selfId, msg, 4)
			self:BeginEvent(self.script_id)
			self:AddText(msg)
			self:EndEvent()
			self:DispatchEventList(selfId,selfId)
			return
		end
		if 7 == ts_id then
			local posx,posz = world_pos.x,world_pos.y
			local dir = self:GetMissionDataEx(selfId,800)
			skynet.logi("dir = ",dir,"dir / 100 = ",dir / 100)
			dir = dir / 100
			local monsterid = self:LuaFnCreateMonster(0,posx,posz,3,0,-1,dir)
			
			self:SetCharacterName(monsterid, tostring(dir))
			return
		end
		
		
		
		-- self:notify_tips( selfId,"DebugB。" )
		if 6 == ts_id then
			-- self:notify_tips( selfId,"XX0" )
			-- self:clientwrite( selfId,0,flag )
			human:send_operate_result_msg(-75)		
			return
		end
		if 5 == ts_id then
			local ret = packet_def.GCPackage_SwapItem.new()
			ret.result = 1
			ret.index_from = 1
			ret.index_to = 2
			ret.count = 0
			-- self:send2client(obj, ret)
			skynet.send(agent, "lua", "send2client", ret.xy_id, ret)
			return
		end
		if 4 == ts_id then
			local ret = packet_def.GCUseEquipResult.new()
			ret.bagIndex = 255
			ret.equipPoint = 16
            ret.equip_guid = {server = 0, world = 0, mask = 0, series = 0}
            ret.item_guid = {server = 0, world = 0, mask = 0, series = 0}
            ret.equipTableIndex = 0
            ret.item_index = -1
            ret.unknow = 1
            ret.result = 2
			local agent = human:get_agent()
			skynet.send(agent, "lua", "send2client", ret.xy_id, ret)
		
			return
		end
		if 3 == ts_id then
			local scriptid = 999361
			local objid = selfId
			local tipnum = 0
			local tips = {}
			local text
			for i = 1,10 do
			tipnum = tipnum + 1
			text = gbk.fromutf8("request = {\n")
			tips[tipnum] = {
				flag = 2,
				str = text,
				type = 0,
				index = 0,
				script_id = scriptid,
				len = string.len(text),
				split = -1
			}
			end
			local ret = packet_def.GCScriptCommand.new()
			ret.m_nCmdID = 0
			ret.event = tips
			ret.target_id = objid
			ret.size = tipnum
			
			local agent = human:get_agent()
			skynet.send(agent, "lua", "send2client", ret.xy_id, ret)
			return
		end
		
		if 2 == ts_id then
			self:BeginUICommand()
			-- self:UICommand_AddInt(index - 1)
			self:UICommand_AddInt(selfId)
			self:EndUICommand()
			self:DispatchUICommand(selfId,89334001)
			return
		end
		if 1 == ts_id then
			
			local ret = packet_def.GCOrnamentsDataUpdate.new()
			--背
			ret.op_target = 0
			ret.op_code = 2
			--头
			-- ret.op_target = 1
			-- ret.op_code = 3
			
				ret.OrnamentsBackUnitNum = 3;
				ret.OrnamentsBackUnit = {
					{exteriorId = 1,x=128,y=128,z=128,state = 1,have_tip = 0},
					{exteriorId = 2,x=128,y=128,z=128,state = 2,have_tip = 0},
					{exteriorId = 3,x=128,y=128,z=128,state = 0,have_tip = 0},
				}
				ret.OrnamentsHeadUnitNum = 1
				ret.OrnamentsHeadUnit = {
					{exteriorId = 1,x=128,y=128,z=128,state = 4,have_tip = 0},
				
				}
			ret.CurOrnamentsBackId = 2
			ret.CurOrnamentsBackPos = 8421504
			ret.CurOrnamentsHeadId = 1
			ret.CurOrnamentsHeadPos = 8421504
			
			
			-- ret.OrnamentsBackUnit[1].exteriorId = 1
			-- ret.OrnamentsBackUnit[1].x = 1
			-- ret.OrnamentsBackUnit[1].y = 1
			-- ret.OrnamentsBackUnit[1].z = 1
			-- ret.OrnamentsBackUnit[1].z = 1
			
			
			-- ret.OrnamentsBackUnit[2].exteriorId = 2
			-- ret.OrnamentsBackUnit[2].x = 2
			-- ret.OrnamentsBackUnit[2].y = 2
			-- ret.OrnamentsBackUnit[2].z = 2
			-- ret.OrnamentsBackUnit[3].exteriorId = 3
			-- ret.OrnamentsBackUnit[3].x = 3
			-- ret.OrnamentsBackUnit[3].y = 3
			-- ret.OrnamentsBackUnit[3].z = 3
			-- ret.CurOrnamentsBackId = 1
			-- ret.nBackPosX = 128
			-- ret.nBackPosY = 128
			-- ret.nBackPosZ = 128
			-- self.CurOrnamentsBackPos = (self.nBackPosZ << 16) | (self.nBackPosY << 8) | self.nBackPosX
			local agent = human:get_agent()
			skynet.send(agent, "lua", "send2client", ret.xy_id, ret)
			-- self:send2client(human, ret)
			-- local scene = self:get_scene()
			-- scene:send2client(human, ret)
			return
		end
		
	end
end
--自身领GMBUFF
function GmTool_Self:ReceiveGmBuff( selfId, index, param1,param2,param3 )
	if self.GmToolIsOpen then
		local rootlv = self:IsGM( selfId );
		if index == 1 then
			if rootlv >= self.GiveSelfGmBuff then
				local gm_buff = 2690
				self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, gm_buff, 0)
				local myname = self:GetName(selfId)
				local logx = "Nhận BUFF:"..tostring(gm_buff)
				self:SetGmToolLog(selfId,"Nhận GM_BUFF",myname,logx)
				self:BeginUICommand()
				self:UICommand_AddInt(426042021)
				self:UICommand_AddStr("#G"..logx)
				self:EndUICommand()
				self:DispatchUICommand(selfId,426042021)
			end
		else
			if env == "local" or env == "debug" then
				if rootlv < self.CS_LevelMax then
					self:notify_tips( selfId,"Quyền GM của bạn không đủ cho mục này." )
					return
				end
			else
				if rootlv < self.ZS_LevelMax then
					self:notify_tips( selfId,"Quyền GM của bạn không đủ cho mục này." )
					return
				end
			end
			if index == 2 then
				local posx,posz = self:GetWorldPos(selfId)
				local monsterid = self:LuaFnCreateMonster(50819,posx,posz,7,0,-1)
				if monsterid and monsterid ~= -1 then
					skynet.logi("monsterid = ",monsterid)
					self:get_scene():reset_dmg_top_monid(monsterid)
					self:SetCharacterDieTime(monsterid, 3600000)
					local monster = self:get_scene():get_obj_by_id(monsterid)
					monster:set_unconstrained_monster(true)
					local human = self:get_scene():get_obj_by_id(selfId)
					local name = human:get_name()
					monster:set_name("Mộc trang ("..tostring(monsterid)..")")
					monster:set_title(name.."Tạo: biến mất sau 3600 giây")
				end
			elseif index == 3 then
				local human = self:get_scene():get_obj_by_id(selfId)
				if human then
					local cds = human:get_cool_downs()
					local count = 0
					for id, _ in pairs(cds) do
						human:set_cool_down(id, 0)
						count = count + 1
					end
					local myname = self:GetName(selfId)
					local logx = "Xóa hồi chiêu kỹ năng:"..tostring(count).."cái"
					self:SetGmToolLog(selfId,"Xóa bỏ thời gian hồi Kỹ năng",myname,logx)
					self:BeginUICommand()
					self:UICommand_AddInt(426042021)
					self:UICommand_AddStr("#G"..logx)
					self:EndUICommand()
					self:DispatchUICommand(selfId,426042021)
				end
			end
		end
	end
end
--对象自身操作
function GmTool_Self:SelfUse( selfId, selectindex, index1, index2, index3, TargetObjId )
	if not self.GmToolIsOpen then
		return
	elseif not selectindex or selectindex < 1 then
		return
	elseif not index1 or not index2 or not index3 then
		return
	end
	local need_rootlv = self.SelfOperation[selectindex].rootlv
	local selectname = self.SelfOperation[selectindex].selectname
	if not need_rootlv or need_rootlv < 1 then
		return
	elseif not selectname then
		return
	end
	local my_rootlv = self:IsGM(selfId)
	if my_rootlv < need_rootlv then
		self:notify_tips( selfId,"Quyền GM của bạn không đủ cho mục này." )
		return
	end
	local operateId = selfId;
	if TargetObjId and TargetObjId > 0 then
		local obj = self:get_scene():get_obj_by_id(TargetObjId);
		if obj then
			operateId = TargetObjId;
		end
	end
	local operateHuman = self:get_scene():get_obj_by_id(operateId)
	local loginfo,backinfo = "",""
	if selectindex == 1 then
		if index1 < 10000000 or index1 >= 70800000 then
			self:notify_tips( selfId,"Xin nhập đúng ID vật phẩm vào P1." )
			return
		elseif index2 < 1 then
			self:notify_tips( selfId,"Xin nhập số lượng đúng vào P2." )
			return
		end
		self:BeginAddItem()
		self:AddItem(index1,index2,false);
		if not self:EndAddItem(operateId) then
			self:notify_tips(selfId,"Túi hành trang không đủ chỗ")
			return
		end
		self:AddItemListToHuman(operateId)
		loginfo = "Đã nhận:"..self:GetItemName(index1)..tostring(index2).."cái"
		backinfo = "#G"..loginfo
	elseif selectindex == 2 then
		if index1 < 0 then
			self:notify_tips( selfId,"Xin nhập đúng ID danh hiệu vào P1." )
			return
		end
		self:LuaFnAddNewAgname(operateId, index1, false)
		loginfo = "Đã cấp danh hiệu ID:"..tostring(index1)
		backinfo = "#G"..loginfo
	elseif selectindex == 3 then
		local human = self:get_scene():get_obj_by_id(operateId)
		if not human then return end
		local cur_exp = human:get_mission_data_by_script_id(ScriptGlobal.MD_DFeng_Exp) or 0
		human:set_mission_data_by_script_id(ScriptGlobal.MD_DFeng_Exp, cur_exp + 200000000)
		human:refresh_dfeng_attrib()
		loginfo = "Đã nhận 200 triệu kinh nghiệm võ cảnh"
		backinfo = "#G"..loginfo
	elseif selectindex == 4 then
		local db = operateHuman and operateHuman.db
		if not db then
			self:notify_tips( selfId,"Đối tượng thuộc tính nhân vật không tồn tại." )
			return
		end
		local IA = define.ITEM_ATTRIBUTE
		local gm_bonus = db:get_db_attrib("gm_attr_bonus")
		if type(gm_bonus) ~= "table" then
			gm_bonus = {}
		end
		for _, ia in ipairs({
			IA.IATTRIBUTE_COLD_RESIST,
			IA.IATTRIBUTE_POISON_RESIST,
			IA.IATTRIBUTE_FIRE_RESIST,
			IA.IATTRIBUTE_LIGHT_RESIST,
		}) do
			local key = tostring(ia)
			gm_bonus[key] = (tonumber(gm_bonus[key]) or 0) + 50
		end
		db:set_db_attrib({gm_attr_bonus = gm_bonus})
		db:item_effect_flush()
		operateHuman:send_refresh_attrib()
		loginfo = "Đã tăng kháng Băng, Độc, Hỏa, Huyền mỗi loại 50 điểm"
		backinfo = "#G"..loginfo
	elseif selectindex == 5 then
		local db = operateHuman and operateHuman.db
		if not db then
			self:notify_tips( selfId,"Đối tượng thuộc tính nhân vật không tồn tại." )
			return
		end
		local IA = define.ITEM_ATTRIBUTE
		local gm_bonus = db:get_db_attrib("gm_attr_bonus")
		if type(gm_bonus) ~= "table" then
			gm_bonus = {}
		end
		local key = tostring(IA.IATTRIBUTE_DEX)
		gm_bonus[key] = (tonumber(gm_bonus[key]) or 0) + 1000
		db:set_db_attrib({gm_attr_bonus = gm_bonus})
		db:item_effect_flush()
		operateHuman:send_refresh_attrib()
		loginfo = "Đã tăng thân pháp nhân vật 1000 điểm"
		backinfo = "#G"..loginfo
	elseif selectindex == 6 then
		if index1 < 1 then
			self:notify_tips( selfId,"Xin nhập số đúng vào P1." )
			return
		end
		local HumanMoney = self:GetMoneyJZ(operateId)
		if HumanMoney + index1 > 144000000 then
			self:notify_tips( selfId,"Giao Tử quá nhiều, nhận thất bại." )
			return
		end
		self:AddMoneyJZ(operateId, index1)
		loginfo = "Đã nhận Giao Tử:"..tostring(index1)
		backinfo = "#GĐã nhận Giao Tử:#{_EXCHG"..tostring(index1).."}"
	elseif selectindex == 7 then
		if index1 < 1 then
			self:notify_tips( selfId,"Xin nhập số đúng vào P1." )
			return
		end
		local delmoney = index1
		local HumanMoney = self:LuaFnGetMoney(operateId)
		if HumanMoney < 1 then
			self:notify_tips( selfId,"Trên người không có Giao Tử." )
			return
		elseif HumanMoney < delmoney then
			delmoney = HumanMoney
		end
		local isok = self:LuaFnCostMoneyWithPriority(operateId, delmoney)
		if isok then
			loginfo = "Đã trừ Giao Tử:"..tostring(delmoney)
			backinfo = "#GĐã trừ Giao Tử:#{_EXCHG"..tostring(delmoney).."}"
		else
			loginfo = "Trừ Giao Tử:"..tostring(delmoney).."Thất bại"
			backinfo = "#cff0000Trừ Giao Tử:#{_EXCHG"..tostring(delmoney).."}thất bại"
		end
	elseif selectindex == 8 then
		if index1 < 1 then
			self:notify_tips( selfId,"Xin nhập số đúng vào P1." )
			return
		end
		local yuanbao = self:GetYuanBao(operateId)
		if yuanbao + index1 > 2000000000 then
			self:notify_tips( selfId,"Nguyên bảo quá nhiều." )
			return
		end
		self:CSAddYuanbao(operateId, index1)
		-- human:add_yuanbao(index1)
		loginfo = "Đã nhận nguyên bảo:"..tostring(index1)
		backinfo = "#G"..loginfo
	elseif selectindex == 9 then
		if index1 < 1 then
			self:notify_tips( selfId,"Xin nhập số đúng vào P1." )
			return
		end
		local yuanbao = self:GetYuanBao(operateId)
		local delyuanbao = index1
		if yuanbao < 1 then
			self:notify_tips( selfId,"Trên người không có nguyên bảo." )
			return
		elseif yuanbao < delyuanbao then
			delyuanbao = yuanbao
		end
		self:LuaFnCostYuanBao(operateId, delyuanbao)
		loginfo = "Đã trừ nguyên bảo:"..tostring(delyuanbao)
		backinfo = "#G"..loginfo
	elseif selectindex == 10 then
		if index1 < 1 then
			self:notify_tips( selfId,"Xin nhập số đúng vào P1." )
			return
		end
		local yuanbao = self:GetBindYuanBao(operateId)
		if yuanbao + index1 > 2000000000 then
			self:notify_tips( selfId,"Nguyên bảo khóa quá nhiều." )
			return
		end
		self:AddBindYuanBao(operateId,index1)
		loginfo = "Đã nhận nguyên bảo khóa:"..tostring(index1)
		backinfo = "#G"..loginfo
	elseif selectindex == 11 then
		if index1 < 1 then
			self:notify_tips( selfId,"Xin nhập số đúng vào P1." )
			return
		end
		local yuanbao = self:GetBindYuanBao(operateId)
		local delyuanbao = index1
		if yuanbao < 1 then
			self:notify_tips( selfId,"Trên người không có nguyên bảo khóa." )
			return
		elseif yuanbao < delyuanbao then
			delyuanbao = yuanbao
		end
		self:LuaFnCostBindYuanBao(operateId, delyuanbao)
		loginfo = "Đã trừ nguyên bảo khóa:"..tostring(delyuanbao)
		backinfo = "#G"..loginfo
	elseif selectindex == 12 then
		self:AddExp(operateId, 200000000)
		loginfo = "Đã nhận 200 triệu kinh nghiệm"
		backinfo = "#G"..loginfo
	elseif selectindex == 13 then
		if index1 < 1 then
			self:notify_tips( selfId,"Xin nhập số đúng vào P1." )
			return
		end
		local myexp = self:GetExp(operateId)
		local delexp = 0 - index1
		if myexp < 1 then
			self:notify_tips( selfId,"Hiện không có kinh nghiệm." )
			return
		elseif myexp < index1 then
			delexp = 0 - myexp
		end
		self:AddExp(operateId, delexp)
		loginfo = "Đã trừ kinh nghiệm:"..tostring(delexp)
		backinfo = "#G"..loginfo
	elseif selectindex == 14 then
		if index1 < 1 or index1 > 200 then
			self:notify_tips( selfId,"Xin nhập số đúng vào P1." )
			return
		end
		local curlv = self:GetLevel(operateId)
		if curlv == index1 then
			self:notify_tips( selfId,"Cấp hiện tại đã khớp, khỏi đặt." )
			return
		end
		-- self:SetLevel(selfId,index1)
		local obj = self:get_scene():get_obj_by_id(operateId)
		obj:set_level(index1)
		obj:wash_points()
		loginfo = "Đã đặt cấp nhân vật:"..tostring(index1).."cấp"
		backinfo = "#G"..loginfo
	elseif selectindex == 15 then
		if index1 < 0 or index1 > 12 then
			self:notify_tips( selfId,"Xin nhập số đúng vào P1." )
			return
		end
		local curmp = self:GetMenPai(operateId)
		if curmp == index1 then
			self:notify_tips( selfId,"Môn phái hiện tại đã khớp, khỏi đổi." )
			return
		elseif not curmp or curmp == -1 or curmp == 9 then
			self:LuaFnCancelImpactInSpecificImpact(operateId, 308)
			self:LuaFnJoinMenpai(operateId, index1)
		else
			self:LuaFnCancelImpactInSpecificImpact(operateId, 308)
			self:LuaFnChangeMenPai(operateId, index1)
			self:CallScriptFunction(888899, "UpdateRechargeMenPaiTitle", selfId, oldMenPai)
		end
		-- self:LuaFnJoinMenpai(operateId, index1)
		local mpname = {
		"少林",
		"明教",
		"丐帮",
		"武当",
		"Nga Mi",
		"星宿",
		"天龙",
		"天山",
		"逍遥",
		"无门派",
		"曼陀",
		"恶人谷",
		"慕容",
		}
		local idx = index1 + 1
		loginfo = "Đã vào:["..tostring(mpname[idx]).."]môn phái"
		backinfo = "#G"..loginfo
	elseif selectindex == 16 then
		local human = self:get_scene():get_obj_by_id(operateId)
		if not human then return end
		human:fix_xiulian_list()
		for i = 1, 11 do
			human.xiulian_list[i].level = 150
			human.xiulian_list[i].upper_limit = 150
		end
		human:send_xiulian_list()
		human:item_flush()
		loginfo = "Đã điểm đầy tu luyện tới cấp 150"
		backinfo = "#G"..loginfo
	elseif selectindex == 17 then
		if index1 < 1 then
			self:notify_tips( selfId,"Xin nhập số đúng vào P1." )
			return
		elseif index1 > self:GetLevel(operateId) then
			self:notify_tips( selfId,"Cấp tâm pháp không vượt cấp nhân vật được." )
			return
		end
		local xinfa_v1 = configenginer:get_config("xinfa_v1")
		local menpai = self:GetMenPai(operateId)
		for id, v1 in ipairs(xinfa_v1) do
			if v1.menpai == menpai then
				if self:HaveXinFa(operateId, id) ~= define.INVAILD_ID then
					self:LuaFnSetXinFaLevel(operateId, id, index1)
				end
			end
		end
		loginfo = "Nâng cấp tâm pháp môn phái đã lĩnh ngộ tới"..tostring(index1).."cấp"
		backinfo = "#G"..loginfo
	elseif selectindex == 18 then
		local list = operateHuman:get_impact_list()
		local imptab = {"#GTổng BUFF hiện tại:"..tostring(#list)}
		local impid
		for _, imp in ipairs(list) do
			impid = imp:get_data_index()
			table.insert(imptab,tostring(impid))
		end
		loginfo = "Đã tra số BUFF và BUFFID"
		backinfo = table.concat(imptab,"\n")
	elseif selectindex == 19 then
		if index1 < 0 then
			self:notify_tips( selfId,"Xin nhập số đúng vào P1." )
			return
		end
		local mdvalue = self:GetMissionData(operateId, index1)
		loginfo = "Đã tra MD:["..tostring(index1).."] = "..tostring(mdvalue)
		backinfo = "#G"..loginfo
	elseif selectindex == 20 then
		if index1 < 0 then
			self:notify_tips( selfId,"Xin nhập số đúng vào P1." )
			return
		end
		local mdvalue = self:GetMissionDataEx(operateId, index1)
		loginfo = "Đã tra EX:["..tostring(index1).."] = "..tostring(mdvalue)
		backinfo = "#G"..loginfo
	elseif selectindex == 21 then
		if index1 < 0 then
			self:notify_tips( selfId,"Xin nhập số đúng vào P1." )
			return
		end
		local mdvalue = self:GetMissionFlag(operateId, index1)
		loginfo = "Đã tra FLAG:["..tostring(index1).."] = "..tostring(mdvalue)
		backinfo = "#G"..loginfo
	elseif selectindex == 22 then
		if index1 < 0 then
			self:notify_tips( selfId,"Xin nhập số đúng vào P1." )
			return
		end
		
		self:notify_tips( selfId,"Chưa mở." )
		return
	elseif selectindex == 23 then
		if index1 < 0 then
			self:notify_tips( selfId,"Xin nhập số đúng vào P1." )
			return
		end
		
		self:notify_tips( selfId,"Chưa mở. Học kỹ năng" )
		return
	elseif selectindex == 24 then
		if index1 < 0 then
			self:notify_tips( selfId,"Xin nhập số đúng vào P1." )
			return
		end
		
		self:notify_tips( selfId,"Chưa mở. Xóa kỹ năng" )
		return
	elseif selectindex == 25 then
		if index1 < 1  then
			self:notify_tips( selfId,"Xin nhập số đúng vào P1." )
			return
		end
		self:LuaFnSendSpecificImpactToUnit(operateId, operateId, operateId, index1, 100)
		loginfo = "Đã nhận BUFF:"..tostring(index1)
		backinfo = "#G"..loginfo
	elseif selectindex == 26 then
		if index1 < 1 or index1 > 32767 then
			self:notify_tips( selfId,"Xin nhập số đúng vào P1." )
			return
		end
		self:LuaFnCancelSpecificImpact(operateId, index1)
		loginfo = "Đã xóa BUFF:"..tostring(index1)
		backinfo = "#G"..loginfo
	elseif selectindex == 27 then
		if index1 >= 0 then
			loginfo = "Đã tra cảnh:["..tostring(index1).."]thông tin tham số"
			local backtab = {loginfo.."#G"}
			local value
			backinfo = loginfo.."\n#G"
			for i = 0,31 do
				value = self:LuaFnGetCopySceneData_Param(index1,i)
				backinfo = "Param["..tostring(i).."] = "..tostring(value)
				table.insert(backtab,backinfo)
			end
			backinfo = table.concat(backtab,"\n")
		else
			local sceneId = self:GetSceneID()
			loginfo = "Đã tra cảnh:["..tostring(sceneId).."]thông tin tham số"
			local backtab = {loginfo.."#G"}
			local value
			backinfo = loginfo.."\n#G"
			for i = 0,31 do
				value = self:LuaFnGetCopySceneData_Param(i)
				backinfo = "Param["..tostring(i).."] = "..tostring(value)
				table.insert(backtab,backinfo)
			end
			backinfo = table.concat(backtab,"\n")
		end
	elseif selectindex == 28 then
		if index1 < 0 then
			x900066_Back( sceneId,selfId,"Xin nhập số đúng vào P1" )
			return
		elseif index2 < 1 or index2 > 999 then
			x900066_Back( sceneId,selfId,"Xin nhập số đúng vào P2" )
			return
		elseif index3 < 1 or index3 > 999 then
			x900066_Back( sceneId,selfId,"Xin nhập số đúng vào P3" )
			return
		end
		self:CallScriptFunction((400900), "TransferFunc", operateId, index1, index2, index3)
		loginfo = "Đã truyền tống tới:"..tostring(index1).."số cảnh ("..tostring(index2)..","..tostring(index3)..")"
		backinfo = "#G"..loginfo
	elseif selectindex == 29 then
		if index1 < 0 then
			self:notify_tips( selfId,"Xin nhập số đúng vào P1." )
			return
		end
		self:SetMissionData(operateId, index1, index2)
		local curvalue = self:GetMissionData(operateId, index1)
		loginfo = "Đã đặt MD:"..tostring(index1).." = "..tostring(curvalue)
		backinfo = "#G"..loginfo
	elseif selectindex == 30 then
		if index1 < 0 then
			self:notify_tips( selfId,"Xin nhập số đúng vào P1." )
			return
		end
		self:SetMissionDataEx(operateId, index1, index2)
		local curvalue = self:GetMissionDataEx(operateId, index1)
		loginfo = "Đã đặt EX:"..tostring(index1).." = "..tostring(curvalue)
		backinfo = "#G"..loginfo
	elseif selectindex == 31 then
		if index1 < 0 then
			self:notify_tips( selfId,"Xin nhập số đúng vào P1." )
			return
		elseif index2 < 0 then
			self:notify_tips( selfId,"Xin nhập số đúng vào P2." )
			return
		end
		self:SetMissionFlag(operateId, index1, index2)
		local curvalue = self:GetMissionFlag(operateId, index1)
		loginfo = "Đã đặt FLAG:"..tostring(index1).." = "..tostring(curvalue)
		backinfo = "#G"..loginfo
	elseif selectindex == 33 then
		local cds = operateHuman:get_cool_downs()
		local count = 0
		for id, _ in pairs(cds) do
			operateHuman:set_cool_down(id, 0)
			count = count + 1
		end
		local db = operateHuman.db
		if db then
			local IA = define.ITEM_ATTRIBUTE
			db.item_effect[IA.IATTRIBUTE_COLD_ATTACK] = (db.item_effect[IA.IATTRIBUTE_COLD_ATTACK] or 0) + 200000
			db.item_effect[IA.IATTRIBUTE_FIRE_ATTACK] = (db.item_effect[IA.IATTRIBUTE_FIRE_ATTACK] or 0) + 200000
			db.item_effect[IA.IATTRIBUTE_LIGHT_ATTACK] = (db.item_effect[IA.IATTRIBUTE_LIGHT_ATTACK] or 0) + 200000
			db.item_effect[IA.IATTRIBUTE_POISON_ATTACK] = (db.item_effect[IA.IATTRIBUTE_POISON_ATTACK] or 0) + 200000
			db:mark_attrib_dirty("att_cold")
			db:mark_attrib_dirty("att_fire")
			db:mark_attrib_dirty("att_light")
			db:mark_attrib_dirty("att_poison")
			db:mark_data_dirty_flag("att_cold")
			db:mark_data_dirty_flag("att_fire")
			db:mark_data_dirty_flag("att_light")
			db:mark_data_dirty_flag("att_poison")
			operateHuman:send_refresh_attrib()
		end
		loginfo = "Đã xóa mọi hồi chiêu kỹ năng ("..tostring(count).."cái)\\nĐã đặt 4 thuộc tính Băng Hỏa Huyền Độc là 200000"
		backinfo = "#G"..loginfo
	else
		self:notify_tips( selfId,"Nội dung chưa mở." )
		return
	end
	local myname = self:GetName(selfId)
	self:SetGmToolLog(selfId,selectname,myname,loginfo)
	self:notify_tips(selfId,backinfo)
	--回传UI
	self:BeginUICommand()
    self:UICommand_AddInt(426042021)
    self:UICommand_AddStr(backinfo)
    self:EndUICommand()
    self:DispatchUICommand(selfId,426042021)
end
--对象操作目标
function GmTool_Self:TargetUse( selfId, selectindex, index1, index2, index3 )
end
--对象操作在线角色
function GmTool_Self:WorldUse( selfId, selectindex, index1, index2, index3 )
	if not self.GmToolIsOpen then
		return
	elseif not selectindex or selectindex < 1 then
		return
	elseif not index1 or not index2 or not index3 then
		return
	end
	local need_rootlv = self.WorldOperation[selectindex].rootlv
	local selectname = self.WorldOperation[selectindex].selectname
	if not need_rootlv or need_rootlv < 1 then
		return
	elseif not selectname then
		return
	end
	local my_rootlv = self:IsGM(selfId)
	if env == "local" or env == "debug" then
		if my_rootlv < self.CS_LevelMax then
			self:notify_tips( selfId,"Quyền GM của bạn không đủ cho mục này." )
			return
		end
	else
		if my_rootlv < need_rootlv then
			self:notify_tips( selfId,"Quyền GM của bạn không đủ cho mục này." )
			return
		end
	end
	local human = self:get_scene():get_obj_by_id(selfId)
	local loginfo,backinfo = "",""
	if selectindex >= 1 and selectindex <= 7 then
		if selectindex ~= 5 then
			self:CallScriptFunction(700489,"Gm_to_Operate",selectindex,selectname)
		else
			self:CallScriptFunction(888819,"StartHuaBangTop",selfId,selectname)
		end
	elseif selectindex == 8 then
		self:GetActivityWar_ini( selfId, 2 )
	elseif selectindex == 9 then
		-- if not index1 or index1 < 1 then
			-- self:notify_tips( selfId,"index1 error。" )
			-- return
		-- end
		local isok,doccd = self:CallScriptFunction(900067,"AddMoneyCardCount",selfId,index1)
		if isok == -1 then
			return
		elseif isok == 0 then
			self:notify_tips( selfId,"Tạo thất bại." )
			return
		end
		local msg = string.format("Số CDK muốn thêm: %d, thực tạo: %d.\\nXin xem %s.",index1,isok,doccd)
		local myname = self:GetName(selfId)
		self:SetGmToolLog(selfId,selectname,myname,"Tạo CDK:"..tostring(isok))
		self:notify_tips(selfId,backinfo)
		--回传UI
		self:BeginUICommand()
		self:UICommand_AddInt(426042021)
		self:UICommand_AddStr(msg)
		self:EndUICommand()
		self:DispatchUICommand(selfId,426042021)
		return
	elseif selectindex == 14 then
		
		if index1 < 0 then
			self:notify_tips( selfId,"Tham số 1 bất thường." )
			return
		end
		local scriptid = index2 > 0 and index2 or -1
		local dir = index3 > 0 and index3 or nil
		local posx,posz = self:GetWorldPos(selfId)
		local monsterid = self:LuaFnCreateMonster(index1,posx,posz,3,0,scriptid,dir)
		if monsterid and monsterid ~= -1 then
			self:SetCharacterDieTime(monsterid,3600000)
			local monster = self:get_scene():get_obj_by_id(monsterid)
			local name = monster:get_name().."_id:"..monsterid
			-- self:SetCharacterName(monsterid,name)
			monster:set_name(name)
			monster:set_title("Biến mất sau 3600 giây")
			monster:set_unconstrained_monster(true)
			backinfo = "Tạo quái:"..monsterid
			loginfo = backinfo
		end
	elseif selectindex == 15 then
		local del_num = 0
		local monster_num = self:GetMonsterCount()
		for i = 1,monster_num do
			local objId = self:GetMonsterObjID(i)
			local obj = self:get_scene():get_obj_by_id(objId)
			local name = obj:get_name()
			if string.find(name,"_id:") then
				self:LuaFnDeleteMonster(objId)
				del_num = del_num + 1
			end
		end
		backinfo = "Xóa quái:"..del_num
		loginfo = backinfo
	elseif selectindex == 16 then
		if index1 < 0 then
			self:notify_tips( selfId,"Tham số 1 bất thường." )
			return
		end
		local posx,posz = self:GetWorldPos(selfId)
		local monsterid = self:LuaFnCreateMonster(index1,posx,posz,4,0,-1)
		if monsterid and monsterid ~= -1 then
			if index2 and index2 > 0 then
				self:LuaFnSetLifeTimeAttrRefix_MaxHP(monsterid,index2)
				self:RestoreHp(monsterid)
			end
			if index3 and index3 > 0 then
				self:SetCharacterDieTime(monsterid,index3 * 1000)
			end
			self:SetUnitReputationID(monsterid,monsterid,29)
		end
		backinfo = "Tạo BOSS:"..index1
		loginfo = backinfo
	elseif selectindex == 17 then
		local guids = {}
		if index1 > 0 then
			table.insert(guids,index1)
		elseif index2 > 0 then
			table.insert(guids,index2)
		elseif index3 > 0 then
			table.insert(guids,index3)
		end
		if #guids > 0 then
			for _,ids in ipairs(guids) do
				local save_lv = skynet.call(".gamed", "lua", "reset_save_lv", ids)
				local msg = string.format("Sửa số phiên bản dữ liệu guid:%d thành %s",ids,tostring(save_lv))
				self:notify_tips(selfId,msg)
			end
			backinfo = "Sửa số phiên bản nhân vật:"..#guids.."cái"
			loginfo = backinfo
		end
	end
	local myname = self:GetName(selfId)
	self:SetGmToolLog(selfId,selectname,myname,loginfo)
	if backinfo ~= "" then
		self:SetTip(selfId,backinfo)
	end
end

-- GM Console V4 ------------------------------------------------------------
-- These entry points use stable action names. They deliberately reject stale
-- target IDs instead of silently applying an operation to the GM character.

local GM_CONSOLE_ATTRS = {
	[6]=true,[7]=true,[8]=true,[9]=true,[10]=true,[11]=true,[12]=true,[13]=true,[14]=true,[15]=true,[16]=true,[17]=true,
	[42]=true,[43]=true,[44]=true,[45]=true,[46]=true,[54]=true,[55]=true,[56]=true,[57]=true,
}
local GM_ROLE_ACTIONS = {[1]="yuanbao",[2]="bind_yuanbao",[3]="exp",[4]="dfeng_exp",[5]="set_level",[6]="set_xinfa",[7]="change_menpai",[8]="max_dfeng",[9]="max_xinluo",[10]="query_buff",[11]="modify_attr",[12]="search_players",[13]="open_pet_gift"}
local GM_ITEM_ACTIONS = {
	[1]="item",
	[2]="equip_random",
	[3]="equip_custom",
	[4]="lingwu_random",
	[5]="lingwu_custom",
}
local GM_SCENE_ACTIONS = {[1]="teleport",[2]="summon",[3]="clear_summons"}
GmTool_Self.ConsoleWorldBuffers = GmTool_Self.ConsoleWorldBuffers or {}
GmTool_Self.ConsoleItemBuffers = GmTool_Self.ConsoleItemBuffers or {}
GmTool_Self.ConsoleSummons = GmTool_Self.ConsoleSummons or {}

local function gmConsoleSearchHash(text, first, count)
	local value = 0
	local folded = string.lower(text or "")
	local last = first + count - 1
	for index = first, last do value = (value * 131 + string.byte(folded, index)) % 2147483647 end
	return value
end

local function gmConsoleNameMatches(name, byteCount, wantedHash)
	local candidates = {tostring(name or "")}
	local ok, gbkName = pcall(gbk.fromutf8, candidates[1])
	if ok and gbkName and gbkName ~= candidates[1] then table.insert(candidates, gbkName) end
	for _, candidate in ipairs(candidates) do
		if string.len(candidate) >= byteCount then
			for first = 1, string.len(candidate) - byteCount + 1 do
				if gmConsoleSearchHash(candidate, first, byteCount) == wantedHash then return true end
			end
		end
	end
	return false
end

function GmTool_Self:ConsoleResolveTarget(selfId, targetId)
	if not self.GmToolIsOpen or self:IsGM(selfId) < 1 then
		self:notify_tips(selfId, "Quyền GM không đủ hoặc công cụ GM chưa mở.")
		return nil, nil
	end
	local operateId = selfId
	if targetId and targetId > 0 then operateId = targetId end
	local human = self:get_scene():get_obj_by_id(operateId)
	if not human or human:get_obj_type() ~= "human" then
		self:BackInfoToUI(selfId, "#RNgười chơi đích đã rời cảnh, xin khóa mục tiêu lại.")
		return nil, nil
	end
	return operateId, human
end

function GmTool_Self:ConsoleResult(selfId, text)
	self:BackInfoToUI(selfId, tostring(text or "Thao tác xong"))
end

function GmTool_Self:ConsoleRoleUse(selfId, action, p1, p2, targetId)
	action = GM_ROLE_ACTIONS[math.floor(tonumber(action) or 0)] or ""
	p1 = tonumber(p1) or 0
	p2 = tonumber(p2) or 0
	if action == "search_players" then
		if not self.GmToolIsOpen or self:IsGM(selfId) < 1 then return end
		local byteCount = math.floor(p1)
		local wantedHash = math.floor(p2)
		if byteCount < 1 or byteCount > 24 or wantedHash < 0 then
			self:ConsoleResult(selfId, "#RTham số tìm tên người chơi không hợp lệ."); return
		end
		local results = {}
		for objId, obj in pairs(self:get_scene():get_objs() or {}) do
			if obj and obj:get_obj_type() == "human" then
				local name = obj:get_name() or ""
				if gmConsoleNameMatches(name, byteCount, wantedHash) then table.insert(results, {id=objId,name=name}) end
			end
		end
		table.sort(results, function(left, right) return left.name < right.name end)
		while #results > 4 do table.remove(results) end
		local packed = {}
		for _, entry in ipairs(results) do table.insert(packed, tostring(entry.id).."|"..entry.name) end
		self:BackInfoToUI(selfId, "@GM_TARGET@"..table.concat(packed, ";"))
		return
	end
	local operateId, human = self:ConsoleResolveTarget(selfId, targetId)
	if not human then return end
	local result = ""

	if action == "yuanbao" then
		if p1 < 1 or self:GetYuanBao(operateId) + p1 > 2000000000 then self:ConsoleResult(selfId, "#RSố nguyên bảo không hợp lệ hoặc vượt hạn."); return end
		self:CSAddYuanbao(operateId, math.floor(p1)); result = "#GĐã thêm nguyên bảo "..math.floor(p1)
	elseif action == "bind_yuanbao" then
		if p1 < 1 or self:GetBindYuanBao(operateId) + p1 > 2000000000 then self:ConsoleResult(selfId, "#RSố nguyên bảo khóa không hợp lệ hoặc vượt hạn."); return end
		self:AddBindYuanBao(operateId, math.floor(p1)); result = "#GĐã thêm nguyên bảo khóa "..math.floor(p1)
	elseif action == "exp" then
		if p1 < 1 then self:ConsoleResult(selfId, "#RKinh nghiệm phải lớn hơn 0."); return end
		self:AddExp(operateId, math.floor(p1)); result = "#GĐã thêm kinh nghiệm nhân vật "..math.floor(p1)
	elseif action == "dfeng_exp" then
		if p1 < 1 then self:ConsoleResult(selfId, "#RKinh nghiệm võ cảnh phải lớn hơn 0."); return end
		local cur = human:get_mission_data_by_script_id(ScriptGlobal.MD_DFeng_Exp) or 0
		human:set_mission_data_by_script_id(ScriptGlobal.MD_DFeng_Exp, math.min(2000000000, cur + math.floor(p1)))
		human:refresh_dfeng_attrib(); result = "#GĐã thêm kinh nghiệm võ cảnh "..math.floor(p1)
	elseif action == "set_level" then
		p1 = math.floor(p1)
		if p1 < 1 or p1 > 200 then self:ConsoleResult(selfId, "#RPhạm vi cấp nhân vật 1 tới 200."); return end
		human:set_level(p1); human:wash_points(); result = "#GCấp nhân vật đã đặt thành "..p1
	elseif action == "set_xinfa" then
		p1 = math.floor(p1)
		if p1 < 1 or p1 > self:GetLevel(operateId) then self:ConsoleResult(selfId, "#RCấp tâm pháp phải từ 1 tới cấp nhân vật hiện tại."); return end
		local xinfa_v1 = configenginer:get_config("xinfa_v1")
		local menpai = self:GetMenPai(operateId)
		for id, cfg in ipairs(xinfa_v1) do
			if cfg.menpai == menpai and self:HaveXinFa(operateId, id) ~= define.INVAILD_ID then self:LuaFnSetXinFaLevel(operateId, id, p1) end
		end
		result = "#GĐã đặt tâm pháp môn phái đã lĩnh ngộ thành "..p1.." cấp"
	elseif action == "change_menpai" then
		p1 = math.floor(p1)
		if p1 < 0 or p1 > 15 then self:ConsoleResult(selfId, "#RChọn môn phái không hợp lệ."); return end
		local old = self:GetMenPai(operateId)
		if old == p1 then self:ConsoleResult(selfId, "#WMục tiêu hiện đã thuộc môn phái này."); return end
		self:LuaFnCancelImpactInSpecificImpact(operateId, 308)
		if not old or old == -1 or old == 9 then self:LuaFnJoinMenpai(operateId, p1) else self:LuaFnChangeMenPai(operateId, p1) end
		result = "#GChuyển môn phái xong"
	elseif action == "max_dfeng" then
		human:set_mission_data_by_script_id(ScriptGlobal.MD_DFeng_Open, 1)
		human:set_mission_data_by_script_id(ScriptGlobal.MD_DFeng_Exp, 0)
		human:set_mission_data_by_script_id(ScriptGlobal.MD_DFeng_Level, 200)
		human:set_mission_data_by_script_id(ScriptGlobal.MD_DFeng_LevelUp_Times, 200)
		human:refresh_dfeng_attrib()
		result = "#GVõ cảnh và thông mạch đã đặt tối đa"
	elseif action == "max_xinluo" then
		human:set_mission_data_by_script_id(ScriptGlobal.MD_DFeng_Open, 1)
		if (human:get_mission_data_by_script_id(ScriptGlobal.MD_DFeng_Level) or 0) < 200 then human:set_mission_data_by_script_id(ScriptGlobal.MD_DFeng_Level, 200) end
		if (human:get_mission_data_by_script_id(ScriptGlobal.MD_DFeng_LevelUp_Times) or 0) < 200 then human:set_mission_data_by_script_id(ScriptGlobal.MD_DFeng_LevelUp_Times, 200) end
		for slot = 1, 20 do
			human:set_dfeng_kw_slot_level(slot, 8)
			human:set_dfeng_kw_slot_active(slot, 4)
			human:set_dfeng_kw_slot_attrs(slot, 1, 2, 3)
		end
		human:refresh_dfeng_attrib(); human:send_dfeng_essence_kongwei(-1)
		result = "#G20 ô tâm lạc đã đặt hết cấp 8"
	elseif action == "query_buff" then
		local impacts = human:get_impact_list() or {}
		local ids = {}
		for _, impact in ipairs(impacts) do
			if #ids < 24 then table.insert(ids, tostring(impact:get_data_index())) end
		end
		result = "#GBUFF hiện tại:"..tostring(#impacts).." cái"
		if #ids > 0 then result = result.."  ID："..table.concat(ids, ",") end
		if #impacts > #ids then result = result.."  (chỉ hiện 24 cái đầu)" end
	elseif action == "modify_attr" then
		local code = math.floor(p1)
		local delta = math.floor(p2)
		if not GM_CONSOLE_ATTRS[code] or delta == 0 then self:ConsoleResult(selfId, "#RThuộc tính hoặc giá trị chỉnh không hợp lệ."); return end
		local db = human.db
		if not db then self:ConsoleResult(selfId, "#RDữ liệu thuộc tính nhân vật đích không dùng được."); return end
		local bonus = db:get_db_attrib("gm_attr_bonus")
		if type(bonus) ~= "table" then bonus = {} end
		local key = tostring(code)
		bonus[key] = (tonumber(bonus[key]) or 0) + delta
		db:set_db_attrib({gm_attr_bonus=bonus}); db:item_effect_flush(); human:send_refresh_attrib()
		result = "#GThuộc tính nhân vật đã chỉnh "..(delta > 0 and "+" or "")..delta
	elseif action == "open_pet_gift" then
		local opened = self:CallScriptFunction(999261, "OpenGmPetGift", selfId, operateId, 8888, 8888)
		if tonumber(opened) ~= 1 then self:ConsoleResult(selfId, "#RMở giao diện trân thú tự chọn thất bại.") end
		return
	else
		self:ConsoleResult(selfId, "#RThao tác nhân vật chưa rõ."); return
	end
	self:ConsoleResult(selfId, result)
end

function GmTool_Self:ConsoleItemCustomAttr(selfId, mode, action, itemId, bindValue, star, targetId, attrCode, attrValue)
	if not self.GmToolIsOpen or self:IsGM(selfId) < 1 then return end
	mode = math.floor(tonumber(mode) or 0)
	action = GM_ITEM_ACTIONS[math.floor(tonumber(action) or 0)] or ""
	itemId = math.floor(tonumber(itemId) or 0)
	star = math.floor(tonumber(star) or 0)
	targetId = math.floor(tonumber(targetId) or 0)
	if action ~= "equip_custom" and action ~= "lingwu_custom" then return end
	if mode == 1 then
		self.ConsoleItemBuffers[selfId] = {action=action,itemId=itemId,bind=tonumber(bindValue)==1,star=star,targetId=targetId,attrs={}}
		return
	end
	local buffer = self.ConsoleItemBuffers[selfId]
	if mode ~= 2 or not buffer or buffer.action ~= action or buffer.itemId ~= itemId or buffer.star ~= star or buffer.targetId ~= targetId then return end
	local code = math.floor(tonumber(attrCode) or -1)
	local value = math.floor(tonumber(attrValue) or 0)
	if code >= 0 and code <= 65 and value >= 0 and #buffer.attrs < 66 then table.insert(buffer.attrs, {code=code,value=value}) end
end

function GmTool_Self:ConsoleItemUse(selfId, action, itemId, count, bindValue, star, targetId)
	local operateId, human = self:ConsoleResolveTarget(selfId, targetId)
	if not human then self.ConsoleItemBuffers[selfId] = nil; return end
	action = GM_ITEM_ACTIONS[math.floor(tonumber(action) or 0)] or ""
	itemId = math.floor(tonumber(itemId) or 0)
	count = math.floor(tonumber(count) or 0)
	local bind = tonumber(bindValue) == 1
	star = math.floor(tonumber(star) or 0)
	local attrs = {}
	if action == "equip_custom" or action == "lingwu_custom" then
		local buffer = self.ConsoleItemBuffers[selfId]
		self.ConsoleItemBuffers[selfId] = nil
		if not buffer or buffer.action ~= action or buffer.itemId ~= itemId or buffer.bind ~= bind or buffer.star ~= star or buffer.targetId ~= math.floor(tonumber(targetId) or 0) then
			self:ConsoleResult(selfId, "#RDữ liệu thuộc tính tùy chỉnh thiếu, xin gửi lại."); return
		end
		attrs = buffer.attrs
	end
	if itemId < 10000000 or itemId >= 70800000 or not count or count < 1 then self:ConsoleResult(selfId, "#RVật phẩm hoặc số lượng không hợp lệ."); return end
	if action == "item" then
		count = math.min(999, count)
		local bagPos = self:TryRecieveItemWithCount(operateId, itemId, count, bind, nil, 0)
		if bagPos == nil or bagPos < 0 then self:ConsoleResult(selfId, "#RPhát thất bại, xin kiểm cấu hình vật phẩm và chỗ túi."); return end
		self:ConsoleResult(selfId, "#GĐã phát "..self:GetItemName(itemId).." x"..count); return
	end
	if action ~= "equip_random" and action ~= "equip_custom" and action ~= "lingwu_random" and action ~= "lingwu_custom" then
		self:ConsoleResult(selfId, "#RThao tác vật phẩm chưa rõ."); return
	end

	local equip_base = configenginer:get_config("equip_base")
	local ling_yu_base = configenginer:get_config("ling_yu_base")
	local base = equip_base and equip_base[itemId]
	local lingyu = ling_yu_base and ling_yu_base[itemId]
	local isLingwuAction = action == "lingwu_random" or action == "lingwu_custom"
	if not base then self:ConsoleResult(selfId, "#RBảng trang bị không có vật phẩm này."); return end
	if isLingwuAction and not lingyu then self:ConsoleResult(selfId, "#RTrang bị chọn không phải Linh Võ."); return end
	if not isLingwuAction and lingyu then self:ConsoleResult(selfId, "#RVật chọn là Linh Võ, xin chuyển sang trang Linh Võ để phát."); return end
	if not isLingwuAction and (star < 1 or star > 9) then self:ConsoleResult(selfId, "#RSao trang bị thường phải từ 1 tới 9."); return end

	local bagPos = self:TryRecieveItemWithCount(operateId, itemId, 1, bind, nil, 0)
	if bagPos == nil or bagPos < 0 then self:ConsoleResult(selfId, "#RPhát trang bị thất bại, xin kiểm chỗ trống túi."); return end
	local item = human:get_prop_bag_container():get_item(bagPos)
	if not item or item:get_serial_class() ~= define.ITEM_CLASS.ICLASS_EQUIP then
		self:EraseItem(operateId, bagPos)
		self:ConsoleResult(selfId, "#RVật chọn không phải trang bị, đã hủy phát."); return
	end
	local equip = item:get_equip_data()
	if isLingwuAction and equip:get_equip_type() ~= 3 then
		self:EraseItem(operateId, bagPos)
		self:ConsoleResult(selfId, "#RTrang bị chọn không phải Linh Võ, đã hủy phát."); return
	end
	if not isLingwuAction and equip:get_equip_type() ~= 0 then
		self:EraseItem(operateId, bagPos)
		self:ConsoleResult(selfId, "#RTrang bị chọn không phải đồ thường, đã hủy phát."); return
	end

	if action == "equip_random" then
		local params, types, values = item_operator:gen_equip_attrs(itemId, 0, star)
		equip:set_attr_count(#types)
		equip:set_attr_value(values)
		equip:set_attr_type(params.attr_type)
		equip:set_attr_types(types)
		equip:set_quality(star)
		equip:set_dur(params.max_dur)
		equip:set_max_dur(params.max_dur)
		self:LuaFnRefreshItemInfo(operateId, bagPos)
		self:ConsoleResult(selfId, "#GĐã phát ngẫu nhiên theo bảng"..tostring(star).."sao trang bị:"..self:GetItemName(itemId)); return
	elseif action == "lingwu_random" then
		self:ConsoleResult(selfId, "#GĐã phát ngẫu nhiên theo bảng"..(isLingwuAction and "Linh Võ:" or "Trang bị:")..self:GetItemName(itemId)); return
	end
	local minAttrCount = isLingwuAction and 1 or math.max(0, tonumber(base["属性条数min"]) or 0)
	local maxAttrCount = isLingwuAction and 3 or math.max(minAttrCount, tonumber(base["属性条数max"]) or 0)
	if #attrs < minAttrCount or #attrs > maxAttrCount then
		self:EraseItem(operateId, bagPos)
		self:ConsoleResult(selfId, "#RSố dòng thuộc tính tùy chỉnh phải là"..tostring(minAttrCount).."Chí"..tostring(maxAttrCount).."dòng, đã hủy phát."); return
	end

	local allowed = {}
	if isLingwuAction then
		local ling_yu_attr_rule = configenginer:get_config("ling_yu_attr_rule")
		local ling_yu_attr_value = configenginer:get_config("ling_yu_attr_value")
		local rule = ling_yu_attr_rule and ling_yu_attr_rule[lingyu.equip_point]
		if not rule or not rule.attr_odds then
			self:EraseItem(operateId, bagPos)
			self:ConsoleResult(selfId, "#RLinh Võ này không có quy tắc thuộc tính dùng được, đã hủy phát."); return
		end
		for index, odd in pairs(rule.attr_odds) do
			local code = tonumber(index) and tonumber(index) - 1 or -1
			local valueRule = ling_yu_attr_value and ling_yu_attr_value[code]
			if code >= 0 and code <= 65 and tonumber(odd) and tonumber(odd) > 0 and valueRule and valueRule.values then
				local minValue = lingyu.class == 0 and 0 or tonumber(valueRule.values[lingyu.class])
				local maxValue = tonumber(valueRule.values[lingyu.class + 1])
				if minValue and maxValue then
					if minValue > maxValue then minValue, maxValue = maxValue, minValue end
					allowed[code] = {min=math.floor(minValue), max=math.floor(maxValue)}
				end
			end
		end
	else
		local item_seg_value = configenginer:get_config("item_seg_value")
		local item_seg_rate = configenginer:get_config("item_seg_rate")
		local valueRule = item_seg_value and item_seg_value[base["起始数值段"]]
		for _, name in ipairs(base.ex_attrs or {}) do
			local code = define.EQUIP_ATTR[name]
			local baseValue = valueRule and tonumber(valueRule[name])
			local minRate = item_seg_rate and item_seg_rate[star] and tonumber(item_seg_rate[star][name])
			local maxRate = item_seg_rate and item_seg_rate[star + 1] and tonumber(item_seg_rate[star + 1][name]) or minRate
			if code and baseValue and minRate and maxRate then
				local minValue = math.max(1, math.ceil(baseValue * minRate / 100))
				local maxValue = math.min(32767, math.max(minValue, math.ceil(baseValue * maxRate / 100)))
				allowed[code] = {min=minValue, max=maxValue}
			end
		end
	end

	local used = {}
	for _, attr in ipairs(attrs) do
		local range = allowed[attr.code]
		if used[attr.code] or not range or attr.value < range.min or attr.value > range.max then
			self:EraseItem(operateId, bagPos)
			self:ConsoleResult(selfId, used[attr.code] and "#RThuộc tính tùy chỉnh không được trùng, đã hủy phát." or "#RTrường hoặc giá trị tùy chỉnh vượt phạm vi bảng của trang bị, đã hủy phát."); return
		end
		used[attr.code] = true
	end
	table.sort(attrs, function(left, right) return left.code < right.code end)

	if isLingwuAction then
		local types = {define.INVAILD_ID, define.INVAILD_ID, define.INVAILD_ID}
		local values, levels = {0, 0, 0}, {0, 0, 0}
		for index, attr in ipairs(attrs) do types[index], values[index] = attr.code, attr.value end
		equip:set_ling_yu_attr_types(types)
		equip:set_ling_yu_attr_value(values)
		equip:set_ling_yu_attrs_enhancement_level(levels)
	else
		local types, values, attrMask = {}, {}, 0
		for _, attr in ipairs(attrs) do
			table.insert(types, attr.code)
			table.insert(values, attr.value)
			attrMask = attrMask | (1 << attr.code)
		end
		equip:set_attr_count(#types)
		equip:set_attr_value(values)
		equip:set_attr_type(attrMask)
		equip:set_attr_types(types)
		equip:set_quality(star)
	end
	self:LuaFnRefreshItemInfo(operateId, bagPos)
	self:ConsoleResult(selfId, "#GĐã phát tùy chỉnh"..(isLingwuAction and "Linh võ" or "Trang bị").."："..self:GetItemName(itemId))
end

-- 2026-09-11: GM Tool phía client gửi ID lấy từ SceneDefineEx (ID client). Nếu ID đó không phải cảnh server
-- đang hoạt động thì thử ánh xạ qua clientres của SceneInfo.ini.
function GmTool_Self:ConsoleResolveSceneId(sceneId)
	sceneId = math.floor(tonumber(sceneId) or -1)
	local scene_info = configenginer:get_config("scene_info") or {}
	local info = scene_info[string.format("scene%d", sceneId)]
	if info and tonumber(info.active) == 1 and tonumber(info.type) ~= 1 then
		return sceneId
	end
	local best
	for key, si in pairs(scene_info) do
		if tonumber(si.clientres) == sceneId and tonumber(si.active) == 1 and tonumber(si.type) == 0 then
			local id = tonumber(string.match(key, "scene(%d+)"))
			if id and (not best or id < best) then best = id end
		end
	end
	if best then
		return best, " (ID client "..sceneId.." → cảnh server "..best..")"
	end
	if info then
		return sceneId -- có trong SceneInfo.ini nhưng chưa active: để TransferFunc báo lỗi rõ ràng
	end
	return nil
end

function GmTool_Self:ConsoleSceneUse(selfId, action, p1, p2, p3, targetId)
	action = GM_SCENE_ACTIONS[math.floor(tonumber(action) or 0)] or ""
	local operateId, human = self:ConsoleResolveTarget(selfId, (action == "summon" or action == "clear_summons") and 0 or targetId)
	if not human then return end
	if action == "teleport" then
		local sceneId, x, z = math.floor(tonumber(p1) or -1), math.floor(tonumber(p2) or 0), math.floor(tonumber(p3) or 0)
		if sceneId < 0 or x < 0 or z < 0 then self:ConsoleResult(selfId, "#RCảnh hoặc tọa độ không hợp lệ."); return end
		local serverSceneId, note = self:ConsoleResolveSceneId(sceneId)
		if not serverSceneId then
			self:ConsoleResult(selfId, "#RCảnh "..sceneId.." không có trên máy chủ (không phải ID cảnh server và không khớp clientres nào).")
			return
		end
		self:CallScriptFunction(400900, "TransferFunc", operateId, serverSceneId, x, z)
		self:ConsoleResult(selfId, "#GĐã truyền tống tới cảnh "..serverSceneId..(note or "").." ("..x..","..z..")")
	elseif action == "summon" then
		local monsterId = math.floor(tonumber(p1) or -1)
		local count = math.max(1, math.min(20, math.floor(tonumber(p2) or 1)))
		local baseAi = math.floor(tonumber(p3) or 3)
		if monsterId < 0 then self:ConsoleResult(selfId, "#RCấu hình quái không hợp lệ."); return end
		local x, z = self:GetWorldPos(selfId)
		local created = 0
		local sceneId = self:get_scene():get_id()
		local summonState = self.ConsoleSummons[selfId]
		if not summonState or summonState.sceneId ~= sceneId then summonState = {sceneId=sceneId,ids={}} end
		for i = 1, count do
			local id = self:LuaFnCreateMonster(monsterId, x, z, baseAi, 0, -1)
			if id and id ~= -1 then
				created = created + 1; self:SetCharacterDieTime(id, 3600000)
				table.insert(summonState.ids, id)
				local monster = self:get_scene():get_obj_by_id(id)
				if monster then monster:set_title("GM triệu hồi: biến mất sau 3600 giây"); monster:set_unconstrained_monster(true) end
			end
		end
		self.ConsoleSummons[selfId] = summonState
		self:ConsoleResult(selfId, "#GĐã tạo đối tượng cảnh "..created.." cái")
	elseif action == "clear_summons" then
		local deleted = 0
		local summonState = self.ConsoleSummons[selfId]
		local ids = summonState and summonState.sceneId == self:get_scene():get_id() and summonState.ids or {}
		for _, objId in ipairs(ids) do
			local obj = self:get_scene():get_obj_by_id(objId)
			if obj and obj:get_obj_type() ~= "human" then self:LuaFnDeleteMonster(objId); deleted = deleted + 1 end
		end
		self.ConsoleSummons[selfId] = {}
		self:ConsoleResult(selfId, "#GĐã xóa đối tượng GM này tạo trong cảnh "..deleted.." cái")
	else self:ConsoleResult(selfId, "#RThao tác cảnh chưa rõ."); return end
end

local function gmConsoleIsUtf8(text)
	local index = 1
	local length = string.len(text or "")
	while index <= length do
		local first = string.byte(text, index)
		local count = 0
		if first <= 0x7F then count = 0
		elseif first >= 0xC2 and first <= 0xDF then count = 1
		elseif first >= 0xE0 and first <= 0xEF then count = 2
		elseif first >= 0xF0 and first <= 0xF4 then count = 3
		else return false end
		if index + count > length then return false end
		for offset = 1, count do
			local value = string.byte(text, index + offset)
			if value < 0x80 or value > 0xBF then return false end
		end
		if count == 2 then
			local second = string.byte(text, index + 1)
			if (first == 0xE0 and second < 0xA0) or (first == 0xED and second > 0x9F) then return false end
		elseif count == 3 then
			local second = string.byte(text, index + 1)
			if (first == 0xF0 and second < 0x90) or (first == 0xF4 and second > 0x8F) then return false end
		end
		index = index + count + 1
	end
	return true
end

function GmTool_Self:ConsoleWorldUse(selfId, mode, p1, p2, p3, p4, p5, p6, p7, p8, p9)
	if not self.GmToolIsOpen or self:IsGM(selfId) < 1 then self:notify_tips(selfId, "Quyền GM không đủ hoặc công cụ GM chưa mở."); return end
	mode = math.floor(tonumber(mode) or 0)
	if mode == 1 then
		local total = math.floor(tonumber(p1) or 0)
		if total < 1 or total > 240 then self:ConsoleResult(selfId, "#RNội dung thông báo trống hoặc quá dài."); return end
		self.ConsoleWorldBuffers[selfId] = {total=total, chunks={}}
		return
	elseif mode == 2 then
		local buffer = self.ConsoleWorldBuffers[selfId]
		local index = math.floor(tonumber(p1) or 0)
		if not buffer or index < 1 or index > 30 then self:ConsoleResult(selfId, "#RThứ tự tải thông báo không hợp lệ."); return end
		buffer.chunks[index] = {tonumber(p2) or 0,tonumber(p3) or 0,tonumber(p4) or 0,tonumber(p5) or 0,tonumber(p6) or 0,tonumber(p7) or 0,tonumber(p8) or 0,tonumber(p9) or 0}
		return
	elseif mode ~= 3 then
		self:ConsoleResult(selfId, "#RThao tác toàn server chưa rõ."); return
	end
	local buffer = self.ConsoleWorldBuffers[selfId]
	if not buffer or buffer.total ~= math.floor(tonumber(p1) or 0) then self:ConsoleResult(selfId, "#RDữ liệu thông báo thiếu, xin gửi lại."); return end
	local bytes = {}
	local neededChunks = math.floor((buffer.total + 7) / 8)
	for index = 1, neededChunks do
		local chunk = buffer.chunks[index]
		if not chunk then self.ConsoleWorldBuffers[selfId] = nil; self:ConsoleResult(selfId, "#RThiếu phân khối dữ liệu thông báo, xin gửi lại."); return end
		for _, byteValue in ipairs(chunk) do
			local byte = math.floor(byteValue)
			if byte < 0 or byte > 255 then
				self.ConsoleWorldBuffers[selfId] = nil
				self:ConsoleResult(selfId, "#RDữ liệu thông báo chứa byte không hợp lệ, xin gửi lại."); return
			end
			if #bytes < buffer.total then table.insert(bytes, string.char(byte)) end
		end
	end
	self.ConsoleWorldBuffers[selfId] = nil
	local message = table.concat(bytes)
	if string.find(message, string.char(0), 1, true) then
		self:ConsoleResult(selfId, "#RDữ liệu thông báo chứa byte rỗng, xin gửi lại.")
		return
	end
	-- The UTF-8 GM interface bypasses the native chat encoder. GCChat writes
	-- content verbatim, so normalize UTF-8 input to the client's GBK wire text.
	if gmConsoleIsUtf8(message) then
		local ok, converted = pcall(gbk.fromutf8, message)
		if not ok or not converted or converted == "" then
			self:ConsoleResult(selfId, "#RChuyển mã chữ loa nhỏ thất bại."); return
		end
		message = converted
	end
	local msg = packet_def.GCChat.new()
	local speaker = self:get_scene():get_obj_by_id(selfId)
	if not speaker then self:ConsoleResult(selfId, "#RNgười gửi loa nhỏ không tồn tại."); return end
	msg.ChatType = define.ENUM_CHAT_TYPE.CHAT_TYPE_SPEAKER
	msg:set_source_name(speaker:get_name())
	msg.Sourceid = selfId
	msg.unknow_3 = 1
	msg:set_content(message)
	skynet.send(".world", "lua", "multicast", msg)
	self:ConsoleResult(selfId, "#GLoa nhỏ đã gửi.")
end

return GmTool_Self
