-- CY XiuLianDetail and XiulianStudy.lua. All indices here are one-based.
local guard=require 'cys_inventory_guard'
local M={}
function M.realm(upper) return upper<=60 and upper//10 or 6+(upper-60)//15 end
function M.power(level) return level<30 and 33 or level<60 and 50 or level<105 and 100 or 200 end
function M.realm_cost(upper) return (M.realm(upper)+1)*10000 end
function M.init(list)
    list=list or {}
    for i=1,15 do
        list[i]=list[i] or {level=0,upper_limit=10}
        assert(guard.integer(list[i].level,0,150) and guard.integer(list[i].upper_limit,10,150),'invalid saved cultivation')
        local upper=math.max(list[i].upper_limit,list[i].level)
        -- Old GL saves used ten-level realms even above60. Preserve earned levels,
        -- round only the unlocked ceiling upward to the matching CY realm.
        list[i].upper_limit=upper<=60 and math.ceil(upper/10)*10 or math.min(150,60+math.ceil((upper-60)/15)*15)
    end
    return list
end
local function reject(s,id,msg) s:notify_tips(id,msg);return false end
function M.operate(s,id,index,advance)
    if not guard.integer(index,0,14) then return reject(s,id,'Mục tu luyện không hợp lệ.') end
    -- The running GL server implements eleven cultivation bonuses. The remaining
    -- CY rows belong to school advancement; never charge for an inactive bonus.
    if index>=11 then return reject(s,id,'Kinh mạch tiến giai chưa được kích hoạt; không trừ chi phí.') end
    local h=s:get_scene():get_obj_by_id(id)
    if not h or h:is_die() or h._leaving then return false end
    if h:get_level()<(index>=11 and 90 or 70) then return reject(s,id,'Chưa đủ cấp để tu luyện quyển này.') end
    local list=h:get_xiulian_list();local row=list[index+1];local level=row.level;local upper=row.upper_limit
    if index>=5 and index<=10 then
        local best=0;for i=1,5 do best=math.max(best,M.realm(list[i].upper_limit)) end
        if best<3 then return reject(s,id,'Cần cảnh giới quyển cơ bản đạt tầng 3.') end
    end
    if index==12 and list[12].level<10 then return reject(s,id,'Thủ Thiếu Dương phải đạt cấp 10.') end
    if index>=13 and (list[12].level<20 or list[13].level<20) then return reject(s,id,'Thủ Thiếu Dương và Túc Thái Âm phải đạt cấp 20.') end
    if level>=150 then return reject(s,id,'Đã đạt giới hạn tu luyện 150.') end
    if advance then
        if level~=upper then return reject(s,id,'Cần tu luyện đầy cấp của cảnh giới hiện tại.') end
        if index<11 then
            local first,last=index<5 and 1 or 6,index<5 and 5 or 11;local companions=0
            for i=first,last do if i~=index+1 and M.realm(list[i].upper_limit)>=M.realm(upper) then companions=companions+1 end end
            if companions<2 then return reject(s,id,'Cần thêm hai quyển cùng bộ đạt cảnh giới hiện tại.') end
        end
        local cost=M.realm_cost(upper)
        if not h:check_money_with_priority(cost) then return reject(s,id,'Không đủ vàng/giao tử; cần '..cost..'.') end
        h:cost_money_with_priority(cost,'Cultivation realm')
        row.upper_limit=math.min(150,upper+(upper<60 and 10 or 15));h:send_xiulian_list()
    else
        if level>=upper then return reject(s,id,'Hãy nâng cảnh giới trước.') end
        local next=s:GetXiuLianDetail(id,index+1,level+1)
        if not next or not guard.integer(next.cost_exp,1,2147483647) or not guard.integer(next.cost_gold,0,2147483647) then return reject(s,id,'Chưa có dữ liệu tu luyện hợp lệ cho môn phái này.') end
        local power=M.power(level)
        if h:get_exp()<next.cost_exp then return reject(s,id,'Không đủ kinh nghiệm.') end
        if h:get_gong_li()<power then return reject(s,id,'Không đủ công lực; cần '..power..'.') end
        if not h:check_money_with_priority(next.cost_gold) then return reject(s,id,'Không đủ vàng/giao tử.') end
        if next.cost_gold>0 then h:cost_money_with_priority(next.cost_gold,'Cultivation level') end
        h:set_exp(h:get_exp()-next.cost_exp);h:cost_gong_li(power);h:xiulian_level_up(index+1)
    end
    return true
end
return M
