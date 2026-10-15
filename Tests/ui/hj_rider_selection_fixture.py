"""Generate a native test of the actual rider-selector body with staged DBC rows."""
import sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'Tools/game'))
from hj_appearance_data import PACK,RawTable
text=(ROOT/'Src/Client/WXClient/Object/Character/Obj_Character.cpp').read_text(encoding='utf8')
body=text[text.index('static INT CysRiderActionSet('):text.index('VOID CObject_Character::UpdateCharActionSetFile(')]
mounts=[r for r in RawTable(PACK/'ConfigFolder/CharMount.txt').rows if r[0]>=2000]
files=RawTable(PACK/'ConfigFolder/ActionSetFile.txt').byid
ids={819,1415}|{r[c] for r in mounts for c in (6,7) if r[c]>=0}
quote=lambda b:'"'+''.join('\\%03o'%c for c in b)+'"'
source='''#include <cstring>
#include <cstdio>
#include <map>
using INT=int; using CHAR=char;
#define INVALID_ID -1
struct _DBC_CHARACTER_MOUNT { int m_nRiderActionSetF,m_nRiderActionSetM; } row;
struct DB { const void* Search_Index_EQU(int) { return &row; } } db;
#define DBC_DEFINEHANDLE(name,kind) DB* name=&db;
std::map<int,const char*> names={
'''+''.join('{%d,%s},\n'%(id,quote(files[id][1])) for id in sorted(ids))+'''};
const char* CysActionSetFileNameByID(int id) { auto it=names.find(id); return it==names.end()?nullptr:it->second; }
'''+body+'\nint main(){ int checked=0;\n'
for r in mounts:
    source+='row={%d,%d}; if(CysRiderActionSet(%d,819)!=%d || CysRiderActionSet(%d,1415)!=%d) return 1; checked+=2;\n'%(r[6],r[7],r[0],r[6],r[0],r[7])
source+='std::printf("PASS %d native rider sex selections using real HJ rows\\n",checked); return 0;}\n'
Path(sys.argv[1]).write_text(source,encoding='utf8')
