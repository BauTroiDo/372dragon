-- CY LingPai: ownership belongs to the character; selected skill/star to the item.
local data=require 'cy_equipment_skill_data'
local T=data.tables
local M={}
local function integer(n)return type(n)=='number' and n==math.floor(n)end
function M.decode(creator)
    local code=(creator or ''):match('&LP(%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w)')
    if not code then return nil end
    local star=tonumber(code:sub(1,1));local ch=code:sub(20,20)
    local group=ch=='0' and 0 or ch:byte()-64
    if not star or star<1 or star>9 or (group~=0 and not T.RSSkill[group]) then return nil end
    return {star=star,group=group,code=code}
end
function M.is_book(id)return T.RLSkillBook[id]~=nil end
function M.learned(human,group)
    local row=T.RSSkill[group];if not row then return false end
    if group<=6 then return true end
    local mask=tonumber(human.mission_data.cy_rl_learned) or 0
    return (mask & (1 << row[3]))~=0
end
function M.sync(human)
    local msg=require('game.packet').GCUICommand.new()
    msg.m_nUIIndex=201406284
    msg.m_Param={m_IntCount=2,m_StrCount=0,m_aIntValue={371,tonumber(human.mission_data.cy_rl_learned) or 0},m_aStrValue='',m_aStrOffset={}}
    human:get_scene():send2client(human,msg)
end
function M.learn(human,pos)
    local logic=require 'human_item_logic'
    if not integer(pos) or pos<0 or pos>254 then return false end
    local item=human:get_prop_bag_container():get_item(pos)
    local row=item and T.RLSkillBook[item:get_index()]
    if not row or item:is_lock() or item:get_lay_count()<1 then return false end
    local group=row[2]
    if group==12 or group==14 then
        human:notify_tips('Kỹ năng này chưa mở trên máy chủ; sách vẫn được giữ trong túi.');return false
    end
    if M.learned(human,group) then human:notify_tips('Kỹ năng Lệnh Bài này đã lĩnh ngộ.');return false end
    local mask=tonumber(human.mission_data.cy_rl_learned) or 0
    if not logic:dec_item_lay_count({reason='cy_rl_learn'},human,pos,1,item:get_index())then return false end
    human.mission_data.cy_rl_learned=mask | (1 << T.RSSkill[group][3])
    M.sync(human);human:notify_tips('Đã lĩnh ngộ kỹ năng Lệnh Bài.');return true
end
function M.switch(human,pos,group)
    if not integer(pos) or pos<0 or pos>254 or not integer(group) or not T.RSSkill[group]then return false end
    -- These two mechanics have conflicting donor data; do not charge for a no-op.
    if group==12 or group==14 then human:notify_tips('Kỹ năng này đang chờ xác minh dữ liệu CY 3.71; chưa tiêu hao tiền.');return false end
    local item=human:get_prop_bag_container():get_item(pos)
    local base=item and T.RLBase[item:get_index()]
    if not base or base[2]<5 or item:is_lock()then return false end
    local state=M.decode(item:get_item_creator())
    if not state or state.group==group or not M.learned(human,group)then return false end
    if human:get_money()+human:get_jiaozi()<100000 then return false end
    local code='&LP'..state.code:sub(1,19)..string.char(64+group)
    local creator=item:get_item_creator():gsub('&LP%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w',code,1)
    human:cost_money_with_priority(100000)
    item:set_item_creator(creator);item:get_equip_data():set_equip_type(0)
    local msg=require('game.packet').GCItemInfo.new();msg.bagIndex=pos;msg.item=item:copy_raw_data()
    human:get_scene():send2client(human,msg);M.sync(human);return true
end
return M
