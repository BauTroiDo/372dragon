-- Read-only routing audit. Uses the actual script registry and scriptenginer.
-- Engine dependencies/scene are fixtures; no gameplay callback is invoked.
local root=assert(arg[1])
assert(root:match('/cys%-test%-20260913$'),'private server only')
package.path=root..'/GameServer/lualib/?.lua;'..root..'/Game_2/Script/?.lua;'..package.path
package.cpath=root..'/GameServer/luaclib/?.so;'..package.cpath
local messages={}
local function log(...)local t={};for _,v in ipairs({...})do t[#t+1]=tostring(v)end;messages[#messages+1]=table.concat(t,' ')end
package.loaded.skynet={logw=log,loge=log,logd=log,error=log}
package.loaded['game.packet']={}
package.loaded.utils={}
package.loaded.configenginer={getinstance=function()return {} end}
local base=require('class')('audit_route_base')
function base:set_scene(scene)self.scene=scene end
package.loaded.script_base=base
local engine=require('scriptenginer').new()
engine:set_scene({})
local routes={
 {'LW',809273,'Lw_PropertyReset'}, {'LW',809273,'DoRefreshLw_Property'}, {'LW',809273,'ExchangeLongWen'},
 {'RL',880001,'RlResetExAttr'}, {'RL',880001,'RL_StarLevelup'}, {'RL',880001,'RL_StarLevelup_Auto'},
 {'RL',880001,'RsLevelUp_RL'}, {'RL',880001,'RL_SetRs'}, {'RL',880001,'RL_RemoveRs'},
 {'RL',880001,'RL_SwitchSkill'}, {'RL',880001,'RlGradeLevelUp'}, {'RL',880011,'ShreddingGem'},
 {'SD',339008,'OnLianDanLuNingLian'}, {'SD',339008,'OnLianDanLuRongHe'}, {'SD',339008,'OnLianDanLuHelp'},
 {'SD',339011,'OnLianDanLuNingLian'}, {'SD',339011,'OnLianDanLuRongHe'}, {'SD',339011,'OnLianDanLuQianNengAccept'},
}
local pass,fail=0,0
local function result(ok,name,detail)
 if ok then pass=pass+1 else fail=fail+1 end
 print((ok and 'PASS' or 'FAIL')..'\t'..name..'\t'..detail)
end
result(engine:have_function(809270,'OnAction')==true,'positive_existing_wuhun','809270/OnAction')
result(not engine:have_function(1999999999,'Absent'),'negative_absent_id','1999999999/Absent')
for _,r in ipairs(routes)do
 local present=engine:have_function(r[2],r[3])==true
 result(present,r[1]..'_callback',r[2]..'/'..r[3]..' registered='..tostring(engine.dat[r[2]]))
end
for _,id in ipairs({892003,880010,901000})do
 result(engine:try_load(id)~=nil,'pack_alternate_script',tostring(id)..' registered='..tostring(engine.dat[id]))
end
print(string.format('SUMMARY checks=%d pass=%d fail=%d dependency_errors=%d',pass+fail,pass,fail,#messages))
for _,m in ipairs(messages)do print('ENGINE '..m)end
os.exit(fail==0 and 0 or 1)
