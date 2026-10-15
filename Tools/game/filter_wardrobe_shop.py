"""Remove only verified wardrobe appearances from private yuanbao shelves.

Works on raw ShopTable cells to preserve its GBK data and six-cell merchandise
tuples. Canonical data is read-only; each write has a full table backup.
"""
from pathlib import Path
import argparse,datetime,hashlib,json,re,shutil,sys
from wardrobe_catalog import ROOT,build,text
from rt_dbc import Dbc
SERVER=Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913')
def excluded():
 cats=build()['categories'];why={};cfg=ROOT/'Assets/CanonicalCY/Data/ConfigFolder'
 def add(item,reason):why[int(item)]=reason
 for r in cats[1]:
  if any(r['valid']):add(r['id'],'wardrobe clothing item')
 for r in cats[7]:
  if any(r['valid']):add(r['visual'][0],'wardrobe weapon appearance')
 rides={r['visual'][0] for r in cats[9] if any(r['valid'])}
 d=Dbc(cfg/'EquipBase.txt')
 for i in range(d.nR):
  if d.i(i,5)==8 and d.i(i,6) in rides:add(d.i(i,0),'mount visual '+str(d.i(i,6)))
 # Native Exterior_Item type0 maps mount unlock cards to Exterior_Ride IDs.
 ride_ids={r['id'] for r in cats[9] if any(r['valid'])};d=Dbc(cfg/'Exterior_Item.txt')
 for i in range(d.nR):
  if d.i(i,2)==0 and d.i(i,3) in ride_ids:add(d.i(i,1),'mount unlock '+str(d.i(i,3)))
 def norm(name):return re.sub(r'\s+',' ',re.sub(r'\s+(Hình|Phát)$','',name,flags=re.I)).strip().casefold()
 faces={norm(n) for r in cats[2] if any(r['valid']) for n in r['name']}
 hairs={norm(n) for r in cats[3] if any(r['valid']) for n in r['name']}
 d=Dbc(cfg/'CommonItem.txt')
 for i in range(d.nR):
  name=text(d.s(i,6))
  match=re.fullmatch(r'Định Nhan Châu\s*[:：·]\s*(.+)',name,re.I)
  if match and norm(match[1]) in faces:add(d.i(i,0),'face name '+match[1])
  hair=re.sub(r'^(?:Bản Vẽ Kiểu Tóc|Bản Đồ Tóc|Kiểu Tóc|Phát Hình Đồ)\s*[:：·]?\s*','',name,flags=re.I)
  hair=re.sub(r'\s*(?:Bản Vẽ Kiểu Tóc|Phát Hình Đồ)$','',hair,flags=re.I)
  if hair!=name and norm(hair) in hairs:add(d.i(i,0),'hair name '+hair)
 return why
def transform(raw,why):
 lines=raw.split(b'\n');changes=[]
 for n,line in enumerate(lines[2:],2):
  end=b'\r' if line.endswith(b'\r') else b'';c=line.removesuffix(b'\r').split(b'\t')
  if not c[0].isdigit() or len(c)<27 or c[7] not in (b'5',b'6'):continue
  count=int(c[11]);goods=[c[27+6*i:33+6*i] for i in range(count)]
  assert all(len(g)==6 for g in goods),(c[0],count)
  kept=[];removed=[]
  for g in goods:
   item=int(g[0] or 0)
   if item in why:removed.append({'id':item,'reason':why[item]})
   elif item>0:kept.append(g)
  if not removed:continue
  for i in range(count):c[27+6*i:33+6*i]=kept[i] if i<len(kept) else [b'0',b'0',b'0',b'0',b'0',b'']
  c[11]=str(len(kept)).encode();lines[n]=b'\t'.join(c)+end
  changes.append({'shop':int(c[0]),'before':count,'after':len(kept),'removed':removed})
 return b'\n'.join(lines),changes
def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('mode',choices=['audit','apply']);p.add_argument('--out',type=Path,required=True);a=p.parse_args()
 target=SERVER/'configs/ShopTable.txt';raw=target.read_bytes();why=excluded();new,changes=transform(raw,why)
 assert not transform(new,why)[1],'filter must be idempotent'
 report={'changed_shops':len(changes),'removed_entries':sum(len(x['removed']) for x in changes),'shelves':changes}
 if a.mode=='apply' and changes:
  stamp=datetime.datetime.now().strftime('%Y%m%d-%H%M%S');bak=SERVER/'backups'/('wardrobe-shop-'+stamp);bak.mkdir(parents=True)
  shutil.copy2(target,bak/target.name);target.write_bytes(new);assert target.read_bytes()==new;report['backup']=str(bak)
 a.out.parent.mkdir(parents=True,exist_ok=True);a.out.write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8')
 print(json.dumps({k:v for k,v in report.items() if k!='shelves'},ensure_ascii=False))
 print([(x['shop'],x['before'],x['after']) for x in changes])
if __name__=='__main__':main()
