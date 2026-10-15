// CYS-INV: Lua glue of the CY bag / equipment / shop windows. See CysHost_Package.h.
#include "CysHost_Package.h"
#include "LuaApiGen.h"
#include "CysTooltipContract.h"
#include <cstring>

namespace CysHostPackage
{
    namespace
    {
        Services g_services;

        LuaPlus::LuaObject Receiver(LuaPlus::LuaObject& globals, const char* name)
        {
            LuaPlus::LuaObject o = globals.GetByName(name);
            if (o.IsTable()) return o;
            if (o.IsUserData())
            {
                LuaPlus::LuaObject meta = o.GetMetaTable();
                if (!meta.IsTable()) return LuaPlus::LuaObject();
                LuaPlus::LuaObject index = meta.GetByName("__index");
                return index.IsTable() ? index : meta;
            }
            if (o.IsNil()) return globals.CreateTable(name);
            return LuaPlus::LuaObject();
        }

        int Count(LuaPlus::LuaState* s, int bag, int what)
        {
            const int n = g_services.bagCount ? g_services.bagCount(g_services.context, bag, what) : 0;
            s->PushInteger(n);
            return 1;
        }
        int BaseNum(LuaPlus::LuaState* s) { return Count(s, BagBase, CountNum); }
        int BaseBase(LuaPlus::LuaState* s) { return Count(s, BagBase, CountBase); }
        int BaseReal(LuaPlus::LuaState* s) { return Count(s, BagBase, CountRealMax); }
        int BaseMax(LuaPlus::LuaState* s) { return Count(s, BagBase, CountMax); }
        int MatNum(LuaPlus::LuaState* s) { return Count(s, BagMaterial, CountNum); }
        int MatBase(LuaPlus::LuaState* s) { return Count(s, BagMaterial, CountBase); }
        int MatReal(LuaPlus::LuaState* s) { return Count(s, BagMaterial, CountRealMax); }
        int MatMax(LuaPlus::LuaState* s) { return Count(s, BagMaterial, CountMax); }
        int TaskNum(LuaPlus::LuaState* s) { return Count(s, BagTask, CountNum); }
        int TaskBase(LuaPlus::LuaState* s) { return Count(s, BagTask, CountBase); }
        int TaskReal(LuaPlus::LuaState* s) { return Count(s, BagTask, CountRealMax); }
        int TaskMax(LuaPlus::LuaState* s) { return Count(s, BagTask, CountMax); }
        int AskBagList(LuaPlus::LuaState* s)
        {
            if (g_services.askBagList) g_services.askBagList(g_services.context);
            s->PushInteger(1);
            return 1;
        }
        int PickAll(LuaPlus::LuaState*) { if (g_services.pickAll) g_services.pickAll(g_services.context); return 0; }
        double Exp(bool maximum) { return g_services.experience ? g_services.experience(g_services.context, maximum) : 0; }
        int GetExp(LuaPlus::LuaState* s) { s->PushNumber(Exp(false)); s->PushNumber(Exp(true)); return 2; }
        int ExpRatio(LuaPlus::LuaState* s) { const double need=Exp(true); s->PushNumber(need>0 ? Exp(false)/need : 0); return 1; }
        int CanLevelUp(LuaPlus::LuaState* s) { const double need=Exp(true); s->PushInteger(need>0 && Exp(false)>=need ? 1 : 0); return 1; }
        // Neutral answers (the CY feature behind them is outside this module).
        int Zero(LuaPlus::LuaState* s) { s->PushInteger(0); return 1; }
        int MinusOne(LuaPlus::LuaState* s) { s->PushInteger(-1); return 1; }
        int False(LuaPlus::LuaState* s) { s->PushBoolean(false); return 1; }
        int Nothing(LuaPlus::LuaState*) { return 0; }

        const char* TipString(int part)
        {
            const char* text = g_services.tooltipText ? g_services.tooltipText(g_services.context, part) : nullptr;
            return text ? text : "";
        }
        int TipStr(LuaPlus::LuaState* s, int part) { s->PushString(TipString(part)); return 1; }
        int TipOptional(LuaPlus::LuaState* s, int part)
        {
            const char* text = TipString(part);
            if (!*text) return 0; // nil: the Lua page element stays hidden
            s->PushString(text);
            return 1;
        }
        int TipNum(LuaPlus::LuaState* s, int part)
        {
            s->PushInteger(g_services.tooltipNumber ? g_services.tooltipNumber(g_services.context, part) : 0);
            return 1;
        }
        int LuaTipIconName(LuaPlus::LuaState* s) { return TipStr(s, TipIcon); }
        int LuaTipStatus(LuaPlus::LuaState* s) { return TipStr(s, TipStatus); }
        int LuaTipDiaowenIcon(LuaPlus::LuaState* s) { return TipStr(s, TipDiaowenIcon); }
        int LuaTipTitle(LuaPlus::LuaState* s) { return TipStr(s, TipTitle); }
        int LuaTipDesc1(LuaPlus::LuaState* s) { return TipStr(s, TipDesc1); }
        int LuaTipDesc2(LuaPlus::LuaState* s) { return TipStr(s, TipDesc2); }
        int LuaTipDesc3(LuaPlus::LuaState* s) { return TipStr(s, TipDesc3); }
        int LuaTipDesc4(LuaPlus::LuaState* s) { return TipStr(s, TipDesc4); }
        int LuaTipDesc6(LuaPlus::LuaState* s) { return TipStr(s, TipDesc6); }
        int LuaTipPropertys(LuaPlus::LuaState* s) { return TipOptional(s, TipPropertys); }
        int LuaTipExplain(LuaPlus::LuaState* s) { return TipStr(s, TipExplain); }
        int LuaTipAuthor(LuaPlus::LuaState* s) { return TipOptional(s, TipAuthor); }
        int Gem1(LuaPlus::LuaState* s) { return TipStr(s, TipGem1); }
        int Gem2(LuaPlus::LuaState* s) { return TipStr(s, TipGem2); }
        int Gem3(LuaPlus::LuaState* s) { return TipStr(s, TipGem3); }
        int Gem4(LuaPlus::LuaState* s) { return TipStr(s, TipGem4); }
        int LuaTipGemHoles(LuaPlus::LuaState* s) { return TipNum(s, TipGemHoles); }
        int LuaTipEquipQual(LuaPlus::LuaState* s) { return TipNum(s, TipEquipQual); }
        int TipMoney(LuaPlus::LuaState* s, bool second)
        {
            if (CysTooltipContract::ContentOld()) return 0;
            const int value = g_services.tooltipNumber
                ? g_services.tooltipNumber(g_services.context, second ? TipMoney2 : TipMoney1) : -1;
            if (value < 0) s->PushNil(); else s->PushInteger(value);
            s->PushString(value < 0 ? "" : TipString(second ? TipMoney2Label : TipMoney1Label));
            return 2; // CY GetMoney1/2: always (number|nil, string), even when absent.
        }
        int LuaTipMoney1(LuaPlus::LuaState* s) { return TipMoney(s, false); }
        int LuaTipMoney2(LuaPlus::LuaState* s) { return TipMoney(s, true); }
        int LuaTipMoneyType(LuaPlus::LuaState* s) { return TipNum(s, TipMoneyType); }
        int One(LuaPlus::LuaState* s) { s->PushInteger(1); return 1; }
        int ZeroString(LuaPlus::LuaState* s) { s->PushString("0"); return 1; }
        int Empty(LuaPlus::LuaState* s) { s->PushString(""); return 1; }
        int ShowToolTipsWithAlt(LuaPlus::LuaState* s)
        {
            LuaPlus::LuaStack args(s);
            for (int i = 2; i <= 5; ++i) if (!args[i].IsNumber()) return 0;
            if (g_services.tooltipShowWithAlt)
                g_services.tooltipShowWithAlt(g_services.context,
                    args[2].GetInteger(), args[3].GetInteger(), args[4].GetInteger(), args[5].GetInteger());
            return 0;
        }
        struct Entry { const char* receiver; const char* name; int (*fn)(LuaPlus::LuaState*); bool force; };
        const Entry kEntries[] = {
            {"DataPool", "GetBaseBag_Num", BaseNum, true},
            {"DataPool", "GetBaseBag_BaseNum", BaseBase, true},
            {"DataPool", "GetBaseBag_RealMaxNum", BaseReal, true},
            {"DataPool", "GetBaseBag_MaxNum", BaseMax, true},
            {"DataPool", "GetMatBag_Num", MatNum, true},
            {"DataPool", "GetMatBag_BaseNum", MatBase, true},
            {"DataPool", "GetMatBag_RealMaxNum", MatReal, true},
            {"DataPool", "GetMatBag_MaxNum", MatMax, true},
            {"DataPool", "GetTaskBag_Num", TaskNum, true},
            {"DataPool", "GetTaskBag_BaseNum", TaskBase, true},
            {"DataPool", "GetTaskBag_RealMaxNum", TaskReal, true},
            {"DataPool", "GetTaskBag_MaxNum", TaskMax, true},
            {"DataPool", "AskMyBagList", AskBagList, true},
            {"PlayerPackage", "PickAllItem", PickAll, true},
            {"Player", "GetExp", GetExp, true},
            {"Player", "GetHumanExpRatioToNeedExp", ExpRatio, true},
            {"Player", "IsCanLevelup", CanLevelUp, true},
            // Packet.lua: `local result, money = Player:GetLevelMoneyLimit(); if result then` (no level cap tooltip)
            {"Player", "GetLevelMoneyLimit", False, true},
            {"GameProduceLogin", "IsWeGameClient", Zero, true},
            {"TLCJ", "IsInTLCJScene", Zero, true},              // Packet_Open refuses to open inside TLCJ
            {"PlayerPackage", "GetBagPosByItemIndex", MinusOne, true},
            {"DataPool", "Lua_IsMissionHaveDone", Zero, true},  // SelfEquip page guides
            {"DataPool", "Lua_CheckOpenTalent", Zero, true},
            {"NpcShop", "CloseConfirm", Nothing, false},
            {"NpcShop", "GetBuyDirectly", Zero, true},
            {"NpcShop", "SetBuyDirectly", Nothing, false},
            {"NpcShop", "GetIsShopReorder", Zero, true},
            // CYS-WARD3 20/09: muc nay nay DA CHET. `Nothing` lam nut `SelfEquip_Yirong_Icon` (cua duy nhat
            // vao phong thay do) khong lam gi ca. Ban cai that nam o CysHost_Wardrobe.cpp (day su kien
            // OPEN_EXTERIOR_FASHION) va dung `table.Register` cuong buc nen luon thang. Giu dong nay lam
            // moc lich su; dung go `Nothing` ra roi tuong la da sua.
            {"Exterior", "LuaFnInitExteriorFashionList", Nothing, false},
            {"Exterior", "LuaFnIsHaveExteriorShowTip", Zero, true},
            {"Exterior", "LuaFnIsHaveHairColorShowTip", Zero, true},
            {"OrnamentsScript", "IsHaveOrnamentsShowTip", Zero, true},
            // SuperTooltip.lua (CY): the parts of an item tooltip; the catalog stubs answer nil, which breaks the
            // numeric comparisons of SuperTooltip_Update, so these replace them.
            {"SuperTooltips", "GetIconName", LuaTipIconName, true},
            {"SuperTooltips", "GetTitle", LuaTipTitle, true},
            {"SuperTooltips", "GetDesc1", LuaTipDesc1, true},
            {"SuperTooltips", "GetDesc2", LuaTipDesc2, true},
            {"SuperTooltips", "GetDesc3", LuaTipDesc3, true},
            {"SuperTooltips", "GetDesc4", LuaTipDesc4, true},
            {"SuperTooltips", "GetDesc5", ZeroString, true},          // "1" = protected (unlock timer part)
            {"SuperTooltips", "GetDesc6", LuaTipDesc6, true},
            {"SuperTooltips", "GetInstanceStatus", LuaTipStatus, true},
            {"SuperTooltips", "GetPropertys", LuaTipPropertys, true},
            {"SuperTooltips", "GetExplain", LuaTipExplain, true},
            {"SuperTooltips", "GetAuthorInfo", LuaTipAuthor, true},
            {"SuperTooltips", "GetGemHoleCounts", LuaTipGemHoles, true},
            {"SuperTooltips", "GetEquipQual", LuaTipEquipQual, true},
            {"SuperTooltips", "Infant_IsInfantCard", False, true},
            {"SuperTooltips", "GetMoney1", LuaTipMoney1, true},
            {"SuperTooltips", "GetMoney2", LuaTipMoney2, true},
            {"SuperTooltips", "GetMoney1Type", LuaTipMoneyType, true},
            {"SuperTooltips", "GetIsShowJiaoZi", Zero, true},
            {"SuperTooltips", "GetPUnlockElapsedTime", Zero, true},
            {"SuperTooltips", "GetYuanbaoTradeFlag", One, true},       // 0/2 add the yuanbao trade line
            {"SuperTooltips", "GetGoodsProtect_Goods", Zero, true},
            {"SuperTooltips", "GetEquipMasterFlag", Zero, true},
            {"SuperTooltips", "GetEquipMasterText", Empty, true},
            {"SuperTooltips", "GetBaiShouLevelText", Empty, true},
            {"SuperTooltips", "GetZhiZunEquipText", Empty, true},
            {"SuperTooltips", "GetZhiZunEquipType", Zero, true},
            {"SuperTooltips", "GetBieYeFurniture1", Empty, true},
            {"SuperTooltips", "GetBieYeFurniture2", Empty, true},
            {"SuperTooltips", "GetBieYeFurniture3", Empty, true},
            {"SuperTooltips", "LuaFnIsShowExplainExtra", Zero, true},
            {"SuperTooltips", "LuaFnGetExplainExtra", Empty, true},
            {"SuperTooltips", "GetT300AuctionSubType", Zero, true},
            {"SuperTooltips", "GetGuiShiItemFlag", Zero, true},
            {"SuperTooltips", "GetGuiShiJiaoYiFlag", Zero, true},
            {"SuperTooltips", "GetSweetWordsID", Zero, true},
            {"SuperTooltips", "GetZongMenTalentTpye", Zero, true},
            {"SuperTooltips", "GetDiaowenIcon", LuaTipDiaowenIcon, true},
            {"SuperTooltips", "GetDiaowenIconEx", Empty, true},
            {"SuperTooltips", "GetGemIcon1", Gem1, true},
            {"SuperTooltips", "GetGemIcon2", Gem2, true},
            {"SuperTooltips", "GetGemIcon3", Gem3, true},
            {"SuperTooltips", "GetGemIcon4", Gem4, true},
            {"SuperTooltips", "GetTypeIsZhenShouDan", Zero, true},
            {"SuperTooltips", "GeKVKExchangeFlag", Zero, true},
            {"SuperTooltips", "ShowCmpWindowMain", Nothing, true},
            {"SuperTooltips", "CloseCmpWindowMain", Nothing, true},
            {"SuperTooltips", "CloseCmpWindowSub", Nothing, true},
            {"SuperTooltips", "ShowToolTipsWithAlt", ShowToolTipsWithAlt, true},
            {"Pet", "GetIsBaiShou", Zero, false},
        };
    }

    int Register(LuaPlus::LuaState* state, const Services& services)
    {
        g_services = services;
        if (!state) return 0;
        LuaPlus::LuaObject globals = state->GetGlobals();
        int registered = 0;
        for (const Entry& e : kEntries)
        {
            LuaPlus::LuaObject table = Receiver(globals, e.receiver);
            if (!table.IsTable()) continue;
            if (!e.force && !LuaApiGen::IsMissing(table, e.name)) continue;
            table.Register(e.name, e.fn);
            ++registered;
        }
        return registered;
    }
}
