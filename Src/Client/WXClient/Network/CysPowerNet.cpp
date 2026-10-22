#include "StdAfx.h"
#include "CysPowerNet.h"

#if defined(CYS_HAVE_NETCORE)



















#include "CysModernGame.h"
#include "CysHost_Power.h"
#include "CysHost_Ride.h"      // CYS-RIDE probe (CYS_RIDE_PROBE)
#include "CysRideNet.h"
#include "..\Script\GMScriptSystem.h"
#include "..\DBC\GMDataBase.h"
#include "..\Procedure\GameProcedure.h"
#include "..\Object\ObjectManager.h"
#include "..\Object\Character\Obj_PlayerMySelf.h"
#include "..\DataPool\GMDP_CharacterData.h"
#include "..\Event\GMEventSystem.h"
#include "PgPackets_misc.h"
#include "TDUtil.h"
#include <cstdarg>
#include <cstdlib>

namespace
{
    const int CYS_XIULIAN_SLOTS = 15;        // GCDetailXiulianList carries exactly 11 scrolls
    const int CYS_XIULIAN_MIJI_ROWS = 15;    // XiuLianMiJi.txt
    const int CYS_XIULIAN_BOOK_ROWS = 3;     // XiuLianBook.txt
    const int CYS_XIULIAN_LEVELS = 151;      // BOOKLEVEL 0..150 per BOOKID (0x97 in B)

    CysPowerNet::Counters g_counters = {};
    int g_level[CYS_XIULIAN_SLOTS];
    int g_upper[CYS_XIULIAN_SLOTS];
    bool g_have = false;
    uint32_t g_gongli=0;
    unsigned g_logs = 0;

    // The three CY tables, opened once through CDataBase::Util_OpenDBCFromTxt (the same path GMSoundSystem uses
    // for SoundUI.txt): they are not part of the 0.85 DBC enum, so they are never registered in CDataBaseSystem.
    // The DBC ids are only labels here; 0xf9 is the id B uses for XiuLianDetail (s_pXiuLianDetailDBC).
    DBC::DBCFile* g_miji = NULL;
    DBC::DBCFile* g_book = NULL;
    DBC::DBCFile* g_detail = NULL;
    bool g_tablesTried = false;

    void PowerLog(const char* fmt, ...)
    {
        if (g_logs++ >= 64) return;
        char text[512] = {};
        va_list args; va_start(args, fmt);
        _vsnprintf(text, sizeof(text) - 1, fmt, args);
        va_end(args);
        TDU_Log("CYS power: %s", text);
    }

    CObject_PlayerMySelf* Self()
    {
        return CObjectManager::GetMe() ? CObjectManager::GetMe()->GetMySelf() : NULL;
    }

    DBC::DBCFile* Open(const char* file, UINT id, int wantCols, int wantRows)
    {
        DBC::DBCFile* dbc = new DBC::DBCFile(id);
        if (!CDataBase::Util_OpenDBCFromTxt(file, dbc))
        {
            PowerLog("%s NOT FOUND (ConfigFolder)", file);
            delete dbc;
            return NULL;
        }
        // A table with a different shape is a different table: answer nothing rather than a wrong number.
        if (dbc->GetFieldsNum() < wantCols || dbc->GetRecordsNum() < wantRows)
        {
            PowerLog("%s shape %dx%d, expected at least %dx%d - table ignored",
                     file, dbc->GetFieldsNum(), dbc->GetRecordsNum(), wantCols, wantRows);
            delete dbc;
            return NULL;
        }
        PowerLog("%s opened %dx%d", file, dbc->GetFieldsNum(), dbc->GetRecordsNum());
        return dbc;
    }

    void LoadTables()
    {
        if (g_tablesTried) return;
        g_tablesTried = true;
        g_miji = Open("XiuLianMiJi.txt", 0xfa, 5, CYS_XIULIAN_MIJI_ROWS);
        g_book = Open("XiuLianBook.txt", 0xfb, 4, CYS_XIULIAN_BOOK_ROWS);
        // 3 key columns + 4 columns per scroll; CY ships 15 scroll groups (63), the server copy only 11 (47).
        g_detail = Open("XiuLianDetail.txt", 0xf9, 3 + 4 * CYS_XIULIAN_SLOTS, CYS_XIULIAN_LEVELS);
    }

    const char* StringAt(DBC::DBCFile* dbc, int row, int col)
    {
        if (!dbc || row < 0 || row >= dbc->GetRecordsNum() || col >= dbc->GetFieldsNum()) return NULL;
        const DBC::DBCFile::FIELD* f = dbc->Search_Posistion(row, col);
        return f ? f->pString : NULL;
    }
}

bool CysPowerNet::Dispatch(const pg::Packet& packet)
{
    if (packet.packetId() != pg::GCDetailXiulianList::PACKET_ID) return false;
    const pg::GCDetailXiulianList& p = static_cast<const pg::GCDetailXiulianList&>(packet);
    // misc.lua:1017/1021 writes the 11 levels first and the 11 upper limits after them (bos codec of packets.yaml
    // id 1014); human.lua get_xiulian_list is the list of {level, upper_limit}.
    char list[160] = {};
    int used = 0;
    for (int i = 0; i < CYS_XIULIAN_SLOTS; ++i)
    {
        g_level[i] = static_cast<int>(p.xiulian[i]);
        g_upper[i] = static_cast<int>(p.xiulian_2[i]);
        if (used < 140) used += _snprintf(list + used, sizeof(list) - used - 1, "%s%d/%d", i ? "," : "", g_level[i], g_upper[i]);
    }
    g_have = true;
    ++g_counters.xiulianLists;
    PowerLog("GCDetailXiulianList %s", list);
    if (CEventSystem::GetMe()) CEventSystem::GetMe()->PushEventByName("UNIT_XIULIAN",{});
    // CYS-POWER probe (CYS_POWER_PROBE=1, evidence runs only): the cultivation list arrives on entering the world,
    // which is exactly when the window can be opened. Logs the seven values Xiulian.lua reads for scroll 0 and then
    // pushes the open event once, so an automated GUI turn exercises the real Lua path without a mouse.
    if (g_counters.xiulianLists == 1)
    {
        char probe[8] = {};
        ::GetEnvironmentVariableA("CYS_POWER_PROBE", probe, sizeof(probe));
        if (probe[0] == '1')
        {
            const int level = XiulianLevel(0);
            PowerLog("probe miji0: Name=%s Level=%d MaxLevel=%d JingJie=%d UpLevelNeedExp=%d UpLevelNeedMoney=%d menpai=%d",
                     MiJiText(0, 0) ? MiJiText(0, 0) : "(nil)", level, XiulianUpperLimit(0), XiulianUpperLimit(0) / 10,
                     UpLevelNeed(0, level, 0), UpLevelNeed(0, level, 1),
                     Self() ? Self()->GetCharacterData()->Get_MenPai() : -1);
            PowerLog("probe book0: Name=%s", BookText(0, 0) ? BookText(0, 0) : "(nil)");
            if (CEventSystem::GetMe()) { CEventSystem::GetMe()->PushEvent(GE_OPEN_XIULIAN_PAGE); PowerLog("probe pushed OPEN_XIULIAN_PAGE"); }
        }
        // CYS-RIDE probe (CYS_RIDE_PROBE=<index>, evidence runs only). This handler is the only hook this agent
        // owns that fires exactly once on entering the world, so the mount path is exercised from here rather
        // than by adding a second trigger to a file another agent owns. It selects a mount
        // (CGExteriorRequest type 7 / category 3) and asks to mount up (CGCharAutoRide), then leaves the
        // verdict to CysRideNet's own log lines and counters.
        char ride[8] = {};
        ::GetEnvironmentVariableA("CYS_RIDE_PROBE", ride, sizeof(ride));
        if (ride[0] >= '0' && ride[0] <= '9')
        {
            const int index = atoi(ride);
            if (CEventSystem::GetMe()) CEventSystem::GetMe()->PushEvent(GE_OPEN_RIDE_PAGE);
            const bool selected = CysHostRide::ProbeSelectRide(index);
            const bool asked = CysRideNet::RequestAutoRide(1);
            PowerLog("ride probe: index=%d select_sent=%d auto_ride_sent=%d mount_id=%d",
                     index, selected ? 1 : 0, asked ? 1 : 0, CysRideNet::MountID());
        }
    }
    return true;
}

int CysPowerNet::XiulianLevel(int miji)
{
    if (!g_have || miji < 0 || miji >= CYS_XIULIAN_SLOTS) return -1;
    return g_level[miji];
}

int CysPowerNet::XiulianUpperLimit(int miji)
{
    if (!g_have || miji < 0 || miji >= CYS_XIULIAN_SLOTS) return -1;
    return g_upper[miji];
}

bool CysPowerNet::HaveXiulian() { return g_have; }

const char* CysPowerNet::MiJiText(int miji, int part)
{
    LoadTables();
    if (miji < 0 || miji >= CYS_XIULIAN_MIJI_ROWS) return NULL;
    return StringAt(g_miji, miji, part == 0 ? 2 : part == 2 ? 3 : 4);   // 0 id, 1 bookId, 2 name, 3 icon, 4 description
}

const char* CysPowerNet::BookText(int book, int part)
{
    LoadTables();
    if (book < 0 || book >= CYS_XIULIAN_BOOK_ROWS) return NULL;
    return StringAt(g_book, book, part == 0 ? 1 : part == 2 ? 2 : 3);   // 0 id, 1 name, 2 icon, 3 description
}

int CysPowerNet::UpLevelNeed(int miji, int level, int what)
{
    LoadTables();
    if (!g_detail || miji < 0 || miji >= CYS_XIULIAN_SLOTS) return 0;
    if (level < 0 || level + 1 > CYS_XIULIAN_LEVELS - 1) return 0;   // B: no row past BOOKLEVEL 150
    CObject_PlayerMySelf* self = Self();
    const int menpai = self ? self->GetCharacterData()->Get_MenPai() : -1;
    if (menpai < 0) return 0;
    // B computes the Index column: level + menpai * 151 + 2 (the next level, Index being 1-based).
    // Search_Index_EQU returns the start of the record, but on x64 a record is NOT an array of FIELD (a FIELD is
    // 8 bytes because of the string pointer, INT columns sit in 4-byte slots - see TLBB_DBC.h). So the cell is
    // read with Search_Posistion, whose row number is Index - 1: every one of the 2416 rows of the table satisfies
    // Index == row + 1 (scripts/30-dbc.py), and the row is re-checked here before its numbers are used.
    const int index = level + menpai * CYS_XIULIAN_LEVELS + 2;
    const int row = index - 1;
    const int col = 3 + miji * 4 + (what == 0 ? 0 : 1);   // 经验 then 金币 of that scroll
    if (row < 0 || row >= g_detail->GetRecordsNum() || col >= g_detail->GetFieldsNum()) return 0;
    const DBC::DBCFile::FIELD* key = g_detail->Search_Posistion(row, 0);
    if (!key || key->iValue != index)
    {
        PowerLog("XiuLianDetail row %d has Index %d, expected %d - no cost shown",
                 row, key ? key->iValue : -1, index);
        return 0;
    }
    const DBC::DBCFile::FIELD* cell = g_detail->Search_Posistion(row, col);
    return cell ? cell->iValue : 0;
}

CysPowerNet::Counters CysPowerNet::Get() { return g_counters; }
uint32_t CysPowerNet::Gongli(){return g_gongli;}
void CysPowerNet::OnGongli(uint32_t value){g_gongli=value;if(CEventSystem::GetMe())CEventSystem::GetMe()->PushEventByName("UINT_POWER",{});}

void CysPowerNet::RegisterHost()
{
    CScriptSystem* scripts = CScriptSystem::GetMe();
    if (!scripts || !scripts->GetLuaState()) return;
    g_have=false;g_counters={};g_gongli=0;
    for(int i=0;i<CYS_XIULIAN_SLOTS;++i){g_level[i]=0;g_upper[i]=0;}
    CysHostPower::Services services;
    services.bookActive=[](int book){return g_have && book>=0 && book<2;};
    services.xiulianLevel = [](int miji) { return CysPowerNet::XiulianLevel(miji); };
    services.xiulianUpperLimit = [](int miji) { return CysPowerNet::XiulianUpperLimit(miji); };
    services.mijiText = [](int miji, int part) { return CysPowerNet::MiJiText(miji, part); };
    services.bookText = [](int book, int part) { return CysPowerNet::BookText(book, part); };
    services.upLevelNeed = [](int miji, int level, int what) { return CysPowerNet::UpLevelNeed(miji, level, what); };
    services.openXiulianPage = []() -> bool {
        CEventSystem* events = CEventSystem::GetMe();
        if (!events) return false;
        events->PushEvent(GE_OPEN_XIULIAN_PAGE);
        return true;
    };
    const int n = CysHostPower::Register(scripts->GetLuaState(), services);
    PowerLog("host functions registered=%d", n);
}

#else
uint32_t CysPowerNet::Gongli(){return 0;}
void CysPowerNet::OnGongli(uint32_t){}
bool CysPowerNet::Dispatch(const pg::Packet&) { return false; }
int CysPowerNet::XiulianLevel(int) { return -1; }
int CysPowerNet::XiulianUpperLimit(int) { return -1; }
bool CysPowerNet::HaveXiulian() { return false; }
const char* CysPowerNet::MiJiText(int, int) { return NULL; }
const char* CysPowerNet::BookText(int, int) { return NULL; }
int CysPowerNet::UpLevelNeed(int, int, int) { return 0; }
CysPowerNet::Counters CysPowerNet::Get() { Counters c = {}; return c; }
void CysPowerNet::RegisterHost() {}
#endif
