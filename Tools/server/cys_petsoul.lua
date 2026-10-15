-- GL PetSoul_LevelUp/BloodLevelUp/XiShuxing/Addlife, using the native server tables.
local cfg=require('configenginer'):getinstance()
local logic=require 'human_item_logic'
local packets=require 'game.packet'
local guard=require 'cys_inventory_guard'
local data=require 'cys_power_data'
local M={UI=990028}
-- Native pet equip packets are retained; validate all ownership/container rules
-- before their legacy handler can bind or exchange an item.
function M.can_equip(scene,id,request,remove)
    local h=scene:get_obj_by_id(id);local g=request.pet_guid
    if not h or h:is_die() or h._leaving or type(g)~='table' or not guard.integer(g.m_uHighSection,0,4294967295) or not guard.integer(g.m_uLowSection,0,4294967295) then return false end
    local guid=require('pet_guid').new();guid:set(g.m_uHighSection,g.m_uLowSection)
    local pet=h:get_pet_bag_container():get_pet_by_guid(guid)
    if not pet or pet:is_lock() or pet:is_in_exchange() or guid==h:get_current_pet_guid() or guid==h:get_current_soul_melting_pet_guid() then
        h:notify_tips('Thu hồi trân thú và tách dung hồn trước khi thay trang bị.');return false
    end
    local bag=h:get_prop_bag_container();local equips=pet:get_equip_container()
    if remove then
        if not guard.integer(request.from,0,5) then return false end
        local item=equips:get_item(request.from)
        return item~=nil and not item:is_empty() and not item:is_lock()
    end
    if not guard.accepts(bag,request.from) then return false end
    local item=bag:get_item(request.from)
    if not item or item:is_empty() or item:is_lock() or item:get_serial_class()~=7 then return false end
    local base=item:get_base_config();local point=base and base.equip_point
    if not guard.integer(point,0,5) or point~=request.to or pet:get_level()<(base.level or 0) then return false end
    local old=equips:get_item(point)
    return not old or not old:is_lock()
end
local function same(a,b) return a and b and a.world==b.world and a.server==b.server and a.series==b.series end
local function soul(h,pos)
    if not guard.integer(pos,0,199) then return end
    local item=h:get_prop_bag_container():get_item(pos)
    if not item or item:is_empty() or item:is_lock() or item:get_serial_class()~=7 then return end
    local e=item:get_pet_equip_data()
    if e:get_pet_equip_type()~=1 or not cfg:get_config('pet_soul_base')[item:get_index()] then return end
    return item,e
end
local function update(h,pos,item)
    local p=packets.GCItemInfo.new();p.bagIndex=pos;p.item=item:copy_raw_data();h:get_scene():send2client(h,p)
end
local function plan(h,ids,count)
    local parts={};local remain=count
    for pos=0,199 do
        local item=h:get_prop_bag_container():get_item(pos)
        if item and not item:is_empty() and not item:is_lock() and ids[item:get_index()] then
            local n=math.min(remain,item:get_lay_count());parts[#parts+1]={pos=pos,n=n,id=item:get_index(),bind=item:is_bind()};remain=remain-n
            if remain==0 then return parts end
        end
    end
end
local function consume(h,parts)
    local bound=false
    for _,p in ipairs(parts) do
        assert(logic:dec_item_lay_count({},h,p.pos,p.n,p.id),'validated soul material changed');bound=bound or p.bind
    end
    return bound
end
local function attr_text(attrs)
    local text={};local ext=cfg:get_config('pet_soul_extension')
    for i=1,6 do
        local a=attrs[i];local type=a and a.type or -1
        if type>=0 then
            local template=data.soul_text[type]
            -- GL LuaFnGetPetSoulData EXTENSION: types15..22 floor(value/10)/10,
            -- formatted to one decimal; the template uses printf's literal %%.
            local value=type>=15 and type<=22 and string.format('%.1f',math.floor((a.value or 0)/10)/10) or tostring(a.value or 0)
            local desc=template and template:gsub('%%s',value):gsub('%%%%','%%') or ('Thuộc tính '..type..': '..value)
            text[#text+1]=i..'. '..desc
        end
    end
    return table.concat(text,'\n')
end
function M.quote(s,h,pos,opening)
    pos=guard.integer(pos,0,199) and pos or -1
    local item,e=soul(h,pos);h._cys_soul_quote=nil
    local rev=(h._cys_soul_revision or 0)%2147483646+1;h._cys_soul_revision=rev
    s:BeginUICommand()
    local ints={rev,pos,opening and 1 or 0,item and item:get_index() or 0}
    local text='Kéo Thú hồn từ hành trang vào ô bên trái.'
    if item then
        local level=e:get_level();local quality=e:get_pet_soul_quanlity();local blood=e:get_pet_soul_level()
        local costs=cfg:get_config('pet_soul_level_cost')[level]
        local count=costs and costs.cost_count[quality+1] or 0;local money=costs and costs.cost_money[quality+1] or 0
        local pending=h._cys_soul_pending
        if pending and (not same(pending.guid,item:get_guid()) or pending.pos~=pos) then h._cys_soul_pending=nil;pending=nil end
        local life=e.pet_equip_unknow_8 or 0;local maxlife=data.soul_maxlife[item:get_index()] or 0
        for _,v in ipairs({level,quality,blood,e:get_pet_soul_exp(),life,maxlife,count,money,pending and 1 or 0}) do ints[#ints+1]=v end
        local base=cfg:get_config('pet_soul_base')[item:get_index()]
        text=string.format('Cấp: %d / 100    Phẩm: %d\nHuyết mạch: %d / 6    Kinh nghiệm: %d\nThọ: %d / %d\nNâng cấp: %d Thăng Hồn Đan + %d vàng/giao tử\nHồn ngọc phù hợp: %s\n\n%s',level,quality,blood+1,e:get_pet_soul_exp(),life,maxlife,count,money,data.soul_material_name[base.material] or 'Hồn ngọc',attr_text(e:get_pet_soul_attr()))
        if pending then text=text..'\n\nKẾT QUẢ TẨY CHƯA NHẬN:\n'..attr_text(pending.attrs) end
        local g=item:get_guid();h._cys_soul_quote={pos=pos,rev=rev,guid={world=g.world,server=g.server,series=g.series},level=level,blood=blood}
    end
    for _,v in ipairs(ints) do s:UICommand_AddInt(v) end
    s:UICommand_AddStr(text);s:EndUICommand();s:DispatchUICommand(h:get_obj_id(),M.UI)
end
local function fail(s,h,pos,text) s:notify_tips(h:get_obj_id(),text);M.quote(s,h,pos,false);return false end
function M.action(s,h,op,pos,revision,material)
    if op==0 then M.quote(s,h,guard.integer(pos,0,199) and pos or -1,true);return true end
    local q=h._cys_soul_quote;local item,e=soul(h,pos)
    if not guard.integer(op,1,5) or not q or q.rev~=revision or q.pos~=pos or not item or not same(q.guid,item:get_guid()) or q.level~=e:get_level() or q.blood~=e:get_pet_soul_level() then return fail(s,h,pos,'Thú hồn đã thay đổi. Hãy đặt lại vật phẩm.') end
    if h:is_die() or h._leaving or s:IsPilferLockFlag(h:get_obj_id()) then return fail(s,h,pos,'Không thể thao tác Thú hồn lúc này.') end
    local level=e:get_level();local quality=e:get_pet_soul_quanlity();local blood=e:get_pet_soul_level();local bound=false
    if op==1 then
        local cost=cfg:get_config('pet_soul_level_cost')[level]
        local next=cfg:get_config('pet_soul_level_up_info')[item:get_index()]
        if level>=100 or not cost or not next or not next[level+1] then return fail(s,h,pos,'Đã đạt giới hạn cấp hoặc chưa có dữ liệu cấp tiếp theo.') end
        local count,money=cost.cost_count[quality+1],cost.cost_money[quality+1]
        local parts=count and plan(h,{[38002530]=true},count)
        if not parts or not money or not h:check_money_with_priority(money) then return fail(s,h,pos,'Không đủ Thăng Hồn Đan hoặc vàng/giao tử.') end
        bound=consume(h,parts);h:cost_money_with_priority(money,'Pet soul level');e:set_level(level+1)
    elseif op==2 or op==5 then
        if not guard.integer(material,0,199) or material==pos then return fail(s,h,pos,'Hãy đặt Hồn ngọc vào ô nguyên liệu.') end
        local m=h:get_prop_bag_container():get_item(material)
        if not m or m:is_empty() or m:is_lock() then return fail(s,h,pos,'Nguyên liệu không còn hoặc đang khóa.') end
        local id=m:get_index();local base=cfg:get_config('pet_soul_base')[item:get_index()]
        local material_quality=id>=38002525 and id<=38002529 and 0 or id>=38002520 and id<=38002524 and 1 or (id>=38002515 and id<=38002519 or id==38002741 or id==38002742) and 2 or id==38002732 and 3 or -1
        if material_quality<0 or (op==2 and material_quality~=quality and not (material_quality==2 and quality==3)) then return fail(s,h,pos,'Hồn ngọc không phù hợp.') end
        if op==2 then
            if blood>=5 then return fail(s,h,pos,'Đã đạt huyết mạch tối đa; nguyên liệu được giữ lại.') end
            local exp=e:get_pet_soul_exp()+(id==38002742 and 100 or id==base.material and 20 or 10)
            while blood<5 and exp>=base.exps[blood+1] do exp=exp-base.exps[blood+1];blood=blood+1 end
            if blood>=5 then exp=0 end
            bound=consume(h,{{pos=material,n=1,id=id,bind=m:is_bind()}});e:set_pet_soul_level(blood);e:set_pet_soul_exp(exp)
        else
            if material_quality>quality then return fail(s,h,pos,'Phẩm Hồn ngọc không được cao hơn Thú hồn.') end
            local current=e.pet_equip_unknow_8 or 0;local maxlife=data.soul_maxlife[item:get_index()] or 0
            if current>=maxlife then return fail(s,h,pos,'Thọ của Thú hồn đã đầy.') end
            local life=({[0]=50,[1]=100,[2]=200,[3]=200})[material_quality]
            bound=consume(h,{{pos=material,n=1,id=id,bind=m:is_bind()}});e.pet_equip_unknow_8=math.min(maxlife,current+life)
        end
    elseif op==3 then
        local materials=quality==0 and {[38002534]=true} or quality==1 and {[38002533]=true,[38002541]=true} or {[38002532]=true,[38002540]=true}
        local parts=plan(h,materials,1)
        if not parts or not h:check_money_with_priority(50000) then return fail(s,h,pos,'Tẩy thuộc tính cần 1 Thối Hồn Dịch/Thúy Hồn Thủy phù hợp và 50000 vàng/giao tử.') end
        -- Generate before any cost so malformed configuration cannot consume materials.
        local attrs=e:gen_soul_attr(0,0);if type(attrs)~='table' or #attrs~=6 then return fail(s,h,pos,'Không tạo được thuộc tính; chưa trừ nguyên liệu.') end
        bound=consume(h,parts);h:cost_money_with_priority(50000,'Pet soul reforge')
        -- Preserve the same paid-material counters used by YunShenShen's rewards.
        local md=require('define').MD_ENUM
        local counter=quality>=2 and md.MD_COST_CHU_HUN_SUI or quality==1 and md.MD_COST_CHU_HUN_YE
        if counter then s:SetMissionData(h:get_obj_id(),counter,s:GetMissionData(h:get_obj_id(),counter)+1) end
        h._cys_soul_pending={guid=q.guid,pos=pos,attrs=attrs}
    elseif op==4 then
        local pending=h._cys_soul_pending
        if not pending or pending.pos~=pos or not same(pending.guid,item:get_guid()) then return fail(s,h,pos,'Không có kết quả tẩy hợp lệ cho Thú hồn này.') end
        e:set_pet_soul_attr(pending.attrs);h._cys_soul_pending=nil
    end
    if bound then item:set_is_bind(true) end
    update(h,pos,item);M.quote(s,h,pos,false);return true
end
return M
