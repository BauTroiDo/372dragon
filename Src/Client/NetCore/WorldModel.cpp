#include "WorldModel.h"
#include "PgPackets_combat.h"
#include "PgPackets_core.h"
#include "PgPackets_item.h"
#include "PgPackets_misc.h"
#include "PgPackets_mission.h"
#include "PgPackets_movement.h"
#include "PgPackets_shop.h" // CYS-INV
#include "PgPackets_social.h"
#include "PgPackets_team.h" // CYS-TEAM
#include <cmath>

namespace cys { namespace net {

namespace {
// CYS-ITEM: stack size of one ItemInfo. The struct is a class-tagged union - the server picks the branch with
// `flag = floor(item_index / 10000000)` (= define.ITEM_CLASS) and writes that class's fixed-size blob
// (services/game/packet_types/item_types.lua bos()). The stack count lives inside that blob, at the byte the
// class's own set_lay_count writes (lualib/item.lua, Lua is 1-based):
//     class 2 material  -> unknow_19[1]   class 3 store map / consumable -> unknow_20[1]
//     class 4 task      -> unknow_21[1]   class 5 gem                    -> unknow_22[49]
// Equipment (1) and pet equipment (7) never stack. Returning 1 for them matches the server, which sets
// equip_data:copy_raw_data() lay_count = 1.
uint32_t itemStackCount(const pg::ItemInfo_bos& item) {
    const int32_t cls = item.item_index / 10000000;
    uint32_t count = 0;
    switch (cls) {
    case 2: count = item.unknow_19[0]; break;   // array<u8,32>
    case 3: count = item.unknow_20[0]; break;   // array<u8,32>
    case 4: count = item.unknow_21[0]; break;   // array<u8,32>
    case 5: count = item.unknow_22[48]; break;  // array<u8,56>
    default: return 1;
    }
    return count ? count : 1;   // a stacking class that reports 0 still means "one item is in this slot"
}
} // namespace

void WorldModel::reset() { *this = WorldModel(); }

void WorldModel::onConnected(uint32_t generation) {
    connected_ = true; gotConnect_ = false; inWorld_ = false;
    generation_ = generation; moveHandle_ = 0;
}

void WorldModel::onTransfer() {
    objects_.clear();
    itemBoxes_.clear(); boxItems_.clear(); boxObjId_ = 0; // CYS-CORE: scene objects are gone
    inWorld_ = false; gotConnect_ = false; notifyPending_ = false;
    ++stats_.transfers;
}

void WorldModel::upsert(uint32_t id, Kind kind, float x, float y, float dir, float speed) {
    auto found = objects_.find(id);
    if (found == objects_.end()) {
        Object object;
        object.kind = kind; object.x = x; object.y = y; object.dir = dir; object.speed = speed;
        objects_.emplace(id, object);
        ++stats_.created;
    } else {
        found->second.kind = kind; found->second.x = x; found->second.y = y;
        found->second.dir = dir; found->second.speed = speed;
        ++stats_.refreshed;
    }
}

bool WorldModel::apply(const pg::Packet& packet, const char** error) {
    ++stats_.packets;
    ++counts_[packet.packetId()];
    auto fail = [&](const char* message) {
        if (error) *error = message;
        return false;
    };
    switch (packet.packetId()) {
    case pg::KeyExchange::PACKET_ID:
        ++stats_.keyExchanges;
        return true;
    case pg::GCConnect::PACKET_ID: {
        if (!connected_ || gotConnect_) return fail("GCConnect outside a new game socket");
        const auto& connect = static_cast<const pg::GCConnect&>(packet);
        gotConnect_ = true;
        connectScene_ = connect.sceneid;
        myX_ = connect.position_x; myY_ = connect.position_y;
        ++stats_.connects;
        return true;
    }
    case pg::GCEnterScene::PACKET_ID: {
        if (!gotConnect_ || inWorld_) return fail("GCEnterScene before GCConnect or twice on one socket");
        const auto& enter = static_cast<const pg::GCEnterScene&>(packet);
        inWorld_ = true;
        myObjectId_ = enter.m_objID;
        sceneId_ = enter.sceneid; clientRes_ = enter.client_res;
        myX_ = enter.m_posWorld_x; myY_ = enter.m_posWorld_y;
        dead_ = false;
        ++stats_.enters;
        return true;
    }
    case pg::GCNewPlayer::PACKET_ID: {
        const auto& p = static_cast<const pg::GCNewPlayer&>(packet);
        upsert(p.m_objID, Kind::Player, p.m_posWorld_x, p.m_posWorld_y, p.m_fDir, p.m_fMoveSpeed);
        return true;
    }
    case pg::GCNewPlayer_Move::PACKET_ID: {
        const auto& p = static_cast<const pg::GCNewPlayer_Move&>(packet);
        upsert(p.m_objID, Kind::Player, p.m_posWorld_x, p.m_posWorld_y, p.dir, p.speed);
        objects_[p.m_objID].handle = static_cast<int32_t>(p.handle);
        return true;
    }
    case pg::GCNewMonster::PACKET_ID: {
        const auto& p = static_cast<const pg::GCNewMonster&>(packet);
        upsert(p.m_objID, Kind::Monster, p.worldPos_x, p.worldPos_y, p.dir, p.speed);
        return true;
    }
    case pg::GCNewMonster_Move::PACKET_ID: {
        const auto& p = static_cast<const pg::GCNewMonster_Move&>(packet);
        upsert(p.m_objID, Kind::Monster, p.world_pos_x, p.world_pos_y, p.dir, p.speed);
        objects_[p.m_objID].handle = static_cast<int32_t>(p.handle);
        return true;
    }
    case pg::GCNewPet::PACKET_ID: {
        const auto& p = static_cast<const pg::GCNewPet&>(packet);
        upsert(p.m_objID, Kind::Pet, p.world_pos_x, p.world_pos_y, 0, p.speed);
        return true;
    }
    case pg::GCNewPet_Move::PACKET_ID: {
        const auto& p = static_cast<const pg::GCNewPet_Move&>(packet);
        upsert(p.m_objID, Kind::Pet, p.worldpos_x, p.worldpos_y, 0, 0);
        return true;
    }
    case pg::GCDelObject::PACKET_ID: {
        const auto& p = static_cast<const pg::GCDelObject&>(packet);
        // As the 0.85 handler: a delete for another scene is ignored.
        if (inWorld_ && p.m_idScene != sceneId_) { ++stats_.foreignSceneDeletes; return true; }
        auto found = objects_.find(p.m_objID);
        if (found == objects_.end()) {
            auto box = itemBoxes_.find(p.m_objID); // CYS-CORE: item boxes leave through the same packet
            if (box != itemBoxes_.end()) { itemBoxes_.erase(box); ++stats_.deleted; if (boxObjId_ == p.m_objID) { boxObjId_ = 0; boxItems_.clear(); } }
            else ++stats_.unknownDeletes;
        } else { objects_.erase(found); ++stats_.deleted; }
        return true;
    }
    case pg::GCCharMove::PACKET_ID: {
        const auto& p = static_cast<const pg::GCCharMove&>(packet);
        ++stats_.moves;
        if (myObjectId_ && p.m_objID == myObjectId_) {
            // The scene broadcasts the mover's own path back to it (broadcast(self, msg, true)).
            ++stats_.selfMoves;
            if (!p.path.empty()) { myX_ = p.path.back().x; myY_ = p.path.back().y; }
            return true;
        }
        auto found = objects_.find(p.m_objID);
        if (found == objects_.end()) { ++stats_.unknownMoves; return true; }
        found->second.handle = p.handleID;
        ++found->second.moves;
        if (!p.path.empty()) { found->second.x = p.path.back().x; found->second.y = p.path.back().y; }
        return true;
    }
    case pg::GCCharMoveResult::PACKET_ID: {
        const auto& p = static_cast<const pg::GCCharMoveResult&>(packet);
        ++stats_.moveResults;
        lastMoveResult_ = p.result;
        if (p.result < 0) ++stats_.moveFailures;
        return true;
    }
    case pg::GCCharAutoRide::PACKET_ID: { // CYS-RIDE: acknowledgement only, carries no mount id
        ++stats_.autoRideReplies;
        return true;
    }
    case pg::GCCharBaseAttrib::PACKET_ID: {
        ++stats_.baseAttribs;
        // CYS-CORE: presence bits as the server setters (combat.lua GCCharBaseAttrib set_*), same as CysModernHandlers.
        const auto& p = static_cast<const pg::GCCharBaseAttrib&>(packet);
        int64_t f[11] = {};
        int64_t peak1 = 0, peak2 = 0;
        pg::deriveCharBaseAttribFlags(p.new_flags.data(), f, &peak1, &peak2);
        const bool self = myObjectId_ && p.m_objID == myObjectId_;
        if (self) {
            if (f[0] & 0x08) myLevel_ = p.level;
            if (f[1] & 0x02) mySpeed_ = p.speed;
            // CYS-RIDE: the mount itself always arrives here, never on GCCharAutoRide (which carries only a flag).
            if ((f[1] & 0x20) && p.ride_model != myRideModel_) { myRideModel_ = p.ride_model; ++rideModelChanges_; }
            if (p.guid) myGuid_ = p.guid;
            if (p.camp_id != -1) myCamp_ = p.camp_id;
            return true;
        }
        auto found = objects_.find(p.m_objID);
        if (found == objects_.end()) return true;
        Object& o = found->second;
        if (f[0] & 0x01) o.model = p.model;
        if (f[0] & 0x02) o.name = p.m_szName;
        if (f[0] & 0x08) o.level = p.level;
        if (f[0] & 0x10) { o.hpPercent = p.hp_percent; ++stats_.hpUpdates; if (p.hp_percent == 0) ++stats_.targetDeaths; }
        if (f[1] & 0x02) o.speed = p.speed;
        if (p.camp_id != -1) o.camp = p.camp_id;
        return true;
    }
    case pg::GCDetailAttrib::PACKET_ID: {
        ++stats_.detailAttribs;
        const auto& p = static_cast<const pg::GCDetailAttrib&>(packet);
        if (!myObjectId_ || p.m_objID != myObjectId_) return true;
        auto has = [&](int64_t index, int64_t mask) { return (pg::at1(p.flags, index) & mask) == mask; };
        if (has(1, 1)) myLevel_ = static_cast<int>(p.level);
        if (has(1, 2)) myHp_ = static_cast<int>(p.hp);
        if (has(2, 128)) myMaxHp_ = static_cast<int>(p.hp_max);
        if (has(1, 8)) myExp_ = static_cast<int64_t>(p.exp);
        if (has(5, 16)) mySpeed_ = p.speed;
        if (has(8, 8) && static_cast<int32_t>(p.ride_model) != myRideModel_) // CYS-RIDE
        { myRideModel_ = static_cast<int32_t>(p.ride_model); ++rideModelChanges_; }
        if (has(1, 16)) myMoney_ = static_cast<int64_t>(p.money); // CYS-INV
        if (has(14, 4)) myJiaozi_ = static_cast<int64_t>(p.jiaozi); // CYS-INV: 交子 (shop currency 8)
        if (has(7, 64)) myMenpai_ = static_cast<int32_t>(p.menpai); // CYS-SKILL: 9 = no sect
        return true;
    }
    case pg::GCDetailHealsAndDamages::PACKET_ID: {
        ++stats_.damages;
        const auto& p = static_cast<const pg::GCDetailHealsAndDamages&>(packet);
        if ((p.dirty_flags & 1) && p.hp_modification < 0) {
            if (myObjectId_ && static_cast<uint32_t>(p.sender) == myObjectId_) ++stats_.damageDealt;
            if (myObjectId_ && p.reciver == myObjectId_) { ++stats_.damageTaken; if (myHp_ > 0) myHp_ += p.hp_modification; }
        }
        return true;
    }
    case pg::GCCharSkill_Send::PACKET_ID: {
        ++stats_.skillSends;
        const auto& p = static_cast<const pg::GCCharSkill_Send&>(packet);
        if (myObjectId_ && p.m_objID == myObjectId_) ++stats_.selfSkillSends;
        return true;
    }
    case pg::GCCharSkill_Missed::PACKET_ID:
        ++stats_.skillMisses;
        return true;
    case pg::GCTargetListAndHitFlags::PACKET_ID:
        ++stats_.targetLists;
        return true;
    case pg::GCNewItemBox::PACKET_ID: {
        ++stats_.itemBoxes;
        const auto& p = static_cast<const pg::GCNewItemBox&>(packet);
        ItemBox box;
        box.x = p.world_pos_x; box.y = p.world_pos_y; box.owner = p.owner_guid; box.monster = p.monster_id; box.type = p.item_box_type;
        itemBoxes_[p.m_objID] = box;
        return true;
    }
    case pg::GCBoxItemList::PACKET_ID: {
        ++stats_.boxLists;
        const auto& p = static_cast<const pg::GCBoxItemList&>(packet);
        boxObjId_ = p.m_objID;
        boxItems_.clear();
        for (const auto& item : p.item_list) {
            BoxItem entry;
            entry.guid = item.guid; entry.itemIndex = item.item_index; entry.count = 1;
            boxItems_.push_back(entry);
        }
        return true;
    }
    case pg::GCPickResult::PACKET_ID: {
        ++stats_.pickResults;
        const auto& p = static_cast<const pg::GCPickResult&>(packet);
        lastPick_.valid = true; lastPick_.result = p.result; lastPick_.bagIndex = p.bag_index;
        lastPick_.boxId = p.m_objID; lastPick_.guid = p.item_guid;
        if (p.result == 0) {
            ++stats_.picksOk;
            for (size_t i = 0; i < boxItems_.size(); ++i) {
                const pg::ItemGUID& g = boxItems_[i].guid;
                if (g.world == p.item_guid.world && g.server == p.item_guid.server && g.series == p.item_guid.series) {
                    boxItems_.erase(boxItems_.begin() + static_cast<std::ptrdiff_t>(i));
                    break;
                }
            }
        }
        return true;
    }
    case pg::GCItemInfo::PACKET_ID: {
        ++stats_.itemInfos;
        const auto& p = static_cast<const pg::GCItemInfo&>(packet);
        if (p.bagIndex < 0 || p.bagIndex > 255) return true;
        const uint8_t index = static_cast<uint8_t>(p.bagIndex);
        // CYS-INV: an emptied slot carries item_cls.new() (index -1 or 0) and unknow_1 = 1 (swap/sell) or -1 (ask).
        if (p.item.item_index <= 0 || p.unknow_1 != 0) { bag_.erase(index); return true; }
        BagItem entry;
        entry.guid = p.item.guid; entry.itemIndex = static_cast<uint32_t>(p.item.item_index);
        entry.count = itemStackCount(p.item);   // CYS-ITEM
        bag_[index] = entry;
        return true;
    }
    case pg::GCMyBagList::PACKET_ID: {
        ++stats_.bagLists;
        const auto& p = static_cast<const pg::GCMyBagList&>(packet);
        bag_.clear();
        for (const auto& item : p.list) {
            BagItem entry;
            entry.guid = item.guid; entry.itemIndex = item.item_index; entry.count = item.count;
            bag_[item.index] = entry;
        }
        return true;
    }
    case pg::GCDetailSkillList::PACKET_ID: {
        ++stats_.skillLists;
        const auto& p = static_cast<const pg::GCDetailSkillList&>(packet);
        if (myObjectId_ && p.m_objID != myObjectId_) return true;
        skills_ = p.m_aSkill;
        return true;
    }
    case pg::GCChat::PACKET_ID: {
        ++stats_.chats;
        const auto& p = static_cast<const pg::GCChat&>(packet);
        lastChat_.type = p.ChatType; lastChat_.source = p.SourceName; lastChat_.text = p.Contex;
        lastChat_.sourceId = (p.ChatType == 0 || p.ChatType == 26) ? p.Sourceid : 0;
        if (myObjectId_ && lastChat_.sourceId == myObjectId_) ++stats_.selfChats;
        // CYS-TEAM: team chat (1) comes back through worldcore team_chat, private chat arrives as
        // CHAT_TYPE_TELL (3) at the receiver and CHAT_TYPE_TELL_RET (25) as the sender's own echo.
        if (p.ChatType == 1) ++stats_.teamChats;
        if (p.ChatType == 3 || p.ChatType == 25) ++stats_.tellChats;
        return true;
    }
    // CYS-TEAM: the whole team surface the private server actually sends. GCTeamList carries no leader
    // field - worldcore always writes team:get_members() and team:leader() is members[1] (lualib/team.lua),
    // so the first entry IS the leader.
    case pg::GCTeamList::PACKET_ID: {
        ++stats_.teamLists;
        const auto& p = static_cast<const pg::GCTeamList&>(packet);
        teamId_ = p.team_id;
        teamExpMode_ = p.exp_mode;
        teamMembers_.clear();
        for (const auto& e : p.member_list) {
            TeamMember m;
            m.guid = e.guid; m.objId = e.m_objID; m.sceneId = e.sceneid;
            m.level = e.level; m.menpai = e.menpai; m.name = e.name;
            teamMembers_.push_back(m);
        }
        if (!teamMembers_.empty()) { teamLeader_ = teamMembers_.front().guid; inTeam_ = true; }
        return true;
    }
    case pg::GCTeamResult::PACKET_ID: {
        ++stats_.teamResults;
        const auto& p = static_cast<const pg::GCTeamResult&>(packet);
        lastTeamResult_.valid = true;
        lastTeamResult_.returnType = p.return_type;
        lastTeamResult_.guid = p.guid; lastTeamResult_.guidEx = p.guid_ex;
        lastTeamResult_.teamId = p.team_id; lastTeamResult_.name = p.name;
        // define.TEAM_RESULT: 0 enter, 1 member leave, 2 leader leave, 3 dismiss, 4 kick, 5 appoint.
        const bool mine = myGuid_ != 0 && p.guid == myGuid_;
        if (p.return_type == 0) {
            teamId_ = p.team_id; inTeam_ = true;
            bool known = false;
            for (const auto& m : teamMembers_) known = known || m.guid == p.guid;
            if (!known) { TeamMember m; m.guid = p.guid; m.objId = p.guid_ex; m.sceneId = p.sceneid; m.name = p.name; teamMembers_.push_back(m); }
        } else if (p.return_type == 3) {
            inTeam_ = false; teamMembers_.clear(); teamLeader_ = 0; teamId_ = 0;
        } else if (p.return_type == 1 || p.return_type == 2 || p.return_type == 4) {
            if (mine) { inTeam_ = false; teamMembers_.clear(); teamLeader_ = 0; teamId_ = 0; }
            else {
                for (size_t i = 0; i < teamMembers_.size(); ++i)
                    if (teamMembers_[i].guid == p.guid) { teamMembers_.erase(teamMembers_.begin() + static_cast<long>(i)); break; }
                if (!teamMembers_.empty()) teamLeader_ = teamMembers_.front().guid;
            }
        } else if (p.return_type == 5) {
            teamLeader_ = p.guid_ex;
        }
        return true;
    }
    case pg::GCTeamError::PACKET_ID: {
        ++stats_.teamErrors;
        lastTeamError_ = static_cast<const pg::GCTeamError&>(packet).error_code;
        return true;
    }
    case pg::GCTeamAskInvite::PACKET_ID: {
        ++stats_.teamAskInvites;
        const auto& p = static_cast<const pg::GCTeamAskInvite&>(packet);
        invite_.valid = true; invite_.guid = p.guid; invite_.memberSize = p.member_size;
        invite_.nickname = p.nickname_text();
        return true;
    }
    case pg::GCTeamLeaderAskInvite::PACKET_ID:
        ++stats_.teamLeaderAskInvites;
        return true;
    case pg::GCTeamAskApply::PACKET_ID: {
        ++stats_.teamAskApplies;
        const auto& p = static_cast<const pg::GCTeamAskApply&>(packet);
        invite_.valid = true; invite_.guid = p.source_guid; invite_.nickname = p.source_name;
        return true;
    }
    case pg::GCTeamOptionChanged::PACKET_ID: {
        ++stats_.teamOptionChanges;
        teamExpMode_ = static_cast<uint32_t>(static_cast<const pg::GCTeamOptionChanged&>(packet).exp_mode);
        return true;
    }
    case pg::GCTeamMemberInfo::PACKET_ID:
        ++stats_.teamMemberInfos;
        return true;
    case pg::GCTeamFollowList::PACKET_ID:
        ++stats_.teamFollowLists;
        return true;
    case pg::GCDetailExp::PACKET_ID: {
        ++stats_.expPackets;
        const auto& p = static_cast<const pg::GCDetailExp&>(packet);
        lastExp_.valid = true; lastExp_.exp = p.exp; lastExp_.awardExp = p.award_exp; lastExp_.petExp = p.bb_exp;
        expGained_ += static_cast<int64_t>(p.exp) + static_cast<int64_t>(p.award_exp);
        return true;
    }
    case pg::GCPlayerDie::PACKET_ID:
        ++stats_.playerDies;
        dead_ = true;
        return true;
    case pg::GCPlayerRelive::PACKET_ID:
        ++stats_.playerRelives;
        dead_ = false;
        return true;
    case pg::GCOperateResult::PACKET_ID:
        ++stats_.operateResults;
        lastOperateResult_ = static_cast<const pg::GCOperateResult&>(packet).result;
        return true;
    case pg::GCLevelUp::PACKET_ID:
        ++stats_.levelUps;
        return true;
    case pg::GCCooldownUpdate::PACKET_ID: {
        // CYS-SKILL: human.lua set_cool_down / update_cool_down_time: {cooldown id (SkillTemplate col 13), ms left, 0}
        ++stats_.cooldowns;
        const auto& p = static_cast<const pg::GCCooldownUpdate&>(packet);
        if (p.m_uHighSection != 0 || p.m_uLowSection != 0) return true; // pet cooldowns (pet guid)
        for (const auto& e : p.m_aCooldowns) {
            Cooldown& c = cooldowns_[e.m_nID];
            c.id = e.m_nID; c.total = e.m_nCooldown; c.elapsed = e.m_nCooldownElapsed; ++c.updates;
            ++stats_.cooldownEntries;
        }
        return true;
    }
    case pg::GCRetSetting::PACKET_ID: { // CYS-SKILL
        ++stats_.settingLists;
        const auto& p = static_cast<const pg::GCRetSetting&>(packet);
        settings_.assign(p.setting.size(), Setting());
        for (size_t i = 0; i < p.setting.size(); ++i) { settings_[i].type = p.setting[i].type; settings_[i].data = p.setting[i].data; }
        haveSettings_ = true;
        return true;
    }
    case pg::GCDetailXinFaList::PACKET_ID: { // CYS-SKILL
        ++stats_.xinfaLists;
        const auto& p = static_cast<const pg::GCDetailXinFaList&>(packet);
        if (myObjectId_ && p.m_objID != myObjectId_) return true;
        xinfas_.clear();
        for (const auto& x : p.m_aXinFa) { XinFa entry; entry.id = x.m_nXinFaID; entry.level = x.m_nXinFaLevel; xinfas_.push_back(entry); }
        return true;
    }
    case pg::GCStudyXinfa::PACKET_ID: { // CYS-SKILL: scenecore.lua char_study_xinfa
        ++stats_.studyResults;
        const auto& p = static_cast<const pg::GCStudyXinfa&>(packet);
        lastStudy_.valid = true; lastStudy_.money = p.spare_money; lastStudy_.exp = p.spare_exp;
        lastStudy_.xinfa = p.xinfa; lastStudy_.level = p.now_level;
        for (auto& x : xinfas_) if (x.id == p.xinfa) x.level = p.now_level;
        return true;
    }
    case pg::GCXinfaStudyInfo::PACKET_ID: { // CYS-SKILL: script_base DispatchXinfaLevelInfo (sect teacher)
        ++stats_.studyInfos;
        const auto& p = static_cast<const pg::GCXinfaStudyInfo&>(packet);
        studyMenpai_ = p.menpai; studyTeacher_ = p.teacher;
        return true;
    }
    case pg::GCAddSkill::PACKET_ID: { // CYS-SKILL
        ++stats_.addSkills;
        const auto& p = static_cast<const pg::GCAddSkill&>(packet);
        bool listed = false;
        for (uint32_t id : skills_) listed = listed || id == p.skill;
        if (!listed) skills_.push_back(p.skill);
        return true;
    }
    case pg::GCNotifyChangeScene::PACKET_ID: {
        const auto& p = static_cast<const pg::GCNotifyChangeScene&>(packet);
        notifyPending_ = true; notifyFrom_ = p.scene_from; notifyTo_ = p.scene_to;
        ++stats_.notifyChangeScene;
        return true;
    }
    case pg::GCRetChangeScene::PACKET_ID:
        // A pumped Packet(280) is a refusal; an accepted transfer arrives as a Transfer event.
        notifyPending_ = false;
        ++stats_.retChangeScene;
        return true;
    case pg::GCRetAskQuit::PACKET_ID:
        ++stats_.quitAcks;
        return true;
    case pg::GCScriptCommand::PACKET_ID: {
        ++stats_.scriptCommands;
        // CYS-INV: event list of an NPC dialogue (m_nCmdID 0/2): flag 1 entries are the numbered options
        // (AddNumText -> index, type, script_id); type 7 is the "shop" option of the Dali merchants.
        const auto& p = static_cast<const pg::GCScriptCommand&>(packet);
        if (p.m_nCmdID == 0 || p.m_nCmdID == 2) {
            ++stats_.scriptEventLists;
            scriptTarget_ = p.target_id;
            scriptEvents_.clear();
            scriptTexts_ = 0;
            for (const auto& e : p.event) {
                if (e.flag != 1) { ++scriptTexts_; continue; }
                ScriptEvent entry;
                entry.index = e.index; entry.type = e.type; entry.scriptId = e.script_id; entry.text = e.str_2;
                scriptEvents_.push_back(entry);
            }
        } else if (p.m_nCmdID == 1 || p.m_nCmdID == 3 || p.m_nCmdID == 4) {
            // CYS-QUEST: script_base.lua DispatchMissionInfo (1) / DispatchMissionDemandInfo (3) / DispatchMissionContinueInfo (4)
            MissionDialog d;
            d.cmd = p.m_nCmdID;
            if (p.m_nCmdID == 1) {
                ++stats_.missionInfos;
                d.npc = static_cast<int32_t>(p.target_id_2); d.script = p.m_objID; d.mission = p.m_idMission;
                d.texts = static_cast<uint32_t>(p.event_2.size()); d.bonuses = p.m_yBonusCount;
                for (const auto& b : p.m_aBonus) d.bonus.push_back(std::make_pair(b.type, static_cast<int32_t>(b.item_index)));
            } else if (p.m_nCmdID == 3) {
                ++stats_.missionDemands;
                d.npc = static_cast<int32_t>(p.target_id_2); d.script = static_cast<int32_t>(p.m_objID_2); d.mission = static_cast<int32_t>(p.m_idMission_2);
                d.done = p.done; d.texts = static_cast<uint32_t>(p.event_3.size()); d.bonuses = p.m_yDemandCount;
            } else {
                ++stats_.missionContinues;
                d.npc = p.target_id; d.script = p.m_objID; d.mission = p.m_idMission;
                d.texts = static_cast<uint32_t>(p.event_4.size()); d.bonuses = static_cast<uint32_t>(p.items.size());
                for (const auto& b : p.items) d.bonus.push_back(std::make_pair(b.flag, b.item_index));
            }
            missionDialog_ = d;
        } else if (p.m_nCmdID == 5) {
            ++stats_.missionTips;
            lastTip_ = p.event_str; // CYS-TEAM: human:notify_tips text (GBK), e.g. the level gate of private chat
        }
        return true;
    }
    // CYS-QUEST ==========================================================================================
    case pg::GCMissionList::PACKET_ID: {
        ++stats_.missionLists;
        const auto& p = static_cast<const pg::GCMissionList&>(packet);
        missions_.clear();
        for (size_t i = 0; i < p.char_missions.size() && i < 20; ++i) {
            if (!(p.m_uMissionListFlags & (1u << i))) continue;
            const auto& m = p.char_missions[i];
            Mission entry;
            entry.id = m.id; entry.script = m.index; entry.flags = m.yFlag;
            for (int k = 0; k < 8; ++k) entry.params[k] = m.params[k];
            missions_.push_back(entry);
        }
        for (size_t i = 0; i < 128; ++i) doneFlags_[i] = p.mission_have_done_flags[i];
        return true;
    }
    case pg::GCMissionAdd::PACKET_ID: {
        ++stats_.missionAdds;
        const auto& p = static_cast<const pg::GCMissionAdd&>(packet);
        Mission entry;
        entry.id = p.id; entry.script = p.index; entry.flags = static_cast<uint8_t>(p.yFlag);
        for (int k = 0; k < 8; ++k) entry.params[k] = p.params[k];
        bool replaced = false;
        for (auto& m : missions_) if (m.id == entry.id) { m = entry; replaced = true; }
        if (!replaced) missions_.push_back(entry);
        return true;
    }
    case pg::GCMissionModify::PACKET_ID: {
        ++stats_.missionModifies;
        const auto& p = static_cast<const pg::GCMissionModify&>(packet);
        if (p.m_nFlag == 0) { // human.lua set_mission_by_index: the whole mission entry
            for (auto& m : missions_) {
                if (m.id != p.m_aMissionData_id) continue;
                m.script = p.m_aMissionData_index; m.flags = static_cast<uint8_t>(p.m_aMissionData_yFlag);
                for (int k = 0; k < 8; ++k) m.params[k] = p.m_aMissionData_params[k];
            }
        }
        return true;
    }
    case pg::GCMissionRemove::PACKET_ID: {
        ++stats_.missionRemoves;
        const auto& p = static_cast<const pg::GCMissionRemove&>(packet);
        for (size_t i = 0; i < missions_.size(); ++i) if (missions_[i].id == p.id) { missions_.erase(missions_.begin() + i); break; }
        return true;
    }
    case pg::GCMissionHaveDoneFlag::PACKET_ID: {
        ++stats_.missionDoneFlags;
        const auto& p = static_cast<const pg::GCMissionHaveDoneFlag&>(packet);
        if (p.mission_id >= 0 && (p.mission_id >> 5) < 128) {
            const uint32_t bit = 1u << (p.mission_id & 31);
            if (p.flag) doneFlags_[p.mission_id >> 5] |= bit; else doneFlags_[p.mission_id >> 5] &= ~bit;
        }
        return true;
    }
    case pg::GCUICommand::PACKET_ID:
        ++stats_.uiCommands;
        lastUiCommand_ = static_cast<int32_t>(static_cast<const pg::GCUICommand&>(packet).m_nUIIndex);
        return true;
    case pg::GCNpcTalk::PACKET_ID:
        ++stats_.npcTalks;
        return true;
    // CYS-INV ============================================================================================
    case pg::GCDetailEquipList::PACKET_ID: {
        ++stats_.equipLists;
        const auto& p = static_cast<const pg::GCDetailEquipList&>(packet);
        if (myObjectId_ && p.m_objID != myObjectId_) return true;
        if (p.m_mode == 0) equips_.clear(); // ASK_EQUIP_ALL; mode 1 = one changed point (char_use_equip)
        for (size_t i = 0; i < p.itemList.size(); ++i) {
            if (!p.itemList[i].present) continue;
            BagItem entry;
            entry.guid = p.itemList[i].anon1.guid;
            entry.itemIndex = static_cast<uint32_t>(p.itemList[i].anon1.item_index);
            entry.count = 1;
            if (entry.itemIndex == 0 || entry.itemIndex == 0xFFFFFFFFu) equips_.erase(static_cast<uint8_t>(i));
            else equips_[static_cast<uint8_t>(i)] = entry;
        }
        return true;
    }
    case pg::GCCharEquipment::PACKET_ID:
        ++stats_.charEquipments;
        return true;
    case pg::GCUseEquipResult::PACKET_ID: {
        ++stats_.useEquips;
        const auto& p = static_cast<const pg::GCUseEquipResult&>(packet);
        lastUseEquip_.valid = true; lastUseEquip_.code = p.result; lastUseEquip_.point = p.equipPoint;
        lastUseEquip_.bagIndex = p.bagIndex; lastUseEquip_.itemIndex = p.item_index; lastUseEquip_.other = p.equipTableIndex;
        if (p.result == 1) { // define.UseEquipResultCode.USEEQUIP_SUCCESS
            ++stats_.useEquipsOk;
            BagItem worn; worn.guid = p.item_guid; worn.itemIndex = static_cast<uint32_t>(p.item_index); worn.count = 1;
            equips_[p.equipPoint] = worn;
            if (p.equipTableIndex > 0) {
                BagItem old; old.guid = p.equip_guid; old.itemIndex = static_cast<uint32_t>(p.equipTableIndex); old.count = 1;
                bag_[p.bagIndex] = old;
            } else bag_.erase(p.bagIndex);
        }
        return true;
    }
    case pg::GCUnEquipResult::PACKET_ID: {
        ++stats_.unEquips;
        const auto& p = static_cast<const pg::GCUnEquipResult&>(packet);
        lastUnEquip_.valid = true; lastUnEquip_.code = p.result; lastUnEquip_.point = p.equipPoint;
        lastUnEquip_.bagIndex = p.bagIndex; lastUnEquip_.itemIndex = p.item_index;
        if (p.result == 1) { // scenecore.lua char_un_equip: 1 = moved to the bag
            ++stats_.unEquipsOk;
            equips_.erase(p.equipPoint);
            if (p.bagIndex != 255) {
                BagItem item; item.guid = p.item_guid; item.itemIndex = static_cast<uint32_t>(p.item_index); item.count = 1;
                bag_[p.bagIndex] = item;
            }
        }
        return true;
    }
    case pg::GCShopMerchandiseList::PACKET_ID: {
        ++stats_.shopLists;
        const auto& p = static_cast<const pg::GCShopMerchandiseList&>(packet);
        shop_ = Shop();
        shop_.open = true; shop_.npc = p.m_objID; shop_.shopId = p.shop_id; shop_.uniqueId = p.unique_id;
        shop_.type = p.shop_type; shop_.yuanbao = p.is_yuanbao_shop; shop_.multi = p.can_multiple_buy;
        for (const auto& m : p.merchadise_list) {
            Merchandise goods;
            goods.itemIndex = m.id; goods.perGroup = m.pnum; goods.max = m.pmax; goods.price = m.price;
            shop_.goods.push_back(goods);
        }
        return true;
    }
    case pg::GCShopSoldList::PACKET_ID:
        ++stats_.soldLists;
        return true;
    case pg::GCShopBuy::PACKET_ID: {
        ++stats_.shopBuys;
        const auto& p = static_cast<const pg::GCShopBuy&>(packet);
        lastBuy_.valid = true; lastBuy_.code = p.result; lastBuy_.itemIndex = p.item_index; lastBuy_.other = p.count;
        if (p.result == 0 || p.result == 1) ++stats_.buysOk; // BUY_OK / BUY_BACK_OK
        return true;
    }
    case pg::GCShopSell::PACKET_ID: {
        ++stats_.shopSells;
        const auto& p = static_cast<const pg::GCShopSell&>(packet);
        lastSell_.valid = true; lastSell_.code = p.result;
        if (p.result == 0) ++stats_.sellsOk; // SELL_OK
        return true;
    }
    case pg::GCDiscardItemResult::PACKET_ID: {
        ++stats_.discards;
        const auto& p = static_cast<const pg::GCDiscardItemResult&>(packet);
        lastDiscard_.valid = true; lastDiscard_.code = p.result; lastDiscard_.bagIndex = p.bag_index; lastDiscard_.itemIndex = p.item_index;
        if (p.result == 0) { ++stats_.discardsOk; if (p.opt == 0) bag_.erase(p.bag_index); } // DISCARDITEM_SUCCESS, FromBag
        return true;
    }
    case pg::GCPackage_SwapItem::PACKET_ID: {
        ++stats_.swaps;
        const auto& p = static_cast<const pg::GCPackage_SwapItem&>(packet);
        lastSwap_.valid = true; lastSwap_.code = p.result; lastSwap_.point = p.index_from; lastSwap_.bagIndex = p.index_to;
        if (p.result == 1) {
            auto a = bag_.find(p.index_from); auto b = bag_.find(p.index_to);
            const bool hasA = a != bag_.end(), hasB = b != bag_.end();
            BagItem ia = hasA ? a->second : BagItem(), ib = hasB ? b->second : BagItem();
            bag_.erase(p.index_from); bag_.erase(p.index_to);
            if (hasA) bag_[p.index_to] = ia;
            if (hasB) bag_[p.index_from] = ib;
        }
        return true;
    }
    case pg::GCSplitItemResult::PACKET_ID: {
        ++stats_.splits;
        const auto& p = static_cast<const pg::GCSplitItemResult&>(packet);
        lastSplit_.valid = true; lastSplit_.code = p.result; lastSplit_.itemIndex = p.item.item_index;
        lastSplit_.bagIndex = (p.con_index >= 0 && p.con_index < 255) ? static_cast<uint8_t>(p.con_index) : 255;
        if (p.result == 2 && lastSplit_.bagIndex != 255) { // human.lua split_item: RESULT_SUCCEED, new stack at con_index
            BagItem entry; entry.guid = p.item.guid; entry.itemIndex = static_cast<uint32_t>(p.item.item_index); entry.count = 1;
            bag_[lastSplit_.bagIndex] = entry;
        }
        return true;
    }
    case pg::GCUseItemResult::PACKET_ID:
        ++stats_.useItems;
        return true;
    default:
        return true;
    }
}

uint32_t WorldModel::nearestMonster(float* distance) const {
    uint32_t best = 0;
    float bestDistance = 0;
    for (const auto& entry : objects_) {
        const Object& o = entry.second;
        if (o.kind != Kind::Monster || o.hpPercent == 0) continue;
        if (o.x == 0 && o.y == 0) continue; // sentinel position (no position packet yet)
        const float d = std::sqrt((o.x - myX_) * (o.x - myX_) + (o.y - myY_) * (o.y - myY_));
        if (!best || d < bestDistance) { best = entry.first; bestDistance = d; }
    }
    if (distance) *distance = best ? bestDistance : 0;
    return best;
}

// CYS-ALLY 17/09/2026: xem WorldModel.h. `hpPercent == -1` nghĩa là chưa nhận GCCharBaseAttrib, nên
// KHÔNG coi là chết: nếu coi là chết thì nhánh `dead` sẽ trả về người còn sống ngay lần đầu thấy họ.
uint32_t WorldModel::nearestPlayer(bool dead, float* distance) const {
    uint32_t best = 0;
    float bestDistance = 0;
    for (const auto& entry : objects_) {
        const Object& o = entry.second;
        if (o.kind != Kind::Player || entry.first == myObjectId_) continue;
        if (dead ? o.hpPercent != 0 : o.hpPercent == 0) continue;
        if (o.x == 0 && o.y == 0) continue; // sentinel position (no position packet yet)
        const float d = std::sqrt((o.x - myX_) * (o.x - myX_) + (o.y - myY_) * (o.y - myY_));
        if (!best || d < bestDistance) { best = entry.first; bestDistance = d; }
    }
    if (distance) *distance = best ? bestDistance : 0;
    return best;
}

uint32_t WorldModel::nearestItemBox(float radius) const {
    uint32_t best = 0;
    float bestDistance = 0;
    for (const auto& entry : itemBoxes_) {
        const ItemBox& b = entry.second;
        const float d = std::sqrt((b.x - myX_) * (b.x - myX_) + (b.y - myY_) * (b.y - myY_));
        if (d > radius) continue;
        if (!best || d < bestDistance) { best = entry.first; bestDistance = d; }
    }
    return best;
}

// CYS-INV
uint32_t WorldModel::nearestObjectAt(float x, float y, float radius, float* distance) const {
    uint32_t best = 0;
    float bestDistance = 0;
    for (const auto& entry : objects_) {
        const Object& o = entry.second;
        if (entry.first == myObjectId_ || (o.x == 0 && o.y == 0)) continue;
        const float d = std::sqrt((o.x - x) * (o.x - x) + (o.y - y) * (o.y - y));
        if (d > radius) continue;
        if (!best || d < bestDistance) { best = entry.first; bestDistance = d; }
    }
    if (distance) *distance = best ? bestDistance : 0;
    return best;
}

std::unique_ptr<pg::Packet> WorldModel::makeEnterScene() const {
    std::unique_ptr<pg::CGEnterScene> packet(new pg::CGEnterScene);
    // Capture: the real client echoes the GCConnect scene with type 0 and position 0,0;
    // the server enters its stored (or change-args) scene and position.
    packet->m_nSceneID = connectScene_;
    packet->m_byEnterType = 0;
    packet->m_posWorld_x = 0; packet->m_posWorld_y = 0;
    return std::unique_ptr<pg::Packet>(packet.release());
}

std::unique_ptr<pg::Packet> WorldModel::makeMove(float targetX, float targetY) {
    std::unique_ptr<pg::CGCharMove> packet(new pg::CGCharMove);
    packet->handleID = ++moveHandle_;
    packet->m_objID = myObjectId_;
    packet->posWorld_x = myX_; packet->posWorld_y = myY_;
    pg::CGCharMove::E_targetPos target;
    target.x = targetX; target.y = targetY;
    packet->targetPos.push_back(target);
    packet->numTargetPos = static_cast<uint8_t>(packet->targetPos.size());
    packet->unknow = 0;
    return std::unique_ptr<pg::Packet>(packet.release());
}

std::unique_ptr<pg::Packet> WorldModel::makeMovePath(const std::vector<std::pair<float, float>>& waypoints) {
    if (waypoints.empty() || waypoints.size() > 16) return std::unique_ptr<pg::Packet>();
    std::unique_ptr<pg::CGCharMove> packet(new pg::CGCharMove);
    packet->handleID = ++moveHandle_;
    packet->m_objID = myObjectId_;
    packet->posWorld_x = myX_; packet->posWorld_y = myY_;
    for (const auto& point : waypoints) {
        pg::CGCharMove::E_targetPos target;
        target.x = point.first; target.y = point.second;
        packet->targetPos.push_back(target);
    }
    packet->numTargetPos = static_cast<uint8_t>(packet->targetPos.size());
    packet->unknow = 0;
    return std::unique_ptr<pg::Packet>(packet.release());
}

std::unique_ptr<pg::Packet> WorldModel::makeAskChangeScene() const {
    std::unique_ptr<pg::CGAskChangeScene> packet(new pg::CGAskChangeScene);
    packet->scene_from = notifyFrom_; packet->scene_to = notifyTo_;
    packet->unknow_1 = 0; packet->unknow_2 = 0;
    return std::unique_ptr<pg::Packet>(packet.release());
}

std::unique_ptr<pg::Packet> WorldModel::makeAskBaseAttrib(uint32_t objectId) const {
    std::unique_ptr<pg::CGCharAskBaseAttrib> packet(new pg::CGCharAskBaseAttrib);
    packet->m_objID = objectId;
    return std::unique_ptr<pg::Packet>(packet.release());
}

// CYS-CORE ---------------------------------------------------------------------------------------
std::unique_ptr<pg::Packet> WorldModel::makeLockTarget(int32_t objectId) const {
    std::unique_ptr<pg::CGLockTarget> packet(new pg::CGLockTarget);
    packet->target_id = objectId; // ObjectManager::SetMainTarget (0.85) -> CGLockTarget; server set_locked_target
    return std::unique_ptr<pg::Packet>(packet.release());
}

std::unique_ptr<pg::Packet> WorldModel::makeExteriorApply(uint32_t category, uint32_t index) const { // CYS-RIDE
    std::unique_ptr<pg::CGExteriorRequest> packet(new pg::CGExteriorRequest);
    packet->type = 7;
    packet->size = 1;
    pg::CGExteriorRequest::E_list entry;
    entry.unknow_1 = category;                              // 0 face, 1 hair, 2 portrait, 3 RIDE, 4 pet soul
    entry.unknow_2 = static_cast<uint16_t>(index);
    packet->list.push_back(entry);
    return std::unique_ptr<pg::Packet>(packet.release());
}

std::unique_ptr<pg::Packet> WorldModel::makeAutoRide(uint32_t flag) const { // CYS-RIDE
    std::unique_ptr<pg::CGCharAutoRide> packet(new pg::CGCharAutoRide);
    packet->flag = flag;
    return std::unique_ptr<pg::Packet>(packet.release());
}

std::unique_ptr<pg::Packet> WorldModel::makeUseSkill(int32_t skillDataId, int32_t targetId) const {
    // misc.lua CGCharUseSkill.bis: dir, skillID, target, m_objID, targetObjID, posTarget. The server uses
    // skillID/targetObjID/posTarget/dir only (scenecore.lua char_use_skill); 0.85 put the target GUID in `target`.
    std::unique_ptr<pg::CGCharUseSkill> packet(new pg::CGCharUseSkill);
    packet->m_objID = myObjectId_;
    packet->skillID = skillDataId;
    packet->target = targetId;
    packet->targetObjID = targetId;
    float tx = myX_, ty = myY_;
    auto found = objects_.find(static_cast<uint32_t>(targetId));
    if (found != objects_.end()) { tx = found->second.x; ty = found->second.y; }
    packet->posTarget_x = tx; packet->posTarget_y = ty;
    packet->dir = std::atan2(ty - myY_, tx - myX_);
    return std::unique_ptr<pg::Packet>(packet.release());
}

std::unique_ptr<pg::Packet> WorldModel::makeChat(uint8_t chatType, const std::string& utf8) const {
    // social.lua CGChat.bis: ChatType u8, Contex str32, unknow_7 str8 (empty), unknow_8 u32, unknow_9 u8,
    // unknow_10 u32, ChatType branch (0: unknow_2 u16), uts[3] = 0 (no item/pet/exterior links).
    std::unique_ptr<pg::CGChat> packet(new pg::CGChat);
    packet->ChatType = chatType;
    packet->set_Contex(utf8);
    packet->unknow_2 = 0; packet->unknow_8 = 0; packet->unknow_9 = 0; packet->unknow_10 = 0;
    packet->uts.fill(0);
    return std::unique_ptr<pg::Packet>(packet.release());
}

std::unique_ptr<pg::Packet> WorldModel::makeOpenItemBox(uint32_t boxId) const {
    std::unique_ptr<pg::CGOpenItemBox> packet(new pg::CGOpenItemBox);
    packet->m_objID = boxId;
    return std::unique_ptr<pg::Packet>(packet.release());
}

std::unique_ptr<pg::Packet> WorldModel::makePickBoxItem(uint32_t boxId, const pg::ItemGUID& guid) const {
    std::unique_ptr<pg::CGPickBoxItem> packet(new pg::CGPickBoxItem);
    packet->m_objID = boxId;
    packet->item_guid = guid;
    return std::unique_ptr<pg::Packet>(packet.release());
}

std::unique_ptr<pg::Packet> WorldModel::makeAskMyBagList() const {
    std::unique_ptr<pg::CGAskMyBagList> packet(new pg::CGAskMyBagList); // ASK_ALL: mode 0, no indices
    packet->unknow_1 = 0; packet->size = 0;
    return std::unique_ptr<pg::Packet>(packet.release());
}

std::unique_ptr<pg::Packet> WorldModel::makeAskDetailSkillList() const {
    std::unique_ptr<pg::CGAskDetailSkillList> packet(new pg::CGAskDetailSkillList);
    packet->m_objID = myObjectId_;
    return std::unique_ptr<pg::Packet>(packet.release());
}

// CYS-SKILL
std::unique_ptr<pg::Packet> WorldModel::makeAskSetting() const {
    return std::unique_ptr<pg::Packet>(new pg::CGAskSetting);
}

std::unique_ptr<pg::Packet> WorldModel::makeModifySetting(uint8_t settingType, uint8_t type, uint32_t data) const {
    // misc.lua CGModifySetting.bis: type (SETTING_TYPE), setting.type (ACTION_OPTYPE), setting.data. The server stores
    // key tostring(type + 1) and ignores the packet during the first 3 s in a scene (scenecore char_modify_setting).
    std::unique_ptr<pg::CGModifySetting> packet(new pg::CGModifySetting);
    packet->type = settingType; packet->setting_type = type; packet->setting_data = data;
    return std::unique_ptr<pg::Packet>(packet.release());
}

std::unique_ptr<pg::Packet> WorldModel::makeAskDetailXinFaList() const {
    std::unique_ptr<pg::CGAskDetailXinFaList> packet(new pg::CGAskDetailXinFaList);
    packet->m_objID = myObjectId_;
    return std::unique_ptr<pg::Packet>(packet.release());
}

std::unique_ptr<pg::Packet> WorldModel::makeAskStudyXinfa(uint16_t menpai, uint16_t xinfa, uint16_t nowLevel) const {
    // msgagent CGAskStudyXinfa: the xinfa must be in the own list and now_level must equal its level.
    std::unique_ptr<pg::CGAskStudyXinfa> packet(new pg::CGAskStudyXinfa);
    packet->menpai = menpai; packet->xinfa = xinfa; packet->now_level = nowLevel;
    return std::unique_ptr<pg::Packet>(packet.release());
}

std::unique_ptr<pg::Packet> WorldModel::makePlayerDieResult(uint32_t code) const {
    std::unique_ptr<pg::CGPlayerDieResult> packet(new pg::CGPlayerDieResult);
    packet->code = code;
    return std::unique_ptr<pg::Packet>(packet.release());
}

// CYS-TEAM -------------------------------------------------------------------------------------
// team.lua CGTeamInvite.bis: data_length i32 (read and ignored by worldcore), m_objID, unknow (-1 in
// the CY client), dest_name str8, unknow_1 u16. worldcore:char_invite_team only reads dest_name.
std::unique_ptr<pg::Packet> WorldModel::makeTeamInvite(const std::string& destName) const {
    std::unique_ptr<pg::CGTeamInvite> packet(new pg::CGTeamInvite);
    packet->m_objID = static_cast<int32_t>(myObjectId_);
    packet->unknow = -1;
    packet->set_dest_name(destName);
    packet->data_length = static_cast<int32_t>(11 + packet->dest_name.size()); // m_objID+unknow+len+name+u16
    packet->unknow_1 = 0;
    return std::unique_ptr<pg::Packet>(packet.release());
}

// team.lua CGTeamRetInvite.bis: return_type u8 (1 = accept, 0 = refuse), guid u32 = the INVITER,
// unknow_3 u32, list[8] u32. worldcore:char_ret_invite looks the inviter up by ret.guid.
std::unique_ptr<pg::Packet> WorldModel::makeTeamRetInvite(uint8_t accept, int32_t inviterGuid) const {
    std::unique_ptr<pg::CGTeamRetInvite> packet(new pg::CGTeamRetInvite);
    packet->return_type = accept;
    packet->guid = static_cast<uint32_t>(inviterGuid);
    packet->unknow_3 = 0;
    packet->list.fill(0);
    return std::unique_ptr<pg::Packet>(packet.release());
}

std::unique_ptr<pg::Packet> WorldModel::makeTeamApply(const std::string& destName) const {
    std::unique_ptr<pg::CGTeamApply> packet(new pg::CGTeamApply);
    packet->source_guid = myGuid_; packet->unknow_1 = -1;
    packet->set_dest_name(destName);
    packet->unknow_2 = 0;
    return std::unique_ptr<pg::Packet>(packet.release());
}

std::unique_ptr<pg::Packet> WorldModel::makeTeamRetApply(uint8_t accept, int32_t sourceGuid) const {
    std::unique_ptr<pg::CGTeamRetApply> packet(new pg::CGTeamRetApply);
    packet->return_type = accept;
    packet->source_guid = sourceGuid;
    packet->dest_guid = myGuid_;
    packet->team_guids.fill(0);
    return std::unique_ptr<pg::Packet>(packet.release());
}

// worldcore:char_team_kick / char_team_appoint read dest_guid only and require the sender to be the leader.
std::unique_ptr<pg::Packet> WorldModel::makeTeamKick(int32_t memberGuid) const {
    std::unique_ptr<pg::CGTeamKick> packet(new pg::CGTeamKick);
    packet->source_guid = myGuid_; packet->dest_guid = memberGuid;
    return std::unique_ptr<pg::Packet>(packet.release());
}

std::unique_ptr<pg::Packet> WorldModel::makeTeamAppoint(int32_t memberGuid) const {
    std::unique_ptr<pg::CGTeamAppoint> packet(new pg::CGTeamAppoint);
    packet->source_guid = myGuid_; packet->dest_guid = memberGuid;
    return std::unique_ptr<pg::Packet>(packet.release());
}

std::unique_ptr<pg::Packet> WorldModel::makeTeamLeave() const {
    std::unique_ptr<pg::CGTeamLeave> packet(new pg::CGTeamLeave); // worldcore uses the session guid
    packet->guid = myGuid_;
    return std::unique_ptr<pg::Packet>(packet.release());
}

std::unique_ptr<pg::Packet> WorldModel::makeTeamDismiss() const {
    std::unique_ptr<pg::CGTeamDismiss> packet(new pg::CGTeamDismiss);
    packet->guid = myGuid_;
    return std::unique_ptr<pg::Packet>(packet.release());
}

std::unique_ptr<pg::Packet> WorldModel::makeAskTeamInfo() const {
    std::unique_ptr<pg::CGAskTeamInfo> packet(new pg::CGAskTeamInfo);
    packet->m_objID = myObjectId_;
    return std::unique_ptr<pg::Packet>(packet.release());
}

std::unique_ptr<pg::Packet> WorldModel::makeTeamChangeOption(uint32_t expMode) const {
    std::unique_ptr<pg::CGTeamChangeOption> packet(new pg::CGTeamChangeOption);
    packet->unknow_1 = 0;
    packet->exp_mode = expMode;
    return std::unique_ptr<pg::Packet>(packet.release());
}

std::unique_ptr<pg::Packet> WorldModel::makeAskTeamMemberInfo(int32_t memberGuid) const {
    std::unique_ptr<pg::CGAskTeamMemberInfo> packet(new pg::CGAskTeamMemberInfo);
    packet->m_objID = static_cast<int32_t>(myObjectId_);
    packet->guid = memberGuid;
    packet->sceneid = static_cast<int16_t>(sceneId_);
    return std::unique_ptr<pg::Packet>(packet.release());
}

// social.lua CGChat branch CHAT_TYPE_TEAM (1): the u16 after the common header is teamID.
std::unique_ptr<pg::Packet> WorldModel::makeTeamChat(const std::string& utf8) const {
    std::unique_ptr<pg::CGChat> packet(new pg::CGChat);
    packet->ChatType = 1;
    packet->set_Contex(utf8);
    packet->teamID = teamId_;
    packet->unknow_8 = 0; packet->unknow_9 = 0; packet->unknow_10 = 0;
    packet->uts.fill(0);
    return std::unique_ptr<pg::Packet>(packet.release());
}

// social.lua CGChat branch CHAT_TYPE_TELL (3): TargetName str8 then a u16. scenecore gates it behind
// check_limit_chat (level >= 50) before it reaches worldcore:tell_chat.
std::unique_ptr<pg::Packet> WorldModel::makeTellChat(const std::string& target, const std::string& utf8) const {
    std::unique_ptr<pg::CGChat> packet(new pg::CGChat);
    packet->ChatType = 3;
    packet->set_Contex(utf8);
    packet->set_TargetName(target);
    packet->unknow_2 = 0; packet->unknow_8 = 0; packet->unknow_9 = 0; packet->unknow_10 = 0;
    packet->uts.fill(0);
    return std::unique_ptr<pg::Packet>(packet.release());
}

// CYS-INV ------------------------------------------------------------------------------------------
std::unique_ptr<pg::Packet> WorldModel::makeAskDetailEquipList() const {
    std::unique_ptr<pg::CGAskDetailEquipList> packet(new pg::CGAskDetailEquipList);
    packet->m_objID = myObjectId_; // scenecore.lua ask_detail_equip_list: objs[ask.m_objID] must be a human
    return std::unique_ptr<pg::Packet>(packet.release());
}

std::unique_ptr<pg::Packet> WorldModel::makeAskDetailAttrib() const {
    std::unique_ptr<pg::CGAskDetailAttrib> packet(new pg::CGAskDetailAttrib);
    packet->m_objID = myObjectId_;
    return std::unique_ptr<pg::Packet>(packet.release());
}

std::unique_ptr<pg::Packet> WorldModel::makeUseEquip(uint8_t bagIndex, uint8_t equipPoint) const {
    std::unique_ptr<pg::CGUseEquip> packet(new pg::CGUseEquip);
    packet->bagIndex = bagIndex; packet->equipPoint = equipPoint;
    packet->type = 0; // 2 = fashion depot (char_use_equip HEQUIP_FASHION); 0 = from the prop bag
    return std::unique_ptr<pg::Packet>(packet.release());
}

std::unique_ptr<pg::Packet> WorldModel::makeUnEquip(uint8_t equipPoint) const {
    std::unique_ptr<pg::CGUnEquip> packet(new pg::CGUnEquip);
    packet->equipPoint = equipPoint; packet->unknow_2 = 0; packet->unknow_3 = 0; packet->unknow_4 = 0;
    return std::unique_ptr<pg::Packet>(packet.release());
}

std::unique_ptr<pg::Packet> WorldModel::makeDiscardItem(uint8_t bagIndex) const {
    std::unique_ptr<pg::CGDiscardItem> packet(new pg::CGDiscardItem);
    packet->bag_index = bagIndex; packet->opt = 0; // item.lua CGDiscardItem.OPT.FromBag
    return std::unique_ptr<pg::Packet>(packet.release());
}

std::unique_ptr<pg::Packet> WorldModel::makePackageSwap(uint8_t from, uint8_t to) const {
    std::unique_ptr<pg::CGPackage_SwapItem> packet(new pg::CGPackage_SwapItem);
    packet->index_from = from; packet->index_to = to; packet->count = 0;
    return std::unique_ptr<pg::Packet>(packet.release());
}

std::unique_ptr<pg::Packet> WorldModel::makeSplitItem(uint8_t bagIndex, uint32_t count) const {
    std::unique_ptr<pg::CGSplitItem> packet(new pg::CGSplitItem);
    packet->container = 1; packet->position = bagIndex; packet->num = count; // item.lua Container.BAG_CON
    return std::unique_ptr<pg::Packet>(packet.release());
}

std::unique_ptr<pg::Packet> WorldModel::makeCharDefaultEvent(uint32_t npcId) const {
    std::unique_ptr<pg::CGCharDefaultEvent> packet(new pg::CGCharDefaultEvent);
    packet->m_objID = npcId; // scenecore.lua char_default_event: objs[args.m_objID]:default_event(who)
    packet->targetID = myObjectId_;
    return std::unique_ptr<pg::Packet>(packet.release());
}

std::unique_ptr<pg::Packet> WorldModel::makeEventRequest(int32_t scriptId, int32_t index, int32_t npcId) const {
    std::unique_ptr<pg::CGEventRequest> packet(new pg::CGEventRequest);
    // scenecore.lua char_event_request: m_objID = script id, index = option, arg = NPC object (-1 = no NPC)
    packet->m_objID = scriptId; packet->index = index; packet->arg = npcId; packet->unknow = 0;
    return std::unique_ptr<pg::Packet>(packet.release());
}

// CYS-QUEST ----------------------------------------------------------------------------------------
const WorldModel::Mission* WorldModel::findMission(int32_t missionId) const {
    for (const auto& m : missions_) if (m.id == missionId) return &m;
    return nullptr;
}

bool WorldModel::missionHaveDone(int32_t missionId) const {
    if (missionId < 0 || (missionId >> 5) >= 128) return false;
    return (doneFlags_[missionId >> 5] & (1u << (missionId & 31))) != 0;
}

std::unique_ptr<pg::Packet> WorldModel::makeAskMissionList() const {
    std::unique_ptr<pg::CGAskMissionList> packet(new pg::CGAskMissionList);
    packet->m_objID = myObjectId_; // scenecore.lua char_ask_mission_list -> human:send_mission_list (288)
    return std::unique_ptr<pg::Packet>(packet.release());
}

std::unique_ptr<pg::Packet> WorldModel::makeMissionAccept(int32_t npcId, int32_t scriptId) const {
    // scenecore.lua char_mission_accept: objs[m_idNPC]:get_script_id() "OnMissionAccept"(who, npc, m_idScript)
    std::unique_ptr<pg::CGMissionAccept> packet(new pg::CGMissionAccept);
    packet->m_idNPC = npcId; packet->unknow = -1; packet->m_idScript = scriptId;
    return std::unique_ptr<pg::Packet>(packet.release());
}

std::unique_ptr<pg::Packet> WorldModel::makeMissionContinue(int32_t npcId, int32_t scriptId) const {
    std::unique_ptr<pg::CGMissionContinue> packet(new pg::CGMissionContinue); // char_mission_continue -> OnMissionContinue
    packet->m_idNPC = npcId; packet->unknow = -1; packet->m_idScript = scriptId;
    return std::unique_ptr<pg::Packet>(packet.release());
}

std::unique_ptr<pg::Packet> WorldModel::makeMissionSubmit(int32_t npcId, int32_t scriptId, int32_t radio) const {
    std::unique_ptr<pg::CGMissionSubmit> packet(new pg::CGMissionSubmit); // char_mission_submit -> OnMissionSubmit
    packet->npc_id = npcId; packet->script_id = scriptId; packet->select_radio_id = radio; packet->unknow_4 = 0;
    return std::unique_ptr<pg::Packet>(packet.release());
}

std::unique_ptr<pg::Packet> WorldModel::makeMissionAbandon(int32_t scriptId) const {
    std::unique_ptr<pg::CGMissionAbandon> packet(new pg::CGMissionAbandon);
    packet->index = scriptId;
    return std::unique_ptr<pg::Packet>(packet.release());
}

std::unique_ptr<pg::Packet> WorldModel::makeShopBuy(uint8_t merchIndex, uint32_t count) const {
    std::unique_ptr<pg::CGShopBuy> packet(new pg::CGShopBuy);
    // shop.lua CGShopBuy.bis; scenecore.lua char_shop_buy: index < BUY_BACK_INDEX(200) -> do_shop(index + 1, buy_num)
    packet->index = merchIndex; packet->series_num = 0;
    packet->unique_id = static_cast<uint32_t>(shop_.uniqueId);
    packet->buy_num = count;
    packet->unknow_1 = 0; packet->unknow_2 = 0; packet->unknow_3 = 0; packet->unknow_4 = 0;
    return std::unique_ptr<pg::Packet>(packet.release());
}

std::unique_ptr<pg::Packet> WorldModel::makeShopSell(uint8_t bagIndex) const {
    std::unique_ptr<pg::CGShopSell> packet(new pg::CGShopSell);
    packet->bag_index = bagIndex; packet->unknow_2 = 0; packet->unknow_3 = 0; // human:shop_sell(sell.bag_index)
    return std::unique_ptr<pg::Packet>(packet.release());
}

}} // namespace cys::net
