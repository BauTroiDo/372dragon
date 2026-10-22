




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_Macro_disableeventlog(LuaPlus::LuaState* state) { return Stub(state, "Macro", "disableeventlog", ""); }

        int LAG_Macro_dumpluaglobals(LuaPlus::LuaState* state) { return Stub(state, "Macro", "dumpluaglobals", ""); }

        int LAG_Macro_efflog(LuaPlus::LuaState* state) { return Stub(state, "Macro", "efflog", ""); }

        int LAG_Macro_enableeventlog(LuaPlus::LuaState* state) { return Stub(state, "Macro", "enableeventlog", ""); }

        int LAG_Macro_enableforbid(LuaPlus::LuaState* state) { return Stub(state, "Macro", "enableforbid", ""); }


        int LAG_Macro_exescript(LuaPlus::LuaState* state) { return Stub(state, "Macro", "exescript", ""); }


        int LAG_Macro_goto(LuaPlus::LuaState* state) { return Stub(state, "Macro", "goto", "o"); }

        int LAG_Macro_ngclear(LuaPlus::LuaState* state) { return Stub(state, "Macro", "ngclear", ""); }

        int LAG_Macro_ngenabletick(LuaPlus::LuaState* state) { return Stub(state, "Macro", "ngenabletick", ""); }

        int LAG_Macro_ngevent(LuaPlus::LuaState* state) { return Stub(state, "Macro", "ngevent", ""); }


        int LAG_Macro_ngload(LuaPlus::LuaState* state) { return Stub(state, "Macro", "ngload", ""); }

        int LAG_Macro_ngtick(LuaPlus::LuaState* state) { return Stub(state, "Macro", "ngtick", ""); }


        int LAG_Macro_pbuildt(LuaPlus::LuaState* state) { return Stub(state, "Macro", "pbuildt", ""); }

        int LAG_Macro_pr(LuaPlus::LuaState* state) { return Stub(state, "Macro", "pr", ""); }

        int LAG_Macro_pushball(LuaPlus::LuaState* state) { return Stub(state, "Macro", "pushball", ""); }

        int LAG_Macro_reloadscript(LuaPlus::LuaState* state) { return Stub(state, "Macro", "reloadscript", ""); }

        int LAG_Macro_reloadsystemcolor(LuaPlus::LuaState* state) { return Stub(state, "Macro", "reloadsystemcolor", ""); }

        int LAG_Macro_renderlog(LuaPlus::LuaState* state) { return Stub(state, "Macro", "renderlog", ""); }


        int LAG_Macro_sendhardchat(LuaPlus::LuaState* state) { return Stub(state, "Macro", "sendhardchat", ""); }

        int LAG_Macro_setfog(LuaPlus::LuaState* state) { return Stub(state, "Macro", "setfog", ""); }


        int LAG_Macro_supermanfast(LuaPlus::LuaState* state) { return Stub(state, "Macro", "supermanfast", "o"); }


        int LAG_Macro_supermangoto(LuaPlus::LuaState* state) { return Stub(state, "Macro", "supermangoto", "o"); }


        int LAG_Macro_supermanlevelup(LuaPlus::LuaState* state) { return Stub(state, "Macro", "supermanlevelup", "o"); }


        int LAG_Macro_supermanxinfalevelup(LuaPlus::LuaState* state) { return Stub(state, "Macro", "supermanxinfalevelup", "o"); }


        int LAG_Macro_supermanyinshen(LuaPlus::LuaState* state) { return Stub(state, "Macro", "supermanyinshen", "o"); }


        int LAG_Macro_survey(LuaPlus::LuaState* state) { return Stub(state, "Macro", "survey", ""); }
    }

    void Register_Macro(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "disableeventlog")) table.Register("disableeventlog", LAG_Macro_disableeventlog);
        if (IsMissing(table, "dumpluaglobals")) table.Register("dumpluaglobals", LAG_Macro_dumpluaglobals);
        if (IsMissing(table, "efflog")) table.Register("efflog", LAG_Macro_efflog);
        if (IsMissing(table, "enableeventlog")) table.Register("enableeventlog", LAG_Macro_enableeventlog);
        if (IsMissing(table, "enableforbid")) table.Register("enableforbid", LAG_Macro_enableforbid);
        if (IsMissing(table, "exescript")) table.Register("exescript", LAG_Macro_exescript);
        if (IsMissing(table, "goto")) table.Register("goto", LAG_Macro_goto);
        if (IsMissing(table, "ngclear")) table.Register("ngclear", LAG_Macro_ngclear);
        if (IsMissing(table, "ngenabletick")) table.Register("ngenabletick", LAG_Macro_ngenabletick);
        if (IsMissing(table, "ngevent")) table.Register("ngevent", LAG_Macro_ngevent);
        if (IsMissing(table, "ngload")) table.Register("ngload", LAG_Macro_ngload);
        if (IsMissing(table, "ngtick")) table.Register("ngtick", LAG_Macro_ngtick);
        if (IsMissing(table, "pbuildt")) table.Register("pbuildt", LAG_Macro_pbuildt);
        if (IsMissing(table, "pr")) table.Register("pr", LAG_Macro_pr);
        if (IsMissing(table, "pushball")) table.Register("pushball", LAG_Macro_pushball);
        if (IsMissing(table, "reloadscript")) table.Register("reloadscript", LAG_Macro_reloadscript);
        if (IsMissing(table, "reloadsystemcolor")) table.Register("reloadsystemcolor", LAG_Macro_reloadsystemcolor);
        if (IsMissing(table, "renderlog")) table.Register("renderlog", LAG_Macro_renderlog);
        if (IsMissing(table, "sendhardchat")) table.Register("sendhardchat", LAG_Macro_sendhardchat);
        if (IsMissing(table, "setfog")) table.Register("setfog", LAG_Macro_setfog);
        if (IsMissing(table, "supermanfast")) table.Register("supermanfast", LAG_Macro_supermanfast);
        if (IsMissing(table, "supermangoto")) table.Register("supermangoto", LAG_Macro_supermangoto);
        if (IsMissing(table, "supermanlevelup")) table.Register("supermanlevelup", LAG_Macro_supermanlevelup);
        if (IsMissing(table, "supermanxinfalevelup")) table.Register("supermanxinfalevelup", LAG_Macro_supermanxinfalevelup);
        if (IsMissing(table, "supermanyinshen")) table.Register("supermanyinshen", LAG_Macro_supermanyinshen);
        if (IsMissing(table, "survey")) table.Register("survey", LAG_Macro_survey);
    }
}
