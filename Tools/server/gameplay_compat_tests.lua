-- Offline only; run actual converted item script + production class/adapter.
-- lua gameplay_compat_tests.lua <private root> <adapter root> [old]
local root, source = assert(arg[1]), assert(arg[2])
package.path = source..'/GameServer/lualib/?.lua;'..root..'/GameServer/lualib/?.lua;'..root..'/Game_2/Script/?.lua;'..package.path
local class = require 'class'
local base = class('script_base_fixture')
local delivered = {}
function base:LuaFnSendOResultToPlayer(who, code) delivered={who,code};return 91 end
function base:LuaFnVerifyUsedItem() return true end
function base:LuaFnGetTargetObjID() return 99 end
function base:LuaFnUnitIsFriend() return false end
if arg[3] ~= 'old' then require('script_legacy_compat').install(base) end
package.loaded.script_base = base
package.loaded.define = {OPERATE_RESULT={OR_INVALID_TARGET=-8}}
local checks,failed=0,0
local function test(name,f)
    checks=checks+1;local ok,err=pcall(f)
    if not ok then failed=failed+1;print('FAIL '..name..': '..tostring(err)) end
end
test('actual item 3041 invalid-target path',function()
    local item=require('scripts.obj.commonitem.item_3041').new()
    assert(item:OnConditionCheck(17)==0)
    assert(delivered[1]==17 and delivered[2]==-8)
    assert(item.is_super_function('SendOResultToPlayer')) -- raw_call remains blocked
end)
local obj=base.new()
test('result delegate preserves return',function()assert(obj:SendOResultToPlayer(33,-12)==91);assert(delivered[1]==33 and delivered[2]==-12)end)
test('converted tostring including nil',function()assert(obj:tostring(27)=='27' and obj:tostring(nil)=='nil')end)
test('converted abs',function()assert(obj:abs(-4.25)==4.25)end)
test('converted format varargs',function()assert(obj:format('%s:%d','npc',12)=='npc:12')end)
test('converted getn',function()assert(obj:getn({4,5,6})==3)end)
test('converted random one point',function()assert(obj:random(9,9)==9)end)
test('invalid format remains an error',function()assert(not pcall(obj.format,obj,'%d',{}))end)
print(string.format('checks=%d errors=%d',checks,failed))
os.exit(failed==0 and 0 or 1)
