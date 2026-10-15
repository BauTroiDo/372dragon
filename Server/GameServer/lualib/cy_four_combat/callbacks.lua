-- Ported contracts for donor scripts808253/808281. Scene-scoped summon state.
-- No persistent Mission329 object IDs, no assumed availability of donor assets.
local M = {}
local function finite(n) return type(n)=="number" and n==n and n~=math.huge and n~=-math.huge end
function M.state(owner)
    local scene=owner:get_scene()
    local s=owner._cy_four_summons
    if not s or s.scene~=scene then s={scene=scene,doll_id=-1,doll_flag=0};owner._cy_four_summons=s end
    return s
end
function M.set_doll(owner,doll)
    assert(doll and doll:get_scene()==owner:get_scene(),"doll must be in owner scene")
    local s=M.state(owner)
    doll._cy_four_summon_owner={guid=owner:get_guid(),owner=owner}
    s.doll_id=doll:get_obj_id();s.doll_flag=0
    return s.doll_id
end
function M.clear_doll(owner)
    local s=M.state(owner);s.doll_id=-1;s.doll_flag=0
end
function M.get_doll_id(owner)
    local s=M.state(owner)
    if not s.scene or s.doll_id<0 then return -1 end
    local doll=s.scene:get_obj_by_id(s.doll_id)
    local tag=doll and doll._cy_four_summon_owner
    if not doll or doll:get_scene()~=s.scene or not tag or tag.owner~=owner or tag.guid~=owner:get_guid() or doll:get_attrib("hp")<=0 then
        M.clear_doll(owner);return -1
    end
    return s.doll_id
end
function M.start_xin_zhen(owner,x,y)
    assert(finite(x) and finite(y),"formation anchor must be finite")
    M.state(owner).guigu_anchor={x=x,y=y}
end
function M.save_qinhuang_position(owner,x,y)
    assert(finite(x) and finite(y),"return anchor must be finite")
    M.state(owner).qinhuang_anchor={x=x,y=y}
end
local formations={
    {first=4067,last=4078,monster=16916,script=808254,life=30000,interval=3000,cooldown=30000,dy=0,int1=0},
    {first=4080,last=4091,monster=16917,script=808255,life=10000,interval=1000,cooldown=10000,dy=-1,talent10=true},
    {first=4166,last=4177,monster=16918,script=808256,life=10000,interval=1000,cooldown=10000,dy=-1,int1=0},
    {first=4226,last=4237,monster=16927,script=808257,life=15000,interval=2000,cooldown=15000,dy=-1},
    {first=4238,last=4249,monster=16928,script=808258,life=15000,interval=1000,cooldown=15000,dy=-1,int1=0},
}
M.formation_contracts=formations
function M.build_adapters(config)
    assert(type(config)=="table" and type(config.donor_impact_by_target)=="table","target to donor impact map required")
    local special=config.special_objects or {}
    local out={}
    local return_impact
    for target,source in pairs(config.donor_impact_by_target) do if source==13321 then return_impact=target end end
    local function make_special(owner,source,pos)
        local target=assert(special[source],"unmapped donor special object"..source)
        local obj=owner:skill_create_obj_specail({x=pos.x,y=pos.y},target)
        if not obj then return false end
        obj:set_continuance(0) -- Source CreateSpecialObjByDataIndex(...,0).
        return true
    end
    function out:get_doll_id(owner) return M.get_doll_id(owner) end
    function out:script_exists(owner,id,fn)
        if id==808281 then
            if fn=="OnImpactFadeOut" then return true end
            if fn=="SetPos" then return type(out.set_position)=="function" end
            return fn=="MouDongGanGe" and special[936]~=nil
        end
        -- Source808254..808258 are absent from the donor. Do not advertise a
        -- working formation merely because its spawning callback was found.
        return id==808253 and fn=="OnImpactFadeOut" and config.formations_verified==true and type(config.spawn_formation)=="function" and type(config.set_cooldown)=="function"
    end
    if return_impact and type(config.send_specific_delay)=="function" and type(config.float2int)=="function" and type(config.teleport_position)=="function" then
        function out:set_position(owner,pos)
            -- xyzServerSetPos -> x808281_SetPos -> impact13321(delay300).
            -- The final network teleport happens on its fade callback.
            local x,y=config.float2int(pos.x),config.float2int(pos.y)
            M.save_qinhuang_position(owner,x,y)
            return config.send_specific_delay(owner,return_impact,300)
        end
    end
    function out:script_mou_dong_gan_ge(owner,x,y)
        -- Donor ignores x/y here. Native182 already swapped the owner; the
        -- visual belongs at the doll's CURRENT position, not owner's target.
        local id=M.get_doll_id(owner)
        if id<0 then return false end
        local doll=owner:get_scene():get_obj_by_id(id)
        return make_special(owner,936,doll:get_world_pos())
    end
    function out:script_on_impact_fade(owner,id,target_impact)
        local source=assert(config.donor_impact_by_target[target_impact],"unmapped callback impact")
        if id==808281 then
            if owner:get_attrib("hp")==0 then return false end
            if source==4372 then M.clear_doll(owner);return true end
            if source==13321 then
                local pos=M.state(owner).qinhuang_anchor
                if not pos then return false end
                local teleport=config.teleport_position or config.set_position
                assert(type(teleport)=="function","network-aware final SetPos adapter required")
                teleport(owner,{x=pos.x,y=pos.y});return true
            end
            return false
        end
        if not self:script_exists(owner,id,"OnImpactFadeOut") then return false end
        local desc,tier,anchor
        if source==13317 then desc=formations[4];tier=12;anchor=owner:get_world_pos()
        else
            for _,r in ipairs(formations) do if source>=r.first and source<=r.last then desc=r;tier=source-r.first+1;break end end
            anchor=M.state(owner).guigu_anchor
        end
        if not desc or not anchor then return false end
        local ok=config.spawn_formation(owner,desc,{x=anchor.x,y=anchor.y+desc.dy},tier)
        if not ok then return false end
        if source~=13317 then config.set_cooldown(owner,83,desc.cooldown) end
        return true
    end
    return out
end
return M
