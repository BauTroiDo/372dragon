




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_UI_WorldMapWindow_GetCurrentSelectScene(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_WorldMapWindow", "GetCurrentSelectScene", "n"); }


        int LAG_UI_WorldMapWindow_InitWorldMap(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_WorldMapWindow", "InitWorldMap", ""); }


        int LAG_UI_WorldMapWindow_UpdateWorldMap(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_WorldMapWindow", "UpdateWorldMap", ""); }
    }

    void Register_UI_WorldMapWindow(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "GetCurrentSelectScene")) table.Register("GetCurrentSelectScene", LAG_UI_WorldMapWindow_GetCurrentSelectScene);
        if (IsMissing(table, "InitWorldMap")) table.Register("InitWorldMap", LAG_UI_WorldMapWindow_InitWorldMap);
        if (IsMissing(table, "UpdateWorldMap")) table.Register("UpdateWorldMap", LAG_UI_WorldMapWindow_UpdateWorldMap);
    }
}
