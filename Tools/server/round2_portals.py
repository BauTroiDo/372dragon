"""Recover ordinary walking portals from CY ScenePosDefineEx; keep unrelated event areas."""
from pathlib import Path
import argparse,configparser,io,json,math,re,sys,hashlib,datetime,subprocess
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'game'))
from dbc_inventory import Table
from cs3a_scene import NavMesh
R=Path('/home/ubuntu/cys-test-20260913')
C=Path('/mnt/c/TLBB/085/CY-Source/Assets/CanonicalCY/Data')
ID=990024
def ini(raw):
    text=raw.decode('gbk');p=configparser.ConfigParser(strict=False,interpolation=None,inline_comment_prefixes=(';',))
    p.read_string(text);return p
def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--out',type=Path,required=True);p.add_argument('--apply',action='store_true');a=p.parse_args()
    info=ini((R/'configs/SceneInfo.ini').read_bytes());scenes={}
    for s in info.sections():
        if re.fullmatch('scene[0-9]+',s) and info.getint(s,'active',fallback=0)==1 and info.getint(s,'type',fallback=0)==0:
            scenes[int(s[5:])]={'file':info.get(s,'file'),'client':info.getint(s,'clientres')}
    source=Table(C/'ConfigFolder/ScenePosDefineEx.txt');routes={};problems=[];navs={};areas={};changes={};report=[]
    originals=Table(Path('/mnt/c/TLBB/085/Tools/DATA NEW/DataCY31-08-26/Config/SceneDefineEx.txt'))
    original_files={int(r[0]):Path(str(r[4])).stem.casefold() for r in originals.rows}
    mapping={}
    for cy,name in original_files.items():
        matches=[sid for sid,s in scenes.items() if Path(s['file']).stem.casefold()==name]
        if matches:
            # ScenePos belongs to the original CY resource IDs, not server IDs.
            # The base scene precedes its duplicate population shards.
            mapping[cy]=min(matches)
    excluded=[]
    registered={int(x) for x in re.findall(r'\[(\d+)\]\s*=',(R/'Game_2/Script/scripts/scripts.lua').read_text())}
    def nav(sid):
        name=Path(scenes[sid]['file']).stem
        if name not in navs:
            config=ini((R/'Game_2/Scene'/scenes[sid]['file']).read_bytes())
            path=R/'Game_2/Scene'/config.get('System','navmapname',fallback=name+'.path')
            if not path.exists():return None
            navs[name]=NavMesh(str(path))
            # Some GL v1000 headers pack the grid width in the high half of the
            # cell word. The already decoded grid and triangle topology stay
            # intact. Validate the low half against world extents before use.
            n=navs[name]
            if n.version==0x1000 and n.cell>65535:
                cell=n.cell&0xffff
                assert 0<cell<=64 and n.nx*cell>=n.bbox[2] and n.nz*cell>=n.bbox[3],name
                n.cell=cell
        return navs[name]
    for row in source.rows:
        if len(row)<10 or int(row[9])!=0:continue
        cy_src,cy_dst=int(row[2]),int(row[6])
        if cy_src not in mapping or cy_dst not in mapping:
            excluded.append({'id':row[0],'source_cy':cy_src,'target_cy':cy_dst,'reason':'scene not deployed as an active ordinary scene'})
            continue
        src,dst=mapping[cy_src],mapping[cy_dst]
        x,z,tx,tz=map(float,[row[3],row[4],row[7],row[8]])
        dn=nav(dst);sn=nav(src)
        accessible=sn.nearest_walkable(x,z,None,3.5) if sn else None
        arrival=dn.nearest_walkable(tx,tz,None,12) if dn else None
        if not dn or not sn or not arrival or not accessible:
            problems.append({'id':row[0],'source':src,'target':dst,'source_pos':[x,z],'target_pos':[tx,tz],
                             'source_walkable':bool(sn and sn.walkable(x,z)),'target_walkable':bool(dn and dn.walkable(tx,tz))})
            continue
        # The CY map table names the gate, not a safe spawn beyond that gate.
        # Arrive outside every exit circle to prevent immediate reverse transfer.
        exits=[(float(r[3]),float(r[4])) for r in source.rows if int(r[2])==cy_dst and int(r[9])==0]
        region=dn.locate(arrival[0],arrival[1])[2]
        candidates=[]
        for radius in [0,6,7,8,9,10,11,12]:
            for step in range(72):
                px=round(arrival[0]+radius*math.cos(step*math.pi/36),2);pz=round(arrival[1]+radius*math.sin(step*math.pi/36),2)
                if dn.walkable(px,pz,region) and all(math.hypot(px-ex,pz-ez)>=6 for ex,ez in exits):
                    candidates.append((math.hypot(px-tx,pz-tz),px,pz))
            if candidates:break
        if not candidates:
            problems.append({'source':src,'target':dst,'reason':'no safe arrival outside gates'});continue
        _,tx,tz=min(candidates)
        # Every active shard using the same scene file gets the same exits.
        peers=[sid for sid,s in scenes.items() if s['file']==scenes[src]['file']]
        entry=(x,z,dst,tx,tz)
        scn=ini((R/'Game_2/Scene'/scenes[src]['file']).read_bytes())
        event=scn.get('System','eventfile',fallback='').strip()
        if not event or event=='-1':
            problems.append({'source':src,'reason':'no event file'});continue
        rel='Game_2/Scene/'+event
        if rel not in areas:areas[rel]=ini((R/rel).read_bytes())
        ai=areas[rel];found=None
        for section in ai.sections():
            if not re.fullmatch('area[0-9]+',section):continue
            ax=ai.getfloat(section,'x') if ai.has_option(section,'x') else (ai.getfloat(section,'left')+ai.getfloat(section,'right'))/2
            az=ai.getfloat(section,'z') if ai.has_option(section,'z') else (ai.getfloat(section,'top')+ai.getfloat(section,'bottom'))/2
            if math.hypot(ax-x,az-z)<7:found=section;break
        if found is None:
            n=ai.getint('area_info','area_count');found='area'+str(n)
            ai.add_section(found);ai.set('area_info','area_count',str(n+1))
        # Only portal-sized matching event areas are replaced; never delete a quest area.
        if ai.has_option(found,'left') and (ai.getfloat(found,'right')-ai.getfloat(found,'left')>30 or ai.getfloat(found,'bottom')-ai.getfloat(found,'top')>30):
            problems.append({'source':src,'reason':'matching large event area','section':found});continue
        old_script=ai.getint(found,'script_id',fallback=-1)
        if old_script not in registered:old_script=-1
        # Existing scripts retain quest/level/population conditions. Only a
        # disabled or missing ordinary gate uses the generic dispatcher.
        for key,value in {'guid':0,'script_id':old_script if old_script>=0 else ID,'left':x-4,'right':x+4,'top':z-4,'bottom':z+4}.items():ai.set(found,key,str(value))
        if ai.has_option(found,'x'):
            for key,value in {'x':x,'z':z,'radious':4}.items():ai.set(found,key,str(value))
        for sid in peers:
            if entry not in routes.setdefault(sid,[]):routes[sid].append(entry)
        report.append({'source':src,'target':dst,'source_cy':cy_src,'target_cy':cy_dst,'pos':[x,z],'arrival':[tx,tz],'script':old_script if old_script>=0 else ID,'area':rel+':'+found})
    for rel,cfg in areas.items():
        out=io.StringIO();cfg.write(out,space_around_delimiters=False);changes[rel]=out.getvalue().encode('gbk')
    script=['local class=require "class"','local base=require "script_base"','local P=class("cys_walk_portals",base)','local routes={']
    for sid,rows in sorted(routes.items()):script.append('[%d]={%s},'%(sid,','.join('{%g,%g,%d,%g,%g}'%r for r in rows)))
    script+=['}','local files={']
    for sid,s in sorted(scenes.items()):script.append('[%d]="%s",'%(sid,s['file']))
    script+=['}', '''function P.resolve(sceneId,x,z,target,tx,tz)
    for _,r in ipairs(routes[sceneId] or {}) do
        if files[target]==files[r[3]] and (x-r[1])^2+(z-r[2])^2<16 then
            return r[4],r[5]
        end
    end
    return tx,tz
end
function P:on_enter_area(scene,obj)
    if obj:get_obj_type()~="human" or not obj:is_alive_in_deed() then return end
    local pos=obj:get_world_pos()
    for _,r in ipairs(routes[scene:get_id()] or {}) do
        if (pos.x-r[1])^2+(pos.y-r[2])^2<16 then
            self:CallScriptFunction(400900,"TransferFunc",obj:get_obj_id(),r[3],r[4],r[5],r[3]==6 and 1 or nil)
            return
        end
    end
end
return P''']
    changes['Game_2/Script/scripts/event/chuansong/cys_walk_portals.lua']=('\n'.join(script)+'\n').encode()
    rel='Game_2/Script/scripts/event/team.lua';team=(R/rel).read_text(encoding='utf8')
    signature='function team:TransferFunc(selfId, newSceneId, posX, posY, minLevel, maxLevel)'
    patch='''
    -- CYS-ROUND2: retain the gate script's conditions; correct only a matching
    -- walking gate's CY arrival. NPC transfers away from a gate are unchanged.
    local gateX,gateZ=self:GetWorldPos(selfId)
    posX,posY=require("scripts.event.chuansong.cys_walk_portals").resolve(
        self:get_scene_id(),gateX,gateZ,newSceneId,posX,posY)
'''
    if '-- CYS-ROUND2: retain' not in team:
        assert team.count(signature)==1;team=team.replace(signature,signature+patch)
    changes[rel]=team.encode()
    rel='Game_2/Script/scripts/scripts.lua';raw=(R/rel).read_text(encoding='utf8')
    entry=f'    [{ID}] = "scripts.event.chuansong.cys_walk_portals",'
    if re.search(r'\['+str(ID)+r'\]',raw):assert entry in raw,'script ID collision'
    else:
        m=re.search(r'^\s*\[\d+\]\s*=',raw,re.M);assert m;raw=raw[:m.start()]+entry+'\n'+raw[m.start():]
    changes[rel]=raw.encode()
    a.out.mkdir(parents=True,exist_ok=True)
    for rel,data in changes.items():
        dst=a.out/rel;dst.parent.mkdir(parents=True,exist_ok=True);dst.write_bytes(data)
        if rel.endswith('.lua'):subprocess.run(['luac','-p',str(dst)],check=True)
    tests=['package.preload.class=function()return function()return {} end end','package.preload.script_base=function()return {} end',
           'local P=dofile('+json.dumps(str(a.out/'Game_2/Script/scripts/event/chuansong/cys_walk_portals.lua'))+')']
    for row in report:
        src,dst=row['source'],row['target'];x,z=row['pos'];tx,tz=row['arrival']
        tests.append(f'do local x,z=P.resolve({src},{x},{z},{dst},-999,-999);assert(x=={tx} and z=={tz}) end')
        tests.append(f'do local x,z=P.resolve({src},{x+20},{z+20},{dst},-999,-999);assert(x==-999 and z==-999) end')
    tests.append('print("PASS portal arrivals and unrelated transfers: '+str(len(report)*2)+' checks")')
    test=a.out/'test_portals.lua';test.write_text('\n'.join(tests));subprocess.run(['lua',str(test)],check=True)
    record={'routes':report,'unresolved':problems,'excluded':excluded,'mapping':mapping,'files':list(changes),'active_scenes':len(scenes)}
    (a.out/'report.json').write_text(json.dumps(record,ensure_ascii=False,indent=2),encoding='utf8')
    print('PLAN',len(report),'portals;',len(problems),'unresolved;',len(changes),'files')
    if a.apply:
        from give_item import connected
        assert not connected()
        assert not problems,'resolve all coordinate issues before applying'
        backup=R/'backups'/('round2-portals-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S'))
        for rel,data in changes.items():
            dst=R/rel
            if dst.exists():
                saved=backup/rel;saved.parent.mkdir(parents=True,exist_ok=True);saved.write_bytes(dst.read_bytes())
            dst.parent.mkdir(parents=True,exist_ok=True);dst.write_bytes(data)
        print('APPLIED backup',backup)
if __name__=='__main__':main()
