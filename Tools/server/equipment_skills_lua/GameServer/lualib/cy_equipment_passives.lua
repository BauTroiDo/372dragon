-- CY LongWen extended properties. Item identities are deliberately explicit:
-- their IDs collide with GL LingYu templates, which must not initialize or apply them.
local tables=require('cy_equipment_skill_data').tables
local M={}
local roots={{1},{21,31,41,51},{11,61,71,81}}
local function int(n)return type(n)=='number' and n==math.floor(n)end
function M.kind(id)
    if id==10157001 or id==10157002 then return 19 end
    if tables.RLBase[id] then return 20 end
end
function M.lw_decode(creator)
    creator=creator or ''
    local a,b,c,d,e=creator:match('&LW(%d%d)(%d)(%d%d)(%d)(%d%d)')
    if not a then return not creator:find('&LW',1,true) and {0,0,0} or nil end
    a,b,c,d,e=tonumber(a),tonumber(b),tonumber(c),tonumber(d),tonumber(e)
    if a>10 or b>4 or c>10 or d>4 or e>10 or (b==0)~=(c==0) or (d==0)~=(e==0) then return nil end
    return {a,b>0 and roots[2][b]+c-1 or 0,d>0 and roots[3][d]+e-1 or 0}
end
function M.lw_encode(creator,ids)
    local values={}
    for slot,id in ipairs(ids)do
        if id==0 then values[slot]={0,0} else
            for kind,root in ipairs(roots[slot])do if id>=root and id<root+10 then values[slot]={kind,id-root+1}end end
        end
        if not values[slot]then return nil end
    end
    local code=string.format('&LW%02d%d%02d%d%02d',values[1][2],values[2][1],values[2][2],values[3][1],values[3][2])
    creator=creator or ''
    if creator:find('&LW',1,true) then return (creator:gsub('&LW%d%d%d%d%d%d%d%d',code,1))end
    if #creator+#code>32 then return nil end
    return creator..code
end
function M.initialize(item)
    local kind=M.kind(item:get_index());if not kind then return false end
    item:get_equip_data():set_equip_type(0)
    -- Empty source state: extensions are learned by the character, never granted here.
    item:set_item_creator(kind==19 and '&LW00000000' or '&LP10000000000000000000')
    return true
end
function M.apply_attributes(attrib,item,slot)
    if M.kind(item:get_index())~=19 or slot~=19 then return end
    local ids=M.lw_decode(item:get_item_creator());if not ids then return end
    -- LongWenAddAttr columns 12..20 (zero based) map to these CY ItemAttribute IDs.
    local attributes={1,8,11,14,17,6,9,12,15}
    for _,id in ipairs(ids)do
        local row=tables.LongWenAddAttr[id]
        if row then for i,attribute in ipairs(attributes)do
            local value=row[12+i]
            if value and value>0 then attrib:cal_item_effect(attribute,value,slot,item:get_serial_type())end
        end end
    end
end
function M.lw_operation(human,pos,operation,selection)
    local logic=require 'human_item_logic'
    if not int(pos) or pos<0 or pos>254 or not int(operation) or operation<4 or operation>9 then return false end
    local bag=human:get_prop_bag_container();local item=bag:get_item(pos)
    if not item or item:get_serial_class()~=1 or M.kind(item:get_index())~=19 or item:is_lock() then return false end
    local ids=M.lw_decode(item:get_item_creator());if not ids then return false end
    local slot=({[4]=1,[5]=3,[6]=2,[7]=1,[8]=3,[9]=2})[operation]
    local row,target,material,count,money
    if operation<=6 then
        selection=slot==1 and 1 or selection
        if not int(selection) or not roots[slot][selection] then return false end
        target=roots[slot][selection];row=tables.LongWenAddAttr[target]
        if ids[slot]>=target and ids[slot]<target+10 then return false end
        material,count,money=row[4],row[5],row[6]
    else
        row=tables.LongWenAddAttr[ids[slot]]
        if not row or row[9]<0 or not tables.LongWenAddAttr[row[9]] then return false end
        target=row[9];material,count,money=row[10],row[11],row[12]
    end
    ids[slot]=target
    local creator=M.lw_encode(item:get_item_creator(),ids)
    if not creator or human:get_money()+human:get_jiaozi()<money then return false end
    local remaining=count;local consume={};local bind=false
    for _,page in ipairs({'prop','material'})do
        for p,mat in bag:ipairs(page)do
            if mat and not mat:is_lock() and (mat:get_index()==material or mat:get_index()==material+8) then
                local n=math.min(remaining,mat:get_lay_count())
                if n>0 then consume[#consume+1]={p,n,mat:get_index()};remaining=remaining-n;bind=bind or mat:is_bind()end
                if remaining==0 then break end
            end
        end
        if remaining==0 then break end
    end
    if remaining~=0 then return false end
    -- Invoked inside the owning human actor: all decrements and writes below are local.
    for _,entry in ipairs(consume)do
        assert(logic:dec_item_lay_count({reason='cy_lw_skill'},human,entry[1],entry[2],entry[3]))
    end
    human:cost_money_with_priority(money,'cy_lw_skill')
    item:get_equip_data():set_equip_type(0)
    item:set_item_creator(creator);if bind then item:set_is_bind(true)end
    local msg=require('game.packet').GCItemInfo.new();msg.bagIndex=pos;msg.item=item:copy_raw_data()
    human:get_scene():send2client(human,msg)
    return true
end
return M
