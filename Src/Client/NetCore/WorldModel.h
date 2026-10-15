#pragma once
// Pure main-thread view of one modern world session, built from pumped GameClient
// events. Used by tests (resulting client state) and by Game.exe diagnostics.
// No sockets, no engine types.
// CYS-CORE: core loop (chat, target, skill, damage, item box, bag, skill list, death).

#include "PgRuntime.h"
#include "PgStructs.h"
#include <cstdint>
#include <map>
#include <memory>
#include <string>
#include <vector>

namespace pg { class GCRetChangeScene; class CGEnterScene; class CGCharMove; }

namespace cys { namespace net {

class WorldModel {
public:
    enum class Kind : uint8_t { Player, Monster, Pet };
    struct Object {
        Kind kind = Kind::Monster;
        float x = 0, y = 0, dir = 0, speed = 0;
        int32_t handle = 0;
        uint32_t moves = 0;
        // CYS-CORE: from GCCharBaseAttrib (-1 = never received)
        int hpPercent = -1, level = -1;
        uint32_t model = 0;
        int16_t camp = -1;
        std::string name;
    };
    struct ItemBox { float x = 0, y = 0; int32_t owner = 0, monster = 0, type = 0; };
    struct BoxItem { pg::ItemGUID guid; int32_t itemIndex = 0; uint32_t count = 1; };
    struct BagItem { pg::ItemGUID guid; uint32_t itemIndex = 0; uint32_t count = 0; };
    struct Chat { uint8_t type = 0; uint32_t sourceId = 0; std::string source, text; };
    struct Pick { bool valid = false; uint8_t result = 0, bagIndex = 0; uint32_t boxId = 0; pg::ItemGUID guid; };
    struct Stats {
        uint32_t packets = 0, connects = 0, keyExchanges = 0, enters = 0, transfers = 0;
        uint32_t created = 0, refreshed = 0, deleted = 0, unknownDeletes = 0, foreignSceneDeletes = 0;
        uint32_t moves = 0, selfMoves = 0, unknownMoves = 0, moveResults = 0, moveFailures = 0;
        uint32_t baseAttribs = 0, notifyChangeScene = 0, retChangeScene = 0, quitAcks = 0, scriptCommands = 0;
        // CYS-CORE
        uint32_t chats = 0, selfChats = 0, skillSends = 0, selfSkillSends = 0, targetLists = 0, damages = 0;
        uint32_t damageDealt = 0, damageTaken = 0, hpUpdates = 0, itemBoxes = 0, boxLists = 0, pickResults = 0, picksOk = 0;
        uint32_t itemInfos = 0, bagLists = 0, skillLists = 0, playerDies = 0, playerRelives = 0, operateResults = 0;
        uint32_t levelUps = 0, detailAttribs = 0, cooldowns = 0, skillMisses = 0, targetDeaths = 0;
        // CYS-INV
        uint32_t equipLists = 0, charEquipments = 0, useEquips = 0, useEquipsOk = 0, unEquips = 0, unEquipsOk = 0;
        uint32_t shopLists = 0, soldLists = 0, shopBuys = 0, buysOk = 0, shopSells = 0, sellsOk = 0;
        uint32_t discards = 0, discardsOk = 0, swaps = 0, splits = 0, useItems = 0, scriptEventLists = 0;
        // CYS-SKILL
        uint32_t settingLists = 0, xinfaLists = 0, cooldownEntries = 0, studyResults = 0, studyInfos = 0, addSkills = 0;
        // CYS-QUEST
        uint32_t missionLists = 0, missionAdds = 0, missionModifies = 0, missionRemoves = 0, missionDoneFlags = 0;
        uint32_t missionInfos = 0, missionDemands = 0, missionContinues = 0, missionTips = 0, uiCommands = 0, npcTalks = 0;
        // CYS-TEAM
        uint32_t teamLists = 0, teamResults = 0, teamErrors = 0, teamAskInvites = 0, teamLeaderAskInvites = 0;
        uint32_t teamAskApplies = 0, teamOptionChanges = 0, teamMemberInfos = 0, teamFollowLists = 0;
        uint32_t expPackets = 0, teamChats = 0, tellChats = 0;
        // CYS-RIDE: GCCharAutoRide (63) acknowledgements. The server only answers on 2 of the 4 paths of
        // scenecore:char_auto_ride, so autoRideReplies < CGCharAutoRide sent is an expected outcome.
        uint32_t autoRideReplies = 0;
    };
    // CYS-QUEST: own mission list (GCMissionList/Add/Modify/Remove), the last mission dialogue of GCScriptCommand 1/3/4.
    struct Mission { int32_t id = -1, script = -1; uint8_t flags = 0; int32_t params[8] = {0, 0, 0, 0, 0, 0, 0, 0}; };
    struct MissionDialog {
        uint32_t cmd = 0; int32_t npc = -1, script = -1, mission = -1; uint32_t done = 0;
        uint32_t texts = 0, bonuses = 0; std::vector<std::pair<int32_t, int32_t>> bonus; // (flag, item_index/amount)
    };
    // CYS-SKILL: quick bar / game settings (GCRetSetting: 109 entries, index = SETTING_TYPE; K0..K9 = 2..11,
    // K10..K19 = 12..21; type 1 = skill template id, 3 = item table id), xinfa (心法), cooldown groups.
    struct Setting { uint8_t type = 0; uint32_t data = 0; };
    struct XinFa { uint32_t id = 0, level = 0; };
    struct Cooldown { int32_t id = 0; uint32_t total = 0, elapsed = 0; uint32_t updates = 0; };
    struct Study { bool valid = false; uint32_t money = 0, exp = 0; uint16_t xinfa = 0, level = 0; };
    // CYS-INV: shop window (GCShopMerchandiseList), script menu (GCScriptCommand 0/2), inventory results.
    struct Merchandise { uint32_t itemIndex = 0; int32_t perGroup = 1, max = -1; uint32_t price = 0; };
    struct Shop { bool open = false; int32_t npc = -1, shopId = -1, uniqueId = 0; uint8_t type = 0, yuanbao = 0, multi = 0; std::vector<Merchandise> goods; };
    struct ScriptEvent { int32_t index = 0, type = 0, scriptId = 0; std::string text; };
    struct Result { bool valid = false; int32_t code = -1; uint8_t point = 0, bagIndex = 255; int32_t itemIndex = 0, other = -1; };
    // CYS-TEAM: team roster (GCTeamList 1280), the pending invite (GCTeamAskInvite 966), the last
    // GCTeamResult 648 / GCTeamError 281 and the exp actually credited (GCDetailExp 1288).
    struct TeamMember { int32_t guid = 0, objId = 0; int16_t sceneId = 0; uint32_t level = 0; uint8_t menpai = 0; std::string name; };
    struct TeamInvite { bool valid = false; int32_t guid = 0; uint8_t memberSize = 0; std::string nickname; };
    struct TeamEvent { bool valid = false; int32_t returnType = -1, guid = 0, guidEx = 0; uint16_t teamId = 0; std::string name; };
    struct ExpGain { bool valid = false; uint32_t exp = 0, awardExp = 0, petExp = 0; };

    void reset();
    // One game socket connected (CGConnect sent). Objects survive until transfer.
    void onConnected(uint32_t generation);
    // GCRetChangeScene accepted: the old scene's objects are gone.
    void onTransfer();
    // Returns false with a fixed reason when the packet contradicts the session order.
    bool apply(const pg::Packet& packet, const char** error = nullptr);

    bool connected() const { return connected_; }
    bool inWorld() const { return inWorld_; }
    uint32_t generation() const { return generation_; }
    uint32_t myObjectId() const { return myObjectId_; }
    uint16_t sceneId() const { return sceneId_; }
    uint16_t clientRes() const { return clientRes_; }
    uint16_t connectScene() const { return connectScene_; }
    float myX() const { return myX_; }
    float myY() const { return myY_; }
    bool changeScenePending() const { return notifyPending_; }
    uint16_t notifyFrom() const { return notifyFrom_; }
    uint16_t notifyTo() const { return notifyTo_; }
    int32_t lastMoveResult() const { return lastMoveResult_; }
    const std::map<uint32_t, Object>& objects() const { return objects_; }
    const std::map<uint16_t, uint32_t>& packetCounts() const { return counts_; }
    const Stats& stats() const { return stats_; }

    // CYS-CORE: own state and core-loop views.
    int myHp() const { return myHp_; }
    int myMaxHp() const { return myMaxHp_; }
    int myLevel() const { return myLevel_; }
    int64_t myExp() const { return myExp_; }
    int32_t myGuid() const { return myGuid_; }
    int16_t myCamp() const { return myCamp_; }
    float mySpeed() const { return mySpeed_; }
    // CYS-RIDE: CharMount id the server last pushed for the own character (ride_model on
    // GCCharBaseAttrib flags[1] & 0x20 / GCDetailAttrib flags[8] & 0x08); -1 = not mounted.
    int32_t myRideModel() const { return myRideModel_; }
    unsigned rideModelChanges() const { return rideModelChanges_; }
    bool dead() const { return dead_; }
    int32_t lastOperateResult() const { return lastOperateResult_; }
    const std::vector<uint32_t>& skills() const { return skills_; }
    const std::map<uint32_t, ItemBox>& itemBoxes() const { return itemBoxes_; }
    uint32_t openBoxId() const { return boxObjId_; }
    const std::vector<BoxItem>& boxItems() const { return boxItems_; }
    const std::map<uint8_t, BagItem>& bag() const { return bag_; }
    const Pick& lastPick() const { return lastPick_; }
    const Chat& lastChat() const { return lastChat_; }
    // CYS-INV
    int64_t myMoney() const { return myMoney_; }
    int64_t myJiaozi() const { return myJiaozi_; }
    const std::map<uint8_t, BagItem>& equips() const { return equips_; }
    const Shop& shop() const { return shop_; }
    int32_t scriptTarget() const { return scriptTarget_; }
    const std::vector<ScriptEvent>& scriptEvents() const { return scriptEvents_; }
    const Result& lastUseEquip() const { return lastUseEquip_; }
    const Result& lastUnEquip() const { return lastUnEquip_; }
    const Result& lastBuy() const { return lastBuy_; }
    const Result& lastSell() const { return lastSell_; }
    const Result& lastDiscard() const { return lastDiscard_; }
    const Result& lastSplit() const { return lastSplit_; }   // code = RESULT (2 succeed), bagIndex = new slot
    const Result& lastSwap() const { return lastSwap_; }     // code = result (1 ok), point = from, bagIndex = to
    // CYS-SKILL
    bool haveSettings() const { return haveSettings_; }
    const std::vector<Setting>& settings() const { return settings_; }   // 109 entries once haveSettings()
    const std::vector<XinFa>& xinfas() const { return xinfas_; }
    const std::map<int32_t, Cooldown>& cooldowns() const { return cooldowns_; }
    const Study& lastStudy() const { return lastStudy_; }
    int32_t myMenpai() const { return myMenpai_; }
    uint16_t studyTeacherMenpai() const { return studyMenpai_; }
    uint32_t studyTeacher() const { return studyTeacher_; }
    // CYS-QUEST
    const std::vector<Mission>& missions() const { return missions_; }
    const Mission* findMission(int32_t missionId) const;
    bool missionHaveDone(int32_t missionId) const; // mission_have_done_flags bit (human.lua is_mission_have_done)
    const MissionDialog& lastMissionDialog() const { return missionDialog_; }
    uint32_t scriptTexts() const { return scriptTexts_; }
    int32_t lastUiCommand() const { return lastUiCommand_; }
    std::unique_ptr<pg::Packet> makeAskMissionList() const;                                   // 957 CGAskMissionList
    std::unique_ptr<pg::Packet> makeMissionAccept(int32_t npcId, int32_t scriptId) const;     // 1232 CGMissionAccept
    std::unique_ptr<pg::Packet> makeMissionContinue(int32_t npcId, int32_t scriptId) const;   // 163 CGMissionContinue
    std::unique_ptr<pg::Packet> makeMissionSubmit(int32_t npcId, int32_t scriptId, int32_t radio) const; // 322
    std::unique_ptr<pg::Packet> makeMissionAbandon(int32_t scriptId) const;                   // 261 CGMissionAbandon
    // Nearest object of any kind to (x, y) within `radius`; 0 when none (NPCs arrive as GCNewMonster).
    uint32_t nearestObjectAt(float x, float y, float radius, float* distance = nullptr) const;
    // Nearest live monster (hpPercent != 0) to the own position; 0 when none.
    uint32_t nearestMonster(float* distance = nullptr) const;
    // CYS-ALLY 17/09/2026: nearest OTHER player (never the bot itself); `dead` picks hpPercent == 0.
    // Skills whose target_logic_by_stand is 0 (ally) refuse every monster with OR_WARNING (-16), and a
    // few refuse the caster too with OR_INVALID_TARGET (-8) - 408 resurrect needs a corpse, 423 needs a
    // hurt ally. Those are the last two skills of the 220 with no way to be measured by one bot alone.
    uint32_t nearestPlayer(bool dead, float* distance = nullptr) const;
    // Nearest item box (drop box first) within `radius`; 0 when none.
    uint32_t nearestItemBox(float radius) const;

    // Outbound helpers with the field values observed from the real client.
    std::unique_ptr<pg::Packet> makeEnterScene() const;            // scene of GCConnect, pos 0,0, type 0
    std::unique_ptr<pg::Packet> makeMove(float targetX, float targetY); // handle counts from 1 per socket
    // CYS-CORE: one CGCharMove with up to 16 straight waypoints (the bot has no navmesh; the private server
    // does not re-check the path against walls since 2026-08-26, scenecore.lua char_move).
    std::unique_ptr<pg::Packet> makeMovePath(const std::vector<std::pair<float, float>>& waypoints);
    std::unique_ptr<pg::Packet> makeAskChangeScene() const;        // echoes the pending notification
    std::unique_ptr<pg::Packet> makeAskBaseAttrib(uint32_t objectId) const;
    // CYS-CORE
    std::unique_ptr<pg::Packet> makeLockTarget(int32_t objectId) const;            // 372 CGLockTarget
    std::unique_ptr<pg::Packet> makeUseSkill(int32_t skillDataId, int32_t targetId) const; // 83 CGCharUseSkill (CY layout)
    // CYS-RIDE: 636 CGCharAutoRide - one u32 flag, echoed back as GCCharAutoRide (63). The mount itself never
    // travels on it: scenecore:char_auto_ride fires skill 21 and the model arrives as ride_model on an attrib
    // packet. Requires a mount SELECTED (db attrib "ride", set by CGExteriorRequest type 7 / sub 3) and one
    // EQUIPPED (HEQUIP_RIDER = 8), otherwise the server returns silently without any reply.
    std::unique_ptr<pg::Packet> makeAutoRide(uint32_t flag) const;
    // CYS-RIDE: 1027 CGExteriorRequest type 7 - the CY "appearance" editor apply. One list entry
    // {unknow_1 = category, unknow_2 = index}; scenecore:char_exterior_request maps category 3 -> set_ride(index),
    // which is the mount SELECTION that char_auto_ride then requires. The server does not check ownership there.
    std::unique_ptr<pg::Packet> makeExteriorApply(uint32_t category, uint32_t index) const;
    std::unique_ptr<pg::Packet> makeChat(uint8_t chatType, const std::string& utf8) const; // 753 CGChat (social.lua bis)
    std::unique_ptr<pg::Packet> makeOpenItemBox(uint32_t boxId) const;             // 1266 CGOpenItemBox
    std::unique_ptr<pg::Packet> makePickBoxItem(uint32_t boxId, const pg::ItemGUID& guid) const; // 1155
    std::unique_ptr<pg::Packet> makeAskMyBagList() const;                          // 170 CGAskMyBagList ASK_ALL
    std::unique_ptr<pg::Packet> makeAskDetailSkillList() const;                    // 1252 CGAskDetailSkillList
    std::unique_ptr<pg::Packet> makePlayerDieResult(uint32_t code) const;          // 1770 (0 = out ghost)
    // CYS-INV (item.lua / shop.lua / misc.lua / mission.lua bis layouts)
    std::unique_ptr<pg::Packet> makeAskDetailEquipList() const;                    // 316 CGAskDetailEquipList (own object)
    std::unique_ptr<pg::Packet> makeAskDetailAttrib() const;                       // 678 CGAskDetailAttrib (own object: money)
    std::unique_ptr<pg::Packet> makeUseEquip(uint8_t bagIndex, uint8_t equipPoint) const; // 238 CGUseEquip (type 0)
    std::unique_ptr<pg::Packet> makeUnEquip(uint8_t equipPoint) const;              // 88 CGUnEquip
    std::unique_ptr<pg::Packet> makeDiscardItem(uint8_t bagIndex) const;            // 520 CGDiscardItem opt FromBag(0)
    std::unique_ptr<pg::Packet> makePackageSwap(uint8_t from, uint8_t to) const;    // 877 CGPackage_SwapItem
    std::unique_ptr<pg::Packet> makeSplitItem(uint8_t bagIndex, uint32_t count) const; // 96 CGSplitItem BAG_CON(1)
    std::unique_ptr<pg::Packet> makeCharDefaultEvent(uint32_t npcId) const;         // 1095 CGCharDefaultEvent
    std::unique_ptr<pg::Packet> makeEventRequest(int32_t scriptId, int32_t index, int32_t npcId) const; // 107 CGEventRequest
    std::unique_ptr<pg::Packet> makeShopBuy(uint8_t merchIndex, uint32_t count) const; // 427 CGShopBuy (index 0-based)
    std::unique_ptr<pg::Packet> makeShopSell(uint8_t bagIndex) const;               // 563 CGShopSell
    // CYS-SKILL (misc.lua bis layouts)
    std::unique_ptr<pg::Packet> makeAskSetting() const;                            // 402 CGAskSetting (empty)
    std::unique_ptr<pg::Packet> makeModifySetting(uint8_t settingType, uint8_t type, uint32_t data) const; // 409 CGModifySetting
    std::unique_ptr<pg::Packet> makeAskDetailXinFaList() const;                    // 134 CGAskDetailXinFaList (own object)
    std::unique_ptr<pg::Packet> makeAskStudyXinfa(uint16_t menpai, uint16_t xinfa, uint16_t nowLevel) const; // 555
    // CYS-TEAM (team.lua / misc.lua bis layouts)
    bool inTeam() const { return inTeam_; }
    uint16_t teamId() const { return teamId_; }
    int32_t teamLeader() const { return teamLeader_; }
    uint32_t teamExpMode() const { return teamExpMode_; }
    const std::vector<TeamMember>& teamMembers() const { return teamMembers_; }
    const TeamInvite& pendingInvite() const { return invite_; }
    const TeamEvent& lastTeamResult() const { return lastTeamResult_; }
    int32_t lastTeamError() const { return lastTeamError_; }
    const ExpGain& lastExp() const { return lastExp_; }
    int64_t expGained() const { return expGained_; }
    const std::string& lastTip() const { return lastTip_; } // GCScriptCommand cmd 5 (human:notify_tips), GBK bytes
    std::unique_ptr<pg::Packet> makeTeamInvite(const std::string& destName) const;         // 447 CGTeamInvite
    std::unique_ptr<pg::Packet> makeTeamRetInvite(uint8_t accept, int32_t inviterGuid) const; // 65 CGTeamRetInvite
    std::unique_ptr<pg::Packet> makeTeamApply(const std::string& destName) const;          // 329 CGTeamApply
    std::unique_ptr<pg::Packet> makeTeamRetApply(uint8_t accept, int32_t sourceGuid) const; // 258 CGTeamRetApply
    std::unique_ptr<pg::Packet> makeTeamKick(int32_t memberGuid) const;                    // 712 CGTeamKick
    std::unique_ptr<pg::Packet> makeTeamAppoint(int32_t memberGuid) const;                 // 717 CGTeamAppoint
    std::unique_ptr<pg::Packet> makeTeamLeave() const;                                     // 1353 CGTeamLeave
    std::unique_ptr<pg::Packet> makeTeamDismiss() const;                                   // 822 CGTeamDismiss
    std::unique_ptr<pg::Packet> makeAskTeamInfo() const;                                   // 145 CGAskTeamInfo
    std::unique_ptr<pg::Packet> makeTeamChangeOption(uint32_t expMode) const;              // 336 CGTeamChangeOption
    std::unique_ptr<pg::Packet> makeAskTeamMemberInfo(int32_t memberGuid) const;           // 964 CGAskTeamMemberInfo
    std::unique_ptr<pg::Packet> makeTeamChat(const std::string& utf8) const;               // 753 CGChat type 1 (team)
    std::unique_ptr<pg::Packet> makeTellChat(const std::string& target, const std::string& utf8) const; // 753 type 3

private:
    void upsert(uint32_t id, Kind kind, float x, float y, float dir, float speed);
    std::map<uint32_t, Object> objects_;
    std::map<uint16_t, uint32_t> counts_;
    Stats stats_;
    bool connected_ = false, gotConnect_ = false, inWorld_ = false, notifyPending_ = false;
    uint32_t generation_ = 0, myObjectId_ = 0;
    uint16_t sceneId_ = 0, clientRes_ = 0, connectScene_ = 0, notifyFrom_ = 0, notifyTo_ = 0;
    float myX_ = 0, myY_ = 0;
    int32_t lastMoveResult_ = 0;
    uint32_t moveHandle_ = 0;
    // CYS-CORE
    int myHp_ = -1, myMaxHp_ = -1, myLevel_ = -1;
    int64_t myExp_ = -1;
    int32_t myGuid_ = 0;
    int16_t myCamp_ = -1;
    float mySpeed_ = 0;
    int32_t myRideModel_ = -1;        // CYS-RIDE
    unsigned rideModelChanges_ = 0;   // CYS-RIDE
    bool dead_ = false;
    int32_t lastOperateResult_ = 0;
    std::vector<uint32_t> skills_;
    std::map<uint32_t, ItemBox> itemBoxes_;
    uint32_t boxObjId_ = 0;
    std::vector<BoxItem> boxItems_;
    std::map<uint8_t, BagItem> bag_;
    Pick lastPick_;
    Chat lastChat_;
    // CYS-INV
    int64_t myMoney_ = -1, myJiaozi_ = -1;
    std::map<uint8_t, BagItem> equips_;
    Shop shop_;
    int32_t scriptTarget_ = -1;
    std::vector<ScriptEvent> scriptEvents_;
    Result lastUseEquip_, lastUnEquip_, lastBuy_, lastSell_, lastDiscard_, lastSplit_, lastSwap_;
    // CYS-SKILL
    bool haveSettings_ = false;
    std::vector<Setting> settings_;
    std::vector<XinFa> xinfas_;
    std::map<int32_t, Cooldown> cooldowns_;
    Study lastStudy_;
    int32_t myMenpai_ = -1;
    uint16_t studyMenpai_ = 0;
    uint32_t studyTeacher_ = 0;
    // CYS-QUEST
    std::vector<Mission> missions_;
    uint32_t doneFlags_[128] = {};
    MissionDialog missionDialog_;
    uint32_t scriptTexts_ = 0;
    int32_t lastUiCommand_ = -1;
    // CYS-TEAM
    bool inTeam_ = false;
    uint16_t teamId_ = 0;
    int32_t teamLeader_ = 0, lastTeamError_ = -1;
    uint32_t teamExpMode_ = 0;
    std::vector<TeamMember> teamMembers_;
    TeamInvite invite_;
    TeamEvent lastTeamResult_;
    ExpGain lastExp_;
    int64_t expGained_ = 0;
    std::string lastTip_;
};

}} // namespace cys::net
