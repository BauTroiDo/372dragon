local M={}
function M.bind(packet,bistream,bostream)
 for _,v in pairs(packet)do assert(type(v)~='table' or v.xy_id~=2242,'CGFlyOperation ID collision') end
 packet.CGFlyOperation={xy_id=2242}
 local p=packet.CGFlyOperation
 function p.new()return setmetatable({object=0,operation=0},{__index=p})end
 function p:bis(buffer)
  assert(#buffer==5,'CGFlyOperation must be exactly five bytes')
  local s=bistream.new();s:attach(buffer);self.object=s:readuint();self.operation=s:readuchar()
 end
 function p:bos()local s=bostream.new();s:writeuint(self.object);s:writeuchar(self.operation);return s:get()end
end
return M
