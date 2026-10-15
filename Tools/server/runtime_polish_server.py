"""Prepare a reviewable private-server patch; never touch the main WSL server."""
from pathlib import Path
import sys,re,json,hashlib,shutil,datetime,argparse
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'Tools/game'))
from dbc_inventory import Table
from round2_gm_rules import literal
SERVER=Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913')
OUT=ROOT/'Build/Logs/2026-09-26-runtime-polish/server'
sha=lambda b:hashlib.sha256(b).hexdigest()
def gift_allowlist():
 rel='configs/AllowableScriptFunc.txt';raw=(SERVER/rel).read_bytes()
 rows=[line.split('\t') for line in raw.decode('gbk').splitlines()[2:] if line.strip()]
 assert not any(r[1]=='990031' for r in rows)
 index=max(int(r[0]) for r in rows)+1
 return rel,raw.rstrip(b'\r\n')+f'\r\n{index}\t990031\tOnClientGetGift\r\n'.encode('ascii')

def allowlist():
 # msgagent has a separate client-call allowlist from script registration.
 rel,raw=gift_allowlist();p=SERVER/rel
 backup=SERVER/'backups'/('runtime-polish-allowlist-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S'))/rel
 backup.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,backup)
 record={'path':rel,'before':sha(p.read_bytes()),'after':sha(raw),'backup':str(backup)}
 p.write_bytes(raw);(OUT/'allowlist-patch.json').write_text(json.dumps(record,indent=2));print(record)

def plan():
 content={}
 rel,raw=gift_allowlist();content[rel]=raw
 common={r[0]:r for r in Table(SERVER/'configs/CommonItem.txt').rows}
 ids=set(common)
 for name in ['EquipBase','GemInfo']:ids.update(r[0] for r in Table(SERVER/f'configs/{name}.txt').rows)
 eligible={};excluded=[]
 for row in Table(ROOT/'Assets/CanonicalCY/Data/ConfigFolder/OptionalGiftBox.txt').rows:
  rewards=[[row[11+4*i],row[12+4*i]] for i in range(row[9])]
  # Skip special acquisition/state/expiry variants until their separate rules
  # are recovered. Ordinary CY row: choose exactly one, two to five options.
  basic=row[5]==1 and row[6]==0 and row[7]==-1 and row[10]==1 and 2<=row[9]<=5
  basic=basic and all(row[13+4*i]==-1 and row[14+4*i]==-1 for i in range(row[9]))
  basic=basic and row[1] in common and all(item in ids and 1<=count<=65535 for item,count in rewards)
  if basic:eligible[row[1]]={'bind':row[8]==1,'items':rewards}
  else:excluded.append(row[1])
 assert eligible
 # Lua literal helper has no bool support.
 raw='return '+literal({k:{'bind':1 if v['bind'] else 0,'items':v['items']} for k,v in eligible.items()})+'\n'
 content['GameServer/lualib/cys_gift_boxes_data.lua']=raw.encode()
 content['GameServer/lualib/cys_gift_boxes.lua']=(ROOT/'Tools/server/cys_gift_boxes.lua').read_bytes()
 content['Game_2/Script/scripts/cys_gift_boxes.lua']=(ROOT/'Tools/server/cys_gift_boxes_script.lua').read_bytes()
 rel='Game_2/Script/scripts/scripts.lua';s=(SERVER/rel).read_text(encoding='utf8');assert '[990031]' not in s
 content[rel]=s.replace('local dat = {','local dat = {\n    [990031] = "scripts.cys_gift_boxes",',1).encode()
 rel='GameServer/services/scene/scenecore.lua';s=(SERVER/rel).read_text(encoding='utf8')
 old="            if require('cy_lingpai').is_book(item_index) then"
 new="""            if require('cys_gift_boxes').supported(item_index) then
                local gift=require('cys_gift_boxes')
                result=gift.open(self.scriptenginer:try_load(990031),obj_me,use.bagIndex) and 0 or 1
            elseif require('cy_lingpai').is_book(item_index) then"""
 assert s.count(old)==1;s=s.replace(old,new)
 old='            elseif script_id ~= define.INVAILD_ID then'
 new='''            elseif script_id ~= define.INVAILD_ID then
                if not self.scriptenginer:have_function(script_id,"OnDefaultEvent") and not self.scriptenginer:have_function(script_id,"OnActivateOnce") then
                    obj_me:notify_tips("Vật phẩm chưa có nội dung sử dụng trên máy chủ (ID "..item_index.."). Vật phẩm vẫn được giữ trong Túi.")
                    return
                end'''
 assert s.count(old)==1;s=s.replace(old,new)
 for old,new in [('请先加入门派','Hãy gia nhập môn phái trước khi lên cấp')]:s=s.replace(old,new)
 content[rel]=s.encode()
 rel='GameServer/services/scene/obj/human.lua';s=(SERVER/rel).read_text(encoding='utf8')
 start=s.index('function human:add_my_exp(');end=s.index('\nend',start)+4
 block=s[start:end].replace('self:notify_tips("#{DNS_211124_54}")','self:notify_tips("EXP tích lũy đã đạt giới hạn 3,5 lần. Hãy lên cấp hoặc dùng EXP để nhận thêm.")')
 content[rel]=(s[:start]+block+s[end:]).encode()
 OUT.mkdir(parents=True,exist_ok=True);manifest=[]
 for rel,raw in content.items():
  p=OUT/rel;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(raw)
  manifest.append({'path':rel,'before':sha((SERVER/rel).read_bytes()) if (SERVER/rel).exists() else None,'after':sha(raw)})
 (OUT/'plan.json').write_text(json.dumps(manifest,indent=2))
 (OUT/'gift-data-audit.json').write_text(json.dumps({'supported':eligible,'special_or_missing_rewards':excluded},ensure_ascii=False,indent=2))
 print('Prepared',len(content),'files; ordinary optional boxes',len(eligible),'special/incomplete',len(excluded))
def apply():
 rows=json.loads((OUT/'plan.json').read_text())
 for r in rows:assert (sha((SERVER/r['path']).read_bytes()) if (SERVER/r['path']).exists() else None)==r['before'],r['path']
 backup=SERVER/'backups'/('runtime-polish-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S'))
 for r in rows:
  p=SERVER/r['path'];raw=(OUT/r['path']).read_bytes();assert sha(raw)==r['after']
  if p.exists():b=backup/r['path'];b.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,b)
  p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(raw)
 print('Applied; backup',backup)
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('mode',choices=['plan','apply','allowlist']);a=p.parse_args()
 {'plan':plan,'apply':apply,'allowlist':allowlist}[a.mode]()
