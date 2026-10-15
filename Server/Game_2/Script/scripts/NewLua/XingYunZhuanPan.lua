--幸运转盘抽奖脚本
--奖品配置格式: {物品ID, 数量, 权重} 权重越大中奖几率越高
--转盘转完后手动领取奖品

local class = require "class"
local define = require "define"
local script_base = require "script_base"
local XingYunZhuanPan = class("XingYunZhuanPan", script_base)
XingYunZhuanPan.script_id = 956821
XingYunZhuanPan.g_EventId = 808125
XingYunZhuanPan.TicketItemId = 30505147  -- 抽奖券物品ID

-- 奖品配置表: {物品ID, 数量, 权重}
XingYunZhuanPan.PrizeConfig = {}

-- 总权重=1000, 百分比=权重/10
XingYunZhuanPan.PrizeConfig[1]  = {30505147, 1, 1}       -- 重楼链               0.1%
XingYunZhuanPan.PrizeConfig[2]  = {30505147, 1, 5}       -- 强化卷轴99级         0.5%
XingYunZhuanPan.PrizeConfig[3]  = {30505147, 1, 5}       -- 武魂下线平自选礼盒   0.5%
XingYunZhuanPan.PrizeConfig[4]  = {30505147, 1, 10}      -- 七级宝石兑换券       1.0%
XingYunZhuanPan.PrizeConfig[5]  = {30505147, 1, 5}       -- 饰品体力雕文         0.5%
XingYunZhuanPan.PrizeConfig[6]  = {30505147, 1, 10}      -- 强化卷轴50级         1.0%
XingYunZhuanPan.PrizeConfig[7]  = {30505147, 1, 20}      -- 六级宝石兑换券       2.0%
XingYunZhuanPan.PrizeConfig[8]  = {30505147, 1, 10}      -- 七级宝石兑换券       1.0%
XingYunZhuanPan.PrizeConfig[9]  = {30505147, 1, 25}      -- 宝石琢刻符           2.5%
XingYunZhuanPan.PrizeConfig[10] = {30505147, 2, 15}      -- 穷奇魂玉             1.5%
XingYunZhuanPan.PrizeConfig[11] = {30505147, 1, 50}      -- 高级宝石合成符       5.0%
XingYunZhuanPan.PrizeConfig[12] = {30505147, 1, 50}      -- 高级宝石合成符       5.0%
XingYunZhuanPan.PrizeConfig[13] = {30505147, 1, 1}       -- 重楼戒               0.1%
XingYunZhuanPan.PrizeConfig[14] = {30505147, 1, 80}      -- 高级宝石合成符       5.0%
XingYunZhuanPan.PrizeConfig[15] = {30505147, 1, 25}      -- 宝石琢刻符           2.5%
XingYunZhuanPan.PrizeConfig[16] = {30505147, 1, 80}      -- 高级宝石合成符       5.0%
XingYunZhuanPan.PrizeConfig[17] = {30505147, 1, 1}       -- 重楼玉               0.1%
XingYunZhuanPan.PrizeConfig[18] = {30505147, 2, 15}      -- 穷奇魂玉             1.5%
XingYunZhuanPan.PrizeConfig[19] = {30505147, 1, 10}      -- 饰品身法雕文         1.0%
XingYunZhuanPan.PrizeConfig[20] = {30505147, 10, 70}    -- 至尊强化精华         10.0%
XingYunZhuanPan.PrizeConfig[21] = {30505147, 10, 70}    -- 至尊强化精华         10.0%
XingYunZhuanPan.PrizeConfig[22] = {30505147, 1, 22}      -- 六级宝石兑换券       2.2%
XingYunZhuanPan.PrizeConfig[23] = {30505147, 10, 210}    -- 破级石               21.0%
XingYunZhuanPan.PrizeConfig[24] = {30505147, 10, 210}    -- 破级石               21.0%

-- 抽奖次数回馈配置: {需要次数, 奖品ID, 奖品名称}
XingYunZhuanPan.RewardConfig = {}
XingYunZhuanPan.RewardConfig[1] = {500,  38002426, "Di Cốt Đan"}
XingYunZhuanPan.RewardConfig[2] = {1000, 38002426, "Di Cốt Đan"}
XingYunZhuanPan.RewardConfig[3] = {1500, 38002426, "Di Cốt Đan"}
XingYunZhuanPan.RewardConfig[4] = {2000, 38002426, "Di Cốt Đan"}
XingYunZhuanPan.RewardConfig[5] = {2500, 38002426, "Di Cốt Đan"}
XingYunZhuanPan.RewardConfig[6] = {3000, 38002426, "Di Cốt Đan"}
XingYunZhuanPan.RewardConfig[7] = {3500, 38002426, "Di Cốt Đan"}

XingYunZhuanPan.MD_DrawCount = 570      -- 累计抽奖次数
XingYunZhuanPan.MD_RewardBase = 571     -- 551~557: 各档位领取标记(0=未领,1=已领)
XingYunZhuanPan.MD_WeaponClaimed = 572  -- 神器礼盒领取标记(0=未领,1=已领)
XingYunZhuanPan.WEAPON_COST = 500
XingYunZhuanPan.WEAPON_ITEM = 30503153  -- 侠客行令牌

-- 神器礼盒兑换武器配置: {物品ID, 名称, cmdId}
XingYunZhuanPan.WeaponExConfig = {}
XingYunZhuanPan.WeaponExConfig[1]  = {10340100, "Đại Hạ Long Tước", 61}
XingYunZhuanPan.WeaponExConfig[2]  = {10341100, "Đại Tần Phong Địch", 62}
XingYunZhuanPan.WeaponExConfig[3]  = {10341200, "Đại Đường Côn Nhạc", 63}
XingYunZhuanPan.WeaponExConfig[4]  = {10342100, "Đại Thương Trần Ảnh", 64}
XingYunZhuanPan.WeaponExConfig[5]  = {10343100, "Đại Chu Lam Dạ", 65}
XingYunZhuanPan.WeaponExConfig[6]  = {10343200, "Đại Tấn Tinh Ngân", 66}
XingYunZhuanPan.WeaponExConfig[7]  = {10344100, "Đại Tống Quân Sầm", 67}
XingYunZhuanPan.WeaponExConfig[8]  = {10345100, "Đại Hán Hoằng Cương", 68}
XingYunZhuanPan.WeaponExConfig[9]  = {10345200, "Đại Tùy Ngưng Sương", 69}
XingYunZhuanPan.WeaponExConfig[10] = {10346100, "Đại Sở Thu Thanh", 70}
XingYunZhuanPan.WeaponExConfig[11] = {10347100, "Đại Tề Minh Phong", 71}
XingYunZhuanPan.WeaponExConfig[12] = {10126751, "Thời trang thuộc tính", 72}
XingYunZhuanPan.WeaponExConfig[13] = {10142125, "Tọa kỵ thuộc tính", 73}
XingYunZhuanPan.WEAPONEX_COUNT = 13

-- 经验兑换道具配置表: {物品ID, 需要经验, 物品名称, 经验描述, 数量, 是否绑定}
-- 新增道具只需在此表追加一行，菜单和逻辑自动生成
-- is_bind: true=发放绑定物品, false/nil=不绑定
XingYunZhuanPan.ExpExchangeConfig = {
    [1] = {30900016,  100000000, "Cao Cấp Bảo Thạch Hợp Thành Phù", "100 triệu", 1, true},
    --[2] = {38002397,  100000000,  "武道玄元丹",     "1亿",  100, true},
    --[3] = {20310220,  300000000, "天地明珠",     "3亿",  1, true},
    [2] = {38002732,  500000000, "Hồn Ngọc Cùng Kỳ",     "500 triệu",  1, true},
}
-- 盲盒积分兑换道具配置表: {物品ID, 需要积分, 物品名称, 经验描述, 数量, 是否绑定}
XingYunZhuanPan.MHJFConfig = {
    [20000] = {26000002,  200, "Vé bảo hộ 15", "200 tích điểm", 1, true},
    [20001] = {26000002,  2000, "Vé bảo hộ 15", "2000 tích điểm",  10, true},
    [20002] = {26000002,  400, "Vé bảo hộ 15", "400 tích điểm", 1, false},
    [20003] = {26000002,  4000, "Vé bảo hộ 15", "4000 tích điểm",  10, false},

    [20004] = {26000003,  2000, "Vé bảo hộ 18", "2000 tích điểm", 1, true},
    [20005] = {26000003,  20000, "Vé bảo hộ 18", "20000 tích điểm",  10, true},
    [20006] = {26000003,  4000, "Vé bảo hộ 18", "4000 tích điểm", 1, false},
    [20007] = {26000003,  40000, "Vé bảo hộ 18", "40000 tích điểm",  10, false},
}
XingYunZhuanPan.EXP_EXCHANGE_BASE_INDEX = 200  -- 菜单index起始值，每个道具占2个(显示+确认)
XingYunZhuanPan.TenDrawCache = {}
XingYunZhuanPan.BroadcastCache = {}
--合成神器配置
XingYunZhuanPan.HCSQonfig = {}

local ItemInfo = 
{
    --合成物品          需要物品
    --传说神器
	[10563001] = {id = 10340102},
    [10563002] = {id = 10341102},
    [10563003] = {id = 10341202},
    [10563004] = {id = 10342102},
    [10563005] = {id = 10343102},
    [10563006] = {id = 10343202},
    [10563007] = {id = 10344102},
    [10563008] = {id = 10345102},
    [10563009] = {id = 10345202},
    [10563011] = {id = 10346102},
    [10563012] = {id = 10347102},

    --史诗神器
    [10563101] = {id = 10563001},
    [10563102] = {id = 10563002},
    [10563103] = {id = 10563003},
    [10563104] = {id = 10563004},
    [10563105] = {id = 10563005},
    [10563106] = {id = 10563006},
    [10563107] = {id = 10563007},
    [10563108] = {id = 10563008},
    [10563109] = {id = 10563009},
    [10563111] = {id = 10563011},
    [10563112] = {id = 10563012},
    --神话神器
    [10563201] = {id = 10563101},
    [10563202] = {id = 10563102},
    [10563203] = {id = 10563103},
    [10563204] = {id = 10563104},
    [10563205] = {id = 10563105},
    [10563206] = {id = 10563106},
    [10563207] = {id = 10563107},
    [10563208] = {id = 10563108},
    [10563209] = {id = 10563109},
    [10563211] = {id = 10563111},
    [10563212] = {id = 10563112},
}

--积分兑换配置
local ItemInfoJFDH = 
{

	[38002426] = {num = 500}, --G移骨丹500积分
    [10422150] = {num = 5000},--重楼戒5000积分
    [10422016] = {num = 10000},--G不绑定重楼戒10000积分
    [10423026] = {num = 5000},--G重楼玉5000积分
    [10423024] = {num = 10000},--G不绑定重楼玉10000积分
    [10415055] = {num = 5000},--G重楼肩5000积分
    [10415056] = {num = 10000},--G不绑定重楼肩10000积分
    [10413102] = {num = 5000},--G重楼甲5000积分
    [10413103] = {num = 10000},--G不绑定重楼甲10000积分

}

--宝石兑换配置
local ItemInfoGem = 
{

    [50921001] = {num = 450},--黄冥石(9级)
    [50921002] = {num = 450},--蓝冥石(9级)
    [50921003] = {num = 450},--红冥石(9级)
    [50921004] = {num = 450},--绿冥石(9级)



    [50913001] = {num = 150},--黄宝石(9级)
    [50913002] = {num = 150},--蓝宝石(9级)
    [50913003] = {num = 150},--绿宝石(9级)
    [50913004] = {num = 150},--红宝石(9级)
    [50913005] = {num = 150},--黑宝石(9级)
    [50911001] = {num = 150},--石榴石(9级)

    [50912005] = {num = 150},--纯净黄玉(9级)
    [50912006] = {num = 150},--纯净皓石(9级)
    [50912007] = {num = 150},--纯净月光石(9级)
    [50912008] = {num = 150},--纯净碧玺(9级)
    [50902005] = {num = 150},--纯净黄晶石(9级)
    [50902006] = {num = 150},--纯净蓝晶石(9级)
    [50902007] = {num = 150},--纯净红晶石(9级)
    [50902008] = {num = 150},--纯净绿晶石(9级)
    [50903001] = {num = 150},--紫玉(9级)
    [50904002] = {num = 150},--变石(9级)
    
    [50914001] = {num = 150},--祖母绿(9级)
    [50901001] = {num = 150},--猫眼石(9级)
    [50901002] = {num = 150},--虎眼石(9级)
    [50913005] = {num = 150},--黑宝石(9级)
    [50911001] = {num = 150},--石榴石(9级)
}
-- 计算总权重
function XingYunZhuanPan:CalcTotalWeight()
    local total = 0
    local i = 1
    while i <= #self.PrizeConfig do
        total = total + self.PrizeConfig[i][3]
        i = i + 1
    end
    return total
end

-- 根据权重抽取奖品索引
function XingYunZhuanPan:DrawPrizeIndex()
    local totalWeight = self:CalcTotalWeight()
    local randValue = math.random(1, totalWeight)
    local accumulated = 0
    local i = 1

    while i <= #self.PrizeConfig do
        accumulated = accumulated + self.PrizeConfig[i][3]
        if randValue <= accumulated then
            return i
        end
        i = i + 1
    end
    return 1
end

-- 发送提示消息
function XingYunZhuanPan:Tips(selfId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

-- 发放单个奖品
function XingYunZhuanPan:GivePrize(selfId, prizeIndex)
    local prize = self.PrizeConfig[prizeIndex]
    if prize == nil then
        return 0
    end

    self:BeginAddItem()
    self:AddItem(prize[1], prize[2], true)
    self:EndAddItem(selfId)
    self:AddItemListToHuman(selfId)

    return 1
end

-- 批量发放奖品（十连抽用）
function XingYunZhuanPan:GiveMultiplePrizes(selfId, prizeIndexList)
    self:BeginAddItem()
    local i = 1
    while i <= #prizeIndexList do
        local prizeIndex = prizeIndexList[i]
        local prize = self.PrizeConfig[prizeIndex]
        if prize then
            self:AddItem(prize[1], prize[2], true)
        end
        i = i + 1
    end
    self:EndAddItem(selfId)
    self:AddItemListToHuman(selfId)
end

-- NPC对话入口
function XingYunZhuanPan:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#Y  Các hạ có phải người đại khí vận, tới chỗ ta thử là biết!")
    self:AddNumText("#GNhận hộp mù may mắn hằng ngày", 6, 2000)
     --self:AddNumText("#G单次抽奖(消耗1张抽奖券)", 6, 80)
     --self:AddNumText("#G十连抽奖(消耗10张抽奖券)", 6, 81)
     --self:AddNumText("#G经验兑换奖券(5000万经验=1张)", 6, 7)
     --self:AddNumText("#G盲盒次数回馈", 6, 20)
     self:AddNumText("#GĐổi tích điểm hộp mù", 6, 40)
     self:AddNumText("#GHợp thành thần khí", 6, 50)
     self:AddNumText("#GĐổi bảo thạch cấp 9", 6, 60)
     self:AddNumText("#GĐổi bảo thạch cấp 9", 6, 61)
     self:AddNumText("#GĐổi cuộn bảo hộ tăng", 6, 62)
    --self:AddNumText("#G兑换9星神器", 2, 55)
    -- 经验兑换道具（配置表驱动，自动生成菜单）
    for i = 1, #self.ExpExchangeConfig do
        local cfg = self.ExpExchangeConfig[i]
        local showIdx = self.EXP_EXCHANGE_BASE_INDEX + (i - 1) * 2
        self:AddNumText("#GĐổi" .. cfg[3] .. "(" .. cfg[4] .. "=" .. cfg[5] .. "cái)", 2, showIdx)
    end
   -- self:AddNumText("#G领取内测等级(102级)", 2, 92)
    self:AddNumText("#GNhận nguyên bảo (1000 vạn + khóa)", 2, 94)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

-- 事件请求处理
function XingYunZhuanPan:OnEventRequest(selfId, targetId, arg, index)
    --self:Tips(selfId, "[调试] OnEventRequest: arg=" .. tostring(arg) .. " index=" .. tostring(index))
    if index == 6 then
        self:OpenLotteryUI(selfId, 12000)
    elseif index == 7 then
        -- 二级对话：显示兑换确认
        local curExp = self:GetExp(selfId)
        self:BeginEvent(self.script_id)
        self:AddText("#YĐổi kinh nghiệm lấy vé rút")
        self:AddText("\\n    Quy tắc đổi:#G50 triệu kinh nghiệm = 1 vé rút")
        self:AddText("\\n    Kinh nghiệm hiện tại của ngươi:#G" .. curExp)
        self:AddNumText("#GXác nhận đổi", 2, 8)
        self:AddNumText("Trở về", 2, 9)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 8 then
        self:ExchangeExpForTicket(selfId, targetId)
    elseif index == 9 then
        self:OnDefaultEvent(selfId, targetId)
    elseif index == 10 then
        -- 批量兑换确认
        local curExp = self:GetExp(selfId)
        self:BeginEvent(self.script_id)
        self:AddText("#YĐổi kinh nghiệm hàng loạt lấy vé rút")
        self:AddText("\\n    Quy tắc đổi:#G100 triệu kinh nghiệm = 10 vé rút")
        self:AddText("\\n    Kinh nghiệm hiện tại của ngươi:#G" .. curExp)
        self:AddNumText("#GXác nhận đổi", 2, 11)
        self:AddNumText("Trở về", 2, 9)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 11 then
        self:ExchangeExpForTicket10(selfId, targetId)
    elseif index == 12 then
        self:ConvertWenYiXia(selfId)
    elseif index == 20 then
        self:ShowRewardUI(selfId, targetId)
    elseif index == 30 then
        self:ClaimReward(selfId, 1, targetId)
    elseif index == 31 then
        self:ClaimReward(selfId, 2, targetId)
    elseif index == 32 then
        self:ClaimReward(selfId, 3, targetId)
    elseif index == 33 then
        self:ClaimReward(selfId, 4, targetId)
    elseif index == 34 then
        self:ClaimReward(selfId, 5, targetId)
    elseif index == 35 then
        self:ClaimReward(selfId, 6, targetId)
    elseif index == 36 then
        self:ClaimReward(selfId, 7, targetId)
    elseif index == 40 then--积分兑换分页
        self:JFDHFY(selfId, targetId)
    elseif index == 41 then
        self:ClaimWeapon(selfId, targetId)


    elseif index == 50 then --神器合成分页
        self:ShowSQHC(selfId, targetId, 0)
    elseif index == 51 then --神器合成分页 传说神器
        self:ShowSQHC(selfId, targetId, 1)
    elseif index == 52 then --神器合成分页 史诗神器
        self:ShowSQHC(selfId, targetId, 2)
    elseif index == 53 then --神器合成分页 神话神器10563001
        self:ShowSQHC(selfId, targetId, 3)

    elseif index == 55 then
        self:ShowWeaponExUI(selfId, targetId, 1)
    elseif index == 56 then
        self:ShowWeaponExUI(selfId, targetId, 2)
    elseif index == 57 then
        self:ShowWeaponExUI(selfId, targetId, 1)
    elseif index == 60 then--九级宝石兑换分页
        self:JJBSDHFY(selfId, targetId)
    elseif index == 61 then--九级宝石兑换分页
        self:JJBSDHFY2(selfId, targetId)
    elseif index == 62 then--保护卷兑换分页
        self:BHJDH(selfId, targetId)
    elseif index == 80 then
        self:DirectDraw(selfId, 1, targetId)
    elseif index == 81 then
        self:DirectDraw(selfId, 10, targetId)
    elseif index == 92 then
        self:ClaimTestLevel(selfId)
    elseif index == 94 then
        self:ClaimYuanBao(selfId)
    elseif index == 2000 then
        self:LQXYMH(selfId,targetId)

    elseif index >= 20000 and index <= 20010    then  --合成神器
        self:ShowMHUI(selfId,targetId,index)

    elseif index >= 10563001 and index <= 10563212    then  --合成神器
        self:HCSQ(selfId,targetId,index)

    elseif index ==  38002426 or index ==  10422150  or index ==  10422016 or index ==  10423026 or index ==  10423024 or index ==  10415055 or index ==  10415056 
    or index ==  10413102  or index ==  10413103 
    then  --积分兑换

        self:JFDH(selfId,targetId,index)
    elseif index >= 50901001 and index <= 50921004    then  --九级宝石兑换
        self:JJBSDH(selfId,targetId,index)

    else
        -- 经验兑换道具（配置表通用路由）
        local handled = false
        for i = 1, #self.ExpExchangeConfig do
            local showIdx = self.EXP_EXCHANGE_BASE_INDEX + (i - 1) * 2
            local confirmIdx = showIdx + 1
            if index == showIdx then
                self:ShowExpExchangeUI(selfId, targetId, i)
                handled = true
                break
            elseif index == confirmIdx then
                self:DoExpExchange(selfId, targetId, i)
                handled = true
                break
            end
        end
        if not handled then
            local wi = 1
            while wi <= self.WEAPONEX_COUNT do
                if index == self.WeaponExConfig[wi][3] then
                    self:ExchangeWeapon(selfId, wi, targetId)
                    return
                end
                wi = wi + 1
            end
        end
    end
end

-- 经验兑换抽奖券
function XingYunZhuanPan:ExchangeExpForTicket(selfId, targetId)
    local needExp = 50000000
    local curExp = self:GetExp(selfId)
    if curExp < needExp then
        self:Tips(selfId, "Kinh nghiệm không đủ, cần 50 triệu mới đổi được")
        return
    end
    if self:LuaFnGetPropertyBagSpace(selfId) < 1 then
        self:Tips(selfId, "Túi không đủ chỗ, xin dọn túi")
        return
    end
    self:AddExp(selfId, 0 - needExp)
    self:BeginAddItem()
    self:AddItem(self.TicketItemId, 1)
    self:EndAddItem(selfId)
    self:AddItemListToHuman(selfId)
    self:Tips(selfId, "Đổi thành công! Tốn 50 triệu kinh nghiệm, nhận vé rút x1")
end

-- 批量兑换：1亿经验=10张抽奖券
function XingYunZhuanPan:ExchangeExpForTicket10(selfId, targetId)
    local needExp = 100000000
    local curExp = self:GetExp(selfId)
    if curExp < needExp then
        self:Tips(selfId, "Kinh nghiệm không đủ, cần 100 triệu mới đổi được")
        return
    end
    if self:LuaFnGetPropertyBagSpace(selfId) < 1 then
        self:Tips(selfId, "Túi không đủ chỗ, xin dọn túi")
        return
    end
    self:AddExp(selfId, 0 - needExp)
    self:BeginAddItem()
    self:AddItem(self.TicketItemId, 10)
    self:EndAddItem(selfId)
    self:AddItemListToHuman(selfId)
    self:Tips(selfId, "Đổi thành công! Tốn 100 triệu kinh nghiệm, nhận vé rút x10")
end


function XingYunZhuanPan:LQXYMH(selfId, targetId)
    
    local count = self:LuaFnGetAvailableItemCount(selfId, 40005203)
    if count < 1 then
        self:Tips(selfId, "Ngươi không có chứng nhận hộp mù hằng ngày")
        return
    end
    if self:LuaFnGetPropertyBagSpace(selfId) < count/2 then
        self:Tips(selfId, "Túi không đủ chỗ, xin dọn túi")
        return
    end

    local lastTime = self:GetMissionData(selfId, define.MD_ENUM.MD_HANYUBED_CANADDEXP_COUNT)

    local daySeconds = 86400
    local timeZoneOffset = 28800 -- 8小时的秒数 (东八区)
    
    -- 获取当前时间
    local nowTime = os.time()
    
    -- 【关键修改】计算“北京时间”的今天0点
    -- 逻辑：(当前时间 + 8小时) 取整后 - 8小时
    -- 这样可以确保“一天”是从北京时间00:00开始计算的
    local todayZero = (nowTime + timeZoneOffset) - ((nowTime + timeZoneOffset) % daySeconds)
    
    -- 同理，计算上次领取时的“北京时间”0点
    local lastDayZero = (lastTime + timeZoneOffset) - ((lastTime + timeZoneOffset) % daySeconds)
    
    --self:Tips(selfId, "修正后 todayZero: " .. todayZero)
    --self:Tips(selfId, "修正后 lastDayZero: " .. lastDayZero)
    
    -- 判断是否同一天
    if lastDayZero == todayZero then
        local nextDrawTime = todayZero + daySeconds
        -- 这里的提示逻辑也可以优化一下，显示具体的剩余秒数
        local waitSec = nextDrawTime - nowTime
        self:Tips(selfId, "Mỗi ngày nhận một lần, xin quay lại sau 0h mai!")
        return 0
    end
    -- 【修改点结束】

    -- 发放奖励...
    -- 更新时间为当前时间


    self:SetMissionData(selfId, define.MD_ENUM.MD_HANYUBED_CANADDEXP_COUNT, nowTime)

    self:BeginAddItem()
    self:AddItem(38008207, 100*count)
    self:EndAddItem(selfId)
    self:AddItemListToHuman(selfId)
    self:Tips(selfId, "Lĩnh hội thành công!")
end


-- 沉木纹艺匣转换：38003158 → 38003165
function XingYunZhuanPan:ConvertWenYiXia(selfId)
    local oldItemId = 38003158
    local newItemId = 38003165
    local count = self:LuaFnGetAvailableItemCount(selfId, oldItemId)
    if count < 1 then
        self:Tips(selfId, "Ngươi không có hộp khắc văn tự chọn (38003158)")
        return
    end
    if self:LuaFnGetPropertyBagSpace(selfId) < 1 then
        self:Tips(selfId, "Túi không đủ chỗ, xin dọn túi")
        return
    end
    if not self:LuaFnDelAvailableItem(selfId, oldItemId, 1) then
        self:Tips(selfId, "Xóa thất bại, xin kiểm vật phẩm có khóa không")
        return
    end
    self:BeginAddItem()
    self:AddItem(newItemId, 1)
    self:EndAddItem(selfId)
    self:AddItemListToHuman(selfId)
    self:Tips(selfId, "Chuyển thành công! Nhận Trầm Mộc Văn Nghệ Hạp x1")
end

-- 直接抽奖（不打开UI，奖品自动发放）
function XingYunZhuanPan:DirectDraw(selfId, drawCount, targetId)
    --self:Tips(selfId, "[调试] DirectDraw进入: drawCount=" .. tostring(drawCount))
    if self:LuaFnGetPropertyBagSpace(selfId) < drawCount or self:LuaFnGetMaterialBagSpace(selfId) < drawCount then
        self:Tips(selfId, "Túi không đủ chỗ, cần trống cả ô đạo cụ lẫn nguyên liệu" .. drawCount .. "vị trí")
        return
    end
    if self:LuaFnGetAvailableItemCount(selfId, self.TicketItemId) < drawCount then
        self:Tips(selfId, "Không đủ vé rút, cần" .. drawCount .. "Trương")
        return
    end
    local delResult = self:LuaFnDelAvailableItem(selfId, self.TicketItemId, drawCount)
    --self:Tips(selfId, "[调试] DelItem返回值=" .. tostring(delResult) .. " 类型=" .. type(delResult))
    if not delResult then
       -- self:Tips(selfId, "[调试] LuaFnDelAvailableItem失败")
        return
    end
    local curDrawCount = self:GetMissionData(selfId, self.MD_DrawCount)
    self:SetMissionData(selfId, self.MD_DrawCount, curDrawCount + drawCount)
    local allIndexes = {}
    local i = 1
    while i <= drawCount do
        allIndexes[i] = self:DrawPrizeIndex()
        i = i + 1
    end
    self:GiveMultiplePrizes(selfId, allIndexes)
    local prizeNames = ""
    i = 1
    while i <= drawCount do
        local prize = self.PrizeConfig[allIndexes[i]]
        if prize then
            prizeNames = prizeNames .. "[" .. self:GetItemName(prize[1]) .. "]"
        end
        i = i + 1
    end
    self:Tips(selfId, "Rút xong! Nhận được:" .. prizeNames)
    local broadStr = string.format("[%s]#Wtại#YVòng quay may mắn#Wnổ nhân phẩm rút trúng#G%s", self:GetName(selfId), prizeNames)
    self:AddGlobalCountNews(broadStr)
end

-- 打开抽奖界面
function XingYunZhuanPan:OpenLotteryUI(selfId, cmdType)
    if cmdType == 12000 then
        self:BeginUICommand()
        self:UICommand_AddInt(selfId)

        local itemIdStr = ""
        local countStr = ""
        local i = 1
        while i <= 24 do
            itemIdStr = itemIdStr .. self.PrizeConfig[i][1] .. ","
            countStr = countStr .. self.PrizeConfig[i][2] .. ","
            i = i + 1
        end

        self:UICommand_AddStr("Rút một lần cần vé rút *1")
        self:UICommand_AddStr(itemIdStr)
        self:UICommand_AddStr(countStr)
        self:UICommand_AddInt(XiaoXiang_CJ_DZP_WPH)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 2012816)
        return
    end

    -- 检查是否有未领取的奖品
    local guid = self:LuaFnGetGUID(selfId)
    if self.TenDrawCache and self.TenDrawCache[guid] then
        self:Tips(selfId, "Xin nhận thưởng lần trước rồi hãy rút tiếp")
        return
    end

    -- 计算抽奖次数
    local drawCount = 1
    if cmdType == 1 then
        drawCount = 10
    end

    -- 检查背包空间
    local minSpace = drawCount
    if self:LuaFnGetPropertyBagSpace(selfId) < minSpace or self:LuaFnGetMaterialBagSpace(selfId) < minSpace then
        self:BroadMsgByChatPipe(selfId, "@*;SrvMsg;DBD:Túi cần trống cả ô đạo cụ lẫn nguyên liệu" .. minSpace .. "vị trí", 0)
        return
    end

    -- 检查抽奖券
    if self:LuaFnGetAvailableItemCount(selfId, self.TicketItemId) < drawCount then
        self:Tips(selfId, "Không đủ vé rút thưởng" .. drawCount .. "cái")
        return
    end

    -- 扣除抽奖券
    if not self:LuaFnDelAvailableItem(selfId, self.TicketItemId, drawCount) then
        return
    end

    -- 累计抽奖次数
    local curDrawCount = self:GetMissionData(selfId, self.MD_DrawCount)
    self:SetMissionData(selfId, self.MD_DrawCount, curDrawCount + drawCount)

    -- 执行抽奖并缓存结果
    if drawCount == 10 then
        -- 十连抽：抽取10个奖品
        local allPrizeIndexes = {}
        local i = 1
        while i <= 10 do
            allPrizeIndexes[i] = self:DrawPrizeIndex()
            i = i + 1
        end

        -- 构建奖品名称字符串
        local prizeNames = ""
        i = 1
        while i <= 10 do
            local prize = self.PrizeConfig[allPrizeIndexes[i]]
            if prize then
                prizeNames = prizeNames .. "[" .. self:GetItemName(prize[1]) .. "]"
            end
            i = i + 1
        end

        -- 缓存广播内容，等转盘动画结束后再播
        self.BroadcastCache[guid] = string.format("[%s]#Wtại#YVòng quay may mắn#Wnổ nhân phẩm rút trúng#G%s", self:GetName(selfId), prizeNames)
        -- 缓存十连抽数据供领取
        self.TenDrawCache[guid] = allPrizeIndexes
        self.TenDrawCache[guid].current = 1
        self.TenDrawCache[guid].total = 10

        -- 显示第一个光圈
        self:SetMissionData(selfId, XiaoXiang_CJ_DZP_WPH, allPrizeIndexes[1])
        self:DispatchUICommand(selfId, 20120817)
    else
        -- 单抽
        local prizeIndex = self:DrawPrizeIndex()

        -- 缓存奖品供领取
        self.TenDrawCache[guid] = {prizeIndex}
        self.TenDrawCache[guid].current = 1
        self.TenDrawCache[guid].total = 1
        -- 缓存广播内容，等转盘动画结束后再播
        local prize = self.PrizeConfig[prizeIndex]
        self.BroadcastCache[guid] = string.format("[%s]#Wtại#YVòng quay may mắn#Wnổ nhân phẩm rút trúng#G[%s]", self:GetName(selfId), self:GetItemName(prize[1]))

        -- 发送UI数据（显示转盘动画）
        self:SetMissionData(selfId, XiaoXiang_CJ_DZP_WPH, prizeIndex)
        self:DispatchUICommand(selfId, 20120817)
    end
end

-- 转盘动画结束后由客户端回调，执行广播
function XingYunZhuanPan:DoBroadcast(selfId)
    local guid = self:LuaFnGetGUID(selfId)
    if not self.BroadcastCache or not self.BroadcastCache[guid] then
        return
    end
    local str = self.BroadcastCache[guid]
    self.BroadcastCache[guid] = nil
    self:AddGlobalCountNews(str)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 49, 0)
end

-- 领取奖品
function XingYunZhuanPan:GetItem(selfId)
    local guid = self:LuaFnGetGUID(selfId)
    if not self.TenDrawCache or not self.TenDrawCache[guid] then
        -- 缓存丢失(脚本重载)时从MissionData恢复
        local savedIndex = self:GetMissionData(selfId, XiaoXiang_CJ_DZP_WPH)
        if savedIndex > 0 and savedIndex <= 24 then
            self:GivePrize(selfId, savedIndex)
            self:SetMissionData(selfId, XiaoXiang_CJ_DZP_WPH, 0)
            local prize = self.PrizeConfig[savedIndex]
            if prize then
                self:Tips(selfId, "Chúc mừng ngươi nhận được" .. self:GetItemName(prize[1]))
            end
        else
            self:Tips(selfId, "Không có thưởng để nhận")
        end
        return
    end

    local cache = self.TenDrawCache[guid]
    local current = cache.current or 1
    local total = cache.total or 1

    if total > 1 then
        -- 十连抽：一次性发放所有奖品
        local remaining = {}
        local count = 0
        local i = current
        while i <= total do
            if cache[i] then
                count = count + 1
                remaining[count] = cache[i]
            end
            i = i + 1
        end
        self:GiveMultiplePrizes(selfId, remaining)
        self.TenDrawCache[guid] = nil
        self:Tips(selfId, "Đã nhận hết phần thưởng")
    else
        -- 单抽：发放并清除
        local prizeIndex = cache[current]
        if prizeIndex then
            self:GivePrize(selfId, prizeIndex)
            local prize = self.PrizeConfig[prizeIndex]
            if prize then
                self:Tips(selfId, "Chúc mừng ngươi nhận được" .. self:GetItemName(prize[1]))
            end
        end
        self.TenDrawCache[guid] = nil
    end
end

-- 关闭界面
function XingYunZhuanPan:CloseMe(selfId)
    -- 清除抽奖数据
    self:SetMissionData(selfId, XiaoXiang_CJ_DZP_WPH, 0)
    self:BeginUICommand()
    self:EndUICommand()
    self:DispatchUICommand(selfId, 1000)
end

-- 抽奖次数回馈界面
function XingYunZhuanPan:ShowRewardUI(selfId, targetId)
    local drawCount = self:GetMissionData(selfId, self.MD_DrawCount)
    self:BeginEvent(self.script_id)
    self:AddText("#YTri ân lượt rút thưởng")
    self:AddText("\\n    Lượt rút tích lũy:#G" .. drawCount .. "Lần")
    self:AddText("\n")
    local i = 1
    while i <= 7 do
        local cfg = self.RewardConfig[i]
        local claimed = self:GetMissionData(selfId, self.MD_RewardBase + i - 1)
        local label = ""
        if claimed == 1 then
            label = "#W" .. cfg[1] .. "lần - " .. cfg[3] .. " (Đã nhận)"
        elseif drawCount >= cfg[1] then
            label = "#G" .. cfg[1] .. "lần - " .. cfg[3] .. " (Nhận được)"
        else
            label = "#R" .. cfg[1] .. "lần - " .. cfg[3] .. " (Chưa đạt)"
        end
        self:AddNumText(label, 2, 29 + i)
        i = i + 1
    end
    self:AddNumText("Trở về", 2, 9)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

-- 领取回馈奖励
function XingYunZhuanPan:ClaimReward(selfId, tier, targetId)
    local cfg = self.RewardConfig[tier]
    if cfg == nil then return end
    local drawCount = self:GetMissionData(selfId, self.MD_DrawCount)
    if drawCount < cfg[1] then
        self:Tips(selfId, "Không đủ lượt rút, cần" .. cfg[1] .. "Lần")
        return
    end
    local claimed = self:GetMissionData(selfId, self.MD_RewardBase + tier - 1)
    if claimed == 1 then
        self:Tips(selfId, "Thưởng mốc này đã nhận rồi")
        return
    end
    if self:LuaFnGetPropertyBagSpace(selfId) < 1 then
        self:Tips(selfId, "Túi hành trang không đủ chỗ")
        return
    end
    self:BeginAddItem()
    self:AddItem(cfg[2], 1, true)
    local addResult = self:EndAddItem(selfId)
    if addResult > 0 then
        self:AddItemListToHuman(selfId)
        self:SetMissionData(selfId, self.MD_RewardBase + tier - 1, 1)
        self:Tips(selfId, "Nhận thành công! Được" .. cfg[3])
    else
        self:Tips(selfId, "Thêm vật phẩm thất bại")
    end
    self:ShowRewardUI(selfId, targetId)
end

-- 兼容旧接口
function XingYunZhuanPan:JudgRandomRouletteItem(selfId, cmdType)
    self:OpenLotteryUI(selfId, cmdType)
end

-- 会员神器领取界面
function XingYunZhuanPan:ShowWeaponUI(selfId, targetId)
    local drawCount = self:GetMissionData(selfId, self.MD_DrawCount)
    local claimed = self:GetMissionData(selfId, self.MD_WeaponClaimed)
    self:BeginEvent(self.script_id)
    self:AddText("#Y5000 tích điểm nhận hộp thần khí tự chọn hội viên (chỉ một lần)")
    self:AddText("\\n    Lượt rút tích lũy:#G" .. drawCount .. "Lần")
    if drawCount < self.WEAPON_COST then
        self:AddText("\\n    #RKhông đủ tích điểm, còn cần" .. (self.WEAPON_COST - drawCount) .. "Lần")
    else
        self:AddText("\\n    #GTích điểm đủ, nhận được!")
        self:AddNumText("#GNhận hộp thần khí tự chọn hội viên", 2, 41)
    end
    self:AddNumText("Trở về", 2, 9)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

-- 领取会员神器自选礼盒
function XingYunZhuanPan:ClaimWeapon(selfId, targetId)
    local claimed = self:GetMissionData(selfId, self.MD_WeaponClaimed)
    if claimed == 1 then
        self:Tips(selfId, "Ngươi đã nhận rồi, không nhận lại được")
        return
    end
    local drawCount = self:GetMissionData(selfId, self.MD_DrawCount)
    if drawCount < self.WEAPON_COST then
        self:Tips(selfId, "Không đủ tích điểm, cần" .. self.WEAPON_COST .. "lần, hiện tại" .. drawCount .. "Lần")
        return
    end
    if self:LuaFnGetPropertyBagSpace(selfId) < 1 then
        self:Tips(selfId, "Túi hành trang không đủ chỗ")
        return
    end
    self:BeginAddItem()
    self:AddItem(self.WEAPON_ITEM, 1, true)
    local addResult = self:EndAddItem(selfId)
    if addResult > 0 then
        self:AddItemListToHuman(selfId)
        self:SetMissionData(selfId, self.MD_WeaponClaimed, 1)
        self:Tips(selfId, "Nhận thành công! Được hộp thần khí tự chọn hội viên")
    else
        self:Tips(selfId, "Thêm vật phẩm thất bại")
    end
end

-- 经验兑换道具 - 通用确认界面
function XingYunZhuanPan:ShowExpExchangeUI(selfId, targetId, cfgIndex)
    local cfg = self.ExpExchangeConfig[cfgIndex]
    if not cfg then return end
    local confirmIdx = self.EXP_EXCHANGE_BASE_INDEX + (cfgIndex - 1) * 2 + 1
    local curExp = self:GetExp(selfId)
    self:BeginEvent(self.script_id)
    self:AddText("#YĐổi kinh nghiệm" .. cfg[3])
    self:AddText("\\n    Quy tắc đổi:#G" .. cfg[4] .. "Kinh nghiệm = " .. cfg[5] .. "cái" .. cfg[3])
    if cfg[6] then
        self:AddText("(Khóa)")
    end
    self:AddText("\\n    Kinh nghiệm hiện tại của ngươi:#G" .. curExp)
    self:AddNumText("#GXác nhận đổi", 2, confirmIdx)
    self:AddNumText("Trở về", 2, 9)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

-- 经验兑换道具 - 通用执行兑换
function XingYunZhuanPan:DoExpExchange(selfId, targetId, cfgIndex)
    local cfg = self.ExpExchangeConfig[cfgIndex]
    if not cfg then return end
    local itemId  = cfg[1]
    local needExp = cfg[2]
    local name    = cfg[3]
    local expDesc = cfg[4]
    local count   = cfg[5]
    local isBind  = cfg[6]
    local curLevel = self:GetLevel(selfId)
    if curLevel < 102 then
        self:Tips(selfId, "Không đủ cấp, cần trên 102 mới đổi được")
        return
    end
    local curExp = self:GetExp(selfId)
    if curExp < needExp then
        self:Tips(selfId, "Không đủ kinh nghiệm, cần" .. expDesc .. "kinh nghiệm mới đổi được")
        return
    end
    if self:LuaFnGetPropertyBagSpace(selfId) < 1 then
        self:Tips(selfId, "Túi không đủ chỗ, xin dọn túi")
        return
    end
    self:AddExp(selfId, 0 - needExp)
    self:BeginAddItem()
    self:AddItem(itemId, count, isBind)
    self:EndAddItem(selfId)
    self:AddItemListToHuman(selfId)
    self:Tips(selfId, "Đổi thành công! Tiêu hao" .. expDesc .. "kinh nghiệm, nhận được" .. name .. "x" .. count)
end

-- 领取内测等级（仅一次，设为102级）
function XingYunZhuanPan:ClaimTestLevel(selfId)
    local claimed = self:GetMissionData(selfId, 573)
    if claimed == 1 then
        self:Tips(selfId, "Ngươi đã nhận cấp test rồi, không nhận lại được")
        return
    end
    self:SetLevel(selfId, 102)
    self:SetMissionData(selfId, 573, 1)
    self:Tips(selfId, "Nhận thành công! Cấp của ngươi lên 102")
end

-- 领取元宝（1000万元宝 + 1000万绑定元宝）
function XingYunZhuanPan:ClaimYuanBao(selfId)
    local amount = 10000000
    self:CSAddYuanbao(selfId, amount, "Nhận nguyên bảo test")
    self:AddBindYuanBao(selfId, amount, "Nhận nguyên bảo khóa test")
    self:Tips(selfId, "Nhận thành công! Được 1000 vạn nguyên bảo + 1000 vạn nguyên bảo khóa")
end

-- 神器礼盒兑换武器界面（分页）
function XingYunZhuanPan:ShowWeaponExUI(selfId, targetId, page)
    page = page or 1
    local hasItem = self:LuaFnGetAvailableItemCount(selfId, 20310220)
    self:BeginEvent(self.script_id)
    self:AddText("#YTốn 255 Thiên Địa Minh Châu đổi vũ khí thần khí")
    if hasItem < 255 then
        self:AddText("\\n    #RThiên Địa Minh Châu không đủ, đang có:" .. hasItem .. "cái, cần 255 cái")
    else
        self:AddText("\\n    #GThiên Địa Minh Châu đủ（" .. hasItem .. "cái）, xin chọn vũ khí:")
    end
    self:AddText("\n")
    local startIdx, endIdx
    if page == 1 then
        startIdx = 1
        endIdx = 7
    else
        startIdx = 8
        endIdx = self.WEAPONEX_COUNT
    end
    local i = startIdx
    while i <= endIdx do
        local wcfg = self.WeaponExConfig[i]
        self:AddNumText(wcfg[2], 2, wcfg[3])
        i = i + 1
    end
    if page == 1 then
        self:AddNumText("#GTrang sau", 2, 56)
    else
        self:AddNumText("#GTrang trước", 2, 57)
    end
    self:AddNumText("Trở về", 2, 9)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

-- 消耗神器礼盒兑换武器
function XingYunZhuanPan:ExchangeWeapon(selfId, index, targetId)
    local wcfg = self.WeaponExConfig[index]
    if wcfg == nil then return end
    if self:LuaFnGetAvailableItemCount(selfId, 20310220) < 255 then
        self:Tips(selfId, "Không đủ Thiên Địa Minh Châu, cần 255")
        return
    end
    if self:LuaFnGetPropertyBagSpace(selfId) < 1 then
        self:Tips(selfId, "Túi hành trang không đủ chỗ")
        return
    end
    if not self:LuaFnDelAvailableItem(selfId, 20310220, 255) then
        self:Tips(selfId, "Trừ Thiên Địa Minh Châu thất bại, xin kiểm khóa")
        return
    end
    self:BeginAddItem()
    self:AddItem(wcfg[1], 1, true)
    self:EndAddItem(selfId)
    self:AddItemListToHuman(selfId)
    self:Tips(selfId, "Đổi thành công! Nhận được" .. wcfg[2])
end


-- 神器合成（分页）
function XingYunZhuanPan:ShowSQHC(selfId, targetId, type)
    if type==0 then --选择神器级别
        self:BeginEvent(self.script_id)
        self:AddText("#YTốn 5 thần khí giống nhau hợp thành thần khí cao hơn")
        self:AddNumText("#GHợp thành thần khí Truyền Thuyết", 6, 51)
        self:AddNumText("#GHợp thành thần khí Sử Thi", 6, 52)
        self:AddNumText("#GHợp thành thần khí Thần Thoại", 6, 53)
        self:AddText("\n")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif type==1 then
        self:BeginEvent(self.script_id)
        self:AddText("#YTốn 5 thần khí giống nhau hợp thành thần khí cao hơn")
        self:AddNumText("#GĐại Hạ Long Tước·Truyền Thuyết", 6, 10563001)
        self:AddNumText("#GĐại Tần Phong Đích·Truyền Thuyết", 6, 10563002)
        self:AddNumText("#GĐại Đường Côn Nhạc·Truyền Thuyết", 6, 10563003)
        self:AddNumText("#GĐại Thương Trần Ảnh·Truyền Thuyết", 6, 10563004)
        self:AddNumText("#GĐại Chu Lam Dạ·Truyền Thuyết", 6, 10563005)
        self:AddNumText("#GĐại Tấn Tinh Ngân·Truyền Thuyết", 6, 10563006)
        self:AddNumText("#GĐại Tống Quân Sầm·Truyền Thuyết", 6, 10563007)
        self:AddNumText("#GĐại Hán Hoằng Cương·Truyền Thuyết", 6, 10563008)
        self:AddNumText("#GĐại Tùy Ngưng Sương·Truyền Thuyết", 6, 10563009)
        self:AddNumText("#GĐại Sở Thu Thanh·Truyền Thuyết", 6, 10563011)
        self:AddNumText("#GĐại Tề Minh Phong·Truyền Thuyết", 6, 10563012)
        self:AddText("\n")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif type==2 then
        self:BeginEvent(self.script_id)
        self:AddText("#YTốn 5 thần khí giống nhau hợp thành thần khí cao hơn")
        self:AddNumText("#GĐại Hạ Long Tước·Sử Thi", 6, 10563101)
        self:AddNumText("#GĐại Tần Phong Đích·Sử Thi", 6, 10563102)
        self:AddNumText("#GĐại Đường Côn Nhạc·Sử Thi", 6, 10563103)
        self:AddNumText("#GĐại Thương Trần Ảnh·Sử Thi", 6, 10563104)
        self:AddNumText("#GĐại Chu Lam Dạ·Sử Thi", 6, 10563105)
        self:AddNumText("#GĐại Tấn Tinh Ngân·Sử Thi", 6, 10563106)
        self:AddNumText("#GĐại Tống Quân Sầm·Sử Thi", 6, 10563107)
        self:AddNumText("#GĐại Hán Hoằng Cương·Sử Thi", 6, 10563108)
        self:AddNumText("#GĐại Tùy Ngưng Sương·Sử Thi", 6, 10563109)
        self:AddNumText("#GĐại Sở Thu Thanh·Sử Thi", 6, 10563111)
        self:AddNumText("#GĐại Tề Minh Phong·Sử Thi", 6, 10563112)
        self:AddText("\n")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif type==3 then
        self:BeginEvent(self.script_id)
        self:AddText("#YTốn 5 thần khí giống nhau hợp thành thần khí cao hơn")
        self:AddNumText("#GĐại Hạ Long Tước·Thần Thoại", 6, 10563201)
        self:AddNumText("#GĐại Tần Phong Đích·Thần Thoại", 6, 10563202)
        self:AddNumText("#GĐại Đường Côn Nhạc·Thần Thoại", 6, 10563203)
        self:AddNumText("#GĐại Thương Trần Ảnh·Thần Thoại", 6, 10563204)
        self:AddNumText("#GĐại Chu Lam Dạ·Thần Thoại", 6, 10563205)
        self:AddNumText("#GĐại Tấn Tinh Ngân·Thần Thoại", 6, 10563206)
        self:AddNumText("#GĐại Tống Quân Sầm·Thần Thoại", 6, 10563207)
        self:AddNumText("#GĐại Hán Hoằng Cương·Thần Thoại", 6, 10563208)
        self:AddNumText("#GĐại Tùy Ngưng Sương·Thần Thoại", 6, 10563209)
        self:AddNumText("#GĐại Sở Thu Thanh·Thần Thoại", 6, 10563211)
        self:AddNumText("#GĐại Tề Minh Phong·Thần Thoại", 6, 10563212)
        self:AddText("\n")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end

end
--盲盒积分兑换分页
function XingYunZhuanPan:JFDHFY(selfId, targetId, type)
    local drawCount = self:GetMissionData(selfId, self.MD_DrawCount)
    
    self:BeginEvent(self.script_id)
   
        self:BeginEvent(self.script_id)
        self:AddText("#YTích điểm hộp mù hiện tại:#G"..drawCount )
        self:AddNumText("#GDi Cốt Đan 500 tích điểm", 6, 38002426)
        self:AddNumText("#GNhẫn Trùng Lâu 5000 tích điểm", 6, 10422150)
        self:AddNumText("#GNhẫn Trùng Lâu không khóa 10000 tích điểm", 6, 10422016)
        self:AddNumText("#GNgọc Trùng Lâu 5000 tích điểm", 6, 10423026)
        self:AddNumText("#GNgọc Trùng Lâu không khóa 10000 tích điểm", 6, 10423024)
        self:AddNumText("#GVai Trùng Lâu 5000 tích điểm", 6, 10415055)
        self:AddNumText("#GVai Trùng Lâu không khóa 10000 tích điểm", 6, 10415056)
        self:AddNumText("#GGiáp Trùng Lâu 5000 tích điểm", 6, 10413102)
        self:AddNumText("#GGiáp Trùng Lâu không khóa 10000 tích điểm", 6, 10413103)
        self:AddText("\n")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)

end
--盲盒积分兑换
function XingYunZhuanPan:JFDH(selfId, targetId, index)
    if self:LuaFnGetPropertyBagSpace(selfId) < 1 then
        self:Tips(selfId, "Túi hành trang không đủ chỗ")
        return
    end

    local drawCount = self:GetMissionData(selfId, self.MD_DrawCount)
    
    local CurItem = ItemInfoJFDH[index]
    if drawCount<CurItem.num then
        self:Tips(selfId, "Không đủ tích điểm!!")
        return
    end
    --扣除积分
    self:SetMissionData(selfId, self.MD_DrawCount, drawCount-CurItem.num)

    self:BeginAddItem()
    self:AddItem(index, 1)
    self:EndAddItem(selfId)
    self:AddItemListToHuman(selfId)
    self:Tips(selfId, "Đổi thành công! Nhận được"..self:GetItemName(index))


end



-- 合成神器
function XingYunZhuanPan:HCSQ(selfId, index, targetId)
    
    local CurItem = ItemInfo[targetId]
 
    if self:LuaFnGetAvailableItemCount(selfId, CurItem.id) < 5 then
        self:Tips(selfId, self:GetItemName(CurItem.id).."không đủ, cần 5 cái")
        return
    end
    if self:LuaFnGetPropertyBagSpace(selfId) < 1 then
        self:Tips(selfId, "Túi hành trang không đủ chỗ")
        return
    end


    local num=0
    for i = 0, 99 do
        itemIdx = self:LuaFnGetItemTableIndexByIndex(selfId, i)
        if itemIdx == CurItem.id and num<5 then
            self:LuaFnEraseItem(selfId, i)
            num=num+1
        end
    end

    

 
    self:BeginAddItem()
    self:AddItem(targetId, 1, false)
    self:EndAddItem(selfId)
    self:AddItemListToHuman(selfId)
    self:Tips(selfId, "Hợp thành thành công! Nhận được"..self:GetItemName(targetId))
end

--九级宝石兑换分页
function XingYunZhuanPan:JJBSDHFY(selfId, targetId, type)
   
    
    self:BeginEvent(self.script_id)
   
        self:BeginEvent(self.script_id)
        self:AddText("#YĐổi bảo thạch cấp 9" )
        self:AddNumText("#GHoàng Minh Thạch(cấp 9)", 6, 50921001)
        self:AddNumText("#GLam Minh Thạch(cấp 9)", 6, 50921002)
        self:AddNumText("#GHồng Minh Thạch(cấp 9)", 6, 50921003)
        self:AddNumText("#GLục Minh Thạch(cấp 9)", 6, 50921004)

        self:AddNumText("#GHoàng Ngọc Thuần Khiết(cấp 9)", 6, 50912005)
        self:AddNumText("#GHạo Thạch Thuần Khiết(cấp 9)", 6, 50912006)
        self:AddNumText("#GNguyệt Quang Thạch Thuần Khiết(cấp 9)", 6, 50912007)
        self:AddNumText("# Bích Tỉ Thuần Khiết(cấp 9)", 6, 50912008)

        self:AddNumText("#GHoàng Tinh Thạch Thuần Khiết(cấp 9)", 6, 50902005)
        self:AddNumText("#GLam Tinh Thạch Thuần Khiết(cấp 9)", 6, 50902006)
        self:AddNumText("#GHồng Tinh Thạch Thuần Khiết(cấp 9)", 6, 50902007)
        self:AddNumText("#GLục Tinh Thạch Thuần Khiết(cấp 9)", 6, 50902008)


        self:AddText("\n")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)

end
--九级宝石兑换分页
function XingYunZhuanPan:JJBSDHFY2(selfId, targetId, type)
   
    
    self:BeginEvent(self.script_id)
   
        self:BeginEvent(self.script_id)
        self:AddText("#YĐổi bảo thạch cấp 9" )

        self:AddNumText("#GHoàng Bảo Thạch(cấp 9)", 6, 50913001)
        self:AddNumText("#GLam Bảo Thạch(cấp 9)", 6, 50913002)
        self:AddNumText("#GLục Bảo Thạch(cấp 9)", 6, 50913003)
        self:AddNumText("#GHồng Bảo Thạch(cấp 9)", 6, 50913004)

        self:AddNumText("#GTử Ngọc(cấp 9)", 6, 50903001)
        self:AddNumText("#GBiến Thạch(cấp 9)", 6, 50904002)
   
        self:AddNumText("#GTổ Mẫu Lục(cấp 9)", 6, 50914001)
        self:AddNumText("# Miêu Nhãn Thạch(cấp 9)", 6, 50901001)
        self:AddNumText("# Hổ Nhãn Thạch(cấp 9)", 6, 50901002)
        self:AddNumText("# Hắc Bảo Thạch(cấp 9)", 6, 50913005)
        self:AddNumText("# Thạch Lựu Thạch(cấp 9)", 6, 50911001)

        self:AddText("\n")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)

end
-- 九级宝石兑换
function XingYunZhuanPan:JJBSDH(selfId, index, targetId)
    
    local CurItem = ItemInfoGem[targetId]
 
    if self:LuaFnGetAvailableItemCount(selfId, 30900016) < CurItem.num then
        self:Tips(selfId, self:GetItemName(30900016).."không đủ, cần"..CurItem.num.."cái")
        return
    end
    if self:LuaFnGetPropertyBagSpace(selfId) < 1 then
        self:Tips(selfId, "Túi hành trang không đủ chỗ")
        return
    end

    if not self:LuaFnDelAvailableItem(selfId, 30900016, CurItem.num) then
        self:Tips(selfId, "Trừ phù hợp thành bảo thạch cao cấp thất bại, xin kiểm khóa")
        return
    end
    self:BeginAddItem()
    self:AddItem(targetId, 1, true)
    self:EndAddItem(selfId)
    self:AddItemListToHuman(selfId)
    self:Tips(selfId, "Hợp thành thành công! Nhận được"..self:GetItemName(targetId))
end
-- 增幅保护卷兑换
function XingYunZhuanPan:BHJDH(selfId, targetId, type)
   
    local drawCount = self:GetMissionData(selfId, self.MD_DrawCount)
    
    self:BeginEvent(self.script_id)
   
    local count1 = self:LuaFnGetAvailableItemCount(selfId, 40005203)
    if count1==200 then
        self:AddText("#YTích điểm hộp mù hiện tại:#G"..drawCount )


        self:AddNumText("#GVé bảo hộ 15 (không khóa) 1 cái 200 tích điểm", 6, 20000)
        self:AddNumText("#GVé bảo hộ 15 (không khóa) 10 cái 2000 tích điểm", 6, 20001)
        self:AddNumText("#GVé bảo hộ 18 (không khóa) 1 cái 2000 tích điểm", 6, 20004)
        self:AddNumText("#GVé bảo hộ 18 (không khóa) 10 cái 20000 tích điểm", 6, 20005)


        self:AddText("\n")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif count1<200 then
        self:AddText("#YTích điểm hộp mù hiện tại:#G"..drawCount )


        self:AddNumText("#GVé bảo hộ 15 (khóa) 1 cái 200 tích điểm", 6, 20000)
        self:AddNumText("#GVé bảo hộ 15 (khóa) 10 cái 2000 tích điểm", 6, 20001)
        self:AddNumText("#GVé bảo hộ 15 (không khóa) 1 cái 400 tích điểm", 6, 20002)
        self:AddNumText("#GVé bảo hộ 15 (không khóa) 10 cái 4000 tích điểm", 6, 20003)
        self:AddNumText("#GVé bảo hộ 18 (khóa) 1 cái 2000 tích điểm", 6, 20004)
        self:AddNumText("#GVé bảo hộ 18 (khóa) 10 cái 20000 tích điểm", 6, 20005)
        self:AddNumText("#GVé bảo hộ 18 (không khóa) 1 cái 4000 tích điểm", 6, 20006)
        self:AddNumText("#GVé bảo hộ 18 (không khóa) 10 cái 40000 tích điểm", 6, 20007)

        self:AddText("\n")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end


end

-- 盲盒积分 - 通用确认界面
function XingYunZhuanPan:ShowMHUI(selfId, targetId, cfgIndex)

    local cfg = self.MHJFConfig[cfgIndex]
    if not cfg then return end
    local itemId  = cfg[1]
    local needExp = cfg[2]
    local name    = cfg[3]
    local expDesc = cfg[4]
    local count   = cfg[5]
    local isBind  = cfg[6]
    local curLevel = self:GetLevel(selfId)

    local drawCount = self:GetMissionData(selfId, self.MD_DrawCount)
    if drawCount < needExp then
        self:Tips(selfId, "Không đủ tích điểm, cần" .. expDesc .. "tích điểm mới đổi được")
        return
    end
    if self:LuaFnGetPropertyBagSpace(selfId) < 1 then
        self:Tips(selfId, "Túi không đủ chỗ, xin dọn túi")
        return
    end
    --扣除积分
    self:SetMissionData(selfId, self.MD_DrawCount, drawCount-needExp)
    self:AddExp(selfId, 0 - needExp)
    self:BeginAddItem()
    local count1 = self:LuaFnGetAvailableItemCount(selfId, 40005203)
    if count1==200 then
        self:AddItem(itemId, count, false)

    elseif count1<200 then
        self:AddItem(itemId, count, isBind)
    end
    
    self:EndAddItem(selfId)
    self:AddItemListToHuman(selfId)
    self:Tips(selfId, "Đổi thành công! Tiêu hao" .. expDesc .. "tích điểm, nhận được" .. name .. "x" .. count)
end

return XingYunZhuanPan
