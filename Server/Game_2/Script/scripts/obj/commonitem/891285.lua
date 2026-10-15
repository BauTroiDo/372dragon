------------------------------------------------------------------------
-- 武道玄元丹 (scriptID=891285, itemID=38002397)
-- 功能：使用后增加武道悟性点，支持批量使用
-- 批量使用流程：
--   1. 玩家右键使用 → OnActivateOnce 打开 Item_MultiUse UI (88991501)
--   2. UI确认后 → 客户端发 CGExecuteScript 到 889915 中转调度器
--   3. 调度器回调 → OnItemBatchUse → Use_XuanYuanDan 执行实际逻辑
-- 扩展新道具时只需参考此文件，实现 OnItemBatchUse 即可
------------------------------------------------------------------------
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local common_item = class("common_item", script_base)
local useitemid = 38002397  -- 武道玄元丹物品ID

function common_item:OnDefaultEvent(selfId, bagIndex)
end

-- 标记为类技能脚本，走 CGUseItem 包处理流程
function common_item:IsSkillLikeScript(selfId)
    return 1
end

function common_item:CancelImpacts(selfId)
    return 0
end

-- 使用前条件检查：验证物品是否合法
function common_item:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

-- 消耗处理：返回1表示允许消耗（批量使用时由 Use_XuanYuanDan 自行扣除，此处不重复扣）
function common_item:OnDeplete(selfId)
    return 1
end

-- 单次使用入口：打开批量使用UI（Item_MultiUse）
-- UICommand 参数依次为：物品ID、最大可用数量、脚本ID、背包位置、函数名
-- DispatchUICommand 88991501 = 打开 Item_MultiUse 批量使用界面
function common_item:OnActivateOnce(selfId)
	local useid = self:LuaFnGetItemIndexOfUsedItem(selfId)
	if useid ~= useitemid then
		return 0
	end
	local usepos = self:LuaFnGetBagIndexOfUsedItem(selfId)
	if self:LuaFnGetItemTableIndexByIndex(selfId,usepos) ~= useid then
		return 0
	end
    local talent_type = self:GetTalentType(selfId)
	if talent_type == define.INVAILD_ID then
		self:notify_tips(selfId, "Xin vào lưu phái rồi hãy dùng.")
		return 0
	end
	local maxcount = self:LuaFnGetAvailableItemCount(selfId,useid)
	self:BeginUICommand()
	self:UICommand_AddInt(useid)        -- param0: 物品ID
	self:UICommand_AddInt(maxcount)     -- param1: 最大可用数量
	self:UICommand_AddInt(891285)       -- param2: 本脚本ID（供UI回传）
	self:UICommand_AddInt(usepos)       -- param3: 背包位置
	self:UICommand_AddStr("Use_XuanYuanDan")  -- param4: 回调函数名（旧路径备用）
	self:EndUICommand()
	self:DispatchUICommand(selfId,88991501)    -- 打开批量使用UI
    return 1
end

function common_item:OnActivateEachTick(selfId)
    return 1
end

-- 批量使用核心逻辑：验证 → 扣物品 → 加悟性点 → 播特效
-- @param selfId  角色ID
-- @param bagpos  背包位置
-- @param count   使用数量
function common_item:Use_XuanYuanDan(selfId,bagpos,count)
	if self:LuaFnGetItemTableIndexByIndex(selfId,bagpos) ~= useitemid then
		self:notify_tips(selfId, "Thứ dùng không phải Võ Đạo Huyền Nguyên Đan.")
		return
	elseif not count or count < 1 then
		self:notify_tips(selfId, "Số dùng ít nhất 1 viên.")
		return
	elseif self:LuaFnGetAvailableItemCount(selfId,useitemid) < count then
		self:notify_tips(selfId, "Túi không có nhiều Huyền Nguyên Đan vậy để dùng.")
		return
	elseif self:GetTalentType(selfId) == define.INVAILD_ID then
		self:notify_tips(selfId, "Chưa vào lưu phái.")
		return
	end
	self:LuaFnDelAvailableItem(selfId, useitemid,count)      -- 扣除物品
	self:LuaFnAddTalentUnderstandPoint(selfId,count)          -- 增加悟性点
	self:ShowObjBuffEffect(selfId,selfId,-1,149)              -- 播放使用特效
end

-- 统一批量使用接口（由 item_multiuse.lua 889915 调度器回调）
-- 新增道具批量使用时，只需实现此函数即可，无需修改 AllowableScriptFunc.txt
function common_item:OnItemBatchUse(selfId, bagPos, count)
    self:Use_XuanYuanDan(selfId, bagPos, count)
end

return common_item
