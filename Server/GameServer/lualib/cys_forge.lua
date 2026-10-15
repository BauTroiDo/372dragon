-- Private CY extension. Existing ItemEnhance bonuses/prices, new timing rule.
local skynet = require "skynet"
local define = require "define"
local packets = require "game.packet"
local logic = require "human_item_logic"
local M = { UI = 990023 }
local widths = {3000,2700,2400,2100,1800,1500,1200,900,600}
local periods = {2600,2400,2200,2000,1800,1600,1400,1200,1000}
local function integer(v) return type(v)=="number" and v==math.floor(v) end
local function pos(v) return integer(v) and v>=0 and v<200 end
local function same(g, h) return g and h and g.world==h.world and g.server==h.server and g.series==h.series end
local function emit(s, h, ints, text)
    s:BeginUICommand()
    for _, v in ipairs(ints) do s:UICommand_AddInt(v) end
    if text then s:UICommand_AddStr(text) end
    s:EndUICommand(); s:DispatchUICommand(h:get_obj_id(), M.UI)
end
local function reject(s,h,seq,text) emit(s,h,{3,seq or 0},text) end
local function update(h,slot,item)
    local p=packets.GCItemInfo.new(); p.bagIndex=slot; p.item=item:copy_raw_data()
    h:get_scene():send2client(h,p)
end
local excluded = {}
for _, name in ipairs({"HEQUIP_RIDER","HEQUIP_UNKNOW1","HEQUIP_UNKNOW2","HEQUIP_FASHION",
    "HEQUIP_WUHUN","LINGWU_JING","LINGWU_CHI","LINGWU_JIA","LINGWU_GOU","LINGWU_DAI","LINGWU_DI"}) do
    local n=define.HUMAN_EQUIP[name]; if n then excluded[n]=true end
end
local function equipment(h,slot,locked)
    if not pos(slot) or h:is_die() then return nil,"Không thể rèn lúc này." end
    local e=h:get_prop_bag_container():get_item(slot)
    if not e or e:is_empty() or e:get_serial_class()~=define.ITEM_CLASS.ICLASS_EQUIP then
        return nil,"Hãy đặt trang bị từ hành trang vào ô rèn."
    end
    local b=e:get_base_config()
    if not b or excluded[b.equip_point] or not e:get_next_enhance_config() then
        return nil,"Loại trang bị này không thể cường hoá."
    end
    if e:is_lock() and not locked then return nil,"Trang bị đang bị khoá." end
    if not e:is_identd() then return nil,"Trang bị chưa được giám định." end
    return e
end
local labels={{21,"Ngoại công"},{28,"Nội công"},{24,"Ngoại thủ"},{31,"Nội thủ"},{75,"Chính xác"},{76,"Né tránh"},{1,"Sinh lực"},{4,"Khí"}}
local function description(e)
    local a=e:get_enhance_config(); local b=e:get_next_enhance_config(); local rows={}
    for _,v in ipairs(labels) do
        local old=a and a.bonus[v[1]] or 0;local new=b and b.bonus[v[1]] or 0
        if old~=0 or new~=0 then rows[#rows+1]=string.format("%s: +%d%% → +%d%%",v[2],old,new) end
    end
    return table.concat(rows,"\n")
end
function M.quote(s,h,slot,seq)
    skynet.error("[CYS-FORGE] quote",h:get_guid(),slot,seq)
    if not integer(seq) or seq<1 then return end
    if h.cys_forge then return reject(s,h,seq,"Hãy hoàn tất lượt đang rèn.") end
    local e,err=equipment(h,slot);if not e then return reject(s,h,seq,err) end
    local lv=e:get_equip_data():get_enhancement_level()
    local material=e:get_base_config().level<40 and 30900005 or 30900006
    local g=e:get_guid()
    h._cys_forge_quote={seq=seq,slot=slot,level=lv,guid={world=g.world,server=g.server,series=g.series}}
    skynet.error("[CYS-FORGE] quoted",h:get_guid(),seq,lv)
    emit(s,h,{0,seq,slot,lv,e:get_next_enhance_config().cost_money,material,material==30900006 and 30900045 or 0},description(e))
end
function M.position(elapsed,period)
    local t=elapsed%(2*period)
    if t>period then t=2*period-t end
    return t*10000/period
end
function M.finish(h,success,quiet)
    local p=h.cys_forge;if not p then return nil end
    h.cys_forge=nil;h._cys_forge_quote=nil
    local e=h:get_prop_bag_container():get_item(p.slot)
    if not e or not same(e:get_guid(),p.guid) then
        skynet.error("[CYS-FORGE] pending identity missing",h:get_guid(),p.slot)
        return nil
    end
    local lv=success and math.min(9,p.level+1) or math.max(0,p.level-1)
    e:get_equip_data():set_enhancement_level(lv)
    e:set_param(9,0,"ushort");e:set_lock(false)
    if not quiet then update(h,p.slot,e) end
    skynet.error("[CYS-FORGE] result",h:get_guid(),p.nonce,success and 1 or 0,p.level,lv)
    return lv,p
end
function M.recover(h,saved)
    if type(saved)=="table" and saved.guid and pos(saved.slot) and integer(saved.level) and saved.level>=0 and saved.level<9 then
        h.cys_forge=saved;M.finish(h,false,true)
    end
end
function M.begin(s,h,slot,material_slot,seq)
    if not integer(seq) or seq<1 then return end
    if h.cys_forge then return reject(s,h,seq,"Lượt rèn đã bắt đầu; không trừ thêm chi phí.") end
    local q=h._cys_forge_quote
    local e,err=equipment(h,slot);if not e then return reject(s,h,seq,err) end
    local lv=e:get_equip_data():get_enhancement_level()
    if lv>=9 then return reject(s,h,seq,"Đã đạt giới hạn +9. Trang bị cấp cao hơn được giữ nguyên.") end
    if not q or q.seq~=seq or q.slot~=slot or q.level~=lv or not same(e:get_guid(),q.guid) then
        return reject(s,h,seq,"Trang bị đã thay đổi. Hãy đặt lại vào ô rèn.")
    end
    if not pos(material_slot) or material_slot==slot then return reject(s,h,seq,"Hãy đặt nguyên liệu vào ô bên cạnh.") end
    local bag=h:get_prop_bag_container();local m=bag:get_item(material_slot)
    if not m or m:is_empty() or m:is_lock() or m:get_lay_count()<1 then return reject(s,h,seq,"Nguyên liệu không còn hoặc đang bị khoá.") end
    local mid=m:get_index();local low=e:get_base_config().level<40
    if (low and mid~=30900005) or (not low and mid~=30900006 and mid~=30900045) then
        return reject(s,h,seq,"Nguyên liệu không phù hợp với cấp trang bị.")
    end
    if m:is_bind() and (e:get_index()==10423024 or e:get_index()==10422016) then
        return reject(s,h,seq,"Trang bị này không dùng nguyên liệu đã khoá giao dịch.")
    end
    local used=mid==30900045 and (m:get_param(8,nil) or 0) or 0
    if used<0 or used>=11 then return reject(s,h,seq,"Lộ Cường Hoá đã hết lượt sử dụng.") end
    local cost=e:get_next_enhance_config().cost_money
    if not integer(cost) or cost<1 or not h:check_money_with_priority(cost) then return reject(s,h,seq,"Không đủ vàng/giao tử để bắt đầu lượt rèn.") end
    -- All validation precedes cost. These local mutations and skynet.send do not yield.
    local bind=m:is_bind()
    if mid==30900045 and used<10 then
        m:set_param(4,11,nil);m:set_param(8,used+1,nil);update(h,material_slot,m)
    elseif not logic:dec_item_lay_count({},h,material_slot,1,mid) then
        return reject(s,h,seq,"Không thể trừ nguyên liệu; lượt rèn chưa bắt đầu.")
    elseif mid==30900045 then
        local remaining=bag:get_item(material_slot)
        if remaining and not remaining:is_empty() and remaining:get_index()==mid then
            remaining:set_param(4,11,nil);remaining:set_param(8,0,nil);update(h,material_slot,remaining)
        end
    end
    h:cost_money_with_priority(cost,"CYS forge attempt")
    if bind then e:set_is_bind(true) end
    e:set_lock(true)
    local nonce=math.random(1,2147483646)
    h.cys_forge={seq=seq,nonce=nonce,slot=slot,guid=q.guid,level=lv,
        start=skynet.now()*10+1000,center=math.random(3000,7000),width=widths[lv+1],period=periods[lv+1]}
    local p=h.cys_forge;update(h,slot,e)
    emit(s,h,{1,seq,nonce,lv,p.center,p.width,p.period,1000,cost})
    skynet.error("[CYS-FORGE] begin",h:get_guid(),nonce,lv,cost,mid)
end
function M.strike(s,h,nonce,elapsed)
    local p=h.cys_forge
    if not p or not integer(nonce) or nonce~=p.nonce then return end
    local server_age=skynet.now()*10-p.start
    -- Timestamp is untrusted: bounded transport allowance, no arbitrary rewinding.
    local time_ok=integer(elapsed) and elapsed>=0 and math.abs(server_age-elapsed)<=350
    local x=time_ok and M.position(elapsed,p.period) or -100000
    local hit=time_ok and math.abs(x-p.center)<=p.width/2
    local lv=M.finish(h,hit)
    if lv then emit(s,h,{2,p.seq,nonce,hit and 1 or 0,lv},hit and "Rèn thành công!" or "Trượt nhịp — giảm 1 cấp, mất lượt rèn.") end
end
function M.cancel(s,h,seq)
    local p=h.cys_forge
    if p and p.seq==seq then
        local lv=M.finish(h,false)
        if lv then emit(s,h,{2,seq,p.nonce,0,lv},"Đã dừng rèn; lượt đang dở tính là thất bại.") end
    end
end
return M
