




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_CoupleZone_LuaFnCoupleInYBOrMoney(LuaPlus::LuaState* state) { return Stub(state, "CoupleZone", "LuaFnCoupleInYBOrMoney", ""); }


        int LAG_CoupleZone_LuaFnCoupleOutYBOrMoney(LuaPlus::LuaState* state) { return Stub(state, "CoupleZone", "LuaFnCoupleOutYBOrMoney", ""); }


        int LAG_CoupleZone_LuaFnDeleteCalendarByDate(LuaPlus::LuaState* state) { return Stub(state, "CoupleZone", "LuaFnDeleteCalendarByDate", "n"); }


        int LAG_CoupleZone_LuaFnDeleteDiaryByRealId(LuaPlus::LuaState* state) { return Stub(state, "CoupleZone", "LuaFnDeleteDiaryByRealId", "n"); }

        int LAG_CoupleZone_LuaFnGetCoupleVaultCharName_0(LuaPlus::LuaState* state) { return Stub(state, "CoupleZone", "LuaFnGetCoupleVaultCharName_0", "s"); }

        int LAG_CoupleZone_LuaFnGetCoupleVaultCharName_1(LuaPlus::LuaState* state) { return Stub(state, "CoupleZone", "LuaFnGetCoupleVaultCharName_1", "s"); }

        int LAG_CoupleZone_LuaFnGetCoupleVaultLogContent(LuaPlus::LuaState* state) { return Stub(state, "CoupleZone", "LuaFnGetCoupleVaultLogContent", "nnnsnsn"); }

        int LAG_CoupleZone_LuaFnGetCoupleVaultLogNum(LuaPlus::LuaState* state) { return Stub(state, "CoupleZone", "LuaFnGetCoupleVaultLogNum", "n"); }

        int LAG_CoupleZone_LuaFnGetCoupleVaultMoney(LuaPlus::LuaState* state) { return Stub(state, "CoupleZone", "LuaFnGetCoupleVaultMoney", "n"); }

        int LAG_CoupleZone_LuaFnGetCoupleVaultYB(LuaPlus::LuaState* state) { return Stub(state, "CoupleZone", "LuaFnGetCoupleVaultYB", "n"); }

        int LAG_CoupleZone_LuaFnGetCoupleZoneData_Annal_WithId(LuaPlus::LuaState* state) { return Stub(state, "CoupleZone", "LuaFnGetCoupleZoneData_Annal_WithId", ""); }

        int LAG_CoupleZone_LuaFnGetCoupleZoneData_Calendar(LuaPlus::LuaState* state) { return Stub(state, "CoupleZone", "LuaFnGetCoupleZoneData_Calendar", "t"); }

        int LAG_CoupleZone_LuaFnGetCoupleZoneData_Diary_WithPage(LuaPlus::LuaState* state) { return Stub(state, "CoupleZone", "LuaFnGetCoupleZoneData_Diary_WithPage", "t"); }

        int LAG_CoupleZone_LuaFnGetCoupleZoneData_License(LuaPlus::LuaState* state) { return Stub(state, "CoupleZone", "LuaFnGetCoupleZoneData_License", "ssn"); }

        int LAG_CoupleZone_LuaFnGetCoupleZoneData_Main(LuaPlus::LuaState* state) { return Stub(state, "CoupleZone", "LuaFnGetCoupleZoneData_Main", "t"); }

        int LAG_CoupleZone_LuaFnGetCoupleZoneData_Vault(LuaPlus::LuaState* state) { return Stub(state, "CoupleZone", "LuaFnGetCoupleZoneData_Vault", "t"); }

        int LAG_CoupleZone_LuaFnIsCZoneRedPointInUIShow(LuaPlus::LuaState* state) { return Stub(state, "CoupleZone", "LuaFnIsCZoneRedPointInUIShow", "n"); }

        int LAG_CoupleZone_LuaFnSetCZoneRedPointInUIShow(LuaPlus::LuaState* state) { return Stub(state, "CoupleZone", "LuaFnSetCZoneRedPointInUIShow", "n"); }


        int LAG_CoupleZone_LuaFnWriteNewCalendar(LuaPlus::LuaState* state) { return Stub(state, "CoupleZone", "LuaFnWriteNewCalendar", "n"); }


        int LAG_CoupleZone_LuaFnWriteNewDiary(LuaPlus::LuaState* state) { return Stub(state, "CoupleZone", "LuaFnWriteNewDiary", "n"); }
    }

    void Register_CoupleZone(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "LuaFnCoupleInYBOrMoney")) table.Register("LuaFnCoupleInYBOrMoney", LAG_CoupleZone_LuaFnCoupleInYBOrMoney);
        if (IsMissing(table, "LuaFnCoupleOutYBOrMoney")) table.Register("LuaFnCoupleOutYBOrMoney", LAG_CoupleZone_LuaFnCoupleOutYBOrMoney);
        if (IsMissing(table, "LuaFnDeleteCalendarByDate")) table.Register("LuaFnDeleteCalendarByDate", LAG_CoupleZone_LuaFnDeleteCalendarByDate);
        if (IsMissing(table, "LuaFnDeleteDiaryByRealId")) table.Register("LuaFnDeleteDiaryByRealId", LAG_CoupleZone_LuaFnDeleteDiaryByRealId);
        if (IsMissing(table, "LuaFnGetCoupleVaultCharName_0")) table.Register("LuaFnGetCoupleVaultCharName_0", LAG_CoupleZone_LuaFnGetCoupleVaultCharName_0);
        if (IsMissing(table, "LuaFnGetCoupleVaultCharName_1")) table.Register("LuaFnGetCoupleVaultCharName_1", LAG_CoupleZone_LuaFnGetCoupleVaultCharName_1);
        if (IsMissing(table, "LuaFnGetCoupleVaultLogContent")) table.Register("LuaFnGetCoupleVaultLogContent", LAG_CoupleZone_LuaFnGetCoupleVaultLogContent);
        if (IsMissing(table, "LuaFnGetCoupleVaultLogNum")) table.Register("LuaFnGetCoupleVaultLogNum", LAG_CoupleZone_LuaFnGetCoupleVaultLogNum);
        if (IsMissing(table, "LuaFnGetCoupleVaultMoney")) table.Register("LuaFnGetCoupleVaultMoney", LAG_CoupleZone_LuaFnGetCoupleVaultMoney);
        if (IsMissing(table, "LuaFnGetCoupleVaultYB")) table.Register("LuaFnGetCoupleVaultYB", LAG_CoupleZone_LuaFnGetCoupleVaultYB);
        if (IsMissing(table, "LuaFnGetCoupleZoneData_Annal_WithId")) table.Register("LuaFnGetCoupleZoneData_Annal_WithId", LAG_CoupleZone_LuaFnGetCoupleZoneData_Annal_WithId);
        if (IsMissing(table, "LuaFnGetCoupleZoneData_Calendar")) table.Register("LuaFnGetCoupleZoneData_Calendar", LAG_CoupleZone_LuaFnGetCoupleZoneData_Calendar);
        if (IsMissing(table, "LuaFnGetCoupleZoneData_Diary_WithPage")) table.Register("LuaFnGetCoupleZoneData_Diary_WithPage", LAG_CoupleZone_LuaFnGetCoupleZoneData_Diary_WithPage);
        if (IsMissing(table, "LuaFnGetCoupleZoneData_License")) table.Register("LuaFnGetCoupleZoneData_License", LAG_CoupleZone_LuaFnGetCoupleZoneData_License);
        if (IsMissing(table, "LuaFnGetCoupleZoneData_Main")) table.Register("LuaFnGetCoupleZoneData_Main", LAG_CoupleZone_LuaFnGetCoupleZoneData_Main);
        if (IsMissing(table, "LuaFnGetCoupleZoneData_Vault")) table.Register("LuaFnGetCoupleZoneData_Vault", LAG_CoupleZone_LuaFnGetCoupleZoneData_Vault);
        if (IsMissing(table, "LuaFnIsCZoneRedPointInUIShow")) table.Register("LuaFnIsCZoneRedPointInUIShow", LAG_CoupleZone_LuaFnIsCZoneRedPointInUIShow);
        if (IsMissing(table, "LuaFnSetCZoneRedPointInUIShow")) table.Register("LuaFnSetCZoneRedPointInUIShow", LAG_CoupleZone_LuaFnSetCZoneRedPointInUIShow);
        if (IsMissing(table, "LuaFnWriteNewCalendar")) table.Register("LuaFnWriteNewCalendar", LAG_CoupleZone_LuaFnWriteNewCalendar);
        if (IsMissing(table, "LuaFnWriteNewDiary")) table.Register("LuaFnWriteNewDiary", LAG_CoupleZone_LuaFnWriteNewDiary);
    }
}
