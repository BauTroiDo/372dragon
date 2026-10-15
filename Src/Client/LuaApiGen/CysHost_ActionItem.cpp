// CYS-UIFRAMES: DataPool:CreateActionItemForShow / CreateBindActionItemForShow.
// The measurement behind every decision here is in CysHost_ActionItem.h - read that first.
#include "CysHost_ActionItem.h"
#include "LuaApiGen.h"
// GMActionSystem.h uses std::map / std::set in its class bodies but includes neither: inside the
// WXClient project it is always reached through StdAfx.h, which has already pulled them in. This
// file is compiled without that precompiled header, so it must supply them itself.
#include <map>
#include <set>
#include "Action/GMActionSystem.h"
#include "Script/GMScriptSystem.h"
#include "TDUtil.h"
#include <windows.h>
#include <cstdio>
#include <cstdlib>

namespace CysHostActionItem
{
    namespace
    {
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
            return LuaPlus::LuaObject();
        }

        // Hand Lua a real CActionItem, always. Never nil, never the generated null object:
        // 862 of the 958 call sites call a method on the result straight away without any guard.
        // When the id resolves to nothing we hand back s_InvalidAction, whose GetID() is 0 - the
        // value `if theAction:GetID() ~= 0 then` is written to test.
        int PushAction(LuaPlus::LuaState* state, tActionItem* pAction)
        {
            LuaPlus::LuaObject obj = state->BoxPointer(
                pAction ? (void*)pAction : (void*)&CActionItem::s_InvalidAction);
            obj.SetMetaTable(*CActionItem::s_pMetaTable);
            obj.PushStack();
            return 1;   // measured: 957 of 958 call sites bind exactly one value
        }

        tActionItem* Resolve(LuaPlus::LuaState* state)
        {
            LuaPlus::LuaStack args(state);
            // Be forgiving about the argument: some CY frames pass a float-valued number. A wrong
            // type must NOT throw here - throwing is the very failure this file exists to remove.
            if (!args[2].IsNumber()) return NULL;
            const int id = (int)args[2].GetNumber();
            if (id <= 0) return NULL;
            CActionSystem* sys = CActionSystem::GetMe();
            if (!sys) return NULL;
            return sys->CreateActionForShow((UINT)id);
        }

        // Both names take (itemDefineId, count) and, measured over all 958 sites, differ in nothing
        // the script can observe: GetNum is never called on the result, and the only other methods
        // used are GetID / GetName / GetItemColorInShop. The "Bind" variant is CY's soul-bound
        // flavour; binding shows in the tooltip, which comes off the item object either way. They
        // therefore share one body until a measurement says otherwise.
        int CreateActionItemForShow(LuaPlus::LuaState* s) { return PushAction(s, Resolve(s)); }
        int CreateBindActionItemForShow(LuaPlus::LuaState* s) { return PushAction(s, Resolve(s)); }

        // ---- CYS_UIFRAMES_PROBE=1: evidence only ------------------------------------------------
        // Two things a live run must show, and neither of them is "the function stopped throwing":
        //  (a) the DATA path - a real item define id resolves to a real action with a real name and
        //      a real icon name. Logged here at register time, when the item tables are already up.
        //  (b) the DRAW path - Lua_CysIconProbe(itemId, slot) parks that action on a main-bar slot,
        //      so the icon has to appear on screen or the patch is not finished. A CYS-only helper,
        //      not a CY name; it is the cheapest frame to photograph because the bar is always up.
        bool EnvFlag(const char* name)
        {
            char buf[8] = {0};
            return ::GetEnvironmentVariableA(name, buf, sizeof(buf)) > 0 && buf[0] && buf[0] != '0';
        }

        // Bao cao tu phia Lua ve: Lua_CysIconProbeReport(action_id, tim_thay_widget)
        int GlobalCysIconProbeReport(LuaPlus::LuaState* s)
        {
            LuaPlus::LuaStack args(s);
            const int aid = args[1].IsNumber() ? (int)args[1].GetNumber() : -1;
            const int found = args[2].IsNumber() ? (int)args[2].GetNumber() : -1;
            const char* wname = args[3].IsString() ? args[3].GetString() : "";
            TDU_Log("CYS-UIFRAMES probe: widget set action=%d widget_found=%d widget=%s",
                    aid, found, wname && *wname ? wname : "(none)");
            return 0;
        }

        // CYS-UIFIX2: ket qua cua `act:GetItemTableIndex()` goi tu Lua.
        //   ok = 0 -> phuong thuc van la nil (ban va KHONG chay)
        //   ok = 1 -> tra ve mot so; voi item CO THAT phai bang chinh item define id,
        //             voi item khong co that phai la -1 (s_InvalidAction, lop co so).
        int GlobalCysTableIndexReport(LuaPlus::LuaState* s)
        {
            LuaPlus::LuaStack args(s);
            const int ok = args[1].IsNumber() ? (int)args[1].GetNumber() : -1;
            const int value = args[2].IsNumber() ? (int)args[2].GetNumber() : -999;
            TDU_Log("CYS-UIFIX2 probe: GetItemTableIndex callable=%d value=%d", ok, value);
            return 0;
        }

        int GlobalCysIconProbe(LuaPlus::LuaState* s)
        {
            // A GLOBAL Lua function starts at args[1]; only a `Recv:Name()` method has self at
            // args[1] and its first real argument at args[2]. CysHost_Ride's Lua_CysSelectRide is
            // the same shape and uses args[1].
            LuaPlus::LuaStack args(s);
            if (!args[1].IsNumber()) { s->PushInteger(0); return 1; }
            const int itemId = (int)args[1].GetNumber();
            const int slot = args[2].IsNumber() ? (int)args[2].GetNumber() : 9;
            const int idAction = ProbeShowActionId(itemId);
            // KHONG goi MainMenuBar_Set o day nua - xem ghi chu trong ProbeLogDataPath: no ghi de
            // thanh phim tat da luu cua nhan vat (gui CGModifySetting len server) va trung voi cu
            // vang luc thoat o live-4. `slot` giu lai de doi so cua ham khong doi.
            (void)slot;
            TDU_Log("CYS-UIFRAMES probe: item=%d -> action=%d (bar placement disabled)", itemId, idAction);
            s->PushInteger(idAction);
            return 1;
        }

        void ProbeLogDataPath()
        {
            // Ids taken from the user's own session log (user-play-2: weapon 10106000) and from the
            // wardrobe depot Mongo read of wardrobe-2 (fashion 10124000/10124006), so these are real
            // rows of THIS tree's tables, not invented numbers.
            static const int kIds[] = {10106000, 10124000, 10124006, 30309900};
            CActionSystem* sys = CActionSystem::GetMe();
            if (!sys) { TDU_Log("CYS-UIFRAMES probe: no action system yet"); return; }
            int first = 0;
            for (int i = 0; i < (int)(sizeof(kIds) / sizeof(kIds[0])); ++i)
            {
                tActionItem* a = sys->CreateActionForShow((UINT)kIds[i]);
                TDU_Log("CYS-UIFRAMES probe: item=%d -> action=%d name=%s icon=%s",
                        kIds[i], a ? a->GetID() : 0,
                        a ? a->GetName() : "(none)", a ? a->GetIconName() : "(none)");
                if (a && !first) first = a->GetID();
            }
            // GO BO: ban dau buoc nay goi MainMenuBar_Set(9, first) de icon hien len thanh chinh
            // cho de chup anh. HAI LY DO PHAI BO, ca hai do duoc o live-4 (20/09 00:25-00:28):
            //  1. MainMenuBar_Set KHONG chi ve len thanh - no con dong goi CGModifySetting va GUI
            //     len server (GMActionSystem.cpp:1465+), tuc mot buoc "chi de lay bang chung" lai
            //     GHI DE thanh phim tat DA LUU cua nhan vat test. Do la tac dung phu khong ai xin.
            //  2. live-2 (khong co buoc nay) thoat sach 20/20 PASS; live-4 (co buoc nay) VANG luc
            //     thoat - mot cu nem C++ tai Game.exe+0x003DAC48, dung giay in "LuaApiGen missing
            //     calls end". Khac biet duy nhat giua hai luot la dong nay. CHUA chung minh nhan
            //     qua (mot mau, va live-4 con khac tai khoan/canh/co danh nhau), nhung mot buoc
            //     LAY BANG CHUNG ma lam client vang thi phai bo truoc, dieu tra sau.
            (void)first;
        }

        // ---- DUONG VE: dat icon THANG len mot widget ActionButton, KHONG gui goi -----------------
        // ActionButton::Lua_SetActionItem chi goi Update(id) -> ve lai o do (UILuaControl.cpp:977).
        // Khac han MainMenuBar_Set, thu da bi go vi no con gui CGModifySetting len server.
        // Chay tre qua SetTimer vi luc RegisterHost thanh chinh chua chac da dung xong.
        //
        // PHEP A/B: item id lay tu CYS_UIFRAMES_PROBE_ITEM.
        //   id CO THAT   (vd 10106000) -> GetID() khac 0 -> o phai DOI  (doi chung duong)
        //   id KHONG CO  (vd 99999999) -> GetID() = 0     -> o phai NGUYEN (doi chung am)
        // Hai luot chay cung tai khoan, cung canh, cung o => chenh lech chi con do icon.
        const char* kProbeChunk =
            "function CysUiFramesIconProbe()\n"
            "  local id = CysUiFramesProbeItem or 0\n"
            "  local aid = 0\n"
            "  local act = DataPool:CreateActionItemForShow(id, 1)\n"
            "  if act ~= nil then aid = act:GetID() end\n"
            // BAY DO DUOC o luot ab-neg 00:58: `Button_Action5` KHONG phai bien toan cuc.
            // Moi khung Lua chay trong MOI TRUONG RIENG ten `<Khung>_Env` (GMScriptSystm.cpp:37
            // `m_strNameInLua = m_strName + \"_Env\"`), va widget cua khung la bien trong moi truong
            // DO, khong phai trong _G. Lan dau tim trong _G nen `widget_found=0`.
            // Nen thu ca hai, va thu vai o de mot luot la du tim ra o dang trong.
            "  local names = {\"Button_Action5\",\"Button_Action4\",\"Button_Action6\",\"Button_Action3\"}\n"
            "  local w, wname = nil, \"\"\n"
            "  for i = 1, table.getn(names) do\n"
            "    local n = names[i]\n"
            "    local cand = rawget(getfenv(0), n)\n"
            "    if cand == nil and MainMenuBar_Env ~= nil then cand = MainMenuBar_Env[n] end\n"
            "    if cand ~= nil then w = cand wname = n break end\n"
            "  end\n"
            "  local found = 0\n"
            "  if w ~= nil then found = 1 w:SetActionItem(aid) end\n"
            // CYS-UIFIX2: goi DUNG bieu thuc dang ném o 23 site, tren mot doi tuong action THAT,
            // qua DUNG duong Lua that trong client that. Truoc ban va: phuong thuc la `nil` =>
            // "attempt to call method 'GetItemTableIndex' (a nil value)" => chunk nay chet va
            // Lua_CysIconProbeReport KHONG chay. Sau ban va: mot so.
            // `pcall` de neu no van ném thi lượt do van bao ve duoc, thay vi mat ca dong bao cao.
            "  local okti, ti = pcall(function() return act:GetItemTableIndex() end)\n"
            "  Lua_CysTableIndexReport(okti and 1 or 0, okti and ti or -999)\n"
            "  Lua_CysIconProbeReport(aid, found, wname)\n"
            "end\n";

        int ProbeItemId()
        {
            char buf[32] = {0};
            if (::GetEnvironmentVariableA("CYS_UIFRAMES_PROBE_ITEM", buf, sizeof(buf)) == 0) return 0;
            return atoi(buf);
        }

        void ScheduleWidgetProbe(LuaPlus::LuaState* state)
        {
            const int item = ProbeItemId();
            if (!state || item == 0) return;
            char line[256];
            _snprintf(line, sizeof(line) - 1, "CysUiFramesProbeItem = %d", item);
            line[sizeof(line) - 1] = 0;
            state->DoString(line);
            state->DoString(kProbeChunk);
            state->DoString("SetTimer(\"CysUiFrames\", \"CysUiFramesIconProbe()\", 15000)");
            TDU_Log("CYS-UIFRAMES probe: widget probe scheduled item=%d (Button_Action5, +15 s)", item);
        }

        struct Entry { const char* receiver; const char* name; int (*fn)(LuaPlus::LuaState*); };

        const Entry kEntries[] =
        {
            {"DataPool", "CreateActionItemForShow",     CreateActionItemForShow},
            {"DataPool", "CreateBindActionItemForShow", CreateBindActionItemForShow},
            {NULL,       "Lua_CysIconProbe",            GlobalCysIconProbe},        // CYS-only helper
            {NULL,       "Lua_CysIconProbeReport",      GlobalCysIconProbeReport},  // CYS-only helper
            {NULL,       "Lua_CysTableIndexReport",     GlobalCysTableIndexReport}, // CYS-only helper
        };
    }

    int Register(LuaPlus::LuaState* state)
    {
        if (!state) return 0;
        if (!CActionItem::s_pMetaTable || !CActionItem::s_pMetaTable->IsTable())
        {
            // The metatable is built in GMScriptSystm.cpp. Without it the boxed pointer would have
            // no methods and every call site would throw - worse than the stub. Refuse instead.
            TDU_Log("CYS-UIFRAMES: CActionItem metatable not ready, action-item host NOT registered");
            return 0;
        }
        // CYS-UIFIX2: them `GetItemTableIndex` vao ActionButtonMetaTable.
        // Dang ky O DAY chu khong o GMScriptSystm.cpp (noi 10 phuong thuc kia duoc dang ky) vi
        // tep ay dang co thay doi CHUA COMMIT cua nhanh `scenemap-api`; `git commit -- <duong dan>`
        // lay CA TEP nen mot dong cua toi se keo theo nam dong cua ho vao commit nay. Metatable
        // la mot LuaObject toan cuc, dang ky tu dau cung tuong duong - RegisterHost() chay sau khi
        // metatable da dung (chinh ham nay tu choi neu chua), nen thu tu van dung.
        CActionItem::s_pMetaTable->RegisterObjectFunctor(
            "GetItemTableIndex", &CActionItem::Lua_GetItemTableIndex);
        CActionItem::s_pMetaTable->RegisterObjectFunctor("GetItemID", &CActionItem::Lua_GetItemID);

        LuaPlus::LuaObject globals = state->GetGlobals();
        int registered = 0;
        for (const Entry& e : kEntries)
        {
            LuaPlus::LuaObject table = e.receiver ? Receiver(globals, e.receiver) : globals;
            if (!table.IsTable()) continue;
            table.Register(e.name, e.fn);   // forced: the generated stub already owns the slot
            ++registered;
        }
        return registered;
    }

    int ProbeShowActionId(int itemDefineId)
    {
        CActionSystem* sys = CActionSystem::GetMe();
        if (!sys || itemDefineId <= 0) return 0;
        tActionItem* pAction = sys->CreateActionForShow((UINT)itemDefineId);
        return pAction ? pAction->GetID() : 0;
    }

    void RegisterHost()
    {
        CScriptSystem* scripts = CScriptSystem::GetMe();
        if (!scripts || !scripts->GetLuaState()) return;
        const int n = Register(scripts->GetLuaState());
        TDU_Log("CYS-UIFRAMES: action-item host functions registered=%d of %d",
                n, (int)(sizeof(kEntries) / sizeof(kEntries[0])));
        if (EnvFlag("CYS_UIFRAMES_PROBE")) ProbeLogDataPath();
        ScheduleWidgetProbe(scripts->GetLuaState());
    }
}
