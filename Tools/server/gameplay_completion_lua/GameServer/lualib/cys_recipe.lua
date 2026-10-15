-- Ordinary table-driven recipes. Scripted recipes keep their authored callbacks.
-- Allocate outputs first, recheck the timed operation and its exact ingredients,
-- then consume and insert without yielding. No new recipe or chance is invented.
local define = require 'define'
local guard = require 'cys_inventory_guard'
local cfg = require('configenginer'):getinstance()
local items = require 'human_item_logic'
local opitem = require('item_operator'):getinstance()
local packets = require 'game.packet'
local authored = require 'cys_recipe_authored'
local R = define.OPERATE_RESULT
local M = {}
local function positive(v) return math.max(0, tonumber(v) or 0) end
local function recipe(a,h)
    local op=h:get_ability_opera()
    return op and a.abilityenginer:get_prescription_list()[op.pres_id],op
end
function M.ordinary(a,h)
    local row=recipe(a,h)
    return row and (row['脚本ID']==-1 or authored.handles(row))
end
function M.available(a,h)
    local row=recipe(a,h)
    if not row then return false end
    if authored.handles(row) then return true end
    local script=row['脚本ID']
    if script and script>0 then
        local engine=h:get_scene().scriptenginer
        -- Some authored special recipes consume within AbilityProduce.
        for _,method in ipairs({'AbilityCheck','AbilityProduce'}) do
            if not engine or not engine:have_function(script,method) then
                h:notify_tips('Công thức này đang thiếu xử lý trong dữ liệu máy chủ. Nguyên liệu chưa bị trừ.')
                return false
            end
        end
    end
    return true
end
local function materials(a,h,row,op)
    local need,parts,bound={},{},false
    if row._cys_needs then
        for id,count in pairs(row._cys_needs)do need[id]=count end
    else for n=1,5 do
        local id,count=row['Stuff'..n..'ID'],row['Stuff'..n..'num']
        if id and id>0 then
            if not guard.integer(count,1,65535) then return nil end
            need[id]=(need[id] or 0)+count
        end
    end end
    local bag=h:get_prop_bag_container()
    local special=(define.COMPOUND_MAT_ITEM_INDEX or {})[a.id]
    if special then
        local p=op.mat_bag_index
        local i=guard.accepts(bag,p) and bag:get_item(p)
        if not i or i:is_lock() or i:is_empty() or not special[i:get_index()] then return nil end
        parts[p]={item=i,id=i:get_index(),before=i:get_lay_count(),count=1}
        bound=i:is_bind()
    elseif op.mat_bag_index and op.mat_bag_index~=255 then return nil end
    for id,count in pairs(need) do
        local family=id//10000000
        local bagkind=(family==3 or family==1 or family==7) and 'prop' or family==4 and 'task' or 'material'
        for p,i in bag:ipairs(bagkind) do
            if count>0 and i and not i:is_lock() and i:get_index()==id then
                local part=parts[p]
                local take=math.min(count,i:get_lay_count()-(part and part.count or 0))
                if take>0 then
                    parts[p]=part or {item=i,id=id,before=i:get_lay_count(),count=0}
                    parts[p].count=parts[p].count+take
                    bound=bound or i:is_bind();count=count-take
                end
            end
        end
        if count>0 then return nil end
    end
    return parts,bound
end
function M.check(a,h,roll)
    local row,op=recipe(a,h)
    if not row or op._cys_recipe_completed or row['对应技能ID']~=a.id or op.ability_id~=a.id
        or not h:is_prescription_have_learnd(op.pres_id) or not h:is_alive() then return R.OR_WARNING end
    local ability=h:get_ability(a.id)
    if not ability or ability.level<row['技能等级需求（此列最低填1）'] then return R.OR_WARNING end
    row=authored.resolve(h,row,roll)
    if not row then return R.OR_STUFF_LACK end
    if ability.exp<positive(row['熟练度需求']) then return R.OR_EXP_LACK end
    if h:get_vigor()<positive(row['活力需求']) then return R.OR_NOT_ENOUGH_VIGOR end
    if h:get_stamina()<positive(row['精力需求']) then return R.OR_NOT_ENOUGH_ENERGY end
    -- The single legacy contribution recipe has no authored debit implementation.
    -- Reject before consumption instead of silently waiving that requirement.
    if positive(row['门派贡献度需求'])>0 then return R.OR_WARNING end
    local tool=row['需求工具ID']
    if tool and tool>0 and items:calc_bag_item_count(h,tool)<1 then return R.OR_NO_TOOL end
    local cooldown=row['冷却组ID']
    if cooldown and cooldown>=0 and not h:is_cool_downed(cooldown) then return R.OR_COOL_DOWNING end
    if not guard.integer(row.ResultID,1,99999999) or not guard.integer(row.ResultNum,1,250) then return R.OR_WARNING end
    for _,v in ipairs(row._cys_outputs or {{id=row.ResultID,count=row.ResultNum}})do
        local family=v.id//10000000
        if family<1 or family>7 then return R.OR_WARNING end
        local output=cfg:get_config(family==1 and 'equip_base' or family==5 and 'gem_info' or family==7 and 'pet_equip_base' or 'common_item')
        if not output or not output[v.id] then return R.OR_WARNING end
    end
    local parts,bound=materials(a,h,row,op)
    if not parts then return R.OR_STUFF_LACK end
    op.max_time=row['操作时间']
    return R.OR_OK,row,op,parts,bound,ability
end
local function unchanged(h,parts)
    local bag=h:get_prop_bag_container()
    for p,v in pairs(parts) do
        if bag:get_item(p)~=v.item or v.item:is_lock() or v.item:get_lay_count()~=v.before
            or v.item:get_index()~=v.id then return false end
    end
    return true
end
local function finish(a,h,kind)
    local res,row,op,parts,bound,ability=M.check(a,h,true)
    if res~=R.OR_OK then return res end
    local pres,level=op.pres_id,ability.level
    local def=cfg:get_config('ability')[a.id]
    local table_name=def['升级需求和消耗表']:gsub('%.txt$','')
    local cost=cfg:get_config(table_name=='menpaishenghuo' and table_name or 'ability_level_up_'..table_name)[level]
    if not cost then return R.OR_WARNING end
    local cap=cost['本级熟练度的上限']
    local way=1
    if row.ResultID//10000000==1 and not row._cys_outputs then
        if kind=='tailor' or kind=='artwork' then way=88
        elseif kind=='compound' then
            local special=parts[op.mat_bag_index]
            if not special then return R.OR_STUFF_LACK end
            way=a:cal_way(row.ResultID,special.id)
        end
    end
    local products={}
    for _,v in ipairs(row._cys_outputs or {{id=row.ResultID,count=row.ResultNum}})do
        local sample=opitem:gen_item({},v.id,v.way or way)
        if not sample then return R.OR_ERROR end
        local maximum=sample:get_max_tile_count()
        if not guard.integer(maximum,1,250) then return R.OR_ERROR end
        local prepared={sample}
        for n=2,math.ceil(v.count/maximum)do
            prepared[n]=opitem:gen_item({},v.id,v.way or way)
            if not prepared[n]then return R.OR_ERROR end
        end
        for _,i in ipairs(prepared)do
            i:set_is_bind(bound)
            if i:is_equip()then i:set_item_creator(h:get_name());i:set_item_record_data_forindex('artisanal',h:get_menpai())end
        end
        products[#products+1]={sample=sample,maximum=maximum,prepared=prepared,count=v.count,id=v.id}
    end
    local refreshed
    res,refreshed=M.check(a,h)
    if res~=R.OR_OK then return res end
    if refreshed['活力需求']~=row['活力需求'] or refreshed['精力需求']~=row['精力需求']
        or refreshed._cys_assist~=row._cys_assist then return R.OR_WARNING end
    if h:get_ability_opera()~=op or op.pres_id~=pres or h:get_ability(a.id)~=ability
        or ability.level~=level or not unchanged(h,parts) then return R.OR_WARNING end
    local bag=h:get_prop_bag_container()
    local changes,reserved={},{}
    for _,product in ipairs(products)do
        local sample,maximum,prepared=product.sample,product.maximum,product.prepared
        local left,next_new=product.count,1
        local bagkind=sample:get_place_bag()
        for p,i in bag:ipairs(bagkind)do
            if left>0 and not reserved[p] and not parts[p] and guard.stackable(sample,i)then
                local add=math.min(left,maximum-i:get_lay_count())
                if add>0 then changes[#changes+1]={p=p,item=i,before=i:get_lay_count(),count=i:get_lay_count()+add,old=i};left=left-add;reserved[p]=true end
            end
        end
        for p,i in bag:ipairs(bagkind)do
            if left>0 and not reserved[p] and (not i or parts[p]and parts[p].count==parts[p].before)then
                local add=math.min(left,maximum)
                changes[#changes+1]={p=p,item=prepared[next_new],count=add,old=i,before=i and i:get_lay_count()}
                next_new=next_new+1;left=left-add;reserved[p]=true
            end
        end
        if left>0 then return R.OR_BAG_OUT_OF_SPACE end
    end
    if not unchanged(h,parts) then return R.OR_STUFF_LACK end
    for _,c in ipairs(changes) do
        if bag:get_item(c.p)~=c.old or c.old and (c.old:is_lock() or c.old:get_lay_count()~=c.before) then return R.OR_BAG_OUT_OF_SPACE end
    end
    if h:get_ability_opera()~=op or op.pres_id~=pres or not h:is_alive()
        or h:get_ability(a.id)~=ability or ability.level~=level or not h:is_prescription_have_learnd(pres)
        or h:get_vigor()<positive(row['活力需求']) or h:get_stamina()<positive(row['精力需求']) then return R.OR_WARNING end
    -- Commit: the following inventory/stat mutations and sends do not yield.
    op._cys_recipe_completed=true
    for p,v in pairs(parts) do
        if v.id//10000000==1 or v.id//10000000==7 then
            assert(v.count==1);assert(items:erase_item_by_bag_index({},h,p))
        else assert(items:dec_item_lay_count({},h,p,v.count,v.id))end
    end
    h:set_vigor(h:get_vigor()-positive(row['活力需求']))
    h:set_stamina(h:get_stamina()-positive(row['精力需求']))
    if row['冷却组ID']>=0 and positive(row['冷却时间(毫秒)'])>0 then h:set_cool_down(row['冷却组ID'],row['冷却时间(毫秒)']) end
    for _,c in ipairs(changes) do c.item:set_lay_count(c.count);bag:set_item(c.p,c.item) end
    for _,c in ipairs(changes) do
        local n=packets.GCNotifyEquip.new();n.bag_index,n.item=c.p,c.item:copy_raw_data();h:get_scene():send2client(h,n)
        n=packets.GCItemInfo.new();n.bagIndex,n.item=c.p,c.item:copy_raw_data();h:get_scene():send2client(h,n)
    end
    local difference=level-(row._cys_gain_level or row['技能等级需求（此列最低填1）'])
    local gain=difference==0 and 100 or difference==1 and 50 or 0
    if not row._cys_no_gain and cap and ability.exp<cap and gain>0 then h:set_ability_exp(a.id,math.min(cap,ability.exp+gain),cap) end
    for _,product in ipairs(products)do
        local n=packets.GCAbilitySucc.new()
        n.ability,n.prescription,n.item_index,n.num=a.id,pres,product.id,product.count
        h:get_scene():send2client(h,n)
    end
    return R.OR_OK
end
function M.finish(a,h,kind)
    if h._cys_recipe_busy then return R.OR_WARNING end
    h._cys_recipe_busy=true
    local ok,res=xpcall(finish,debug.traceback,a,h,kind)
    h._cys_recipe_busy=nil
    if not ok then error(res) end
    return res
end
return M
