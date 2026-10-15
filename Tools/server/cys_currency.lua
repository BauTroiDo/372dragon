-- Two wallets. Vo Thach is stored in lower-grade units; 100:1:100 denominations
-- are presentation only. Legacy Jiaozi fields remain zero so old sums cannot double.
local M={MAX=2147483647}
function M.integer(v) return type(v)=='number' and v==v and v>=0 and v<=M.MAX and v==math.floor(v) end
function M.normalize(a)
 local money=(a.money or 0)+(a.jiaozi or 0)
 local yb=(a.yuanbao or 0)+(a.bind_yuanbao or 0)+(a.zengdian or 0)
 assert(M.integer(money) and M.integer(yb),'currency migration range')
 a.money,a.jiaozi,a.yuanbao,a.bind_yuanbao,a.zengdian=money,0,yb,0,0
 return a
end
function M.parts(n)
 assert(M.integer(n));return n//10000,(n//100)%100,n%100
end
function M.update(a,changes)
 local r={};for k,v in pairs(changes) do r[k]=v end
 if r.jiaozi~=nil then r.money=(r.money or a.money or 0)+r.jiaozi;r.jiaozi=0 end
 if r.bind_yuanbao~=nil or r.zengdian~=nil then
  r.yuanbao=(r.yuanbao or a.yuanbao or 0)+(r.bind_yuanbao or 0)+(r.zengdian or 0)
  r.bind_yuanbao,r.zengdian=0,0
 end
 assert((r.money==nil or M.integer(r.money)) and (r.yuanbao==nil or M.integer(r.yuanbao)),'currency update range')
 return r
end
function M.install(H)
 local oldSetMoney,oldSetYb=H.set_money,H.set_yuanbao
 function H:set_money(n,reason,extra)
  if not M.integer(n) then return false end
  return oldSetMoney(self,n,reason,extra)
 end
 function H:set_yuanbao(n,reason,extra,top)
  if not M.integer(n) then return false end
  return oldSetYb(self,n,reason,extra,top)
 end
 function H:get_jiaozi() return 0 end
 function H:get_bind_yuanbao() return 0 end
 function H:add_money(n,reason,extra)
  if not M.integer(n) or not M.integer(self:get_money()+n) then return false end
  return self:set_money(self:get_money()+n,reason,extra)
 end
 function H:add_yuanbao(n,reason,extra)
  if not M.integer(n) or not M.integer(self:get_yuanbao()+n) then return false end
  return self:set_yuanbao(self:get_yuanbao()+n,reason,extra)
 end
 function H:cost_money(n,reason,extra)
  if not M.integer(n) or n>self:get_money() then return false end
  return self:set_money(self:get_money()-n,reason,extra)
 end
 function H:cost_yuanbao(n,reason,extra,top)
  if not M.integer(n) or n>self:get_yuanbao() then return false end
  return self:set_yuanbao(self:get_yuanbao()-n,reason,extra,top)
 end
 function H:check_money_with_priority(n) return M.integer(n) and self:get_money()>=n end
 function H:cost_money_with_priority(n,reason,extra)
  if not self:cost_money(n,reason,extra) then return false,0,0 end
  return true,0,n
 end
 H.add_jiaozi=H.add_money
 H.set_jiaozi=H.set_money
 H.add_bind_yuanbao=H.add_yuanbao
 H.set_bind_yuanbao=H.set_yuanbao
 H.cost_bind_yuanbao=H.cost_yuanbao
 local checkShop,costShop=H.check_cost_money_by_shop_type,H.cost_money_by_shop_type
 function H:check_cost_money_by_shop_type(kind,n)
  if kind==9 then kind=5 elseif kind==8 then kind=1 end
  return M.integer(n) and checkShop(self,kind,n)
 end
 function H:cost_money_by_shop_type(kind,n,extra)
  if kind==9 then kind=5 elseif kind==8 then kind=1 end
  if not self:check_cost_money_by_shop_type(kind,n) then return false end
  costShop(self,kind,n,extra);return true
 end
end
return M
