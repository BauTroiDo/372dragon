"""Import the GL soul catalog as isolated resources, never reuse GL numeric IDs in CY tables."""
from pathlib import Path
import hashlib,json,sys,struct
from dbc_inventory import Table
ROOT=Path(__file__).resolve().parents[2]
sys.path[:0]=[str(ROOT/'Tools/pipeline'),str(ROOT/'Tests')]
import canon_lib as C
from validators import common as V
CY=ROOT/'Assets/CanonicalCY/Data/ConfigFolder'
GL=ROOT.parent/'client_GL/Data'
SERVER=Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913/configs')
OUT=ROOT/'Build/Logs/2026-09-25-wuhun-appearance/assets'

class Source(C.SourceView):
    def __init__(self):
        self.root=str(GL);self.base=V.DataRoot(self.root)
        self.obj_data=(GL/'ModelFolder/all.obj').read_bytes();self.obj_first={}
        for n,s,e in V.obj_spans(self.obj_data):self.obj_first.setdefault(n,(s,e))
        self.obj_lower={n.lower():n for n in self.obj_first};self.defs={}
        for kind in C.DEF_KINDS:
            data=(GL/V.SCRIPTS[kind].replace('\\','/')).read_bytes();first={};parents={}
            for hdr,s,e in V.script_spans(data)[0]:
                n,parent=V.def_name(kind,hdr)
                if n and n not in first:first[n]=(s,e);parents[n]=parent or b''
            self.defs[kind]=(data,first,parents)
    def resolve(self,name):
        rel=self.base.resolve(name)
        # Planner wants a GBK-spelled relative name, not the Windows mojibake spelling.
        return '\\'.join(V.gbk_name(p).decode('gbk') for p in rel.split('\\')) if rel else None
    def file_bytes(self,rel):
        actual=self.base.resolve(rel.split('\\')[-1].encode('gbk'))
        return Path(self.base.path(actual)).read_bytes(),0,''

def generate():
    OUT.mkdir(parents=True,exist_ok=True)
    src=Source();base=V.DataRoot(str(ROOT/'Assets/CanonicalCY/Data'))
    plan=C.Planner(base,None,{'GL':src});plan.base_obj_lower=set()
    loc={r[0]:r for r in Table(GL/'ConfigFolder/ItemVisualLocator.txt').rows}
    catalog=Table(SERVER/'WuhunWg.txt');names={r[0]:r[1] for r in Table(GL/'ConfigFolder/WuhunWg.txt').rows}
    keys=sorted({v for r in catalog.rows for v in r[10:13]+r[16:19]})
    roots={v:plan.add_switched(loc[v][9].encode('gbk'),'GL','GL soul appearance') for v in keys}
    # Ogre creates each Entity with the embedded mesh materials before the .obj
    # applies its per-entity override. Import/rewrite those defaults as well.
    # Otherwise the final image may look correct while resource loading warns
    # about missing GL material names on every newly created soul.
    for mesh in list(plan.all_items()):
        if mesh.kind!='mesh':continue
        for sub in mesh.walk['subs']:
            material=plan.item_def('material','GL',sub['mat'])
            if material:mesh.deps.append(('submat',sub['mat'],material))
    assert not plan.problems,plan.problems
    items=plan.all_items()
    hj=ROOT/'Assets/Imported/HJ20260910'
    if (hj/'wuhun-overrides.json').exists():
        overrides={r['source']:r for r in json.loads((hj/'wuhun-overrides.json').read_text(encoding='utf8'))}
        for it in items:
            row=overrides.get(it.name.decode('gbk')) if it.kind=='texture' else None
            if row:
                data=(hj/'MaterialFolder'/row['hj_output']).read_bytes()
                assert hashlib.sha256(data).hexdigest()==row['sha256']
                it.data0=data;it.data=data
    for it in items:
        suffix=Path(it.name.decode('gbk')).suffix.encode('ascii') if it.kind in C.FILE_KINDS+('obj',) else b''
        it.final_name=b'cys_wh_'+hashlib.sha256(it.kind.encode()+b':'+it.name).hexdigest()[:16].encode()+suffix
    for it in items:plan.render(it)
    manifest=[];blocks={k:[] for k in C.SCRIPT_KINDS}
    for it in items:
        if it.kind in blocks:blocks[it.kind].append(it.data)
        else:
            folder='MaterialFolder' if it.kind=='texture' else 'ModelFolder'
            p=OUT/folder/it.final_name.decode();p.parent.mkdir(exist_ok=True);p.write_bytes(it.data)
        manifest.append({'kind':it.kind,'source':it.name.decode('gbk'),'output':it.final_name.decode(),'sha256':hashlib.sha256(it.data).hexdigest()})
    for kind,values in blocks.items():
        if not values:continue
        folder='ModelFolder' if kind=='obj' else 'MaterialFolder' if kind=='material' else 'EffectFolder'
        raw=b'\r\n'.join(values)
        if kind=='obj':raw=b'<AllObjects>\r\n'+raw+b'\r\n</AllObjects>\r\n'
        p=OUT/folder/('cys_wuhun.'+kind);p.parent.mkdir(exist_ok=True);p.write_bytes(raw)
    model=Table(CY/'CharModelEx.txt');rows=[r[:] for r in model.rows];baseModel=next(r for r in rows if r[0]==2341)
    next_id=max(r[0] for r in rows)+1
    mappings=[]
    for v in range(699,709):
        m=next(r[0] for r in rows if r[1]==loc[v][9]);mappings.append((v,loc[v][9],m))
    for v,it in roots.items():
        row=baseModel[:];row[0]=next_id;row[1]=it.final_name.decode();rows.append(row)
        mappings.append((v,row[1],next_id));next_id+=1
    # Preserve every original cell and GBK resource key; Table's display decoder
    # is deliberately not used to round-trip this mixed-encoding binary table.
    raw=(CY/'CharModelEx.txt').read_bytes();magic,nf,nr,np=struct.unpack_from('<Iiii',raw)
    cellstart=16+nf*4;poolstart=cellstart+nf*nr*4
    cells=bytearray(raw[cellstart:poolstart]);pool=bytearray(raw[poolstart:poolstart+np])
    template=raw[cellstart+model.rows.index(baseModel)*nf*4:cellstart+(model.rows.index(baseModel)+1)*nf*4]
    for row in rows[nr:]:
        cell=bytearray(template);struct.pack_into('<I',cell,0,row[0]);struct.pack_into('<I',cell,4,len(pool))
        pool.extend(row[1].encode('ascii')+b'\0');cells.extend(cell)
    (OUT/'CharModelEx.txt').write_bytes(struct.pack('<Iiii',magic,nf,len(rows),len(pool))+raw[16:cellstart]+cells+pool)
    quote=lambda x:'"'+''.join('\\%03o'%b for b in x.encode('gbk'))+'"'
    header=['#pragma once','// Generated by wuhun_appearance_data.py. Visual IDs belong to the private GL server.',
            'namespace CysWuhunData {','struct Visual {int id;const char* object;int model;};','static const Visual visuals[] = {']
    header+=['{%d,%s,%d},'%(v,quote(obj),m) for v,obj,m in mappings]
    header+=['};','inline const Visual* Find(int id){for(const auto& r:visuals)if(r.id==id)return &r;return nullptr;}',
             'struct Soul {int id;const char* name;int gold,material[2],count;};','static const Soul souls[] = {']
    header+=['{%d,u8%s,%d,{%d,%d},%d},'%(r[0],json.dumps(names[r[0]],ensure_ascii=False),r[3],r[4],r[5],r[6]) for r in catalog.rows]
    header+=['};','struct Upgrade {int key,gold,material[2],count;};','static const Upgrade upgrades[] = {']
    upgrade=Table(SERVER/'WuhunWgLevel.txt')
    for r in upgrade.rows:
        header.append('{%d,%d,{%d,%d},%d},'%(r[0],r[4],r[5],r[6],r[7]))
    header+=['};','inline const Upgrade* Cost(int id,int lv,int grade){for(const auto& r:upgrades)if(r.key==id*10000+lv*100+grade)return &r;return nullptr;}',
             'inline int HuanVisual(int id,int side,int tier){static const int v[6][2][3]={']
    header+=['{{%s},{%s}},'%(','.join(map(str,r[10:13])),','.join(map(str,r[16:19]))) for r in catalog.rows]
    header+=['};return id>=1&&id<=6&&side>=0&&side<2&&tier>=0&&tier<3?v[id-1][side][tier]:0;}','}']
    (ROOT/'Src/Client/WXClient/DataPool/CysWuhunData.h').write_text('\n'.join(header)+'\n',encoding='utf8')
    (OUT/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=1),encoding='utf8')
    (ROOT/'Registry/wuhun-appearance.json').write_text(json.dumps({'source':'GL WuhunWg / ItemVisualLocator, private server visual IDs','models':[{'visual':v,'object':obj,'model':m} for v,obj,m in mappings]},ensure_ascii=False,indent=1),encoding='utf8')
    print('Imported',len(roots),'appearances,',len(items),'isolated dependencies; model IDs',rows[-36][0],rows[-1][0])
if __name__=='__main__':generate()
