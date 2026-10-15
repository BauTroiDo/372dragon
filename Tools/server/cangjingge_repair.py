"""Restore the GL Cangjingge monster family into an isolated CY ID range.

Only plan writes by default. Server apply requires the private Game stopped.
Canonical/client_GL are read-only; the client DBC is a candidate overlay.
"""
from pathlib import Path
import argparse,datetime,hashlib,importlib.util,json,re,shutil,struct,subprocess,sys
from cs3b_menpai import read_table,write_table
from cs3c_tables import COLMAP
from inventory_integrity import function
ROOT=Path(__file__).resolve().parents[2]
LIVE=Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913')
LOG=ROOT/'Build/Logs/2026-09-29-cangjingge'
SCRIPT='Game_2/Script/scripts/obj/DynamicNPC/'
RELS=['configs/MonsterAttrExTable.txt',SCRIPT+'bg_CangJingGe.lua',SCRIPT+'FB_cangjinge_FB.lua']
IDS=range(13565,13601);OFFSET=100000
spec=importlib.util.spec_from_file_location('npc_rows',ROOT/'Tools/reapply/npcdata/80-monsterattr-rows.py')
dbc=importlib.util.module_from_spec(spec);spec.loader.exec_module(dbc)
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def replace(s,a,b,count=1):
    assert s.count(a)==count,(a,s.count(a));return s.replace(a,b)
def baseline(rel):
    p=LOG/'baseline'/rel
    if not p.exists():p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(LIVE/rel,p)
    return p
def patch_bg(s):
    s=replace(s,'local class = require "class"','local skynet = require "skynet"\nlocal class = require "class"')
    s=replace(s,'        self:CurSceneHaveMonster(MosDataID)',
        '        self:CurSceneHaveMonster(MosDataID, self:LuaFnGetNpcIntParameter(MonsterId, 3))')
    s=replace(s,'    for _, BossData in pairs(self.g_BossData) do','    for slot, BossData in ipairs(self.g_BossData) do')
    s=replace(s,'\t\tself:LuaFnSetNpcIntParameter(MonsterID, 2, actId + 1)',
        '\t\tself:LuaFnSetNpcIntParameter(MonsterID, 2, actId + 1)\n            self:LuaFnSetNpcIntParameter(MonsterID, 3, slot)')
    s=function(s,'bg_CangJingGe:CurSceneHaveMonster',change=lambda b:'''function bg_CangJingGe:CurSceneHaveMonster(DataID, slot)
    -- Persist the spawn slot on the NPC: survivors must not consume another
    -- position's slot when one monk has entered a party's copy scene.
    local Data = slot and self.g_BossData[slot]
    if Data and DataID == Data["ID"] then Data["NeedCreate"] = 0 end
end''')
    needle='\t\tself:LuaFnSetNpcIntParameter(MonsterID, 1, sceneId)'
    s=replace(s,needle,'''            if not MonsterID or MonsterID <= 0 then
                skynet.loge("CYS Cangjingge: failed to create entry NPC", BossData["ID"], sceneId)
                return
            end
'''+needle)
    return s
def patch_fb(s):
    s=replace(s,'local gbk = require "wire_charset"','local skynet = require "skynet"\nlocal gbk = require "wire_charset"')
    s=replace(s,'    self:MakeCopyScene(selfId, targetId)\n    self:LuaFnDeleteMonster(targetId)',
        '    if self:MakeCopyScene(selfId, targetId) then\n        self:LuaFnDeleteMonster(targetId)\n    end')
    # Wire attribute writers require integer levels; preserve the weighted mean rule.
    s=replace(s,'    config.params[8] = mylevel','    config.params[8] = math.floor(mylevel)')
    s=function(s,'FB_cangjinge_FB:MakeCopyScene',change=lambda b:replace(b,'    self:DispatchMissionTips(selfId)',
        '    self:DispatchMissionTips(selfId)\n    return bRetSceneID > 0'))
    s=function(s,'FB_cangjinge_FB:OnCopySceneTimer',change=lambda b:replace(
        replace(b,'        self:SetUnitCampID(nNpcId, 100)','        if not nNpcId or nNpcId <= 0 then self:CysAbortSpawn(); return end\n        self:SetUnitCampID(nNpcId, 100)'),
        '        self:SetUnitCampID(nNpcId, 101)','        if not nNpcId or nNpcId <= 0 then self:CysAbortSpawn(); return end\n        self:SetUnitCampID(nNpcId, 101)'))
    # The two directions must use the same level family as the party, not a fixed level-80 row.
    s=replace(s,'self:LuaFnCreateMonster(13579, 23, 47, 9, -1, -1)',
        'self:CreateNpc(13574, 23, 47, 9, -1, -1, 227766)')
    s=replace(s,'self:LuaFnCreateMonster(13579, 103, 48, 9, -1, -1)',
        'self:CreateNpc(13574, 103, 48, 9, -1, -1, 227766)')
    for var in ('nMonsterIda','nMonsterIdb'):
        s=replace(s,f'        self:SetUnitCampID({var}, 101)',
            f'        if not {var} or {var} <= 0 then self:CysAbortSpawn(); return end\n        self:SetUnitCampID({var}, 101)')
    s=function(s,'FB_cangjinge_FB:CreateNpc',change=lambda b:replace(b,
        '    self:SetLevel(nMonsterId, PlayerLevel)',
        '    if not nMonsterId or nMonsterId <= 0 then self:CysAbortSpawn(); return -1 end\n    self:SetLevel(nMonsterId, math.floor(PlayerLevel))'))
    s=function(s,'FB_cangjinge_FB:OnDie',change=lambda b:replace(b,
        '    self:LuaFnSetCopySceneData_Param(2, (self.g_CloseTime - 20))',
        '    if objId ~= self:LuaFnGetCopySceneData_Param(13) then return end\n    self:LuaFnSetCopySceneData_Param(2, (self.g_CloseTime - 20))'))
    # An infrastructure failure must not turn into a successful timed defense.
    s=replace(s,'function FB_cangjinge_FB:OnCopySceneTimer(nowTime)',
        '''function FB_cangjinge_FB:CysAbortSpawn()
    if self:LuaFnGetCopySceneData_Param(21) == -1 then return end
    self:LuaFnSetCopySceneData_Param(21, -1)
    skynet.loge("CYS Cangjingge: instance monster creation failed", self:get_scene_id())
    self:TipAllHuman("Không thể tạo quái phụ bản. Đội được đưa về vị trí cũ; hãy báo GM kiểm tra.")
    local ids = {}
    for i = 1, self:LuaFnGetCopyScene_HumanCount() do
        ids[#ids+1] = self:LuaFnGetCopyScene_HumanObjId(i)
    end
    for _, id in ipairs(ids) do self:KickOut(id) end
end

function FB_cangjinge_FB:OnCopySceneTimer(nowTime)
    if self:LuaFnGetCopySceneData_Param(21) == -1 then return end''')
    return s
def plan():
    LOG.mkdir(exist_ok=True)
    previous=LOG/'manifest.json'
    if previous.exists():
        archive=LOG/'manifests';archive.mkdir(exist_ok=True)
        target=archive/(sha(previous)+'.json')
        if not target.exists():shutil.copy2(previous,target)
    server=read_table(baseline(RELS[0]));gl=read_table(LIVE/'configs/cys_gl_only/MonsterAttrExTable.txt')
    donors={int(r[0]):r for r in gl['rows'] if int(r[0]) in IDS};assert len(donors)==36
    assert server['types']==gl['types'] and server['names']==gl['names']
    client_path=ROOT/'Assets/CanonicalCY/Data/ConfigFolder/MonsterAttrExTable.txt'
    t=dbc.dbc_read(client_path);original={dbc.S(r[0]):r[:] for r in t['rows']};assert t['nF']==73
    server_ids={int(r[0]) for r in server['rows']}
    newids={i+OFFSET for i in IDS};assert not newids.intersection(server_ids|set(original))
    # Verify model identity by asset name and scale, not by coincident numeric ID.
    sys.path.insert(0,str(ROOT/'Tools/game'));from dbc_inventory import Table
    models={int(r[0]):r for r in Table(ROOT/'Assets/CanonicalCY/Data/ConfigFolder/CharModelEx.txt').rows}
    oldmodels={int(r[0]):r for r in Table(ROOT.parent/'client_GL/Data/ConfigFolder/CharModelEx.txt').rows}
    pool=t['pool'];mapping=[]
    for i in IDS:
        row=donors[i][:];mid=int(row[44]);a=oldmodels[mid];b=models[mid]
        assert a[1]==b[1] and a[2:6]==b[3:7],(mid,a,b)
        row[0]=str(i+OFFSET).encode('ascii');server['rows'].append(row)
        # CY-only fields come from its native traveling monk. All shared fields
        # use the independently documented GL<->CY column map, including model.
        cells=original[549][:]
        for glc,cyc in COLMAP['MonsterAttrExTable.txt'].items():
            raw=row[glc];typ=t['types'][cyc]
            if typ==2:
                value=len(pool);pool+=raw+b'\0'
            elif typ==1:value=struct.unpack('<I',struct.pack('<f',float(raw)))[0]
            elif typ==0:value=dbc.U(int(raw))
            else:value=int(raw)
            cells[cyc]=value
        t['rows'].append(cells)
        mapping.append(dict(source=i,target=i+OFFSET,model=mid,asset=a[1],name=row[1].decode('gbk')))
    t['pool']=pool;t['rows'].sort(key=lambda r:dbc.S(r[0]))
    server['rows'].sort(key=lambda r:int(r[0]))
    dest=LOG/'server'/RELS[0];dest.parent.mkdir(parents=True,exist_ok=True)
    write_table(str(dest),server['types'],server['names'],server['rows'],server['eol'])
    dbc_out=LOG/'client/MonsterAttrExTable.txt';dbc_out.parent.mkdir(exist_ok=True)
    dbc.dbc_write(str(dbc_out),t)
    actual=dbc.dbc_read(dbc_out);assert actual['pool'].startswith(dbc.dbc_read(client_path)['pool'])
    assert all(original[dbc.S(r[0])]==r for r in actual['rows'] if dbc.S(r[0]) in original)
    for rel,patch in zip(RELS[1:],(patch_bg,patch_fb)):
        raw=patch(baseline(rel).read_text(encoding='utf8'))
        raw=re.sub(r'\b(135[6-9]\d|13600)\b',lambda m:str(int(m[0])+OFFSET) if int(m[0]) in IDS else m[0],raw)
        p=LOG/'server'/rel;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(raw,encoding='utf8',newline='\n')
    rows=[dict(path=r,before=sha(baseline(r)),after=sha(LOG/'server'/r)) for r in RELS]
    manifest=dict(server=rows,client=dict(source=sha(client_path),after=sha(dbc_out)),mapping=mapping)
    (LOG/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf8')
    reg=ROOT/'Registry/import/cangjingge-monsters-20260929.json'
    reg.write_text(json.dumps(dict(source='GL quarantined MonsterAttrExTable; assets verified against native CY',reserved_offset=OFFSET,rows=mapping),ensure_ascii=False,indent=2),encoding='utf8')
    print('Planned 36 monsters; existing client/server rows preserved; 2 event scripts repaired')
def apply():
    m=json.loads((LOG/'manifest.json').read_text(encoding='utf8'))
    s=json.loads(subprocess.check_output(['wsl','-d','TLBB','-u','root','--','python3',
        '/mnt/c/TLBB/085/CY-Source/Tools/server/provision_test_wsl.py','status']))
    assert not next(x for x in s['services'] if x['name']=='Game')['running']
    deployed={}
    if (LOG/'applied.json').exists():
        prior=json.loads((LOG/'applied.json').read_text())['manifest']
        p=LOG/'manifests'/(prior+'.json');assert p.exists() and sha(p)==prior
        deployed={r['path']:r['after'] for r in json.loads(p.read_text(encoding='utf8'))['server']}
    for r in m['server']:
        assert sha(LIVE/r['path'])==deployed.get(r['path'],r['before']),r['path']
        assert sha(LOG/'server'/r['path'])==r['after']
    backup=ROOT/'Build/backups/cangjingge'/datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
    for r in m['server']:
        p=backup/r['path'];p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(LIVE/r['path'],p)
        shutil.copy2(LOG/'server'/r['path'],LIVE/r['path']);assert sha(LIVE/r['path'])==r['after']
    (LOG/'applied.json').write_text(json.dumps(dict(backup=str(backup),manifest=sha(LOG/'manifest.json')),indent=2))
    print('Applied private server only; backup',backup)
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('mode',choices=['plan','apply']);a=p.parse_args()
    plan() if a.mode=='plan' else apply()
