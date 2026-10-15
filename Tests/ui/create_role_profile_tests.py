"""Real DATA CY closure checks and controller execution with the production Lua DLL.

No Game/network/GPU is started. Lua controls and native host responses are fixtures;
runtime rendering and transport remain separate gates owned by the Game smoke.
"""
import argparse
import ctypes
import json
import io
from pathlib import Path
import shutil
import subprocess
import sys
from unittest import mock
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'Tools/data'))
import prepare_create_role_profile as profile


class Lua:
    def __init__(self, path):
        self.dll = ctypes.CDLL(str(path))
        ptr = ctypes.c_void_p
        for name in ('lua_close', 'luaopen_base', 'luaopen_table', 'luaopen_string', 'luaopen_math'):
            getattr(self.dll, name).argtypes = [ptr]
        self.dll.lua_open.restype = ptr
        self.dll.luaL_loadbuffer.argtypes = [ptr, ctypes.c_char_p, ctypes.c_size_t, ctypes.c_char_p]
        self.dll.lua_pcall.argtypes = [ptr, ctypes.c_int, ctypes.c_int, ctypes.c_int]
        self.dll.lua_tostring.argtypes = [ptr, ctypes.c_int]
        self.dll.lua_tostring.restype = ctypes.c_char_p
        self.dll.lua_settop.argtypes = [ptr, ctypes.c_int]
        self.state = self.dll.lua_open()
        if not self.state:
            raise RuntimeError('Lua state allocation failed')
        for name in ('luaopen_base', 'luaopen_table', 'luaopen_string', 'luaopen_math'):
            getattr(self.dll, name)(self.state)
            self.dll.lua_settop(self.state, 0)

    def run(self, script):
        raw = script.encode('utf-8') if isinstance(script, str) else script
        code = self.dll.luaL_loadbuffer(self.state, raw, len(raw), b'@create-role-profile-test')
        if not code:
            code = self.dll.lua_pcall(self.state, 0, 0, 0)
        if code:
            error = self.dll.lua_tostring(self.state, -1)
            raise AssertionError((error or b'Lua failure').decode('utf-8', errors='replace'))
        self.dll.lua_settop(self.state, 0)

    def close(self):
        self.dll.lua_close(self.state)


MOCK = r'''
calls={apply=0,create=0,back=0,ask=0,preview=0,restore=0}
events={}
function window()
    return {text='',visible=false,enabled=true,properties={},
        SetTextOriginal=function(self,value) self.original=value end,
        GetText=function(self) return self.text end,
        SetProperty=function(self,name,value) self.properties[name]=value;if name=='Text' then self.text=value end end,
        SetCheck=function(self,value) assert(value==0 or value==1);self.checked=value end,
        SetToolTip=function(self,value) self.tooltip=value end,
        SetFakeObject=function(self,value) self.object=value end,
        RotateBegin=function(self,value) self.rotation=value end,
        RotateEnd=function(self) self.rotation=0 end,
        Show=function(self) self.visible=true end,
        Hide=function(self) self.visible=false end,
        Enable=function(self) self.enabled=true end,
        Disable=function(self) self.enabled=false end,
        RegisterEvent=function(self,event) events[event]=true end}
end
this=window()
GameProduceLogin={
    GetCreateOptions=function(self,sex,kind)
        local n={face=6,hair=3,outfit=3,portrait=15}
        local choices={}
        for i=1,n[kind] do choices[i]={id=i+100,label='Choice '..i,image='set:CysCR_Portrait image:p'..(i-1)} end
        return choices
    end,
    ApplyCreateAppearance=function(self,sex,face,hair,outfit,portrait)
        assert(sex==0 or sex==1)
        assert(face>=0 and face<6 and hair>=0 and hair<3 and outfit>=0 and outfit<3 and portrait>=0 and portrait<15)
        calls.apply=calls.apply+1
        last={sex,face,hair,outfit,portrait}
        return sex==0 and 'CreateRole_Woman' or 'CreateRole_Man','set:CysCR_Portrait image:p'..portrait
    end,
    ModelRotBegin=function(self,value) calls.rotation=value end,
    ModelRotEnd=function(self,value) assert(value==0);calls.rotation=0 end,
    ModelZoom=function(self,value) calls.zoom=value end,
    ShowCreatePreview=function(self,id,sex)
        assert(id>=0 and id<15 and (sex==0 or sex==1))
        calls.preview=calls.preview+1;calls.previewId=id;calls.previewSex=sex
        return 'real-scene-actor', 'set:CysCR_CreateRole3 image:Icon_Tianshan','Native class description'
    end,
    HideCreatePreview=function(self) calls.restore=calls.restore+1 end,
    CreateRole=function(self,name,sex) calls.create=calls.create+1; calls.name=name;calls.sex=sex end,
    ChangeToSelectRoleDlgFromCreateRole=function(self) calls.back=calls.back+1 end,
    ChangeToAccountInputDlgFromSelectRole=function(self) calls.back=calls.back+1 end,
    GetRoleCount=function(self) return roleCount end,
    GetRoleInfo=function(self,index) assert(index>=0 and index<roleCount);return 'Role'..index,roleFaction,1,0,'set:CysCR_Portrait image:p'..index end,
    GetRoleUIModleName=function(self,index) return 'SelectRole'..index end,
    GetCurSelectRole=function(self) return nativeRole end,
    SelectRoleSlot=function(self,index) calls.role=index;nativeRole=index;return 1 end,
    SendEnterGameMsg=function(self,index) assert(index>=0 and index<roleCount);calls.enter=(calls.enter or 0)+1;calls.enterIndex=index end
}
DataPool={AskCreateCharCode=function(self) calls.ask=calls.ask+1 end}
roleCount=0
nativeRole=0
roleFaction=0
'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--stage', required=True)
    parser.add_argument('--out', required=True)
    parser.add_argument('--lua-dll', default='Build/cmake/ci-x64/bin/LuaPlus.dll')
    args = parser.parse_args()
    base = profile.checked(args.stage)
    out = profile.checked(args.out)
    out.mkdir(parents=True, exist_ok=False)
    results = []
    def check(name, condition):
        if not condition:
            raise AssertionError(name)
        results.append(name)
    def reject(name, call):
        try:
            call()
        except ValueError:
            check(name, True)
            return
        raise AssertionError(name + ' was accepted')
    _, gl = profile.verify_base(base)
    stage = out / 'stage'
    stage.mkdir()
    # Minimum real stage data, without an executable or credentials.
    paths = {r['path'] for r in gl['files']}
    paths.update({'Bin64/offline_stage.json', profile.GL_MARKER, 'Data/Config/StrFilter.txt',
                  'Data/Model/all.obj', 'Data/Material/all.material',
                  'Data/MaterialTemplates.zip', 'Data/Effect/all.effect', 'Data/Effect/all.particle',
                  'Data/Interface/Schema/NotoSansSC-Regular.ttf'})
    paths.update('Data/Interface/' + r['path'] for r in gl['pairs'])
    for suffix in ('.material', '.program'):
        paths.update(p.relative_to(base).as_posix() for p in (base / 'Data/Scene').glob('*' + suffix))
    for name in paths:
        destination = stage / name
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(base / name, destination)
    check('fixture has no Game executable', not (stage / 'Bin64/Game.exe').exists())
    before = {name: profile.digest((stage / name).read_bytes()) for name in paths}
    # A dangling link has exists()==False. Simulate only its reparse predicate;
    # no link or target outside Build is created, and the real guard must reject it.
    marker = stage / profile.MARKER
    real_is_symlink = Path.is_symlink
    with mock.patch.object(Path, 'is_symlink', lambda path: path == marker or real_is_symlink(path)):
        reject('reject dangling marker before profile reads or writes', lambda: profile.verify_base(stage))
    updates, plan = profile.make_plan(stage)
    check('plan does not mutate stage', all(profile.digest((stage / n).read_bytes()) == v for n, v in before.items()))
    check('full model closure included', plan['appearance']['updates'] >= 85)
    check('original full scene dependency closure is valid', plan['scene']['valid'] and
          plan['scene']['object_count'] == 421 and not plan['scene']['missing'] and
          not plan['scene']['unsupported'] and not plan['scene']['ambiguous_resources'])
    check('all thirty native sect model IDs have dependency closure',
          {r['model_id'] for r in plan['scene']['sect_objects'] if r['model_id'] is not None} == set(range(4950,4980)))
    scene_targets = [name for name in updates if name.lower() == ('Data/Scene/' + plan['scene']['scene']).lower()]
    check('scene filename has one Windows filesystem target', len(scene_targets) == 1)
    check('scene bytes and every copied source hash match original CY',
          updates[scene_targets[0]] == (profile.SOURCE / 'Scene' / plan['scene']['scene']).read_bytes() and
          all(profile.digest((ROOT / r['path']).read_bytes()) == r['sha256'] for r in plan['scene']['sources']))
    showroom = updates['Data/Config/CysLoginShowroom.txt'].decode('ascii').splitlines()
    check('showroom contains exact scene and five settled native camera rows',
          showroom[0] == 'scene ' + plan['scene']['scene'] and len(showroom) == 6 and
          [row.split()[0] for row in showroom[1:]] == ['female','male','select0','select1','select2'] and
          all(len(row.split()) == 13 for row in showroom[1:]) and plan['showroom']['pose_count'] == 5)
    check('both S2 parent materials and eight paired programs',
          plan['materials']['material_count'] == 2 and plan['materials']['program_count'] == 8)
    with zipfile.ZipFile(io.BytesIO(updates['Data/MaterialTemplates.zip'])) as archive:
        scene_edits = [r for r in plan['scene']['bootstrap']['edits'] if r['location'] == 'zip']
        changed_by_scene = {r['file'] for r in scene_edits}
        check('unrelated Bootstrap entries retain exact bytes after both closures',
              all(profile.digest(archive.read(r['name'])) == r['sha256']
                  for r in plan['materials']['unchanged_entries'] if r['name'] not in changed_by_scene) and
              all(profile.digest(archive.read(r['name'])) == r['sha256']
                  for r in plan['scene']['bootstrap']['unchanged_entries']))
        import create_role_scene_resources as scene_resources
        check('scene parent blocks replace only declared entries with exact S2 bytes', all(
              profile.digest(scene_resources.script_blocks(archive.read(r['file']), r['kind'])[bytes.fromhex(r['key_hex'])])
                  == r['block_sha256']
              for r in scene_edits if r['kind'] in ('material', 'program')))
        check('all selected shader source bytes match S2', all(archive.read(r['name']) ==
              (profile.SOURCE / 'MaterialTemplates' / r['name']).read_bytes()
              for r in plan['materials']['edits'] if r['kind'] == 'shader source'))
    check('material source hashes match DATA CY', all(profile.digest((ROOT / r['path']).read_bytes()) == r['sha256']
          for r in plan['materials']['sources']))
    check('twenty exact DATA CY atlases without synthetic panels', len(plan['atlases']) == 20 and
          all(a['name'] != 'CysCR_MeshBackdrop' for a in plan['atlases']))
    preview_table = updates['Data/Config/CysCreatePreview.txt'].decode('utf-8').splitlines()
    check('preview table has fifteen exact IDs and native-safe UTF-8 fields', len(preview_table) == 15 and
          all(len(row.split('\t')) == 3 and row.split('\t')[0] == str(i) for i, row in enumerate(preview_table)))
    check('preview labels follow actual bitmap text rather than misleading atlas names',
          'Đào Hoa Đảo' in preview_table[12] and 'Tuyệt Tình Cốc' in preview_table[13] and 'Ác Nhân Cốc' in preview_table[14])
    check('thirty actual selectable portraits', plan['portrait_count'] == 30)
    check('seven table aliases preserve S2 bytes', all(updates['Data/Config/CysCreate' + k + '.txt'] ==
          (profile.SOURCE / 'Config' / v).read_bytes() for k, v in profile.TABLES.items()))
    check('six login pairs omitted from updates', all('Data/Interface/' + r['path'] not in updates for r in gl['pairs']))
    check('approved font and empty filter untouched', 'Data/Config/StrFilter.txt' not in updates and
          'Data/Interface/Schema/NotoSansSC-Regular.ttf' not in updates)
    check('original source hashes match', all(profile.digest((ROOT / r['path']).read_bytes()) == r['sha256'] for r in plan['sources']))
    schemes = ET.fromstring(updates['Data/Interface/' + profile.SCHEME])
    baseline_scheme = ET.fromstring((stage / 'Data/Interface' / profile.SCHEME).read_bytes())
    for tag, attr in [('FalagardMapping', 'WindowType'), ('Imageset', 'Name'), ('Font', 'Name')]:
        values = [n.attrib[attr] for n in schemes.findall(tag) if n.attrib[attr].startswith(profile.PREFIX)]
        check('no duplicate creation registration ' + tag, len(values) == len(set(values)))
        check('existing registrations retained ' + tag,
              [n.attrib for n in schemes.findall(tag) if not n.attrib[attr].startswith(profile.PREFIX)] ==
              [n.attrib for n in baseline_scheme.findall(tag)])
    layout_module = profile.load_layout_module()
    for name in ('CreateRole', 'SelectRole'):
        tree = ET.fromstring(updates['Data/Interface/' + name + '/' + name + '.layout.xml'])
        original = layout_module.source_layout(name)
        def hierarchy(document):
            def walk(node, parent):
                records = []
                if node.tag == 'Window':
                    records.append((node.attrib['Name'], parent, node.attrib['Type'].removeprefix(profile.PREFIX)))
                    parent = node.attrib['Name']
                for child in node:
                    records.extend(walk(child, parent))
                return records
            return walk(document, '')
        check('exact original CY control tree ' + name, hierarchy(tree) == hierarchy(original) and
              len(list(tree.iter('Window'))) == layout_module.COUNTS[name])
        check('exact original event hooks ' + name,
              [n.attrib for n in tree.iter('Event')] == [n.attrib for n in original.iter('Event')])
        for generated, source in zip(tree.iter('Window'), original.iter('Window')):
            expected = [(n.attrib['Name'], n.attrib['Value']) for n in source.findall('Property')]
            actual = [(n.attrib['Name'], n.attrib['Value']) for n in generated.findall('Property')]
            allowed = {'Font'}
            if source.attrib['Name'] in layout_module.LABELS:
                allowed.add('Text')
            if source.attrib['Name'] == 'CreateRole_Name':
                allowed.add('MaxTextLength')
            expected = [(k, v) for k, v in expected if k not in allowed]
            actual = [(k, v.replace('set:' + profile.PREFIX, 'set:')) for k, v in actual if k not in allowed]
            if expected != actual:
                raise AssertionError('Original CY geometry/art/property changed: ' + source.attrib['Name'])
        check('every original geometry and art property retained ' + name, True)
        if name == 'CreateRole':
            model = next(n for n in tree.iter('Window') if n.attrib['Name'] == 'CreateRole_Model')
            check('retained RTT control names actual parent',
                  any(p.attrib == {'Name': 'ShowControl', 'Value': 'CreateRole_Frame'} for p in model.findall('Property')))
        else:
            check('selection never inserts an invented RTT model',
                  not any('MeshWindow' in n.attrib['Type'] for n in tree.iter('Window')))
    check('twelve original CY type mappings', len([n for n in schemes.findall('FalagardMapping')
          if n.attrib['WindowType'].startswith(profile.PREFIX)]) == 12)
    check('fifteen original preview title images', sum(len([v for v in a['images'] if v.startswith('Icon_')])
          for a in plan['atlases'] if a['name'] in {'CysCR_CreateRole3','CysCR_CreateRole4','CysCR_CreateRole5'}) == 15)
    reject('reject destination traversal', lambda: profile.checked('Build/../escape'))
    reject('reject source as destination', lambda: profile.checked('../Tools/DATA NEW/DataCY31-08-26'))
    pair = stage / 'Data/Interface' / gl['pairs'][0]['path']
    raw = pair.read_bytes()
    pair.write_bytes(raw + b'\n')
    reject('reject changed login pair', lambda: profile.verify_base(stage))
    pair.write_bytes(raw)
    filter_path = stage / 'Data/Config/StrFilter.txt'
    raw = filter_path.read_bytes()
    filter_path.write_bytes(raw + b'0\tblocked\n')
    reject('reject nonempty StrFilter', lambda: profile.verify_base(stage))
    filter_path.write_bytes(raw)

    # Parse and exercise the actual generated controller with the current production DLL.
    dll = ROOT / args.lua_dll
    vm = Lua(dll)
    try:
        vm.run(MOCK)
        for names in plan['controls'].values():
            vm.run('\n'.join(n + '=window()' for n in names))
        for name in ('CreateRole', 'SelectRole'):
            vm.run(updates['Data/Interface/' + name + '/' + name + '.lua'])
        def lua_check(name, code):
            vm.run(code)
            check(name, True)
        lua_check('controller registers create and selection events', '''LoginCreateRole_PreLoad();LoginSelectRole_PreLoad()
assert(events.GAMELOGIN_OPEN_CREATE_CHARACTOR and events.GAMELOGIN_CREATE_CLEAR_NAME and events.GAMELOGIN_CREATE_ROLE_OK)''')
        lua_check('fixture keeps original text separate from displayed text', '''local w=window();w:SetTextOriginal('original')
assert(w.text=='' and w.original=='original');w:SetProperty('Text','display');assert(w.text=='display')''')
        lua_check('creation uses native scene and leaves original RTT unhooked', """LoginCreateRole_OnLoad();LoginSelectRole_OnLoad()
LoginCreateRole_OnEvent('GAMELOGIN_OPEN_CREATE_CHARACTOR')
assert(this.visible and calls.apply==1 and last[1]==0 and CreateRole_Model.object=='' and not CreateRole_Model.visible)""")
        lua_check('original face hair outfit labels and sex update actual visible text', """assert(CreateRole_SelectFace_Text2.text=='1/6')
assert(CreateRole_SelectHair_Text2.text=='1/3' and CreateRole_SelectClothing_Text2.text=='1/3')
assert(CreateRole_SelectSex_Girl.text=='Nữ' and CreateRole_SelectSex_Girl.checked==1 and CreateRole_Info.text~='')""")
        lua_check('first portrait page fills nine actual catalog images', """assert(CreateRole_Select_HeadImage1.visible and CreateRole_Select_HeadImage9.visible)
assert(CreateRole_Select_HeadImage9.properties.Image=='set:CysCR_Portrait image:p8')
assert(CreateRole_Select_Head1.checked==1 and not CreateRole_PageUp.enabled and CreateRole_PageDown.enabled)""")
        lua_check('second portrait page hides only unavailable cells and bounds navigation', """CreateRole_BnClickFacePageDown()
assert(CreateRole_Select_HeadImage1.properties.Image=='set:CysCR_Portrait image:p9')
assert(CreateRole_Select_HeadImage6.visible and not CreateRole_Select_HeadImage7.visible and not CreateRole_Select_Head7.visible)
assert(CreateRole_PageUp.enabled and not CreateRole_PageDown.enabled)
CreateRole_BnClickFacePageDown();CreateRole_BnSelFace6();assert(last[5]==14)
CreateRole_BnSelFace7();assert(last[5]==14)""")
        lua_check('portrait page change retains off-page selection', """CreateRole_BnClickFacePageUp();CreateRole_BnClickFacePageUp()
assert(CreateRole_Select_HeadImage1.properties.Image=='set:CysCR_Portrait image:p0' and CreateRole_Select_Head1.checked==0)
CreateRole_BnSelFace9();assert(last[5]==8)""")
        lua_check('face previous and next wrap by table count', "CreateRole_SelectFace_TurnLeft1_Clicked();assert(last[2]==5);CreateRole_SelectFace_TurnRight1_Clicked();assert(last[2]==0)")
        lua_check('sex resets independent choices and check buttons', "CreateRole_SelectBoy();assert(last[1]==1 and last[2]==0 and last[5]==0 and CreateRole_SelectSex_Boy.checked==1 and CreateRole_SelectSex_Girl.checked==0)")
        lua_check('random appearance stays inside catalog and follows portrait page', 'for i=1,100 do CreateRole_Random_Clicked() end')
        lua_check('random name uses DATA CY UTF-8 and native byte limit', 'CreateRole_RandomName_Clicked();assert(string.len(CreateRole_Name.text)>0 and string.len(CreateRole_Name.text)<=29)')
        lua_check('empty name never reaches create host', "CreateRole_Name.text='';CreateRole_BnClickCreateRole();assert(calls.create==0)")
        lua_check('overlong UTF-8 name never reaches create host', "CreateRole_Name.text=string.rep('中',10);CreateRole_BnClickCreateRole();assert(calls.create==0)")
        lua_check('valid name passes unmodified to native host', "CreateRole_Name.text='Việt中';CreateRole_BnClickCreateRole();assert(calls.create==1 and calls.name=='Việt中' and calls.sex==1)")
        lua_check('all fifteen native previews support both sexes without assigning creation faction', """for id=0,14 do
CreateRole_BnClickMenpaiModel(id);assert(calls.previewId==id and not CreateRole_Info_Frame.visible and CreateRole_Info2_Frame.visible)
CreateRole_Preview_Woman_Clicked();assert(calls.previewSex==0)
CreateRole_Preview_Man_Clicked();assert(calls.previewSex==1)
end
assert(calls.create==1 and CreateRole_Info2_Frame_Back2.properties.Image~='' and Createshow_Info2.text~='')
assert(CreateRole_Name.properties.DefaultEditBox=='False' and not CreateRole_Name.visible)""")
        lua_check('preview cancel restores creation selection and editor', """local old=last
CreateRole_BnClickMenpaiModel(-1)
assert(calls.restore==1 and CreateRole_Info_Frame.visible and not CreateRole_Info2_Frame.visible and CreateRole_Name.visible)
for i=1,5 do assert(old[i]==last[i]) end
assert(CreateRole_Name.properties.DefaultEditBox=='True')""")
        lua_check('original rotation and zoom directions stop on release', """CreateRole_Modle_TurnLeft(1);assert(calls.rotation==-1)
CreateRole_Modle_TurnLeft(0);assert(calls.rotation==0);CreateRole_Modle_TurnRight(1);assert(calls.rotation==1)
CreateRole_Modle_TurnRight(0);CreateRole_Modle_ZoomOut(1);assert(calls.zoom==-1)
CreateRole_Modle_ZoomOut(0);assert(calls.zoom==0);CreateRole_Modle_ZoomIn(1);assert(calls.zoom==1)
CreateRole_Modle_ZoomIn(0);assert(calls.zoom==0)""")
        lua_check('close creation releases motion and edit focus', "LoginCreateRole_OnEvent('GAMELOGIN_CLOSE_CREATE_CHARACTOR');assert(not this.visible and CreateRole_Model.object=='' and CreateRole_Name.properties.DefaultEditBox=='False' and calls.zoom==0 and calls.rotation==0)")
        lua_check('zero role retains three original empty cards', """LoginSelectRole_OnEvent('GAMELOGIN_OPEN_SELECT_CHARACTOR')
assert(SelectRole_TargetInfo_Create.visible and SelectRole_TargetInfo_Create2.visible and SelectRole_TargetInfo_Create3.visible)
assert(not SelectRole_TargetInfo_Name_Text.visible and SelectRole_Create.enabled)""")
        lua_check('create click requests actual server challenge', 'SelectRole_CreateRole();assert(calls.ask==1)')
        lua_check('role refresh fills original cards and selects native scene actor', """roleCount=2;LoginSelectRole_OnEvent('GAMELOGIN_REFRESH_ROLE_SELECT_CHARACTOR')
assert(SelectRole_TargetInfo_Name_Text.text=='Role0' and SelectRole_TargetInfo_Name_Text2.text=='Role1')
assert(SelectRole_Icon2.visible and SelectRole_Icon2.properties.Image=='set:CysCR_Portrait image:p1')
assert(SelectRole_TargetInfo_Create3.visible and not SelectRole_TargetInfo_Create2.visible and calls.role==0)""")
        lua_check('role faction labels use actual role IDs rather than preview IDs', """roleFaction=-1;LoginSelectRole_OnEvent('GAMELOGIN_REFRESH_ROLE_SELECT_CHARACTOR')
assert(SelectRole_TargetInfo_Menpai_Text.text=='Vô môn')
roleFaction=12;LoginSelectRole_OnEvent('GAMELOGIN_REFRESH_ROLE_SELECT_CHARACTOR')
assert(SelectRole_TargetInfo_Menpai_Text.text=='Mộ Dung');roleFaction=0""")
        lua_check('original slot click changes native selection and highlight', 'SelectRole_Clicked(1);assert(calls.role==1 and SelectRole_TargetInfo_Gaoliang2.visible and not SelectRole_TargetInfo_Gaoliang1.visible)')
        lua_check('post-create follows native GUID selection and disables full-slot creation', "roleCount=3;nativeRole=1;LoginSelectRole_OnEvent('GAMELOGIN_CREATE_ROLE_OK');assert(not SelectRole_Create.enabled and calls.role==1)")
        lua_check('modern enter is available for real roles while delete stays disabled', 'assert(SelectRole_Play.enabled and not SelectRole_Delete.enabled)')
        lua_check('enter sends the native selected slot and releases model motion', """calls.rotation=1;calls.zoom=1;local before=calls.enter or 0
SelectRole_EnterGame();assert(calls.enter==before+1 and calls.enterIndex==nativeRole and calls.rotation==0 and calls.zoom==0)
assert(SelectRole_Info.text=='Đang vào game...')""")
        lua_check('double click selects that slot before entering', 'local before=calls.enter;SelectRole_DoubleClicked(2);assert(calls.role==2 and calls.enter==before+1 and calls.enterIndex==2)')
        lua_check('no role or invalid native slot never sends enter', """local before=calls.enter
nativeRole=7;SelectRole_EnterGame();assert(calls.enter==before and SelectRole_Info.text=='Chọn một nhân vật.')
roleCount=0;LoginSelectRole_OnEvent('GAMELOGIN_REFRESH_ROLE_SELECT_CHARACTOR');SelectRole_EnterGame()
assert(calls.enter==before and not SelectRole_Play.enabled)
roleCount=3;nativeRole=1;LoginSelectRole_OnEvent('GAMELOGIN_REFRESH_ROLE_SELECT_CHARACTOR')""")
        # Every declared callback must parse and call only actual declared methods.
        for name in ('CreateRole', 'SelectRole'):
            for node in ET.fromstring(updates['Data/Interface/' + name + '/' + name + '.layout.xml']).iter('Event'):
                vm.run(node.attrib['Function'])
        check('all declared layout callbacks execute', True)
    finally:
        vm.close()

    apply_out = out / 'apply'
    command = [sys.executable, '-B', str(ROOT / 'Tools/data/prepare_create_role_profile.py'),
               '--stage', stage.relative_to(ROOT).as_posix(), '--out', apply_out.relative_to(ROOT).as_posix(), '--apply']
    completed = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, encoding='utf-8')
    (out / 'apply.log').write_text(completed.stdout + completed.stderr, encoding='utf-8')
    check('full private fixture apply succeeds', completed.returncode == 0)
    applied = json.loads((stage / profile.MARKER).read_bytes())
    check('marker applied only after complete plan', applied['applied'] is True and len(applied['files']) == len(updates))
    check('all applied file hashes match marker', all(profile.digest((stage / r['path']).read_bytes()) == r['sha256'] for r in applied['files']))
    check('every replaced file has exact backup', all(not r.get('backup') or profile.digest((ROOT / r['backup']).read_bytes()) == r['sha256_before'] for r in applied['files']))
    child_gl = json.loads((stage / profile.GL_MARKER).read_bytes())
    check('inherited GL manifest remains valid', all(profile.digest((stage / r['path']).read_bytes()) == r['sha256'] for r in child_gl['files']))
    check('original six pairs survive byte-for-byte', all(profile.digest((stage / 'Data/Interface' / r['path']).read_bytes()) == r['sha256'] for r in gl['pairs']))
    reject('reject accidental repeated apply', lambda: profile.verify_base(stage))
    result = {'passed': len(results), 'failed': 0, 'tests': results, 'lua_dll': args.lua_dll,
              'lua_dll_sha256': profile.digest(dll.read_bytes()), 'fixture': stage.relative_to(ROOT).as_posix(),
              'runtime_scope': 'Data closure and Lua controller fixtures only; no native UI render, server or Game launch.'}
    (out / 'result.json').write_bytes(profile.json_bytes(result))
    print(json.dumps({'passed': len(results), 'failed': 0, 'result': (out / 'result.json').relative_to(ROOT).as_posix()}))


if __name__ == '__main__':
    main()
