local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ejinghu_Boss = class("ejinghu_Boss", script_base)
ejinghu_Boss.randomdata = 0
ejinghu_Boss.g_PreTimeHour_1 = 0
ejinghu_Boss.g_PreTimeHour_2 = 0
ejinghu_Boss.g_PreTimeHour_3 = 0
ejinghu_Boss.g_Boss = {
    {
        ["x"] = 141,
        ["z"] = 96,
        ["b1"] = 885,
        ["b2"] = 887,
        ["b3"] = 889,
        ["n1"] = "北海混江小龙",
        ["n2"] = "Bắc Hải Xuất Động Tiểu Giao",
        ["n3"] = "Bắc Hải Phiên Giang Tiểu Thận"
    }
    , {
    ["x"] = 250,
    ["z"] = 98,
    ["b1"] = 885,
    ["b2"] = 887,
    ["b3"] = 889,
    ["n1"] = "东海混江小龙",
    ["n2"] = "Đông Hải Xuất Động Tiểu Giao",
    ["n3"] = "Đông Hải Phiên Giang Tiểu Thận"
}
, {
    ["x"] = 206,
    ["z"] = 253,
    ["b1"] = 885,
    ["b2"] = 887,
    ["b3"] = 889,
    ["n1"] = "南海混江小龙",
    ["n2"] = "Nam Hải Xuất Động Tiểu Giao",
    ["n3"] = "Nam Hải Phiên Giang Tiểu Thận"
}
, {
    ["x"] = 101,
    ["z"] = 256,
    ["b1"] = 885,
    ["b2"] = 887,
    ["b3"] = 889,
    ["n1"] = "西海混江小龙",
    ["n2"] = "Tây Hải Xuất Động Tiểu Giao",
    ["n3"] = "Tây Hải Phiên Giang Tiểu Thận"
}
, {
    ["x"] = 139,
    ["z"] = 133,
    ["b1"] = 884,
    ["b2"] = 886,
    ["b3"] = 888,
    ["n1"] = "混江龙",
    ["n2"] = "出洞蛟",
    ["n3"] = "翻江蜃"
}
}
function ejinghu_Boss:OnSceneTimer(timer)
	if self:GetSceneID() ~= 5 then
		return
	end
    local nHour = self:GetQuarterTime()
    if nHour > 16 and nHour < 40 then
        return
    end
	self.randomdata = math.random(1,2100000000)
    if self:GetMinute() >= 45 and self:GetMinute() < 55 then
        if nHour == self.g_PreTimeHour_1 then
            return
        end
        self.g_PreTimeHour_1 = nHour
        if self:IsHaveMonster("北海混江小龙") == 0 then
            self:UpDateMonster(1, 10,self.randomdata)
        end
        if self:IsHaveMonster("东海混江小龙") == 0 then
            self:UpDateMonster(2, 11,self.randomdata)
        end
        if self:IsHaveMonster("南海混江小龙") == 0 then
            self:UpDateMonster(3, 12,self.randomdata)
        end
        if self:IsHaveMonster("西海混江小龙") == 0 then
            self:UpDateMonster(4, 13,self.randomdata)
        end
    end
    if self:GetMinute() >= 55 then
        if nHour == self.g_PreTimeHour_3 then
            return
        end
        self.g_PreTimeHour_3 = nHour
        if self:IsHaveMonster("混江龙") == 0 then
            self:UpDateMonster(5, 14,self.randomdata)
        end
    end
end

function ejinghu_Boss:IsHaveMonster(MonsterName)
    local nMonsterNum = self:GetMonsterCount()
    local bHaveMonster = 0
    for i = 1, nMonsterNum do
        local nMonsterId = self:GetMonsterObjID(i)
        if self:GetName(nMonsterId) == MonsterName then
            bHaveMonster = 1
        end
    end
    return bHaveMonster
end

function ejinghu_Boss:UpDateMonster(nIndex, nGroupId,randomid)
	if randomid ~= self.randomdata then
		return
	end
    local nMonsterNum = self:GetMonsterCount()
    for i = 1, nMonsterNum do
        local nMonsterId = self:GetMonsterObjID(i)
        if self:GetName(nMonsterId) == self.g_Boss[nIndex]["n1"] then
            self:LuaFnDeleteMonster(nMonsterId)
        end
        if self:GetName(nMonsterId) == self.g_Boss[nIndex]["n2"] then
            self:LuaFnDeleteMonster(nMonsterId)
        end
        if self:GetName(nMonsterId) == self.g_Boss[nIndex]["n3"] then
            self:LuaFnDeleteMonster(nMonsterId)
        end
    end
    local nMonId
    nMonId = self:LuaFnCreateMonster(self.g_Boss[nIndex]["b1"], self.g_Boss[nIndex]["x"], self.g_Boss[nIndex]["z"], 19,
        197, 005117)
    self:SetCharacterName(nMonId, self.g_Boss[nIndex]["n1"])
    self:SetMonsterGroupID(nMonId, nGroupId)
    self:SetCharacterTitle(nMonId, "Kính Hồ Lục Bá")
    nMonId = self:LuaFnCreateMonster(self.g_Boss[nIndex]["b2"], self.g_Boss[nIndex]["x"] + 2, self.g_Boss[nIndex]["z"],
        19, 198, 005118)
    self:SetCharacterName(nMonId, self.g_Boss[nIndex]["n2"])
    self:SetMonsterGroupID(nMonId, nGroupId)
    self:SetCharacterTitle(nMonId, "Kính Hồ Lục Bá")
    nMonId = self:LuaFnCreateMonster(self.g_Boss[nIndex]["b3"], self.g_Boss[nIndex]["x"] - 2, self.g_Boss[nIndex]["z"],
        19, 199, 005119)
    self:SetCharacterName(nMonId, self.g_Boss[nIndex]["n3"])
    self:SetMonsterGroupID(nMonId, nGroupId)
    self:SetCharacterTitle(nMonId, "Kính Hồ Lục Bá")
    if nIndex == 5 then
        local str = "#PThủy tặc năm xưa hoành hành Tầm Dương Giang #{_BOSS14}#Pđã dẫn quân xuất hiện tại #GKính Hồ#P! Kính mời anh hùng thiên hạ mau chóng đến tiêu diệt!"
        self:AddGlobalCountNews(str)
    end
end

return ejinghu_Boss
