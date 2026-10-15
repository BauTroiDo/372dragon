-- Execute the real event purchase method with a single-wallet runtime double.
package.preload['scripts.ScriptGlobal']=function() return {MDEX_JINGE_POINT=1,MDEX_JINGE_BUY_COUNT=2} end
package.preload['scripts.new_zhanling_info']=function() return {} end
package.preload['script_base']=function() return {} end
package.preload['class']=function() return function(_,base) return setmetatable({},{__index=base}) end end
local event=assert(loadfile(assert(arg[1],'Path to patched zhenghe.lua')))()
local cases=0
local function test(ok) assert(ok);cases=cases+1 end
local function fixture(money)
 local s=setmetatable({money=money,calls=0,data={[1]=0,[2]=0}},{__index=event})
 function s:CheckReset() return {} end
 function s:GetMissionDataEx(_,key) return self.data[key] end
 function s:SetMissionDataEx(_,key,n) self.data[key]=n end
 function s:GetYuanBao() return self.money end
 -- Legacy getter aliases the same wallet. Adding these two is a regression.
 s.GetBindYuanBao=s.GetYuanBao
 function s:LuaFnCostYuanBao(_,n)
  assert(n>0 and n<=self.money,'Insufficient debit reached')
  self.calls=self.calls+1;self.money=self.money-n
 end
 s.LuaFnCostBindYuanBao=s.LuaFnCostYuanBao
 for _,name in ipairs{'notify_tips','BeginUICommand','UICommand_AddInt','UICommand_AddStr','EndUICommand','DispatchUICommand','DispatchState'} do s[name]=function() end end
 return s
end
local s=fixture(60);s:AskAddProgress(1,1,1)
test(s.money==60 and s.calls==0 and s.data[1]==0 and s.data[2]==0)
s=fixture(100);s:AskAddProgress(1,1,0)
test(s.money==100 and s.calls==0 and s.data[1]==0)
s:AskAddProgress(1,1,1)
test(s.money==0 and s.calls==1 and s.data[1]==200 and s.data[2]==1)
s:AskAddProgress(1,1,1)
test(s.money==0 and s.calls==1 and s.data[1]==200 and s.data[2]==1)
s=fixture(200);s:AskAddProgress(1,2,1)
test(s.money==0 and s.calls==1 and s.data[1]==400 and s.data[2]==2)
s=fixture(200);s:AskAddProgress(1,-1,1);s:AskAddProgress(1,1.5,1)
test(s.money==200 and s.calls==0 and s.data[1]==0)
print('PASS '..cases..' event cases: insufficient single wallet, preview, exact debit, repeat, multi-buy, invalid count')
