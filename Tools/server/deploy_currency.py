from pathlib import Path
import datetime,json,hashlib,shutil,subprocess,sys,re
ROOT=Path(__file__).resolve().parents[2]
LIVE=Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913')
OUT=ROOT/'Build/Logs/2026-09-26-vothach/server'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def method(s,name,body):
 start=s.index('function '+name+'(');end=s.index('\nfunction ',start+10)
 return s[:start]+body.rstrip()+'\n'+s[end:]
def patch(rel,s):
 if rel.endswith('/event/zhenghe.lua'):
  old='''    local bind_yuanbao = self:GetBindYuanBao(selfId)
    local yuanbao = self:GetYuanBao(selfId)
    if bind_yuanbao + yuanbao < cost then'''
  assert s.count(old)==1
  s=s.replace(old,'''    local yuanbao = self:GetYuanBao(selfId)
    if yuanbao < cost then''')
  old='''    local bind_cost = math.min(bind_yuanbao, cost)
    local yuanbao_cost = cost - bind_cost
    if bind_cost > 0 then
        self:LuaFnCostBindYuanBao(selfId, bind_cost)
    end
    if yuanbao_cost > 0 then
        self:LuaFnCostYuanBao(selfId, yuanbao_cost)
    end'''
  assert s.count(old)==1
  return s.replace(old,'    self:LuaFnCostYuanBao(selfId, cost)').replace('Tổng nguyên bảo khóa và nguyên bảo không đủ','Không đủ Nguyên Bảo').replace('nguyên bảo khóa/nguyên bảo mua','Nguyên Bảo mua')
 if rel.endswith('/893252.lua'):
  start=s.index('function common_item:Yuanbao_AddFuZhou(');end=s.index('\nreturn common_item',start)
  return s[:start]+'''function common_item:Yuanbao_AddFuZhou(selfId, BagPos)
    -- Both historical purchase buttons now spend one Yuanbao wallet once.
    return self:YuanbaoBind_AddFuZhou(selfId, BagPos)
end
'''+s[end:]
 if rel.endswith('/human_attrib.lua'):
  anchor='    self.db_attribs = db';assert s.count(anchor)==1
  s=s.replace(anchor,"    require('cys_currency').normalize(db)\n"+anchor)
  anchor='function human_attrib:set_db_attrib(set_list)';assert s.count(anchor)==1
  return s.replace(anchor,anchor+"\n    set_list = require('cys_currency').update(self.db_attribs,set_list)")
 if rel.endswith('/script_base.lua'):
  s=method(s,'script_base:GetBindYuanBao','''function script_base:GetBindYuanBao(selfId)
    return self.scene:get_obj_by_id(selfId):get_yuanbao()
end''')
  # Conversion is now an identity: both names denote the same wallet.
  start=s.index('    local my_jiaozi = human:get_jiaozi()')
  a=s.rfind('\nfunction ',0,start);b=s.index('\nfunction ',start)
  old=s[a:b];sig=old.split('\n')[1]
  s=s[:a]+'\n'+sig+"\n    return true -- Vo Thach has no separate bound wallet.\nend\n"+s[b:]
  return s
 if rel.endswith('/human.lua'):
  # Sell-to-NPC bound proceeds become ordinary Vo Thach; do not overwrite balance.
  anchor='local money = self:get_jiaozi()';assert s.count(anchor)==1
  s=s.replace(anchor,'local money = self:get_money()')
  pos=s.rfind('return human');assert pos>0
  return s[:pos]+"require('cys_currency').install(human)\n"+s[pos:]
 raise AssertionError(rel)
def main():
 OUT.mkdir(parents=True,exist_ok=True);rows=[]
 paths=['GameServer/services/scene/obj/human.lua','GameServer/services/scene/human.lua','GameServer/lualib/db/human_attrib.lua','GameServer/lualib/script_base.lua','GameServer/lualib/cys_currency.lua','Game_2/Script/scripts/obj/commonitem/893252.lua','Game_2/Script/scripts/event/zhenghe.lua']
 for rel in paths:
  live=LIVE/rel;before=OUT/'baseline'/rel;after=OUT/'candidate'/rel
  if live.exists() and not before.exists():before.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(live,before)
  if rel.endswith('/cys_currency.lua'):raw=(Path(__file__).parent/'cys_currency.lua').read_bytes()
  else:raw=patch(rel,before.read_text(encoding='utf8')).encode()
  after.parent.mkdir(parents=True,exist_ok=True);after.write_bytes(raw)
  subprocess.run(['wsl','-d','TLBB','-u','root','--','luac5.4','-p','/mnt/c'+after.as_posix()[2:]],check=True)
  rows.append({'path':rel,'before':sha(before) if before.exists() else None,'after':sha(after)})
 if '--apply' in sys.argv:
  active=subprocess.check_output(['wsl','-d','TLBB','-u','root','--','ss','-Htn','state','established'],text=True)
  assert not re.search(r':1573[34]\b',active),'Private client connected'
  backup=LIVE/'backups'/('vothach-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S'))
  for r in rows:
   p=LIVE/r['path'];assert (sha(p) if p.exists() else None) in [r['before'],r['after']],r['path']
  for r in rows:
   p=LIVE/r['path']
   if p.exists():b=backup/r['path'];b.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,b)
   shutil.copy2(OUT/'candidate'/r['path'],p)
 (OUT/'manifest.json').write_text(json.dumps(rows,indent=2));print('PASS currency syntax; applied','--apply' in sys.argv)
if __name__=='__main__':main()
