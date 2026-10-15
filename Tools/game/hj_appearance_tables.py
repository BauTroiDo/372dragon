"""Map HJ appearance rows to CY, preserving all current Play table bytes.

Namespaced models/visuals are deliberately unrelated to donor numeric IDs.
Run after hj_appearance_data.py assets. This writes a candidate pack only.
"""
from pathlib import Path
import collections, json, re, sys, xml.etree.ElementTree as ET
from hj_appearance_data import ROOT,HJ,PLAY,CY,OUT,PACK,RawTable,sha,display,json_write
from validators import common as V, v01_mesh, v02_skeleton

def live(name):
    rel=Path('ConfigFolder')/(name+'.txt')
    saved=PACK/'baseline'/rel
    if saved.exists():return saved
    return next(p for p in (PLAY/'Overlay/Post'/rel,PLAY/'Overlay/Pre'/rel,CY/rel) if p.exists())

class Tables:
    def __init__(self):
        self.hj={};self.cy={};self.added=collections.defaultdict(list)
        self.resources={(r['kind'],r['source']):r['output'].encode() for r in json.loads((PACK/'resource-manifest.json').read_text(encoding='utf8'))}
        self.audit=json.loads((OUT/'resource-audit.json').read_text(encoding='utf8'))
        self.catalog={i:[] for i in range(1,10)};self.families={i:[] for i in range(1,10)}
        self.server=collections.defaultdict(list);self.icons=set();self.maps={};self.excluded=[]
        self.icon_index={}
        for p in (HJ/'Interface').rglob('*.imageset.xml'):
            tree=ET.fromstring(p.read_bytes())
            for e in tree.findall('Image'):
                self.icon_index.setdefault(e.get('Name'),(p,tree))

    def source(self,name):
        if name not in self.hj:self.hj[name]=RawTable(HJ/'Config'/(name+'.txt'))
        return self.hj[name]
    def base(self,name):
        if name not in self.cy:
            self.cy[name]=RawTable(live(name))
            saved=PACK/'baseline/ConfigFolder'/(name+'.txt')
            if not saved.exists():saved.parent.mkdir(parents=True,exist_ok=True);saved.write_bytes(self.cy[name].raw)
        return self.cy[name]
    def resource(self,kind,b):
        if b in (b'',b'-1',b'0'):return b
        if kind=='material' and b in (b'BaseWhite',b'BaseWhiteNoLighting'):return b
        return self.resources[(kind,display(b))]
    def material(self,b):return b';'.join(self.resource('material',p) for p in b.split(b';'))
    def icon(self,b):
        if b in (b'',b'-1'):return b''
        name=b.decode('ascii')
        full=re.fullmatch(r'set:(\S+) image:(\S+)',name)
        if full:
            self.icon(full[2].encode())
            return f'set:CysHJ{full[1]} image:CysHJ{full[2]}'.encode()
        assert name in self.icon_index,('missing HJ icon',name)
        self.icons.add(name);return ('CysHJ'+name).encode()
    def emit(self,name,row):
        assert len(row)==self.base(name).nf,(name,row[0],len(row),self.base(name).nf)
        self.added[name].append(row)
    def entry(self,cat,id,name,icon,visual,native=None,**extras):
        if isinstance(name,bytes):name=[display(name)+' [HJ]']*2
        if isinstance(icon,bytes):icon=[icon.decode()]*2
        if isinstance(visual,int):visual=[visual]*2
        row=dict(id=id,native=native if native is not None else id if cat in (1,9) else 10000+id,
                 name=name,icon=icon,visual=visual,valid=[True,True],source='HJ',**extras)
        self.catalog[cat].append(row);return row
    def single(self,cat,row):self.families[cat].append(dict(row,key=row['id'],variants=[dict(row,aliases=[row['id']])]))
    def server_row(self,name,row):self.server[name].append([display(x) for x in row])

    def fashion(self):
        iv=self.source('ItemVisualChar').byid
        for fix in self.audit['repairs']:
            if fix['table']=='ItemVisualChar':iv[fix['id']][fix['column']]=fix['after'].encode('gbk')
        groups=collections.defaultdict(list)
        for r in self.source('EquipDress').rows:
            if r[2] not in iv:
                self.excluded.append({'kind':'fashion','dress':r[0],'visual':r[2],'reason':'model row absent in donor and GL'})
                continue
            groups[(r[7],r[2])].append(r)
        for vid in sorted({k[1] for k in groups}):
            r=iv[vid][:];r[0]=20000+vid
            for c in (1,12):r[c]=self.resource('mesh',r[c])
            for c in list(range(2,12))+list(range(13,23)):r[c]=self.material(r[c])
            self.emit('ItemVisualChar',r)
        equips=collections.defaultdict(list)
        for r in self.source('EquipBase').rows:
            if r[5]==16:equips[r[6]].append(r)
        cytemplate=next(r for r in self.base('EquipBase').rows if r[5]==16 and r[11]==1)
        # Dedicated unused Type 29; class/quality/type/index remain consistent
        # with the numeric item ID. Cosmetic attributes follow the existing
        # plain wardrobe template; no HJ combat statistics are imported.
        for index,((family,vid),dresses) in enumerate(sorted(groups.items())):
            item=10129000+index
            assert item not in self.base('EquipBase').byid
            dr=min(dresses,key=lambda r:(r[6],r[0]))
            originals=equips.get(dr[0]) or [e for d in dresses for e in equips.get(d[0],[])]
            if not originals:
                self.excluded.append({'kind':'fashion-family','id':family,'reason':'No donor equipment row names this appearance'})
                continue
            src=originals[0];name=src[10];icon=self.icon(src[21]); visual=20000+dr[0]
            cr=cytemplate[:];cr[:7]=[item,1,1,29,item%1000,16,visual]
            cr[10]=(display(name)+' [HJ]').encode('utf8');cr[12]=b'-1';cr[13]=b'HJ wardrobe';cr[18]=icon
            self.emit('EquipBase',cr)
            # Server table uses the HJ schema (101 columns). Preserve its own
            # plain fashion template and replace only identity/appearance.
            self.maps.setdefault('fashion',[]).append({'item':item,'source_item':src[0],'template':cytemplate[0],'dress':dr[0],'visual':visual,'name':display(name),'icon':icon.decode()})
            row=self.entry(1,item,name,icon,visual,group=100000000+family*1000+vid,base=20000+family,model=20000+vid,color=dr[6],colorName='Mặc định')
            variants=[];dyes={}
            for d in sorted(dresses,key=lambda d:(d[6],d[0])):
                v=20000+d[0];out=[v,d[1],20000+d[2],d[3],d[4],d[6],20000+d[7]]
                self.emit('EquipDress',out)
                # Server needs visual -> model and colour for persisted items.
                self.server_row('EquipDress',[v,d[1],20000+d[2],d[3],d[4],d[5],d[6],20000+d[7]])
                valid=[iv[vid][c] not in (b'',b'-1') for c in (1,12)];dyes[v]=valid
                variants.append(dict(row,visual=[v]*2,valid=valid,color=d[6],colorName='Mặc định' if d[6]==1 else 'Màu '+str(d[6]-1),aliases=[item]))
            row['dyes']=dyes;row['valid']=variants[0]['valid']
            self.families[1].append(dict(row,key=row['group'],variants=variants))
        for r in self.source('SpecialDressEffect').rows:
            if not any(d[0]==20000+r[0] for d in self.added['EquipDress']):continue
            out=r[:];out[0]+=20000
            for c in (1,2):
                parts=[]
                for part in r[c].split(b','):
                    if not part:continue
                    name,sep,slot=part.partition(b':');parts.append(self.resource('effect',name)+sep+slot)
                out[c]=b','.join(parts)+(b',' if parts else b'')
            self.emit('SpecialDressEffect',out)
        by_dress={r['dress']:r['item'] for r in self.maps['fashion']}
        for r in self.source('SpecialEquipVisiblRule').rows:
            original=self.source('EquipBase').byid.get(r[1])
            item=by_dress.get(original[6]) if original else None
            if item:
                out=r[:];out[0]=1000+r[0];out[1]=item;self.emit('SpecialEquipVisiblRule',out)

    def faces(self):
        for cat,ext,geo in [(2,'Exterior_Face','CharFaceGeo'),(3,'Exterior_Hair','CharHairGeo'),(4,'Exterior_Head','CharHead')]:
            used={v for r in self.source(ext).rows for v in r[1:3] if v>=0}
            geos=self.source(geo).byid
            for gid in sorted(used):
                r=geos[gid]
                if cat==2:
                    mesh=self.resource('mesh',r[2]);out=[20000+gid,r[1],mesh,mesh,r[3].decode('gbk').encode('utf8'),*r[5:10],11000+r[10] if r[10]>=0 else -1,-1]
                    out[8]=self.icon(r[8])
                elif cat==3:
                    mesh=self.resource('mesh',r[2]);second=self.resource('mesh',r[3])
                    out=[20000+gid,r[1],mesh,mesh,second,second,r[4].decode('gbk').encode('utf8'),*r[7:12],11000+r[12] if r[12]>=0 else -1,-1]
                    out[10]=self.icon(r[10])
                else:
                    out=r[:];out[0]+=20000;out[2]=r[2].decode('gbk').encode('utf8');out[6]=self.icon(r[6]);out[8]+=20000
                    out[10]=20000+r[10] if r[10]>=0 else r[10]
                    portrait=self.source('CharacterFace').byid[r[8]][:];portrait[0]+=20000
                    for col in (2,5):portrait[col]=self.icon(portrait[col])
                    self.emit('CharacterFace',portrait)
                self.emit(geo,out)
                if cat in (2,3):
                    # Native beauty scripts resolve Exterior -> Geo -> cost.
                    # Server retains HJ/GL schema and does not render resources.
                    native=r[:];native[0]+=20000
                    self.server_row(geo,native)
            for r in self.source(ext).rows:
                id=1000+r[0];out=r[:6]+[1]+r[6:] # CY inserts the availability field before the acquisition ID.
                out[0]=id;out[1:3]=[20000+r[1],20000+r[2]];self.emit(ext,out)
                sr=out[:];sr[0]=10000+id;self.server_row(ext,sr)
                namecol,iconcol={2:(3,8),3:(4,10),4:(2,6)}[cat]
                pair=[geos[r[1]],geos[r[2]]]
                row=self.entry(cat,id,[display(x[namecol])+' [HJ]' for x in pair],[self.icon(x[iconcol]).decode() for x in pair],out[1:3])
                self.single(cat,row)

    def ornaments(self):
        used=set();ivs=self.source('ItemOrnamentsVisual').byid
        idle={r[2]:r[6:9] for r in self.source('ItemLocatorAction').rows if r[1]==3}
        for cat,ext in [(5,'Exterior_TS'),(6,'Exterior_BG')]:
            for r in self.source(ext).rows:
                id=1000+r[0];v=ivs[r[4]];used.add(v[0]);out=r[:];out[0]=id;out[4]+=20000;out[2]=self.icon(r[2])
                self.emit(ext,out);sr=out[:];sr[0]+=10000;self.server_row(ext,sr)
                row=self.entry(cat,id,r[1],out[2],out[4],obj=[self.resource('obj',v[c]).decode() for c in (1,3)],
                    pos=[r[12:15],r[15:18]],scale=[r[18:21],r[21:24]],bounds=r[6:12],idle=[display(x) for x in idle.get(r[4],[])])
                self.single(cat,row)
        for vid in sorted(used):
            r=ivs[vid][:];r[0]+=20000
            for c in (1,3):r[c]=self.resource('obj',r[c])
            for c in (2,4):r[c]=self.material(r[c])
            self.emit('ItemOrnamentsVisual',r)

    def selection_profiles(self):
        # Selection resolves persisted face/hair/portrait through its isolated
        # creation catalog. Keep premium HJ entries out of new-role choices,
        # while allowing exact saved IDs/resources to resolve on relogin.
        for source,target,flag in [('CharFaceGeo','CysCreateFace',7),
                                   ('CharHairGeo','CysCreateHair',9),
                                   ('CharacterFace','CysCreatePortrait',3)]:
            assert self.base(source).types==self.base(target).types,(source,target)
            for row in self.added[source]:
                out=row[:];out[flag]=0
                self.emit(target,out)

    def actions(self,sets):
        basekv=self.base('ActionSet/ActionSetKV');kv_byname={r[1]:r[0] for r in basekv.rows};kvmap={}
        for r in self.source('ActionSet/ActionSetKV').rows:
            name=self.resources.get(('skill',display(r[1])),r[1])
            if name not in kv_byname:
                id=len(kv_byname) # reset below: names can alias IDs in CY
                id=basekv.nr+len(self.added['ActionSet/ActionSetKV']);kv_byname[name]=id
                self.emit('ActionSet/ActionSetKV',[id,name])
            kvmap[r[0]]=kv_byname[name]
        hjlines=self.source('ActionSet/ActionSetLine').byid;linemap={};asbase=self.base('ActionSet/ActionSet')
        # GL/HJ shared slot 9 -> CY shared 13; sickle 8 -> CY 15.
        # New CY weapon classes use the shared rider/creature animation.
        slots=[0,1,2,3,4,5,6,7,9,9,9,9,9,9,10,8]
        for r in self.source('ActionSet/ActionSet').rows:
            if r[1] not in sets:continue
            line=r[3]
            replacement=self.mount_action_repairs.get((r[1],r[2]))
            key=(line,replacement)
            if key not in linemap:
                old=hjlines[line];id=self.base('ActionSet/ActionSetLine').nr+len(linemap);linemap[key]=id
                values=[kvmap[old[1+s]] for s in slots]
                if replacement:
                    name=self.resources.get(('skill',display(replacement)),replacement)
                    values=[kv_byname[name]]*16
                self.emit('ActionSet/ActionSetLine',[id]+values+old[-3:])
            id=asbase.nr+len(self.added['ActionSet/ActionSet'])
            self.emit('ActionSet/ActionSet',[id,10000+r[1],r[2],linemap[key]])
        for id in sorted(sets):
            # This is also the sex discriminator in CysRiderActionSet; its
            # female/male stem must remain intact. IDs are already isolated.
            if id>=0:self.emit('ActionSetFile',[10000+id,self.source('ActionSetFile').byid[id][1]])

    def mount_animation_repairs(self,model_ids):
        """Resolve donor aliases only where the authored skeleton proves a gap.

        HJ and GL share these stale aliases. Walk uses the same model's run
        action, and stationary jump uses its existing moving-jump action.
        No skeleton tracks are fabricated or modified.
        """
        raw=(PACK/'ModelFolder/cys_hj.obj').read_bytes()
        objects={n:raw[a:b] for n,a,b in V.obj_spans(raw)}
        raw=(PACK/'EffectFolder/cys_hj.skill').read_bytes()
        wrappers={V.def_name('skill',h)[0]:re.search(rb'^\s*Animation\s+([^\r\n]+)',raw[a:b],re.M)[1].strip() for h,a,b in V.script_spans(raw)[0]}
        kv=self.source('ActionSet/ActionSetKV').byid;lines=self.source('ActionSet/ActionSetLine').byid
        actions=collections.defaultdict(dict)
        for r in self.source('ActionSet/ActionSet').rows:
            actions[r[1]][r[2]]=[kv[v][1] for v in lines[r[3]][1:12]]
        changes={};evidence=[]
        for mid in sorted(model_ids):
            model=self.source('CharModelEx').byid[mid];aset=model[9]
            body=objects[self.resource('obj',model[1])];available=set()
            for e in V.tags(body,b'Entity'):
                sk=v01_mesh.walk_mesh((PACK/'ModelFolder'/e[b'file'].decode()).read_bytes())['skel']
                if sk:available.update(n for n,_ in v02_skeleton.walk_skeleton((PACK/'ModelFolder'/sk.decode()).read_bytes())['anims'])
            for e in V.tags(body,b'Skeleton'):available.update(e.get(b'animations',b'').split())
            for action,names in actions[aset].items():
                if action not in (1,3,9,922):continue
                name=names[9];wrapped=self.resources.get(('skill',display(name)),name)
                animation=wrappers.get(wrapped,name)
                if not animation or animation in available:continue
                replacement=None
                if action in (3,9):replacement=actions[aset].get({3:4,9:12}[action],[b'']*11)[9]
                elif action==1 and name=='休闲1'.encode('gbk'):replacement='休闲'.encode('gbk')
                elif action==922 and name=='飞起'.encode('gbk'):replacement='起飞'.encode('gbk')
                if not replacement:continue
                translated=self.resources.get(('skill',display(replacement)),replacement)
                assert wrappers.get(translated,replacement) in available,(mid,action,display(replacement))
                assert len(set(names))==1,(mid,action,'nonuniform creature slots')
                assert (aset,action) not in changes or changes[(aset,action)]==replacement
                changes[(aset,action)]=replacement
                evidence.append({'model':mid,'set':aset,'action':action,'before':display(name),'after':display(replacement),'evidence':'HJ skeleton animation names; HJ/GL stale action alias'})
        self.mount_action_repairs=changes
        json_write(OUT/'mount-action-repairs.json',evidence)

    def mounts(self):
        mounts=self.source('CharMount').byid;models=self.source('CharModelEx').byid
        cameras=self.source('ExteriorRideCamera').byid
        used_mounts={r[10] for r in self.source('Exterior_Ride').rows}
        sets=set();model_ids=set()
        for id in sorted(used_mounts):
            r=mounts[id];assert r[3]>=0
            model_ids.add(r[3]);sets.update(v for v in r[5:8]+r[9:11] if v>=0)
            remap=lambda n:10000+n if n>=0 else n
            out=[2000+id,r[1],r[2],20000+r[3],r[4],remap(r[5]),remap(r[6]),remap(r[7]),r[8],remap(r[9]),remap(r[10]),r[11],b'attach3',b'attach4',b'attach5',b'attach6',r[12],r[13],-1,-1,0,-1,r[14],-1]
            self.emit('CharMount',out)
            camera=cameras[id][:];camera[0]=2000+id;self.emit('ExteriorRideCamera',camera)
        for id in sorted(model_ids):
            r=models[id];obj=self.resource('obj',r[1]);sets.add(r[9])
            self.emit('CharModelEx',[20000+id,obj,obj,*r[2:6]]+[-1]*13+[10000+r[9]])
        self.mount_animation_repairs(model_ids)
        self.actions(sets)
        for r in self.source('Exterior_Ride').rows:
            id=2000+r[0];m=mounts[r[10]]
            out=self.base('Exterior_Ride').rows[0][:]
            out[:13]=r[:13];out[0]=id;out[7]=(display(r[7])+' [HJ]').encode('gbk');out[8]=self.icon(r[8]);out[10]=2000+r[10]
            # New rows get independently mapped server impacts, never donor
            # impact IDs. Client appearance fields are all in columns 0..12.
            out[13:]=[-1]*(len(out)-13);self.emit('Exterior_Ride',out)
            # GL NewExterior_Ride view mode 1 uses the mount-only camera pair.
            # These are keyed by CharMount, not CharModelEx linked IDs.
            camera=cameras[r[10]]
            row=self.entry(9,id,r[7],out[8],out[10],height=m[4],fly=m[14],camera=camera[4:6]);self.single(9,row)
            self.maps.setdefault('mounts',[]).append({'id':id,'source':r[0],'mount':out[10],'name':display(r[7]),'icon':out[8].decode(),'speed':r[11]})

    def weapons(self):
        locs=self.source('ItemVisualLocator').byid;used=set();item_rows=self.base('EquipBase').byid
        reserved=set(item_rows);alloc={}
        def itemid(typ):
            start=10100000+typ*1000
            value=next(n for n in range(start+999,start-1,-1) if n not in reserved)
            reserved.add(value);return value
        for r in self.source('Exterior_Weapon').rows:
            family=[]
            for level,v in enumerate(r[9:13],1):
                if v<0:continue
                used.add(v);leaf=1000+r[0]*10+level;typ=(r[8]%100000)//1000;item=itemid(typ)
                template=item_rows[r[8]][:];template[0]=item;template[4]=item%1000;template[6]=20000+v
                template[10]=(display(r[1])+f' [HJ {level}]').encode('utf8');template[18]=self.icon(r[2]);template[13]=r[3].decode('gbk').encode('utf8')
                self.emit('EquipBase',template)
                wr=[leaf,1,level,-1,template[10],template[18],item,b'',template[13]];self.emit('Exterior_Weapon',wr)
                row=self.entry(7,leaf,r[1],template[18],item,weaponVisual=20000+v,group=1000+r[0],groupName=display(r[1])+' [HJ]',level=level,actions=[])
                family.append(dict(row,aliases=[leaf]))
                self.server_row('Exterior_Weapon',[row['native'],r[1],template[18],r[3],r[4],r[5],r[6],r[7],item,20000+v,20000+v,20000+v,-1])
                self.maps.setdefault('weapons',[]).append({'item':item,'source_item':r[8],'visual':20000+v,'name':display(r[1])+f' [HJ {level}]','icon':template[18].decode()})
            if family:self.families[7].append(dict(family[0],key=1000+r[0],variants=family))
        # Soul appearances share these native attachment records. Keep their
        # imported resources available for the soul importer/validation too.
        for v in sorted(used):
            r=locs[v];out=[b'']*63;out[0]=20000+v
            for c in (2,5,9):out[c]=self.resource('obj',r[c])
            for c in (3,6,10):out[c]=self.material(r[c])
            for old,new in ((11,13),(13,17),(15,21),(17,25)):
                out[new]=self.resource('obj',r[old]);out[new+1]=self.material(r[old+1])
            for c in range(19,53):out[c+10]=self.resource('effect',r[c])
            self.emit('ItemVisualLocator',out)

    def export_icons(self):
        groups={}
        for name in sorted(self.icons):
            p,tree=self.icon_index[name];groups.setdefault(p,(tree,set()))[1].add(name)
        entries=[]
        for p,(tree,names) in groups.items():
            oldname=tree.get('Name');newname='CysHJ'+oldname
            filename=tree.get('Imagefile').replace('\\','/');source=HJ/'Interface'/filename
            if not source.exists():source=p.parent/Path(filename).name
            if not source.exists():source=HJ/'Material'/filename
            if not source.exists():source=next((folder/filename for folder in sorted(HJ.glob('Material*')) if (folder/filename).exists()),source)
            assert source.exists(),('missing imageset bitmap',str(p),filename)
            target='Icons/CysHJ'+Path(filename).name
            dest=PACK/'InterfaceFolder'/target;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(source.read_bytes())
            doc=ET.Element('Imageset',dict(tree.attrib,Name=newname,Imagefile=target))
            for e in tree.findall('Image'):
                if e.get('Name') in names:ET.SubElement(doc,'Image',dict(e.attrib,Name='CysHJ'+e.get('Name')))
            rel='Icons/'+newname+'.imageset.xml';path=PACK/'InterfaceFolder'/rel
            path.write_bytes(ET.tostring(doc,encoding='utf-8',xml_declaration=True));entries.append(rel)
        json_write(PACK/'icon-imagesets.json',entries)

    def run(self):
        self.fashion();self.faces();self.ornaments();self.mounts();self.weapons();self.selection_profiles();self.export_icons()
        evidence={}
        for name,added in self.added.items():
            raw=self.base(name).extend(added);dest=PACK/'ConfigFolder'/(name+'.txt');dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(raw)
            # Round trip and strict ordering prove no ID collision or damaged
            # source cell/pool. Compare original semantic byte cells as well.
            result=RawTable(dest);assert list(result.byid)==sorted(result.byid)
            for r in self.base(name).rows:assert result.byid[r[0]]==r,(name,r[0])
            evidence[name]={'baseline':sha(self.base(name).raw),'sha256':sha(raw),'added':len(added),'rows':result.nr}
        json_write(PACK/'tables-manifest.json',evidence)
        json_write(PACK/'server-rows.json',self.server)
        json_write(PACK/'mapping.json',self.maps)
        json_write(ROOT/'Registry/hj-appearance-catalog.json',{'categories':self.catalog,'families':self.families,'excluded':self.excluded})
        header=['#pragma once','// Generated from the imported HJ catalog; probe only.','namespace CysHjProbeData {','struct Row {int cat,id,visual;};','static const Row rows[] = {']
        probes=[]
        for cat,groups in self.families.items():
            for family in groups:
                for r in family['variants']:
                    if any(r['valid']):probes.append((cat,r['id'],r['visual'][0],r['visual'][1]))
        header=['#pragma once','// Generated by hj_appearance_tables.py; probe only.','namespace CysHjProbeData {','struct Row {int cat,id,visual[2];};','static const Row rows[] = {']
        header+=['{%d,%d,{%d,%d}},'%r for r in probes]
        header+=['};','}']
        (ROOT/'Src/Client/WXClient/DataPool/CysHjProbeData.h').write_text('\n'.join(header)+'\n',encoding='ascii')
        print(json.dumps({'counts':{k:len(v) for k,v in self.catalog.items()},'families':{k:len(v) for k,v in self.families.items()},'tables':evidence,'excluded':self.excluded},ensure_ascii=False))

if __name__=='__main__':
    sys.stdout.reconfigure(encoding='utf8');Tables().run()
