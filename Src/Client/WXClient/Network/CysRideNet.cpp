#include "StdAfx.h"
#include "CysRideNet.h"

#if defined(CYS_HAVE_NETCORE)
// CYS-RIDE: mounts on the CY protocol. Every number in this file was read from the server clone, the tables or
// the CY binary - none of it is guessed. The chain is written out in CysRideNet.h; the short version:
//   * CGCharAutoRide = 636, GCCharAutoRide = 63, both bodies exactly one u32 "flag"
//     (Src/Shared/ProtocolGen/PgIds.h, PgPackets_core.h/.cpp - 4..4 bytes, confidence high).
//   * scenecore.lua:6172 char_auto_ride answers on only two of its four paths, so silence is an expected
//     outcome and the timeout below is what turns it into a visible counter instead of a hang.
//   * The mount MODEL never travels on these packets; it arrives as ride_model on GCCharBaseAttrib /
//     GCDetailAttrib, which CysModernHandlers already applies. This module only tracks and requests.
#include "CysModernGame.h"
#include "PgPackets_core.h"
#include "CysMountFlightPacket.h"
#include "../Object/ObjectManager.h"
#include "../Object/Character/Obj_PlayerMySelf.h"
#include "../Object/Character/AI/GMAI_Base.h"
#include "../DataPool/GMDP_CharacterData.h"
#include "../World/WorldManager.h"
#include "../World/Scene.h"
#include "../World/CysNavMesh.h"
#include "../Event/GMEventSystem.h"
#include "../Global.h"
#include "TDTimeSystem.h"
#include "..\Procedure\GameProcedure.h"
#include "TDUtil.h"

namespace
{
    // scenecore.lua waits at most 15 retries of skynet.timeout(10) = 15 * 100 ms before giving up, plus the
    // round trip and the skill's own 聚气 (channel) time. 6 s leaves a wide margin and still expires inside a
    // human-noticeable window instead of pending forever.
    const unsigned CYS_RIDE_REQUEST_TIMEOUT_MS = 6000;

    CysRideNet::Counters g_counters = {};
    bool g_pending = false;
    unsigned g_pendingSince = 0;
    uint32_t g_pendingFlag = 0;
    int g_mountId = -1;
    float g_flyHeight = 0.0f;
    unsigned g_logs = 0;
    DWORD g_flightSent=0;
    bool g_flightPending=false;
    unsigned g_flightReplies=0;

    void RideLog(const char* fmt, ...)
    {
        if (g_logs++ >= 64) return;
        char text[512] = {};
        va_list args; va_start(args, fmt);
        _vsnprintf(text, sizeof(text) - 1, fmt, args);
        va_end(args);
        TDU_Log("CYS ride: %s", text);
    }

    unsigned NowMs()
    {
        return CGameProcedure::s_pTimeSystem ? CGameProcedure::s_pTimeSystem->GetTimeNow() : 0;
    }
}

bool CysRideNet::IsWorldPacket(uint16_t id)
{
    return id == pg::GCCharAutoRide::PACKET_ID;
}

bool CysRideNet::Dispatch(const pg::Packet& packet)
{
    if(packet.packetId()==pg::GCUICommand::PACKET_ID) {
        const auto& p=static_cast<const pg::GCUICommand&>(packet);
        if(p.m_nUIIndex!=990030) return false;
        const auto& v=p.m_Param_m_aIntValue;
        if(v.size()<4 || v[1]<0 || v[1]>3 || v[3]<0 || v[3]>10000) return true;
        auto objects=CObjectManager::GetMe();
        auto obj=objects?static_cast<CObject*>(objects->FindServerObject(v[0])):NULL;
        if(obj && g_theKernel.IsKindOf(obj->GetClass(),GETCLASS(CObject_Character))) {
            auto ch=static_cast<CObject_Character*>(obj);
            if(v[1]==0 || (ch->GetCharacterData()->Get_MountID()==v[2] && ch->CysCanMountFly())) ch->CysSetMountFlight(v[1],v[3]);
            if(obj==objects->GetMySelf()) {
                ++g_flightReplies;
                g_flightPending=false;
                if(!p.m_Param_m_aStrValue.empty()) CEventSystem::GetMe()->PushEvent(GE_NEW_DEBUGMESSAGE,p.m_Param_m_aStrValue.c_str());
            }
        }
        return true;
    }
    if (packet.packetId() != pg::GCCharAutoRide::PACKET_ID) return false;
    const pg::GCCharAutoRide& reply = static_cast<const pg::GCCharAutoRide&>(packet);

    if (g_pending)
    {
        ++g_counters.repliesOk;
        const unsigned now = NowMs();
        RideLog("GCCharAutoRide flag=%u after %u ms (mount=%d fly=%.1f)",
                reply.flag, now >= g_pendingSince ? now - g_pendingSince : 0u, g_mountId, g_flyHeight);
        g_pending = false;
    }
    else
    {
        // The server also replies to a request it never saw us make (case 2 of char_auto_ride, or a GM/script
        // mount). Counted separately so a live capture can tell the two apart.
        ++g_counters.repliesUnmatched;
        RideLog("GCCharAutoRide flag=%u with no request pending (mount=%d)", reply.flag, g_mountId);
    }
    return true;
}

bool CysRideNet::RequestAutoRide(uint32_t flag)
{
    auto self=CObjectManager::GetMe()?CObjectManager::GetMe()->GetMySelf():NULL;
    if(self && self->CysMountFlightState()) {
        CEventSystem::GetMe()->PushEvent(GE_NEW_DEBUGMESSAGE,u8"Hãy hạ cánh bằng Ctrl + chuột trái trước khi xuống thú cưỡi.");
        return false;
    }
    if (g_pending)
    {
        ++g_counters.requestsRefused;
        RideLog("RequestAutoRide refused: a request is still pending");
        return false;
    }

    pg::CGCharAutoRide* request = new pg::CGCharAutoRide;
    request->flag = flag;
    if (!CysModernGame::SendModern(std::unique_ptr<pg::Packet>(request)))
    {
        ++g_counters.requestsRefused;
        RideLog("RequestAutoRide refused: no modern session");
        return false;
    }

    g_pending = true;
    g_pendingFlag = flag;
    g_pendingSince = NowMs();
    ++g_counters.requestsSent;
    RideLog("CGCharAutoRide flag=%u sent (mount=%d)", flag, g_mountId);
    return true;
}

bool CysRideNet::Pending()
{
    return g_pending;
}

void CysRideNet::Tick()
{
    if (!g_pending) return;
    const unsigned now = NowMs();
    if (now < g_pendingSince) { g_pendingSince = now; return; }   // clock went backwards (scene change)
    if (now - g_pendingSince < CYS_RIDE_REQUEST_TIMEOUT_MS) return;

    g_pending = false;
    ++g_counters.timeouts;
    // Reaching here is the normal shape of the three silent server paths. The most common by far is "no mount
    // selected": char_auto_ride returns before the skill when get_ride() == INVALID, and the mount is selected
    // through CGExteriorRequest(1027) type 7 / option.unknow_1 == 3, not through this packet.
    RideLog("CGCharAutoRide flag=%u got no reply in %u ms - server path was silent "
            "(no mount selected via CGExteriorRequest type 7, no equipped mount for skill 21, or not a human obj)",
            g_pendingFlag, CYS_RIDE_REQUEST_TIMEOUT_MS);
}

int CysRideNet::MountID() { return g_mountId; }
float CysRideNet::FlyHeight() { return g_flyHeight; }
bool CysRideNet::IsFlying() { auto s=CObjectManager::GetMe()?CObjectManager::GetMe()->GetMySelf():NULL;return s && s->CysMountFlightState()!=0; }
bool CysRideNet::FlightRequestPending() { return g_flightPending && GetTickCount()-g_flightSent<5000; }
unsigned CysRideNet::FlightReplies() { return g_flightReplies; }
bool CysRideNet::ToggleFlight()
{
    auto self=CObjectManager::GetMe()?CObjectManager::GetMe()->GetMySelf():NULL;
    if(!self || !CysModernGame::IsInWorld()) return false;
    auto data=self->GetCharacterData();
    const char* error=NULL;
    if(!self->CysCanMountFly()) error=u8"Thú cưỡi này không hỗ trợ bay lên cao.";
    else if(self->CysMountFlightChanging() || FlightRequestPending() || (g_flightSent && GetTickCount()-g_flightSent<2000)) return false;
    else if(data->IsDie() || data->IsLimitMove() || data->Get_IsInStall() || data->Get_TeamFollowFlag() || self->CysIsLeaping() || self->GetbJumping()) error=u8"Không thể cất cánh hoặc hạ cánh trong trạng thái hiện tại.";
    auto scene=static_cast<CScene*>(CWorldManager::GetMe()->GetActiveScene());
    fVector2 pos(self->GetPosition().x,self->GetPosition().z);float y=0;
    if(!error && (!scene || !scene->FlightHeight(pos,y))) error=u8"Bản đồ này không hỗ trợ thú cưỡi bay cao.";
    if(!error && self->CysMountFlightState()==1 && (!scene->GetNavMesh() || scene->GetNavMesh()->IsBlocked(pos.x,pos.y))) error=u8"Hãy di chuyển tới nơi có thể đứng trên mặt đất để hạ cánh.";
    if(error) { CEventSystem::GetMe()->PushEvent(GE_NEW_DEBUGMESSAGE,error);return false; }
    std::unique_ptr<pg::CGFlyOperation> p(new pg::CGFlyOperation);
    p->object=self->GetServerID();p->operation=self->CysMountFlightState()==1?1:0;
    TDU_Log("CYS-MOUNT-FLIGHT: request obj=%u op=%u mount=%d",p->object,p->operation,data->Get_MountID());
    if(!CysModernGame::SendModern(std::move(p))) return false;
    self->CharacterLogic_GetAI()->OnAIStopped();
    g_flightPending=true;g_flightSent=GetTickCount();return true;
}
CysRideNet::Counters CysRideNet::Get() { return g_counters; }

void CysRideNet::NoteMountApplied(int mountId, float flyHeight)
{
    if (mountId == g_mountId && flyHeight == g_flyHeight) return;
    const int oldMount = g_mountId;
    g_mountId = mountId;
    g_flyHeight = flyHeight;
    if(mountId<0) g_flightPending=false;
    auto self=CObjectManager::GetMe()?CObjectManager::GetMe()->GetMySelf():NULL;
    if(oldMount!=mountId && self && self->CysCanMountFly())
        CEventSystem::GetMe()->PushEvent(GE_NEW_DEBUGMESSAGE,u8"Thú cưỡi có thể bay cao: giữ Ctrl và bấm chuột trái xuống nền bản đồ để cất cánh/hạ cánh.");
    ++g_counters.mountChanges;
    if (flyHeight > 0.0f) ++g_counters.flyMountChanges;
    RideLog("mount %d -> %d, fly height %.1f%s", oldMount, mountId, flyHeight,
            flyHeight > 0.0f ? " (FLYING)" : "");
}

#else
bool CysRideNet::IsWorldPacket(uint16_t) { return false; }
bool CysRideNet::Dispatch(const pg::Packet&) { return false; }
bool CysRideNet::RequestAutoRide(uint32_t) { return false; }
bool CysRideNet::Pending() { return false; }
void CysRideNet::Tick() {}
int CysRideNet::MountID() { return -1; }
float CysRideNet::FlyHeight() { return 0.0f; }
bool CysRideNet::IsFlying() { return false; }
bool CysRideNet::ToggleFlight() { return false; }
bool CysRideNet::FlightRequestPending() { return false; }
unsigned CysRideNet::FlightReplies() { return 0; }
CysRideNet::Counters CysRideNet::Get() { Counters c = {}; return c; }
void CysRideNet::NoteMountApplied(int, float) {}
#endif
