-- Read-only: real cfghelper, exact server function bodies, fixture items only.
-- Exit 1 reports a gameplay invariant failure; no live service or account is changed.
local root = assert(arg[1], 'private server root required')
local source=arg[2] or root
assert(root:match('/cys%-test%-20260913$'), 'private root only')
package.path = source..'/GameServer/lualib/?.lua;'..root..'/GameServer/lualib/?.lua;'..package.path
package.cpath = root..'/GameServer/luaclib/?.so;'..package.cpath
local say, quiet = print, function()end
package.loaded.skynet = {getenv=function(k) if k=='config_path' then return root..'/configs/%s' end end,
    logd=quiet,logi=quiet,logw=quiet,loge=quiet,error=quiet,log=quiet}
package.loaded['skynet.manager'] = {}
package.loaded['skynet.sharetable'] = {}
table.tostr = function()return '' end
local define = require 'define'
local cfg = require('cfghelper').new()
local configs = {}
for _,name in ipairs({'ling_yu_base','ling_yu_set','ling_yu_set_effect','equip_base'}) do
    print=quiet; cfg['read_'..name](cfg); print=say
    configs[name]=assert(cfg[name], name)
end
local function method(rel, class_name, method_name, env)
    local f=assert(io.open(source..'/GameServer/lualib/'..rel,'rb'))
    local src=f:read('*a'):gsub('\r\n','\n');f:close()
    local signature='function '..class_name..':'..method_name
    local start=assert(src:find(signature,1,true))
    local finish=assert(src:find('\nend',start,true)) + 3
    local line=select(2,src:sub(1,start-1):gsub('\n',''))+1
    local body=src:sub(start,finish)
    assert(load(body,'@'..rel..':'..line,'t',env))()
    say('SOURCE\t'..rel..':'..line..'\t'..method_name)
end
local human_attrib,item_operator={},{}
local env=setmetatable({human_attrib=human_attrib,item_operator=item_operator,define=define,
    configenginer={get_config=function(_,name)return assert(configs[name],name)end}},{__index=_G})
method('db/human_attrib.lua','human_attrib','lingwu_equip_effect_flush',env)
method('item_operator.lua','item_operator','gen_common_equip_attrib',env)
local pass,fail=0,0
local function result(ok,name,detail)
    if ok then pass=pass+1 else fail=fail+1 end
    say((ok and 'PASS' or 'FAIL')..'\t'..name..'\t'..detail)
end
local current, slot, effects, branch
local function make_item(id)
    local data={}
    local ed=setmetatable({}, {__index=function(_,k)
        assert(k:match('^set_'),k)
        return function(_,v)data[k:sub(5)]=v end
    end})
    return {get_index=function()return id end,
        get_serial_type=function()return 1 end,
        copy_raw_data=function()return data end,
        get_equip_data=function()return ed end,set_rule=quiet,set_item_creator=function(_,v)data.creator=v end}
end
function item_operator:gen_lingyu_attr(item)
    branch='lingyu'
    -- Neutral extension attrs isolate the real base-table lookup and base effects.
    local ed=item:get_equip_data()
    ed:set_ling_yu_attrs({});ed:set_ling_yu_attr_values({})
end
function human_attrib:get_human()
    return {get_equip_container=function()return {get_item=function(_,i)if i==slot then return current end end}end}
end
function human_attrib:cal_item_effect(ia,iv,equip_point)
    effects[#effects+1]=string.format('%s:%s@%s',ia,iv,equip_point)
end
local function flush(id,p)
    slot=p;effects={};branch='none';current=id and make_item(id) or nil
    if current then item_operator:gen_common_equip_attrib(nil,current)end
    return pcall(human_attrib.lingwu_equip_effect_flush,human_attrib)
end
local ok,err=flush(nil,19)
result(ok and #effects==0,'empty_control','no_throw='..tostring(ok))
-- A valid reference LingYu item, independent of the CY EquipBase collision.
slot=19;effects={};current=make_item(10157000)
current:get_equip_data():set_ling_yu_attrs({})
current:get_equip_data():set_ling_yu_attr_values({})
ok,err=pcall(human_attrib.lingwu_equip_effect_flush,human_attrib)
result(ok and #effects>0,'valid_lingyu_control','effects='..table.concat(effects,','))
slot=19;effects={};current=make_item(19999999)
ok,err=pcall(human_attrib.lingwu_equip_effect_flush,human_attrib)
result(not ok and tostring(err):find('base',1,true)~=nil,'absent_id_negative_control',tostring(err))
for _,id in ipairs({10157001,10157002,10158001,10158002,10158003,10158004,10158005})do
    local base=assert(configs.equip_base[id],tostring(id))
    local present=configs.ling_yu_base[id]~=nil
    ok,err=flush(id,base.equip_point)
    result(ok and branch~='lingyu','cy_item_'..id,
        string.format('slot=%s lingyu_row=%s init_branch=%s no_throw=%s effects=%s error=%s',
        base.equip_point,tostring(present),branch,tostring(ok),table.concat(effects,','),ok and '-' or tostring(err)))
end
say(string.format('SUMMARY checks=%d pass=%d fail=%d',pass+fail,pass,fail))
os.exit(fail==0 and 0 or 1)
