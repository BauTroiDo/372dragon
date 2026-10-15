#include "StdAfx.h"
#include "CysInventoryNet.h"
#include "CysInspectNet.h"
#include "CysTemBank.h"
#include "CysSkillNet.h"
#include "CysUiCommandParams.h"
#include "CysTooltipContract.h"
#include "CysEventTextJoin.h" // CYS-QUEST
#include "CysQuestNet.h"      // CYS-QUEST: EventListText
#include <vector>

#if defined(CYS_HAVE_NETCORE)
// CYS-INV: inventory / equipment / NPC shop on the CY skynet protocol (Docs/specs/net/inventory-equip_vi.md).
// Server behaviour (read-only clone /home/ubuntu/cys-test-20260913): scenecore.lua char_use_equip / char_un_equip /
// char_discard_item / package_swap_item / char_shop_buy / char_shop_sell / char_event_request, human.lua do_shop /
// shop_sell / split_item / send_sold_out_list, script_base.lua DispatchShopItem.
#include "CysModernHandlers.h"
#include "CysModernGame.h"
#include "CysHost_Package.h"
#include "CysHost_NbShop.h"
#include "CysHost_Wardrobe.h" // CYS-WARD2: GCAskFashionDepotData feeds the wardrobe's fashion depot
#include "..\Script\GMScriptSystem.h"
#include "..\Interface\GMInterface_Script_Tooltip.h"
#include "..\Interface\GMGameInterface.h"
#include "CysEquipmentTooltipFormat.h"
#include "..\DBC\GMDataBase.h"
#include "TDDBC_Struct.h"
#include <string>
#include "PgPackets_item.h"
#include "PgPackets_misc.h"
#include "PgPackets_mission.h"
#include "PgPackets_shop.h"
#include "PgPackets_core.h"
#include "TDEventDefine.h"
#include "TDUtil.h"
#include "GameStruct_Item.h"
#include "ScriptCommandStruct.h"
#include "..\Procedure\GameProcedure.h"
#include "..\Procedure\GamePro_Main.h"
#include "..\Object\ObjectManager.h"
#include "..\Object\Character\Obj_PlayerMySelf.h"
#include "..\Object\Item\Obj_Item.h"
#include "..\Object\Item\Obj_Item_Equip.h"
#include "..\DataPool\GMDataPool.h"
#include "..\DataPool\GMUIDataPool.h"
#include "..\DataPool\GMDP_CharacterData.h"
#include "..\Action\GMActionSystem.h"
#include "..\Event\GMEventSystem.h"
#include "..\Sound\GMSoundSystem.h"
#include "..\Global.h"
#include "TDUISystem.h"
#include "CGUseEquip.h"
#include "CGUnEquip.h"
#include "CGDiscardItem.h"
#include "CGSplitItem.h"
#include "CGPackUpPacket.h"
#include "CGPackage_SwapItem.h"
#include "CGShopBuy.h"
#include "CGShopSell.h"
#include "CGCharDefaultEvent.h"
#include "CGEventRequest.h"
#include "CGUseItem.h"
#include "CGAskDetailEquipList.h"
#include "CGAskItemInfo.h"
#include <cstdarg>
#include <cstring>

namespace
{
    CysInventoryNet::Counters g_counters = {};
    int g_propSize = 20, g_materialSize = 20; // base capacity until GCBagSizeChange arrives
    bool g_sizeKnown = false, g_sizeAsked = false;
    int g_shopScript = -1, g_shopIndex = -1;
    unsigned g_logs = 0;

    bool IsMain() { return CGameProcedure::GetActiveProcedure() == (CGameProcedure*)CGameProcedure::s_pProcMain; }

    void InvLog(const char* fmt, ...)
    {
        // CYS-UNEQUIP 20/09/2026: say ONCE that the budget ran out. The user's 19-minute session (stage-play-5,
        // 14:30) spent all 96 lines by 14:38:31 - seven seconds before the character frame was first opened - and
        // "there is no CGUnEquip line" was then read as "the client never sent it". A silent cap turns every later
        // absence into a false negative; the line below makes the cap visible in the log itself.
        if (g_logs >= 96)
        {
            static bool s_said = false;
            if (!s_said)
            {
                s_said = true;
                TDU_Log("CYS inv: log budget of 96 lines is spent - inventory lines below this point are NOT written "
                        "(only equip / unequip gestures still are); an absent line proves nothing from here on");
            }
            return;
        }
        ++g_logs;
        char text[512] = {};
        va_list args; va_start(args, fmt);
        _vsnprintf(text, sizeof(text) - 1, fmt, args);
        va_end(args);
        TDU_Log("CYS inv: %s", text);
    }

    // CYS-UNEQUIP: lines that are 1:1 with a gesture of the player on a piece of equipment (put on / take off and
    // the server's answer). One line per gesture is a rare event, not a hot path, so they bypass the budget: these
    // are exactly the lines a "cannot take my weapon off" report is diagnosed with.
    void InvLogGesture(const char* fmt, ...)
    {
        char text[512] = {};
        va_list args; va_start(args, fmt);
        _vsnprintf(text, sizeof(text) - 1, fmt, args);
        va_end(args);
        TDU_Log("CYS inv: %s", text);
    }

    void Tip(const char* utf8)
    {
        CEventSystem::GetMe()->PushEvent(GE_NEW_DEBUGMESSAGE, utf8);
    }

    // ---------------------------------------------------------------------------------------------------------
    // GCUseEquipResultHandler (define.UseEquipResultCode: 1 success, 2 level, 3 type, 4 ident, 5 job)
    void OnUseEquipResult(const pg::GCUseEquipResult& p)
    {
        ++g_counters.useEquip;
        InvLogGesture("GCUseEquipResult result=%u point=%u bag=%u item=%d old=%d", p.result, p.equipPoint, p.bagIndex, p.item_index, p.equipTableIndex);
        if (!IsMain()) return;
        CDataPool* pool = CDataPool::GetMe();
        switch (p.result)
        {
        case 1:
        {
            tObject_Item* atBag = pool->UserBag_GetItem(p.bagIndex);
            if (!atBag || atBag->GetItemClass() != ICLASS_EQUIP) { InvLogGesture("GCUseEquipResult: bag slot %u holds no equipment on the client", p.bagIndex); break; }
            tObject_Item* atUser = pool->UserEquip_GetItem((HUMAN_EQUIP)p.equipPoint);
            ((CObject_Item*)atBag)->ChangeClientID();
            if (atUser) ((CObject_Item*)atUser)->ChangeClientID();
            if (p.equipPoint < HEQUIP_NUMBER)
                CObjectManager::GetMe()->GetMySelf()->GetCharacterData()->Set_Equip((HUMAN_EQUIP)p.equipPoint, atBag->GetIdTable());
            pool->UserEquip_SetItem((HUMAN_EQUIP)p.equipPoint, atBag, FALSE);
            if (atUser)
            {
                atUser->SetGUID(p.equip_guid.world, p.equip_guid.server, (GUID_t)p.equip_guid.series);
                atUser->SetTypeOwner(tObject_Item::IO_MYSELF_PACKET);
                atUser->SetPosIndex(p.bagIndex);
            }
            pool->UserBag_SetItem(p.bagIndex, atUser, FALSE);
            CActionSystem::GetMe()->UserBag_Update();
            CEventSystem::GetMe()->PushEvent(GE_PACKAGE_ITEM_CHANGED, p.bagIndex);
            CSoundSystemFMod::_PlayUISoundFunc(67);
            break;
        }
        case 2: Tip(u8"Cấp độ trang bị cao hơn cấp hiện tại"); break;
        case 3: Tip(u8"Sai loại trang bị"); break;
        case 5: Tip(u8"Môn phái không phù hợp"); break;
        default: Tip(u8"Lỗi không xác định"); break;
        }
        CActionSystem::GetMe()->UserEquip_Update();
        CEventSystem::GetMe()->PushEvent(GE_UPDATE_EQUIP);
    }

    // GCUnEquipResultHandler (scenecore.lua char_un_equip: result 1 = moved to bag_index; 3 = fashion depot full)
    void OnUnEquipResult(const pg::GCUnEquipResult& p)
    {
        ++g_counters.unEquip;
        InvLogGesture("GCUnEquipResult result=%u point=%u bag=%u item=%d", p.result, p.equipPoint, p.bagIndex, p.item_index);
        if (!IsMain()) return;
        if (p.result != 1) { Tip(u8"Túi đồ đã đầy!"); CSoundSystemFMod::_PlayUISoundFunc(96); return; }
        tObject_Item* item = CDataPool::GetMe()->UserEquip_GetItem((HUMAN_EQUIP)p.equipPoint);
        if (!item) return;
        ((CObject_Item*)item)->ChangeClientID();
        if (p.bagIndex != 255) CDataPool::GetMe()->UserBag_SetItem(p.bagIndex, item, TRUE);
        CDataPool::GetMe()->UserEquip_SetItem((HUMAN_EQUIP)p.equipPoint, NULL, FALSE);
        if (p.bagIndex == 255) CObject_Item::DestroyItem((CObject_Item*)item); // fashion -> depot, not the bag
        CObject_PlayerMySelf* self = CObjectManager::GetMe()->GetMySelf();
        if (self && p.equipPoint < HEQUIP_NUMBER)
        {
            self->UnEquipItem((HUMAN_EQUIP)p.equipPoint);
            self->GetCharacterData()->Set_Equip((HUMAN_EQUIP)p.equipPoint, -1);
        }
        CActionSystem::GetMe()->UserEquip_Update();
        CActionSystem::GetMe()->UserBag_Update();
        CEventSystem::GetMe()->PushEvent(GE_UPDATE_EQUIP);
        CEventSystem::GetMe()->PushEvent(GE_PACKAGE_ITEM_CHANGED);
        CSoundSystemFMod::_PlayUISoundFunc(67);
    }

    // GCDetailEquipListHandler (own object: the data pool of SelfEquip; other players: the target equipment view)
    void OnDetailEquipList(const pg::GCDetailEquipList& p)
    {
        ++g_counters.equipLists;
        if (!IsMain()) return;
        CObject* object = (CObject*)CObjectManager::GetMe()->FindServerObject((INT)p.m_objID);
        CObject_PlayerMySelf* self = CObjectManager::GetMe()->GetMySelf();
        unsigned present = 0;
        const bool mine = object && object == (CObject*)self;
        if (!mine && !CysInspectNet::AcceptEquipment((int)p.m_objID)) return;
        if (!mine) CDataPool::GetMe()->OtherPlayerEquip_Clear();
        for (size_t i = 0; i < p.itemList.size(); ++i)
        {
            const bool has = p.itemList[i].present;
            if (!mine)
            {
                if (i >= CYS_CLIENT_EQUIP_SLOTS) continue;
                if (!has) { CDataPool::GetMe()->OtherPlayerEquip_SetItem((HUMAN_EQUIP)i, NULL, TRUE); continue; }
            }
            if (!has || i >= CYS_CLIENT_EQUIP_SLOTS) continue;
            _ITEM item;
            CysModernHandlers::ItemInfoToLegacy(p.itemList[i].anon1, item);
            CObject_Item* obj = CObject_Item::NewItem(item.m_ItemIndex);
            if (!obj) { InvLog("GCDetailEquipList point %u item %u unknown to the item tables", (unsigned)i, item.m_ItemIndex); continue; }
            ++present;
            obj->SetGUID(item.m_ItemGUID.m_World, item.m_ItemGUID.m_Server, (GUID_t)item.m_ItemGUID.m_Serial);
            obj->SetExtraInfo(&item);
            obj->SetPosIndex((INT)i);
            if (mine)
            {
                obj->SetTypeOwner(tObject_Item::IO_MYSELF_EQUIP);
                CDataPool::GetMe()->UserEquip_SetItem((HUMAN_EQUIP)i, obj);
                if (CDataPool::GetMe()->UserEquip_GetItem((HUMAN_EQUIP)i) != obj) CObject_Item::DestroyItem(obj); // point refused
            }
            else
            {
                obj->SetTypeOwner(tObject_Item::IO_PLAYEROTHER_EQUIP);
                CDataPool::GetMe()->OtherPlayerEquip_SetItem((HUMAN_EQUIP)i, obj);
                if (CDataPool::GetMe()->OtherPlayerEquip_GetItem((HUMAN_EQUIP)i) != obj) CObject_Item::DestroyItem(obj);
            }
        }
        InvLog("GCDetailEquipList obj=%u mine=%d mode=%u items=%u", p.m_objID, mine ? 1 : 0, p.m_mode, present);
        if (mine)
        {
            CActionSystem::GetMe()->UserEquip_Update();
            CEventSystem::GetMe()->PushEvent(GE_UPDATE_EQUIP);
        }
        else if (object)
        {
            CActionSystem::GetMe()->OtherPlayerEquip_Update();
            CysInspectNet::EquipmentReady();
        }
    }

    // GCCharEquipmentHandler: visible equipment of a character (broadcast by scenecore.lua broad_char_equioment).
    // CY flag bits (misc.lua:2364-2435): 0x1 weapon, 0x2 cap, 0x4 armour, 0x8 cuff(glove, point 3), 0x10 boot.
    void OnCharEquipment(const pg::GCCharEquipment& p)
    {
        ++g_counters.charEquipments;
        if (!IsMain()) return;
        CObject* object = (CObject*)CObjectManager::GetMe()->FindServerObject((INT)p.m_objID);
        if (!object || !g_theKernel.IsKindOf(object->GetClass(), GETCLASS(CObject_Character))) return;
        CCharacterData* data = ((CObject_Character*)object)->GetCharacterData();
        if (p.flag & 0x1) { data->Set_EquipGem(HEQUIP_WEAPON, p.WeaponGemID); data->Set_Equip(HEQUIP_WEAPON, p.m_WeaponID); }
        if (p.flag & 0x2) data->Set_Equip(HEQUIP_CAP, p.m_CapID);
        if (p.flag & 0x4) data->Set_Equip(HEQUIP_ARMOR, p.m_ArmourID);
        if (p.flag & 0x8) data->Set_Equip(HEQUIP_CUFF, p.m_CuffID);
        if (p.flag & 0x10) data->Set_Equip(HEQUIP_BOOT, p.unknow_6_a);
        // CYS-DRESS: 时装 (装备点 16, bit 0x10000 do scenecore.lua set_fasion dat). `visual` la chi so EquipDress,
        // khong phai id ItemVisualChar; chuoi day du o Docs/specs/server/costumes-all_vi.md.
        if (p.flag & 0x10000) data->Set_DressVisual(p.fashion_item_id > 0 ? (INT)p.visual : INVALID_ID);
        if (p.flag & 0x40000) {
            data->Set_WuhunAppearance(p.wuhun_item_id,p.wuhun_visual);
            CEventSystem::GetMe()->PushEventByName("CYS_WUHUN_APPEARANCE",{});
            InvLogGesture("soul appearance obj=%u item=%d visual=%d",p.m_objID,p.wuhun_item_id,p.wuhun_visual);
        }
        InvLog("GCCharEquipment obj=%u flag=0x%x weapon=%d(visual %d) cap=%d armour=%d cuff=%d boot=%d dress=%d(visual %d)",
               p.m_objID, p.flag, p.m_WeaponID, p.Weapon_visual, p.m_CapID, p.m_ArmourID, p.m_CuffID, p.unknow_6_a,
               p.fashion_item_id, p.visual);
        object->PushDebugString("GCCharEquipment");
    }

    // GCShopMerchandiseListHandler (script_base.lua DispatchShopItem)
    void OnShopMerchandiseList(const pg::GCShopMerchandiseList& p)
    {
        ++g_counters.shopLists;
        if (!IsMain()) return;
        CDataPool* pool = CDataPool::GetMe();
        pool->Booth_Clear();
        pool->Booth_Sold_Clear();
        INT shown = 0;
        for (size_t i = 0; i < p.merchadise_list.size() && i < MAX_BOOTH_NUMBER; ++i)
        {
            const auto& m = p.merchadise_list[i];
            tObject_Item* item = CObject_Item::NewItem(m.id);
            if (!item) { InvLog("GCShopMerchandiseList item %u unknown to the item tables", m.id); continue; }
            item->SetPosIndex((INT)i);
            item->SetNumber(m.pnum > 0 ? m.pnum : 1);
            item->SetMax(m.pmax);
            pool->Booth_SetItemPrice((INT)i, m.price);
            pool->Booth_SetItem((INT)i, item);
            shown = (INT)i + 1;
        }
        pool->Booth_SetNumber(shown);
        pool->Booth_SetBuyType(p.sold_type);
        pool->Booth_SetRepairType(-1);
        pool->Booth_SetCallBack(1);
        const int walletType=p.shop_type==9?5:(p.shop_type==8?1:p.shop_type);
        pool->Booth_SetCurrencyUnit(walletType); // Legacy bound shops use the two canonical wallets.
        pool->Booth_SetSerialNum(0);
        pool->Booth_SetbCanBuyMult(p.can_multiple_buy);
        pool->Booth_SetShopType(walletType == 5 ? 1 : 0);
        if (shown > 0) CActionSystem::GetMe()->Booth_Update();
        pool->Booth_Open();
        tObject* npc = CObjectManager::GetMe()->FindServerObject(p.m_objID);
        if (npc) CUIDataPool::GetMe()->SetCurShopNpcId(npc->GetServerID());
        pool->Booth_SetShopNpcId(npc ? npc->GetID() : -1);
        pool->Booth_SetShopUniqueId((UINT)p.unique_id);
        InvLog("GCShopMerchandiseList shop=%d npc=%d type=%u goods=%u shown=%d unique=%d", p.shop_id, p.m_objID, p.shop_type,
               (unsigned)p.merchadise_list.size(), shown, p.unique_id);
        // The GL server's flag 2 means mystery shop, not the CY outfit shop. Only flag 1 has shared meaning.
        if (p.is_yuanbao_shop == 1 && !CysHostNbShop::Off('o'))
        {
            TDU_Log("CYS-NBSHOP: OPEN_YUANBAOSHOP shop=%d goods=%u shown=%d currency=%u", p.shop_id,
                    (unsigned)p.merchadise_list.size(), shown, p.shop_type);
            CEventSystem::GetMe()->PushEvent(GE_OPEN_YUANBAOSHOP);
        }
        else CEventSystem::GetMe()->PushEvent(GE_OPEN_BOOTH);
    }

    // GCShopSoldListHandler: buy-back list; each entry is item:get_stream() (188 bytes, head = ItemGUID + index).
    void OnShopSoldList(const pg::GCShopSoldList& p)
    {
        ++g_counters.soldLists;
        if (!IsMain()) return;
        CDataPool* pool = CDataPool::GetMe();
        pool->Booth_Sold_Clear();
        INT count = 0;
        for (size_t i = 0; i < p.item_list.size() && i < MAX_BOOTH_SOLD_NUMBER; ++i)
        {
            const std::string& bytes = p.item_list[i].item.anon1;
            if (bytes.size() < 14) continue;
            const unsigned char* b = (const unsigned char*)bytes.data();
            UINT serial = 0; INT index = 0;
            std::memcpy(&serial, b + 4, 4);
            std::memcpy(&index, b + 8, 4);
            tObject_Item* item = CObject_Item::NewItem((UINT)index);
            if (!item) continue;
            item->SetGUID(b[0], b[1], (GUID_t)serial);
            item->SetPosIndex(count);
            item->SetNumber(1);
            item->SetMax(1);
            pool->Booth_SetSoldItem(count, item);
            pool->Booth_SetSoldPrice(count, p.item_list[i].price);
            ++count;
        }
        pool->Booth_SetSoldNumber(count);
        InvLog("GCShopSoldList items=%u shown=%d", (unsigned)p.item_list.size(), count);
        CActionSystem::GetMe()->Booth_Update();
        CEventSystem::GetMe()->PushEvent(GE_UPDATE_BOOTH);
    }

    // GCShopBuyHandler (shop.lua BUY_RESULT: 0 ok, 1 buy back ok, 2 money, 4 bag full)
    void OnShopBuy(const pg::GCShopBuy& p)
    {
        ++g_counters.shopBuys;
        InvLog("GCShopBuy result=%u item=%d count=%d price=%u", p.result, p.item_index, p.count, p.price);
        if (!IsMain()) return;
        switch (p.result)
        {
        case 0: case 1:
        {
            tObject_Item* item = CObject_Item::NewItem((UINT)p.item_index);
            char text[256] = {};
            _snprintf(text, sizeof(text) - 1, u8"Bạn đã mua %d %s", p.count > 0 ? p.count : 1, item ? item->GetName() : "");
            if (CGameProcedure::s_pUISystem) ADDTALKMSG(text);
            if (item) CObject_Item::DestroyItem((CObject_Item*)item);
            CSoundSystemFMod::_PlayUISoundFunc(25 + 59);
            break;
        }
        case 2: Tip(u8"Không đủ tiền."); break;
        case 4: Tip(u8"Túi đồ đã đầy"); break;
        default: Tip(u8"Hàng đã thay đổi, hãy mở lại cửa hàng"); break;
        }
    }

    // GCDiscardItemResultHandler (define.DISCARDITEM_RESULT 0 success)
    void OnDiscardItemResult(const pg::GCDiscardItemResult& p)
    {
        ++g_counters.discards;
        InvLog("GCDiscardItemResult result=%u bag=%u opt=%u item=%d", p.result, p.bag_index, p.opt, p.item_index);
        if (!IsMain()) return;
        if (p.result != 0) { CGameProcedure::s_pGfxSystem->PushDebugString("Discard item failed!"); return; }
        if (p.opt == 0)
        {
            CDataPool::GetMe()->UserBag_SetItemInfo(p.bag_index, TRUE, NULL);
            CActionSystem::GetMe()->UserBag_Update();
            CEventSystem::GetMe()->PushEvent(GE_PACKAGE_ITEM_CHANGED, p.bag_index);
        }
    }

    // GCPackage_SwapItemHandler (scenecore.lua package_swap_item: result 1; the two GCItemInfo follow)
    void OnPackageSwap(const pg::GCPackage_SwapItem& p)
    {
        ++g_counters.swaps;
        InvLog("GCPackage_SwapItem result=%u from=%u to=%u", p.result, p.index_from, p.index_to);
        if (!IsMain()) return;
        if (p.result != 1) { Tip(u8"Thao tác túi đồ thất bại!"); return; }
        CDataPool* pool = CDataPool::GetMe();
        tObject_Item* a = pool->UserBag_GetItem(p.index_from);
        tObject_Item* b = pool->UserBag_GetItem(p.index_to);
        if (!a && !b) return;
        pool->UserBag_SetItem(p.index_to, a, FALSE);
        pool->UserBag_SetItem(p.index_from, b, FALSE);
        CActionSystem::GetMe()->UserBag_Update();
        CEventSystem::GetMe()->PushEvent(GE_PACKAGE_ITEM_CHANGED);
    }

    // GCSplitItemResultHandler (item.lua RESULT: 0 false, 1 no grid, 2 succeed; container 1 = bag)
    void OnSplitItemResult(const pg::GCSplitItemResult& p)
    {
        ++g_counters.splits;
        InvLog("GCSplitItemResult result=%u container=%u index=%d", p.result, p.container, p.con_index);
        if (!IsMain()) return;
        if (p.result == 2 && p.container == 1 && p.con_index >= 0)
        {
            _ITEM item;
            CysModernHandlers::ItemInfoToLegacy(p.item, item);
            CObject_Item* obj = CObject_Item::NewItem(item.m_ItemIndex);
            if (obj)
            {
                obj->SetGUID(item.m_ItemGUID.m_World, item.m_ItemGUID.m_Server, (GUID_t)item.m_ItemGUID.m_Serial);
                obj->SetExtraInfo(&item);
                obj->SetTypeOwner(tObject_Item::IO_MYSELF_PACKET);
                obj->SetPosIndex(p.con_index);
                CDataPool::GetMe()->UserBag_SetItem(p.con_index, obj);
                CActionSystem::GetMe()->UserBag_Update();
            }
        }
        else if (p.result == 1) Tip(u8"Túi đầy, không thể tách");
        else if (p.result != 2) Tip(u8"Tách thất bại");
        INT pos = CDataPool::GetMe()->Split_GetItemPos();
        if (CDataPool::GetMe()->Split_GetItemConta() == tObject_Item::IO_MYSELF_PACKET)
            if (tObject_Item* locked = CDataPool::GetMe()->UserBag_GetItem(pos)) locked->SetLock(FALSE);
        CDataPool::GetMe()->Split_SetItemConta(-1);
        CDataPool::GetMe()->Split_SetItemPos(-1);
        CEventSystem::GetMe()->PushEvent(GE_PACKAGE_ITEM_CHANGED);
    }

    void OnUseItemResult(const pg::GCUseItemResult& p)
    {
        ++g_counters.useItems;
        InvLog("GCUseItemResult result=%d", p.result);
        if (!IsMain()) return;
        switch (p.result)
        {
        case 0: break;
        case 1: Tip(u8"Vật phẩm này không thể dùng"); break;
        case 2: Tip(u8"Cấp độ không đủ"); break;
        case 3: Tip(u8"Sai loại vật phẩm!"); break;
        case 4: Tip(u8"Sai loại mục tiêu!"); break;
        case 6: Tip(u8"Phù giám định không hợp lệ hoặc đang bị khóa."); break;
        case 7: Tip(u8"Trang bị không phù hợp, đã giám định hoặc đang bị khóa."); break;
        case 8: Tip(u8"Cấp phù giám định chưa đủ cho trang bị này."); break;
        default: break;
        }
    }

    // GCScriptCommandHandler, event list only (m_nCmdID 0 = SCRIPT_COMMAND_EVENT_LIST_RESPONSE): the NPC menu whose
    // shop option opens GCShopMerchandiseList. flag = ENUM_EVENT_ITEM_TYPE (0 section, 1 option, 2 text),
    // option: index / type (the AddNumText icon = 0.85 m_state) / script_id. Other commands stay with npc-quest.
    bool OnScriptCommand(const pg::GCScriptCommand& p)
    {
        if (p.m_nCmdID != 0) return false;
        ++g_counters.eventLists;
        if (!IsMain()) return true;
        static ScriptParam_EventList list;
        list.Reset();
        list.m_idNPC = (ObjID_t)p.target_id;
        g_shopScript = g_shopIndex = -1;
        // CYS-QUEST: texts the server split at the CY 255-byte limit (ending with 0x1F) are joined back into one item;
        // the full text of a joined item longer than ScriptString is served by CysQuestNet::EventListText.
        std::vector<std::pair<int, std::string> > raw;
        for (size_t i = 0; i < p.event.size(); ++i)
            raw.push_back(std::make_pair((int)p.event[i].flag, p.event[i].flag == 1 ? p.event[i].str_2 : p.event[i].str));
        const std::vector<CysEventTextJoin::Joined> joined = CysEventTextJoin::Join(raw);
        CysQuestNet::ClearEventListTexts();
        for (size_t i = 0; i < joined.size() && i < MAX_EVENT_LIST_ITEM_COUNT; ++i)
        {
            const auto& e = p.event[joined[i].first];
            ScriptEventItem item;
            item.Reset();
            ScriptString text;
            text = joined[i].text.c_str();
            if (e.flag == 1)
            {
                item.SetScriptID(e.index, e.type, e.script_id, &text);
                if (e.type == 7 && g_shopScript < 0) { g_shopScript = e.script_id; g_shopIndex = e.index; }
            }
            else
            {
                if (e.flag == 0) item.SetSection(&text); else item.SetText(&text);
                if (joined[i].text.size() >= DEF_SCRIPT_STRING_LEN) CysQuestNet::SetEventListText((int)list.m_yItemCount, joined[i].text.c_str());
            }
            list.AddItem(&item);
        }
        InvLog("GCScriptCommand event list npc=%d items=%u", p.target_id, (unsigned)list.m_yItemCount);
        SCommand_DPC command;
        command.m_wID = DPC_SCRIPT_COMMAND;
        command.m_anParam[0] = SCRIPT_COMMAND_EVENT_LIST_RESPONSE;
        command.m_apParam[1] = &list;
        ((CUIDataPool*)CGameProcedure::s_pDataPool)->OnCommand_(&command);
        return true;
    }
}

namespace
{
    int HostBagCount(void*, int bag, int what)
    {
        const int size = bag == CysHostPackage::BagBase ? g_propSize : bag == CysHostPackage::BagMaterial ? g_materialSize : 20;
        switch (what)
        {
        case CysHostPackage::CountNum: return size;
        case CysHostPackage::CountBase: return size < 20 ? size : 20;
        case CysHostPackage::CountRealMax: { const int lines = (size + 9) / 10; return (lines < 2 ? 2 : lines > 10 ? 10 : lines) * 10; }
        default: return bag == CysHostPackage::BagTask ? 20 : 100; // server bag_start: prop 0, material 100, task 200
        }
    }
    DWORD g_lastBagAsk = 0;
    void HostAskBagList(void*)
    {
        const DWORD now = GetTickCount();
        if (g_lastBagAsk && now - g_lastBagAsk < 3000) return; // CY AskMyBagList has its own timer
        g_lastBagAsk = now;
        std::unique_ptr<pg::CGAskMyBagList> list(new pg::CGAskMyBagList);
        list->unknow_1 = 0; list->size = 0;
        CysModernGame::SendModern(std::unique_ptr<pg::Packet>(list.release()));
        CysModernGame::SendModern(std::unique_ptr<pg::Packet>(new pg::CGAskMyBagSize));
    }
}

namespace
{
    // CY tooltip parts of the item under SuperTooltips (0.85 SuperTooltips::SetActionItem); labels in Vietnamese.
    tObject_Item* TooltipItem(tActionItem** actionOut = nullptr)
    {
        CActionItem* action = SCRIPT_SANDBOX::SuperTooltips::s_SupperTooltip.GetActionItem();
        if (actionOut) *actionOut = action;
        // CYS-SKILL: the tooltip also opens over skills of the skill book / quick bar, whose impl is SCLIENT_SKILL
        // (gui-live-1: hovering F1 called GetItemClass on a skill -> AV). Only item/equipment actions carry an item.
        if (!action || (action->GetType() != AOT_ITEM && action->GetType() != AOT_EQUIP)) return nullptr;
        return (tObject_Item*)action->GetImpl();
    }

    CysEquipmentTooltip::Snapshot TooltipInstance(tObject_Item* item)
    {
        CysEquipmentTooltip::Snapshot result;
        if (!item || item->GetItemClass()!=ICLASS_EQUIP || item->GetTypeOwner()==tObject_Item::IO_BOOTH) return result;
        USHORT world=0,server=0;UINT serial=0;item->GetGUID(world,server,serial);
        CysModernHandlers::EquipmentTooltip((uint8_t)world,(uint8_t)server,serial,item->GetIdTable(),result);
        return result;
    }
    void HostPickAll(void*)
    {
        auto pool=CDataPool::GetMe();
        if(!pool || !CysModernGame::IsInWorld() || pool->ItemBox_GetID()<0) return;
        // Use the same per-GUID transaction as a manual click. The server removes
        // a row only after successful insertion; retries cannot create another item.
        for(int i=0;i<MAX_BOXITEM_NUMBER;++i)
            if(auto item=pool->ItemBox_GetItem(i)) CGameProcedure::s_pGameInterface->ItemBox_PickItem(item);
    }
    double HostExperience(void*,bool maximum)
    {
        auto self=CObjectManager::GetMe()?CObjectManager::GetMe()->GetMySelf():nullptr;
        if(!self)return 0;
        const __int64 value=maximum?self->GetCharacterData()->Get_MaxExp():self->GetCharacterData()->Get_Exp();
        return value>0?value:0;
    }
    const char* HostTooltipText(void*, int part)
    {
        static std::string text;
        tActionItem* action = nullptr;
        tObject_Item* item = TooltipItem(&action);
        text.clear();
        if (!action) return "";
        char line[256] = {};
        const auto instance=TooltipInstance(item);
        switch (part)
        {
        case CysHostPackage::TipTitle:
            text=action->GetName()?action->GetName():"";
            if(item && item->GetItemClass()==ICLASS_EQUIP) {
                DBC_DEFINEHANDLE(s_titleEquipBase,DBC_ITEM_EQUIP_BASE);
                const auto base=(const _DBC_ITEM_EQUIP_BASE*)s_titleEquipBase->Search_Index_EQU((UINT)item->GetIdTable());
                if(base)text=std::string(CysEquipmentTooltip::TitleColour(base->nQuality))+text;
            }
            if(instance.enhancement) text+=u8" #c5bc257(+"+std::to_string(instance.enhancement)+")";
            text+="#W";
            break;
        case CysHostPackage::TipAuthor:
            text=CysEquipmentTooltip::Author(instance);
            break;
        case CysHostPackage::TipGem1:case CysHostPackage::TipGem2:case CysHostPackage::TipGem3:case CysHostPackage::TipGem4:
        {
            const int gem=instance.gems[part-CysHostPackage::TipGem1];
            if(gem<=0)break;
            DBC_DEFINEHANDLE(s_gems,DBC_ITEM_GEM);
            const auto def=(const _DBC_ITEM_GEM*)s_gems->Search_Index_EQU(gem);
            if(def&&def->szIcon)text=def->szIcon;
            break;
        }
        case CysHostPackage::TipIcon: return action->GetIconName();
        case CysHostPackage::TipDesc1:
            if (item && item->GetNeedLevel() > 0) _snprintf(line, sizeof(line) - 1, u8"Cấp yêu cầu: %d", item->GetNeedLevel());
            text = line; break;
        case CysHostPackage::TipDesc2:
            if (item && item->GetItemClass() == ICLASS_EQUIP) _snprintf(line, sizeof(line) - 1, u8"Độ bền: %d/%d", ((CActionItem*)action)->GetItemDur(), ((CActionItem*)action)->GetItemMaxDur());
            else if (item) _snprintf(line, sizeof(line) - 1, u8"Số lượng: %d", item->GetNumber() > 0 ? item->GetNumber() : 1);
            text = line; break;
        case CysHostPackage::TipDesc3:
        {
            INT price = item ? item->GetItemPrice() : -1;
            if (!CysTooltipContract::ContentOld() && item && item->GetItemClass() == ICLASS_EQUIP)
            {
                DBC_DEFINEHANDLE(s_pEquipBasePrice, DBC_ITEM_EQUIP_BASE);
                const _DBC_ITEM_EQUIP_BASE* base = reinterpret_cast<const _DBC_ITEM_EQUIP_BASE*>(s_pEquipBasePrice->Search_Index_EQU((UINT)item->GetIdTable()));
                // GCItemInfo carries no sale price. Its legacy zero must not overwrite the static table price.
                if (base) price = base->nSalePrice;
            }
            if (price > 0) _snprintf(line, sizeof(line) - 1, u8"Giá bán: #{_MONEY%d}", price);
            text = line; break;
        }
        case CysHostPackage::TipMoney1Label: return u8"Giá mua:";
        case CysHostPackage::TipMoney2Label: return "";
        case CysHostPackage::TipDesc4:
        {
            if(item && item->GetItemClass()==ICLASS_EQUIP) {
                if(instance.itemIndex)text=(instance.status&1)?u8"Đã khóa":u8"Chưa khóa";
                break;
            }
            const char* type = ((CActionItem*)action)->GetTypeDesc();
            text = type ? type : ""; break;
        }
        case CysHostPackage::TipPropertys:
        {
            if (!item || item->GetItemClass() != ICLASS_EQUIP) break;
            DBC_DEFINEHANDLE(s_pEquipBase, DBC_ITEM_EQUIP_BASE);
            const _DBC_ITEM_EQUIP_BASE* base = (const _DBC_ITEM_EQUIP_BASE*)s_pEquipBase->Search_Index_EQU((UINT)item->GetIdTable());
            if (!base) break;
            text=CysEquipmentTooltip::Properties(instance,base->nEquipPoint,
                {{base->nBaseAttackP,base->nBaseAttackM,base->nBaseDefenceP,base->nBaseDefenceM,base->nBaseHit,base->nBaseMiss}});
            if(instance.itemIndex && item->GetItemMaxDur() > 0) {
                // script_base:DoHighRepair refuses after three failures, not three successes.
                const int failed = item->GetItemRepairCount();
                const int remaining = failed >= 3 ? 0 : failed < 0 ? 3 : 3 - failed;
                CysEquipmentTooltip::Line(text, std::string(remaining ? "#W" : "#R") +
                    u8"Sửa cao cấp thất bại: " + std::to_string(failed < 0 ? 0 : failed) + u8"/3 · Còn " + std::to_string(remaining) + "#W");
            }
            break;
        }
        case CysHostPackage::TipStatus: text=CysEquipmentTooltip::Status(instance);break;
        case CysHostPackage::TipDiaowenIcon:
        {
            const auto dw=CysTooltipTables::Diaowen(instance.diaowen);
            if(dw)text=dw->icon;break;
        }
        case CysHostPackage::TipExplain:
        {
            const char* desc = item ? item->GetDesc() : action->GetDesc();
            text = desc ? desc : ""; break;
        }
        default: break;
        }
        return text.c_str();
    }

    int HostTooltipNumber(void*, int part)
    {
        tObject_Item* item = TooltipItem();
        switch (part)
        {
        case CysHostPackage::TipPresent: return item ? 1 : 0;
        case CysHostPackage::TipGemHoles: return TooltipInstance(item).gemSlots;
        case CysHostPackage::TipEquipQual: return TooltipInstance(item).quality;
        case CysHostPackage::TipMoney1:
            if (!item || item->GetTypeOwner() != tObject_Item::IO_BOOTH) return -1;
            if (CysTooltipContract::Probe()) TDU_Log("CYS-FT-TOOLTIP: shop-money item=%u slot=%d value=%u unit=%d",
                item->GetIdTable(), item->GetPosIndex(), CDataPool::GetMe()->Booth_GetItemPrice(item->GetPosIndex()), CDataPool::GetMe()->Booth_GetCurrencyUnit());
            return static_cast<int>(CDataPool::GetMe()->Booth_GetItemPrice(item->GetPosIndex()));
        case CysHostPackage::TipMoney2: return -1;
        case CysHostPackage::TipMoneyType:
            if (CysTooltipContract::ContentOld()) return 0;
            return item && item->GetTypeOwner() == tObject_Item::IO_BOOTH ? CDataPool::GetMe()->Booth_GetCurrencyUnit() : 1;
        default: return 0;
        }
    }
    void HostTooltipShowWithAlt(void*, int left, int top, int right, int bottom)
    {
        SCRIPT_SANDBOX::SuperTooltips::s_SupperTooltip.ShowToolTipsWithAlt(left, top, right, bottom);
    }
}

namespace
{
    // CY methods on action items (ActionButtonMetaTable): Packet.lua SetActionFlash, Shop.lua GetEquipPoint /
    // GetItemColorInShop, SelfEquip.lua GetEquipDur / IsLevelEnoughEquip. self = boxed CActionItem pointer.
    CActionItem* ActionSelf(LuaPlus::LuaState* state)
    {
        lua_State* L = state->GetCState();
        if (lua_type(L, 1) != LUA_TUSERDATA) return nullptr;
        void** box = static_cast<void**>(lua_touserdata(L, 1));
        return box ? static_cast<CActionItem*>(*box) : nullptr;
    }
    tObject_Item* ActionObjectItem(CActionItem* action)
    {
        if (!action) return nullptr;
        return action->GetType() == AOT_ITEM || action->GetType() == AOT_EQUIP ? static_cast<tObject_Item*>(action->GetImpl()) : nullptr;
    }
    int ActionSetActionFlash(LuaPlus::LuaState*) { return 0; } // flash animation of the guide: not modelled
    int ActionGetEquipPoint(LuaPlus::LuaState* state)
    {
        tObject_Item* item = ActionObjectItem(ActionSelf(state));
        state->PushInteger(item && item->GetItemClass() == ICLASS_EQUIP ? (INT)((CObject_Item_Equip*)item)->GetItemType() : -1);
        return 1;
    }
    int ActionGetItemColorInShop(LuaPlus::LuaState* state) { state->PushString(""); return 1; }
    int ActionSpiritType(LuaPlus::LuaState* state) {
        const auto item=ActionObjectItem(ActionSelf(state));
        const int raw=CysEquipmentTooltip::ParseCreator(TooltipInstance(item).creator).spirit;
        state->PushInteger(raw>=60?2:raw>19?1:0);return 1;
    }
    int ActionIconName(LuaPlus::LuaState* state) { CActionItem* a = ActionSelf(state); state->PushString(a && a->GetIconName() ? a->GetIconName() : ""); return 1; }
    int ActionGetEquipDur(LuaPlus::LuaState* state)
    {
        CActionItem* action = ActionSelf(state);
        tObject_Item* item = ActionObjectItem(action);
        const int cur=item && item->GetItemClass()==ICLASS_EQUIP ? action->GetItemDur() : -1;
        const int max=item && item->GetItemClass()==ICLASS_EQUIP ? action->GetItemMaxDur() : -1;
        // B Game.exe+0x1df930: remaining/max, not the raw remaining points.
        state->PushNumber(cur>=0 && max>0 ? static_cast<double>(cur)/max : 1.0);
        return 1;
    }
    int ActionGetRemainRepairCount(LuaPlus::LuaState* state)
    {
        auto action = ActionSelf(state);
        auto item = ActionObjectItem(action);
        // Existing private GL server rule (script_base.lua DoHighRepair), shared by CY repair windows.
        const int failed = item && item->GetItemClass() == ICLASS_EQUIP ? item->GetItemRepairCount() : 3;
        state->PushInteger(failed >= 3 ? 0 : failed < 0 ? 3 : 3 - failed);
        return 1;
    }
    int ActionGetEquipDurValue(LuaPlus::LuaState* state)
    {
        auto action=ActionSelf(state);auto item=ActionObjectItem(action);
        const bool equip=item && item->GetItemClass()==ICLASS_EQUIP;
        state->PushInteger(equip?action->GetItemDur():-1);
        state->PushInteger(equip?action->GetItemMaxDur():-1);
        return 2;
    }
    int ActionIsLevelEnoughEquip(LuaPlus::LuaState* state)
    {
        tObject_Item* item = ActionObjectItem(ActionSelf(state));
        CObject_PlayerMySelf* self = CObjectManager::GetMe() ? CObjectManager::GetMe()->GetMySelf() : nullptr;
        const INT level = self ? self->GetCharacterData()->Get_Level() : 0;
        state->PushInteger(!item || item->GetNeedLevel() <= level ? 1 : 0);
        return 1;
    }
}

void CysInventoryNet::RegisterHost()
{
    g_propSize = g_materialSize = 20;
    g_sizeKnown = g_sizeAsked = false;
    g_lastBagAsk = 0;
    CScriptSystem* scripts = CScriptSystem::GetMe();
    if (!scripts || !scripts->GetLuaState()) return;
    CysHostPackage::Services services;
    services.bagCount = HostBagCount;
    services.askBagList = HostAskBagList;
    services.pickAll = HostPickAll;
    services.experience = HostExperience;
    services.tooltipText = HostTooltipText;
    services.tooltipNumber = HostTooltipNumber;
    services.tooltipShowWithAlt = HostTooltipShowWithAlt;
    const int n = CysHostPackage::Register(scripts->GetLuaState(), services);
    InvLog("host functions registered=%d (bag counters, AskMyBagList, neutral CY helpers)", n);
    if (CActionItem::s_pMetaTable && CActionItem::s_pMetaTable->IsTable())
    {
        const struct { const char* name; int (*fn)(LuaPlus::LuaState*); } methods[] = {
            {"SetActionFlash", ActionSetActionFlash}, {"GetEquipPoint", ActionGetEquipPoint},
            {"GetItemColorInShop", ActionGetItemColorInShop}, {"GetEquipDur", ActionGetEquipDur},
            {"GetEquipDurValue", ActionGetEquipDurValue},
            {"GetRemainRepairCount", ActionGetRemainRepairCount},
            {"IsLevelEnoughEquip", ActionIsLevelEnoughEquip}, {"Lua_GetEquipZhiZunType", ActionSpiritType},
            {"GetItemIconInShop", ActionIconName} };
        for (const auto& m : methods) CActionItem::s_pMetaTable->Register(m.name, m.fn);
    }
}

int CysInventoryNet::BagSize(int bag) { return bag == 0 ? g_propSize : bag == 1 ? g_materialSize : 20; }

bool CysInventoryNet::LastShopOption(int& scriptId, int& index)
{
    scriptId = g_shopScript; index = g_shopIndex;
    return g_shopScript >= 0;
}

std::unique_ptr<pg::Packet> CysInventoryNet::Translate(Packet* legacy)
{
    CDataPool* pool = CDataPool::GetMe();
    CObject_PlayerMySelf* self = CObjectManager::GetMe() ? CObjectManager::GetMe()->GetMySelf() : nullptr;
    switch (legacy->GetPacketID())
    {
    case PACKET_CG_PACKUP_PACKET:
    {
        const int tab = static_cast<CGPackUpPacket*>(legacy)->GetConIndex();
        if (tab < 0 || tab > 2) return nullptr;
        // Opt-in negative control for the former missing transport mapping.
        static const bool old = [] { char v[4] = {}; return GetEnvironmentVariableA("CYS_BAG_PACK_OLD", v, 4) == 1 && v[0] == '1'; }();
        if (old) return nullptr;
        std::unique_ptr<pg::CGPackUpPacket> out(new pg::CGPackUpPacket);
        out->unknow = static_cast<uint32_t>(tab);
        InvLog("CGPackUpPacket tab=%d", tab);
        return std::unique_ptr<pg::Packet>(out.release());
    }
    case PACKET_CG_ASKITEMINFO:
    {
        // Live misc.lua:2794 and scenecore.lua:1958: u16 bag index + echoed u32 ask id.
        // Prop-bag indices are already zero-based; the legacy local query has no correlation id.
        std::unique_ptr<pg::CGAskItemInfo> out(new pg::CGAskItemInfo);
        out->bagIndex = static_cast<CGAskItemInfo*>(legacy)->getID();
        out->askid = 0;
        if (CysTooltipContract::Probe())
            TDU_Log("CYS-FT-TOOLTIP: item request mapped legacy=%u modern=%u slot=%u askid=%u",
                legacy->GetPacketID(), out->packetId(), out->bagIndex, out->askid);
        return std::unique_ptr<pg::Packet>(out.release());
    }
    case PACKET_CG_USEEQUIP:
    {
        // 0.85 carries only the bag slot; the CY server needs the equip point (char_use_bag_equip checks it).
        const BYTE bag = static_cast<CGUseEquip*>(legacy)->getBagIndex();
        tObject_Item* item = pool ? pool->UserBag_GetItem(bag) : nullptr;
        if (!item || item->GetItemClass() != ICLASS_EQUIP) { InvLogGesture("CGUseEquip bag=%u: no equipment in the client slot; not sent", bag); return nullptr; }
        std::unique_ptr<pg::CGUseEquip> out(new pg::CGUseEquip);
        out->bagIndex = bag;
        out->equipPoint = static_cast<uint8_t>(((CObject_Item_Equip*)item)->GetItemType());
        out->type = 0;
        InvLogGesture("CGUseEquip bag=%u point=%u item=%u", bag, out->equipPoint, item->GetIdTable());
        return std::unique_ptr<pg::Packet>(out.release());
    }
    case PACKET_CG_UNEQUIP:
    {
        std::unique_ptr<pg::CGUnEquip> out(new pg::CGUnEquip);
        out->equipPoint = static_cast<CGUnEquip*>(legacy)->getEquipPoint(); // the server picks the bag slot
        InvLogGesture("CGUnEquip point=%u", out->equipPoint);
        return std::unique_ptr<pg::Packet>(out.release());
    }
    case PACKET_CG_DISCARDITEM:
    {
        CGDiscardItem* discard = static_cast<CGDiscardItem*>(legacy);
        if (discard->GetOpt() != 0) return nullptr; // bank discard: not in this module
        std::unique_ptr<pg::CGDiscardItem> out(new pg::CGDiscardItem);
        out->bag_index = discard->GetBagIndex(); out->opt = 0;
        InvLog("CGDiscardItem bag=%u", out->bag_index);
        return std::unique_ptr<pg::Packet>(out.release());
    }
    case PACKET_CG_SPLITITEM:
    {
        CGSplitItem* split = static_cast<CGSplitItem*>(legacy);
        // A bank split must never silently operate on the same index in the bag.
        if (CDataPool::GetMe()->Split_GetItemConta() != tObject_Item::IO_MYSELF_PACKET) return nullptr;
        std::unique_ptr<pg::CGSplitItem> out(new pg::CGSplitItem);
        out->container = 1; // BAG_CON (the 0.85 bank container is not mapped)
        out->position = static_cast<uint32_t>(split->GetPosition());
        out->num = static_cast<uint32_t>(split->GetNumber());
        return std::unique_ptr<pg::Packet>(out.release());
    }
    case PACKET_CG_PACKAGE_SWAPITEM:
    {
        CGPackage_SwapItem* swap = static_cast<CGPackage_SwapItem*>(legacy);
        std::unique_ptr<pg::CGPackage_SwapItem> out(new pg::CGPackage_SwapItem);
        out->index_from = swap->GetPackageIndex1(); out->index_to = swap->GetPackageIndex2(); out->count = 0;
        InvLog("CGPackage_SwapItem %u -> %u", out->index_from, out->index_to);
        return std::unique_ptr<pg::Packet>(out.release());
    }
    case PACKET_CG_SHOPBUY:
    {
        CGShopBuy* buy = static_cast<CGShopBuy*>(legacy);
        std::unique_ptr<pg::CGShopBuy> out(new pg::CGShopBuy);
        out->index = buy->GetIndex();            // < 200: merchandise (0-based), >= 200: buy back by GUID
        out->series_num = buy->GetSerialNum();
        out->unique_id = buy->GetUniqueID();
        const _ITEM_GUID guid = buy->GetItemGUID();
        out->item_guid.world = guid.m_World; out->item_guid.server = guid.m_Server;
        out->item_guid.series = static_cast<uint32_t>(guid.m_Serial);
        out->item_guid.mask = CysModernHandlers::ItemGuidMask(guid.m_World, guid.m_Server, static_cast<unsigned>(guid.m_Serial));
        out->buy_num = buy->GetBuyNum() ? buy->GetBuyNum() : 1;
        InvLog("CGShopBuy index=%u count=%u", out->index, out->buy_num);
        return std::unique_ptr<pg::Packet>(out.release());
    }
    case PACKET_CG_SHOPSELL:
    {
        std::unique_ptr<pg::CGShopSell> out(new pg::CGShopSell);
        out->bag_index = static_cast<CGShopSell*>(legacy)->GetBagIndex();
        InvLog("CGShopSell bag=%u", out->bag_index);
        return std::unique_ptr<pg::Packet>(out.release());
    }
    case PACKET_CG_CHARDEFAULTEVENT:
    {
        std::unique_ptr<pg::CGCharDefaultEvent> out(new pg::CGCharDefaultEvent);
        out->m_objID = static_cast<uint32_t>(static_cast<CGCharDefaultEvent*>(legacy)->getObjID());
        out->targetID = self ? static_cast<uint32_t>(self->GetServerID()) : 0;
        InvLog("CGCharDefaultEvent npc=%u", out->m_objID);
        return std::unique_ptr<pg::Packet>(out.release());
    }
    case PACKET_CG_EVENTREQUEST:
    {
        CGEventRequest* request = static_cast<CGEventRequest*>(legacy);
        std::unique_ptr<pg::CGEventRequest> out(new pg::CGEventRequest);
        out->m_objID = request->getScriptID(); out->index = request->getExIndex(); out->arg = request->getNPCID(); out->unknow = 0;
        InvLog("CGEventRequest script=%d index=%d npc=%d", out->m_objID, out->index, out->arg);
        return std::unique_ptr<pg::Packet>(out.release());
    }
    case PACKET_CG_USEITEM:
    {
        CGUseItem* use = static_cast<CGUseItem*>(legacy);
        tObject_Item* item = pool ? pool->UserBag_GetItem(use->GetBagIndex()) : nullptr;
        if (!item) return nullptr;
        std::unique_ptr<pg::CGUseItem> out(new pg::CGUseItem);
        out->bagIndex = use->GetBagIndex();
        out->item_index = item->GetIdTable();   // scenecore.lua char_use_item compares it with the slot
        out->target_obj_id = use->GetTargetObjID();
        out->target_pos_x = use->GetTargetPos()->m_fX; out->target_pos_y = use->GetTargetPos()->m_fZ;
        out->target_dir = use->GetTargetDir();
        out->target_bag_index = use->GetTargetItem();
        // CY has two GUID-shaped fields: the first is ItemGUID; the selected
        // pet belongs in pet_guid_2 (the server reads it into targeting params).
        // Losing it breaks books, food, longevity and return-to-child items.
        static const bool petLegacy = [] { char v[4] = {}; return GetEnvironmentVariableA("CYS_PET_ITEM_LEGACY", v, 4) == 1 && v[0] == '1'; }();
        if (!petLegacy) {
            const PET_GUID_t pet = use->GetTargetPetGUID();
            out->pet_guid_2.m_uHighSection = pet.m_uHighSection;
            out->pet_guid_2.m_uLowSection = pet.m_uLowSection;
        }
        return std::unique_ptr<pg::Packet>(out.release());
    }
    case PACKET_CG_ASKDETAILEQUIPLIST:
    {
        std::unique_ptr<pg::CGAskDetailEquipList> out(new pg::CGAskDetailEquipList);
        out->m_objID = static_cast<uint32_t>(static_cast<CGAskDetailEquipList*>(legacy)->getObjID());
        return std::unique_ptr<pg::Packet>(out.release());
    }
    default:
        return nullptr;
    }
}

bool CysInventoryNet::IsWorldPacket(uint16_t id)
{
    if (id == pg::GCUICommand::PACKET_ID || id == pg::GCExteriorInfo::PACKET_ID) return true;
    switch (id)
    {
    case pg::GCUseEquipResult::PACKET_ID: case pg::GCUnEquipResult::PACKET_ID: case pg::GCDetailEquipList::PACKET_ID:
    case pg::GCCharEquipment::PACKET_ID: case pg::GCShopMerchandiseList::PACKET_ID: case pg::GCShopSoldList::PACKET_ID:
    case pg::GCShopBuy::PACKET_ID: case pg::GCShopSell::PACKET_ID: case pg::GCDiscardItemResult::PACKET_ID:
    case pg::GCPackage_SwapItem::PACKET_ID: case pg::GCSplitItemResult::PACKET_ID: case pg::GCUseItemResult::PACKET_ID:
    case pg::GCScriptCommand::PACKET_ID:
    case pg::GCPackUpPacket::PACKET_ID:
    case pg::GCAskFashionDepotData::PACKET_ID: // CYS-WARD2
        return true;
    default:
        return false;
    }
}

bool CysInventoryNet::Dispatch(const pg::Packet& packet)
{
    // The wardrobe owns index 990021 and validates its sequence/payload itself.
    // Dispatch it before the generic UI command consumer, which otherwise eats
    // every acknowledgement and leaves the fitting room waiting forever.
    if (CysWardrobeCatalog::Dispatch(packet)) return true;
    if (packet.packetId() == pg::GCUICommand::PACKET_ID) {
        const auto& p = static_cast<const pg::GCUICommand&>(packet);
        // Opt-in negative control, never present in the play launcher.
        static const bool old = [] { char v[4] = {}; return GetEnvironmentVariableA("CYS_UI_COMMAND_OLD", v, 4) == 1 && v[0] == '1'; }();
        if (old || !IsMain()) return true;
        X_PARAM params;
        if (!CysUiCommandParams::Copy(p, params)) {
            TDU_Log("CYS UI command rejected index=%u ints=%u strings=%u bytes=%u", p.m_nUIIndex,
                p.m_Param_m_IntCount, p.m_Param_m_StrCount, (unsigned)p.m_Param_m_aStrValue.size());
            return true;
        }
        if(p.m_nUIIndex==990025 && params.m_IntCount==2) CysTemBank::Snapshot(params.m_aIntValue[0],params.m_aIntValue[1]);
        if(p.m_nUIIndex==990026) CysSkillNet::AssistSnapshot(params.m_aIntValue,params.m_IntCount);
        CEventSystem::GetMe()->PushUICommand(static_cast<INT>(p.m_nUIIndex), params);
        return true;
    }
    if(packet.packetId()==pg::GCExteriorInfo::PACKET_ID) {
        const auto& p=static_cast<const pg::GCExteriorInfo&>(packet);
        auto self=CObjectManager::GetMe()->GetMySelf();
        if(IsMain() && self && p.type==6) {
            auto data=self->GetCharacterData();
            data->Set_Ornament(0,p.exterior_head_id,p.exterior_head_pos);
            data->Set_Ornament(1,p.exterior_back_id,p.exterior_back_pos);
            data->Set_ExteriorWeapon(p.extrior_weapon_visual_id);
        }
        return true;
    }
    // First world packet of this module after entering: ask the page sizes once (msgagent.lua CGAskMyBagSize -> 143).
    if (!g_sizeKnown && !g_sizeAsked && CysModernGame::IsInWorld())
    {
        g_sizeAsked = CysModernGame::SendModern(std::unique_ptr<pg::Packet>(new pg::CGAskMyBagSize));
    }
    switch (packet.packetId())
    {
    case pg::GCUseEquipResult::PACKET_ID: OnUseEquipResult(static_cast<const pg::GCUseEquipResult&>(packet)); return true;
    case pg::GCUnEquipResult::PACKET_ID: OnUnEquipResult(static_cast<const pg::GCUnEquipResult&>(packet)); return true;
    case pg::GCDetailEquipList::PACKET_ID: OnDetailEquipList(static_cast<const pg::GCDetailEquipList&>(packet)); return true;
    case pg::GCCharEquipment::PACKET_ID: OnCharEquipment(static_cast<const pg::GCCharEquipment&>(packet)); return true;
    case pg::GCShopMerchandiseList::PACKET_ID: OnShopMerchandiseList(static_cast<const pg::GCShopMerchandiseList&>(packet)); return true;
    case pg::GCShopSoldList::PACKET_ID: OnShopSoldList(static_cast<const pg::GCShopSoldList&>(packet)); return true;
    case pg::GCShopBuy::PACKET_ID: OnShopBuy(static_cast<const pg::GCShopBuy&>(packet)); return true;
    case pg::GCShopSell::PACKET_ID: ++g_counters.shopSells; InvLog("GCShopSell result=%d", static_cast<const pg::GCShopSell&>(packet).result); return true;
    case pg::GCDiscardItemResult::PACKET_ID: OnDiscardItemResult(static_cast<const pg::GCDiscardItemResult&>(packet)); return true;
    case pg::GCPackage_SwapItem::PACKET_ID: OnPackageSwap(static_cast<const pg::GCPackage_SwapItem&>(packet)); return true;
    case pg::GCSplitItemResult::PACKET_ID: OnSplitItemResult(static_cast<const pg::GCSplitItemResult&>(packet)); return true;
    case pg::GCUseItemResult::PACKET_ID: OnUseItemResult(static_cast<const pg::GCUseItemResult&>(packet)); return true;
    case pg::GCScriptCommand::PACKET_ID: return OnScriptCommand(static_cast<const pg::GCScriptCommand&>(packet));
    // CYS-WARD2: the character's own fashion depot (时装仓库). scenecore.lua send_char_fashion_depot_data answers
    // a FIXED 100-slot array: an empty slot has item_index 0 and the fashion being worn is placed at the
    // character's fashion_depot_index, so the array index is exactly the nVecIndex the CY list works with.
    case pg::GCAskFashionDepotData::PACKET_ID:
    {
        const auto& p = static_cast<const pg::GCAskFashionDepotData&>(packet);
        std::vector<int> ids, visuals;
        ids.reserve(p.list.size()); visuals.reserve(p.list.size());
        for (size_t i = 0; i < p.list.size(); ++i)
        {
            ids.push_back(p.list[i].item_index > 0 ? p.list[i].item_index : 0);
            visuals.push_back((int)p.list[i].visual);
        }
        CysWardrobeHost::SetServerDepot(ids.empty() ? NULL : &ids[0], visuals.empty() ? NULL : &visuals[0], (int)ids.size());
        InvLog("GCAskFashionDepotData slots=%u size=%u open_editor=%u", (unsigned)p.list.size(), p.size, p.open_editor);
        return true;
    }
    case pg::GCBagSizeChange::PACKET_ID:
    {
        const auto& p = static_cast<const pg::GCBagSizeChange&>(packet);
        if (p.prop_size < 20 || p.prop_size > 100 || p.material_size < 20 || p.material_size > 100) return true;
        g_propSize = p.prop_size; g_materialSize = p.material_size; g_sizeKnown = true;
        InvLog("GCBagSizeChange prop=%u material=%u", p.prop_size, p.material_size);
        if (IsMain()) CEventSystem::GetMe()->PushEvent(GE_PACKAGE_ITEM_CHANGED);
        return true;
    }
    case pg::GCPackUpPacket::PACKET_ID:
        ++g_counters.packs;
        CActionSystem::GetMe()->UserBag_Update();
        CEventSystem::GetMe()->PushEvent(GE_PACKAGE_ITEM_CHANGED);
        return true;
    default: return false;
    }
}

CysInventoryNet::Counters CysInventoryNet::Get() { return g_counters; }

#else // !CYS_HAVE_NETCORE

std::unique_ptr<pg::Packet> CysInventoryNet::Translate(Packet*) { return nullptr; }
bool CysInventoryNet::IsWorldPacket(uint16_t) { return false; }
bool CysInventoryNet::Dispatch(const pg::Packet&) { return false; }
CysInventoryNet::Counters CysInventoryNet::Get() { Counters c = {}; return c; }
void CysInventoryNet::RegisterHost() {}
int CysInventoryNet::BagSize(int) { return 0; }
bool CysInventoryNet::LastShopOption(int&, int&) { return false; }

#endif
