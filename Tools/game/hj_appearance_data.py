"""Import HJ cosmetic resources into an isolated, reproducible CY overlay.

Donors and CanonicalCY are read-only. Resource names are GBK bytes; only UI
labels are decoded. Tables are extended without re-encoding existing cells.
"""
from pathlib import Path
import argparse, collections, hashlib, json, re, struct, sys

ROOT=Path(__file__).resolve().parents[2]
sys.path[:0]=[str(ROOT/'Tools/pipeline'),str(ROOT/'Tests')]
import canon_lib as C
from validators import common as V
HJ=ROOT.parent/'Tools/DATA NEW/CYHJ091026'
PLAY=ROOT/'Build/world-gui/stage-play-21'
CY=ROOT/'Assets/CanonicalCY/Data'
OUT=ROOT/'Build/Logs/2026-09-25-hj-import'
PACK=ROOT/'Assets/Imported/HJ20260910'

def sha(b): return hashlib.sha256(b).hexdigest()
def display(b): return b.decode('gbk') if isinstance(b,bytes) else b
def json_write(path,value):
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(json.dumps(value,ensure_ascii=False,indent=1)+'\n',encoding='utf8')

class RawTable:
    def __init__(self,path):
        self.path=Path(path); self.raw=self.path.read_bytes(); self.rows=[]
        raw=self.raw; self.binary=raw[:4]==b'\x00\xcc\xbb\xdd'
        if self.binary:
            self.nf,self.nr,np=struct.unpack_from('<3I',raw,4)
            self.types=list(struct.unpack_from('<%dI'%self.nf,raw,16))
            self.start=16+4*self.nf; end=self.start+4*self.nf*self.nr
            self.pool=raw[end:end+np]; assert end+np==len(raw),self.path
            self.rawrows=[raw[self.start+i*self.nf*4:self.start+(i+1)*self.nf*4] for i in range(self.nr)]
            for cell in self.rawrows:
                row=[]
                for j,t in enumerate(self.types):
                    v=struct.unpack_from('<'+('f' if t==1 else 'i' if t==0 else 'I'),cell,j*4)[0]
                    if t==2:
                        assert v<len(self.pool),(path,v)
                        v=self.pool[v:self.pool.index(b'\0',v)]
                    row.append(v)
                self.rows.append(row)
        else:
            lines=raw.split(b'\n'); kinds=lines[0].rstrip(b'\r').split(b'\t')
            self.types=[{b'INT':0,b'FLOAT':1,b'STRING':2,b'UINT':3,b'DWORDTIME':4}[v] for v in kinds]
            self.nf=len(self.types)
            for line in lines[2:]:
                if not line.strip() or line.lstrip().startswith(b'#'):continue
                cells=line.rstrip(b'\r').split(b'\t'); assert len(cells)==self.nf,(path,len(cells),self.nf)
                self.rows.append([v if t==2 else float(v or b'0') if t==1 else int(v or b'0') for t,v in zip(self.types,cells)])
            self.nr=len(self.rows)
        self.byid={r[0]:r for r in self.rows}
        assert len(self.byid)==self.nr,('duplicate IDs',path)

    def extend(self,added):
        """Keep old record bytes/string offsets; merge new IDs in strictly sorted order."""
        if not self.binary:
            lines=self.raw.splitlines()
            cells={int(line.split(b'\t',1)[0]):line for line in lines[2:]
                   if line.strip() and not line.lstrip().startswith(b'#')}
            for row in added:
                assert len(row)==self.nf and row[0] not in cells,(self.path,row[0])
                values=[v if t==2 else str(v).encode('ascii') for t,v in zip(self.types,row)]
                assert all(b'\t' not in v and b'\n' not in v and b'\r' not in v for v in values)
                cells[row[0]]=b'\t'.join(values)
            return b'\r\n'.join(lines[:2]+[cells[k] for k in sorted(cells)])+b'\r\n'
        pool=bytearray(self.pool); cells={r[0]:c for r,c in zip(self.rows,self.rawrows)}
        offsets={}
        for row in added:
            assert len(row)==self.nf and row[0] not in cells,(self.path,row[0],len(row))
            cell=bytearray()
            for column,(t,v) in enumerate(zip(self.types,row)):
                if t==2:
                    assert isinstance(v,bytes),(self.path,row[0],v)
                    if v not in offsets:offsets[v]=len(pool);pool.extend(v+b'\0')
                    v=offsets[v]
                if t!=1:assert isinstance(v,int),(str(self.path),row[0],column,t,v)
                cell.extend(struct.pack('<'+('f' if t==1 else 'i' if t==0 else 'I'),v))
            cells[row[0]]=cell
        return self.raw[:4]+struct.pack('<3I',self.nf,len(cells),len(pool))+self.raw[16:self.start]+b''.join(cells[k] for k in sorted(cells))+pool

class HJSource(C.SourceView):
    """One missing HJ texture is restored from the same named CY distribution asset."""
    FLAG='tga_dweapon_2026七夕项羽战旗.dds'.encode('gbk')
    def __init__(self):
        super().__init__('S3');self.fallback=None
    def resolve(self,name):
        rel=super().resolve(name)
        if rel is None and name==self.FLAG:
            if self.fallback is None:self.fallback=C.SourceView('S2')
            other=self.fallback.resolve(name)
            if other:return '__S2__/'+other
        return rel
    def file_bytes(self,rel):
        if rel.startswith('__S2__/'):return self.fallback.file_bytes(rel[7:])
        return super().file_bytes(rel)

class HJPlanner(C.Planner):
    def item_def(self,kind,S,name):
        # The HJ .obj explicitly uses the 01 materials; the mesh was exported
        # with the old names. Resolve those defaults to that authored override.
        if kind=='material' and name.startswith('ride_2025精卫鸟'.encode('gbk')) and name not in self.src[S].defs[kind][1]:
            name=name.replace('ride_2025精卫鸟'.encode('gbk'),'ride_2025精卫鸟01'.encode('gbk'),1)
        return super().item_def(kind,S,name)

class Import:
    def __init__(self):
        self.tables={};self.roots=[];self.unresolved=[];self.repairs=[];self.source=HJSource()
        self.plan=HJPlanner(V.DataRoot(str(CY)),None,{'S3':self.source})
        self.plan.base_obj_lower=set()

    def table(self,name):
        if name not in self.tables:self.tables[name]=RawTable(HJ/'Config'/(name+'.txt'))
        return self.tables[name]

    def resource(self,kind,name,owner):
        if name in (b'',b'-1',b'0'):return None
        self.plan._ctx=owner.encode('ascii')
        if kind=='obj': it=self.plan.item_obj('S3',name)
        elif kind in C.FILE_KINDS:it=self.plan.item_file(kind,'S3',name)
        else:it=self.plan.item_def(kind,'S3',name)
        self.roots.append((owner,kind,name,it))
        return it

    def collect(self):
        # Source table defects verified against the actual submesh material
        # list, not repaired by substituting another costume.
        for vid in (383,384,385,529):
            row=self.table('ItemVisualChar').byid[vid]
            for col in (1,12):
                mesh=self.resource('mesh',row[col],'fashion:'+str(vid))
                old=row[col+1]
                row[col+1]=b';'.join(s['mat'] for s in mesh.walk['subs'])
                self.repairs.append({'table':'ItemVisualChar','id':vid,'column':col+1,'before':display(old),'after':display(row[col+1]),'evidence':'authored mesh submaterials'})
        visual_ids={r[2] for r in self.table('EquipDress').rows}
        for vid in sorted(visual_ids):
            r=self.table('ItemVisualChar').byid.get(vid)
            if not r:
                self.unresolved.append(['ItemVisualChar',vid,'Referenced by EquipDress but absent in HJ'])
                continue
            owner='fashion:'+str(vid)
            for col in (1,12):self.resource('mesh',r[col],owner)
            for col in list(range(2,12))+list(range(13,23)):
                for mat in r[col].split(b';'): self.resource('material',mat,owner)
        for n,cols in [('CharFaceGeo',[2]),('CharHairGeo',[2,3])]:
            for r in self.table(n).rows:
                for col in cols:self.resource('mesh',r[col],n+':'+str(r[0]))
        for r in self.table('ItemOrnamentsVisual').rows:
            for col in (1,3):self.resource('obj',r[col],'ornament:'+str(r[0]))
        model_ids=set()
        mounts=self.table('CharMount')
        for r in mounts.rows:
            if r[3]>=0:model_ids.add(r[3])
        for mid in sorted(model_ids):
            r=self.table('CharModelEx').byid[mid]
            self.resource('obj',r[1],'mount-model:'+str(mid))
        loc=self.table('ItemVisualLocator').byid
        vids={v for r in self.table('Exterior_Weapon').rows for v in r[9:13] if v>0}
        vids|={v for r in self.table('WuhunWg').rows for v in r[10:13]+r[16:19] if v>0}
        vids|={v for r in self.table('Exterior_Poss').rows for v in r[10:13] if v>0}
        self.locator_ids=sorted(vids)
        for vid in sorted(vids):
            r=loc[vid]
            for col in (2,5,9,11,13,15,17):self.resource('obj',r[col],'locator:'+str(vid))
            for col in (1,3,4,6,7,8,10,11,12,14,16,18):
                # Slots not used by this schema are blank/flags. Material keys
                # are imported only when the donor actually defines them.
                for mat in r[col].split(b';'):
                    if mat in self.source.defs['material'][1]:self.resource('material',mat,'locator:'+str(vid))
            for name in r[19:]:self.resource('effect',name,'locator:'+str(vid))
        for r in self.table('SpecialDressEffect').rows:
            for col in (1,2):
                for entry in r[col].split(b','):
                    self.resource('effect',entry.split(b':')[0],'dress-effect:'+str(r[0]))
        # Action names can name .skill wrappers rather than skeleton animations.
        # Preserve the donor's animation, timed effects, ribbons and sounds.
        # Scope these to the actual mount models, not generic rider combat sets.
        mount_byid=self.table('CharMount').byid
        model_byid=self.table('CharModelEx').byid
        mount_sets={model_byid[mount_byid[r[10]][3]][9] for r in self.table('Exterior_Ride').rows}
        lines=self.table('ActionSet/ActionSetLine').byid
        kv=self.table('ActionSet/ActionSetKV').byid
        names={kv[v][1] for r in self.table('ActionSet/ActionSet').rows if r[1] in mount_sets for v in lines[r[3]][1:12]}
        raw=C.IS.read_src('S3','skill')
        definitions={V.def_name('skill',h)[0]:raw[a:b] for h,a,b in V.script_spans(raw)[0]}
        ornament_ids={r[4] for table in ('Exterior_TS','Exterior_BG') for r in self.table(table).rows}
        ornament_names={name for r in self.table('ItemLocatorAction').rows if r[1]==3 and r[2] in ornament_ids for name in r[6:9] if name}
        # These two new names are already carried by the native back-action
        # data. Provide collision-checked aliases to isolated HJ definitions;
        # existing CY skill definitions and compiled catalog IDs stay intact.
        self.skill_aliases=(ornament_names & definitions.keys())-self.plan.base.defs('skill')['first'].keys()
        names|=self.skill_aliases
        self.skills={};self.sounds={}
        for name in sorted(names & definitions.keys()):
            block=definitions[name];deps={}
            for prop,ref in re.findall(rb'^\s*(EffectTemplateName|Material|SoundName)\s+([^\r\n]+)',block,re.M):
                ref=ref.strip()
                if prop==b'EffectTemplateName' and ref.startswith(b'<') and ref.endswith(b'>'):
                    # LogicModel::_getTemplateEffectName resolves terrain/water
                    # placeholders at runtime; these are not resource names.
                    continue
                if prop==b'SoundName':
                    path=HJ/'Sound'/display(ref).replace('\\','/')
                    assert path.is_file(),('missing skill sound',display(name),str(path))
                    data=path.read_bytes();out=b'cys_hj_'+sha(b'sound:'+ref)[:16].encode()+b'.wav'
                    self.sounds[ref]=(out,data)
                else:
                    kind='effect' if prop==b'EffectTemplateName' else 'material'
                    deps[(prop,ref)]=self.resource(kind,ref,'mount-skill:'+sha(name)[:12])
            self.skills[name]=(block,deps)
        # Some premium mounts use rider poses absent from CY's character
        # skeleton links (boat/umbrella, phoenix, Qixi bridge). Extend the
        # existing CY actors with the exact HJ authored skeletons only.
        self.rider_links={}
        actions=collections.defaultdict(dict)
        for r in self.table('ActionSet/ActionSet').rows:actions[r[1]][r[2]]=kv[lines[r[3]][10]][1]
        mounts=[mount_byid[r[10]] for r in self.table('Exterior_Ride').rows]
        for sex,cols in [('女',(6,9)),('男',(7,10))]:
            required=set()
            for mount in mounts:
                for col in cols:
                    for action in (0,1,2,3,4,9,12,922,923,924,925,926,927,928,929):
                        name=actions[mount[col]].get(action,b'')
                        if not name or name==b'-1':continue
                        wrapper=definitions.get(name)
                        required.add(re.search(rb'^\s*Animation\s+([^\r\n]+)',wrapper,re.M)[1].strip() if wrapper else name)
            donor=self.source.obj_block((sex+'主角.obj').encode('gbk'))[1]
            links={anim:link for link in V.tags(donor,b'Skeleton') for anim in link.get(b'animations',b'').split()}
            for suffix in ('','_iv'):
                actor=(sex+'主角'+suffix+'.obj').encode('gbk');base=self.plan.base.object_block(actor)
                assert base and b'</Skeletons>' in base,display(actor)
                available={anim for link in V.tags(base,b'Skeleton') for anim in link.get(b'animations',b'').split()}
                additions=[]
                for name in sorted(required-available):
                    assert name in links,('missing rider animation in HJ',display(actor),display(name))
                    link=links[name];skel=self.resource('skeleton',link[b'skeleton'],'rider:'+sex.encode('gbk').hex())
                    additions.append((name,skel))
                self.rider_links[actor]=(base,additions)
        # Import embedded defaults before overrides; process newly discovered
        # meshes too (an effect may introduce another mesh).
        seen=set()
        while True:
            meshes=[i for i in self.plan.all_items() if i.kind=='mesh' and id(i) not in seen]
            if not meshes:break
            for it in meshes:
                seen.add(id(it));self.plan._ctx=it.name
                for sub in it.walk['subs']:
                    mat=self.plan.item_def('material','S3',sub['mat'])
                    if mat:it.deps.append(('submat',sub['mat'],mat))
        items=self.plan.all_items()
        for it in items:
            suffix=Path(display(it.name)).suffix.encode('ascii') if it.kind in C.FILE_KINDS+('obj',) else b''
            it.final_name=b'cys_hj_'+sha(it.kind.encode()+b':'+it.name)[:16].encode()+suffix
        # dynbone lookup derives the name from the mesh basename.
        for it in items:
            if it.kind=='dynbone' and it.follows:it.final_name=it.follows.final_name.rsplit(b'.',1)[0]+b'.dynbone'
        report={'source':str(HJ),'roots':len(self.roots),'counts':dict(collections.Counter(i.kind for i in items)),
                'source_bytes':sum(len(i.data0) for i in items),'problems':self.plan.problems,'unresolved_tables':self.unresolved,'repairs':self.repairs,
                'tables':{n:sha(t.raw) for n,t in self.tables.items()}}
        json_write(OUT/'resource-audit.json',report)
        print(json.dumps(report,ensure_ascii=False),flush=True)
        return items

    def export(self,items):
        assert not self.plan.problems,'Resolve resource-audit.json before export'
        blocks={k:[] for k in C.SCRIPT_KINDS};manifest=[]
        for it in items:
            self.plan.render(it)
            folder='ModelFolder' if it.kind in ('mesh','skeleton','dynbone','obj') else 'MaterialFolder' if it.kind in ('texture','material') else 'EffectFolder'
            if it.kind in blocks:blocks[it.kind].append(it.data)
            else:
                path=PACK/folder/it.final_name.decode();path.parent.mkdir(parents=True,exist_ok=True)
                if not path.exists() or sha(path.read_bytes())!=sha(it.data):path.write_bytes(it.data)
            manifest.append({'kind':it.kind,'source':display(it.name),'output':it.final_name.decode(),'source_sha256':sha(it.data0),'sha256':sha(it.data)})
        for kind,values in blocks.items():
            if not values:continue
            folder='ModelFolder' if kind=='obj' else 'MaterialFolder' if kind=='material' else 'EffectFolder'
            raw=b'\r\n'.join(values)
            if kind=='obj':raw=b'<AllObjects>\r\n'+raw+b'\r\n</AllObjects>\r\n'
            p=PACK/folder/('cys_hj.'+kind);p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(raw)
        skills=[]
        for name,(block,deps) in self.skills.items():
            out=b'cys_hj_'+sha(b'skill:'+name)[:16].encode()
            def replace(m):
                prop,ref=m[2],m[3].strip()
                if prop==b'skill':value=out
                elif prop==b'SoundName':value=self.sounds[ref][0]
                elif prop==b'EffectTemplateName' and ref.startswith(b'<') and ref.endswith(b'>'):value=ref
                else:value=deps[(prop,ref)].final_name
                return m[1]+prop+b' '+value
            data=re.sub(rb'(^[ \t]*)(skill|EffectTemplateName|Material|SoundName)[ \t]+([^\r\n]+)',replace,block,flags=re.M)
            skills.append(data)
            entry={'kind':'skill','source':display(name),'output':out.decode(),'source_sha256':sha(block),'sha256':sha(data)}
            if name in self.skill_aliases:
                alias=data.replace(b'skill '+out,b'skill '+name,1);skills.append(alias)
                entry.update(native_alias=display(name),native_alias_sha256=sha(alias))
            manifest.append(entry)
        (PACK/'EffectFolder/cys_hj.skill').write_bytes(b'\r\n'.join(skills))
        for ref,(out,data) in self.sounds.items():
            p=PACK/'SoundFolder'/out.decode();p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data)
            manifest.append({'kind':'sound','source':display(ref),'output':out.decode(),'source_sha256':sha(data),'sha256':sha(data)})
        actors=[];links=[]
        for name,(base,additions) in self.rider_links.items():
            if not additions:continue
            extra=b''.join(b'<Skeleton skeleton="'+item.final_name+b'" animations="'+anim+b'" />\r\n' for anim,item in additions)
            data=base.replace(b'</Skeletons>',extra+b'</Skeletons>',1);actors.append(data)
            links.append({'actor':display(name),'source_sha256':sha(base),'sha256':sha(data),
                          'links':[{'animation':display(anim),'source':display(item.name),'output':item.final_name.decode()} for anim,item in additions]})
        (PACK/'ModelFolder/cys_hj_riders.obj').write_bytes(b'<AllObjects>\r\n'+b'\r\n'.join(actors)+b'\r\n</AllObjects>\r\n')
        json_write(PACK/'rider-link-manifest.json',links)
        json_write(PACK/'resource-manifest.json',manifest)

def main():
    p=argparse.ArgumentParser();p.add_argument('mode',choices=['audit','assets']);a=p.parse_args()
    imp=Import();items=imp.collect()
    if a.mode=='assets':imp.export(items)

if __name__=='__main__':
    sys.stdout.reconfigure(encoding='utf8'); main()
