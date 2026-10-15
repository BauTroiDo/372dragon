#include "AIBridge.h"

void ReSetNeedGoDist(sol::table ai)
{
    auto aiscript_call = ai["aiscript_call"];
	auto result = aiscript_call(ai, "ReSetNeedGoDist");
}

int GetAIScriptTimes(sol::table ai, int id)
{
    int times = -1;
    auto aiscript_call = ai["aiscript_call"];
	auto result = aiscript_call(ai, "GetAIScriptTimes", id);
    if (result.valid()){
        times = result;
    }
    return times;
}

void SetAIScriptTimes(sol::table ai, int id, int time)
{
    auto aiscript_call = ai["aiscript_call"];
	auto result = aiscript_call(ai, "SetAIScriptTimes", id, time);
}

int GetSkillID(sol::table ai)
{
    int skill = 0;
    auto aiscript_call = ai["aiscript_call"];
	auto result = aiscript_call(ai, "GetSkillID");
    if (result.valid()){
        skill = result;
    }else{
        sol::error err = result;
		std::cout<<"AIS_IsCanSkill error = " << err.what() << endl;
    }
    return skill;
}

float GetNeedGoDist(sol::table ai, int skill)
{
    float dist = 0;
    auto aiscript_call = ai["aiscript_call"];
	auto result = aiscript_call(ai, "GetNeedGoDist", skill);
    if (result.valid()){
        dist = result;
    }
    return dist;
}

void SetNeedGoDist(sol::table ai, float dist)
{
    auto aiscript_call = ai["aiscript_call"];
	auto result = aiscript_call(ai, "SetNeedGoDist", dist);
}

void SetSkillID(sol::table ai, int skill)
{
    auto aiscript_call = ai["aiscript_call"];
	auto result = aiscript_call(ai, "SetSkillID", skill);
}

sol::table GetCharacter(sol::table ai)
{
    auto aiscript_call = ai["aiscript_call"];
	auto result = aiscript_call(ai, "get_character");
    if (result.valid()){
        return result;
    }
}