-- Exercise the actual private-server charlist serializer without login/DB.
local f=assert(io.open(assert(arg[1]),'rb'));local source=f:read('*a');f:close()
local block=assert(source:match('packet%.LCRetCharList = {(.-)\n}\n'))
local body=assert(block:match('bos = function%(self%)(.-)\n    end%s*$'))
local stream={}
for method,format in pairs({writeint='<i4',writeuint='<I4',writeuchar='<I1',writeshort='<i2'})do
 stream[method]=function(self,v)table.insert(self.parts,string.pack(format,v))end
end
function stream:write(v,n)table.insert(self.parts,v:sub(1,n)..string.rep('\0',math.max(0,n-#v)))end
function stream:get()return table.concat(self.parts)end
local env={bostream={new=function()return setmetatable({parts={}},{__index=stream})end},
 gbk={fromutf8=function(s)return s end},define={HUMAN_EQUIP={HEQUIP_TOTAL=19}}}
local serialize=assert(load('return function(self)'..body..'\nend','charlist-bos','t',env))()
for _,hair in ipairs({0,1,5,254,255,256,299,20299})do
 local char={guid=200016,sex=1,nickname='HairTest',level=100,hair_color=0,hair=hair,head=20202}
 local bytes=serialize({unknow=0,uuid='test',charlist={char}})
 -- Packet prefix 4+50+1; native char record full hair offset 0x34.
 local compact=string.unpack('<I1',bytes,55+0x31+1)
 local full=string.unpack('<i4',bytes,55+0x34+1)
 assert(full==hair and char.hair==hair,'native hair was truncated/mutated')
 assert(compact==(hair<=255 and hair or 0),'compact ID overflow')
 assert(#bytes==395,'wire layout changed')
end
print('PASS actual charlist serializer: 8 boundary/native IDs, full hair, no mutation, unchanged wire length')
