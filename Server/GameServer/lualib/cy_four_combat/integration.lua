-- Compose the independently ported modules without touching global registries.
-- Root supplies converted collection predicates and explicit resource storage.
local M={}
function M.prepare(config,extra)
    require("cy_four_combat.phase2").configure(config)
    require("cy_four_combat.phase3").configure(config)
    require("cy_four_combat.release").configure(config)
    assert(config.reference_complete==true,"complete remapping is required")
    local Adapter=require "cy_four_combat.runtime_adapter"
    local base=Adapter.new(config)
    local reverse={}
    for donor,target in pairs(config.resolve.impacts) do reverse[target]=tonumber(donor) end
    local callbacks=require("cy_four_combat.callbacks")
    local extensions=callbacks.build_adapters{
        donor_impact_by_target=reverse,
        special_objects=config.resolve.special_objects,
        formations_verified=false,
        float2int=function(v) return base:float2int(v) end,
        send_specific_delay=function(owner,id,delay) return base:send_specific_delay(owner,owner,id,delay) end,
        teleport_position=function(owner,p) return owner:on_teleport(p) end,
    }
    local packet=require("cy_four_combat.packet_adapters").build_adapters(require "game.packet",{
        client_stream12_verified=config.client_stream12_verified==true,
    })
    for name,fn in pairs(packet) do extensions[name]=fn end
    local swap=require("cy_four_combat.ui_swap_transport").build(require "game.packet",config)
    for name,fn in pairs(swap) do extensions[name]=fn end
    function extensions:clear_doll(owner) return callbacks.clear_doll(owner) end
    local phase2,formation_adapters=require("cy_four_combat.phase2").prepare(config,base)
    for name,fn in pairs(formation_adapters) do extensions[name]=fn end
    for name,fn in pairs(extra or {}) do extensions[name]=fn end
    local missing={}
    for _,row in pairs(config.impacts) do
        if row.donor_logic==99 or row.donor_logic==167 then
            local ids=row.donor_logic==99 and {row.params[4],row.params[6]} or {config.resolve.collections[360]}
            for _,id in ipairs(ids) do if not config.collections or not config.collections[id] then missing[#missing+1]="collection:"..tostring(id) end end
        end
    end
    if #missing>0 then return nil,{configuration=missing} end
    local bridge,missing=require("cy_four_combat.installation").prepare(config,extensions)
    if bridge then
        bridge.phase2=phase2
        require("cy_four_combat.release").install(bridge)
        require("cy_four_combat.guigu_auras").install(bridge)
    end
    return bridge,missing
end
return M
