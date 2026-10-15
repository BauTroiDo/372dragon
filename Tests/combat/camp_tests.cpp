#include "CampAndStand.h"
#include <cstdio>
#include <cstring>
#include <functional>
#include <limits>
#include <new>
#include <sstream>
#include <stdexcept>

static int passed=0, failed=0;
static void require(bool ok,const char* text){if(!ok)throw std::runtime_error(text);}
static void test(const char* name,const std::function<void()>& body){
    try {body();++passed;std::printf("PASS %s\n",name);}
    catch(const std::exception& e){++failed;std::printf("FAIL %s: %s\n",name,e.what());}
    catch(const std::string& e){++failed;std::printf("FAIL %s: %s\n",name,e.c_str());}
}
struct GuardedManager {
    unsigned long long before[8];
    alignas(CampAndStandDataMgr_T) unsigned char storage[sizeof(CampAndStandDataMgr_T)];
    unsigned long long after[16];
    CampAndStandDataMgr_T* manager;
    GuardedManager(){std::memset(before,0xA5,sizeof(before));std::memset(after,0xA5,sizeof(after));manager=new(storage) CampAndStandDataMgr_T;}
    bool intact()const{
        for(auto value:before)if(value!=0xA5A5A5A5A5A5A5A5ull)return false;
        for(auto value:after)if(value!=0xA5A5A5A5A5A5A5A5ull)return false;
        return true;
    }
    // A failed guard means the original defect may also have overwritten the
    // manager's owned pointer. Report that write without a second invalid delete.
    ~GuardedManager(){if(intact())manager->~CampAndStandDataMgr_T();}
};
static std::string makeTable(const std::vector<int>& ids,int camps=16){
    std::ostringstream out;
    for(int col=0;col<=camps;++col)out<<(col?"\tINT":"INT");out<<"\n# synthetic camp relation fixture\n";
    for(int id:ids){out<<id;for(int col=0;col<camps;++col)out<<'\t'<<(id==col?1:0);out<<'\n';}
    return out.str();
}
static void load(DBC::DBCFile& db,const std::string& text){require(db.OpenFromMemory(text.data(),text.data()+text.size(),"synthetic-camp"),"DBC did not load fixture");}
int main(int argc,char** argv){
    setvbuf(stdout,nullptr,_IONBF,0);
    if(argc!=3){std::fprintf(stderr,"usage: camp_tests canonical-binary stage-text\n");return 2;}
    DBC::DBCFile modern(0),staged(0);
    test("modern binary and stage text contain the same complete camp matrix",[&]{
        require(modern.OpenFromTXT(argv[1])&&staged.OpenFromTXT(argv[2]),"current data did not load");
        require(modern.GetRecordsNum()==16 && modern.GetFieldsNum()==17 && staged.GetRecordsNum()==16 && staged.GetFieldsNum()==17,"camp schema changed");
        for(int row=0;row<16;++row)for(int col=0;col<17;++col)require(modern.Search_Posistion(row,col)->iValue==staged.Search_Posistion(row,col)->iValue,"matrix mismatch");
    });
    test("all 16 current camp records fit inside the manager canary",[&]{
        GuardedManager guard;require(guard.manager->InitFromDBMemory(&staged),"manager init failed");require(guard.intact(),"current rows overwrote manager boundary");
        require(guard.manager->Size()==16,"current rows lost");
        for(int id=0;id<16;++id)require(guard.manager->GetInstanceByID(id)!=nullptr,"current camp was silently skipped");
    });
    test("all 256 current relations reach native friend and enemy behavior",[&]{
        GuardedManager guard;guard.manager->InitFromDBMemory(&modern);
        for(int row=0;row<16;++row)for(int col=0;col<16;++col){
            const bool value=modern.Search_Posistion(row,col+1)->iValue!=0;
            require((guard.manager->GetInstanceByID(row)->StandByCampID(col)!=FALSE)==value,"relation changed");
            require(CalcRelationType(row,col,guard.manager)==(value?RELATION_FRIEND:RELATION_ENEMY),"native relation result changed");
        }
    });
    // CYS-TESTRED 19/09: "invalid" means "outside CampStandRecord_T::MAX_SIZE", never a literal 16. Commit
    // 3bbd7759 (14/09, CS2) widened MAX_ID 15 -> 63 so the camp matrix matches CY 3.71's 64-row ReputationTable;
    // ids 16 and 17 became LEGAL that day and these two cases turned red with no product defect behind them
    // (the suite had no caller, so nobody saw it). Reading the bound from the header instead of retyping it keeps
    // the case alive the next time the ceiling moves. The ceiling is pinned from below by the case that follows,
    // so narrowing MAX_ID again is still caught here rather than silently accepted.
    for(int invalid:std::vector<int>{-1,CampStandRecord_T::MAX_SIZE,CampStandRecord_T::MAX_SIZE+1,(std::numeric_limits<int>::max)()}){
        std::string label="memory loader skips invalid camp ID "+std::to_string(invalid)+" without changing guards";
        test(label.c_str(),[&,invalid]{
            DBC::DBCFile db(0);load(db,makeTable({invalid,15}));GuardedManager guard;
            require(guard.manager->InitFromDBMemory(&db),"memory loader failed");
            require(guard.intact(),"invalid ID wrote outside manager");
            require(!guard.manager->GetInstanceByID(invalid),"invalid ID became reachable");
            require(guard.manager->GetInstanceByID(15)&&guard.manager->GetInstanceByID(15)->StandByCampID(15),"last valid ID lost");
        });
    }
    // CYS-TESTRED 19/09: the other half of the bound, and it needs an INDEPENDENT anchor. Measured, not assumed:
    // rebuilding this suite against a MAX_ID=15 header leaves every derived case green (sizeof_record 260 -> 68,
    // still 12/12) because the loop above then asks about 16/17 instead of 64/65 - a bound that defines its own
    // expectation cannot catch the bound moving. So the ceiling is pinned to the source it was taken FROM:
    // CY 3.71 keeps 64 camp rows in ReputationTable.txt (CY Game.exe FUN_140784410 checks the id against 0..0x3f,
    // matrix 0x14103e0b8 = 64 rows x 0x120), which is what commit 3bbd7759 (14/09, CS2) implemented. Change this
    // number only together with new evidence from CY, never to make a build pass.
    test("the camp ceiling still matches CY 3.71 and its highest ID is reachable",[&]{
        require(CampStandRecord_T::MAX_SIZE==64,"camp ceiling no longer matches CY 3.71 ReputationTable (64 rows)");
        const int last=CampStandRecord_T::MAX_ID;
        DBC::DBCFile db(0);load(db,makeTable({last,0}));GuardedManager guard;
        require(guard.manager->InitFromDBMemory(&db),"memory loader failed");
        require(guard.intact(),"highest legal ID wrote outside manager");
        require(guard.manager->GetInstanceByID(last),"highest legal camp ID was skipped as out of range");
        require(guard.manager->GetInstanceByID(0)&&guard.manager->GetInstanceByID(0)->StandByCampID(0),"first camp lost");
    });
    test("legacy 12-camp table keeps existing relations and clears absent columns",[&]{
        std::vector<int> ids;for(int id=0;id<12;++id)ids.push_back(id);
        DBC::DBCFile db(0);load(db,makeTable(ids,12));GuardedManager guard;guard.manager->InitFromDBMemory(&db);
        require(guard.intact()&&!guard.manager->GetInstanceByID(12),"legacy table invented rows or damaged memory");
        for(int id=0;id<12;++id)for(int col=0;col<16;++col)require((guard.manager->GetInstanceByID(id)->StandByCampID(col)!=FALSE)==(id==col),"legacy relation changed");
    });
    // CYS-TESTRED 19/09: "wider than supported" is MAX_SIZE+1 relation columns, not a literal 17 - a 17-column
    // table is legal since 3bbd7759 (CampAndStand.cpp:43 `columns > MAX_SIZE`). 67 columns is deliberately
    // avoided: fields==68 selects the CY ReputationTable layout (CampAndStand.cpp:40), a different branch.
    test("record rejects an unsupported wider relation table before writing",[&]{
        const int tooWide=CampStandRecord_T::MAX_SIZE+1;
        DBC::DBCFile db(0);load(db,makeTable({0},tooWide));CampStandRecord_T record;
        require(!record.InitFromDB(&db,0)&&!record.IsInited(),"wide relation schema silently truncated");
        DBC::DBCFile fits(0);load(fits,makeTable({0},CampStandRecord_T::MAX_SIZE));CampStandRecord_T widest;
        require(widest.InitFromDB(&fits,0)&&widest.IsInited(),"a table exactly as wide as MAX_SIZE was rejected");
    });
    test("record validates null database and row bounds",[&]{
        CampStandRecord_T record;require(!record.InitFromDB(nullptr,0),"null database accepted");
        require(!record.InitFromDB(&modern,-1)&&!record.InitFromDB(&modern,16),"invalid row accepted");
        require(!record.IsInited(),"invalid row marked initialized");
    });
    test("file loader and memory loader use identical native relations",[&]{
        GuardedManager guard;require(guard.manager->InitFromDB(argv[1]),"file manager init failed");
        require(guard.intact(),"file loader crossed allocation");
        for(int id=0;id<16;++id)require(guard.manager->GetInstanceByID(id)!=nullptr,"file loader dropped a current ID");
    });
    std::printf("RESULT passed=%d failed=%d sizeof_record=%zu sizeof_manager=%zu\n",passed,failed,sizeof(CampStandRecord_T),sizeof(CampAndStandDataMgr_T));
    return failed?1:0;
}
