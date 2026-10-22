




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_YiGui_ClearShowDressByIndex(LuaPlus::LuaState* state) { return Stub(state, "YiGui", "ClearShowDressByIndex", ""); }

        int LAG_YiGui_CloseYiGui(LuaPlus::LuaState* state) { return Stub(state, "YiGui", "CloseYiGui", ""); }


        int LAG_YiGui_EnumItem(LuaPlus::LuaState* state) { return Stub(state, "YiGui", "EnumItem", "o"); }


        int LAG_YiGui_EnumItemName(LuaPlus::LuaState* state) { return Stub(state, "YiGui", "EnumItemName", "sssn"); }

        int LAG_YiGui_EquipDressAskBind(LuaPlus::LuaState* state) { return Stub(state, "YiGui", "EquipDressAskBind", ""); }

        int LAG_YiGui_EquipDressWithoutAskBind(LuaPlus::LuaState* state) { return Stub(state, "YiGui", "EquipDressWithoutAskBind", ""); }

        int LAG_YiGui_GetFashionSpecialVisualName(LuaPlus::LuaState* state) { return Stub(state, "YiGui", "GetFashionSpecialVisualName", "nn"); }

        int LAG_YiGui_GetYiGuiMoveFromIndex(LuaPlus::LuaState* state) { return Stub(state, "YiGui", "GetYiGuiMoveFromIndex", "n"); }

        int LAG_YiGui_GetYiGuiMoveToIndex(LuaPlus::LuaState* state) { return Stub(state, "YiGui", "GetYiGuiMoveToIndex", "n"); }

        int LAG_YiGui_GetYiGuiNpcID(LuaPlus::LuaState* state) { return Stub(state, "YiGui", "GetYiGuiNpcID", "n"); }

        int LAG_YiGui_GetYiGuiSize(LuaPlus::LuaState* state) { return Stub(state, "YiGui", "GetYiGuiSize", "n"); }

        int LAG_YiGui_PlayDressAction(LuaPlus::LuaState* state) { return Stub(state, "YiGui", "PlayDressAction", ""); }

        int LAG_YiGui_ResetYiGuiMoveFlag(LuaPlus::LuaState* state) { return Stub(state, "YiGui", "ResetYiGuiMoveFlag", ""); }

        int LAG_YiGui_SetChangeSexNewModel(LuaPlus::LuaState* state) { return Stub(state, "YiGui", "SetChangeSexNewModel", ""); }

        int LAG_YiGui_SetShowDress(LuaPlus::LuaState* state) { return Stub(state, "YiGui", "SetShowDress", "n"); }
    }

    void Register_YiGui(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "ClearShowDressByIndex")) table.Register("ClearShowDressByIndex", LAG_YiGui_ClearShowDressByIndex);
        if (IsMissing(table, "CloseYiGui")) table.Register("CloseYiGui", LAG_YiGui_CloseYiGui);
        if (IsMissing(table, "EnumItem")) table.Register("EnumItem", LAG_YiGui_EnumItem);
        if (IsMissing(table, "EnumItemName")) table.Register("EnumItemName", LAG_YiGui_EnumItemName);
        if (IsMissing(table, "EquipDressAskBind")) table.Register("EquipDressAskBind", LAG_YiGui_EquipDressAskBind);
        if (IsMissing(table, "EquipDressWithoutAskBind")) table.Register("EquipDressWithoutAskBind", LAG_YiGui_EquipDressWithoutAskBind);
        if (IsMissing(table, "GetFashionSpecialVisualName")) table.Register("GetFashionSpecialVisualName", LAG_YiGui_GetFashionSpecialVisualName);
        if (IsMissing(table, "GetYiGuiMoveFromIndex")) table.Register("GetYiGuiMoveFromIndex", LAG_YiGui_GetYiGuiMoveFromIndex);
        if (IsMissing(table, "GetYiGuiMoveToIndex")) table.Register("GetYiGuiMoveToIndex", LAG_YiGui_GetYiGuiMoveToIndex);
        if (IsMissing(table, "GetYiGuiNpcID")) table.Register("GetYiGuiNpcID", LAG_YiGui_GetYiGuiNpcID);
        if (IsMissing(table, "GetYiGuiSize")) table.Register("GetYiGuiSize", LAG_YiGui_GetYiGuiSize);
        if (IsMissing(table, "PlayDressAction")) table.Register("PlayDressAction", LAG_YiGui_PlayDressAction);
        if (IsMissing(table, "ResetYiGuiMoveFlag")) table.Register("ResetYiGuiMoveFlag", LAG_YiGui_ResetYiGuiMoveFlag);
        if (IsMissing(table, "SetChangeSexNewModel")) table.Register("SetChangeSexNewModel", LAG_YiGui_SetChangeSexNewModel);
        if (IsMissing(table, "SetShowDress")) table.Register("SetShowDress", LAG_YiGui_SetShowDress);
    }
}
