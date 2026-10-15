-- Run the actual attribute conversion function against CY values, varying one stat.
local root,cyfile,tablefile=...;tablefile=tablefile or root..'/configs/BaseValueTable.ini'
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('a');f:close();return s:gsub('\r\n','\n')end
local function ini(p)
 local result,section={}
 for line in read(p):gmatch('[^\n]+')do
  local id=line:match('^%[MENPAI(%d+)%]');if id then section='MENPAI'..id;result[section]={}end
  local key,value=line:match('^(AINFOTYPE%d+)%s*=%s*(-?%d+)');if key and section then result[section][key]=tonumber(value)end
 end
 return result
end
local actual,expected=ini(tablefile),ini(cyfile)
local influence=assert(read(root..'/GameServer/lualib/menpai.lua'):match('menpai.influence = (%{.-\n%})'))
local specs={hp_max={0,1,'con',2},mp_max={6,7,'int',8},attrib_att_physics={12,13,'str',14},attrib_att_magic={15,16,'spr',17},attrib_def_physics={18,19,'con',20},attrib_def_magic={21,22,'int',23},attrib_hit={24,25,'dex',26},attrib_miss={27,28,'dex',29},mind_attack={30,31,'dex',32},mind_defend={33,34,'dex',35}}
local env=setmetatable({human_attrib={},lv1_attribs={},not_gen_attribs={},db_attribs={},menpai_attribs=specs,must_be_positive={},menpai_logic={influence=assert(load('return '..influence))()},configenginer={get_config=function()return actual end}},{__index=_G})
local body=assert(read(root..'/GameServer/lualib/db/human_attrib.lua'):match('(function human_attrib:get_base_attrib%([^\n]*\n.-\nend)'))
assert(load(body,'@human_attrib.lua','t',env))()
local total,failed=0,0
for school=0,15 do for key,spec in pairs(specs)do
 total=total+1
 local ok,err=pcall(function()
  for _,axis in ipairs({'none','str','spr','con','int','dex','level'})do
   local values={str=20,spr=20,con=20,int=20,dex=20,level=95};if axis~='none'then values[axis]=values[axis]+100 end
   local h=setmetatable({db_attribs={menpai=school},get_attrib=function(_,k)return assert(values[k])end},{__index=env.human_attrib})
   local ref=assert(expected['MENPAI'..school]);local value=math.ceil((ref['AINFOTYPE'..spec[1]]+ref['AINFOTYPE'..spec[2]]*values[spec[3]]+ref['AINFOTYPE'..spec[4]]*values.level)/100)
   local got=h:get_base_attrib(key);assert(got==value,axis..' '..got..' ~= CY '..value)
  end
 end)
 if not ok then failed=failed+1 end
 print((ok and 'PASS 'or'FAIL ')..school..' '..key..(ok and ''or': '..tostring(err)))
end end
print(('RESULT attributes=%d failed=%d'):format(total,failed));os.exit(failed==0 and 0 or 1)
