-- Flight landing uses the client's exact triangle mesh, not nav_adapter's
-- five-point polygon approximation. Mirrors CysNavMesh::FindTri + Geometry.h.
local M={}
local function finite(n) return n==n and n~=math.huge and n~=-math.huge end
local function f32(n) return (string.unpack('<f',string.pack('<f',n))) end
local function cross(a,b,x,z)
 return f32(f32(f32(b[1]-a[1])*f32(z-a[2]))-f32(f32(b[2]-a[2])*f32(x-a[1])))
end
function M.parse(bytes)
 local at=1
 local function read(fmt) local v;v,at=string.unpack('<'..fmt,bytes,at);return v end
 local version=read('I2');assert(version==0x1000 or version==0x2000,'invalid path version')
 local kind=version==0x1000 and 'I2' or 'I4'
 local function n(cap) local v=read(kind);assert(v<=cap,'invalid path count');return v end
 local vertices={};local nv=n(math.min(8000000,#bytes//8))
 for i=1,nv do local x,z=read('f'),read('f');assert(finite(x) and finite(z));vertices[i]={x,z} end
 assert(nv>0,'empty path vertices')
 local triangles={};local nt=n(math.min(8000000,#bytes//15))
 for i=1,nt do
  local a,b,c=read(kind)+1,read(kind)+1,read(kind)+1
  read(kind);read(kind);read(kind);local flag=read('I1');read(kind)
  -- Same repair as PathLib's length-checked reader.
  triangles[i]={vertices[a] and a or 1,vertices[b] and b or 1,vertices[c] and c or 1,flag&1}
 end
 local ne=n(#bytes//8);for i=1,ne do for j=1,4 do read(kind) end end
 local size=read('I4');if size==0 then size=8 end
 local nx,nz=n(65536),n(65536);assert(nx*nz<=#bytes//4,'invalid grid size')
 local cells={}
 for i=1,nx*nz do
  local ntri,nedge=n(#bytes//2),n(#bytes//2);local cell={}
  for j=1,ntri do local ti=read(kind)+1;if ti<=nt then cell[#cell+1]=ti end end
  for j=1,nedge do read(kind) end
  cells[i]=cell
 end
 return {vertices=vertices,triangles=triangles,cells=cells,size=size,nx=nx,nz=nz,walkable=M.walkable}
end
function M.walkable(mesh,x,z)
 if not finite(x) or not finite(z) or x<0 or z<0 then return false end
 x,z=f32(x),f32(z)
 local gx,gz=math.floor(f32(x/mesh.size)),math.floor(f32(z/mesh.size))
 if gx>=mesh.nx or gz>=mesh.nz then return false end
 for _,index in ipairs(mesh.cells[gz*mesh.nx+gx+1]) do
  local t=mesh.triangles[index];local a,b,c=mesh.vertices[t[1]],mesh.vertices[t[2]],mesh.vertices[t[3]]
  local d1,d2,d3=cross(a,b,x,z),cross(b,c,x,z),cross(c,a,x,z)
  if not ((d1<0 or d2<0 or d3<0) and (d1>0 or d2>0 or d3>0)) then return t[4]==0 end
 end
 return false
end
local directory=debug.getinfo(1,'S').source:sub(2):match('^(.*[/\\])')
local cache={}
function M.for_scene(scene)
 local info=require('cys_mount_flight_data').scenes[scene:get_id()]
 if not info or not info[3] or not info[4] then return nil end
 local offset=info[3]
 if cache[offset]~=nil then return cache[offset] or nil end
 local file=directory and io.open(directory..'cys_mount_flight_nav.bin','rb')
 if not file then return nil end
 local bytes
 if file:read(5)=='CYFN1' and file:seek('set',offset) then bytes=file:read(info[4]) end
 file:close()
 local ok,mesh=false,nil
 if bytes and #bytes==info[4] then ok,mesh=pcall(M.parse,bytes) end
 cache[offset]=ok and mesh or false
 return cache[offset] or nil
end
return M
