-- Equipment workshop. Costs/rules: CY EquipEducationClient (900113),
-- server809272 and DiaowenInfo/DiaowenRule. Never trust client prices or item IDs.
local cfg=require('configenginer'):getinstance()
local guard=require 'cys_inventory_guard'
local logic=require 'human_item_logic'
local packets=require 'game.packet'
local M={UI=990029}
local soul_ids={[20800031]=true,[20800032]=true}
local silk_ids={[20310166]=true,[20310167]=true,[20310168]=true}
local soul_cost={{5,6,8,10,12,14,16,19,22},{25,28,32,36,40,45,50,55,62}}
local soul_bonus={{0,1,2,4,6,8,10,13,16,19},{25,28,31,34,37,40,43,46,50,54}}
local labels={'Thăng Linh','Khắc điêu văn','Nâng điêu văn','Tháo điêu văn','Hợp điêu văn','Chuyển điêu văn'}
local function clone(v) if type(v)~='table' then return v end;local t={};for k,x in pairs(v)do t[k]=clone(x)end;return t end
local function equal(a,b)
 if type(a)~=type(b) then return false end
 if type(a)~='table' then return a==b end
 for k,v in pairs(a)do if not equal(v,b[k])then return false end end
 for k in pairs(b)do if a[k]==nil then return false end end;return true
end
local function bagitem(h,p)
 local bag=h:get_prop_bag_container()
 if not guard.accepts(bag,p) then return end
 local i=bag:get_item(p);if i and not i:is_empty() and not i:is_lock() then return i end
end
local function equipment(h,p)
 local i=bagitem(h,p)
 if i and i:is_equip() and i:get_base_config() and (i:get_equip_data():get_equip_type()==0 or i:get_equip_data():get_equip_type()==1) then return i,i:get_equip_data(),i:get_base_config() end
end
function M.shengling(creator)
 creator=creator or '';local a,b,digits=creator:find('&W(%d%d)')
 local raw=a and (b==#creator or creator:sub(b+1,b+1)=='&') and tonumber(digits) or 0
 local stage=raw>=60 and 2 or raw>19 and 1 or 0;local level=raw%10
 return raw,stage,level,stage==2 and 60 or soul_bonus[stage+1][level+1]
end
function M.bonus(equip,ia,value)
 -- ShengLing applies to the equipment's extra attributes, never gems, engraving,
 -- base/enhancement values. The exclusions match this server's Zengfu path.
 if ia==1 or ia==7 or ia==10 or ia==13 or ia==16 or ia==18 or (ia>=54 and ia<=57) then return value end
 local _,_,_,pct=M.shengling(equip:get_item_creator())
 return value+math.floor(value*pct/100)
end
local function creator_next(creator,raw)
 creator=creator or '';local mark=string.format('&W%02d',raw)
 if creator:find('&W%d%d') then return (creator:gsub('&W%d%d',mark,1)) end
 -- Zengfu's native parser requires &ZF to remain the final suffix.
 local z=creator:find('&ZF',1,true)
 return z and creator:sub(1,z-1)..mark..creator:sub(z) or creator..mark
end
local function dwconfig(product,blueprint)
 local found
 for _,d in pairs(cfg:get_config('diaowen_info')) do
  if (blueprint and d.tupu_material==product and d.level==1 or not blueprint and d.product==product) and (not found or d.id<found.id) then found=d end
 end
 return found
end
local function update(h,p,i,new)
 if new then local n=packets.GCNotifyEquip.new();n.bag_index=p;n.item=i:copy_raw_data();h:get_scene():send2client(h,n) end
 local n=packets.GCItemInfo.new();n.bagIndex=p;n.item=i:copy_raw_data();h:get_scene():send2client(h,n)
end
local function safe(h,s) return not h:is_die() and not h._leaving and not s:IsPilferLockFlag(h:get_obj_id()) end
local function needed(t,ids,n,name,selected) t.needs[#t.needs+1]={ids=ids,n=n,name=name,selected=selected} end
local function set(list)local t={};for _,id in ipairs(list or {})do if id>0 then t[id]=true end end;return t end
-- Plan against the exact selected item(s). Secondary supplies are collected from
-- unlocked bag stacks and each physical slot can only be charged once.
local function materials(h,t)
 local used,parts,bound={},{},false
 for _,need in ipairs(t.needs) do
  local remain=need.n
  local first,last=0,199
  if need.selected then first,last=need.selected,need.selected end
  for pos=first,last do
   local i=bagitem(h,pos)
   if remain>0 and i and not i:is_equip() and need.ids[i:get_index()] then
    local n=math.min(remain,i:get_lay_count()-(used[pos] or 0))
    if n>0 then used[pos]=(used[pos] or 0)+n;remain=remain-n;bound=bound or i:is_bind() end
   end
  end
  if remain>0 then return nil,'Thiếu '..need.name..' ('..need.n..').' end
 end
 for pos,n in pairs(used)do local i=bagitem(h,pos);parts[#parts+1]={pos=pos,n=n,id=i:get_index(),raw=clone(i:copy_raw_data())} end
 table.sort(parts,function(a,b)return a.pos<b.pos end)
 return parts,nil,bound
end
local function describe(t)
 local text=t.text..'\n\nChi phí: '..string.format('%g',t.money/10000)..' vàng/giao tử'
 for _,n in ipairs(t.needs)do text=text..'\n'..n.n..' '..n.name end
 return text
end
function M.plan(h,mode,pos,material,target)
 local t={mode=mode,pos=pos,material=material,target=target,money=0,needs={},rewards={},bound=false}
 if not guard.integer(mode,1,6) then return nil,'Thao tác không hợp lệ.' end
 if h:get_level()<(mode==1 and 85 or 52) then return nil,'Cần nhân vật cấp '..(mode==1 and 85 or 52)..'.' end
 local i,e,b=equipment(h,pos)
 if mode~=5 and not i then return nil,'Đặt trang bị đã tháo vào ô Trang bị.' end
 if mode~=5 and i and not i:is_identd() then return nil,'Trang bị chưa giám định.' end
 t.item=i;t.equip=e;t.base=b
 if mode==1 then
  local point=b.equip_point;local id=i:get_index()
  if point==0 or point==16 or point==17 or point==8 or point==18 or point==9 or point==10 then return nil,'Loại trang bị này không thể Thăng Linh.' end
  local special=id>=10553100 and id<=10553215 or id>=10159133 and id<=10159135 or id>=10410004 and id<=10410035
  if not special and ((b.level or 0)<80 or e:get_quality()<6) then return nil,'Cần trang bị cấp 80 trở lên, đạt ít nhất 6 sao.' end
  local raw,stage,level,pct=M.shengling(i:get_item_creator())
  if stage==2 then return nil,'Trang bị Thiên Đạo đã đạt giới hạn Thăng Linh (+60%).' end
  local advance=level==9
  t.creator=creator_next(i:get_item_creator(),advance and (stage==0 and 30 or 60) or raw+1)
  if #t.creator>32 then return nil,'Dữ liệu người chế tạo đã đầy; giữ nguyên vật phẩm.' end
  t.money=advance and 500000 or stage==0 and 100000 or 200000
  needed(t,soul_ids,advance and 60 or soul_cost[stage+1][level+1],'Tử Vi Linh Hồn')
  if advance then t.text=string.format('Tiến bậc: %s\nThuộc tính cộng thêm: +%d%% → +%d%%',stage==0 and 'Chí Tôn → Vương Quyền' or 'Vương Quyền → Thiên Đạo',pct,stage==0 and 25 or 60)
  else t.text=string.format('%s · Thăng Linh: %d → %d / 9\nThuộc tính cộng thêm: +%d%% → +%d%%',stage==0 and 'Chí Tôn' or 'Vương Quyền',level,level+1,pct,soul_bonus[stage+1][level+2]) end
 elseif mode==2 then
  if e:get_diaowen_id()~=0 then return nil,'Trang bị đã có điêu văn; tháo hoặc chuyển trước.' end
  local mat=bagitem(h,material);local d=mat and dwconfig(mat:get_index())
  if not d then return nil,'Đặt viên điêu văn vào ô Nguyên liệu.' end
  local rules=cfg:get_config('diaowen_rule')[d.rule]
  if not rules or not rules[b.equip_point] or rules[b.equip_point]==0 then return nil,'Điêu văn không phù hợp với loại trang bị này.' end
  needed(t,{[mat:get_index()]=true},1,'viên điêu văn',material);needed(t,{[30503149]=true},1,'Dung dịch khắc điêu văn')
  t.dw=d.id;t.progress=0;t.text='Khắc điêu văn cấp '..d.level..' lên trang bị.'
 elseif mode==3 then
  local d=cfg:get_config('diaowen_info')[e:get_diaowen_id()]
  if not d then return nil,'Trang bị chưa có điêu văn.' end
  local next=cfg:get_config('diaowen_info')[d.id+1]
  if d.level>=10 or not next or next.level~=d.level+1 or next.rule~=d.rule then return nil,'Điêu văn đã đạt giới hạn cấp.' end
  local progress=e:get_diaowen_material_count();local count=d.enhance_material_count-progress
  if not guard.integer(count,1,65535) then return nil,'Tiến độ điêu văn không hợp lệ; chưa trừ vật phẩm.' end
  needed(t,silk_ids,count,'Kim Tàm Ti');t.bound=true;t.dw=d.id+1;t.progress=0
  t.text=string.format('Điêu văn: cấp %d → %d / 10\nTiến độ đã tích lũy: %d / %d\nTrang bị sẽ khóa sau khi nâng.',d.level,next.level,progress,d.enhance_material_count)
 elseif mode==4 then
  local d=cfg:get_config('diaowen_info')[e:get_diaowen_id()]
  if not d then return nil,'Trang bị chưa có điêu văn.' end
  if (e.dw_advance_level or 0)>0 or (e.dw_rankexp or 0)>0 or (e.dw_featuresid or 0)>0 then return nil,'Điêu văn đã tinh khắc: hãy dùng chuyển điêu văn để giữ cấp và hiệu ứng.' end
  needed(t,{[30503150]=true,[30121002]=true},1,'Bột Dung Kim');t.money=50000;t.dw=0;t.progress=0
  t.rewards={{id=d.product,count=1,bound=true}}
  local progress=e:get_diaowen_material_count()
  if not guard.integer(progress,0,8191) then return nil,'Tiến độ điêu văn không hợp lệ; chưa trừ vật phẩm.' end
  if progress>0 then t.rewards[#t.rewards+1]={id=20310166,count=progress,bound=true} end
  t.text='Tháo điêu văn cấp '..d.level..'.\nNhận lại viên điêu văn đã khóa và Kim Tàm Ti đã nạp.'
 elseif mode==5 then
  t.item=nil;t.equip=nil
  local mat=bagitem(h,material);local d=mat and dwconfig(mat:get_index(),true)
  if not d then return nil,'Đặt đồ phổ điêu văn vào ô Nguyên liệu.' end
  needed(t,{[mat:get_index()]=true},1,'Đồ phổ điêu văn',material)
  needed(t,set(d.danqing_material),d.danqing_material_count,'Đan Thanh')
  needed(t,{[d.huangzhi_material]=true},d.huangzhi_material_count,'Giấy vàng')
  t.money=50000;t.rewards={{id=d.product,count=1}};t.text='Hợp thành 1 viên điêu văn cấp 1 từ đồ phổ.'
 elseif mode==6 then
  local other,oe,ob=equipment(h,target)
  if pos==target or not other or not other:is_identd() then return nil,'Đặt trang bị nhận khác vào ô Đích.' end
  if b.equip_point~=ob.equip_point or b.level<50 or ob.level<50 then return nil,'Hai trang bị phải cùng vị trí, từ cấp 50 trở lên.' end
  if e:get_diaowen_id()==0 or oe:get_diaowen_id()~=0 then return nil,'Trang bị nguồn cần có điêu văn; trang bị nhận phải chưa có.' end
  t.other=other;t.other_equip=oe;t.money=100000
  t.text='Chuyển điêu văn sang trang bị nhận.\nGiữ nguyên cấp, tiến độ, tinh khắc và hiệu ứng.\nTrang bị nhận sẽ khóa.'
 end
 return t
end
local function selected_state(h,p) local i=bagitem(h,p);return i and clone(i:copy_raw_data()) or false end
function M.quote(s,h,mode,pos,material,target,opening,message)
 mode=guard.integer(mode,1,6) and mode or 1
 pos=guard.accepts(h:get_prop_bag_container(),pos) and pos or -1
 material=guard.accepts(h:get_prop_bag_container(),material) and material or -1
 target=guard.accepts(h:get_prop_bag_container(),target) and target or -1
 local rev=(h._cys_craft_revision or 0)%2147483646+1;h._cys_craft_revision=rev
 local t,err=M.plan(h,mode,pos,material,target);local enabled=false
 local text=labels[mode]..'\n'..(t and describe(t) or err)
 if t then
  local parts,why=materials(h,t);enabled=parts~=nil and h:check_money_with_priority(t.money) and safe(h,s)
  if why then text=text..'\n\n#R'..why..'#W' elseif not h:check_money_with_priority(t.money) then text=text..'\n\n#RKhông đủ vàng/giao tử.#W' end
 end
 if message then text=message..'\n\n'..text end
 h._cys_craft_quote={rev=rev,mode=mode,pos=pos,material=material,target=target,states={selected_state(h,pos),selected_state(h,material),selected_state(h,target)}}
 s:BeginUICommand()
 for _,v in ipairs({rev,mode,pos,material,target,opening and 1 or 0,enabled and 1 or 0})do s:UICommand_AddInt(v)end
 s:UICommand_AddStr(text);s:EndUICommand();s:DispatchUICommand(h:get_obj_id(),M.UI)
end
local function still(h,s,q,parts)
 if h._cys_craft_quote~=q or not safe(h,s) then return false end
 for n,p in ipairs({q.pos,q.material,q.target})do if not equal(q.states[n],selected_state(h,p)) then return false end end
 for _,p in ipairs(parts)do local i=bagitem(h,p.pos);if not i or not equal(p.raw,i:copy_raw_data())then return false end end
 return true
end
-- Prepare reward objects before deductions: GUID allocation can yield. Reserve
-- current free slots after the yield, then validate and commit without yielding.
-- Conservative free-slot reservation intentionally does not overwrite input slots.
local function rewards(h,t,bound)
 if #t.rewards==0 then return {} end
 local op=require 'item_operator';local prepared={}
 for _,r in ipairs(t.rewards)do
  local remain=r.count
  while remain>0 do
   local i=op:gen_item({fun_name='cys_equipcraft'},r.id,1)
   if not i then return nil end
   i:set_is_bind(r.bound or bound);local n=math.min(remain,i:get_max_tile_count())
   if not guard.integer(n,1,250) then return nil end
   i:set_lay_count(n);prepared[#prepared+1]=i;remain=remain-n
  end
 end
 local bag=h:get_prop_bag_container();local reserved,result={},{}
 for _,i in ipairs(prepared)do
  local found
  for p,old in bag:ipairs(i:get_place_bag())do if not old and not reserved[p]then found=p;break end end
  if not found then return nil end
  reserved[found]=true;result[#result+1]={pos=found,item=i}
 end
 return result
end
function M.action(s,h,op,mode,pos,material,target,revision)
 if h._cys_craft_busy then return false end
 if op==0 then M.quote(s,h,mode,pos,material,target,true);return true end
 local q=h._cys_craft_quote
 local function fail(msg) M.quote(s,h,mode,pos,material,target,false,'#R'..msg..'#W');return false end
 if op~=1 or h._cys_craft_busy or not q or q.rev~=revision or q.mode~=mode or q.pos~=pos or q.material~=material or q.target~=target or not still(h,s,q,{})then return fail('Trang bị hoặc lượt thao tác đã thay đổi. Hãy kiểm tra lại.') end
 local t,err=M.plan(h,mode,pos,material,target);if not t then return fail(err)end
 local parts,why,bound=materials(h,t);if not parts then return fail(why)end
 if not h:check_money_with_priority(t.money) then return fail('Không đủ vàng/giao tử.')end
 h._cys_craft_busy=true
 local ok,output=pcall(rewards,h,t,bound)
 h._cys_craft_busy=nil
 if not ok or not output then return fail('Không đủ ô túi trống hoặc không tạo được vật phẩm; chưa trừ chi phí.')end
 if not still(h,s,q,parts) or not h:check_money_with_priority(t.money) then return fail('Hành trang đã thay đổi; chưa trừ chi phí.')end
 -- All operations below are local/no-yield. Invalidate first: replay cannot pay twice.
 h._cys_craft_quote=nil
 for _,p in ipairs(parts)do assert(logic:dec_item_lay_count({},h,p.pos,p.n,p.id),'craft validated material changed')end
 if t.money>0 then assert(h:cost_money_with_priority(t.money,'Equipment craft'))end
 if mode==1 then t.item:set_item_creator(t.creator)
 elseif mode==6 then
  local a,b=t.equip,t.other_equip
  b:set_diaowen_id(a:get_diaowen_id());b:set_diaowen_material_count(a:get_diaowen_material_count())
  for _,k in ipairs({'dw_advance_level','dw_rankexp','dw_featuresid'})do b[k]=a[k] or 0;a[k]=0 end
  a:set_diaowen_id(0);a:set_diaowen_material_count(0);t.other:set_is_bind(true);update(h,target,t.other)
 elseif mode~=5 then t.equip:set_diaowen_id(t.dw);t.equip:set_diaowen_material_count(t.progress) end
 if t.item then if bound or t.bound then t.item:set_is_bind(true)end;update(h,pos,t.item)end
 for _,r in ipairs(output)do h:get_prop_bag_container():set_item(r.pos,r.item);update(h,r.pos,r.item,true)end
 h:item_flush();M.quote(s,h,mode,pos,material,target,false,'#c5bc257Thành công. Trang bị đã được cập nhật.#W');return true
end
return M
