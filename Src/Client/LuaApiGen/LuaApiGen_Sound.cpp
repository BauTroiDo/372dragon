




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_Sound_PlaySoundEffect(LuaPlus::LuaState* state) { return Stub(state, "Sound", "PlaySoundEffect", "n"); }

        int LAG_Sound_PlayUISound(LuaPlus::LuaState* state) { return Stub(state, "Sound", "PlayUISound", ""); }
    }

    void Register_Sound(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "PlaySoundEffect")) table.Register("PlaySoundEffect", LAG_Sound_PlaySoundEffect);
        if (IsMissing(table, "PlayUISound")) table.Register("PlayUISound", LAG_Sound_PlayUISound);
    }
}
