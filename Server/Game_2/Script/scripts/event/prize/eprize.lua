local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local eprize = class("eprize", script_base)
eprize.script_id = 888899
--ScriptGlobal.MD_CHANGE_YUANBAO_RATE
eprize.duihuanrate = 400				--兑换比例  1点数需求多少元宝
eprize.rmb_rate = 1				--游戏记录用 1元 = 多少点数  单位:点数



eprize.menpaititle =
{
    1096,1108,1117,1099,1102,1105,1111,1120,1114,-1,1219,1362,
}
eprize.menpaititletxt =
{
    "少林第一人","明教第一人","丐帮第一人","武当第一人","峨嵋第一人","星宿第一人","天龙第一人","天山第一人","逍遥第一人","","Đệ Nhất Nhân Mạn Đà Sơn Trang","恶人谷第一人"
}

-- 充值称号配置表：{点数阈值, 称号ID}
eprize.pay_title_config = {
	{500, 1288},	-- 500/长歌剑影怀情客
	{800, 1286},	-- 800/初会便已许平生
	{1500, 1375},	-- 1500/天龙争锋豪侠士
	{2500, 1374},	-- 2500/御风腾山海
	{4000, 1392},	-- 4000/紫影凌空
	{8000, 1394},	-- 8000/千军辟易慑八荒
	{12000, 1407},	-- 12000/豪情万丈走天涯
	{15000, 1405},	-- 15000/九州御风问长生
	{20000, 1385},	-- 20000/凌绝紫禁·群雄之首
	{25000, 1386},	-- 25000/鏖战紫禁·武林魁杰
	{30000, 1387},	-- 30000/会战紫禁·江湖英豪
	{35000, 1237},	-- 35000/勇冠四海·武林豪杰
}
function eprize:GetYuanBaoRate(selfId)
	return eprize.duihuanrate
end
function eprize:AskPoint(selfId)
    -- local point = self:GetTopUpPoint(selfId) * 10
    -- self:NotifyLeftPoint(selfId, point)
    self:NotifyLeftPoint(selfId, 0)
end

function eprize:NotifyLeftPoint(selfId, nLeftPoint)
    local point = self:GetTopUpPoint(selfId)
    self:BeginUICommand()
    self:UICommand_AddInt(point)
    self:UICommand_AddInt(self.duihuanrate)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 2003)
end

function eprize:BuyYuanBao(selfId, point, rate)
    local human = self:get_scene():get_obj_by_id(selfId)
	if not human then
		return
	end
    local result = self:CostTopUpPoint(selfId, point)
    if not result then
        self:notify_tips(selfId, "Không đủ điểm")
        return
    end
	local addyuanbao = point * self.duihuanrate
    --human:add_yucanbao(addyuanbao,"兑换点数:"..tostring(point))
	self:AddBindYuanBao(selfId,addyuanbao)
	self:notify_tips(selfId, "Ngươi đã thành công của đổi" .. tostring(point) .. "điểm, nhận được"..tostring(addyuanbao).."Nguyên bảo khóa.")
	
    local total_exchange_point = self:GetMissionData(selfId, ScriptGlobal.MD_CHANGE_POINTCOUNT)
	self:SetMissionData(selfId, ScriptGlobal.MD_CHANGE_POINTCOUNT, total_exchange_point + point)
	
	-- 累计记录玩家已兑换点数（用于后续活动，例如圣诞累计兑换）
	local total_exchange_point = self:GetMissionData(selfId, ScriptGlobal.MD_SHENGDAN_POINT)
	self:SetMissionData(selfId, ScriptGlobal.MD_SHENGDAN_POINT, total_exchange_point + point)

	
    local acme_havepoint = self:GetMissionData(selfId, ScriptGlobal.MD_CHANGE_YUANBAO)
    self:SetMissionData(selfId, ScriptGlobal.MD_CHANGE_YUANBAO, acme_havepoint + addyuanbao)
	local RMBPoint = math.ceil(point / self.rmb_rate)
	self:CallScriptFunction(888817,"ResetPayReward",selfId,RMBPoint,666666,888888)		--666666,888888 此两值不要改动
	--self:AddPayTitle(selfId)
	--self:UpdateMingDongTop(selfId,nil,point)
end
--function eprize:UpdateRechargeMenPaiTitle(selfId,oldmp)
--    local menpai = self:GetMenPai(selfId)
--	if not menpai or menpai < 0 then return end
--	menpai = menpai + 1
--    local HaveYuanBao = self:GetMissionData(selfId, 388) / 100
--    if HaveYuanBao >= 1000 then
--		self:LuaFnAddNewAgname(selfId, self.menpaititle[menpai])			--不用删除，因为这几些称号都是同互斥的，给予时会先删掉再给新的
--		self:notify_tips(selfId,string.format("获得称号：%s",self.menpaititletxt[menpai]))
--    end
--	-- id = -1 , update = nil or false   刷新称号到客户端
--	-- self:LuaFnDelNewAgname(selfId,-1)
--end
function eprize:AddPayTitle(selfId)
    local HaveYuanBao = self:GetMissionData(selfId, ScriptGlobal.MD_CHANGE_YUANBAO) / self.duihuanrate
	--新称号表的  Type 列为互斥ID  同类互斥的用  elseif 从大往小进行即可
	--LuaFnAddNewAgname  给予时会遍历称号 有没有存在同互斥的，有则先删再给   可以不用检测是否拥有
	--LuaFnAddNewAgname  参数3   == true 时则先不刷新到客户端    == false or nil 时则立马刷新到客户端  因为还在继续检测给予 ，最后再给个false  一起刷新客户端即可
	-- 累积称号：只要达成条件，每个称号都给予
	--self:notify_tips(selfId, "当前point。"..HaveYuanBao)
	for _, config in ipairs(self.pay_title_config) do
		local need_point = config[1]  -- 需要的点数
		local title_id = config[2]    -- 称号ID
		if HaveYuanBao >= need_point then
			if not self:LuaFnHaveAgname(selfId, title_id) then
				self:LuaFnAddNewAgname(selfId, title_id, false)
			end
		end
	end
	-- id = -1 , update = nil or false   刷新称号到客户端
	self:LuaFnAddNewAgname(selfId, -1)
end

return eprize