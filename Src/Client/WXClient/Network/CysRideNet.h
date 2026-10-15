#pragma once
// CYS-RIDE: mounts (坐骑) on the skynet CY protocol. Game.exe main thread only.
//
// What this module owns (ride-core, 17/09/2026):
//   * CGCharAutoRide (636) - "mount up / dismount" request; body is a single u32 flag.
//   * GCCharAutoRide (63)  - the server's acknowledgement; body is the same u32 flag echoed back.
//   * The client-side mount state derived from those two plus the ride_model already applied by
//     CysModernHandlers (GCCharBaseAttrib flags[1] & 0x20, GCDetailAttrib flags[8] & 0x08 -> Set_MountID).
//
// IMPORTANT - what the two packets do NOT do. GCCharAutoRide carries no mount id and no model: it is only an
// acknowledgement that the server finished the mount sequence. The visible mount always arrives separately as
// ride_model on GCCharBaseAttrib / GCDetailAttrib, which CysModernHandlers already feeds into
// CCharacterData::Set_MountID -> CObject_Character::UpdateMountModel. So this module must never try to set the
// model itself; doing so would fight the attribute path.
//
// Server behaviour (read-only clone /home/ubuntu/cys-test-20260913, verified 17/09/2026):
//   msgagent.lua:1525  request:CGCharAutoRide -> scene "char_auto_ride"(obj, flag)
//   scenecore.lua:6172 scenecore:char_auto_ride(who, flag):
//       1. not a human obj                       -> silently returns, NO reply
//       2. already mounted (ride_model valid)     -> replies GCCharAutoRide(flag) at once
//       3. get_ride() == INVALID                  -> silently returns, NO reply   <-- the usual failure
//       4. otherwise push_command_use_skill(21, self, ...) and poll every 10 ticks, at most 15 times, for
//          ride_model to become valid; replies GCCharAutoRide(flag) when it does, otherwise gives up silently.
//   Skill 21 is 标准聚气乘骑 in configs/SkillData_V1.txt, described as "召唤坐骑 ... 需要装备坐骑"
//   (summon the mount; REQUIRES AN EQUIPPED MOUNT - define.HUMAN_EQUIP.HEQUIP_RIDER = 8).
//   The "selected" mount of case 3 is the db attrib "ride", written by human:set_ride, which is reached from
//   scenecore.lua:3761 - the exterior/appearance path CGExteriorRequest(1027) type 7 with option.unknow_1 == 3.
//   => three of the four outcomes send NOTHING back, so a request that never answers is normal, not a bug.
//      RequestAutoRide therefore records why it asked and Pending() stays true until a reply or the timeout.
//
// High flight uses native CY CGFlyOperation2242 (object u32, operation u8),
// CharMount[19] eligibility and each scene's .fly surface. Column22 is only the
// separate low hover offset. CGCharFly/GCCharFly1225/1262 remain qinggong.
// The private server publishes flight/AOI state via GCUICommand990030 because
// its inherited base-attribute packet lacks the CY3.71 flight-state extension.

#include <cstdint>

namespace pg { class Packet; }

namespace CysRideNet
{
    // A world packet of this module (stashed by CysModernHandlers until the scene is ready).
    bool IsWorldPacket(uint16_t id);

    // Returns true when the packet was consumed (GCCharAutoRide).
    bool Dispatch(const pg::Packet& packet);

    // Send CGCharAutoRide. flag is echoed back by the server untouched; CY uses 1 to mount. Returns false when
    // nothing was sent (no session, or a request is still pending).
    bool RequestAutoRide(uint32_t flag = 1);
    // CY high flight, Ctrl + left click: native CGFlyOperation2242, operation0/1.
    bool ToggleFlight();
    bool FlightRequestPending();
    unsigned FlightReplies();

    // True between RequestAutoRide and either the GCCharAutoRide reply or the give-up deadline. The server stays
    // silent in the "no mount selected" and "not a human" cases, so this is the only way to notice them.
    bool Pending();

    // Call once per frame (CysModernHandlers::Pump) to expire a pending request. Cheap when nothing is pending.
    void Tick();

    // Mount id currently applied to the own character (CharMount row id), or -1.
    int MountID();
    // Flight altitude of that mount in game units (CharMount col 22); 0 = a ground mount or no mount.
    float FlyHeight();
    // Authoritative high-flight state, including takeoff and landing.
    bool IsFlying();

    struct Counters
    {
        unsigned requestsSent;      // CGCharAutoRide written to the wire
        unsigned requestsRefused;   // RequestAutoRide returned false
        unsigned repliesOk;         // GCCharAutoRide received
        unsigned repliesUnmatched;  // GCCharAutoRide with no request pending (server-initiated)
        unsigned timeouts;          // pending request expired with no reply
        unsigned mountChanges;      // observed Set_MountID transitions
        unsigned flyMountChanges;   // of which the new mount has col 22 > 0
    };
    Counters Get();

    // CObject_Character::UpdateMountModel reports every applied mount here (id, CharMount col 22).
    // -1 / 0 means "dismounted". Safe to call before any session exists.
    void NoteMountApplied(int mountId, float flyHeight);
}
