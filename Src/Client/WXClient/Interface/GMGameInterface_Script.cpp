#include "StdAfx.h"
#include "GMGameInterface.h"
#include "GMGameInterface_Script.h"
#include "../Procedure/GamePro_Login.h"
#include "../NetWork/NetManager.h"
#include "LuaPlus.h"
#include "../Global.h"
#include "../Event/GMEventSystem.h"
#include "TDException.h"
#include "../Action/GMActionSystem.h"
#include "../DataPool/GMUIDataPool.h"
#include "../DataPool/GMDataPool.h"
#include "../Object/ObjectManager.h"
#include "../Object/Object.h"
#include "../Object/Character/Obj_Character.h"
#include "../Input/GMInputSystem.h"
#include "../world/worldmanager.h"
#include "tddbc_struct.h"
#include "../object/character/obj_playermyself.h"
#include "tdutil.h"
#include "ScriptCommandStruct.h"
#include "CGEventRequest.h"
#include "CGTeamInvite.h"
#include "CGAskDetailEquipList.h"
#include "..\DBC\GMDataBase.h"
#include "..\DataPool\GMDP_CharacterData.h"
#include "GMInterface_Script_Tooltip.h"
#include "../world/scene.h"
#include "..\Procedure\GameProcedure.h"
#include "..\Procedure\GamePro_main.h"
#include "TDUISystem.h"
#include "..\Sound\GMSoundSystem.h"
#include "CGDiscardItem.h"
#include "CGDiscardEquip.h"
#include "CGCharIdle.h"
#include "..\Object\Item\Obj_Item_Equip.h"
#include "..\Object\ObjectCommandDef.h"
#include "CGExecuteScript.h"
#include "..\WxRender\RenderSystem.h"
#include "CGMinorPasswd.h"								// 发送设置2级密码
#include "..\Action\GMActionSystem_MouseCmd.h"
#include "CGAskDetailSkillList.h"
#include "../Network/CysModernGame.h"
#include "PgPackets_mission.h"
#include <array>
using namespace LuaPlus;

namespace SCRIPT_SANDBOX
{
// CY CGExecuteScript carries a byte count followed by that many signed ints.
// Keep this separate from the six-field 0.85 X_SCRIPT ABI shared with DLLs.
static std::array<int,255> cysScriptParams = {};
static unsigned cysScriptParamCount = 0;
	const FLOAT PI_2 = 2 * __PI;
//登陆界面中，用于点击确定后的操作(-- for debug)
INT Lua_ServerLogin(LuaPlus::LuaState* state)
{
	if(CGameProcedure::GetActiveProcedure() == (CGameProcedure*)CGameProcedure::s_pProcLogIn)
	{
		CSoundSystemFMod::_PlayUISoundFunc(68);
		if(CGameProcedure::s_pProcLogIn->GetStatus() == CGamePro_Login::LOGIN_DEBUG_SETTING)
		{
			CGameProcedure::s_pProcLogIn->SetStatus(CGamePro_Login::LOGIN_DISCONNECT);
		}
	}
	return 0;
}

//要求退出程序
INT Lua_QuitApplication(LuaPlus::LuaState* state)
{
	PostMessage(g_hMainWnd, WM_CLOSE, 0XC0DE, 0XC0DE);
	return 0;
}

//要求打开/关闭技能书
INT Lua_ToggleSkillBook(LuaPlus::LuaState* state)
{
	/*INT m_ID;*/
	if(CGameProcedure::s_pUISystem && 
		(CGameProcedure::s_pUISystem->IsWindowShow("LifeSkill") || 
		 CGameProcedure::s_pUISystem->IsWindowShow("ActionSkill") ||
		 CGameProcedure::s_pUISystem->IsWindowShow("CommonSkill") ) ) 
		CEventSystem::GetMe()->PushEvent(GE_CLOSE_SKILL_BOOK);
	else
		/*m_ID = CObjectManager::GetMe()->GetMySelf()->GetServerID();
		CGAskDetailSkillList	msgMySkill;
		msgMySkill.setTargetID(m_ID);
		CNetManager::GetMe()->SendPacket(&msgMySkill);*/
		CEventSystem::GetMe()->PushEvent(GE_TOGLE_COMMONSKILL_PAGE);
	//CEventSystem::GetMe()->PushEvent(GE_PROGRESSBAR_WIDTH,10);
	return 0;
}

//要求打开技能书
INT Lua_OpenSkillBook(LuaPlus::LuaState* state)
{
	CEventSystem::GetMe()->PushEvent(GE_TOGLE_SKILL_BOOK);
	//CEventSystem::GetMe()->PushEvent(GE_PROGRESSBAR_WIDTH,10);
	return 0;
}
//要求打开/关闭宠物界面
INT Lua_TogglePetPage(LuaPlus::LuaState* state)
{
	CEventSystem::GetMe()->PushEvent(GE_TOGLE_PET_PAGE);
	//CEventSystem::GetMe()->PushEvent(GE_PROGRESSBAR_SHOW, "");
	//CEventSystem::GetMe()->PushEvent(GE_PROGRESSBAR_WIDTH,10);
	return 0;
}
//要求打开/关闭自动打怪界面
INT Lua_ToAUTOHit(LuaPlus::LuaState* state)
{
	//fujia
	std::vector< STRING > strParamInfo;

	strParamInfo.push_back("确定要开启自动打怪吗?");
	strParamInfo.push_back("4");

	((CEventSystem*)CGameProcedure::s_pEventSystem)->PushEvent( GE_GAMELOGIN_SYSTEM_INFO_YESNO, strParamInfo);
	return 0;
}
//要求打开生活技能界面
INT Lua_OpenLifePage(LuaPlus::LuaState* state)
{
	CEventSystem::GetMe()->PushEvent(GE_TOGLE_LIFE_PAGE);
//	CEventSystem::GetMe()->PushEvent(GE_UPDATE_TARGETPET_PAGE,0);

	//CEventSystem::GetMe()->PushEvent(GE_PROGRESSBAR_WIDTH,10);
	return 0;
}

//要求打开普通技能界面
INT Lua_OpenCommonSkillPage(LuaPlus::LuaState* state)
{
	CEventSystem::GetMe()->PushEvent(GE_TOGLE_COMMONSKILL_PAGE);
	//CEventSystem::GetMe()->PushEvent(GE_PROGRESSBAR_WIDTH,10);
	return 0;
}
INT Lua_UpdateMinimap( LuaPlus::LuaState* state )
{
	CGameProcedure::m_bNeedFreshMinimap = true;
	return 0;
}
INT Lua_OpenMinimap( LuaPlus::LuaState* state )
{
	LuaStack args(state);
	if( !args[ 1 ].IsString() ) return 0;
	if( strcmp( args[ 1 ].GetString(), "Minimap" ) == 0 ) // 打开小地图
	{
		CEventSystem::GetMe()->PushEvent( GE_OPEN_MINIMAP, "1" );
		
	}
	else if( strcmp( args[ 1 ].GetString(), "MinimapExp" ) == 0) // 打开扩展小地图
	{
		CEventSystem::GetMe()->PushEvent( GE_OPEN_MINIMAPEXP, "1" ); 
	}
	CGameProcedure::m_bNeedFreshMinimap = true;
	CGameProcedure::m_bWaitNeedFreshMinimap = true;
	return 0;
}
// 关闭打开大地图
INT Lua_ToggleLargeMap( LuaPlus::LuaState* state )
{
	LuaStack args(state);
	if( !args[ 1 ].IsString() ) 
		CEventSystem::GetMe()->PushEvent( GE_TOGLE_LARGEMAP, "2" );
		return 0;
	CEventSystem::GetMe()->PushEvent( GE_TOGLE_LARGEMAP, args[ 1 ].GetString() );
	CGameProcedure::m_bNeedFreshMinimap = true;
	CGameProcedure::m_bWaitNeedFreshMinimap = true;
	return 0;
}
// 关闭打开场景地图
INT Lua_ToggleSceneMap( LuaPlus::LuaState* state )
{
	LuaStack args(state);
	std::vector< STRING > vParam;
	vParam.push_back( CWorldManager::GetMe()->GetActiveScene()->GetSceneDefine()->szSceneMap );
	if( !args[ 1 ].IsString() ) 
		vParam.push_back( "2" );
	else
		vParam.push_back( args[ 1 ].GetString() );
	
	CEventSystem::GetMe()->PushEvent(GE_TOGLE_SCENEMAP, vParam );
	CGameProcedure::m_bNeedFreshMinimap = true;
	CGameProcedure::m_bWaitNeedFreshMinimap = true;
	return 0;
}


//打开包裹
INT Lua_ToggleContainer(LuaPlus::LuaState* state)  //fujia 2007.10.24
{
	CEventSystem::GetMe()->PushEvent(GE_TOGLE_CONTAINER);
	return 0;
}
INT Lua_ToggleContainer1(LuaPlus::LuaState* state)
{
	CEventSystem::GetMe()->PushEvent(GE_TOGLE_CONTAINER1);
	return 0;
}
INT Lua_ToggleContainer2(LuaPlus::LuaState* state)
{
	CEventSystem::GetMe()->PushEvent(GE_TOGLE_CONTAINER2);
	return 0;
}
//打开任务
INT Lua_ToggleMission(LuaPlus::LuaState* state)
{
	CEventSystem::GetMe()->PushEvent(GE_TOGLE_MISSION);
	return 0;
}
INT Lua_PushDebugMessage(LuaPlus::LuaState* state)
{
	LuaStack args(state);

	if (!(args[1].IsString()))
	{
		TDThrow("LUA: Lua_PushDebugMessage Wrong Param");
	}
	STRING Msg = args[1].GetString();

	CEventSystem::GetMe()->PushEvent(GE_NEW_DEBUGMESSAGE,args[1].GetString());

	return 0;
}

INT Lua_Get_XParam_INT(LuaPlus::LuaState* state)
{
	LuaStack args(state);

	if (!(args[1].IsInteger()))
	{
		TDThrow("LUA: Lua_Get_XParam_INT Wrong Param");
	}
	INT ret = (INT)CDataPool::GetMe()->X_PARAM_Get()->GetIntValue(args[1].GetInteger());

	state->PushInteger(ret);

	return 1;
}

INT Lua_Get_XParam_STR(LuaPlus::LuaState* state)
{
	LuaStack args(state);

	if (!(args[1].IsInteger()))
	{
		TDThrow("LUA: Lua_Get_XParam_STR Wrong Param");
	}
	char* ret = CDataPool::GetMe()->X_PARAM_Get()->GetStrValue(args[1].GetInteger());
	if(!ret) return 0;

	state->PushString(ret);

	return 1;
}

INT Lua_Get_XParam_INT_Count(LuaPlus::LuaState* state)
{
	state->PushInteger(CDataPool::GetMe()->X_PARAM_Get()->GetIntCount());
	return 1;
}

INT Lua_Get_XParam_STR_Count(LuaPlus::LuaState* state)
{
	state->PushInteger(CDataPool::GetMe()->X_PARAM_Get()->GetStrCount());
	return 1;
}

INT Lua_Set_XSCRIPT_Function_Name(LuaPlus::LuaState* state)
{
	LuaStack args(state);

	if (!(args[1].IsString()))
	{
		TDThrow("LUA: Lua_Set_XSCRIPT_Function_Name Wrong Param");
	}

	char* str_temp = (char*)args[1].GetString();

	if(!str_temp) return 0;
	CDataPool::GetMe()->X_XCRIPT_Get()->SetFunName(str_temp);

	return 0;
}

INT Lua_Set_XSCRIPT_Parameter(LuaPlus::LuaState* state)
{
	LuaStack args(state);

	if (!(args[1].IsInteger() && args[2].IsInteger()))
	{
		TDThrow("LUA: Lua_Set_XSCRIPT_Parameter Wrong Param");
	}
    const int index=args[1].GetInteger();
    if(CysModernGame::IsActive()) {
        if(index<0 || index>=(int)cysScriptParams.size()) TDThrow("XSCRIPT parameter index out of range");
        cysScriptParams[index]=args[2].GetInteger();
    }
    if(index>=0 && index<MAX_INT_PARAM_COUNT)
        CDataPool::GetMe()->X_XCRIPT_Get()->SetParam((BYTE)index,args[2].GetInteger());

	return 0;
}

INT Lua_Set_XSCRIPT_ScriptID(LuaPlus::LuaState* state)
{
	LuaStack args(state);

	if (!(args[1].IsInteger()))
	{
		TDThrow("LUA: Lua_Set_XSCRIPT_ScriptID Wrong Param");
	}
	CDataPool::GetMe()->X_XCRIPT_Get()->SetScriptID(args[1].GetInteger());

	return 0;
}

INT Lua_Set_XSCRIPT_ParamCount(LuaPlus::LuaState* state)
{
	LuaStack args(state);

	if (!(args[1].IsInteger()))
	{
		TDThrow("LUA: Lua_Set_XSCRIPT_ParamCount Wrong Param");
	}
    const int count=args[1].GetInteger();
    if(CysModernGame::IsActive()) {
        if(count<0 || count>(int)cysScriptParams.size()) TDThrow("XSCRIPT parameter count out of range");
        cysScriptParamCount=(unsigned)count;
        CDataPool::GetMe()->X_XCRIPT_Get()->SetParamCount((BYTE)(std::min)(count,MAX_INT_PARAM_COUNT));
    } else CDataPool::GetMe()->X_XCRIPT_Get()->SetParamCount(count);

	return 0;
}

INT Lua_Clear_XSCRIPT(LuaPlus::LuaState* state)
{
	LuaStack args(state);

	CDataPool::GetMe()->X_XCRIPT_Get()->CleanUp();
    cysScriptParams.fill(0);cysScriptParamCount=0;

	return 0;
}

INT Lua_Send_XSCRIPT(LuaPlus::LuaState* state)
{
	LuaStack args(state);
	CGExecuteScript msg;

	X_SCRIPT* pXScript_DataPool = CDataPool::GetMe()->X_XCRIPT_Get();
    if(CysModernGame::IsActive()) {
        const int length=pXScript_DataPool->GetFunNameSize();
        if(length<=0 || length>MAX_FUNC_NAME_SIZE) TDThrow("XSCRIPT function name out of range");
        std::unique_ptr<pg::CGExecuteScript> modern(new pg::CGExecuteScript);
        modern->m_ScriptID=(uint32_t)pXScript_DataPool->GetScriptID();
        modern->set_m_szFunName(std::string(pXScript_DataPool->GetFunName(),length));
        modern->m_uParamCount=(uint8_t)cysScriptParamCount;
        modern->m_aParam.assign(cysScriptParams.begin(),cysScriptParams.begin()+cysScriptParamCount);
        if(getenv("CYS_RUNTIME_POLISH_LIVE")) TDU_Log("CYS-XSCRIPT: id=%u function=%s count=%u",modern->m_ScriptID,modern->m_szFunName.c_str(),cysScriptParamCount);
        CysModernGame::SendModern(std::move(modern));
        return 0;
    }
	X_SCRIPT* pXScript_Send = msg.GetScript();

	memcpy(pXScript_Send,pXScript_DataPool,sizeof(X_SCRIPT));
	
	CNetManager::GetMe()->SendPacket( &msg );
	
	return 0;
}

/*
//导出数据池内从服务器发送来的老师的门派信息
INT Lua_GetMenpaiInfo(LuaPlus::LuaState* state)
{
	INT idMenpai = (INT)CDataPool::GetMe()->JoinMenpai_GetMenpaiInfo();
	state->PushNumber( idMenpai );

	//有可能将要扩展导出的内容
	return 1;
}
//加入门派
INT Lua_MenpaiFrameJoin(LuaPlus::LuaState* state)
{
	INT idMenpai = (INT)CDataPool::GetMe()->JoinMenpai_GetMenpaiInfo();

	CDataPool::GetMe()->SendJoinMenpaiEvent();
	return 0;
}
*/

//导出心法等级
//INT Lua_GetXinfaLevel(LuaPlus::LuaState* state)
//{
//	LuaStack args(state);
//
//	if (!(args[1].IsInteger()))
//	{
//		TDThrow("LUA: Lua_GetXinfaLevel Wrong Param");
//	}
//	INT nXinfaID = args[1].GetInteger();
//
//	const SCLIENT_XINFA* pXinFa = CObjectManager::GetMe()->GetMySelf()->GetCharacterData()->Get_XinFa(nXinfaID);
//	if(!pXinFa) 
//	{
//		state->PushInteger(-1);
//	}
//	else
//	{
//		state->PushInteger(pXinFa->m_nLevel);
//	}
//
//	return 1;
//}

//fujia 
//通过技能类表得到不同等级技能ID
INT GetStudySkillLevelId(int SkillId,int skillLevel )
{
	//加载技能类表
	DBC_DEFINEHANDLE(pSpendDBC, DBC_SKILL_DATA);

	INT nNum = (INT)pSpendDBC->GetRecordsNum();
	for(INT i=0; i<nNum; i++)
	{
		const _DBC_SKILL_DATA* pSpend = (const _DBC_SKILL_DATA*)pSpendDBC->Search_LineNum_EQU(i);
		if(pSpend->m_nID != SkillId) 
			continue;
		INT nSkilllevel	= CYS_SKILL_BY_LEVEL(pSpend, skillLevel-1);	// CYS-CY: 31 levels, bounds-checked

		//const _DBC_XINFA_STUDYSPEND* pSpend = (const _DBC_XINFA_STUDYSPEND*)pSpendDBC->Search_LineNum_EQU(i);
		//if(pSpend->nStudyLevel != nXinfaLevel) 
		//	continue;
		return nSkilllevel;
	}
	return -1;
}

//得到技能图标
INT Lua_GetSkillImage(LuaPlus::LuaState* state)
{
	LuaStack args(state);
	if (!(args[1].IsInteger()))
	{
		TDThrow("LUA: Lua_GetSkillImage Wrong Param");
	}
	INT SkillId = args[1].GetInteger();
	//加载技能类表
	DBC_DEFINEHANDLE(pSpendDBC, DBC_SKILL_DATA);

	INT nNum = (INT)pSpendDBC->GetRecordsNum();
	for(INT i=0; i<nNum; i++)
	{
		const _DBC_SKILL_DATA* pSpend = (const _DBC_SKILL_DATA*)pSpendDBC->Search_LineNum_EQU(i);
		if(pSpend->m_nID != SkillId) 
			continue;

		LPCSTR nSkillImage	=  pSpend->m_lpszIconName;
		state->PushString((char *)nSkillImage);
		break;
	}
	return 1;
}
//得到学习技能的金钱要求
INT Lua_GetStudySkillMoney(LuaPlus::LuaState* state)
{
	LuaStack args(state);
	if (!(args[1].IsInteger()))
	{
		TDThrow("LUA: Lua_GetUplevelSkillSpendMoney Wrong Param");
	}

	if (!(args[2].IsInteger()))
	{
		TDThrow("LUA: Lua_GetUplevelSkillSpendMoney Wrong Param");
	}
	INT skillId = args[1].GetInteger();
	INT skillLvl = args[2].GetInteger();

	INT nSkilllevel = GetStudySkillLevelId(skillId,skillLvl);
	
	//加载等级消耗表
	DBC_DEFINEHANDLE(pSpendDBC, DBC_SKILLDATA_V1_DEPLETE);

	INT mNum = (INT)pSpendDBC->GetRecordsNum();
	for(INT i=0; i<mNum; i++)
	{
		const _DBC_SKILLDATA_V1_DEPLETE* pSpend = (const _DBC_SKILLDATA_V1_DEPLETE*)pSpendDBC->Search_LineNum_EQU(i);
		if(pSpend->nId != nSkilllevel) 
			continue;
		INT nNeedMoney	= 0;	// CYS: client_GL SkillData_V1 has no need-money column

		//const _DBC_XINFA_STUDYSPEND* pSpend = (const _DBC_XINFA_STUDYSPEND*)pSpendDBC->Search_LineNum_EQU(i);
		//if(pSpend->nStudyLevel != nXinfaLevel) 
		//	continue;
		state->PushNumber( nNeedMoney );

		// 同时输出转换为金币、银币、铜币的格式输出
		INT nMoney = nNeedMoney;
		INT nGoldCoin;	
		INT nSilverCoin;
		INT nCopperCoin;

		nCopperCoin = nMoney % 100;

		if( nMoney >= 100 )
		{
			nSilverCoin = ((nMoney-nCopperCoin)/100) % 100;
		}
		else
		{
			nSilverCoin = 0;
		}
		if ( nMoney >= 10000 )
		{
			nGoldCoin = (((nMoney-nCopperCoin)/100)-nSilverCoin)/100;
		}
		else
			nGoldCoin = 0;

		state->PushInteger(nGoldCoin);
		state->PushInteger(nSilverCoin);
		state->PushInteger(nCopperCoin);

		break;
	}
	return 4;
}
//得到学习技能的等级要求
INT Lua_GetStudySkillName(LuaPlus::LuaState* state)
{
	LuaStack args(state);
	if (!(args[1].IsInteger()))
	{
		TDThrow("LUA: Lua_GetUplevelSkillNeedLevel Wrong Param");
	}

	if (!(args[2].IsInteger()))
	{
		TDThrow("LUA: Lua_GetUplevelSkillNeedLevel Wrong Param");
	}
	INT skillId = args[1].GetInteger();
	INT skillLvl = args[2].GetInteger();

	INT nSkilllevel = GetStudySkillLevelId(skillId,skillLvl);

	//加载等级消耗表
	DBC_DEFINEHANDLE(pSpendDBC, DBC_SKILLDATA_V1_DEPLETE);

	INT mNum = (INT)pSpendDBC->GetRecordsNum();
	for(INT i=0; i<mNum; i++)
	{
		const _DBC_SKILLDATA_V1_DEPLETE* pSpend1 = (const _DBC_SKILLDATA_V1_DEPLETE*)pSpendDBC->Search_LineNum_EQU(i);
		if(pSpend1->nId != nSkilllevel) 
			continue;
		LPCSTR nSkillName	= pSpend1->szEffectDesc;
		state->PushString((char *)nSkillName);
		break;
	}
	return 1;
}

//得到学习技能描述
INT Lua_GetStudySkillMS(LuaPlus::LuaState* state)
{
	LuaStack args(state);
	if (!(args[1].IsInteger()))
	{
		TDThrow("LUA: Lua_GetStudySkillMS Wrong Param");
	}

	if (!(args[2].IsInteger()))
	{
		TDThrow("LUA: Lua_GetStudySkillMS Wrong Param");
	}
	INT skillId = args[1].GetInteger();
	INT skillLvl = args[2].GetInteger();

	INT nSkilllevel = GetStudySkillLevelId(skillId,skillLvl);

	//加载等级消耗表
	DBC_DEFINEHANDLE(pSpendDBC, DBC_SKILLDATA_V1_DEPLETE);

	INT mNum = (INT)pSpendDBC->GetRecordsNum();
	for(INT i=0; i<mNum; i++)
	{
		const _DBC_SKILLDATA_V1_DEPLETE* pSpend1 = (const _DBC_SKILLDATA_V1_DEPLETE*)pSpendDBC->Search_LineNum_EQU(i);
		if(pSpend1->nId != nSkilllevel) 
			continue;
		LPCSTR nSkillMS	= pSpend1->Skill_Desc_Interface;
		state->PushString((char *)nSkillMS);
		break;
	}
	return 1;
}
//得到学习技能的等级要求
INT Lua_GetStudySkillLevel(LuaPlus::LuaState* state)
{
	LuaStack args(state);
	if (!(args[1].IsInteger()))
	{
		TDThrow("LUA: Lua_GetUplevelSkillNeedLevel Wrong Param");
	}

	if (!(args[2].IsInteger()))
	{
		TDThrow("LUA: Lua_GetUplevelSkillNeedLevel Wrong Param");
	}
	INT skillId = args[1].GetInteger();
	INT skillLvl = args[2].GetInteger();

	INT nSkilllevel = GetStudySkillLevelId(skillId,skillLvl);
	
	//加载等级消耗表
	DBC_DEFINEHANDLE(pSpendDBC, DBC_SKILLDATA_V1_DEPLETE);

	INT mNum = (INT)pSpendDBC->GetRecordsNum();
	for(INT i=0; i<mNum; i++)
	{
		const _DBC_SKILLDATA_V1_DEPLETE* pSpend1 = (const _DBC_SKILLDATA_V1_DEPLETE*)pSpendDBC->Search_LineNum_EQU(i);
		if(pSpend1->nId != nSkilllevel) 
			continue;
		INT nNeedLevel	= 0;	// CYS: client_GL SkillData_V1 has no need-level column
		state->PushInteger(nNeedLevel);
		break;
	}
	return 1;
}

// CYS-CY 16/09 (menpai-verify): chi phí nâng một cấp tâm pháp, đọc thẳng bảng CY XinFaStudySpend_V1 (DBC 907,
// 244 cột × 302 dòng). nWhat: 0 = tiền, 1 = kinh nghiệm. Trả 0 khi bảng trống, khi id tâm pháp ngoài 0..120 hoặc
// khi không có dòng cho cấp đó (cấp > 300), thay vì đọc ngoài mảng như bản 0.85 (StudySpend[54]).
static INT CysXinfaStudySpend(INT nXinfaId, INT nXinfaLevel, INT nWhat)
{
	if(nXinfaId < 0 || nXinfaId >= DBC_XINFA_STUDYSPEND_SLOTS)
		return 0;

	//加载心法升级消耗表
	DBC_DEFINEHANDLE(pSpendDBC, DBC_XINFA_STUDYSPEND);
	if(!pSpendDBC)
		return 0;

	const INT nNum = (INT)pSpendDBC->GetRecordsNum();
	for(INT i = 0; i < nNum; i++)
	{
		const _DBC_XINFA_STUDYSPEND* pSpend = (const _DBC_XINFA_STUDYSPEND*)pSpendDBC->Search_LineNum_EQU(i);
		if(!pSpend || pSpend->nStudyLevel != nXinfaLevel)
			continue;
		return nWhat == 0 ? pSpend->StudySpend[nXinfaId].dwSpendMoney
		                  : pSpend->StudySpend[nXinfaId].dwSpendExperience;
	}
	return 0;
}

//导出心法升级需要的金钱,传入的参数为要学习的心法等级
INT Lua_GetUplevelXinfaSpendMoney(LuaPlus::LuaState* state)
{
	LuaStack args(state);
	if (!(args[1].IsInteger()))
	{
		TDThrow("LUA: Lua_GetUplevelXinfaSpendMoney Wrong Param");
	}

	if (!(args[2].IsInteger()))
	{
		TDThrow("LUA: Lua_GetUplevelXinfaSpendMoney Wrong Param");
	}

	INT nXinfaId = args[1].GetInteger();
	INT nXinfaLevel = args[2].GetInteger();

	// CYS-CY 16/09 (menpai-verify): 行 888 của bảng CY nói ô thứ k là tâm pháp id k (0..120), nên StudySpend[id]
	// đúng cho id 1..120 (ActionSkill.lua:306, ActionSkillsStudy.lua:279 truyền id của XinFa_V1). Luôn đẩy đủ 4 giá
	// trị: trước đây khi không tìm thấy dòng cấp, hàm trả 4 mà không đẩy gì và Lua nhận nil rồi lỗi nối chuỗi.
	INT nNeedMoney = CysXinfaStudySpend(nXinfaId, nXinfaLevel, 0);
	state->PushNumber( nNeedMoney );

	// 同时输出转换为金币、银币、铜币的格式输出
	INT nMoney = nNeedMoney;
	INT nGoldCoin;
	INT nSilverCoin;
	INT nCopperCoin;

	nCopperCoin = nMoney % 100;

	if( nMoney >= 100 )
	{
		nSilverCoin = ((nMoney-nCopperCoin)/100) % 100;
	}
	else
	{
		nSilverCoin = 0;
	}

	if ( nMoney >= 10000 )
	{
		nGoldCoin = (((nMoney-nCopperCoin)/100)-nSilverCoin)/100;
	}
	else
		nGoldCoin = 0;

	state->PushInteger(nGoldCoin);
	state->PushInteger(nSilverCoin);
	state->PushInteger(nCopperCoin);

	return 4;
}
//导出心法升级需要的经验值,传入的参数为要学习的心法等级
INT Lua_GetUplevelXinfaSpendExp(LuaPlus::LuaState* state)
{
	LuaStack args(state);

	if (!(args[1].IsInteger()))
	{
		TDThrow("LUA: Lua_GetUplevelXinfaSpendExp Wrong Param");
	}
	if (!(args[2].IsInteger()))
	{
		TDThrow("LUA: Lua_GetUplevelXinfaSpendExp Wrong Param");
	}
	INT nXinfaId = args[1].GetInteger();
	INT nXinfaLevel = args[2].GetInteger();

	state->PushNumber( CysXinfaStudySpend(nXinfaId, nXinfaLevel, 1) );
	return 1;
}

//学习技能界面
INT lua_SkillsStudyFrame_study(LuaPlus::LuaState* state)
{
	LuaStack args(state);

	if (!(args[1].IsInteger()))
	{
		TDThrow("LUA: lua_SkillsStudyFrame_study Wrong Param");
	}
	if (!(args[2].IsInteger()))
	{
		TDThrow("LUA: lua_SkillsStudyFrame_study Wrong Param");
	}
	if (!(args[3].IsInteger()))
	{
		TDThrow("LUA: lua_SkillsStudyFrame_study Wrong Param");
	}
	CDataPool::GetMe()->SendStudySkillEvent(args[1].GetInteger(),args[2].GetInteger(),args[3].GetInteger());

	return 0;
}

INT	Lua_GetActionNum(LuaPlus::LuaState* state)
{
	LuaStack args(state);

	if (!(args[1].IsString()))
	{
		TDThrow("LUA: GetActionNum Wrong Param");
	}

	state->PushNumber( CActionSystem::GetMe()->GetActionNum(args[1].GetString()));

	return 1;
}

INT Lua_IsWindowShow(LuaPlus::LuaState* state)
{
	LuaStack args(state);

	if (!(args[1].IsString()))
	{
		TDThrow("LUA: Lua_IsWindowShow Wrong Param");
	}
	BOOL ret = CGameProcedure::s_pUISystem && CGameProcedure::s_pUISystem->IsWindowShow(args[1].GetString());
	state->PushBoolean( ret != FALSE );

	return 1;
}
//得到操作对象
INT	Lua_EnumAction(LuaPlus::LuaState* state)
{
	LuaStack args(state);

	if (!(args[1].IsInteger()))
	{
		TDThrow("LUA: EnumAction Wrong Param1");
	}
	if (!(args[2].IsString()))
	{
		TDThrow("LUA: EnumAction Wrong Param2");
	}

	INT nIndex = args[1].GetInteger();
	const char* szFilter = args[2].GetString();

	tActionItem* pActionItem = CActionSystem::GetMe()->EnumAction(nIndex, szFilter);

	if(pActionItem) 
	{
		LuaObject objReturn = state->BoxPointer(pActionItem);
		objReturn.SetMetaTable(*CActionItem::s_pMetaTable);
		objReturn.PushStack();
	}
	else
	{
		LuaObject objReturn = state->BoxPointer(&(CActionItem::s_InvalidAction));
		objReturn.SetMetaTable(*CActionItem::s_pMetaTable);
		objReturn.PushStack();
	}

	return 1;
}

INT	Lua_ShowContexMenu(LuaPlus::LuaState* state)
{
	LuaStack args(state);

	if (!(args[1].IsString()))
	{
		TDThrow("LUA:ShowContexMenu Wrong Param");
	}

	LPCTSTR szMenuName = args[1].GetString();

	POINT ptMouse = CInputSystem::GetMe()->MouseGetPos();

	std::vector< STRING > vParam;

	//arg0 - MenuNema
	vParam.push_back(szMenuName);

	vParam.push_back("-1");

	//arg2, arg3 MouseX, MouseY
	CHAR szTemp[32];

	_snprintf(szTemp, 32, "%d", ptMouse.x);
	vParam.push_back(szTemp);

	_snprintf(szTemp, 32, "%d", ptMouse.y);
	vParam.push_back(szTemp);

	CEventSystem::GetMe()->PushEvent(GE_SHOW_CONTEXMENU, vParam);

	return 0;
}

INT Lua_QuestFrameOptionClicked(LuaPlus::LuaState* state)
{
	LuaStack args(state);

	if (!(args[1].IsNumber()))
	{
		TDThrow("LUA:QuestFrameOptionClicked Wrong Param1");
	}

	if (!(args[2].IsNumber()))
	{
		TDThrow("LUA:QuestFrameOptionClicked Wrong Param2");
	}

	if (!(args[3].IsNumber()))
	{
		TDThrow("LUA:QuestFrameOptionClicked Wrong Param3");
	}

	INT nIndex = (INT)args[1].GetNumber();
	INT nExIndex1 = (INT)args[2].GetNumber();
	INT nExIndex2 = (INT)args[3].GetNumber();

	CUIDataPool::GetMe()->SendSelectEvent(nIndex,nExIndex1,nExIndex2);

	//CGameProcedure::s_pGfxSystem->PushDebugString("CGEventRequest");
	return 0;
}

//接受任务
INT Lua_QuestFrameAcceptClicked(LuaPlus::LuaState* state)
{
	CUIDataPool::GetMe()->SendAcceptEvent();
	return 0;
}
//拒绝任务
INT Lua_QuestFrameRefuseClicked(LuaPlus::LuaState* state)
{
	CUIDataPool::GetMe()->SendRefuseEvent();
	return 0;
}
//继续任务
INT Lua_QuestFrameMissionContinue(LuaPlus::LuaState* state)
{
	CUIDataPool::GetMe()->SendContinueEvent();
	return 0;
}
//放弃任务
INT Lua_QuestFrameMissionAbnegate(LuaPlus::LuaState* state)
{
	LuaStack args(state);

	if ( !(args[1].IsInteger()) ) return 0;
	CUIDataPool::GetMe()->SendAbandonEvent(args[1].GetInteger());
	return 0;
}
//完成任务
INT Lua_QuestFrameMissionComplete(LuaPlus::LuaState* state)
{
	LuaStack args(state);

	if (!(args[1].IsNumber()))
	{
		TDThrow("LUA:QuestFrameMissionComplete Wrong Param");
	}

	INT nIndex = (INT)args[1].GetNumber();

	//为了对应服务器从1开始编号
	CUIDataPool::GetMe()->SendCompleteEvent( nIndex );
	return 0;
}


// 得到当前场景得尺寸
INT Lua_GetSceneSize( LuaPlus::LuaState* state)
{
	const _DBC_SCENE_DEFINE* pSceneDef = CWorldManager::GetMe()->GetActiveScene()->GetSceneDefine();
	state->PushNumber( pSceneDef->nXSize );
	state->PushNumber( pSceneDef->nZSize );
	return 2;
}
INT Lua_GetSceneID( LuaPlus::LuaState* state)
{
	state->PushInteger( CWorldManager::GetMe()->GetActiveSceneID() );
	return 1;
}

// ---------------------------------------------------------------------------------------------
// CYS-SCENEMAP: hai ham host cua ban do lon (Alt+M) va minimap. Truoc 20/09 ca hai la STUB sinh
// tu dong (LuaApiGen_Globals.cpp:225/233) nen tra ve "" va 0,0 => LargeMap.lua:283,
// MiniMap.lua:246/402/407 va SceneMap.lua:572-573/814 khong dung duoc o .dds nao, con d_SceneSize
// bi dat = 0 (UILuaControl.cpp:2615) nen no thanh MAU SO 0 trong FalagardSceneMap::UpdateAllWindow
// va ScenePosToWindowPos => cham vi tri nhan vat sai cho.
//
// BANG + COT (do tu ma may cua B, KHONG suy tu ten ham):
//   B = C:\TLBB\085\client\Bin64\Game.exe, sha256 0bf344935d6266ab80b6807d048fcd59184a925f18fd
//       292072ccc596d045c918, chuoi duong dan nhung trong binary = D:\TLBB\Temp_Release_v0-08-0101
//       (client_GL\Bin64\Game.exe co cung byte cho hai ham nay - catalog impl_bytes="same").
//   Dinh vi lai bang CHUOI, khong nhay thang toi dia chi chep tu tai lieu (luat 22.8):
//       "Lua_GetSceneMapByID Wrong nIndex:%d" o VA 0x140762a18 co DUNG MOT xref, tai 0x14021f93a,
//       nam trong [0x14021f8b0, +193) => dung la than ham GetSceneMapByID.
//   0x14021f8b0 GetSceneMapByID : lua_tonumber(L,1) -> DBC_DEFINEHANDLE(s_pSceneDBC) ->
//       Search_Index_EQU(id) -> if(!row) TDThrow(...) -> lua_pushstring(row[+0x40]).
//       row[+0x40] = offset 64 = _DBC_SCENE_DEFINE::szSceneMap = cot [10] (cot thu 11 dem tu 1).
//   0x14021f7e0 GetSceneSizeByID: cung tra cuu, roi push row[+0x10] va row[+0x14]
//       = nXSize (cot [2]) va nZSize (cot [3]).
//   Doi chung doc lap: Assets\CanonicalCY\Data\ConfigFolder\SceneDefineEx.txt (sha256
//       df9324a0cb9f1a33..., 803 dong x 25 cot, do 20/09) cot [10] cua canh Dai Ly = "dali_new_320"
//       va Vo Luong = "wuliangscene" - trung khit voi hai bo o jpg_dali_new_320_* /
//       jpg_wuliangscene_* ma `minimap-holes` dem duoc tren dia; cot [2]/[3] = 320/320.
//
// KHONG GIONG B mot cho, CO Y: B goi thang Search_Index_EQU roi nem neu truot. Do tren
// SceneInfo.ini cua server rieng: 514 canh active thi 455 tra duoc bang chinh scene id, con
// 55 canh CHI tra duoc qua client_res (vd scene 230/265/266/... -> clientres 536), va 4 canh
// (42, 316, 1298, 1301) khong co dong DBC nao. Vi Lua chi cam scene id (MiniMap.lua:245
// `sceneID = GetSceneID()` = ID phia SERVER, xem CWorldManager::GetActiveSceneID), tra cuu tran
// se lam 55 canh do van trang. Nen: truot thi dung dinh nghia cua canh DANG DUNG, vi
// CWorldManager::EnterScene da giai xong client_res cho no (WorldManager.cpp:112-127 CYS-SCENERES).
// Va thay vi nem, tra ve gia tri trung tinh + ghi log MOT lan moi ID, de 4 canh khong co dong DBC
// hong sach chu khong lam van client.
// ---------------------------------------------------------------------------------------------
static const _DBC_SCENE_DEFINE* _CysSceneDefineByID( INT nSceneID )
{
	DBC_DEFINEHANDLE(s_pSceneDBC, DBC_SCENE_DEFINE);
	const _DBC_SCENE_DEFINE* pSceneDef =
		(const _DBC_SCENE_DEFINE*)s_pSceneDBC->Search_Index_EQU( nSceneID );
	if( pSceneDef )
		return pSceneDef;

	// Canh pho ban / canh dung client_res: khong co dong nao o scene id cua server.
	CWorldManager* pWorld = CWorldManager::GetMe();
	if( pWorld && pWorld->GetActiveScene() && pWorld->GetActiveSceneID() == nSceneID )
		return pWorld->GetActiveScene()->GetSceneDefine();

	return NULL;
}

// Ghi log mot lan cho moi scene id khong tra duoc, de khong lam ngap log khi UI goi moi khung hinh.
static VOID _CysWarnSceneOnce( INT nSceneID, const CHAR* szWho )
{
	static std::set<INT> s_setWarned;
	if( s_setWarned.insert( nSceneID ).second )
		TDU_Log( "CYS-SCENEMAP: %s(%d) khong co dong SceneDefineEx (va khong phai canh dang dung)",
				 szWho, nSceneID );
}

// 得到指定场景的地图贴图名 (SceneDefineEx cot [10])
INT Lua_GetSceneMapByID( LuaPlus::LuaState* state)
{
	LuaStack args(state);
	// LargeMap.lua:283 truyen thang thuoc tinh "CurrentScene" - mot CHUOI - nen phai nhan ca chuoi
	// so. LuaStackObject::IsNumber() la phep thu NGHIEM NGAT (LuaStackObject.inl:117
	// lua_type == LUA_TNUMBER) nen se truot o do; nhung GetNumber() la lua_tonumber
	// (LuaStackObject.inl:162) nen tu doi chuoi so. Vi vay canh cong bang IsNumber||IsString.
	if( !args[1].IsNumber() && !args[1].IsString() )
	{
		state->PushString( "" );
		return 1;
	}
	const INT nSceneID = (INT)args[1].GetNumber();
	const _DBC_SCENE_DEFINE* pSceneDef = _CysSceneDefineByID( nSceneID );
	if( !pSceneDef || !pSceneDef->szSceneMap )
	{
		_CysWarnSceneOnce( nSceneID, "GetSceneMapByID" );
		state->PushString( "" );
		return 1;
	}
	// szSceneMap la KHOA TAI NGUYEN (ASCII thuan: do het 803 dong, 0 byte >127, dai nhat 27),
	// khong phai chu hien thi => KHONG doi bang ma o day.
	state->PushString( pSceneDef->szSceneMap );
	return 1;
}

// 得到指定场景的尺寸 (SceneDefineEx cot [2]/[3])
INT Lua_GetSceneSizeByID( LuaPlus::LuaState* state)
{
	LuaStack args(state);
	// Khi khong tra duoc: tra kich thuoc mac dinh cua widget (FalagardSceneMap.cpp:64
	// d_SceneSize = Size(128,128)) chu KHONG phai 0,0. d_SceneSize la MAU SO trong
	// UpdateAllWindow (:395-405) va ScenePosToWindowPos (:673-674, 713-714); 0 lam hong ca khung
	// chu khong chi ve thieu anh.
	INT nXSize = 128, nZSize = 128;
	if( args[1].IsNumber() || args[1].IsString() )
	{
		const INT nSceneID = (INT)args[1].GetNumber();
		const _DBC_SCENE_DEFINE* pSceneDef = _CysSceneDefineByID( nSceneID );
		if( pSceneDef )
		{
			nXSize = pSceneDef->nXSize;
			nZSize = pSceneDef->nZSize;
		}
		else
		{
			_CysWarnSceneOnce( nSceneID, "GetSceneSizeByID" );
		}
	}
	state->PushNumber( nXSize );
	state->PushNumber( nZSize );
	return 2;
}

// 得到当前小地图得尺寸
INT Lua_GetMinimapSize( LuaPlus::LuaState* state)
{

	state->PushNumber( 256 );
	state->PushNumber( 256 );
	return 2;
}
INT Lua_ResetCamera( LuaPlus::LuaState* state )
{
	//FLOAT fSub = max( FLOAT( nMousePosXDiff /10.0f ), 1.0f) / 100;
	float fCurrentDirect = float( CGameProcedure::s_pGfxSystem->Camera_GetDirection() );
	if( fCurrentDirect < 0 )
	{
		float ftmp = float( int( fCurrentDirect / PI_2 ) );
		ftmp *= PI_2;
		fCurrentDirect = fCurrentDirect - ftmp + PI_2;
	}
	else 
	{
		fCurrentDirect = fCurrentDirect - float( int( fCurrentDirect / PI_2 ) * PI_2 );
	}
	CGameProcedure::s_pGfxSystem->Camera_Direction( fCurrentDirect );
	if( fCurrentDirect < __PI  )
		CGamePro_Main::m_nResetCamera = 1;
	else 
		CGamePro_Main::m_nResetCamera = -1;
	return 0;
}

//要求打开/关闭技能书
INT Lua_ToggleComposeWnd(LuaPlus::LuaState* state)
{
	CEventSystem::GetMe()->PushEvent(GE_TOGLE_COMPOSE_WINDOW);
	return 0;
}
//得到某一种配方的数量
INT Lua_GetMethodNumber( LuaPlus::LuaState* state)
{
	LuaStack args(state);
	// 第一个值为配方类型，第二个为配方序列号
	if (!(args[1].IsInteger()))
	{
		TDThrow("LUA: EnumAction Wrong Param");
	}

	INT nType = args[1].GetInteger();		//  配方类型

	return 0;
}
//枚举配方数据
INT	Lua_EnumMethod(LuaPlus::LuaState* state)
{
	LuaStack args(state);
	// 第一个值为配方类型，第二个为配方序列号
	if (!(args[1].IsInteger()))
	{
		//INT t1 = args[1].GetType();
		//INT t2 = args[1].GetType();
		TDThrow("LUA: EnumAction Wrong Param");
	}

	INT nType = args[1].GetInteger();		//  配方类型
	INT nIndex = args[ 2 ].GetInteger();	//  配方序列好
	return 3;
}

//发送聊天信息 
/*
1. 频道
2. 聊天类型，比如是私了还是喊叫
3. 队伍的id,如果有队伍的话
4. 聊天的内容
5. 聊天的对象，把话发给谁。
*/
INT Lua_SendChatMessage( LuaPlus::LuaState* state)
{
	LuaStack args(state);
	if( !args[ 1 ].IsString() ) return 0; // 消息字符串 
	if( !args[ 2 ].IsString() ) return 0; // 目标名字字符串
	if( !args[ 3 ].IsInteger() ) return 0; //频道id
	if( !args[ 4 ].IsInteger() ) return 0; // 消息类型
	if( !args[ 5 ].IsInteger() ) return 0;	// 团队id

	CGameProcedure::s_pGameInterface->SendChatCommand( args[ 3 ].GetInteger(),
		args[ 4 ].GetInteger(),
		args[ 5 ].GetInteger(),
		args[ 1 ].GetString(),
		args[ 2 ].GetString() );
	return 0;
}

INT Lua_SendGMCommand(LuaPlus::LuaState* state)
{
	LuaStack args(state);
	if( !args[ 1 ].IsString() ) return 0; // 消息字符串 

	CGameProcedure::s_pGameInterface->GM_SendCommand(args[1].GetString());
	return 0;
}

INT Lua_SendAUTOMove(LuaPlus::LuaState* state)
{
	LuaStack args(state);
	if( !args[ 1 ].IsInteger() ) return 0; // x坐标
	if( !args[ 2 ].IsInteger() ) return 0; // Z坐标 
	CGameProcedure::s_pGameInterface->Player_MoveTo(fVector2((FLOAT)args[1].GetInteger(),(FLOAT)args[2].GetInteger()));
	return 0;
}

INT Lua_GetCurChatProperty( LuaPlus::LuaState* state )
{
	state->PushInteger( 0 );
	state->PushInteger( 0 );
	state->PushInteger( 0 );
	state->PushString( "" );
	return 4;
}

INT Lua_AxTrace(LuaPlus::LuaState* state)
{
	LuaStack args(state);
	
	if(!(args[1].IsInteger()) || !(args[2].IsInteger()) || !(args[3].IsString()))
		return 0;

	AxTrace(args[1].GetInteger(), args[2].GetInteger(), "%s", args[3].GetString());

	return 0;
}

INT Lua_ComposeItem_Begin(LuaPlus::LuaState* state)
{
	LuaStack args(state);
	if (! (args[1].IsInteger()) || !(args[2].IsInteger()) )
	{
		TDThrow("LUA: ComposeItem Wrong Param");

	}
	if( CObjectManager::GetMe()->GetMySelf()->CharacterLogic_Get() == CObject_Character::CHARACTER_LOGIC_ABILITY_ACTION )
		return 0;
	INT Make_Count = args[2].GetInteger();

	if(Make_Count < 1)
		return 0;

//	INT	nAbility		= args[1].GetInteger();
	INT	nPrescription	= args[1].GetInteger();
//	ObjID_t	n_guidPlatform	= args[3].GetInteger();
//	AxTrace(nAbility, nPrescription, "%s", n_guidPlatform);
	CGameProcedure::s_pGameInterface->Player_UseLifeAbility( nPrescription, Make_Count);

	return 0;
}

INT Lua_ComposeItem_Cancel(LuaPlus::LuaState* state)
{
	LuaStack args(state);
	//if (! (args[1].IsInteger()) )
	//{
	//	TDThrow("LUA: ComposeItem_Cancel Wrong Param");
	//}
//	INT	nAbility		= args[1].GetInteger();
//	INT	nPrescription	= args[1].GetInteger();
//	ObjID_t	n_guidPlatform	= args[3].GetInteger();
//	AxTrace(nAbility, nPrescription, "%s", n_guidPlatform);

	//anyway，hide prograssbar first. 
	CEventSystem::GetMe()->PushEvent(GE_PROGRESSBAR_HIDE);
	CObject_PlayerMySelf *pMySelf = CObjectManager::GetMe()->GetMySelf();
	// 不充许这么操作
	//SCommand_Object pCmd;
	//pCmd.m_wID = OC_IDLE;
	//pCmd.m_abParam[2] = TRUE;
	////when the cancel button is clicked, the logic of client enter idle first.
	////then send the idle command to server.
	////it is not the best measure,but i can't get the better way.
	//pMySelf->DoCommand(&pCmd);
	//向服务器发送发呆消息
	CGCharIdle msg;
	CNetManager::GetMe()->SendPacket( &msg );

	return 0;
}


INT Lua_OpenBooth( LuaPlus::LuaState* state) 
{
	//测试使用
	return 0;
}



INT Lua_CloseBooth( LuaPlus::LuaState* state)
{
	CGameProcedure::s_pGameInterface->Booth_Close();
	return 0;
}

INT Lua_RepairAll( LuaPlus::LuaState* state)
{
	//检查是否有需要修理的物品
	BOOL bNeed = FALSE;
	for(INT i = 0; i<HEQUIP_NUMBER; i++)
	{
		CObject_Item_Equip* pItem = (CObject_Item_Equip*)(CDataPool::GetMe()->UserEquip_GetItem((HUMAN_EQUIP)i));
		if(!pItem)
			continue;
		if(pItem->GetItemDur() < pItem->GetItemMaxDur())
		{
			bNeed = TRUE;
			break;
		}
	}

	//需要修理的时候再通知服务器端修改
	if(bNeed)
	{
		CGameProcedure::s_pGameInterface->Booth_Repair(true,0);
	}
	else
	{
		BOOL bLog = (CGameProcedure::s_pUISystem != NULL)?TRUE:FALSE;
		if(bLog)	
		{
			ADDNEWDEBUGMSG(STRING("没有物品需要修理"));
		}
	}

	return 0;
}

INT Lua_RepairOne( LuaPlus::LuaState* state)
{
	//设置鼠标为修理状态
	CGameProcedure::s_pGameInterface->Booth_EnterRepair();
	return 0;
}

//打开关闭称号界面
INT Lua_OpenSelfEquip( LuaPlus::LuaState* state) 
{
	LuaStack args(state);
	if( !args[ 1 ].IsInteger() ) 
	{
		return 0;
	}

	CEventSystem::GetMe()->PushEvent(GE_OPEN_EQUIP, args[1].GetInteger());

	return 0;
}
//关闭称号界面
INT Lua_CloseTitleList( LuaPlus::LuaState* state) 
{
	CEventSystem::GetMe()->PushEvent(GE_CLOSE_AGNAME);

	return 0;
}


//打开称号界面
INT Lua_OpenTitleList( LuaPlus::LuaState* state) 
{
	CEventSystem::GetMe()->PushEvent(GE_OPEN_AGNAME);

	return 0;
}


INT Lua_GetCurrentSceneName( LuaPlus::LuaState* state )
{
	const _DBC_SCENE_DEFINE* pSceneDef = CWorldManager::GetMe()->GetActiveScene()->GetSceneDefine();
	state->PushString( pSceneDef->szName );
	return 1;
}

INT Lua_GetCurrentSceneNameById( LuaPlus::LuaState* state )
{
	LuaStack args(state);
	int nIndex=args[1].GetInteger();

	DBC_DEFINEHANDLE(s_pSceneNameDBC, DBC_SCENE_DEFINE);
	const _DBC_SCENE_DEFINE* pSceneDef = (const _DBC_SCENE_DEFINE*)s_pSceneNameDBC->Search_Index_EQU(nIndex);
	state->PushString( pSceneDef->szName );
	return 1;
}


//获得商店的修理和收购类型
INT Lua_GetShopType( LuaPlus::LuaState* state )
{
	LuaStack args(state);
	if( !args[1].IsString() )
	{
		TDThrow("LUA: Lua_GetShopType[1] param parameter error");
	}
	std::string str = args[1].GetString();

	if(str == "Repair")
	{
		state->PushInteger(CDataPool::GetMe()->Booth_GetRepairType());
		return 1;
	}
	else if( str == "buy" )
	{
		state->PushInteger(CDataPool::GetMe()->Booth_GetBuyType());
		return 1;
	}
	else if(str == "type")
	{
		state->PushInteger(CDataPool::GetMe()->Booth_GetShopType());
		return 1;
	}

	return 0;
}

INT Lua_GetOperationType( LuaPlus::LuaState* state )
{
	state->PushInteger(CDataPool::GetMe()->Booth_GetRepairType());
	return 1;
}

INT Lua_OpenCharacter( LuaPlus::LuaState* state )
{
	LuaStack args(state);
	if( !args[ 1 ].IsInteger() ) return 0;
	CEventSystem::GetMe()->PushEvent( GE_OPEN_CHARACTOR, args[ 1 ].GetInteger() );
	return 0;
}

INT Lua_OpenEquip( LuaPlus::LuaState* state )
{
	LuaStack args(state);
	if( !args[ 1 ].IsInteger() ) return 0;

	CEventSystem::GetMe()->PushEvent(GE_OPEN_EQUIP, args[1].GetInteger());

	return 0;
}

INT Lua_GetActionInfo( LuaPlus::LuaState* state )
{
	LuaStack args(state);
	if( !args[ 1 ].IsInteger() ) return 0;

	return 1;
}



//请求升级
INT Lua_AskLevelUp(LuaPlus::LuaState* state)
{
	CGameInterface::GetMe()->Player_AskLevelUp();
	return 0;
}

//开启/关闭挂机
INT Lua_AutoHit(LuaPlus::LuaState* state)
{
	LuaStack args(state);
	if( !args[ 1 ].IsInteger() ) return 0;
	CGameInterface::GetMe()->Player_AUTOHit(args[ 1 ].GetInteger());
	return 0;
}

//---------------------------------------------------------------------------------------------------------
// 组队相关.

// 队员或队长的功能菜单.
INT Lua_ShowTeamFuncMenu(LuaPlus::LuaState* state)	
{
	
	LuaStack args(state);
	if( !args[ 1 ].IsInteger() )
	{
		return 0;
	}

	// 记录当前选择的队友.
	CUIDataPool::GetMe()->m_iSelectedTeamMember = args[ 1 ].GetInteger();
	
	// 得到自己的guid
	INT MyGUID   = CObjectManager::GetMe()->GetMySelf()->GetServerGUID();

	// 得到队长的guid
	UINT LeaderId = CUIDataPool::GetMe()->GetTeamOrGroup()->GetLeaderGUID();

	//得到鼠标位置
	POINT ptMouse = CInputSystem::GetMe()->MouseGetPos();
	CHAR szXPos[32]; _snprintf(szXPos, 32, "%d", ptMouse.x);
	CHAR szYPos[32]; _snprintf(szYPos, 32, "%d", ptMouse.y);
	CHAR szIndex[ 32 ]; 
	_snprintf(szIndex, 32, "%d", CUIDataPool::GetMe()->m_iSelectedTeamMember );
	std::vector< STRING > strParamInfo;
	if(MyGUID == LeaderId)
	{

		strParamInfo.push_back("Team_Leader");
		strParamInfo.push_back("-1");
		strParamInfo.push_back(szXPos);
		strParamInfo.push_back(szYPos);
		strParamInfo.push_back(szIndex);
		((CEventSystem*)CGameProcedure::s_pEventSystem)->PushEvent( GE_SHOW_CONTEXMENU, strParamInfo);
		//如果自己是队长. 打开队长界面.
		//CEventSystem::GetMe()->PushEvent( GE_SHOW_TEAM_FUNC_MENU_LEADER, args[ 1 ].GetInteger() );
		//CEventSystem::GetMe()->PushEvent(GE_SHOW_CONTEXMENU, "Team_Leader");
	}
	else
	{
		strParamInfo.push_back("Team_Member");
		strParamInfo.push_back("-1");
		strParamInfo.push_back(szXPos);
		strParamInfo.push_back(szYPos);
		strParamInfo.push_back(szIndex);
		((CEventSystem*)CGameProcedure::s_pEventSystem)->PushEvent( GE_SHOW_CONTEXMENU, strParamInfo);
		// 如果自己是队员, 打开队员界面.
		//CEventSystem::GetMe()->PushEvent( GE_SHOW_TEAM_FUNC_MENU_MEMBER, args[ 1 ].GetInteger() );
		//CEventSystem::GetMe()->PushEvent(GE_SHOW_CONTEXMENU, "Team_Member");//
	}

	return 0;
}

// 设置当前选择的队员
INT Lua_SetCurSelMember(LuaPlus::LuaState* state)	
{
	
	LuaStack args(state);
	if( !args[ 1 ].IsInteger() )
	{
		return 0;
	}

	// 记录当前选择的队友.

	CUIDataPool::GetMe()->m_iSelectedTeamMember = args[ 1 ].GetInteger();
	return 0;
}




// 显示队伍信息对话框.
INT Lua_ShowTeamInfoDlg(LuaPlus::LuaState* state)
{
	LuaStack args(state);
	if( !args[ 1 ].IsInteger() )
	{
		return 0;
	}

	int iOpenType = 0;

	// 得到打开队友信息的类型.
	// 0 : 打开队伍信息
	// 1 : 有人申请加入队伍
	// 2 : 有人邀请你加入队伍
	iOpenType = args[ 1 ].GetInteger();

	CEventSystem::GetMe()->PushEvent(GE_TEAM_OPEN_TEAMINFO_DLG, iOpenType);
	return 0;
}

// 闪烁按钮.
INT Lua_FlashTeamButton(LuaPlus::LuaState* state)
{
	LuaStack args(state);
	if( !args[ 1 ].IsInteger() )
	{
		return 0;
	}

	int iOpenType = 0;

	// 得到打开队友信息的类型.
	// 0 : 打开队伍信息
	// 1 : 有人申请加入队伍
	// 2 : 有人邀请你加入队伍
	iOpenType = args[ 1 ].GetInteger();
	CEventSystem::GetMe()->PushEvent(GE_TEAM_NOTIFY_APPLY, iOpenType);
	return 0;
}

// 组队相关.
//--------------------------------------------------------------------------------------------------------

// 设置一个全局变量（）
INT Lua_SetGlobalInteger(LuaPlus::LuaState* state)
{
	LuaStack args(state);
	if (! (args[1].IsNumber()) )
	{
		TDThrow("LUA: Lua_SetGlobalInteger Wrong Param");
	}

	if (! (args[2].IsString()) )
	{
		TDThrow("LUA: Lua_SetGlobalInteger Wrong Param");
	}

	int nNumber = args[1].GetInteger();
	std::string str = args[2].GetString();

	lua_pushnumber(state->GetCState(),nNumber);
	lua_setglobal(state->GetCState(),str.c_str());

	return 0;
}

// 获得一个全局变量
INT Lua_GetGlobalInteger(LuaPlus::LuaState* state)
{
	LuaStack args(state);
	if (! (args[1].IsString()) )
	{
		TDThrow("LUA: Lua_GetGlobalInteger Wrong Param");
	}
	std::string str = args[1].GetString();
	
	lua_getglobal(state->GetCState(),str.c_str());
	INT nNumber = (INT)lua_tonumber(state->GetCState(),-1);

	state->PushNumber(nNumber);
	return 1;
}

// 要装备的详细信息
INT Lua_AskEquipDetial( LuaPlus::LuaState* state)
{
	//详细装备(用于在数据池中存储物品详细属性)
	if ( CObjectManager::GetMe()->GetMySelf() != NULL )
	{
		CGAskDetailEquipList msgAskMyDetailEquip;
		msgAskMyDetailEquip.setObjID(CObjectManager::GetMe()->GetMySelf()->GetServerID());
		msgAskMyDetailEquip.SetAskMode(ASK_EQUIP_ALL);
		CNetManager::GetMe()->SendPacket(&msgAskMyDetailEquip);
	}

	return 0;
}

// 销毁物品
INT Lua_DiscardItem(LuaPlus::LuaState* state)
{
	//销毁物品,根据不同的物品来源，需要发送不同的销毁消息
	INT nTypeOwner	=	CDataPool::GetMe()->DisCard_GetItemConta();
	INT	nItemPos	=	CDataPool::GetMe()->DisCard_GetItemPos();
	switch( nTypeOwner ) 
	{
	case tObject_Item::IO_MYSELF_PACKET:				// 来自玩家的背包
		{
			tObject_Item* pItem = CDataPool::GetMe()->UserBag_GetItem(nItemPos);

			if(!pItem) break;
			//验证是否可以丢弃
			if(!pItem->Rule(tObject_Item::RULE_DROP))
			{
				CEventSystem::GetMe()->PushEvent(GE_NEW_DEBUGMESSAGE, pItem->RuleFailMessage(tObject_Item::RULE_DROP).c_str());
				break;
			}

			CGDiscardItem msg;
			msg.SetOpt(CGDiscardItem::FromBag);
			msg.SetBagIndex(nItemPos);

			CNetManager::GetMe()->SendPacket(&msg);
		}
		break;
	case tObject_Item::IO_MYSELF_EQUIP:					// 来自玩家身上的装备
		{
			break;
			tObject_Item* pItem = CDataPool::GetMe()->UserEquip_GetItem((HUMAN_EQUIP)nItemPos);

			if(!pItem) break;
			//验证是否可以丢弃
			if(!pItem->Rule(tObject_Item::RULE_DROP))
			{
				CEventSystem::GetMe()->PushEvent(GE_NEW_DEBUGMESSAGE, pItem->RuleFailMessage(tObject_Item::RULE_DROP).c_str());
				break;
			}

			CGDiscardEquip msg;
			msg.SetEquipPoint(nItemPos);

			CNetManager::GetMe()->SendPacket(&msg);
		}
		break;
	case tObject_Item::IO_MYSELF_BANK:					// 玩家的银行
		{
			tObject_Item* pItem = CDataPool::GetMe()->UserBank_GetItem(nItemPos);

			if(!pItem) break;
			//验证是否可以丢弃
			if(!pItem->Rule(tObject_Item::RULE_DROP))
			{
				CEventSystem::GetMe()->PushEvent(GE_NEW_DEBUGMESSAGE, pItem->RuleFailMessage(tObject_Item::RULE_DROP).c_str());
				break;
			}

			CGDiscardItem msg;
			msg.SetOpt(CGDiscardItem::FromBank);
			msg.SetBagIndex(nItemPos);

			CNetManager::GetMe()->SendPacket(&msg);
		}
		break;
	default:
		break;
	}

	return 0;
}

// 取消物品的锁定状态
INT Lua_DiscardItemCancelLocked( LuaPlus::LuaState* state)
{
	INT nTypeOwner	=	CDataPool::GetMe()->DisCard_GetItemConta();
	INT	nItemPos	=	CDataPool::GetMe()->DisCard_GetItemPos();

	switch( nTypeOwner ) 
	{
	case tObject_Item::IO_MYSELF_PACKET:				// 来自玩家的背包
		{
			tObject_Item* pItem = CDataPool::GetMe()->UserBag_GetItem(nItemPos);

			if(pItem)
			{
				pItem->SetLock(FALSE);
			}
		}
		break;
	case tObject_Item::IO_MYSELF_EQUIP:					// 来自玩家身上的装备
		{
			tObject_Item* pItem = CDataPool::GetMe()->UserEquip_GetItem((HUMAN_EQUIP)nItemPos);

			if(pItem)
			{
				pItem->SetLock(FALSE);
			}
		}
		break;
	case tObject_Item::IO_MYSELF_BANK:					// 玩家的银行
		{
			tObject_Item* pItem = CDataPool::GetMe()->UserBank_GetItem(nItemPos);

			if(pItem)
			{
				pItem->SetLock(FALSE);
			}
		}
		break;
	default:
		break;
	}

	CEventSystem::GetMe()->PushEvent(GE_PACKAGE_ITEM_CHANGED);
	return 0;
}

// 播放声音
INT Lua_PlaySound(LuaPlus::LuaState* state)
{
	LuaStack args(state);
	if (! (args[1].IsNumber()) )
	{
		TDThrow("LUA: Lua_SetGlobalInteger Wrong Param");
	}

	int nSoundIndex = args[1].GetInteger();
	CSoundSystemFMod::_PlayUISoundFunc(nSoundIndex);
	return 0;
}

INT	Lua_CloseAllWindow( LuaPlus::LuaState* state)
{
	CGameProcedure::s_pUISystem->CloseAllWindow();
	return 0;
}

// target窗口弹出的菜单
INT	Lua_OpenTargetMenu( LuaPlus::LuaState* state)
{
	INT iObjectId = 0;
	
	if(NULL == CObjectManager::GetMe()->GetMainTarget())
	{
		return 0;
	}

	iObjectId = CObjectManager::GetMe()->GetMainTarget()->GetServerID();
	CGameProcedure::s_pGameInterface->Object_ShowContexMenu(iObjectId);
	return 0;
}


INT Lua_GetMousePos( LuaPlus::LuaState* state)
{
	POINT ptMouse = CInputSystem::GetMe()->MouseGetPos();
	state->PushInteger( ptMouse.x );
	state->PushInteger( ptMouse.y );
	return 2;
}

// 显示系统提示对话框。2006－3－27
INT Lua_ShowSystemTipInfo( LuaPlus::LuaState* state)
{
	
	LuaStack args(state);
	if (! (args[1].IsString()) )
	{
		TDThrow("LUA: Lua_ShowSystemTipInfo Wrong Param");
	}

	const char* pInfo =  args[1].GetString();
	CEventSystem::GetMe()->PushEvent(GE_OPEN_SYSTEM_TIP_INFO_DLG, pInfo);
	return 0;
}

// 打开更改二级密码对话框。2006－3－27
INT Lua_OpenChangeMinorPasswordDlg( LuaPlus::LuaState* state)
{
	CEventSystem::GetMe()->PushEvent(GE_MINORPASSWORD_OPEN_CHANGE_PASSWORD_DLG);
	return 0;
}

// 打开解锁密码。2006－3－27
INT Lua_OpenUnLockeMinorPasswordDlg( LuaPlus::LuaState* state)
{
	CEventSystem::GetMe()->PushEvent(GE_MINORPASSWORD_OPEN_UNLOCK_PASSWORD_DLG);
	return 0;
}

// 打开设置密码界面。2006－3－28
INT Lua_OpenSetMinorPasswordDlg( LuaPlus::LuaState* state)
{

	CEventSystem::GetMe()->PushEvent(GE_MINORPASSWORD_OPEN_SET_PASSWORD_DLG);
	return 0;

}


// 设置密码。2006－3－28
INT Lua_SendSetMinorPassword( LuaPlus::LuaState* state)
{

	LuaStack args(state);
	if (! (args[1].IsString()) )
	{
		TDThrow("LUA: Lua_SendSetMinorPassword Wrong Param");
	}

	const char* pPassword =  args[1].GetString();

	CGMinorPasswd Msg;
	CG_MINORPASSWD* pMinorPasswd = Msg.GetMinorPassword();
	pMinorPasswd->CleanUp();
	pMinorPasswd->m_Type = MREQT_SETPASSWD;
	pMinorPasswd->m_OnePasswd.CleanUp();
	pMinorPasswd->m_OnePasswd.SetPasswd( pPassword );

	CNetManager::GetMe()->SendPacket(&Msg);

	return 0;
}

// 修改密码。2006－3－28
INT Lua_SendModifyMinorPassword( LuaPlus::LuaState* state)
{
	LuaStack args(state);
	if (! (args[1].IsString()) )
	{
		TDThrow("LUA: Lua_SendModifyMinorPassword Wrong Param");
	}

	const char* pPassword =  args[1].GetString();

	CGMinorPasswd Msg;
	CG_MINORPASSWD* pMinorPasswd = Msg.GetMinorPassword();
	pMinorPasswd->CleanUp();
	pMinorPasswd->m_Type = MREQT_MODIFYPASSWD;
	pMinorPasswd->m_OnePasswd.CleanUp();
	pMinorPasswd->m_OnePasswd.SetPasswd( pPassword );

	CNetManager::GetMe()->SendPacket(&Msg);

	return 0;
}

// 解锁密码。2006－3－28
INT Lua_UnLockMinorPassword( LuaPlus::LuaState* state)
{
	LuaStack args(state);
	if (! (args[1].IsString()) )
	{
		TDThrow("LUA: Lua_UnLockMinorPassword Wrong Param");
	}

	const char* pPassword =  args[1].GetString();

	CGMinorPasswd Msg;
	CG_MINORPASSWD* pMinorPasswd = Msg.GetMinorPassword();
	pMinorPasswd->CleanUp();
	pMinorPasswd->m_Type = MREQT_UNLOCKPASSWD;
	pMinorPasswd->m_OnePasswd.CleanUp();
	pMinorPasswd->m_OnePasswd.SetPasswd( pPassword );

	CNetManager::GetMe()->SendPacket(&Msg);

	return 0;
}

// 强制解锁密码。2006－3－28
INT Lua_ForceUnLockMinorPassword( LuaPlus::LuaState* state)
{
	CGMinorPasswd Msg;
	CG_MINORPASSWD* pMinorPasswd = Msg.GetMinorPassword();
	pMinorPasswd->CleanUp();
	pMinorPasswd->m_Type = MREQT_DELETEPASSWD;
	pMinorPasswd->m_OnePasswd.CleanUp();

	CNetManager::GetMe()->SendPacket(&Msg);

	return 0;
}


// 修改密码。2006－3－28
INT Lua_ModifyMinorPassword( LuaPlus::LuaState* state)
{

	LuaStack args(state);
	if (! (args[1].IsString()) )
	{
		TDThrow("LUA: Lua_UnLockMinorPassword Wrong Param");
	}

	const char* pOldPassword =  args[1].GetString();

	if (! (args[2].IsString()) )
	{
		TDThrow("LUA: Lua_UnLockMinorPassword Wrong Param");
	}

	const char* pNewPassword =  args[2].GetString();

	CGMinorPasswd Msg;
	CG_MINORPASSWD* pMinorPasswd = Msg.GetMinorPassword();
	pMinorPasswd->CleanUp();
	pMinorPasswd->m_Type = MREQT_MODIFYPASSWD;
	pMinorPasswd->m_ModifyPasswd.CleanUp();

	// 设置要修改的密码
	pMinorPasswd->m_ModifyPasswd.SetOldPasswd(pOldPassword);
	pMinorPasswd->m_ModifyPasswd.SetNewPasswd(pNewPassword);

	CNetManager::GetMe()->SendPacket(&Msg);

	return 0;
}

INT Lua_GetCurrentTime( LuaPlus::LuaState* state)
{
	SYSTEMTIME systime;
	::GetLocalTime( &systime );
	
	state->PushInteger( int( systime.wHour ) );
	state->PushInteger( int( systime.wMinute ) );
	state->PushInteger( int( systime.wMilliseconds ) );
	return 3;
}

INT Lua_GetCurMousePos( LuaPlus::LuaState* state)
{
	POINT ptMouse = CGameProcedure::s_pInputSystem->MouseGetPos();

	state->PushInteger(ptMouse.x);
	state->PushInteger(ptMouse.y);

	return 2;
}

//// 播放音乐。参数是音乐的ID 2006－3－28
//INT Lua_PlayMusic( LuaPlus::LuaState* state)
//{
//	LuaStack args(state);
//	if (! (args[1].IsString()) )
//	{
//		TDThrow("LUA: Lua_PlayMusic Wrong Param");
//	}
//
//	INT iId =  args[1].GetInteger();
//
//
//}
//
//
//// 停止音乐。参数是音乐的句柄 2006－3－28
//INT Lua_StopMusic( LuaPlus::LuaState* state)
//{
//
//}//


}
