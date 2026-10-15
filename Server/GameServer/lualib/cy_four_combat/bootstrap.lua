-- Scene-local Lua module cache. Configure once before either engine loadall.
local M={}
function M.configure(config,extensions)
    assert(not M.bridge,"CY combat bridge already configured")
    local bridge,missing=require("cy_four_combat.installation").prepare(config,extensions)
    assert(bridge,"CY combat operations unready: "..require("cy_four_combat.bootstrap").describe(missing))
    M.bridge=bridge
    return bridge
end
function M.describe(missing)
    local parts={}
    for id,names in pairs(missing) do parts[#parts+1]=id.."="..table.concat(names,",") end
    table.sort(parts);return table.concat(parts,"; ")
end
local function bind(engine,key,entries)
    if not M.bridge then return false end
    if engine.cy_four_bridge==M.bridge then return true end
    assert(engine.cy_four_bridge==nil,"engine already has another CY bridge")
    for id in pairs(entries) do assert(engine[key][id]==nil,"CY logic collision "..id) end
    for id,logic in pairs(entries) do engine[key][id]=logic end
    engine.cy_four_bridge=M.bridge
    return true
end
function M.bind_impacts(engine) return M.bridge and bind(engine,"logics",M.bridge.impacts) or false end
function M.bind_skills(engine) return M.bridge and bind(engine,"skill_logics",M.bridge.skills) or false end
return M
