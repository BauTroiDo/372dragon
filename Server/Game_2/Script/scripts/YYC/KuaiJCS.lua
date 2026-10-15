--快捷传送UI
--呦西1509688459
--转换为新版服务端Lua写法

local gbk = require "wire_charset"
local define = require "define"
local class = require "class"
local script_base = require "script_base"
local KuaiJCS = class("KuaiJCS", script_base)
KuaiJCS.script_id = 890096

-- 传送配置数据
local ChuansongList = {}

-- 城市传送
ChuansongList[1] = {
    "城市传送",
    "Ở đây chọn được thành hoặc bang phái muốn tới",
    {
        {"Dịch trạm Lạc Dương", 0, 140, 181, 10}, {"Tô ChâuDịch trạm", 1, 113, 161, 10}, 
		{"Cửa hàng Thợ rèn Tô Châu", 1, 236, 128, 10}, 
        {"Đại LýDịch trạm", 2, 241, 141, 10}, {"束河古镇", 420, 200, 211, 10},
        {"Cổ thành Lâu Lan", 186, 288, 136, 0}, {"", 420, 280, 118, 10},--
        {"", 420, 280, 118, 10}, {"", 420, 280, 118, 10},
        {"", 420, 280, 118, 10}, 
        {"逍遥", 14, 67, 145, 0}, {"丐帮", 10, 91, 116, 0},
        {"明教", 11, 98, 167, 0}, {"武当", 12, 103, 140, 0},
        {"天山", 17, 95, 120, 0}, {"Nga Mi", 15, 89, 144, 0},
        {"星宿", 16, 96, 152, 0}, {"天龙", 13, 96, 120, 0},
        {"少林", 9, 95, 137, 0}, {"曼陀山庄", 184, 140, 160, 0},
		{"恶人谷", 987, 128, 155, 0}, {"慕容山庄", 1358, 28, 133, 10}, 
    }
}

-- 快速练级
ChuansongList[2] = {
    "Luyện Cấp Nhanh",
    "",
    {
        {"Ma Nhai Động", 170, 26, 216, 10},-- {"南海马贼", 34, 110, 25, 10},{"苗疆马贼", 29, 66, 44, 10},
		{"", 420, 280, 118, 10},{"", 420, 280, 118, 10},
        {"", 420, 280, 118, 10}, {"", 420, 280, 118, 10},{"Cổ Mộ tầng 1", 159, 68, 95, 10},
        {"Cổ Mộ tầng 2", 160, 87, 89, 10}, {"Cổ Mộ tầng 3", 161, 13, 25, 10},
        {"Cổ Mộ tầng 4", 162, 102, 18, 10}, {"Cổ Mộ tầng 5", 163, 24, 24, 10},
        {"Cổ Mộ tầng 6", 164, 65, 108, 10}, {"Cổ Mộ tầng 7", 165, 28, 107, 10},
        {"Cổ Mộ tầng 8", 166, 14, 14, 10}, {"Cổ Mộ tầng 9", 167, 20, 18, 10},
        {"", 420, 280, 118, 10}, {"Địa Cung tầng 1", 400, 227, 226, 10},
        {"Địa Cung tầng 2", 401, 223, 225, 10}, {"Địa Cung tầng 3", 402, 231, 218, 10},--{"高昌迷宫", 520, 83, 40, 90}, {"昆仑山", 433, 112, 120, 90},
        {"", 420, 280, 118, 10}, {"", 420, 280, 118, 10},
        {"Thánh Hỏa Cung", 202, 55, 57, 90},{"Hãn Huyết Lĩnh", 432, 90, 86, 90},--{"塔克拉玛干", 427, 38, 24, 90},
		{"Côn Luân Phúc Địa", 434, 93, 37, 90},{"Địa Cung tầng 4", 1303, 132, 102, 10}, {"", 420, 280, 118, 10},
		--{"黄龙马贼", 23, 48, 277, 10}{"撒马尔罕", 201, 111, 34, 90},
        --{"南诏马贼", 28, 184, 54, 10},{"苗疆马贼", 29, 66, 44, 10},{"南海马贼", 34, 135, 46, 10},{"琼州马贼", 35, 88, 118, 10}
    }
}

-- BOSS活动
ChuansongList[3] = {
    "#cff66ccHoạt động BOSS",
    "",
    {
        {"#cff66ccNhóm BOSS Diêm Hồ", 415, 226, 169, 80},
        -- {"武夷冰妖", 32, 77, 141, 10},
        -- {"玄武蛤蟆", 39, 180, 53, 10}, {"苍山金刚", 25, 67, 249, 10},
        -- {"草原小白", 20, 77, 122, 10}, {"", 420, 280, 118, 10},
        -- {"圣兽山龙龟", 158, 164, 47, 10},{"圣兽山宝箱", 158, 141, 113, 10},{"", 420, 280, 118, 10},{"", 420, 280, 118, 10},{"", 420, 280, 118, 10},
        -- {"沉月岛", 707, 59, 59, 60},{"地火岛", 708, 198, 58, 60},{"繁林岛", 709, 174, 146, 10},{"", 420, 280, 118, 10},{"", 420, 280, 118, 10},
        --  {"熔岩蜃景", 710, 183, 73, 10},{"密林蜃景", 711, 185, 86, 10},{"清湖蜃景", 712, 176, 206, 10}
		--{"沉月岛", 707, 132, 96, 90}, {"清湖蜃景", 710, 197, 208, 90}, {"密林蜃景", 711, 214, 83, 90}, {"熔岩蜃景", 712, 68, 186, 90}
    }
}

-- -- 副本传送		
-- ChuansongList[4] = {
--     "副本传送",
--     "",
--     {
      
--         {"缥缈峰", 186, 190, 222, 75}
--     }
-- }

-- 全局配置
local g_Yinpiao = 40002000
local g_Impact_NotTransportList = {} -- 禁止传送的Impact
local g_TalkInfo_NotTransportList = {"#{GodFire_Info_062}", "#{XSHCD_20080418_099}"} -- 禁止传送的提示信息

-- NPC交互入口
function KuaiJCS:OnDefaultEvent(selfId, targetId)
 --self:NotifyTip(selfId, "此功能只允许在主城使用。")
    self:CallScriptFunction(64, "Restore_hpmp", selfId, targetId)
	self:BeginEvent(self.script_id)
	self:AddText("#cFFFF00Chào mừng dùng dịch vụ truyền tống!#P")
	self:AddNumText("Truyền tống vạn năng#P", 2, 1)
	self:EndEvent()
	self:DispatchEventList(selfId, targetId)
end

-- 通知提示
function KuaiJCS:NotifyTip(selfId, Msg)
    self:BeginEvent(self.script_id)
    self:AddText(Msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

-- 快捷传送事件处理
function KuaiJCS:TransPort(selfId, Type, Index, arg)
    local sceneId = self:GetSceneID()
    
    -- -- 检查是否在主城
    -- if sceneId > 2 then
    --     self:NotifyTip(selfId, "此功能只允许在主城使用。")
    --     return
    -- end

    if Type == 0 then -- 显示主菜单
        local menuTitles = ""
        local locationNames = ""
        
        -- 构建菜单标题
        for i = 1, #ChuansongList do
            menuTitles = menuTitles .. ChuansongList[i][1] .. ","
        end
        
        -- 构建地点名称
        for j = 1, #ChuansongList[Index][3] do
            locationNames = locationNames .. ChuansongList[Index][3][j][1] .. ","
        end
        
        -- 发送UI命令
        self:BeginUICommand()
        self:UICommand_AddInt(Index)
        self:UICommand_AddStr(menuTitles)
        self:UICommand_AddStr(ChuansongList[Index][2])
        self:UICommand_AddStr(locationNames)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 20170502)
        
    elseif Type == 1 then -- 显示子菜单
        local locationNames = ""
        
        -- 构建地点名称
        for j = 1, #ChuansongList[Index][3] do
            locationNames = locationNames .. ChuansongList[Index][3][j][1] .. ","
        end
        
        -- 发送UI命令
        self:BeginUICommand()
        self:UICommand_AddInt(Index)
        self:UICommand_AddStr(ChuansongList[Index][2])
        self:UICommand_AddStr(locationNames)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 20170503)
        
    elseif Type == 2 then -- 执行传送
        -- 检查银票
        local itemCount = self:GetBagItemLayCount(selfId, g_Yinpiao)
        if itemCount and itemCount >= 1 then
            self:NotifyTip(selfId, "Trên người ngươi có Ngân phiếu, đang chạy thương! Ta không thể giúp ngươi.")
            return
        end
        
        -- 检查漕运任务
        local missionFlag = self:IsHaveMission(selfId, 4021)
        if missionFlag and missionFlag > 0 then
            self:NotifyTip(selfId, "Ngươi đang mang khoang hàng tào vận\\\\, dịch trạm không truyền tống cho ngươi được.")
            return
        end
        
        -- 检查禁止传送的状态效果
        for i, ImpactId in ipairs(g_Impact_NotTransportList) do
            local haveImpact = self:LuaFnHaveImpactOfSpecificDataIndex(selfId, ImpactId)
            if haveImpact then
                self:NotifyTip(selfId, g_TalkInfo_NotTransportList[i])
                return
            end
        end
        
        -- 获取目标传送位置
        local location = ChuansongList[Index][3][arg]
        
        if not location or not location[1] or location[1] == "" then
            self:NotifyTip(selfId, "Mục tiêu truyền tống không hợp lệ.")
            return
        end
        
        -- 执行传送
        self:CallScriptFunction(400900, "TransferFunc", selfId, location[2], location[3], location[4], location[5])
    end
end

-- 事件处理
function KuaiJCS:OnEventRequest(selfId, targetId, arg, index)
	if index == 1 then
		self:TransPort(selfId, 0, 1)
		return
	end
    -- if index == 2 then 
    --     if self:GetLevel(selfId) < 119 then
    --         self:SetLevel(selfId, 95)
    --         self:notify_tips(selfId, "领取成功。")
    --     end
    -- end
end


-- 中转函数 - 处理客户端UI回调
function KuaiJCS:ScriptTransitCenter(selfId, xieziA, xieziB, xieziC, xieziD, xieziE, xieziF)
    if xieziA == 9996 then -- 快捷传送UI
        self:TransPort(selfId, xieziB, xieziC, xieziD)
        return
    end
end

-- 检查是否有任务（需要在script_base中实现或扩展）
function KuaiJCS:IsHaveMission(selfId, missionId)
    -- 如果script_base有此方法则调用，否则返回0
    if self.LuaFnIsHaveMission then
        return self:LuaFnIsHaveMission(selfId, missionId)
    end
    return 0
end

return KuaiJCS