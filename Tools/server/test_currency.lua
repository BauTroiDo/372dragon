package.path='/mnt/c/TLBB/085/CY-Source/Tools/server/?.lua;'..package.path
local m=require'cys_currency';local cases=0
local function test(ok)assert(ok);cases=cases+1 end
for _,n in ipairs{0,1,99,100,101,9999,10000,10001,123456,2147483647}do
 local hi,mid,lo=m.parts(n);test(hi*10000+mid*100+lo==n and mid<100 and lo<100)
end
local a={money=99,jiaozi=9901,yuanbao=11,bind_yuanbao=12,zengdian=13}
m.normalize(a);test(a.money==10000 and a.yuanbao==36 and a.jiaozi==0 and a.bind_yuanbao==0 and a.zengdian==0)
m.normalize(a);test(a.money==10000 and a.yuanbao==36)
local r=m.update(a,{jiaozi=7});test(r.money==10007 and r.jiaozi==0)
r=m.update(a,{bind_yuanbao=5,zengdian=3});test(r.yuanbao==44 and r.bind_yuanbao==0 and r.zengdian==0)
test(not pcall(m.normalize,{money=m.MAX,jiaozi=1}))
local H={get_money=function(h)return h.money end,get_yuanbao=function(h)return h.yb end,
 set_money=function(h,n)h.money=n;h.writes=h.writes+1;return true end,
 set_yuanbao=function(h,n)h.yb=n;h.writes=h.writes+1;return true end,
 check_cost_money_by_shop_type=function(h,k,n)return (k==5 and h.yb or h.money)>=n end,
 cost_money_by_shop_type=function(h,k,n)if k==5 then h:cost_yuanbao(n)else h:cost_money(n)end end}
m.install(H)
local h=setmetatable({money=10001,yb=301,writes=0},{__index=H})
test(h:get_jiaozi()==0 and h:get_bind_yuanbao()==0)
test(h:cost_money_with_priority(2) and h.money==9999)
test(h:add_jiaozi(1) and h.money==10000 and h:get_jiaozi()==0)
test(h:cost_money_by_shop_type(8,100) and h.money==9900)
test(h:cost_money_by_shop_type(9,100) and h.yb==201)
test(h:add_bind_yuanbao(99) and h.yb==300 and h:get_bind_yuanbao()==0)
test(h:cost_bind_yuanbao(1) and h.yb==299)
for _,n in ipairs{-1,0/0,math.huge,0.5,m.MAX+1}do
 local before=h.writes;test(not h:cost_money(n) and not h:add_money(n) and not h:cost_yuanbao(n) and not h:add_yuanbao(n) and h.writes==before)
end
local before=h.writes;test(not h:cost_money(9901) and h.money==9900 and h.writes==before)
test(h:cost_money(9900) and h.money==0);before=h.writes
test(not h:cost_money(1) and h.writes==before)
h.money=m.MAX;test(not h:add_jiaozi(1) and h.money==m.MAX)
print('PASS '..cases..' currency cases: denominations, exact/idempotent conversion, legacy rewards/shop routes, insufficiency, invalid amounts, overflow, no double wallet')
