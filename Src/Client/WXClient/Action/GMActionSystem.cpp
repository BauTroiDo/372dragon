#include "StdAfx.h"
#include "../Network/CysPowerNet.h"
#include "..\network\NetManager.h"
#include "GMActionSystem.h"
#include "CysQuickbarContract.h"
#include "../Network/CysTooltipCompare.h"
#include "../Network/CysModernGame.h"
#include "../../LuaApiGen/CysHost_EquipmentSkills.h"
#include "..\Event\GMEventSystem.h"
#include "..\DataPool\GMUIDataPool.h"
#include "..\DataPool\GMDataPool.h"
#include "TDException.h"
#include "..\Procedure\GameProcedure.h"
#include "..\Interface\GMGameInterface.h"
#include "..\DataPool\DetailAttrib_Player.h"
#include "TDObjectSystem.h"
#include "..\Script\GMScriptSystem.h"
#include "..\Object\ObjectManager.h"
#include "..\Interface\GMGameInterface.h"
#include "..\Object\Item\Obj_Item.h"
#include "..\Object\Item\Obj_Item_Medicine.h"
#include "SkillDataMgr.h"
#include "TDDBC_Struct.h"
#include "..\Object\Character\Obj_PlayerMySelf.h"
#include "TDObjectSystem.h"
#include "TDVariable.h"
#include "TDUtil.h"
#include "CysTooltipContract.h"
#include "..\DBC\GMDataBase.h"
#include "..\DataPool\GMDP_CharacterData.h"
#include "..\DataPool\GMDP_Struct_Quest.h"
#include "CGBankAddItem.h"
#include "CGBankRemoveItem.h"
#include "CGBankSwapItem.h"
#include "CGModifySetting.h"
#include "GMActionSystem_Item.h"
#include "GMActionSystem_LifeAbility.h"
#include "GMActionSystem_Skill.h"
#include "GMActionSystem_XinFa.h"
#include "GMActionSystem_PetSkill.h"

#include "GMActionSystem_ChatMood.h"
#include "TDInputSystem.h"
#include "..\Interface\GMInterface_Script_Tooltip.h"
#include "gamedefine2.h"
#include "GMActionSystem_MouseCmd.h"

const char*		NAMETYPE_SKILL			= "skill";
const char*		NAMETYPE_LIFESKILL		= "life";
const char*		NAMETYPE_PACKAGEITEM	= "packageitem";
const char*		NAMETYPE_BANKITEM		= "bankitem";
const char*		NAMETYPE_BOOTITEM		= "boothitem";
const char*		NAMETYPE_LOOTITEM		= "lootitem";
const char*		NAMETYPE_XINFA			= "xinfa";
const char*		NAMETYPE_PETSKILL		= "petskill";
const char*		NAMETYPE_VIRTUALITEM	= "virtualitem";
const char*		NAMETYPE_EQUIP			= "equip";
const char*		NAMETYPE_EXCHANGESELF	= "ex_self";
const char*		NAMETYPE_EXCHANGEOTHER	= "ex_other";
const char*		NAMETYPE_MISSIONREFER	= "mission";
const char*		NAMETYPE_APPENDITEM		= "appenditem";
const char*		NAMETYPE_STALLSELF		= "st_self";
const char*		NAMETYPE_STALLOTHER		= "st_other";
const char*		NAMETYPE_OTHEREQUIP		= "targetequip";
const char*		NAMETYPE_PS_SELF		= "ps_self";
const char*		NAMETYPE_PS_OTHER		= "ps_other";
const char*		NAMETYPE_CHATMOOD		= "chatmood";
const char*		NAMETYPE_CALLBACK		= "callback";
const char*		NAMETYPE_SPLITGEM		= "splitgem";
const char*		NAMETYPE_CITY_RESEARCH	= "cityresearch";
const char*		NAMETYPE_CITY_SHOP		= "cityshop";
const char*		NAMETYPE_TRANSFER_ITEM	= "transferitem";
const char*		NAMETYPE_QUESTUI_DEMAND	= "questui_demand";
const char*		NAMETYPE_QUESTUI_REWARD	= "questui_reward";


//======================================================================
CActionItem CActionItem::s_InvalidAction;
LuaPlus::LuaObject* CActionItem::s_pMetaTable = NULL;
CActionItem::CActionItem(INT id)
{
	m_ID		= id;
	m_bChecked	= FALSE;
	m_bEnabled	= TRUE;
}

CActionItem::~CActionItem()
{
	ClearRefrence();

	if(CGameProcedure::s_pGameInterface && this==CGameProcedure::s_pGameInterface->Skill_GetActive())
	{
		CGameInterface::GetMe()->Skill_SetActive(0);
	}

	if(CGameProcedure::s_pActionSystem && this==CActionSystem::GetMe()->GetDefaultAction())
	{
		CActionSystem::GetMe()->SetDefaultAction(0);
	}
}

VOID CActionItem::ClearRefrence(VOID)
{
	std::set< tActionReference* >::iterator it;
	for(it=m_setReference.begin(); it!=m_setReference.end(); it++)
	{
		(*it)->BeDestroyed();
	}
}

VOID CActionItem::UpdateToRefrence(VOID)
{
	std::set< tActionReference* >::iterator it;
	for(it=m_setReference.begin(); it!=m_setReference.end(); it++)
	{
		(*it)->Update(GetID());
	}
}

INT	CActionItem::Lua_GetID(LuaPlus::LuaState* pState)	//得到ID
{
	INT id = GetID();
	pState->PushInteger(id);
	return 1;
}

// CYS-UIFRAMES: see the declaration in GMActionSystem.h for why this is "" and not a colour.
INT	CActionItem::Lua_GetItemColorInShop(LuaPlus::LuaState* pState)
{
	pState->PushString("");
	return 1;
}

// CYS-UIFIX2: `theAction:GetItemTableIndex()` - MOT gia tri, KHONG doi so (do tren ca 22 dong goi).
// `GetDefineID()` la ao: ban item tra `pItem->GetIdTable()`, lop co so tra -1. Do dung bang voi
// host `PlayerPackage:GetItemTableIndex` da co, nen hai duong khong the lech nhau.
INT	CActionItem::Lua_GetItemTableIndex(LuaPlus::LuaState* pState)
{
	pState->PushInteger(GetDefineID());
	return 1;
}

INT CActionItem::Lua_GetPrice(LuaPlus::LuaState* pState)	//得到价格
{
	pState->PushInteger(GetItemPrice());
	return 1;
}

INT CActionItem::Lua_GetNum(LuaPlus::LuaState* pState)	//得到每个格子里头的数量
{
	pState->PushInteger(GetNum());
	return 1;
}

INT	CActionItem::Lua_GetType(LuaPlus::LuaState* pState)	//得到类型
{
//	AxTrace(0, 1, "Item:%d", CObject_Item::Debug_GetNum());
//	AxTrace(0, 1, "Action:%d", CActionSystem::GetMe()->m_mapItem.size());
	pState->PushString( GetType_String() );
	return 1;
}

INT CActionItem::Lua_GetDesc(LuaPlus::LuaState* pState)
{
	pState->PushString(GetDesc());
	return 1;
}

INT CActionItem::Lua_GetName(LuaPlus::LuaState* pState)
{
	pState->PushString(GetName());
	return 1;
}

//得到在资源表中的ID
INT	CActionItem::Lua_GetDefineID(LuaPlus::LuaState* pState)
{
	if(CysModernGame::IsActive() && GetType()==AOT_SKILL) {
		const SCLIENT_SKILL* skill=(const SCLIENT_SKILL*)GetImpl();
		if(skill && skill->m_pDefine) {
			pState->PushInteger(skill->m_pDefine->m_nID);return 1;
		}
	}
	pState->PushInteger(GetDefineID());
	return 1;
}

INT CActionItem::Lua_GetItemID(LuaPlus::LuaState* pState)
{
	const CObject_Item* item=GetType()==AOT_ITEM?(const CObject_Item*)GetImpl():NULL;
	pState->PushInteger(item?item->GetID():-1);return 1;
}

INT CActionItem::Lua_GetOwnerXinfa(LuaPlus::LuaState* pState)
{
	if(GetType() != AOT_SKILL)
	{
		pState->PushNumber(-1);
		return 1;
	}

	const SCLIENT_SKILL* pSkill = (const SCLIENT_SKILL*)GetImpl();
	// Murong's temporary borrowed attacks have no permanent book slot.
	if(CysModernGame::IsActive() && pSkill && pSkill->m_pDefine &&
	   pSkill->m_pDefine->m_nID >= 788 && pSkill->m_pDefine->m_nID <= 800) {
		pState->PushInteger(-1);return 1;
	}
	if(CysModernGame::IsActive() && pSkill && pSkill->m_pDefine && CysEquipmentSkills::IsWuhunSkill(pSkill->m_pDefine->m_nID)) {
		pState->PushInteger(-8888);return 1;
	}
	if(!pSkill || pSkill->m_pDefine->m_nClassByUser != A_SKILL_FOR_PLAYER)
	{
		pState->PushNumber(-1);
		return 1;
	}

	CActionItem* pXinFaActionItem = (CActionItem*)CActionSystem::GetMe()->GetAction_SkillClass(pSkill->m_pDefine->m_nSkillClass);
	if(!pXinFaActionItem)
	{
		pState->PushNumber(-9999);
		return 1;
	}


	pState->PushNumber(pXinFaActionItem->GetID());
	return 1;
}

INT CActionItem::Lua_GetPetSkillOwner(LuaPlus::LuaState* pState)
{
	if(GetType() != AOT_PET_SKILL)
	{
		pState->PushNumber(-1);
		return 1;
	}

	const PET_SKILL* pSkill = (const PET_SKILL*)GetImpl();
	if(!pSkill)
	{
		pState->PushNumber(-1);
		return 1;
	}

	pState->PushNumber(pSkill->m_nPetNum);
	return 1;
}

INT	CActionItem::Lua_GetOwnerQuest(LuaPlus::LuaState* pState)
{
	if(GetType() != AOT_ITEM)
	{
		pState->PushNumber(-1);
		return 1;
	}

	CActionItem_Item* pItem = (CActionItem_Item*)(tObject_Item*)GetImpl();
	if(!pItem)
	{
		pState->PushNumber(-1);
		return 1;
	}

	pState->PushNumber(pItem->GetQuestIndex());
	return 1;
}

VOID CActionItem::DoActionPrepare(BOOL bCheck)
{
	//显示按钮按下动画
	std::set< tActionReference* >::iterator it;
	for(it=m_setReference.begin(); it!=m_setReference.end(); it++)
	{
		(*it)->SetCheck(bCheck);
	}
}

VOID CActionItem::AddReference(tActionReference* pRef,BOOL bIsInMenuToolbar)
{
	//如果没有,加入
	if(m_setReference.find(pRef) == m_setReference.end()) 
	{
		m_setReference.insert(pRef);
	}
	//刷新Check信息
	pRef->SetCheck(m_bChecked);
	pRef->SetDefault(CActionSystem::GetMe()->GetDefaultAction() == this);

	switch(GetType())
	{
	case AOT_ITEM:
		{
			//物品的每组的个数显示在右下角
			tObject_Item* pItem = (tObject_Item*)GetImpl();
			
			if( pItem->GetTypeOwner() == tObject_Item::IO_BOOTH 
				||pItem->GetTypeOwner() == tObject_Item::IO_BOOTH_CALLBACK
				||pItem->GetTypeOwner() == tObject_Item::IO_CITY_SHOP)
			{
				INT nGroupNumber = GetNum();
				if(nGroupNumber > 1)
				{
					CHAR szTemp[32];
					_snprintf(szTemp, 32, "%d", nGroupNumber);
					pRef->SetCornerChar(tActionReference::ANP_BOTRIGHT, szTemp);
				}
				else
				{
					pRef->SetCornerChar(tActionReference::ANP_BOTRIGHT, "");
				}

				//有限物品的最大数量显示在左上角
				INT nMaxNumber = pItem->GetMax();
				if(nMaxNumber > 1)
				{
					CHAR szTemp[32];
					_snprintf(szTemp, 32, "%d", nMaxNumber);
					pRef->Enable();
					pRef->SetCornerChar(tActionReference::ANP_TOPLEFT, szTemp);
				}
				else if(nMaxNumber == 0)
				{
					pRef->Disable();
					pRef->SetCornerChar(tActionReference::ANP_TOPLEFT, "");
				}
				else
				{
					pRef->Enable();
					pRef->SetCornerChar(tActionReference::ANP_TOPLEFT, "");
				}
			}
			else if( pItem->GetTypeOwner() == tObject_Item::IO_MYSELF_PACKET 
				|| pItem->GetTypeOwner() == tObject_Item::IO_MYSELF_BANK 
				|| pItem->GetTypeOwner() == tObject_Item::IO_MYEXBOX 
				|| pItem->GetTypeOwner() == tObject_Item::IO_OTHEREXBOX
				|| pItem->GetTypeOwner() == tObject_Item::IO_MISSIONBOX
				|| pItem->GetTypeOwner() == tObject_Item::IO_MYSTALLBOX
				|| pItem->GetTypeOwner() == tObject_Item::IO_OTSTALLBOX
				|| pItem->GetTypeOwner() == tObject_Item::IO_QUESTVIRTUALITEM
				|| pItem->GetTypeOwner() == tObject_Item::IO_ITEMBOX
				|| pItem->GetTypeOwner() == tObject_Item::IO_PS_SELFBOX
				|| pItem->GetTypeOwner() == tObject_Item::IO_PS_OTHERBOX
                )
			{
				INT nGroupNumber = GetNum();
				//AxTrace(0, 0, "%s:GroupNumber=%d", pItem->GetName(), nGroupNumber);
				if(bIsInMenuToolbar == TRUE)
				{
					CHAR szTemp[32];
					_snprintf(szTemp, 32, "%d", CDataPool::GetMe()->UserBag_CountItemByIDTable(pItem->GetIdTable()));
					pRef->SetCornerChar(tActionReference::ANP_BOTRIGHT, szTemp);
				}
				else if(nGroupNumber > 1)
				{
					CHAR szTemp[32];
					_snprintf(szTemp, 32, "%d", nGroupNumber);
					pRef->SetCornerChar(tActionReference::ANP_BOTRIGHT, szTemp);
				}
				else
				{
					pRef->SetCornerChar(tActionReference::ANP_BOTRIGHT, "");
				}
			}
		}
		break;

	default:
		pRef->SetCornerChar(tActionReference::ANP_BOTRIGHT, "");
		break;
	}


	UpdateCoolDown();
}

VOID CActionItem::RemoveRefrence(tActionReference* pRef)
{
	if(m_setReference.find(pRef) == m_setReference.end()) return;

	m_setReference.erase(pRef);

	pRef->SetCheck(false);
	pRef->SetDefault(false);
}

VOID CActionItem::SetCheckState(BOOL bCheck)
{
	m_bChecked = bCheck;
	std::set< tActionReference* >::iterator it;

	for(it=m_setReference.begin(); it!=m_setReference.end(); it++)
	{
		(*it)->SetCheck(bCheck);
	}
}

VOID CActionItem::SetDefaultState(BOOL bCheck)
{
	std::set< tActionReference* >::iterator it;

	for(it=m_setReference.begin(); it!=m_setReference.end(); it++)
	{
		(*it)->SetDefault(bCheck);
	}
}

VOID CActionItem::UpdateCoolDown(VOID)
{
	std::set< tActionReference* >::iterator it;
	INT nCoolDownID = GetCoolDownID();

	//对于没有冷却的Action
	if(-1 == nCoolDownID)
	{
		for(it=m_setReference.begin(); it!=m_setReference.end(); it++)
		{
			(*it)->EnterCoolDown(-1, 0.0f);
		}
		return;
	}

	//取得冷却组数据
	const CDataPool::COOLDOWN_GROUP* pCoolDownGroup =
			CDataPool::GetMe()->CoolDownGroup_Get(nCoolDownID);

	INT nTimeNow   = pCoolDownGroup->nTime;
	INT nTimeTotal = pCoolDownGroup->nTotalTime;

	for(it=m_setReference.begin(); it!=m_setReference.end(); it++)
	{
		if(nTimeNow <= 0 || nTimeTotal <= 0)
		{
			(*it)->EnterCoolDown(-1, 0.0f);
		}
		else
		{
			(*it)->EnterCoolDown(nTimeTotal, 1.0f - (FLOAT)nTimeNow/(FLOAT)nTimeTotal);
		}
	}
}

VOID CActionItem::UpdateCommonCoolDown(VOID)
{
	//药品也要走cooldown
	CObject_Item_Medicine* pItem = (CObject_Item_Medicine*)GetImpl();
	if(!pItem)
	{
		return;
	}

    //针对技能Action
	if(GetType() != AOT_SKILL /*&& pItem->GetItemClass() != ICLASS_COMITEM*/ ) return;

	//取得冷却组数据
	const CDataPool::COOLDOWN_GROUP* pCoolDownGroup =
			CDataPool::GetMe()->CoolDownGroup_Get(GetCoolDownID());
	if(!pCoolDownGroup) return;

	//如果处于冷却中
	if(pCoolDownGroup->nTime > 0) return;
	
	INT nCommonCoolDown = CDataPool::GetMe()->CommonCoolDown_Get();

	//通知UI，进入公共冷却
	std::set< tActionReference* >::iterator it;
	for(it=m_setReference.begin(); it!=m_setReference.end(); it++)
	{
		(*it)->EnterCoolDown(nCommonCoolDown, 1.0f - (FLOAT)nCommonCoolDown/(FLOAT)COMMONCOOLDOWN_TIME );
	}
}

// CYS-FRAMESTRUTH 20/09: A/B switch, read ONCE. CYS_FT_TOOLTIP_OLD=1 restores the pre-patch event (4 params, mouse
// position) so the same binary can run both arms. Default = the living contract.
bool CysFtTooltipOldContract()
{
	static int s_old = -1;
	if (s_old < 0)
	{
		char text[8] = {};
		const DWORD n = ::GetEnvironmentVariableA("CYS_FT_TOOLTIP_OLD", text, sizeof(text));
		s_old = (n == 1 && text[0] == '1') ? 1 : 0;
		TDU_Log("CYS-FRAMESTRUTH: SHOW_SUPERTOOLTIP contract=%s", s_old ? "OLD (4 params, mouse point; CYS_FT_TOOLTIP_OLD=1)" : "living (7 params, button rect, cmp count)");
	}
	return s_old == 1;
}

//显示tooltips
VOID CActionItem::NotifyTooltipsShow(INT nLeft, INT nTop, INT nRight, INT nBottom)
{
	//生成数据
	SCRIPT_SANDBOX::SuperTooltips::s_SupperTooltip.SetActionItem(this);

	//产生UI事件
	std::vector< STRING > vParam;
	vParam.push_back("1");
	vParam.push_back(GetType_String());

	char szTemp[32];
	if (CysFtTooltipOldContract())
	{
		POINT ptMouse = CGameProcedure::s_pInputSystem->MouseGetPos();
		_snprintf(szTemp, 32, "%d", ptMouse.x);
		vParam.push_back(szTemp);
		_snprintf(szTemp, 32, "%d", ptMouse.y);
		vParam.push_back(szTemp);
		if (CysTooltipContract::Probe()) TDU_Log("CYS-FT-TOOLTIP: show params=4 point=%d,%d", ptMouse.x, ptMouse.y);
		CEventSystem::GetMe()->PushEvent(GE_SUPERTOOLTIP, vParam);
		return;
	}

	// The living contract (B FUN_1401de070 / CY 3.71 FUN_1400107c0, both = CActionItem vtable +0xa8): seven strings -
	// "1", type, LEFT, TOP, RIGHT, BOTTOM of the button, and the NUMBER OF COMPARE WINDOWS. SuperTooltip.lua reads them
	// as arg2..arg6 with no nil guard (`g_mCmpWndCount = tonumber(arg6)`, then `nCmpWndCount > 0` at :153 and :191).
	const INT rect[4] = { nLeft, nTop, nRight, nBottom };
	for (int i = 0; i < 4; ++i)
	{
		_snprintf(szTemp, 32, "%d", rect[i]);
		vParam.push_back(szTemp);
	}
    // CY counts worn items of the same equipment point (including paired slots)
    // and exposes independent action contexts through Cmp1/Cmp2 while Alt is held.
    const int comparisons=CysTooltipCompare::Prepare(this);
    vParam.push_back(std::to_string(comparisons));
    if (CysTooltipContract::Probe()) TDU_Log("CYS-FT-TOOLTIP: show params=7 rect=%d,%d,%d,%d compare=%d", nLeft, nTop, nRight, nBottom,comparisons);

	CEventSystem::GetMe()->PushEvent(GE_SUPERTOOLTIP, vParam);
}

//隐藏Tooltip
VOID CActionItem::NotifyTooltipsHide(VOID)
{
    CysTooltipCompare::Close();
	//生成数据
	SCRIPT_SANDBOX::SuperTooltips::s_SupperTooltip.SetActionItem(NULL);

	//隐藏Tooltip
	CEventSystem::GetMe()->PushEvent(GE_SUPERTOOLTIP, "0");
}


// 返回物品的等级
INT	CActionItem::GetItemLevel()
{
	// -1 表示物品没有等级.
	return -1;
}

// 得到物品的耐久
INT	CActionItem::GetItemDur()
{
	// -1 表示物品没有这个属性
	return -1;
}

// 得到物品的最大耐久
INT	CActionItem::GetItemMaxDur()
{
	// -1 表示物品没有这个属性
	return -1;
}

// 得到物品的修理次数
INT	CActionItem::GetItemRepairCount()
{
	// -1 表示物品没这个属性.
	return -1;
}

// 得到物品的绑定信息 
INT	CActionItem::GetItemBindInfo()
{
	// -1 表示物品没这个属性
	return -1;
}

// 得到物品卖给npc的价格
INT	CActionItem::GetItemPrice()
{
	// -1 表示物品没这个属性
	return -1;
}


// 得到物品的制作人
LPCTSTR	CActionItem::GetManufacturer()
{

	return _T("");
}


// 得到白色属性
LPCTSTR	CActionItem::GetBaseWhiteAttrInfo()
{
	return _T("");
}

// 得到扩展蓝色属性
LPCTSTR	CActionItem::GetExtBlueAttrInfo()
{

	return _T("");
}


// 得到action所引用的item 的类型
INT	CActionItem::GetItemType()
{
	return -1;
}


// 得到类型描述
LPCTSTR	CActionItem::GetTypeDesc()
{

	return "无类型描述";
}
// 是否需要在ToolTip上显示价格
INT CActionItem::IsViewToolTopsPrice()
{
	switch(GetType())
	{
	case AOT_EMPTY:

	case AOT_SKILL:							//战斗技能
	case AOT_SKILL_LIFEABILITY:				//生活技能
	case AOT_XINFA:							//心法
	case AOT_PET_SKILL:						//宠物技能
	case AOT_CHATMOOD:						//聊天动作
	case AOT_MOUSECMD_REPARE:				//鼠标指令_修理
	case AOT_MOUSECMD_IDENTIFY:				//鼠标指令_鉴定
	case AOT_MOUSECMD_ADDFRIEND:			//鼠标指令_加为好友
	case AOT_MOUSECMD_SALE:
	case AOT_MOUSECMD_BUYMULT:
		{
			return CActionItem_Item::TOOLTOPS_VIEW_PRICE_NO;
		}
		break;
	case AOT_ITEM:							//物品
	case AOT_EQUIP:							//装备
		{
			return ((CActionItem_Item*)this)->IsViewToolTopsPrice();
		}
		break;
	default:
		break;
	}
	return CActionItem_Item::TOOLTOPS_VIEW_PRICE_NO;
}
// 获得在ToolTip上显示的价格
INT	CActionItem::GetViewToolTopsPrice()
{
	switch(GetType())
	{
	case AOT_EMPTY:

	case AOT_SKILL:							//战斗技能
	case AOT_SKILL_LIFEABILITY:				//生活技能
	case AOT_XINFA:							//心法
	case AOT_PET_SKILL:						//宠物技能
	case AOT_CHATMOOD:						//聊天动作
	case AOT_MOUSECMD_REPARE:				//鼠标指令_修理
	case AOT_MOUSECMD_IDENTIFY:				//鼠标指令_鉴定
	case AOT_MOUSECMD_ADDFRIEND:			//鼠标指令_加为好友
	case AOT_MOUSECMD_SALE:
	case AOT_MOUSECMD_BUYMULT:
		{
			return 0;
		}
		break;
	case AOT_ITEM:							//物品
	case AOT_EQUIP:							//装备
		{
			return ((CActionItem_Item*)this)->GetViewToolTopsPrice();
		}
		break;
	default:
		break;
	}
	return 0;
}


//==================================================================

WX_IMPLEMENT_DYNAMIC(CActionSystem, GETCLASS(tActionSystem));
CActionSystem* CActionSystem::s_pMe = NULL;
CActionSystem::CActionSystem()
{
	s_pMe = this;
	m_pDefaultAction = NULL;
	m_pSetoutAction =NULL;
}

CActionSystem::~CActionSystem()
{
}

VOID CActionSystem::Initial(VOID*)
{
	//---------------------------------------------------------------------------------
	//加载主菜单配置
	const INT	s_MainMenuBarNum	= CysQuickbarContract::SlotCount;


	for (INT i=0; i<s_MainMenuBarNum; i++)
	{
		ACTIONBAR_ITEM newItem = {};
		newItem.idActionItem = INVALID_ID;
		newItem.typeItem = AOT_EMPTY;
		newItem.idImpl = INVALID_ID;
		newItem.idPetIndex = INVALID_ID;
		m_barMain.push_back(newItem);
	}

	//注册关心的事件
	//技能开始使用
	CEventSystem::GetMe()->RegisterEventHandle("ON_SKILL_ACTIVE", _OnSkillActive);

	//创建鼠标操作Action - 修理
	CActionItem_MouseCmd_Repair* pRepairAction = new CActionItem_MouseCmd_Repair(_CreateID());
	m_mapAllAction[pRepairAction->GetID()] = pRepairAction;

	//创建鼠标操作Action - 鉴定
	CActionItem_MouseCmd_Identify* pIdenAction = new CActionItem_MouseCmd_Identify(_CreateID());
	m_mapAllAction[pIdenAction->GetID()] = pIdenAction;
}

VOID CActionSystem::Release(VOID)
{
	std::map< INT, CActionItem* >::iterator it;
	for(it=m_mapAllAction.begin(); it!=m_mapAllAction.end(); it++)
	{
		if(it->second) delete (it->second);

		it->second = NULL;
	}
	m_mapAllAction.clear();
}

VOID CActionSystem::SaveAction(VOID)
{
	for(INT i=0; i<(INT)m_barMain.size(); i++)
	{
		ACTIONBAR_ITEM& barItem = m_barMain[i];

		tActionItem* pActionItem = NULL;
		CGModifySetting msg;
		_OWN_SETTING* pSend_Value = msg.GetValue();

		switch(barItem.typeItem)
			{
			case AOT_PET_SKILL:
				pActionItem = GetAction_PetSkillID(barItem.idPetIndex,barItem.idImpl);
				
//				if(m_bIsInitalDone == TRUE)
//				{
					msg.SetType(CysQuickbarContract::TaggedSlot(i));
					pSend_Value->m_SettingType = barItem.typeItem;
					pSend_Value->m_SettingData = (barItem.idPetIndex << 16) + barItem.idImpl;

					CNetManager::GetMe()->SendPacket( &msg );
//				}

				break;
			case AOT_SKILL:
				pActionItem = GetAction_SkillID(barItem.idImpl);

//				if(m_bIsInitalDone == TRUE)
//				{
					msg.SetType(CysQuickbarContract::TaggedSlot(i));
					pSend_Value->m_SettingType = barItem.typeItem;
					pSend_Value->m_SettingData = barItem.idImpl;

					CNetManager::GetMe()->SendPacket( &msg );
//				}
				break;

			case AOT_SKILL_LIFEABILITY:
				break;
			case AOT_ITEM:
				pActionItem = GetAction_ItemIDTable_FromMyPacket(barItem.idImpl);
				if(pActionItem)
				{
					barItem.idItemCount = CDataPool::GetMe()->UserBag_CountItemByIDTable(barItem.idImpl);
				}
				else
				{
					barItem.idItemCount = 0; // retain item type across inventory refreshes
				}

//				if(m_bIsInitalDone == TRUE)
//				{
					msg.SetType(CysQuickbarContract::TaggedSlot(i));
					pSend_Value->m_SettingType = barItem.typeItem;
					pSend_Value->m_SettingData = barItem.idImpl;

					CNetManager::GetMe()->SendPacket( &msg );
//				}

				break;
			case AOT_XINFA:
				break;

			case AOT_EMPTY:
//				if(m_bIsInitalDone == TRUE)
//				{
					msg.SetType(CysQuickbarContract::TaggedSlot(i));
					pSend_Value->m_SettingType = barItem.typeItem;
					pSend_Value->m_SettingData = barItem.idImpl;
					//给服务器发送CGMODIFYSETTING

					CNetManager::GetMe()->SendPacket( &msg );
//				}
				break;

			default:
				break;
			}
	}


}

VOID CActionSystem::Tick(VOID)
{
}

VOID CActionSystem::UserSkill_Update(VOID)
{
	CleanInvalidAction();

	//技能列表
	const SSKILL_MAP& mapSkill = 
		CObjectManager::GetMe()->GetMySelf()->GetCharacterData()->Get_Skill();

	SSKILL_MAP::const_iterator it;
	for(it=mapSkill.begin(); it!=mapSkill.end(); it++)
	{
		UpdateAction_FromSkill(&(it->second));
	}
}

VOID CActionSystem::UserPetSkill_Update(INT nPetNum)
{
	CleanInvalidAction();
	if( nPetNum < 0 || nPetNum >= HUMAN_PET_MAX_COUNT )
		return;
	//技能列表
	// CYS-PETSKILL 19/09: PET_MAX_SKILL_COUNT (the pool / CY wire count, 13), not MAX_PET_SKILL_COUNT (6, the size of
	// the 0.85 GCDetailAttrib_Pet packet array). This loop is what turns a pool cell into a "petskill" action, and
	// Pet.lua reads the actions back with Pet:EnumPetSkill(index, pos) for PETSKILL_BUTTONS_NUM = 12 buttons: bumping
	// only the enum would store cells 6..12 and still show six.
	for(INT i=0; i < PET_MAX_SKILL_COUNT; i++)
	{
		const PET_SKILL* arraySkill = CDataPool::GetMe()->Pet_GetSkill(nPetNum,i);
		if(!arraySkill || (arraySkill->m_pDefine== NULL)) continue;
		UpdateAction_FromPetSkill(nPetNum,arraySkill);
	}
	CEventSystem::GetMe()->PushEvent(GE_UPDATE_PET_PAGE);
}

VOID CActionSystem::UserTargetPetSkill_Update(VOID)
{
	CleanInvalidAction();

	//技能列表
	// CYS-PETSKILL 19/09: same count as UserPetSkill_Update; m_TargetPet is an SDATA_PET, so its m_aSkill vector is
	// resized to PET_MAX_SKILL_COUNT by the same constructor (GMDP_Struct_Pet.h) - TargetPet_GetSkill has no bound
	// check of its own, so the two must stay the same constant.
	for(INT i=0; i < PET_MAX_SKILL_COUNT; i++)
	{
		const PET_SKILL* arraySkill = CDataPool::GetMe()->TargetPet_GetSkill(i);
		if(!arraySkill || (arraySkill->m_pDefine== NULL)) continue;
		UpdateAction_FromPetSkill(TARGETPET_INDEX,arraySkill);
	}
//	CEventSystem::GetMe()->PushEvent(GE_UPDATE_PET_PAGE);
}

VOID CActionSystem::UserPetSkillStudy_Update(VOID)
{
	CleanInvalidAction();
	
	INT i=0;
	const PET_SKILL* pSk = CDataPool::GetMe()->PetSkillStudy_MenPaiList_Get(i);

	while(pSk)
	{
		if(!pSk || !(pSk->m_pDefine)) break;
		UpdateAction_FromPetSkillStudy(pSk);
		pSk = CDataPool::GetMe()->PetSkillStudy_MenPaiList_Get(++i);
	}
}

VOID CActionSystem::UserLifeAbility_Update(VOID)
{
	CleanInvalidAction();

	//技能
	const SLIFEABILITY_MAP& mapLifeAbility = 
		CObjectManager::GetMe()->GetMySelf()->GetCharacterData()->Get_LifeAbility();

	SLIFEABILITY_MAP::const_iterator it;
	for(it=mapLifeAbility.begin(); it!=mapLifeAbility.end(); it++)
	{
		UpdateAction_FromLifeAbility(&(it->second));
	}
	CGameProcedure::s_pEventSystem->PushEvent(GE_UPDATE_LIFESKILL_PAGE);
}

VOID CActionSystem::SkillClass_Update(VOID)
{
	CleanInvalidAction();

	//心法
	const SKILLCLASS_MAP& mapSkillClass = CObjectManager::GetMe()->GetMySelf()->GetCharacterData()->Get_SkillClass();

	SKILLCLASS_MAP::const_iterator it;
	for(it=mapSkillClass.begin(); it!=mapSkillClass.end(); it++)
	{
		UpdateAction_FromSkillClass(&(it->second));
	}
}

VOID CActionSystem::CleanInvalidAction(BOOL bForceCleanItemBox)
{
	register std::map< INT, CActionItem* >::iterator it;
	for(it=GetMe()->m_mapAllAction.begin(); it!=GetMe()->m_mapAllAction.end();)
	{
		std::map< INT, CActionItem* >::iterator itNext = it;
		itNext++;

		CActionItem* pActionItem = it->second;
		VOID* pImpl = pActionItem->GetImpl();
		if(!pImpl) 
		{
			//销毁
			EraseActionItem(it->second);
		}

		it = itNext;
	}
}

VOID CActionSystem::UserBag_Update(INT changedSlot)
{
	//清空已经不存在的Action
	GetMe()->CleanInvalidAction();

	const INT first = changedSlot >= 0 && changedSlot < CYS_CLIENT_BAG_SLOTS ? changedSlot : 0;
	const INT end = changedSlot >= 0 && changedSlot < CYS_CLIENT_BAG_SLOTS ? changedSlot + 1 : CYS_CLIENT_BAG_SLOTS;
	for(INT i=first; i<end; i++)
	{
		//取得物品
		tObject_Item*	pItem = CDataPool::GetMe()->UserBag_GetItem(i);
		if(pItem)
		{
			//设置新的物品数据
			GetMe()->UpdateAction_FromItem(pItem);
		}
	}
}

// 通过数据池中的数据, 创建出来装备action item
VOID CActionSystem::UserEquip_Update(VOID)
{
	//清空已经不存在的Action
	GetMe()->CleanInvalidAction();

	// 装备点的最大个数.
	for(INT i=0; i<CYS_CLIENT_EQUIP_SLOTS; i++) // CYS-INV
	{
		//取得玩家身上的装备
		tObject_Item*	pItem = CDataPool::GetMe()->UserEquip_GetItem((HUMAN_EQUIP)i);
		if(pItem)
		{
			//创建新的装备的action item
			GetMe()->UpdateAction_FromItem(pItem);
		}
	}
}

// 通过数据池中的数据, 创建出来装备action item
VOID CActionSystem::OtherPlayerEquip_Update(VOID)
{
	//清空已经不存在的Action
	GetMe()->CleanInvalidAction();

	// 装备点的最大个数.
	for(INT i=0; i<CYS_CLIENT_EQUIP_SLOTS; i++)
	{
		//取得玩家身上的装备
		tObject_Item*	pItem = CDataPool::GetMe()->OtherPlayerEquip_GetItem((HUMAN_EQUIP)i);
		if(pItem)
		{
			//创建新的装备的action item
			GetMe()->UpdateAction_FromItem(pItem);
		}
	}
}


//摆摊（出售）
VOID CActionSystem::UserStallSale_Update(VOID)
{
	//清空已经不存在的Action
	GetMe()->CleanInvalidAction();

	for(INT i=0; i<STALL_BOX_SIZE; i++)
	{
		//取得物品
		tObject_Item*	pItem = CDataPool::GetMe()->MyStallBox_GetItem(i);
		if(pItem)
		{
			//设置新的物品数据
			UpdateAction_FromItem(pItem);
		}
	}
}

//摆摊（购买）
VOID CActionSystem::UserStallBuy_Update(VOID)
{
	//清空已经不存在的Action
	GetMe()->CleanInvalidAction();

	for(INT i=0; i<STALL_BOX_SIZE; i++)
	{
		//取得物品
		tObject_Item*	pItem = CDataPool::GetMe()->OtStallBox_GetItem(i);
		if(pItem)
		{
			//设置新的物品数据
			UpdateAction_FromItem(pItem);
		}
	}
}

//聊天动作
VOID CActionSystem::UserChatMood_Update(VOID)
{
	GetMe()->CleanInvalidAction();

	INT i = 0;
	do {
		TALK_ACT_STRUCT* pActStruct = SCRIPT_SANDBOX::Talk::s_Talk.GetTalkActStructByID(i++);
		if(pActStruct)
		{
			UpdateAction_FromChatMood(pActStruct);
		}
		else
		{
			break;
		}
	} while(TRUE);
}

VOID CActionSystem::UserBank_Update(VOID)
{
	//清空已经不存在的Action
	GetMe()->CleanInvalidAction();

	for(INT i=0; i<MAX_BANK_SIZE; i++)
	{
		//取得物品
		tObject_Item*	pItem = CDataPool::GetMe()->UserBank_GetItem(i);
		if(pItem)
		{
			//设置新的物品数据
			UpdateAction_FromItem(pItem);
		}
	}
}

VOID CActionSystem::UserExchangeSelf_Update(VOID)
{
	//清空已经不存在的Action
	GetMe()->CleanInvalidAction();

	for(INT i=0; i<EXCHANGE_BOX_SIZE; i++)
	{
		//取得物品
		tObject_Item*	pItem = CDataPool::GetMe()->MyExBox_GetItem(i);
		if(pItem)
		{
			//设置新的物品数据
			UpdateAction_FromItem(pItem);
		}
	}
}

VOID CActionSystem::UserExchangeOther_Update(VOID)
{
	//清空已经不存在的Action
	GetMe()->CleanInvalidAction();

	for(INT i=0; i<EXCHANGE_BOX_SIZE; i++)
	{
		//取得物品
		tObject_Item*	pItem = CDataPool::GetMe()->OtExBox_GetItem(i);
		if(pItem)
		{
			//设置新的物品数据
			UpdateAction_FromItem(pItem);
		}
	}
}
// 任务物品提交界面的更新
VOID CActionSystem::UserMission_Update(VOID)
{
	//清空已经不存在的Action
	GetMe()->CleanInvalidAction();
	for(INT i=0; i<MISSION_BOX_SIZE; i++)
	{
		//取得物品
		tObject_Item*	pItem = CDataPool::GetMe()->MissionBox_GetItem(i);
		if(pItem)
		{
			//设置新的物品数据
			UpdateAction_FromItem(pItem);
		}
	}
}

// 玩家商店的更新
VOID CActionSystem::UserPS_Self_Update(VOID)
{
	//清空已经不存在的Action
	GetMe()->CleanInvalidAction();
	for(INT k=0; k<10; k++)
	{
		for(INT i=0; i<STALL_BOX_SIZE; i++)
		{
			//取得物品
			tObject_Item*	pItem = CDataPool::GetMe()->PlayerShop_GetItem(TRUE,k,i);  
			if(pItem)
			{
				//设置新的物品数据
				UpdateAction_FromItem(pItem);
			}
		}
	}
}

// 玩家商店的更新
VOID CActionSystem::UserPS_Other_Update(VOID)
{
	//清空已经不存在的Action
	GetMe()->CleanInvalidAction();
	for(INT k=0; k<10; k++)
	{
		for(INT i=0; i<STALL_BOX_SIZE; i++)
		{
			//取得物品
			tObject_Item*	pItem = CDataPool::GetMe()->PlayerShop_GetItem(FALSE,k,i);  
			if(pItem)
			{
				//设置新的物品数据
				UpdateAction_FromItem(pItem);
			}
		}
	}
}

VOID CActionSystem::ItemBox_Update(VOID)
{
	GetMe()->CleanInvalidAction();
	//创建新的物品
	for(INT i=0; i<MAX_BOXITEM_NUMBER; i++)
	{
		//取得物品
		tObject_Item* pItem = CDataPool::GetMe()->ItemBox_GetItem(i);
		if(!pItem) continue;

		UpdateAction_FromItem(pItem);
	}
}

VOID CActionSystem::ItemBox_Created(INT nObjId)
{
	//清空原有ItemBox中的所有物品Action
	GetMe()->CleanInvalidAction(true);
	//创建新的物品
	for(INT i=0; i<MAX_BOXITEM_NUMBER; i++)
	{
		//取得物品
		tObject_Item* pItem = CDataPool::GetMe()->ItemBox_GetItem(i);
		if(!pItem) continue;

		UpdateAction_FromItem(pItem);
	}

	//产生事件打开UI箱子
	CGameProcedure::s_pEventSystem->PushEvent(GE_LOOT_OPENED,nObjId);
}

VOID CActionSystem::_OnSkillActive(const EVENT* pEvent, UINT_PTR dwOwnerData)
{
	//取得技能id
	INT idSkill = atoi(pEvent->vArg[0].c_str());
	//技能Action
	CActionItem_Skill* pSkillItem = (CActionItem_Skill*)GetMe()->GetAction(idSkill);
	if(!pSkillItem) return;

	//检查是否是能够自动进行的技能
	pSkillItem->AutoKeepOn();
}

VOID CActionSystem::UpdateAction_FromSkill(const SCLIENT_SKILL* pSkill)
{
	TDAssert(pSkill);

	//检查时候已经有该操作
	CActionItem_Skill* pSkillAction = (CActionItem_Skill*)GetAction_SkillID(pSkill->m_pDefine->m_nID*100 + pSkill->m_nLevel);
	
	//AxTrace(0, 0, "Skill:%d", pSkill->m_pDefine->m_dwID);
	//如果没有,创建
	if(!pSkillAction)
	{
		pSkillAction = new CActionItem_Skill(_CreateID());
		pSkillAction->Update_Skill(pSkill);
		//INT nPos = pSkillAction->GetPosIndex();
		//加入
		m_mapAllAction[pSkillAction->GetID()] = pSkillAction;
		UpdateToolBar();

		//如果有上次存的默认技能，则设置为它。
		if( pSkill->m_pDefine->m_nID*100 + pSkill->m_nLevel == CGameProcedure::s_pVariableSystem->GetAs_Int("DefaultSkill") )
		{
			CGameInterface::GetMe()->Skill_SetActive(pSkillAction);
		}
	}
	else
	{
		pSkillAction->Update_Skill(pSkill);
	}

}

VOID CActionSystem::UpdateAction_FromPetSkill(INT nPetNum,const PET_SKILL* pSkill)
{
	TDAssert(pSkill);

	//检查时候已经有该操作

	CActionItem_PetSkill* pSkillAction = (CActionItem_PetSkill*)GetAction_PetSkillID(nPetNum,pSkill->m_pDefine->m_nID);
	
	//AxTrace(0, 0, "Skill:%d", pSkill->m_pDefine->m_dwID);
	//如果没有,创建
	if(!pSkillAction)
	{
		pSkillAction = new CActionItem_PetSkill(_CreateID());
		pSkillAction->Update_PetSkill(pSkill);
		//加入
		m_mapAllAction[pSkillAction->GetID()] = pSkillAction;
		UpdateToolBar();
	}
	else
	{
		pSkillAction->Update_PetSkill(pSkill);
		UpdateToolBar();
	}
}

VOID CActionSystem::UpdateAction_FromPetSkillStudy(const PET_SKILL* pSk)
{
	TDAssert(pSk);

	//检查时候已经有该操作

	CActionItem_PetSkill* pSkillAction = (CActionItem_PetSkill*)GetAction_PetSkillID(pSk->m_nPetNum,pSk->m_pDefine->m_nID);
	
	//AxTrace(0, 0, "Skill:%d", pSkill->m_pDefine->m_dwID);
	//如果没有,创建
	if(!pSkillAction)
	{
		pSkillAction = new CActionItem_PetSkill(_CreateID());
		pSkillAction->Update_PetSkill(pSk);
		//加入
		m_mapAllAction[pSkillAction->GetID()] = pSkillAction;
	}
	else
	{
		pSkillAction->Update_PetSkill(pSk);
	}
}

VOID CActionSystem::UpdateAction_FromLifeAbility(const SCLIENT_LIFEABILITY* pLifeAbility)
{
	TDAssert(pLifeAbility);

	//如果没有学会的技能，退出
	if(pLifeAbility->m_nLevel <= 0) return;

	if(pLifeAbility->m_pDefine == NULL)
		return;

	//检查时候已经有该操作
	CActionItem_LifeAbility* pLifeAbilityAction = (CActionItem_LifeAbility*)GetAction_LifeAbilityID(pLifeAbility->m_pDefine->nID);

	//如果没有,创建
	if(!pLifeAbilityAction)
	{
		pLifeAbilityAction = new CActionItem_LifeAbility(_CreateID());
		pLifeAbilityAction->Update_LifeAbility(pLifeAbility);
		//加入
		m_mapAllAction[pLifeAbilityAction->GetID()] = pLifeAbilityAction;
//		UpdateToolBar();
	}
}

VOID CActionSystem::UpdateAction_FromItem(tObject_Item* pItem)
{
	TDAssert(pItem);

	//检查时候已经有该操作
	CActionItem_Item* pItemAction = (CActionItem_Item*)GetAction_ItemID(pItem->GetID());

	//如果没有,创建
	if(!pItemAction)
	{
		pItemAction = new CActionItem_Item(_CreateID());
		pItemAction->Update_Item(pItem);
		
		//加入链表
		m_mapAllAction[pItemAction->GetID()] = pItemAction;
		UpdateToolBar();
	}
	//如果有，更新
	else
	{
		pItemAction->Update_Item(pItem);
		for(INT i=0; i<(INT)m_barMain.size(); i++)
		{
			ACTIONBAR_ITEM& barItem = m_barMain[i];

			if(barItem.idImpl == pItem->GetIdTable())
			{
				MainMenuBar_Set(i,pItemAction->GetID());
			}
		}
	}
}

VOID CActionSystem::UpdateAction_FromSkillClass(const SCLIENT_SKILLCLASS* pSkillClass)
{
	//检查时候已经有该操作
	CActionItem_XinFa* pSkillClassAction = (CActionItem_XinFa*)GetAction_SkillClass(pSkillClass->m_pDefine->nID);

	//如果没有,创建
	if(!pSkillClassAction)
	{
		pSkillClassAction = new CActionItem_XinFa(_CreateID());
		m_mapAllAction[pSkillClassAction->GetID()] = pSkillClassAction;
	}

	pSkillClassAction->Update_SkillClass(pSkillClass);
}

VOID CActionSystem::UpdateAction_FromChatMood(const TALK_ACT_STRUCT* pActStruct)
{
	CActionItem_ChatMood* pChatMood = (CActionItem_ChatMood*)GetAction_ChatMoodID(pActStruct->m_actIdx);

	if(!pChatMood)
	{
		pChatMood = new CActionItem_ChatMood(_CreateID());
		pChatMood->Update_ChatMood(pActStruct);

		m_mapAllAction[pChatMood->GetID()] = pChatMood;
		UpdateToolBar();
	}
	else
	{
		pChatMood->Update_ChatMood(pActStruct);
		UpdateToolBar();
	}
}

VOID CActionSystem::EraseActionItem(CActionItem* pItem)
{
	if(!pItem) return;
	//从总表中删除
	m_mapAllAction.erase(m_mapAllAction.find(pItem->GetID()));

	delete pItem;
	//...不能再调用pItem任何代码
}

INT CActionSystem::_CreateID(VOID) const
{
	static INT idNow = 1;
	return idNow++;
}

INT CActionSystem::GetActionNum(LPCTSTR szType)
{
    if(CysModernGame::IsActive()){if(!_stricmp(szType,"xiulianbook"))return 3;if(!_stricmp(szType,"xiulianmiji"))return 15;}
	INT nNum = 0;

	if(_stricmp(szType, NAMETYPE_PACKAGEITEM) == 0) 
		return CYS_CLIENT_BAG_SLOTS;
	else if(_stricmp(szType, NAMETYPE_LOOTITEM) == 0) 
		return CDataPool::GetMe()->ItemBox_GetNumber();
	else if(_stricmp(szType, NAMETYPE_BANKITEM) == 0)
	{
		std::map< INT, CActionItem* >::iterator it;
		for(it=m_mapAllAction.begin(); it!=m_mapAllAction.end(); it++)
		{
			if(_stricmp(it->second->GetType_String(), szType) == 0) 
				nNum++;
		}

		return nNum;
	}
	else if(_stricmp(szType, NAMETYPE_EXCHANGESELF) == 0)
	{
		std::map< INT, CActionItem* >::iterator it;
		for(it=m_mapAllAction.begin(); it!=m_mapAllAction.end(); it++)
		{
			if(_stricmp(it->second->GetType_String(), szType) == 0) 
				nNum++;
		}

		return nNum;
	}
	else if(_stricmp(szType, NAMETYPE_STALLSELF) == 0)
	{
		std::map< INT, CActionItem* >::iterator it;
		for(it=m_mapAllAction.begin(); it!=m_mapAllAction.end(); it++)
		{
			if(_stricmp(it->second->GetType_String(), szType) == 0) 
				nNum++;
		}

		return nNum;
	}
	else if(_stricmp(szType, NAMETYPE_STALLOTHER) == 0)
	{
		std::map< INT, CActionItem* >::iterator it;
		for(it=m_mapAllAction.begin(); it!=m_mapAllAction.end(); it++)
		{
			if(_stricmp(it->second->GetType_String(), szType) == 0) 
				nNum++;
		}

		return nNum;
	}
	else if(_stricmp(szType, NAMETYPE_STALLOTHER) == 0)
	{
		std::map< INT, CActionItem* >::iterator it;
		for(it=m_mapAllAction.begin(); it!=m_mapAllAction.end(); it++)
		{
			if(_stricmp(it->second->GetType_String(), szType) == 0) 
				nNum++;
		}

		return nNum;
	}

	else
	{
		std::map< INT, CActionItem* >::iterator it;
		for(it=m_mapAllAction.begin(); it!=m_mapAllAction.end(); it++)
		{
			CActionItem* aa = it->second;
			if(_stricmp(it->second->GetType_String(), szType) == 0) 
				nNum++;
		}

		return nNum;
	}
}


VOID CActionSystem::MainMenuBar_Set(INT nIndex, INT idAction)
{
	if(!CysQuickbarContract::IsSlot(nIndex)) return;

	if(idAction == INVALID_ID)
	{
		m_barMain[nIndex].typeItem = AOT_EMPTY;
		m_barMain[nIndex].idImpl = INVALID_ID;
		m_barMain[nIndex].idActionItem = INVALID_ID;

		UpdateToolBar();
	}
	
	CActionItem* pItem = (CActionItem*)GetAction(idAction);
	if(pItem)
	{

		switch(pItem->GetType())
		{
		case AOT_SKILL:
			{
				const SCLIENT_SKILL* pSkill = (const SCLIENT_SKILL*)pItem->GetImpl();
				if(!pSkill) break;

				m_barMain[nIndex].typeItem = AOT_SKILL;
				m_barMain[nIndex].idImpl = pSkill->m_pDefine->m_nID*100 + pSkill->m_nLevel;
				m_barMain[nIndex].idActionItem = INVALID_ID;
			}
			break;
		case AOT_ITEM:
			{
				const CObject_Item* pItemInfo = (const CObject_Item*)(const tObject_Item*)pItem->GetImpl();
				if(!pItemInfo) break;

				m_barMain[nIndex].typeItem = AOT_ITEM;
				m_barMain[nIndex].idImpl = pItemInfo->GetIdTable();
				m_barMain[nIndex].idActionItem = INVALID_ID;

			}
			break;
		case AOT_PET_SKILL:
			{
				const PET_SKILL* pPetSkill = (const PET_SKILL*)pItem->GetImpl();
				if(!pPetSkill) break;

				m_barMain[nIndex].typeItem = AOT_PET_SKILL;
				m_barMain[nIndex].idImpl = pPetSkill->m_pDefine->m_nID;
				m_barMain[nIndex].idPetIndex = pPetSkill->m_nPetNum;
				m_barMain[nIndex].idActionItem = INVALID_ID;
			}
			break;
		case AOT_CHATMOOD:
			{
				const TALK_ACT_STRUCT* pActStruct = (const TALK_ACT_STRUCT*)pItem->GetImpl();
				if(!pActStruct) break;

				m_barMain[nIndex].typeItem = AOT_CHATMOOD;
				m_barMain[nIndex].idImpl = pActStruct->m_actIdx;
				m_barMain[nIndex].idActionItem = INVALID_ID;
			}
			break;
		default:
			break;
		}

		UpdateToolBar();
	}
	ACTIONBAR_ITEM& barItem = m_barMain[nIndex];

	tActionItem* pActionItem = NULL;
	CGModifySetting msg;
	_OWN_SETTING* pSend_Value = msg.GetValue();

	switch(barItem.typeItem)
		{
		case AOT_PET_SKILL:
			pActionItem = GetAction_PetSkillID(barItem.idPetIndex,barItem.idImpl);
			msg.SetType(CysQuickbarContract::TaggedSlot(nIndex));
			pSend_Value->m_SettingType = barItem.typeItem;
			pSend_Value->m_SettingData = (barItem.idPetIndex << 16) + barItem.idImpl;

			CNetManager::GetMe()->SendPacket( &msg );
			break;

		case AOT_SKILL:
			pActionItem = GetAction_SkillID(barItem.idImpl);
			msg.SetType(CysQuickbarContract::TaggedSlot(nIndex));
			pSend_Value->m_SettingType = barItem.typeItem;
			pSend_Value->m_SettingData = barItem.idImpl;

			CNetManager::GetMe()->SendPacket( &msg );
			break;

		case AOT_SKILL_LIFEABILITY:
			break;

		case AOT_ITEM:
			pActionItem = GetAction_ItemIDTable_FromMyPacket(barItem.idImpl);
			if(pActionItem)
			{
				barItem.idItemCount = CDataPool::GetMe()->UserBag_CountItemByIDTable(barItem.idImpl);
			}
			else
			{
				barItem.idItemCount = 0; // retain item type across inventory refreshes
			}

			msg.SetType(CysQuickbarContract::TaggedSlot(nIndex));
			pSend_Value->m_SettingType = barItem.typeItem;
			pSend_Value->m_SettingData = barItem.idImpl;

			CNetManager::GetMe()->SendPacket( &msg );
			break;

		case AOT_XINFA:
			break;

		case AOT_EMPTY:
			msg.SetType(CysQuickbarContract::TaggedSlot(nIndex));
			pSend_Value->m_SettingType = barItem.typeItem;
			pSend_Value->m_SettingData = barItem.idImpl;

			CNetManager::GetMe()->SendPacket( &msg );
			break;

		default:
			break;
		}
}



VOID CActionSystem::MainMenuBar_SetID(INT nIndex, INT idType,INT idData)
{
	if(!CysQuickbarContract::IsSlot(nIndex)) return;

	if(idType == INVALID_ID)
	{
		m_barMain[nIndex].typeItem = AOT_EMPTY;
		m_barMain[nIndex].idImpl = INVALID_ID;
		m_barMain[nIndex].idActionItem = INVALID_ID;

		UpdateToolBar();
		return;
	}

	switch(idType)
	{
	case AOT_SKILL:
		{
			m_barMain[nIndex].typeItem = AOT_SKILL;
			m_barMain[nIndex].idImpl = idData;
			m_barMain[nIndex].idActionItem = INVALID_ID;
		}
		break;
	case AOT_ITEM:
		{
			m_barMain[nIndex].typeItem = AOT_ITEM;
			m_barMain[nIndex].idImpl = idData;
			m_barMain[nIndex].idActionItem = INVALID_ID;

		}
		break;
	case AOT_PET_SKILL:
		{
			m_barMain[nIndex].typeItem = AOT_PET_SKILL;
			m_barMain[nIndex].idImpl = idData & 0xFFFF;
			m_barMain[nIndex].idActionItem = INVALID_ID;
			m_barMain[nIndex].idPetIndex = (idData >> 16) & 0xFFFF;
		}
		break;

	default:
		break;
	}
	
//	if(nIndex == 9)
//		m_bIsInitalDone = TRUE;

	UpdateToolBar();
}


INT CActionSystem::MainMenuBar_Get(INT nIndex)
{
	if(!CysQuickbarContract::IsSlot(nIndex)) return -1;

	return m_barMain[nIndex].idActionItem;
}

VOID CActionSystem::UserBag_Set(INT nIndex, INT idAction)
{
	if(nIndex < 0 || nIndex > 20) return;

	CActionItem* pItem = (CActionItem*)GetAction(idAction);
	if(!pItem) return;

	switch(pItem->GetType())
	{
	case AOT_ITEM:
		{
			CDataPool::GetMe()->UserBag_SetItem(nIndex, (tObject_Item*)pItem->GetImpl());
		}
		break;

	default:
		break;
	}
}

VOID CActionSystem::UpdateToolBar(VOID)
{
	// 保存MainMenuBar上修改过的快捷键
	///////////////////////////////////////////////
	STRING szTemp = "";
	STRING szRightTemp = "";
	INT nPet_Num =-1;
	///////////////////////////////////////////////

	//MainMenu Bar
	for(INT i=0; i<(INT)m_barMain.size(); i++)
	{
		ACTIONBAR_ITEM& barItem = m_barMain[i];

		//如果尚未引用
		if(	barItem.idActionItem == INVALID_ID || 
			NULL==GetAction(barItem.idActionItem) || 
			barItem.typeItem == AOT_PET_SKILL || barItem.typeItem == AOT_ITEM)
		{
			//查询是否可以引用
			tActionItem* pActionItem = NULL;

			switch(barItem.typeItem)
			{
			case AOT_PET_SKILL:
				pActionItem = GetAction_PetSkillID(barItem.idPetIndex,barItem.idImpl);
				///////////////////////////////////////////////////
				//要是以后策划改主意了，就把这段注释掉。
/*				nPet_Num = pActionItem->GetNum();
				if(nPet_Num >= 0 && nPet_Num < HUMAN_PET_MAX_COUNT )
				{
					SDATA_PET* My_Pet = CDataPool::GetMe()->Pet_GetPet(nPet_Num);
					if(My_Pet->m_GUID != CObjectManager::GetMe()->GetMySelf()->GetCharacterData()->Get_CurrentPetGUID() )
					{
						MainMenuBar_Set(i,INVALID_ID);
						return;
					}
				}
*/				////////////////////////////////////////////////////			
				break;
			case AOT_SKILL:
				pActionItem = GetAction_SkillID(barItem.idImpl);
				break;
			case AOT_SKILL_LIFEABILITY:
				break;
			case AOT_ITEM:
				pActionItem = GetAction_ItemIDTable_FromMyPacket(barItem.idImpl);
				if(pActionItem)
				{
					barItem.idItemCount = CDataPool::GetMe()->UserBag_CountItemByIDTable(barItem.idImpl);
				}
				else
				{
					barItem.idItemCount = 0; // retain item type across inventory refreshes
				}
				break;
			case AOT_XINFA:
				break;

			case AOT_EMPTY:
				break;
			case AOT_CHATMOOD:
				pActionItem = GetAction_ChatMoodID(barItem.idImpl);
				break;
			default:
				break;
			}

			INT idAction;
			
			if(pActionItem)
			{
				barItem.idActionItem = pActionItem->GetID();
				idAction = pActionItem->GetID();
			}
			else
			{
				barItem.idActionItem = INVALID_ID;
				idAction = INVALID_ID;
			}

			//可以引用了，给UI发送事件
			CHAR szTemp[32];
			std::vector< STRING > vParam;
			vParam.push_back("main");

			_snprintf(szTemp, 32, "%d", i+1);	//Lua数组以1起始
			vParam.push_back(szTemp);

			_snprintf(szTemp, 32, "%d", idAction);
			vParam.push_back(szTemp);

			if(idAction != INVALID_ID && barItem.typeItem == AOT_PET_SKILL)
			{
//				_snprintf(szTemp, 32, "%d", pActionItem->GetNum());//以后策划要是变想法了，就把这句恢复回来。
				_snprintf(szTemp, 32, "%d", INVALID_ID);
				vParam.push_back(szTemp);
			}
			else
			{
				_snprintf(szTemp, 32, "%d", INVALID_ID);
				vParam.push_back(szTemp);
			}

			CEventSystem::GetMe()->PushEvent(GE_CHANGE_BAR, vParam);
		}
	}
}

VOID CActionSystem::UpdateToolBarForPetSkill(VOID)
{
	CleanInvalidAction();
	for(INT i=0; i<(INT)m_barMain.size(); i++)
	{
		ACTIONBAR_ITEM& barItem = m_barMain[i];

		if(	barItem.typeItem == AOT_PET_SKILL)
		{
			//查询是否可以引用
			tActionItem* pActionItem = NULL;

			pActionItem = GetAction_PetSkillID(barItem.idPetIndex,barItem.idImpl);
			if(!pActionItem)
			{
				MainMenuBar_Set(i,INVALID_ID);
				continue;
			}
///////////////////////////////////////////////////
			//要是以后策划改主意了，就把这段注释掉。
			INT nPet_Num = pActionItem->GetNum();
			if(nPet_Num >= 0 && nPet_Num < HUMAN_PET_MAX_COUNT )
			{
				SDATA_PET* My_Pet = CDataPool::GetMe()->Pet_GetPet(nPet_Num);
				if(My_Pet->m_GUID != CObjectManager::GetMe()->GetMySelf()->GetCharacterData()->Get_CurrentPetGUID() )
				{
					MainMenuBar_Set(i,INVALID_ID);
					continue;
				}
			}
		
////////////////////////////////////////////////////			
			INT idAction;
			
			if(pActionItem)
			{
				barItem.idActionItem = pActionItem->GetID();
				idAction = pActionItem->GetID();
			}
			else
			{
				idAction = INVALID_ID;
				MainMenuBar_Set(i,INVALID_ID);
			}

			//可以引用了，给UI发送事件
			CHAR szTemp[32];
			std::vector< STRING > vParam;
			vParam.push_back("main");

			_snprintf(szTemp, 32, "%d", i+1);	//Lua数组以1起始
			vParam.push_back(szTemp);

			_snprintf(szTemp, 32, "%d", idAction);
			vParam.push_back(szTemp);
			
			if(idAction != INVALID_ID)
			{
//				_snprintf(szTemp, 32, "%d", pActionItem->GetNum());
// 以后策划要是变想法了，就把上面这句恢复回来。把下面那句注释起来。
				_snprintf(szTemp, 32, "%d", INVALID_ID);
			}
			else
			{
				_snprintf(szTemp, 32, "%d", INVALID_ID);
				vParam.push_back(szTemp);
			}

			CEventSystem::GetMe()->PushEvent(GE_CHANGE_BAR, vParam);
		}

	}
	return;
}
//枚举所有Action
// Display-only bag skills: no learned-skill object, cast, or toolbar operation.
class CysCultivationAction : public CActionItem {
    bool book; int position; std::string desc;
public:
    CysCultivationAction(int id,int pos,bool b):CActionItem(id),book(b),position(pos){
        auto read=b?CysPowerNet::BookText:CysPowerNet::MiJiText;
        const char* n=read(pos,0);const char* i=read(pos,2);const char* d=read(pos,1);
        m_strName=n?n:"";m_strIconName=i?i:"";desc=d?d:"";
    }
    virtual LPCTSTR GetType_String(){return book?"xiulianbook":"xiulianmiji";}
    virtual INT GetPosIndex(){return position;}
    virtual INT GetDefineID(){return position;}
    virtual LPCTSTR GetDesc(){return desc.c_str();}
};
class CysKfsPreviewAction : public CActionItem {
    int position,skill;
public:
    CysKfsPreviewAction(int id,int pos):CActionItem(id),position(pos),skill(-1){}
    void Set(int sid,const std::string& name,const std::string& icon){skill=sid;m_strName=name;m_strIconName=icon;UpdateToRefrence();}
    virtual LPCTSTR GetType_String(){return "kfsskill";}
    virtual INT GetPosIndex(){return position;}
    virtual INT GetDefineID(){return skill;}
    virtual LPCTSTR GetDesc(){return m_strName.c_str();}
};
class CysZhenfaPreviewAction:public CActionItem {
    int skill;
public:
    CysZhenfaPreviewAction(int id,const _DBC_SKILL_DATA& def):CActionItem(id),skill(def.m_nID){m_strName=def.m_lpszName;m_strIconName=def.m_lpszIconName;}
    virtual LPCTSTR GetType_String(){return "zhenfaskill";}
    virtual INT GetPosIndex(){return skill;}
    virtual INT GetDefineID(){return skill;}
    virtual LPCTSTR GetDesc(){return m_strName.c_str();}
};
tActionItem* CActionSystem::EnumAction(INT nPosIndex, LPCTSTR szFilter)
{
    if(CysModernGame::IsActive() && (!_stricmp(szFilter,"xiulianbook")||!_stricmp(szFilter,"xiulianmiji"))) {
        bool book=!_stricmp(szFilter,"xiulianbook");if(nPosIndex<0||nPosIndex>=(book?3:15))return nullptr;
        for(auto& entry:m_mapAllAction)if(!_stricmp(entry.second->GetType_String(),szFilter)&&entry.second->GetPosIndex()==nPosIndex)return entry.second;
        auto action=new CysCultivationAction(_CreateID(),nPosIndex,book);m_mapAllAction[action->GetID()]=action;return action;
    }

    if(CysModernGame::IsActive() && _stricmp(szFilter,"zhenfaskill")==0) {
        for(auto& entry:m_mapAllAction)if(_stricmp(entry.second->GetType_String(),"zhenfaskill")==0&&entry.second->GetPosIndex()==nPosIndex)return entry.second;
        DBC_DEFINEHANDLE(table, DBC_SKILL_DATA);
        const auto def=table?(const _DBC_SKILL_DATA*)table->Search_Index_EQU(nPosIndex):nullptr;
        if(!def)return NULL;
        auto preview=new CysZhenfaPreviewAction(_CreateID(),*def);m_mapAllAction[preview->GetID()]=preview;return preview;
    }
	if(CysModernGame::IsActive() && _stricmp(szFilter,"kfsskill")==0) {
		int skill;std::string name,icon;
		if(!CysEquipmentSkills::Preview(nPosIndex,skill,name,icon))return NULL;
		CysKfsPreviewAction* preview=NULL;
		for(auto& entry:m_mapAllAction)if(_stricmp(entry.second->GetType_String(),"kfsskill")==0 && entry.second->GetPosIndex()==nPosIndex)
			preview=static_cast<CysKfsPreviewAction*>(entry.second);
		if(!preview){preview=new CysKfsPreviewAction(_CreateID(),nPosIndex);m_mapAllAction[preview->GetID()]=preview;}
		preview->Set(skill,name,icon);return preview;
	}
	int SkillIndex = -1;
	std::map< INT, CActionItem* >::iterator it;
	for(it=m_mapAllAction.begin(); it!=m_mapAllAction.end(); it++)
	{
		if(_stricmp(it->second->GetType_String(), szFilter) == 0) 
		{
			if (_stricmp("skill", szFilter) == 0)
			{
				SkillIndex ++;
				if (SkillIndex == nPosIndex)
				{
					return it->second;
				}
			}else
			{
				if(it->second->GetPosIndex() == nPosIndex)  
					return it->second;
			}
		}		
	}

	return NULL;
}

tActionItem* CActionSystem::EnumPetSkill(INT nPetIndex, INT nPetSkill, LPCTSTR szFilter)
{
//	GetMe()->CleanInvalidAction();
	UserTargetPetSkill_Update();

	std::map< INT, CActionItem* >::iterator it;
	for(it=m_mapAllAction.begin(); it!=m_mapAllAction.end(); it++)
	{
		if(_stricmp(it->second->GetType_String(), szFilter) == 0) 
		{
			if(it->second->GetPosIndex() == nPetSkill && it->second->GetNum() == nPetIndex)  
				return it->second;
		}		
	}

	return NULL;
}

// CYS: cancellation is distinct from MainMenuBar_DoAction(index, FALSE), which executes.
VOID CActionSystem::MainMenuBar_CancelPrepare(INT nIndex)
{
	if(nIndex < 0 || nIndex >= s_MainMenuBarNum) return;
	CActionItem* item = (CActionItem*)GetAction(m_barMain[nIndex].idActionItem);
	if(item) item->DoActionPrepare(FALSE);
}

VOID CActionSystem::MainMenuBar_DoAction(INT nIndex, BOOL bPrepare)
{
	if(nIndex<0 || nIndex>=s_MainMenuBarNum) return;

	// Resolve again after consuming or moving a stack; never use a different item in its old bag slot.
	if (m_barMain[nIndex].typeItem == AOT_ITEM) UpdateToolBar();

	ACTIONBAR_ITEM& item = m_barMain[nIndex];

	//尚未设定
	CActionItem* pItem = (CActionItem*)GetAction(item.idActionItem);
	if(!pItem) return;
	if (!bPrepare && getenv("CYS_QUICKBAR_LIVE")) TDU_Log("CYS-QUICKBAR: dispatch slot=%d define=%d type=%d", nIndex, pItem->GetDefineID(), pItem->GetType());

	if(bPrepare)
	{
		//显示Check
		pItem->DoActionPrepare(true);
	}
	else
	{
		//如果有交易，摆摊，玩家商店界面开着，不能执行
		// 如果交易界面开着
		if(CGameProcedure::s_pUISystem && CGameProcedure::s_pUISystem->IsWindowShow("Exchange"))
		{
			CEventSystem::GetMe()->PushEvent(GE_NEW_DEBUGMESSAGE, "你现在无法这样做");
			return ;
		}
		//如果摆摊界面开着
		if(CGameProcedure::s_pUISystem && CGameProcedure::s_pUISystem->IsWindowShow("StallSale"))
		{
			CEventSystem::GetMe()->PushEvent(GE_NEW_DEBUGMESSAGE, "你现在无法这样做");
			return ;
		}
		//如果玩家商店界面开着
		if(CGameProcedure::s_pUISystem && CGameProcedure::s_pUISystem->IsWindowShow("PS_ShopMag"))
		{
			CEventSystem::GetMe()->PushEvent(GE_NEW_DEBUGMESSAGE, "你现在无法这样做");
			return ;
		}

		//隐藏Check
		pItem->DoActionPrepare(FALSE);
		//执行动作
		pItem->DoAction();
	}
}

tActionItem* CActionSystem::GetAction(INT id)
{
	std::map< INT, CActionItem* >::iterator it;

	it = m_mapAllAction.find(id);
	if( it != m_mapAllAction.end() ) return it->second;

	return NULL;
}

// CYS-UIFRAMES: see the comment on the declaration in GMActionSystem.h.
//
// Measured, not guessed: all 958 Lua call sites of DataPool:CreateActionItemForShow /
// CreateBindActionItemForShow were counted (Build/Logs/2026-09-19-ui-frames/scan/actionitem-census.json).
// 957 of 958 take exactly ONE return value and pass exactly TWO arguments, and the whole method
// surface used on the returned value is three names: GetID (2376 uses), GetName (100) and
// GetItemColorInShop (4). GetNum is never called on it, so the second argument (a count) is not
// observable through the object at any call site and is deliberately not stored here.
tActionItem* CActionSystem::CreateActionForShow(UINT idTable)
{
	// already made one for this define id?
	std::map< UINT, INT >::iterator itShow = m_mapCysShowAction.find(idTable);
	if(itShow != m_mapCysShowAction.end())
	{
		tActionItem* pOld = GetAction(itShow->second);
		if(pOld) return pOld;
		m_mapCysShowAction.erase(itShow);	// the action went away; fall through and rebuild
	}

	// CObject_Item::NewItem builds an item object straight from the item tables (it is what the
	// drag-drop copy path in GMActionSystem_Item.cpp already uses), so no server object is needed.
	CObject_Item* pItem = CObject_Item::NewItem(idTable);
	if(!pItem) return NULL;

	// CYS-UIFRAMES, phep canh do NHANH `data-regress` chi ra (20/09):
	// Update_Item lam `m_strName = pItem->GetName()` (GMActionSystem_Item.cpp:64) KHONG kiem NULL
	// chut nao, va `m_strIconName = pItem->GetIconName()` (dong 67) chi kiem NULL. Gan mot LPCTSTR
	// hong vao std::string = strlen tren con tro rac -> vang trong ucrtbase, dung chu ky ma
	// data-regress dang truy. Truoc ban va, duong nay chi chay cho vat pham NGUOI CHOI THUC SU CO
	// (server da xac nhan). Ban va nay mo no ra cho MOI item define id ma 419 khung cua hang nhac
	// toi, tuc no LAM RONG vung phoi nhiem. Nen chan o day: khong co ten hoac khong co icon thi
	// coi nhu khong dung duoc -> tra NULL -> Lua nhan s_InvalidAction -> `GetID() ~= 0` bo qua.
	// (Van khong chan duoc con tro RAC KHAC NULL; do la viec cua dbc-schema-red.)
	if(!pItem->GetName() || !pItem->GetIconName())
	{
		CObject_Item::DestroyItem(pItem);
		return NULL;
	}

	CActionItem_Item* pAction = new CActionItem_Item(_CreateID());
	pAction->Update_Item(pItem);			// copies name + icon off the item - this is what draws
	m_mapAllAction[pAction->GetID()] = pAction;
	m_mapCysShowAction[idTable] = pAction->GetID();
	// NOTE: deliberately no UpdateToolBar() here - a shop icon must not touch the player's bar.
	return pAction;
}

tActionItem* CActionSystem::GetAction_SkillID(INT id)
{
	register std::map< INT, CActionItem* >::iterator it;
	
	for(it=m_mapAllAction.begin(); it!=m_mapAllAction.end(); it++)
	{
		CActionItem* pActionItem = (CActionItem*) it->second;

		//如果是技能
		if(	pActionItem && pActionItem->GetType() == AOT_SKILL)
		{
			const SCLIENT_SKILL* pSkill = (const SCLIENT_SKILL*)pActionItem->GetImpl();
			if(!pSkill) continue;

			if(pSkill->m_pDefine->m_nID*100 + pSkill->m_nLevel == id)	return pActionItem;
		}
	}

	return NULL;
}

tActionItem* CActionSystem::GetAction_PetSkillID(INT nPetNum,INT id)
{
	register std::map< INT, CActionItem* >::iterator it;
	
	for(it=m_mapAllAction.begin(); it!=m_mapAllAction.end(); it++)
	{
		CActionItem* pActionItem = (CActionItem*) it->second;

		//如果是技能
		if(	pActionItem && pActionItem->GetType() == AOT_PET_SKILL)
		{
			const PET_SKILL* pSkill = (const PET_SKILL*)pActionItem->GetImpl();
			if( !pSkill || !pSkill->m_pDefine ) continue;

			if(	pSkill->m_pDefine->m_nID == id &&
				pSkill->m_nPetNum == nPetNum)	
				return pActionItem;

		}
	}

	return NULL;
}

tActionItem* CActionSystem::GetAction_ItemID(INT id)
{
	register std::map< INT, CActionItem* >::iterator it;
	
	for(it=m_mapAllAction.begin(); it!=m_mapAllAction.end(); it++)
	{
		CActionItem* pActionItem = (CActionItem*) it->second;

		//如果是物品
		if(	pActionItem && 
			pActionItem->GetType() == AOT_ITEM )
		{
			tObject_Item* pItem = (tObject_Item* )pActionItem->GetImpl();
			if(pItem && pItem->GetID() == id) return pActionItem;
		}
	}

	return NULL;
}

tActionItem* CActionSystem::GetAction_ItemIDTable_FromMyPacket(INT id)
{
	register std::map< INT, CActionItem* >::iterator it;
	
	for(it=m_mapAllAction.begin(); it!=m_mapAllAction.end(); it++)
	{
		CActionItem* pActionItem = (CActionItem*) it->second;

		//如果是物品
		if(	pActionItem && 
			pActionItem->GetType() == AOT_ITEM )
		{
			tObject_Item* pItem = (tObject_Item* )pActionItem->GetImpl();
			if(pItem && pItem->GetIdTable() == id && pItem->GetTypeOwner() == tObject_Item::IO_MYSELF_PACKET) return pActionItem;
		}
	}

	return NULL;
}

tActionItem* CActionSystem::GetAction_LifeAbilityID(INT idAbility)
{
	register std::map< INT, CActionItem* >::iterator it;
	
	for(it=m_mapAllAction.begin(); it!=m_mapAllAction.end(); it++)
	{
		CActionItem* pActionItem = (CActionItem*) it->second;

		//如果是生活技能
		if(	pActionItem && 
			pActionItem->GetType() == AOT_SKILL_LIFEABILITY )
		{
			const SCLIENT_LIFEABILITY* pAbility = (const SCLIENT_LIFEABILITY*)pActionItem->GetImpl();
			if(pAbility && pAbility->m_pDefine->nID == idAbility) return pActionItem;
		}
	}

	return NULL;
}

tActionItem* CActionSystem::GetAction_SkillClass(INT idXinFa)
{
	register std::map< INT, CActionItem* >::iterator it;
	
	for(it=m_mapAllAction.begin(); it!=m_mapAllAction.end(); it++)
	{
		CActionItem* pActionItem = (CActionItem*) it->second;

		//如果是生活技能
		if(	pActionItem && 
			pActionItem->GetType() == AOT_XINFA )
		{
			const SCLIENT_SKILLCLASS* pSkillCLass = (const SCLIENT_SKILLCLASS*)pActionItem->GetImpl();
			if(pSkillCLass && pSkillCLass->m_pDefine->nID == idXinFa) return pActionItem;
		}
	}

	return NULL;
}

tActionItem* CActionSystem::GetAction_ChatMoodID(INT idAct)
{
	register std::map< INT, CActionItem* >::iterator it;

	for(it=m_mapAllAction.begin(); it!=m_mapAllAction.end(); it++)
	{
		CActionItem* pActionItem = (CActionItem*) it->second;

		//如果是聊天动作
		if(	pActionItem && 
			pActionItem->GetType() == AOT_CHATMOOD )
		{
			const TALK_ACT_STRUCT* pActStruct = (const TALK_ACT_STRUCT*)pActionItem->GetImpl();
			if(pActStruct && pActStruct->m_actIdx == idAct) return pActionItem;
		}
	}

	return NULL;
}

VOID CActionSystem::UpdateCoolDown(INT nCoolDownID)
{
	register std::map< INT, CActionItem* >::iterator it;
	
	for(it=m_mapAllAction.begin(); it!=m_mapAllAction.end(); it++)
	{
		CActionItem* pActionItem = (CActionItem*) it->second;

		//如果是相应冷却组的Action
		if(	pActionItem && pActionItem->GetCoolDownID() == nCoolDownID )
		{
			pActionItem->UpdateCoolDown();
		}
	}
}

VOID CActionSystem::UpdateCommonCoolDown(INT nSkillID)
{

	register std::map< INT, CActionItem* >::iterator it;

	INT nCommonCoolDown = CDataPool::GetMe()->CommonCoolDown_Get();
	if( nCommonCoolDown > 0 ) return;
	CDataPool::GetMe()->CommonCoolDown_Update();

	for(it=m_mapAllAction.begin(); it!=m_mapAllAction.end(); it++)
	{
		CActionItem* pActionItem = (CActionItem*) it->second;
		
		//如果是相应冷却组的Action
		if(	pActionItem && (pActionItem->GetCoolDownID() != INVALID_ID) )
		{
			if(INVALID_ID != nSkillID && pActionItem->GetDefineID() == nSkillID && pActionItem->GetType_String() == NAMETYPE_SKILL ) continue;
			pActionItem->UpdateCommonCoolDown();
		}
	}
}


VOID CActionSystem::Booth_Update(VOID)
{
	GetMe()->CleanInvalidAction();

	//创建新的物品
	for(INT i=0; i<MAX_BOOTH_NUMBER; i++)
	{
		//取得物品
		tObject_Item* pItem = CDataPool::GetMe()->Booth_GetItem(i);
		if(!pItem) continue;

		GetMe()->UpdateAction_FromItem(pItem);
	}

	//回购商品刷新
	for(INT i=0; i<MAX_BOOTH_SOLD_NUMBER ; i++)
	{
		//取得物品
		tObject_Item* pItem = CDataPool::GetMe()->Booth_GetSoldItem(i);
		if(!pItem) continue;

		GetMe()->UpdateAction_FromItem(pItem);
	}
}

VOID CActionSystem::QuestLogItem_Update(VOID)
{
	GetMe()->CleanInvalidAction();
	_MISSION_INFO* misInfo = NULL;
	
	//创建新的物品
	for(INT i=0; i < MAX_CHAR_MISSION_NUM; i++)
	{
		const _OWN_MISSION * OwnMission = CUIDataPool::GetMe()->GetMySelfDetailAttrib()->GetMission(i);

		if(!OwnMission)	continue;

		INT scriptId = OwnMission->m_idScript;

		misInfo = &(GetMissionInfo(scriptId));
		if((!misInfo) || (!misInfo->m_bFill)) continue;
		INT max = (INT)misInfo->m_vecQuestRewardItem.size();
		for(INT j=0; j< max; j++)
		{			
			//取得物品
			_MISSION_INFO::QuestRewardItem misItem = misInfo->m_vecQuestRewardItem[j];
			if(		misItem.pItemData->m_nType == MISSION_BONUS_TYPE_ITEM 
				||	misItem.pItemData->m_nType == MISSION_BONUS_TYPE_ITEM_RAND
				||	misItem.pItemData->m_nType == MISSION_BONUS_TYPE_ITEM_RADIO )
			{
				tObject_Item* pItem = misItem.pItemImpl;
				if(!pItem) continue;
				UpdateAction_FromItem(pItem);
			}
		}
	}
	return;
}

tActionItem* CActionSystem::GetTooltipsFocus(void)
{
	return SCRIPT_SANDBOX::SuperTooltips::s_SupperTooltip.GetActionItem();
}

VOID CActionSystem::SetDefaultAction(tActionItem* pDefAction) 
{ 
	if(m_pDefaultAction != pDefAction && m_pDefaultAction)
	{
		((CActionItem*)m_pDefaultAction)->SetDefaultState(FALSE);
	}

	m_pDefaultAction = pDefAction;

	if(m_pDefaultAction)
	{
		((CActionItem*)m_pDefaultAction)->SetDefaultState(TRUE);
	}
}
