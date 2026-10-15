-- Scoped CY wardrobe controller. WARD_CATALOG is generated from the actual DBCs.
local category, page, selected, ownedOnly, search = 1, 1, nil, false, ''
local visible, rows, sex, revision = false, {}, 1, -1
local pageSize = 16
local snapshotDue=false
local position={128,128,128}
local positionEdited=false
local selectedFamily=nil
local removing=nil
local previewMount=-1
local function hasVariants() return category==1 or category==7 or category==8 end
local function isOrnament() return category==5 or category==6 end
local function requestSnapshot()
 if snapshotDue and Lua_CysWardrobeRequest(0,category,0)==1 then snapshotDue=false end
end
local labels = {'Trang phục','Mặt','Tóc','Avatar','Đầu sức','Bối sức','Huyễn sức','Thú hồn','Thú cưỡi'}
local messages = {[0]='', [1]='Bạn đã sở hữu vật phẩm này.', [2]='Ngoại hình chưa có đủ dữ liệu cho nhân vật.',
 [3]='Hãy sở hữu ngoại hình trước khi sử dụng.', [4]='Thú hồn được kích hoạt qua sự kiện riêng.',
 [5]='Kho thời trang đã đầy. Hãy chuyển bớt vật phẩm ra túi rồi thử lại.', [6]='Chưa thể áp dụng. Ngoại hình đang dùng được giữ nguyên.',
 [7]='Thao tác quá nhanh. Hãy bấm lại sau một lát.', [8]='Chưa nhận được phản hồi. Bấm Đồng bộ để thử lại.',
 [9]='Chưa nhận được xác nhận sở hữu từ máy chủ.', [10]='Vị trí vượt giới hạn của vật phẩm.',
 [11]='Ngoại hình đang dùng đã thay đổi. Hãy kiểm tra rồi tháo lại.'}
local function control(name) return getfenv(1)['CysWard_'..name] end
local function enable(widget,value) if value then widget:Enable() else widget:Disable() end end
local function owned(row) return Lua_CysWardrobeOwned(category,row.id)==1 end
local function rowName(row) return row.name[sex+1] end
local function variantId(row)
 local _,_,_,current=Lua_CysWardrobeState(category)
 for _,id in ipairs(row.aliases or {row.id}) do if id==current then return id end end
 for _,id in ipairs(row.aliases or {row.id}) do if Lua_CysWardrobeOwned(category,id)==1 then return id end end
 return row.id
end
local function familyOwned(row)
 for _,v in ipairs(row.variants) do if Lua_CysWardrobeOwned(category,variantId(v))==1 then return true end end
 return false
end
local function matches(row)
 if string.sub(search,1,1)=='=' then
  for _,v in ipairs(row.variants) do
   for _,id in ipairs(v.aliases or {v.id}) do if tostring(id)==string.sub(search,2) then return true end end
  end
  return false
 end
 if search=='' or string.find(string.lower(rowName(row)),search,1,true) then return true end
 for _,v in ipairs(row.variants) do
  if string.find(string.lower(rowName(v)),search,1,true) then return true end
  for _,id in ipairs(v.aliases or {v.id}) do if string.find(tostring(id),search,1,true) then return true end end
 end
 return false
end
local function cellName(text)
 local pattern='[%z\1-\127\194-\244][\128-\191]*'
 local function cost(c)
  if string.byte(c)>=228 then return 2 end
  if c=='W' or c=='M' or c=='m' or c=='w' then return 1.5 end
  return 1
 end
 local lines={''}; local line,width=1,0
 for word in string.gfind(text,'%S+') do
  local size=0; for c in string.gfind(word,pattern) do size=size+cost(c) end
  if width>0 then
   if width+1+size>11 then line=line+1; lines[line]=''; width=0
   else lines[line]=lines[line]..' '; width=width+1 end
  end
  for c in string.gfind(word,pattern) do
   if width+cost(c)>11 then line=line+1; lines[line]=''; width=0 end
   lines[line]=lines[line]..c; width=width+cost(c)
  end
 end
 if table.getn(lines)>2 then
  local short,n='',0
  for c in string.gfind(lines[2],pattern) do
   if n+cost(c)>9 then break end
   short=short..c; n=n+cost(c)
  end
  lines[2]=short..'…'
 end
 return lines[1]..(lines[2] and '#r'..lines[2] or '')
end
function NewExterior_DressBox_PreLoad()
 this:RegisterEvent('OPEN_EXTERIOR_FASHION')
 this:RegisterEvent('CYS_WARDROBE_CHANGED')
 this:RegisterEvent('ON_SCENE_TRANS')
 this:RegisterEvent('ON_SERVER_TRANS')
 this:RegisterEvent('HIDE_ON_SCENE_TRANSED')
end
function NewExterior_DressBox_OnLoad() control('Search'):SetToolTip('Tìm theo tên, hoặc =mã để chọn đúng một vật phẩm') end
function NewExterior_DressBox_OnEvent(event)
 if event=='OPEN_EXTERIOR_FASHION' then
  if tonumber(arg0)==1 then CysWard_Open() elseif tonumber(arg0)==0 then NewExterior_DressBox_CloseClick() end
 elseif event=='CYS_WARDROBE_CHANGED' then
  if visible then requestSnapshot(); CysWard_Refresh(true) end
 elseif event=='ON_SCENE_TRANS' or event=='ON_SERVER_TRANS' or event=='HIDE_ON_SCENE_TRANSED' then
  NewExterior_DressBox_CloseClick()
 end
end
function CysWard_Open()
 sex=Lua_CysWardrobeAppearance()
 visible=true; removing=nil; selected=nil; selectedFamily=nil; page=1; revision=-1
 control('Portrait'):Hide()
 Exterior:LuaFnSetCurrentExteriorSetInfo('RESET')
 Lua_CysWardrobePreview(0,-1)
 PushEvent('OPEN_EQUIP','0')
 this:Show()
 CysWard_Attach()
 if category~=9 then Exterior:LuaFnUpdateExteriorPlayerData() end
 CysWard_Camera()
 CysWard_Refresh(false)
 snapshotDue=true; requestSnapshot()
 SetTimer('NewExterior_DressBox','CysWard_Timeout()',11000)
end
function CysWard_Category(cat)
 if cat<1 or cat>9 then return end
 category=cat; removing=nil; selected=nil; selectedFamily=nil; page=1; revision=-1
 control('Portrait'):Hide()
 CysWard_Attach()
 Lua_CysWardrobePreview(0,-1)
 if category~=9 then Exterior:LuaFnUpdateExteriorPlayerData() end
 CysWard_Camera(); CysWard_Refresh(false)
 snapshotDue=true; requestSnapshot()
 SetTimer('NewExterior_DressBox','CysWard_Timeout()',11000)
end
function CysWard_Refresh(response)
 local ready,busy,result,current,rev,count=Lua_CysWardrobeState(category)
 if response and removing==category and busy==0 then
  removing=nil
  if result==0 then
   selected=nil;selectedFamily=nil;Lua_CysWardrobePreview(0,-1)
   Exterior:LuaFnSetCurrentExteriorSetInfo('RESET');Exterior:LuaFnUpdateExteriorPlayerData();CysWard_Camera()
  end
 end
 revision=rev
 if response and isOrnament() and selected and not positionEdited then
  position={Lua_CysWardrobePosition(category,selected.id)}
  Lua_CysWardrobeAdjustPreview(category,selected.id,CysWard_PackedPosition())
 end
 rows={}
 for _,r in ipairs(WARD_CATALOG[category]) do
  if matches(r) and (not ownedOnly or familyOwned(r)) then table.insert(rows,r) end
 end
 local pages=math.max(1,math.ceil(table.getn(rows)/pageSize))
 page=math.min(math.max(1,page),pages)
 for i=1,9 do
  control('Tab'..i):SetText((i==category and '#cFFD68A' or '#cDBD3C4')..labels[i])
 end
 control('Count'):SetText(labels[category]..'  |  '..table.getn(rows)..' mục  |  '..(ready==1 and tostring(count)..' đã sở hữu' or 'Đang đồng bộ'))
 control('Page'):SetText('Trang '..page..' / '..pages)
 control('Filter'):SetText(ownedOnly and 'Đã sở hữu' or 'Tất cả')
 enable(control('Prev'),page>1); enable(control('Next'),page<pages)
 for i=1,pageSize do
  local r=rows[(page-1)*pageSize+i]
  local b=control('Item'..i)
  if r then
   b:Show()
   local icon=r.icon[sex+1]
   local image=string.sub(icon,1,4)=='set:' and icon or GetIconFullName(icon)
   control('Icon'..i):SetProperty('Image',image)
   control('Name'..i):SetText(cellName(rowName(r)))
   local state=familyOwned(r) and '#c8CE0B6Đã sở hữu' or '#cADA99FChưa sở hữu'
   if category==8 then state=familyOwned(r) and '#c8CE0B6Đã kích hoạt' or '#cD6BE8ASự kiện riêng' end
   control('State'..i):SetText(state)
   control('Select'..i):SetProperty('Visible',selected and selectedFamily==r and 'True' or 'False')
   b:SetToolTip(rowName(r)..'#rMã: '..r.id..'#r'..(category==8 and 'Kích hoạt theo sự kiện thú hồn' or 'Chọn để xem trước'))
  else b:Hide() end
 end
 control('Empty'):SetProperty('Visible',table.getn(rows)==0 and 'True' or 'False')
 local valid=selected and selected.valid[sex+1]
 enable(control('Own'),ready==1 and busy==0 and valid and not owned(selected) and category~=8)
 enable(control('Wear'),ready==1 and busy==0 and valid and owned(selected) and (current~=selected.id or category==1) and category~=8)
 control('Own'):SetText(selected and owned(selected) and 'Đã sở hữu' or 'Sở hữu')
 control('Wear'):SetText(category==1 and 'Mặc' or (category==9 and 'Chọn dùng' or 'Dùng'))
 local removable=category==1 or category==5 or category==6 or category==7
 control('Remove'):SetProperty('Visible',removable and 'True' or 'False')
 enable(control('Remove'),removable and ready==1 and busy==0 and current>0)
 control('Remove'):SetToolTip('Tháo ngoại trang đang dùng khỏi nhân vật; giữ quyền sở hữu.')
 local actions=selected and selected.actions or {}
 for i=1,3 do
  control('Action'..i):SetProperty('Visible',actions[i] and 'True' or 'False')
  if actions[i] then control('Action'..i):SetToolTip(actions[i].name) end
 end
 control('Reset'):SetProperty('UnifiedYPosition',table.getn(actions)>0 and '{0,632}' or '{0,611}')
 control('Ride'):SetProperty('Visible',category==9 and 'True' or 'False')
 enable(control('Ride'),category==9 and ready==1 and busy==0 and current>0)
 control('Selected'):SetText(selected and (rowName(selected)..'#rMã: '..selected.id) or 'Chọn một ngoại hình để xem trước')
 if selected and not valid then control('Status'):SetText(messages[2])
 elseif category==8 then control('Status'):SetText(messages[4])
 elseif busy==1 then control('Status'):SetText('Đang chờ máy chủ xác nhận...')
 elseif result~=0 then control('Status'):SetText(messages[result] or 'Chưa thể hoàn tất thao tác.')
 elseif category==9 then control('Status'):SetText('Chọn dùng, rồi bấm Lên / xuống thú để triệu hồi.#rSở hữu miễn phí · Lưu theo nhân vật')
 elseif response then control('Status'):SetText('Đã đồng bộ với nhân vật.')
 else control('Status'):SetText('Sở hữu miễn phí · Lưu theo nhân vật') end
 CysWard_PositionRefresh(ready,busy)
 CysWard_VariantRefresh()
end
function CysWard_Select(index)
 selectedFamily=rows[(page-1)*pageSize+index]
 if not selectedFamily then return end
 local choice=selectedFamily.variants[1]
 local _,_,_,current=Lua_CysWardrobeState(category)
 local _,wornVisual=Lua_CysWardrobeAppearance()
 for _,v in ipairs(selectedFamily.variants) do
  if variantId(v)==current and (category~=1 or v.visual[sex+1]==wornVisual) then choice=v; break end
 end
 if search~='' then
  local query=string.sub(search,1,1)=='=' and string.sub(search,2) or search
  local found=false
  for _,v in ipairs(selectedFamily.variants) do
   for _,id in ipairs(v.aliases or {v.id}) do if tostring(id)==query then choice=v;found=true;break end end
   if found then break end
  end
 end
 CysWard_ChooseVariant(choice)
end
-- Used by the native resource census. It follows the same selection/preview
-- path as the buttons; ownership/wear still requires the ordinary ACK RPC.
function CysWard_HJPreview(cat,id,visual)
 if category~=cat then CysWard_Category(cat) end
 for _,family in ipairs(WARD_CATALOG[cat] or {}) do
  if family.source=='HJ' then
   for _,v in ipairs(family.variants) do
    if v.id==id and v.visual[sex+1]==visual and v.valid[sex+1] then
     selectedFamily=family
     CysWard_ChooseVariant(v)
     return true
    end
   end
  end
 end
 return false
end
function CysWard_ChooseVariant(choice)
 if not choice then return end
 selected={}; for k,v in pairs(choice) do selected[k]=v end
 selected.id=variantId(choice)
 if isOrnament() then
  position={Lua_CysWardrobePosition(category,selected.id)}
  positionEdited=false
 end
 if selected.valid[sex+1] then
  Lua_CysWardrobePreview(category,isOrnament() and selected.id or selected.visual[sex+1],isOrnament() and CysWard_PackedPosition() or (category==8 and selected.fusion or -1))
  if category==9 then
   -- Changing ModelID replaces the creature entity. Release the RTT reference
   -- before replacement, then bind the newly created entity.
   if previewMount~=selected.visual[sex+1] then
    NewExterior_DressBox_FakeObject:RotateEndEx()
    NewExterior_DressBox_FakeObject:DetachWindowEx()
    Exterior:LuaFnUpdateExteriorAvatarMount(selected.visual[sex+1])
    NewExterior_DressBox_FakeObject:AttachWindowEx('Exterior_Ride')
    previewMount=selected.visual[sex+1]
   end
  else Exterior:LuaFnUpdateExteriorPlayerData() end
  CysWard_Camera()
 end
 control('Portrait'):SetProperty('Visible',category==4 and 'True' or 'False')
 if category==4 then control('Portrait'):SetProperty('Image',GetIconFullName(selected.icon[sex+1])) end
 CysWard_Refresh(false)
end
function CysWard_Variant(kind,delta)
 if not selected or not selectedFamily then return end
 local field=kind=='Level' and 'level' or 'color'
 local other=kind=='Level' and 'color' or 'level'
 local values={}
 for _,v in ipairs(selectedFamily.variants) do
  if (v[other] or 1)==(selected[other] or 1) then table.insert(values,v) end
 end
 for i,v in ipairs(values) do
  if (v[field] or 1)==(selected[field] or 1) then
   local next=values[i+delta]
   if next then CysWard_ChooseVariant(next) end
   return
  end
 end
end
function CysWard_VariantRefresh()
 control('Variants'):SetProperty('Visible',hasVariants() and 'True' or 'False')
 if not hasVariants() then return end
 for _,kind in ipairs({'Level','Color'}) do
  local field=kind=='Level' and 'level' or 'color'
  local other=kind=='Level' and 'color' or 'level'
  local prev,next=false,false
  if selected and selectedFamily then
   for _,v in ipairs(selectedFamily.variants) do
    if (v[other] or 1)==(selected[other] or 1) then
     prev=prev or (v[field] or 1)<(selected[field] or 1)
     next=next or (v[field] or 1)>(selected[field] or 1)
    end
   end
  end
  enable(control(kind..'Prev'),prev); enable(control(kind..'Next'),next)
  local value='—'
  if selected then
   if kind=='Color' then
    value=selected.colorName or 'Mặc định'
    value=string.gsub(value,'#c%x%x%x%x%x%x','');value=string.gsub(value,'#[A-Z]','')
    value='#cDBD3C4'..value
   else value=selected.level and ('Cấp '..selected.level) or 'Không phân cấp' end
   if category==8 and kind=='Level' then value=value..' · Dung hợp '..selected.fusion end
  end
  control(kind..'Value'):SetText(value)
 end
end
function CysWard_Operation(op)
 if not selected or category==8 then return end
 Lua_CysWardrobeRequest(op,category,selected.id,category==1 and selected.visual[sex+1] or position[1],position[2],position[3])
 CysWard_Refresh(false)
 SetTimer('NewExterior_DressBox','CysWard_Timeout()',11000)
end
function CysWard_DoRemove()
 local ready,busy,_,current=Lua_CysWardrobeState(category)
 if ready~=1 or busy~=0 or current<=0 then return end
 removing=Lua_CysWardrobeRequest(4,category,current)==1 and category or nil
 CysWard_Refresh(false)
 SetTimer('NewExterior_DressBox','CysWard_Timeout()',11000)
end
function CysWard_PlayAction(index)
 if not selected then return end
 if Lua_CysWardrobeAction(category,selected.id,index)~=1 then control('Status'):SetText('Động tác chưa có dữ liệu phù hợp.') end
end
function CysWard_DoSync()
 snapshotDue=true; requestSnapshot(); CysWard_Refresh(false)
 SetTimer('NewExterior_DressBox','CysWard_Timeout()',11000)
end
function CysWard_DoRide()
 if category~=9 then return end
 local ready,busy,result,current=Lua_CysWardrobeState(9)
 if ready~=1 or busy~=0 or current<=0 then return end
 if Player:UseSkillInLua_Const()==1 then
  control('Ride'):Disable()
  control('Status'):SetText('Đang lên / xuống thú...')
  SetTimer('NewExterior_DressBox','CysWard_RideDone()',6500)
 end
end
function CysWard_RideDone() if visible then CysWard_Refresh(false) end end
function CysWard_Timeout() if visible then CysWard_Refresh(false); requestSnapshot() end end
function CysWard_DoPage(delta) page=page+delta; selected=nil; CysWard_Refresh(false) end
function CysWard_DoFilter() ownedOnly=not ownedOnly; page=1; selected=nil; CysWard_Refresh(false) end
function CysWard_DoSearch()
 search=string.lower(control('Search'):GetText()); page=1; selected=nil; CysWard_Refresh(false)
end
function CysWard_Camera()
 local ornament=isOrnament() or hasVariants()
 NewExterior_DressBox_FakeObject:SetProperty('UnifiedSize',ornament and '{{0,355},{0,350}}' or '{{0,355},{0,505}}')
 control('Left'):SetProperty('UnifiedYPosition',ornament and '{0,411}' or '{0,565}')
 control('Right'):SetProperty('UnifiedYPosition',ornament and '{0,411}' or '{0,565}')
 NewExterior_DressBox_FakeObject:SetProperty('Visible',(category~=9 or selected) and 'True' or 'False')
 if category==9 and selected then
  if selected.camera then
   -- Authored HJ ExteriorRideCamera, mount-only columns used by GL's Lua.
   NewExterior_DressBox_FakeObject:SetCameraEx(selected.camera[1],selected.camera[2],0.15,0)
   return
  end
  -- Mount sizes vary widely. The actor's CY Camera_Main property resolves
  -- through Model_Parameter (e.g. tiger 0.4/8.1, golden dragon 5.0/14.0).
  NewExterior_DressBox_FakeObject:RestPositonEx()
 elseif category==2 or category==3 or category==5 then NewExterior_DressBox_FakeObject:SetCameraEx(sex==0 and 1.55 or 1.65,1.8,0.10,0)
 elseif category==7 or category==8 then NewExterior_DressBox_FakeObject:SetCameraEx(0.95,4.1,0.15,0)
 else NewExterior_DressBox_FakeObject:SetCameraEx(0.95,3.3,0.15,0) end
end
function CysWard_Attach()
 previewMount=-1
 NewExterior_DressBox_FakeObject:RotateEndEx()
 NewExterior_DressBox_FakeObject:DetachWindowEx()
 NewExterior_DressBox_FakeObject:AttachWindowEx(category==9 and 'Exterior_Ride' or 'Exterior_Player')
end
function CysWard_Rotate(dir)
 if dir==0 then NewExterior_DressBox_FakeObject:RotateEndEx()
 else NewExterior_DressBox_FakeObject:RotateBeginEx(category==9 and 'Exterior_Ride' or 'Exterior_Player',dir*0.3) end
end
function CysWard_DoReset()
 control('Portrait'):Hide()
 selected=nil; Lua_CysWardrobePreview(0,-1); Exterior:LuaFnSetCurrentExteriorSetInfo('RESET')
 Exterior:LuaFnUpdateExteriorPlayerData(); CysWard_Camera(); CysWard_Refresh(false)
end
function CysWard_PackedPosition()
 return position[1]+position[2]*256+position[3]*65536
end
function CysWard_PositionRefresh(ready,busy)
 control('Position'):SetProperty('Visible',isOrnament() and 'True' or 'False')
 if not isOrnament() then return end
 local valid=selected and selected.valid[sex+1]
 local changed=false
 if valid then
  local x,y,z=Lua_CysWardrobePosition(category,selected.id)
  changed=x~=position[1] or y~=position[2] or z~=position[3]
  if not changed then positionEdited=false end
 end
 for i,axis in ipairs({'X','Y','Z'}) do
  control('Pos'..axis):SetText(valid and tostring(position[i]) or '—')
  enable(control('Pos'..axis..'Minus'),valid and position[i]>selected.bounds[i*2-1])
  enable(control('Pos'..axis..'Plus'),valid and position[i]<selected.bounds[i*2])
 end
 enable(control('PosDefault'),valid)
 enable(control('PosSave'),valid and ready==1 and busy==0 and owned(selected) and changed)
 control('PosSave'):SetText(valid and owned(selected) and not changed and 'Đã lưu vị trí' or 'Lưu vị trí')
end
function CysWard_PositionPreview()
 Lua_CysWardrobeAdjustPreview(category,selected.id,CysWard_PackedPosition())
 CysWard_Refresh(false)
end
function CysWard_Adjust(axis,delta)
 if not isOrnament() or not selected or not selected.valid[sex+1] or axis<1 or axis>3 then return end
 position[axis]=math.min(selected.bounds[axis*2],math.max(selected.bounds[axis*2-1],position[axis]+delta))
 positionEdited=true
 CysWard_PositionPreview()
end
function CysWard_DefaultPosition()
 if not isOrnament() or not selected then return end
 local p=selected.pos[sex+1]; position={p[1],p[2],p[3]}
 positionEdited=true
 CysWard_PositionPreview()
end
function CysWard_SavePosition()
 if not isOrnament() or not selected or not owned(selected) then return end
 CysWard_Operation(3)
end
function NewExterior_DressBox_CloseClick() this:Hide() end
function NewExterior_DressBox_OnHidden()
 visible=false; removing=nil; selected=nil
 NewExterior_DressBox_FakeObject:RotateEndEx()
 NewExterior_DressBox_FakeObject:DetachWindowEx()
 Lua_CysWardrobePreview(0,-1)
 Exterior:LuaFnSetCurrentExteriorSetInfo('RESET')
end
