-- Dedicated character document fields; donor mission numbers are API labels only.
-- The normal character save pipeline persists this table without a DB migration.
local M={}
local fields={[328]='empathy_state',[331]='blade_state',[332]='blade_timer'}
local function key(id) return assert(fields[id], 'unsupported four-school resource slot') end
function M.load(saved)
    if saved==nil then return nil end
    assert(type(saved)=='table', 'invalid four-school resource document')
    local out={}
    for _,name in pairs(fields) do
        local value=saved[name]
        if value~=nil then
            value=math.tointeger(value)
            assert(value and value>=0 and value<=2147483647, 'invalid four-school resource value')
            out[name]=value
        end
    end
    return out
end
function M.get(owner,id)
    local name=key(id)
    return owner.cy_four_resources and owner.cy_four_resources[name] or 0
end
function M.set(owner,id,value)
    local name=key(id)
    local faction=owner:get_menpai()
    -- menpai-fix: số phái CY (桃花岛 13, 绝情谷 14) như Serverhook MenPai_13/14 (GetMenPai()==0xd/0xe); GL cũ 15/16 làm assert mỗi nhịp tim
    assert((id==328 and faction==13) or ((id==331 or id==332) and faction==14), 'resource/faction mismatch')
    value=math.tointeger(value)
    assert(value and value>=0 and value<=2147483647, 'invalid four-school resource value')
    owner.cy_four_resources=owner.cy_four_resources or {}
    owner.cy_four_resources[name]=value
end
function M.snapshot(owner) return M.load(owner.cy_four_resources) end
function M.adapters()
    return {
        resource_get=function(_,owner,id) return owner:get_cy_four_resource(id) end,
        resource_set=function(_,owner,id,value) return owner:set_cy_four_resource(id,value) end,
    }
end
return M
