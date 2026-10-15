"""Compile and exercise the actual production Tick_Move body with minimal dependencies."""
from pathlib import Path
import argparse, datetime, hashlib, json, os, subprocess

root = Path(__file__).resolve().parents[2]
ap = argparse.ArgumentParser(description=__doc__)
ap.add_argument('--source', type=Path, default=root / 'Src/Client/WXClient/Object/Character/Obj_Character_Logic.cpp')
ap.add_argument('--out-dir', type=Path, help='New evidence directory; existing directories are refused')
ap.add_argument('--vcvars', type=Path, help='Optional vcvarsall.bat; otherwise discover VS C++ through vswhere')
args = ap.parse_args()
source = args.source.resolve()
out = (args.out_dir or root / 'Build/Tests/movement' / datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f')).resolve()
vc = args.vcvars
if vc is None:
    vswhere = Path(os.environ.get('ProgramFiles(x86)', r'C:\Program Files (x86)')) / 'Microsoft Visual Studio/Installer/vswhere.exe'
    if not vswhere.is_file(): ap.error('vswhere is unavailable; pass --vcvars')
    installation = subprocess.run([str(vswhere), '-latest', '-products', '*', '-requires', 'Microsoft.VisualStudio.Component.VC.Tools.x86.x64', '-property', 'installationPath'], capture_output=True, text=True, check=True).stdout.strip()
    if not installation: ap.error('No Visual Studio C++ installation found; pass --vcvars')
    vc = Path(installation) / 'VC/Auxiliary/Build/vcvarsall.bat'
vc = vc.resolve()
if not vc.is_file(): ap.error('--vcvars must name vcvarsall.bat')
out.mkdir(parents=True, exist_ok=False)
body = source.read_text(encoding='utf-8-sig')
body = body[body.index('// CYS-MOVE-NODE:'):body.index('BOOL CObject_Character::Tick_MagicCharge')]
(out / 'production.inc').write_text(body, encoding='utf-8')
harness = r'''
#define NOMINMAX
#include <windows.h>
#include <cmath>
#include <cstdio>
#include <cstdarg>
#include <vector>
#include <algorithm>
using FLOAT=float;
struct fVector2 { float x=0,y=0; fVector2()=default; fVector2(float a,float b):x(a),y(b){} fVector2 operator-(fVector2 b)const{return {x-b.x,y-b.y};} };
struct fVector3 { float x=0,y=0,z=0; };
struct WORLD_POS { float m_fX=0,m_fZ=0; };
struct CObjectCommand_Move { std::vector<WORLD_POS> nodes; int GetNodeCount(){return (int)nodes.size();} const WORLD_POS* GetNodeList(){return nodes.data();} };
struct CharacterData { float speed=4.2f; float Get_MoveSpeed(){return speed;} };
struct CObject_Character {
 CObjectCommand_Move cmd; CharacterData data; fVector3 position; bool stopped=false;
 struct { WORLD_POS m_posSaveStart,m_posSaveTarget; int m_nCurrentNodeIndex=0; } m_paramLogic_Move;
 CObjectCommand_Move* GetCurrentLogicCommand(){return &cmd;} CharacterData* GetCharacterData(){return &data;}
 fVector3 GetPosition(){return position;} float GetFaceDir(){return 0;} void SetFaceDir(float){}
 void SetMapPosition(fVector2 p){position.x=p.x;position.z=p.y;}
 void CharacterLogic_Stop(BOOL){stopped=true;}
 BOOL Tick_Move(UINT);
};
struct CObjectManager { static CObjectManager* GetMe(){static CObjectManager m;return &m;} CObject_Character* self=nullptr; CObject_Character* GetMySelf(){return self;} };
struct CPath { static bool IsPointInUnreachRegion(fVector2){return false;} };
float TDU_GetYAngle(fVector2 a,fVector2 b){return atan2f(b.y-a.y,b.x-a.x);}
fVector2 TDU_GetReflect(fVector2,fVector2,fVector2 p){return p;}
void TDU_Log(const char*,...){}
#include "production.inc"
float dist(WORLD_POS a,WORLD_POS b){return hypotf(a.m_fX-b.m_fX,a.m_fZ-b.m_fZ);}
float progress(CObject_Character& c){
 int index=c.m_paramLogic_Move.m_nCurrentNodeIndex; float result=0; WORLD_POS prev{};
 for(int i=0;i<std::min(index,c.cmd.GetNodeCount());++i){result+=dist(prev,c.cmd.nodes[i]);prev=c.cmd.nodes[i];}
 if(index<c.cmd.GetNodeCount()) result+=dist(prev,{c.position.x,c.position.z});
 return result;
}
struct Result { bool bounded=true,arrived=false; float largest=0; int frames=0; };
Result run(const char* name,std::vector<WORLD_POS> nodes,UINT ms,float speed){
 CObject_Character c; c.cmd.nodes=nodes; c.data.speed=speed; CObjectManager::GetMe()->self=&c;
 Result r; float old=0; const float budget=ms*speed/1000.0f;
 for(int i=0;i<10000 && !c.stopped;++i){c.Tick_Move(ms);float now=progress(c);float delta=now-old;r.largest=std::max(r.largest,delta);if(delta>budget+0.0001f || delta < -0.0001f)r.bounded=false;old=now;++r.frames;}
 r.arrived=c.stopped && dist({c.position.x,c.position.z},nodes.back())<0.0001f;
 printf("%s ms=%u speed=%.4f budget=%.6f max_arc_step=%.6f frames=%d bounded=%d arrived=%d final=%.6f,%.6f\n",name,ms,speed,budget,r.largest,r.frames,r.bounded,r.arrived,c.position.x,c.position.z);
 return r;
}
int main(int argc,char**){
 bool legacy=argc>1; SetEnvironmentVariableA("CYS_MOVE_NODE_LEGACY",legacy?"1":"0"); SetEnvironmentVariableA("CYS_MOVE_NODE_LOG","0");
 int checks=0,fail=0,negative=0;
 auto check=[&](const char* n,std::vector<WORLD_POS> p,UINT ms=16,float speed=4.2f){auto r=run(n,p,ms,speed);++checks;if(!r.bounded||!r.arrived){++negative;if(!legacy)++fail;}};
 check("turns",{{.02f,0},{.02f,10},{10,10},{10,20}});
 check("zero-first",{{0,0},{10,0}});
 check("zero-middle",{{.02f,0},{.02f,0},{.02f,10}});
 check("many-identical",{{0,0},{0,0},{0,0},{0,10},{0,10},{10,10},{10,10}});
 check("zero-last",{{.02f,0},{10,0},{10,0}});
 check("single-zero",{{0,0}});
 check("exact-boundary",{{.0672f,0},{.0672f,10}});
 check("budget-many-nodes",{{.01f,0},{.02f,0},{.02f,.03f},{.05f,.03f},{.05f,.1f},{10,.1f}},250);
 for(UINT ms: {4u,8u,16u,33u,100u,250u}) for(float speed: {3.5f,4.2f,6.0f}) check("rate-sweep",{{.02f,0},{.02f,10},{10,10},{10,20}},ms,speed);
 if(legacy && negative<3)++fail;
 printf("VERDICT arm=%s checks=%d negative_cases=%d failures=%d\n",legacy?"legacy":"patched",checks,negative,fail);
 return fail?1:0;
}
'''
(out / 'test.cpp').write_text(harness, encoding='ascii')
cmd = '@echo off\ncall "' + str(vc) + '" x64 >nul\nif errorlevel 1 exit /b 1\ncl /nologo /utf-8 /std:c++17 /EHsc /O2 /W4 test.cpp /Fe:test.exe\nif errorlevel 1 exit /b 1\ntest.exe legacy > legacy.log\nif errorlevel 1 exit /b 1\ntest.exe > patched.log\nexit /b %errorlevel%\n'
(out / 'run.cmd').write_text(cmd, encoding='ascii')
with (out/'compile.log').open('wb') as log:
    p=subprocess.run(['cmd.exe','/d','/c',str(out/'run.cmd')],cwd=out,stdout=log,stderr=subprocess.STDOUT)
(out/'manifest.json').write_text(json.dumps({'source':str(source),'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'extracted_sha256':hashlib.sha256(body.encode()).hexdigest(),'exit_code':p.returncode,'scope':'actual production Tick_Move, engine and network dependencies mocked'},indent=2))
print(out)
print((out/'compile.log').read_text(errors='replace'))
for name in ['legacy.log','patched.log']:
    if (out/name).exists(): print(name+': '+(out/name).read_text().splitlines()[-1])
raise SystemExit(p.returncode)
