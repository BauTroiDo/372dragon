-- Explicit installation, after configuration and engine hook preflight.
local M={}
function M.prepare(config,extensions)
    assert(config.reference_complete~=false,"native references are incomplete")
    local adapter=require("cy_four_combat.runtime_adapter").new(config,extensions)
    local bridge=require("cy_four_combat.engine").new(config,adapter)
    local missing={}
    local ids={}
    for _,row in pairs(config.impacts) do ids[row.donor_logic]=true end
    for id in pairs(config.skill_logics or {}) do ids[id]=true end
    for id in pairs(ids) do
        if not (config.disabled_logic_ids and config.disabled_logic_ids[id]) then
            local ok,why=bridge:readiness(id)
            if not ok then missing[id]=why end
        end
    end
    if config.resources_enabled then
        for _,name in ipairs({"resource_get","resource_set","get_doll_id","donor_faction","talent_level","random_1000","float2int"}) do
            if type(adapter[name])~="function" then missing.resources=missing.resources or {};table.insert(missing.resources,name) end
        end
    end
    if next(missing) then return nil,missing end
    if config.resources_enabled then bridge.resources=require("cy_four_combat.resources").new(config,adapter) end
    -- Build every object before touching either live registry.
    for id in pairs(ids) do
        if config.disabled_logic_ids and config.disabled_logic_ids[id] then bridge:make_unavailable_impact(id)
        elseif id>=792 and id<=794 then bridge:make_skill(id) else bridge:make_impact(id) end
    end
    return bridge,{}
end
function M.attach(bridge,impact_engine,skill_engine)
    assert(bridge and impact_engine and skill_engine,"engines/validated bridge required")
    assert(not impact_engine.cy_four_bridge and not skill_engine.cy_four_bridge,"combat already installed")
    for id in pairs(bridge.impacts) do assert(impact_engine.logics[id]==nil,"impact logic collision "..id) end
    for id in pairs(bridge.skills) do assert(skill_engine.skill_logics[id]==nil,"skill logic collision "..id) end
    for id,logic in pairs(bridge.impacts) do impact_engine.logics[id]=logic end
    for id,logic in pairs(bridge.skills) do skill_engine.skill_logics[id]=logic end
    impact_engine.cy_four_bridge=bridge
    skill_engine.cy_four_bridge=bridge
    return bridge
end
return M
