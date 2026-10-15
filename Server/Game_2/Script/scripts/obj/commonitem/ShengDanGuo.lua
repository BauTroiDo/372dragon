local gbk = require "wire_charset"
local class = require "class"               
local define = require "define"             
local script_base = require "script_base"   

local ShengDanGuo = class("ShengDanGuo", script_base)
ShengDanGuo.script_id = 300085  

function ShengDanGuo:OnDefaultEvent(selfId, bagIndex)
end

function ShengDanGuo:IsSkillLikeScript(selfId)
    return 1
end


function ShengDanGuo:CancelImpacts(selfId)
    return 0
end

function ShengDanGuo:OnConditionCheck(selfId)
    local sceneId = self:GetSceneID()
    if sceneId ~= 4 then
        self:notify_tips(selfId,"Chỉ ước nguyện được ở Thái Hồ!") 
        return 0
    end
    local treasureX = 157  -- 许愿树X坐标
    local treasureZ = 188  -- 许愿树Z坐标
    local PlayerX = self:GetHumanWorldX(selfId)
    local PlayerZ = self:GetHumanWorldZ(selfId) 
    local Distance = math.floor(math.sqrt((treasureX - PlayerX) * (treasureX - PlayerX) + (treasureZ - PlayerZ) * (treasureZ - PlayerZ)))
    if Distance > 5 then
        self:notify_tips(selfId,"Xin dùng [Quả Giáng Sinh] gần cây thông Thái Hồ (157,188), tọa độ hiện cách cây còn" ..Distance .. "gạo")
        return 0
    end

    return 1
end

function ShengDanGuo:OnDeplete(selfId)
    return self:LuaFnDepletingUsedItem(selfId)
end


function ShengDanGuo:OnActivateOnce(selfId)
	local XuYuanNum = self:LuaFnGetWorldGlobalDataEx(95) 
	local JiangLiNum = self:LuaFnGetWorldGlobalDataEx(96) 
	self:LuaFnSetWorldGlobalDataEx(95,XuYuanNum+1)
	if XuYuanNum == 58 and JiangLiNum < 10 then
		self:DiscoverTrap(selfId)
		self:LuaFnSetWorldGlobalDataEx(95,0)
		self:LuaFnSetWorldGlobalDataEx(96,JiangLiNum+1)
	end
    self:BeginAddItem()
	self:AddItem(20310100,1) --重楼之芒 处理下如何并换重楼
    if not self:EndAddItem(selfId) then
		return 0
    end
	self:AddItemListToHuman(selfId)
	self:notify_tips(selfId,string.format("Ước thành công, chúc mừng bạn nhận: %s.",self:GetItemName(20310100)))
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 0)
    return 1
end
--掉落包的物品掉落表....
ShengDanGuo.g_DropBoxItem = {
	{ odds = 20, itemId =38008300 },
	{ odds = 20, itemId =38008300 },
	{ odds = 20, itemId =38008300 },
	{ odds = 20, itemId =38008300 },
	{ odds = 20, itemId =38008300 },
}
function ShengDanGuo:DiscoverTrap(selfId)
	-- local strGlobalNews = gbk.fromutf8("#P少侠#{_INFOUSR%s}尽显豪侠风范，在#G洛阳钱庄#P的#Y孙进宝#G（65，40）#P处参与#Y一掷千金豪情礼#P活动，获得#G%s重豪情礼")
	-- self:AddGlobalCountNews(string.format(strGlobalNews, gbk.fromutf8(self:GetName(selfId)),gbk.fromutf8(TopChongZhiTxt[nSelectIdx])), true)
	--计算总权重....
	local totalOdds = 0
	for _, item in pairs(self.g_DropBoxItem )do
		totalOdds = totalOdds  + item.odds
	end
	if totalOdds < 1 then
		return
	end
	--给掉落包....
	local DropItemId = -1
	for i = 1, 66 do
		--计算本包掉落的物品....
		local randValue = math.random(1, totalOdds)
		local currentOdds = 0
		for _, item in pairs(self.g_DropBoxItem) do
			currentOdds = currentOdds + item.odds
			if randValue <= currentOdds then
				DropItemId = item.itemId
				break
			end
		end
		local PlayerX = self:GetHumanWorldX(selfId)
		local PlayerZ = self:GetHumanWorldZ(selfId)
		local PosX = PlayerX + math.random(-10, 10)
		local PosZ = PlayerZ + math.random(-10, 10)
		--放掉落包到场景里....
		if DropItemId > 0 then
			local BoxId = self:DropBoxEnterScene(PosX, PosZ)
			if BoxId > -1 then
				self:AddItemToBox(BoxId, define.QUALITY_CREATE_BY_BOSS, 1, DropItemId)
			end
		end
	end
end
function ShengDanGuo:OnActivateEachTick(selfId)
    return 1
end

return ShengDanGuo