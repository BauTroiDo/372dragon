-- CY ShenMuWangDing.lua (901000): 45 pills, two tracks, shared medicine dust.
-- Values come from cys_power_data.lua; the server owns costs and progression.
local guard=require 'cys_inventory_guard'
local logic=require 'human_item_logic'
local data=require 'cys_power_data'
local M={UI=990027}
local function integer(v,a,b) return guard.integer(v,a,b) end
function M.init(saved)
    saved=type(saved)=='table' and saved or {}
    local s={}
    for _,k in ipairs({'dust','con','attack','con_gold','attack_gold','ice','fire','light','poison'}) do
        local v=saved[k] or 0
        local cap=(k=='con' or k=='attack') and 45 or (k=='con_gold' or k=='attack_gold') and 10 or k=='dust' and 9999999 or 9999
        assert(integer(v,0,cap),'invalid saved ShenDing '..k)
        s[k]=v
    end
    return s
end
function M.max_gold(count)
    -- CY item descriptions specify seven at grade 8, ten only at grade 9.
    if count>=45 then return 10 elseif count>=36 then return 7 elseif count>=28 then return 5 elseif count>=21 then return 3 elseif count>=15 then return 1 end
    return 0
end
function M.values(s)
    local con,points=s.con_gold*100,s.attack_gold*80
    for i=1,s.con do con=con+data.ding[i].con end
    for i=1,s.attack do points=points+data.ding[i].attack end
    return con,points-s.ice-s.fire-s.light-s.poison
end
function M.attributes(db)
    local h=db:get_human();local s=h.cys_shending
    if not s then return end
    local con=M.values(s)
    for _,pair in ipairs({{44,con},{6,s.ice},{9,s.fire},{12,s.light},{15,s.poison}}) do
        if pair[2]>0 then db:cal_item_effect(pair[1],pair[2]) end
    end
end
function M.payload(h,opening)
    local s=h.cys_shending;local con,points=M.values(s)
    return {h.cys_shending_revision,opening and 1 or 0,s.dust,s.con,s.attack,s.con_gold,s.attack_gold,
        con,points,s.ice,s.fire,s.light,s.poison,M.max_gold(s.con),M.max_gold(s.attack)}
end
function M.sync(h)
    -- SelfEquip needs this before the player has ever opened the ShenDing page.
    if not h.cys_shending then return end
    local p=require('game.packet').GCUICommand.new()
    p.m_nUIIndex=M.UI;p.m_Param.m_aIntValue=M.payload(h,false)
    p.m_Param.m_IntCount=#p.m_Param.m_aIntValue
    h:get_scene():send2client(h,p)
end
function M.snapshot(script,h,opening)
    script:BeginUICommand()
    for _,v in ipairs(M.payload(h,opening)) do script:UICommand_AddInt(v) end
    script:EndUICommand();script:DispatchUICommand(h:get_obj_id(),M.UI)
end
local function fail(script,h,message)
    script:notify_tips(h:get_obj_id(),message);M.snapshot(script,h,false);return false
end
local function consume(h,ids)
    local bag=h:get_prop_bag_container()
    for i=0,199 do
        local item=bag:get_item(i)
        if item and not item:is_empty() and not item:is_lock() and ids[item:get_index()] then
            if logic:dec_item_lay_count({},h,i,1,item:get_index()) then return ids[item:get_index()] end
        end
    end
end
function M.action(script,h,op,revision,a,b,c,d)
    if op==0 then M.snapshot(script,h,true);return true end
    if not integer(op,1,7) or revision~=h.cys_shending_revision then return M.snapshot(script,h,false) end
    if h:is_die() or h._leaving or h:get_level()<15 then return fail(script,h,'Thần Đỉnh yêu cầu nhân vật cấp 15 và còn sống.') end
    if script:IsPilferLockFlag(h:get_obj_id()) then return fail(script,h,'Hãy mở khóa bảo vệ trước khi thao tác.') end
    local s=h.cys_shending
    if op==1 or op==2 then
        local key=op==1 and 'con' or 'attack';local next_level=s[key]+1;local row=data.ding[next_level]
        if not row then return fail(script,h,'Đã ngưng đủ 45 đan của nhánh này.') end
        if s.dust<row.cost then return fail(script,h,'Không đủ Dược Trần; cần '..row.cost..' điểm.') end
        s.dust=s.dust-row.cost;s[key]=next_level
    elseif op==3 or op==4 then
        local key=op==3 and 'con' or 'attack';local gold=key..'_gold'
        if s[gold]>=M.max_gold(s[key]) then return fail(script,h,'Chưa đủ phẩm đan hoặc đã đạt giới hạn dung hợp.') end
        if not consume(h,data.gold[key]) then return fail(script,h,'Không có Kim Đan phù hợp trong hành trang.') end
        s[gold]=s[gold]+1
    elseif op==5 then
        local vals={a,b,c,d};local keys={'ice','fire','light','poison'};local spent=0
        for i,key in ipairs(keys) do
            if not integer(vals[i],s[key],9999) then return fail(script,h,'Điểm phân phối không hợp lệ; dùng Thiết lập lại để thu hồi điểm.') end
            spent=spent+vals[i]-s[key]
        end
        local _,remaining=M.values(s)
        if spent<=0 or spent>remaining then return fail(script,h,'Không đủ điểm Côn Võ để phân phối.') end
        for i,key in ipairs(keys) do s[key]=vals[i] end
    elseif op==6 then
        if s.ice+s.fire+s.light+s.poison==0 then return fail(script,h,'Chưa có điểm Côn Võ đã phân phối.') end
        if s.dust<2000 then return fail(script,h,'Thiết lập lại cần 2000 Dược Trần.') end
        s.dust=s.dust-2000;s.ice=0;s.fire=0;s.light=0;s.poison=0
    elseif op==7 then
        -- Explicitly consume one dust item; never buy currency on the player's behalf.
        local eligible={}
        for id,value in pairs(data.dust) do if s.dust+value<=9999999 then eligible[id]=value end end
        local amount=consume(h,eligible)
        if not amount then return fail(script,h,'Không có vật phẩm Dược Trần phù hợp, hoặc đã đầy điểm Dược Trần.') end
        s.dust=s.dust+amount
    end
    h.cys_shending_revision=h.cys_shending_revision%2147483646+1
    h:item_flush();M.snapshot(script,h,false)
    return true
end
return M
