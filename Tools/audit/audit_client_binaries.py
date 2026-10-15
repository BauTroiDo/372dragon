"""Read-only PE/build provenance inventory of a CY-Source stage; no DLL is loaded."""
from pathlib import Path
import argparse, datetime, hashlib, json, re
import pefile

ROOT = Path(__file__).resolve().parents[2]
BUILT = {
    'Game.exe': ('cys_wxclient', 'wxclient', 'Src/Client/WXClient'),
    'CEGUIBase.dll': ('cys_ceguibase', 'cegui', 'Src/ThirdParty/CEGUI-0.4.1'),
    'CEGUIFalagard.dll': ('cys_ceguifalagard', 'cegui', 'Src/ThirdParty/CEGUI-0.4.1; Src/Client/CEGUIFalagardEx'),
    'CEGUIOgreRenderer.dll': ('cys_ceguiogrerenderer', 'cegui', 'Src/ThirdParty/CEGUI-0.4.1'),
    'LuaPlus.dll': ('cys_luaplus', 'luaplus', 'Src/ThirdParty/LuaPlus'),
    'OgreMain.dll': ('OgreMain', 'ogremain', 'Src/Engine/OGRE'),
    'PathLib.dll': ('cys_pathlib', 'pathlib', 'Src/Engine/PathLib'),
    'Plugin_CgProgramManager.dll': ('Plugin_CgProgramManager', 'ogre_plugins', 'Src/Engine/OGRE/PlugIns/CgProgramManager'),
    'Plugin_ParticleFX2.dll': ('cys_particlefx2', 'particlefx2', 'Src/Engine/ParticleFX2'),
    'Plugin_Scorpio.dll': ('cys_scorpio', 'scorpio', 'Src/Engine/Scorpio'),
    'Render.dll': ('cys_wxrender', 'wxrender', 'Src/Engine/WXRender; Src/Engine/WXCore'),
    'RenderSystem_Direct3D9.dll': ('RenderSystem_Direct3D9', 'ogre_d3d9', 'Src/Engine/OGRE/RenderSystems/Direct3D9'),
    'UI_CEGUI.dll': ('cys_uisystem', 'uisystem', 'Src/Client/CEGUISystem'),
}
VENDOR = {
    'cg.dll': ROOT.parent/'client_GL/Bin64/cg.dll',
    'fmod.dll': ROOT/'Src/ThirdParty/_sdk/fmod/api/core/lib/x64/fmod.dll',
    'fmodL.dll': ROOT/'Src/ThirdParty/_sdk/fmod/api/core/lib/x64/fmodL.dll',
    'd3dx9_43.dll': Path('C:/Windows/System32/d3dx9_43.dll'),
    'D3DCompiler_43.dll': Path('C:/Windows/System32/D3DCompiler_43.dll'),
}
APIS = {'CreateRemoteThread','CreateRemoteThreadEx','NtCreateThreadEx','RtlCreateUserThread',
        'WriteProcessMemory','VirtualAllocEx','QueueUserAPC','SetWindowsHookExA','SetWindowsHookExW',
        'VirtualProtect','VirtualAlloc','FlushInstructionCache','LoadLibraryA','LoadLibraryW',
        'LoadLibraryExA','LoadLibraryExW','GetProcAddress','OpenProcess'}

def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest() if p.is_file() else None

def normalized_pe(p):
    """Exclude identified build metadata only, never whole sections or code."""
    pe=pefile.PE(str(p));raw=bytearray(p.read_bytes());fields=[]
    def zero(offset,size,label):
        fields.append({'offset':offset,'size':size,'field':label})
        raw[offset:offset+size]=b'\0'*size
    zero(pe.FILE_HEADER.get_field_absolute_offset('TimeDateStamp'),4,'COFF.TimeDateStamp')
    zero(pe.OPTIONAL_HEADER.get_field_absolute_offset('CheckSum'),4,'OptionalHeader.CheckSum')
    if hasattr(pe,'DIRECTORY_ENTRY_EXPORT'):
        zero(pe.DIRECTORY_ENTRY_EXPORT.struct.get_field_absolute_offset('TimeDateStamp'),4,'Export.TimeDateStamp')
    for d in getattr(pe,'DIRECTORY_ENTRY_DEBUG',[]):
        zero(d.struct.get_field_absolute_offset('TimeDateStamp'),4,'Debug.TimeDateStamp')
        pos=d.struct.PointerToRawData
        if d.struct.Type==2 and raw[pos:pos+4]==b'RSDS':zero(pos+4,20,'CodeView.PdbGuidAndAge')
    if p.name=='OgreMain.dll':
        # Verified __DATE__ strings, from il_states.c:23 and ilu_states.c:19.
        for prefix in [b"Developer's Image Library Utilities (ILU) 1.6.7 ",b"Developer's Image Library (DevIL) 1.6.8pre "]:
            pos=raw.find(prefix)
            if pos>=0:
                start=pos+len(prefix)
                assert re.fullmatch(rb'[A-Z][a-z]{2} [ 0-9][0-9] [0-9]{4}\x00',raw[start:start+12])
                zero(start,11,'DevIL/ILU.__DATE__')
    pe.close();return bytes(raw),fields

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--stage',type=Path,default=ROOT/'Build/world-gui/stage-play-21')
    p.add_argument('--build',type=Path,default=ROOT/'Build/cmake/coord-x64')
    p.add_argument('--out',type=Path,required=True)
    a=p.parse_args();a.out.mkdir(parents=True,exist_ok=True)
    manifest=json.loads((a.stage/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
    rows={r['name']:r for r in manifest['binaries']}
    ninja=(a.build/'build.ninja').read_text(encoding='utf8')
    report={'at':datetime.datetime.now().astimezone().isoformat(),'stage':str(a.stage.resolve()),
            'build':str(a.build.resolve()),'manifest_sha256':sha(a.stage/'Bin64/game_data_stage.json'),'binaries':[]}
    for f in sorted((a.stage/'Bin64').iterdir(),key=lambda x:x.name.lower()):
        if f.suffix.lower() not in ('.exe','.dll'):continue
        pe=pefile.PE(str(f));imports={}
        for kind in ('DIRECTORY_ENTRY_IMPORT','DIRECTORY_ENTRY_DELAY_IMPORT'):
            for d in getattr(pe,kind,[]):
                imports.setdefault(d.dll.decode(errors='replace'),[]).extend(
                    i.name.decode(errors='replace') if i.name else 'ordinal:'+str(i.ordinal) for i in d.imports)
        r={'name':f.name,'bytes':f.stat().st_size,'sha256':sha(f),'machine':hex(pe.FILE_HEADER.Machine),
           'manifest_match':f.name in rows and rows[f.name]['sha256']==sha(f),
           'manifest_kind':rows.get(f.name,{}).get('kind'),'imports':imports,
           'exports_count':len(getattr(getattr(pe,'DIRECTORY_ENTRY_EXPORT',None),'symbols',[])),
           'interesting_imports':sorted({n for ns in imports.values() for n in ns if n in APIS}),
           'sections':[{'name':s.Name.rstrip(b'\0').decode(errors='replace'),'virtual_size':s.Misc_VirtualSize,
                        'r':bool(s.Characteristics&0x40000000),'w':bool(s.Characteristics&0x80000000),
                        'x':bool(s.Characteristics&0x20000000),'entropy':round(s.get_entropy(),3)} for s in pe.sections],
           'pdb':[getattr(d.entry,'PdbFileName',b'').rstrip(b'\0').decode(errors='replace')
                  for d in getattr(pe,'DIRECTORY_ENTRY_DEBUG',[]) if hasattr(d,'entry') and hasattr(d.entry,'PdbFileName')]}
        if f.name in BUILT:
            target,component,source=BUILT[f.name]
            source_edges=[line for line in ninja.splitlines() if line.startswith('build CMakeFiles\\'+target+'.dir\\') and '.obj: ' in line]
            link_rule=next((line for line in ninja.splitlines() if line.startswith(('build bin\\'+f.name+' ', 'build bin\\'+f.name+':'))),None)
            r.update(origin='source_build',target=target,cmake='Src/cmake/components/'+component+'.cmake',source=source,
                     direct_object_count=len(source_edges),ninja_link_rule=bool(link_rule),
                     build_output_match=sha(f)==sha(a.build/'bin'/f.name))
            assert source_edges and link_rule,(f.name,'missing build rule')
            a_bytes,a_fields=normalized_pe(f);b_bytes,b_fields=normalized_pe(a.build/'bin'/f.name)
            r.update(normalized_build_match=a_bytes==b_bytes,comparison_excluded_fields=a_fields,
                     normalized_sha256=hashlib.sha256(a_bytes).hexdigest())
        elif f.name in VENDOR:
            r.update(origin='prebuilt_runtime',reference=str(VENDOR[f.name]),reference_match=sha(f)==sha(VENDOR[f.name]))
        else:r['origin']='unclassified'
        report['binaries'].append(r);pe.close()
    report['counts']={k:sum(r['origin']==k for r in report['binaries']) for k in ('source_build','prebuilt_runtime','unclassified')}
    report['all_manifest_hashes_match']=all(r['manifest_match'] for r in report['binaries'])
    report['all_source_build_outputs_match']=all(r.get('build_output_match',True) for r in report['binaries'])
    report['all_source_outputs_match_except_documented_build_metadata']=all(r.get('normalized_build_match',True) for r in report['binaries'])
    report['all_prebuilt_references_match']=all(r.get('reference_match',True) for r in report['binaries'])
    report['runtime_proxy_present']=(a.stage/'Bin64/d3d9.dll').exists()
    report['diagnostic_proxy_build_present']=(a.build/'bin/d3d9trace/d3d9.dll').exists()
    report['remote_injection_imports']={r['name']:[s for s in r['interesting_imports'] if s in APIS-{'VirtualAlloc','VirtualProtect','FlushInstructionCache','LoadLibraryA','LoadLibraryW','LoadLibraryExA','LoadLibraryExW','GetProcAddress','OpenProcess'}] for r in report['binaries']}
    (a.out/'binary-inventory.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    (a.out/'build-source-edges.txt').write_text('\n'.join(line for line in ninja.splitlines() if line.startswith('build CMakeFiles\\') and '.obj: ' in line)+'\n',encoding='utf8')
    print(json.dumps({k:v for k,v in report.items() if k not in ('binaries','remote_injection_imports')},ensure_ascii=False,indent=2))
    for r in report['binaries']:print(r['name'],r['origin'],'match',r.get('build_output_match',r.get('reference_match')),r['interesting_imports'])

if __name__=='__main__':main()
