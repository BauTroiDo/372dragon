/*************************************************************************
 文件名	: 	AIScriptFunction.h
 版本号 :	0.0.1
 功  能	:	AIScript的专用函数
 修改记录:	
 *************************************************************************/


#ifndef _AISCRIPTFUNCTION_H_
#define _AISCRIPTFUNCTION_H_
#include "../sol/sol.hpp"
class Obj_Character;

typedef int (*PLAISFunc)( sol::table pChar, int param0, int param1, int param2 );
#define REGISTERAISFUNC(funcname) {#funcname,PLAISFunc(funcname)},

struct AISFuncMap
{
	char* funcname;
	PLAISFunc Func;
};

struct AISMacroMap
{
	char* Macroname;
	int	  MacroID;
};

const PLAISFunc GetFuncPtrbyName( const char* funcName );
const char*		GetFuncNamebyPtr( const PLAISFunc FuncPtr );
const int		GetMacrobyName( const char* MacroName );
// 接口部分
//////////////////////////////////////////////////////////////////////////
int	 AIS_GetBuffState( sol::table pChar, int param0, int param1, int param2 );

int	 AIS_GetAIState( sol::table pChar, int param0, int param1, int param2 );

int  AIS_GetHP( sol::table pChar, int param0, int param1, int param2 );

int  AIS_GetMP( sol::table pChar, int param0, int param1, int param2 );

int  AIS_Rand( sol::table pChar, int param0, int param1, int param2 );

int  AIS_GetEBuffState( sol::table pChar, int param0, int param1, int param2 );

int  AIS_GetEMP( sol::table pChar, int param0, int param1, int param2 );

int  AIS_GetEHP( sol::table pChar, int param0, int param1, int param2 );	

int  AIS_GetEMenPai( sol::table pChar, int param0, int param1, int param2 );	

int  AIS_GetELevel( sol::table pChar, int param0, int param1, int param2 );

int  AIS_IsCanSpeak( sol::table pChar, int param0, int param1, int param2 );

int  AIS_IsHasEnemy( sol::table pChar, int param0, int param1, int param2 );

int  AIS_GetESex( sol::table pChar, int param0, int param1, int param2 );

int  AIS_GetCamp(sol::table pChar, int param0, int param1, int param2 );

int  AIS_GetPK( sol::table pChar, int param0, int param1, int param2 );

int  AIS_GetETeamNum( sol::table pChar, int param0, int param1, int param2 );

int  AIS_IsEHasSpecialItem( sol::table pChar, int param0, int param1, int param2 );

int  AIS_GetSingleDamage( sol::table pChar, int param0, int param1, int param2 );

int  AIS_GetEnemyNum( sol::table pChar, int param0, int param1, int param2 );

int  AIS_IsBoss( sol::table pChar, int param0, int param1, int param2 );

int  AIS_BeSkill( sol::table pChar, int param0, int param1, int param2 );

int  AIS_ToFlee( sol::table pChar, int param0, int param1, int param2 );

int  AIS_IsCanSkill( sol::table pChar, int param0, int param1, int param2 );

int  AIS_ToSkill( sol::table pChar, int param0, int param1, int param2 );	

int  AIS_ToSummon( sol::table pChar, int param0, int param1, int param2 );

int  AIS_ToLongAttack( sol::table pChar, int param0, int param1, int param2 );

int  AIS_ToFollow( sol::table pChar, int param0, int param1, int param2 );

int  AIS_ToSpeak( sol::table pChar, int param0, int param1, int param2 );	

int  AIS_SetTimes( sol::table pChar, int param0, int param1, int param2 );

int  AIS_SetPRI( sol::table pChar, int param0, int param1, int param2 );

int  AIS_ToAssistTeammate( sol::table pChar, int param0, int param1, int param2 );

int  AIS_SetBaseAIType( sol::table pChar, int param0, int param1, int param2 );

int  AIS_SetPatrolID( sol::table pChar, int param0, int param1, int param2 );

int  AIS_CallOtherMonsterByGroup( sol::table pChar, int param0, int param1, int param2 );

int  AIS_CallOtherMonsterByTeam( sol::table pChar, int param0, int param1, int param2 );

int  AIS_StartPatrol( sol::table pChar, int param0, int param1, int param2 );

//int  AIS_PetToAttack( sol::table pChar, int param0, int param1, int param2 );
	   

#endif