-- Read-only: evaluate the actual book module with a dependency-only base class,
-- inspect its captured data. Never call an item callback or construct a scene.
local root,out=assert(arg[1]),assert(arg[2])
package.path=root..'/GameServer/lualib/?.lua;'..root..'/Game_2/Script/?.lua;'..package.path
package.loaded.script_base=require('class')('audit_base')
-- The module captures configenginer for condition checks. This exporter never
-- invokes one; refuse if that read-only contract accidentally changes.
package.loaded.configenginer={getinstance=function()
    return {get_config=function()error('exporter must not execute item conditions')end}
end}
local module=require('scripts.obj.commonitem.338000')
local books
for n=1,30 do
    local name,value=debug.getupvalue(module.OnConditionCheck,n)
    if not name then break end
    if name=='g_SkillBooks' then books=value end
end
assert(type(books)=='table','book table not found')
local ids={};for id in pairs(books)do ids[#ids+1]=id end;table.sort(ids)
local file=assert(io.open(out,'w'))
file:write('item\ttype\tid\tmenpai\tlevel\txinfa\txinfa_level\n')
for _,id in ipairs(ids)do
    local b=books[id]
    file:write(table.concat({id,b.type,b.id,b.menpaiId,b.needLevel,b.needXinfa,b.needXinfaLevel},'\t'),'\n')
end
file:close();print('books='..#ids)
