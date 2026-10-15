-- teleport-dali 41: A/B o muc SCRIPT - chay DUNG ma Lua that (cy4_npc.lua OnDefaultEvent/OnEventRequest + cfg cua 4 NPC ve),
-- mot bien so duy nhat = CAY (goc /home/ubuntu  <->  clone da va). Khong can server.
-- Chay: lua5.4 41-lua-ab.lua <goc cay Script>     vd  /home/ubuntu/Game_2/Script
-- In ra cho moi NPC: menu phat ra + tham so THAT truyen cho TransferFunc khi nguoi choi chon muc 0.
local root = assert(arg[1], "thieu duong dan goc cay Script")
package.path = root .. "/?.lua;" .. package.path

-- stub toi thieu: class co ke thua, script_base rong, training_npc khong chen muc nao
package.preload["class"] = function()
    return function(name, base)
        local c = {}
        c.__index = c
        c.__cname = name
        if base then setmetatable(c, { __index = base }) end
        c.new = function(...) return setmetatable({}, c) end
        return c
    end
end
package.preload["script_base"] = function() return {} end
package.preload["scripts.obj.cy4.cy4_training_npc"] = function()
    return { menu = function() end, event = function() return false end,
             qinggong_menu = function() end, ability_menu = function() end }
end

local mods = { "cy4_congren_travel", "cy4_guigu_travel", "cy4_taohuadao_travel", "cy4_tangmen_travel" }
local fail = 0
for _, m in ipairs(mods) do
    local cls = require("scripts.obj.cy4." .. m)
    local npc = cls.new()
    local menu, calls, says = {}, {}, {}
    npc.BeginEvent = function() end
    npc.EndEvent = function() end
    npc.DispatchEventList = function() end
    npc.AddText = function(_, t) menu[#menu + 1] = "text:" .. t end
    npc.AddNumText = function(_, t, icon, idx) menu[#menu + 1] = ("item[%d/%d]:%s"):format(icon, idx, t) end
    npc.GetMenPai = function() return 9 end
    npc.GetLevel = function() return 15 end
    npc.Say = function(_, _, _, t) says[#says + 1] = t end
    npc.CallScriptFunction = function(_, ...) calls[#calls + 1] = { ... } end
    npc:OnDefaultEvent(1001, 2002)
    npc:OnEventRequest(1001, 2002, npc.script_id, 0)   -- nguoi choi chon muc index 0 = "Den Dai Ly"
    local c = calls[1]
    if not c then
        print(("%-22s script_id=%d  KHONG co loi goi TransferFunc nao (says=%d)"):format(m, npc.script_id, #says)); fail = fail + 1
    else
        print(("%-22s script_id=%d  menu={%s}  ->  CallScriptFunction(%s, %q, selfId=%s, scene=%s, x=%s, z=%s, min_level=%s)  so loi goi=%d")
            :format(m, npc.script_id, table.concat(menu, " | "), tostring(c[1]), tostring(c[2]), tostring(c[3]),
                    tostring(c[4]), tostring(c[5]), tostring(c[6]), tostring(c[7]), #calls))
    end
end
os.exit(fail == 0 and 0 or 1)
