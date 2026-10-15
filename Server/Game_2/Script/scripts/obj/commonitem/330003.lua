local ScriptGlobal = require "scripts.ScriptGlobal"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local common_item = class("common_item", script_base)
local maan = 56
local gold_maan = 58

function common_item:IsSkillLikeScript()
    return 1
end

function common_item:CancelImpacts()
    return 0
end

function common_item:OnConditionCheck(selfId)
	-- if self:GetMissionData(selfId,ScriptGlobal.MD_CHANGE_POINTCOUNT) < 1500 then
	   -- self:notify_tips(selfId, "充值小于1500点无法使用小喇叭。")
       -- return 0
	-- end
    -- if ScriptGlobal.is_internal_test then
        -- self:notify_tips(selfId, "内测活动中,无法使用喇叭。")
        -- return 0
    -- end
	return 1
end

function common_item:OnDeplete(selfId)
    return 1
end
--【OnActivateOnce】UI使用道具  成功时返回 2   重要  失败返回 0 非UI道具成功返回 1
function common_item:OnActivateOnce(selfId)
    self:BeginUICommand()
	self:EndUICommand()
	self:DispatchUICommand(selfId, 5422 )
    return 2
end
--【UI确定操作】
function common_item:CallBackSpeakerAfter(selfId)
	-- if self:GetMissionData(selfId,ScriptGlobal.MD_CHANGE_POINTCOUNT) < 1500 then
	   -- self:notify_tips(selfId, "充值小于1500点无法使用小喇叭。")
       -- return false
	-- end
    -- if ScriptGlobal.is_internal_test then
        -- self:notify_tips(selfId, "内测活动中,无法使用喇叭。")
        -- return false
    -- end
	--常规检测后，开始校验当前使用道具 {验证的道具ID，至少一个，有几个就加几个}
	local usepos = self:LuaFnCheckUseItem_UI(selfId,{30505107,30505219})
	if usepos == -1 then
		self:notify_tips(selfId, "Vị trí dùng đạo cụ đã đổi, xin dừng mọi hack dùng đạo cụ khác.")
        return false
    end
	--如果有判断空间的先在这里检测
	
	
	--现在的扣除函数不需要加返回验证了，底层有打印跟断言
	self:LuaFnDecItemLayCount(selfId, usepos, 1)
	
	--现在是扣除后的处理
	
	return true
end

return common_item