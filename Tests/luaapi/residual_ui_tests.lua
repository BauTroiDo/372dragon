-- Actual UI Lua; only optional server metadata and tooltip controls are fixtures.
local root=assert(arg[1]);local flat=arg[2]=='flat'
math.mod=math.fmod
local pass,fail=0,0
local function test(name,fn)local ok,e=pcall(fn);if ok then pass=pass+1 else fail=fail+1 end;print(ok and 'PASS' or 'FAIL',name,e or '')end
for _,name in ipairs({'Xiulian','XiulianStudy'})do
    local widget={SetToolTip=function(self,t)self.tip=t end}
    local data={}
    local env=setmetatable({DataPool=data,Player={GetData=function()return 0 end}},{__index=_G})
    for _,w in ipairs({'Xiulian_Vigor','Xiulian_Gongli_Text','Xiulian_Gongli_Tooltip','XiulianStudy_CurrentlyGongli_Tooltip'})do env[w]=widget end
    local file=root..'/'..(flat and '' or name..'/')..name..'.lua'
    assert(loadfile(file,'t',env))()
    for _,kind in ipairs({'Happy','Merge'})do
      local suffix=kind=='Happy' and 'Powfix' or 'Power'
      data['Lua_Get'..suffix..'Value']=function()return 30 end
      data['Lua_IsSet'..suffix]=function()return 1 end
      data['Lua_On'..suffix..'Time']=function()return 1 end
      local call=env[name..'_Set'..kind..'Month']
      for _,case in ipairs({'missing','one value','negative','inactive','valid'})do
        test(name..' '..kind..' '..case,function()
          local first,last=20260901,20260930
          if case=='missing'then first,last=nil,nil elseif case=='one value'then last=nil elseif case=='negative'then first=-1 end
          data['Lua_Get'..suffix..'Time']=function()return first,last end
          data['Lua_IsSet'..suffix]=function()return case=='inactive' and 0 or 1 end
          widget.tip='stale';call()
          assert(case=='valid' and widget.tip~='' or case~='valid' and widget.tip=='','wrong bonus tooltip')
        end)
      end
    end
end
print(string.format('SUMMARY pass=%d fail=%d',pass,fail));os.exit(fail==0 and 0 or 1)
