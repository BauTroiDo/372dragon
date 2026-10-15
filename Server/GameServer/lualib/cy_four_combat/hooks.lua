-- No global singleton: the actor's own scene determines the combat bridge.
local M={}
local function resources(owner)
    local scene=owner:get_scene()
    local engine=scene and scene:get_impact_enginer()
    local bridge=engine and engine.cy_four_bridge
    if bridge and bridge.config and bridge.config.gameplay_enabled==false then return nil end
    return bridge and bridge.resources
end
function M.on_use_skill_successfully(owner,skill_info)
    local scene=owner:get_scene()
    local engine=scene and scene:get_impact_enginer()
    local bridge=engine and engine.cy_four_bridge
    if bridge and bridge.config.gameplay_enabled==true and bridge.phase2 then
        -- taohua-doll 17/09/2026: `character:on_use_skill_success_fully` (obj/character.lua:1054) goi
        -- ham nay KHONG bao pcall, nen mot loi trong nhanh phai (tao/guigu/jue) huy luon phan con lai
        -- cua lan tung — do that pass11: `tao.lua:94` nem trong `skynet.pack` => 3820 ra `sends = 0`
        -- (client khong nhan noi GCCharSkill_Send) VA `resources:on_use_skill_successfully` ben duoi
        -- bi bo qua nen 共情 khong bi tru. GHI LOG roi di tiep, KHONG nuot im lang — dung cach ma
        -- chinh `character.lua:1057` da lam cho `talent_on_use_skill_success_fully`.
        local ok,err=pcall(bridge.phase2.on_use_skill_successfully,bridge.phase2,owner,skill_info)
        if not ok then
            local oks,skynet=pcall(require,'skynet')
            if oks and skynet and skynet.loge then
                skynet.loge('[cy_four] phase2:on_use_skill_successfully error =',err)
            end
        end
    end
    local r=resources(owner)
    if r then return r:on_use_skill_successfully(owner,skill_info) end
end
function M.on_cancel(owner,skill_info)
    local r=resources(owner)
    if r then return r:cancel(owner,skill_info) end
end
function M.on_rage_regeneration(owner,periods)
    local r=resources(owner)
    if r then return r:on_rage_regeneration(owner,periods) end
end
function M.final_damage(owner,attacker,damage,is_critical)
    local scene=owner:get_scene()
    local engine=scene and scene:get_impact_enginer()
    local bridge=engine and engine.cy_four_bridge
    if not bridge or (bridge.config and bridge.config.gameplay_enabled==false) then return damage end
    return bridge:final_damage(owner,attacker,damage,{critical=is_critical==true or is_critical==1})
end
function M.critical_rate(owner,rate,skill_id)
    if not owner then return rate end
    local scene=owner:get_scene()
    local engine=scene and scene:get_impact_enginer()
    local bridge=engine and engine.cy_four_bridge
    if not bridge or (bridge.config and bridge.config.gameplay_enabled==false) then return rate end
    return bridge:critical_rate(owner,rate,skill_id)
end
return M
