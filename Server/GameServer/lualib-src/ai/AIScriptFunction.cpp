#include "AIScriptDef.h"
#include "AIScriptFunction.h"

AISFuncMap g_AISFuncTable[] =
{
	REGISTERAISFUNC(AIS_GetBuffState)
	REGISTERAISFUNC(AIS_GetAIState)
	REGISTERAISFUNC(AIS_GetHP)
	REGISTERAISFUNC(AIS_GetMP)
	REGISTERAISFUNC(AIS_Rand)
	REGISTERAISFUNC(AIS_GetEBuffState)
	REGISTERAISFUNC(AIS_GetEMP)
	REGISTERAISFUNC(AIS_GetEHP)
	REGISTERAISFUNC(AIS_GetEMenPai)
	REGISTERAISFUNC(AIS_GetELevel)
	REGISTERAISFUNC(AIS_IsCanSpeak)
	REGISTERAISFUNC(AIS_IsHasEnemy)
	REGISTERAISFUNC(AIS_GetESex)
	REGISTERAISFUNC(AIS_GetCamp)
	REGISTERAISFUNC(AIS_GetPK)
	REGISTERAISFUNC(AIS_GetETeamNum)
	REGISTERAISFUNC(AIS_IsEHasSpecialItem)
	REGISTERAISFUNC(AIS_GetSingleDamage)
	REGISTERAISFUNC(AIS_GetEnemyNum)
	REGISTERAISFUNC(AIS_IsBoss)
	REGISTERAISFUNC(AIS_BeSkill)
	REGISTERAISFUNC(AIS_ToFlee)
	REGISTERAISFUNC(AIS_IsCanSkill)
	REGISTERAISFUNC(AIS_ToSkill)
	REGISTERAISFUNC(AIS_ToSummon)
	REGISTERAISFUNC(AIS_ToLongAttack)
	REGISTERAISFUNC(AIS_ToFollow)
	REGISTERAISFUNC(AIS_ToSpeak)
	REGISTERAISFUNC(AIS_SetTimes)
	REGISTERAISFUNC(AIS_SetPRI)
	REGISTERAISFUNC(AIS_ToAssistTeammate)
	REGISTERAISFUNC(AIS_SetBaseAIType)
	REGISTERAISFUNC(AIS_SetPatrolID)
	REGISTERAISFUNC(AIS_StartPatrol)
	REGISTERAISFUNC(AIS_CallOtherMonsterByGroup)
	REGISTERAISFUNC(AIS_CallOtherMonsterByTeam)
	//REGISTERAISFUNC(AIS_PetToAttack)

};

AISMacroMap g_AISMacroTable[] = 
{
	"SIDLE",			SIDLE,
	"SAPPROACH",		SAPPROACH,
	"SFLEE",			SFLEE,
	//"SUSESKILL",		SUSESKILL,
	"SATTACK",			SATTACK,
	//"SCHANGEENEMY",	SCHANGEENEMY,
	//"SWAIT",			SWAIT,
	//"SFASTFLEE",		SFASTFLEE,
	//"SARRIVE",		SARRIVE,
	"SFOLLOW",			SFOLLOW,
	"SPATROL",			SPATROL,
	"SRETURN",			SRETURN,
	"SKILLSECTION",		SKILLSECTION,
	"ONBESKILLSECTION",	ONBESKILLSECTION,
	"ONDAMAGESECTION",	ONDAMAGESECTION,
	"ONDEADSECTION",	ONDEADSECTION,
	//"YUN",			YUN,
	//"ZHONGDU",		ZHONGDU,
	//"DEAD",			DEAD,
	//"SLEEP",			SLEEP,
	//"HAPPY",			HAPPY,
	//"ANGRY",			ANGRY,
	//"SORROW",			SORROW,
	//"ENJOY",			ENJOY,
	//"PHYSICSKILL",	PHYSICSKILL,
	//"MAGICSKILL",		MAGICSKILL,
	//"ASSISTSKILL",	ASSISTSKILL,

};

const PLAISFunc GetFuncPtrbyName(const char* funcName)
{
	for (int i = 0; i < sizeof(g_AISFuncTable)/sizeof(AISFuncMap); ++i)
	{
		if (strcmp(funcName, g_AISFuncTable[i].funcname) == 0) 
		{
			return g_AISFuncTable[i].Func;
		}
	}
	return NULL;
}

const char*	 GetFuncNamebyPtr(const PLAISFunc FuncPtr)
{
	for (int i = 0; i < sizeof(g_AISFuncTable)/sizeof(AISFuncMap); ++i)
	{
		if (FuncPtr == g_AISFuncTable[i].Func) 
		{
			return g_AISFuncTable[i].funcname;
		}
	}
	return NULL;
}

const int GetMacrobyName(const char* MacroName)
{
	for (int i = 0; i < sizeof(g_AISMacroTable)/sizeof(AISMacroMap); ++i)
	{
		if (strcmp(MacroName, g_AISMacroTable[i].Macroname) == 0) 
		{
			return g_AISMacroTable[i].MacroID;
		}
	}
	return -1;
}

/******************************************************************************
 * Desc		: 获取怪物状态
 * pChar	: 函数调用者，如：Monster或Pet
 * param0	: invalid
 * param1	: invalid
 * param2	: invalid
 */
int AIS_GetBuffState(sol::table pChar, int param0, int param1, int param2)
{
	return 0;
}
/******************************************************************************
* Desc		: 获取怪物AI状态
* pChar		: 函数调用者，如：Monster或Pet
* param0	: invalid
* param1	: invalid
* param2	: invalid
*/
int AIS_GetAIState(sol::table pChar, int param0, int param1, int param2)
{
	int state = 0;
	auto aiscript_call = pChar["aiscript_call"];
	auto result = aiscript_call(pChar, "get_ai_state", param0);
	if (result.valid()){
		state = result;
		CheckReturnType<int>(result, __FUNCTION__);
		return state;
	}else{
		sol::error err = result;
		std::cout<<"AIS_GetAIState error = " << err.what() << endl;
	}
	return state;
}
/******************************************************************************
* Desc		: 获取怪物HP
* pChar		: 函数调用者，如：Monster或Pet
* param0	: invalid
* param1	: invalid
* param2	: invalid
*/
int AIS_GetHP(sol::table pChar, int param0, int param1, int param2)
{
	int hp = 0;
	int max = 0;
	auto aiscript_call = pChar["aiscript_call"];
	{
		auto result = aiscript_call(pChar, "get_hp");
		if (result.valid()){
			hp = result;
		}else{
			sol::error err = result;
			std::cout<<"AIS_GetHP error = " << err.what() << endl;
		}
	}
	{
		auto result = aiscript_call(pChar, "get_max_hp");
		if (result.valid()){
			max = result;
		}else{
			sol::error err = result;
			std::cout<<"AIS_GetHP error = " << err.what() << endl;
		}
	}
	return hp * 100 / max;
}
/********************************************************************************
* Desc		: 获取怪物MP
* pChar		: 函数调用者，如：Monster或Pet
* param0	: invalid
* param1	: invalid
* param2	: invalid
*/
int AIS_GetMP(sol::table pChar, int param0, int param1, int param2)
{
	return 0;
}
/********************************************************************************
* Desc		: 随机取值
* pChar		: 函数调用者，如：Monster或Pet
* param0	: invalid
* param1	: invalid
* param2	: invalid
*/
int AIS_Rand(sol::table pChar, int param0, int param1, int param2)
{
	int rand = 0;
	auto aiscript_call = pChar["aiscript_call"];
	auto result = aiscript_call(pChar, "ais_rand", param0);
	if (result.valid()){
		rand = result;
	}else{
		sol::error err = result;
		std::cout<<"AIS_Rand error = " << err.what() << endl;
	}
	return rand;
}
/********************************************************************************
* Desc		: 敌人状态
* pChar		: 函数调用者，如：Monster或Pet
* param0	: invalid
* param1	: invalid
* param2	: invalid
*/
int AIS_GetEBuffState(sol::table pChar, int param0, int param1, int param2)
{
	return 0;
}
/********************************************************************************
* Desc		: 敌人MP
* pChar		: 函数调用者，如：Monster或Pet
* param0	: invalid

* param1	: invalid
* param2	: invalid
*/
int AIS_GetEMP(sol::table pChar, int param0, int param1, int param2)
{
	int emp = 0;
	auto aiscript_call = pChar["aiscript_call"];
	auto result = aiscript_call(pChar, "get_mp", param0);
	if (result.valid()){
		emp = result;
	}else{
		sol::error err = result;
		std::cout<<"AIS_GetEMP error = " << err.what() << endl;
	}
	return emp;
}
/********************************************************************************
* Desc		: 敌人HP
* pChar		: 函数调用者，如：Monster或Pet
* param0	: invalid
* param1	: invalid
* param2	: invalid
*/
int AIS_GetEHP(sol::table pChar, int param0, int param1, int param2)
{
	int ehp = 0;
	auto aiscript_call = pChar["aiscript_call"];
	auto result = aiscript_call(pChar, "get_hp", param0);
	if (result.valid()){
		ehp = result;
	}else{
		sol::error err = result;
		std::cout<<"AIS_GetEHP error = " << err.what() << endl;
	}
	return ehp;
}
/********************************************************************************
* Desc		: 敌人门派
* pChar		: 函数调用者，如：Monster或Pet
* param0	: invalid
* param1	: invalid
* param2	: invalid
*/
int AIS_GetEMenPai(sol::table pChar, int param0, int param1, int param2)
{
	int emp = 0;
	auto aiscript_call = pChar["aiscript_call"];
	auto result = aiscript_call(pChar, "get_menpai", param0);
	if (result.valid()){
		emp = result;
	}else{
		sol::error err = result;
		std::cout<<"AIS_GetEHP error = " << err.what() << endl;
	}
	return emp;
}
/********************************************************************************
* Desc		: 敌人等级
* pChar		: 函数调用者，如：Monster或Pet
* param0	: invalid
* param1	: invalid
* param2	: invalid
*/
int AIS_GetELevel(sol::table pChar, int param0, int param1, int param2)
{
	int elevel = 0;
	auto aiscript_call = pChar["aiscript_call"];
	auto result = aiscript_call(pChar, "get_level", param0);
	if (result.valid()){
		elevel = result;
	}else{
		sol::error err = result;
		std::cout<<"AIS_GetELevel error = " << err.what() << endl;
	}
	return elevel;
}
/********************************************************************************
* Desc		: 是否能说话
* pChar		: 函数调用者，如：Monster或Pet
* param0	: invalid
* param1	: invalid
* param2	: invalid
*/
int AIS_IsCanSpeak(sol::table pChar, int param0, int param1, int param2)
{
	return 0;

}
/********************************************************************************
* Desc		: 是否有敌人
* pChar		: 函数调用者，如：Monster或Pet
* param0	: invalid
* param1	: invalid
* param2	: invalid
*/
int AIS_IsHasEnemy(sol::table pChar, int param0, int param1, int param2)
{
	return 0;
}
/********************************************************************************
* Desc		: 敌方性别
* pChar		: 函数调用者，如：Monster或Pet
* param0	: invalid
* param1	: invalid
* param2	: invalid
*/
int AIS_GetESex(sol::table pChar, int param0, int param1, int param2)
{
	int esex = 0;
	auto aiscript_call = pChar["aiscript_call"];
	auto result = aiscript_call(pChar, "get_sex", param0);
	if (result.valid()){
		esex = result;
	}else{
		sol::error err = result;
		std::cout<<"AIS_GetESex error = " << err.what() << endl;
	}
	return esex;
}
/********************************************************************************
* Desc		: 阵营判断
* pChar		: 函数调用者，如：Monster或Pet
* param0	: invalid
* param1	: invalid
* param2	: invalid
*/
int AIS_GetCamp(sol::table pChar, int param0, int param1, int param2)
{
	if (sol::optional<sol::function> is_enemy = pChar["is_enemy"])
    {
    	return 1; //is_enemy.value()(pChar, param0);
    }
    else
    {
        std::cout << "error pChar does not have a 'is_enemy' method\n";
    }
}
/********************************************************************************
* Desc		: PK值
* pChar		: 函数调用者，如：Monster或Pet
* param0	: invalid
* param1	: invalid
* param2	: invalid
*/
int AIS_GetPK(sol::table pChar, int param0, int param1, int param2)
{
	return 0;
}
/********************************************************************************
* Desc		: 敌方队伍人数
* pChar		: 函数调用者，如：Monster或Pet
* param0	: invalid
* param1	: invalid
* param2	: invalid
*/
int AIS_GetETeamNum(sol::table pChar, int param0, int param1, int param2)
{
	int etnum = 0;
	auto aiscript_call = pChar["aiscript_call"];
	auto result = aiscript_call(pChar, "get_team_num", param0);
	if (result.valid()){
		etnum = result;
	}else{
		sol::error err = result;
		std::cout<<"AIS_GetETeamNum error = " << err.what() << endl;
	}
	return etnum;
}
/********************************************************************************
* Desc		: 敌方是否有特殊物品
* pChar		: 函数调用者，如：Monster或Pet
* param0	: invalid
* param1	: invalid
* param2	: invalid
*/
int AIS_IsEHasSpecialItem(sol::table pChar, int param0, int param1, int param2)
{
	return 0;

}
/********************************************************************************
* Desc		: 单次伤害值
* pChar		: 函数调用者，如：Monster或Pet
* param0	: invalid
* param1	: invalid
* param2	: invalid
*/
int AIS_GetSingleDamage(sol::table pChar, int param0, int param1, int param2)
{
	return 0;
}
/********************************************************************************
* Desc		: 敌人个数
* pChar		: 函数调用者，如：Monster或Pet
* param0	: invalid
* param1	: invalid
* param2	: invalid
*/
int AIS_GetEnemyNum(sol::table pChar, int param0, int param1, int param2)
{
	return 0;
}
/********************************************************************************
* Desc		: 是否为BOSS
* pChar		: 函数调用者，如：Monster或Pet
* param0	: invalid
* param1	: invalid
* param2	: invalid
*/
int AIS_IsBoss(sol::table pChar, int param0, int param1, int param2)
{
	return 0;

}
/********************************************************************************
* Desc		: 被敌方技能命中
* pChar		: 函数调用者，如：Monster或Pet
* param0	: 技能ID
* param1	: invalid
* param2	: invalid
*/
int AIS_BeSkill(sol::table pChar, int param0, int param1, int param2)
{
	return 0;
}
/********************************************************************************
* Desc		: 逃跑
* pChar		: 函数调用者，如：Monster或Pet
* param0	: 逃跑类型
* param1	: X坐标
* param2	: Z坐标
*/
int AIS_ToFlee(sol::table pChar, int param0, int param1, int param2)
{
	return 0;
}
/********************************************************************************
* Desc		: 是否能释放技能
* pChar		: 函数调用者，如：Monster或Pet
* param0	: 技能ID
* param1	: invalid
* param2	: invalid
*/
int  AIS_IsCanSkill(sol::table pChar, int param0, int param1, int param2)
{
	int is_can = 0;
	auto aiscript_call = pChar["aiscript_call"];
	auto result = aiscript_call(pChar, "ais_is_can_skill", param0);
	if (result.valid()){
		is_can = result;
	}else{
		sol::error err = result;
		std::cout<<"AIS_IsCanSkill error = " << err.what() << endl;
	}
	return is_can;
}
/********************************************************************************
* Desc		: 使用技能
* pChar		: 函数调用者，如：Monster或Pet
* param0	: 技能ID
* param1	: invalid
* param2	: invalid
*/
int AIS_ToSkill(sol::table pChar, int param0, int param1, int param2)
{
	auto aiscript_call = pChar["aiscript_call"];
	auto result = aiscript_call(pChar, "ais_to_skill", param0);
	if (result.valid()){
	}else{
		sol::error err = result;
		std::cout<<"AIS_IsCanSkill error = " << err.what() << endl;
	}
	return 1;
}
/********************************************************************************
* Desc		: 召唤队友
* pChar		: 函数调用者，如：Monster或Pet
* param0	: 召唤类型
* param1	: 召唤个数
* param2	: invalid
*/
int AIS_ToSummon(sol::table pChar, int param0, int param1, int param2)
{
	return 0;
}
/********************************************************************************
* Desc		: 远程攻击
* pChar		: 函数调用者，如：Monster或Pet
* param0	: invalid
* param1	: invalid
* param2	: invalid
*/
int AIS_ToLongAttack(sol::table pChar, int param0, int param1, int param2)
{
	return 0;

}
/********************************************************************************
* Desc		: 跟随
* pChar		: 函数调用者，如：Monster或Pet
* param0	: invalid
* param1	: invalid
* param2	: invalid
*/
int AIS_ToFollow(sol::table pChar, int param0, int param1, int param2)
{
	return 0;

}
/********************************************************************************
* Desc		: 泡泡说话
* pChar		: 函数调用者，如：Monster或Pet
* param0	: 泡泡起始ID
* param1	: 泡泡ID范围
* param2	: invalid
*/
int AIS_ToSpeak(sol::table pChar, int param0, int param1, int param2)
{
	return 0;
}
/********************************************************************************
* Desc		: 设置各种行为的执行次数
* pChar		: 函数调用者，如：Monster或Pet
* param0	: invalid
* param1	: invalid
* param2	: invalid
*/
int AIS_SetTimes(sol::table pChar, int param0, int param1, int param2)
{
	return 1;
}
/********************************************************************************
* Desc		: 设置各种行为的优先级
* pChar		: 函数调用者，如：Monster或Pet
* param0	: invalid
* param1	: invalid
* param2	: invalid
*/
int  AIS_SetPRI(sol::table pChar, int param0, int param1, int param2)
{
	return 1;
}
/********************************************************************************
* Desc		: 协助队友
* pChar		: 函数调用者，如：Monster或Pet
* param0	: 队友ID
* param1	: invalid
* param2	: invalid
*/
int AIS_ToAssistTeammate(sol::table pChar, int param0, int param1, int param2)
{
	return 0;
}

int AIS_SetBaseAIType(sol::table pChar, int param0, int param1, int param2)
{
	return 0;
}

int AIS_SetPatrolID(sol::table pChar, int param0, int param1, int param2)
{
	return 0;
}

int AIS_CallOtherMonsterByGroup(sol::table pChar, int param0, int param1, int param2)
{
	auto aiscript_call = pChar["aiscript_call"];
	auto result = aiscript_call(pChar, "ais_call_other_monster_by_group", param0);
	if (result.valid()){
	}else{
		sol::error err = result;
		std::cout<<"AIS_CallOtherMonsterByGroup error = " << err.what() << endl;
	}
	return 1;
}

int AIS_CallOtherMonsterByTeam(sol::table pChar, int param0, int param1, int param2)
{
	return 0;
}

int AIS_StartPatrol(sol::table pChar, int param0, int param1, int param2)
{
	return 0;
}