"""Audit HJ mounted action -> skill -> skeleton/effect/sound, independently of export."""
import collections,json,re
from hj_appearance_data import ROOT,PACK,OUT,CY,RawTable,sha,json_write,display,C,V
from validators.v01_mesh import walk_mesh
from validators.v02_skeleton import walk_skeleton

def validate():
    manifest=json.loads((PACK/'resource-manifest.json').read_text(encoding='utf8'))
    reverse={r['output'].encode():r['source'].encode('gbk') for r in manifest}
    donor=C.IS.read_src('S3','skill')
    source={V.def_name('skill',h)[0]:donor[a:b] for h,a,b in V.script_spans(donor)[0]}
    raw=(PACK/'EffectFolder/cys_hj.skill').read_bytes()
    skills={V.def_name('skill',h)[0]:raw[a:b] for h,a,b in V.script_spans(raw)[0]}
    normal=lambda b:re.sub(rb'\s+',b' ',b).strip()
    entries={r['output'].encode():r for r in manifest if r['kind']=='skill'}
    aliases={r['native_alias'].encode('gbk'):r for r in entries.values() if r.get('native_alias')}
    assert set(skills)==set(entries)|set(aliases)
    base=V.DataRoot(str(CY))
    base_skill_names={V.def_name('skill',h)[0] for h,_,_ in V.script_spans(base.script('skill'))[0]}
    assert not set(aliases)&base_skill_names, 'native aliases would override CY skills'
    for name,block in skills.items():
        row=entries.get(name,aliases.get(name));original=source[row['source'].encode('gbk')]
        assert sha(block)==row['native_alias_sha256' if name in aliases else 'sha256'] and sha(original)==row['source_sha256']
        restored=re.sub(rb'cys_hj_[0-9a-f]{16}(?:\.wav)?',lambda m:reverse[m[0]],block)
        assert normal(restored)==normal(original),('changed authored skill properties',row['source'])
    for row in manifest:
        if row['kind']=='sound':assert sha((PACK/'SoundFolder'/row['output']).read_bytes())==row['source_sha256']==row['sha256']
    t=lambda n:RawTable(PACK/'ConfigFolder'/(n+'.txt'))
    ext=t('Exterior_Ride');mounts=t('CharMount').byid;models=t('CharModelEx').byid
    lines=t('ActionSet/ActionSetLine').byid;kv=t('ActionSet/ActionSetKV').byid
    sets=collections.defaultdict(dict)
    for r in t('ActionSet/ActionSet').rows:sets[r[1]][r[2]]=r[3]
    objraw=(PACK/'ModelFolder/cys_hj.obj').read_bytes()
    objs={n:objraw[a:b] for n,a,b in V.obj_spans(objraw)}
    animations={n:re.search(rb'^\s*Animation\s+([^\r\n]+)',b,re.M)[1].strip() for n,b in skills.items()}
    errors=[];count=0;mount_count=0
    for e in ext.rows:
        if e[0]<2000:continue
        mount_count+=1;model=models[mounts[e[10]][3]];body=objs[model[1]];available=set()
        for entity in V.tags(body,b'Entity'):
            sk=walk_mesh((PACK/'ModelFolder'/entity[b'file'].decode()).read_bytes())['skel']
            if sk:available.update(n for n,_ in walk_skeleton((PACK/'ModelFolder'/sk.decode()).read_bytes())['anims'])
        for link in V.tags(body,b'Skeleton'):available.update(link.get(b'animations',b'').split())
        for action in (0,1,2,3,4,9,12,922,923,924,925,926,927,928,929):
            if action not in sets[model[-1]]:continue
            name=kv[lines[sets[model[-1]][action]][14]][1]
            if name in (b'',b'-1',b'NULL',b'null',b'none',b'None'):continue
            count+=1
            if animations.get(name,name) not in available:
                errors.append({'exterior':e[0],'action':action,'name':display(name)})
    # CysRiderActionSet chooses sex by the original action-file stem.
    files=t('ActionSetFile').byid;sex_rows=0
    for r in mounts.values():
        if r[0]<2000:continue
        for col,prefix in ((6,'女主角'),(7,'男主角')):
            if r[col]<0:continue
            assert (files[r[col]][1].startswith(prefix.encode('gbk')) or
                    (r[6]==r[7] and files[r[col]][1].startswith('主角_'.encode('gbk')))),(r[0],col,files[r[col]][1])
            sex_rows+=1
    raw=(PACK/'ModelFolder/cys_hj_riders.obj').read_bytes()
    riders={n:raw[a:b] for n,a,b in V.obj_spans(raw)}
    base=V.DataRoot(str(CY));rider_links=json.loads((PACK/'rider-link-manifest.json').read_text(encoding='utf8'))
    for record in rider_links:
        actor=record['actor'].encode('gbk');block=riders[actor];restored=block
        assert sha(block)==record['sha256']
        for link in record['links']:
            animation=link['animation'].encode('gbk');skeleton=link['output'].encode()
            tag=b'<Skeleton skeleton="'+skeleton+b'" animations="'+animation+b'" />\r\n'
            assert restored.count(tag)==1;restored=restored.replace(tag,b'',1)
            info=walk_skeleton((PACK/'ModelFolder'/link['output']).read_bytes())
            assert animation in {n for n,_ in info['anims']},link
        assert restored==base.object_block(actor) and sha(restored)==record['source_sha256']
    # Check both seats, both sexes, world and preview character actors.
    raw=base.script('skill');base_skills={}
    for h,a,b in V.script_spans(raw)[0]:
        animation=re.search(rb'^\s*Animation\s+([^\r\n]+)',raw[a:b],re.M)
        if animation:base_skills[V.def_name('skill',h)[0]]=animation[1].strip()
    # Head/back idle strings are consumed directly by native ornament code,
    # including the two original-name aliases required by the gourd ornaments.
    catalog=json.loads((ROOT/'Registry/hj-appearance-catalog.json').read_text(encoding='utf8'))
    ornament_actions=0
    for cat in ('5','6'):
        for row in catalog['categories'][cat]:
            for sex,obj in enumerate(row['obj']):
                body=objs[obj.encode()];available=set()
                for entity in V.tags(body,b'Entity'):
                    sk=walk_mesh((PACK/'ModelFolder'/entity[b'file'].decode()).read_bytes())['skel']
                    if sk:available.update(n for n,_ in walk_skeleton((PACK/'ModelFolder'/sk.decode()).read_bytes())['anims'])
                for link in V.tags(body,b'Skeleton'):available.update(link.get(b'animations',b'').split())
                for text in row['idle']:
                    name=text.encode('gbk')
                    if not name or name==b'-1':continue
                    ornament_actions+=1
                    if animations.get(name,base_skills.get(name,name)) not in available:
                        errors.append({'ornament':row['id'],'sex':sex,'name':text})
    rider_actions=0
    for sex,cols in [('女',(6,9)),('男',(7,10))]:
        for suffix in ('','_iv'):
            actor=(sex+'主角'+suffix+'.obj').encode('gbk')
            body=riders.get(actor,base.object_block(actor))
            available={n for link in V.tags(body,b'Skeleton') for n in link.get(b'animations',b'').split()}
            for mount in mounts.values():
                if mount[0]<2000:continue
                for col in cols:
                    for action in (0,1,2,3,4,9,12,922,923,924,925,926,927,928,929):
                        if mount[col]<0 or action not in sets[mount[col]]:continue
                        name=kv[lines[sets[mount[col]][action]][14]][1]
                        if not name or name==b'-1':continue
                        rider_actions+=1;animation=animations.get(name,base_skills.get(name,name))
                        if animation not in available:errors.append({'rider':display(actor),'mount':mount[0],'action':action,'name':display(name)})
    report={'passed':not errors,'mounts':mount_count,'actions':count,'skills':len(entries),'native_skill_aliases':len(aliases),'ornament_actions':ornament_actions,'sex_seats':sex_rows,
            'rider_actors':len(riders),'rider_actions':rider_actions,'errors':errors}
    json_write(OUT/'mount-animation-validation.json',report)
    assert not errors,errors[:10]
    print('PASS mounted action/resource closure',report)
    return report

if __name__=='__main__':validate()
