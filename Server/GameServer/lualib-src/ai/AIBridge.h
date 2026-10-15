#ifndef __AI_BRIDGE_H__
#define __AI_BRIDGE_H__
#include "AIScriptDef.h"

void ReSetNeedGoDist(sol::table ai);
int GetAIScriptTimes(sol::table ai, int id);
void SetAIScriptTimes(sol::table ai, int id, int time);
int GetSkillID(sol::table ai);
float GetNeedGoDist(sol::table ai, int skill = 0);
void SetNeedGoDist(sol::table ai, float dist);
void SetSkillID(sol::table ai, int skill);
sol::table GetCharacter(sol::table ai);
#endif