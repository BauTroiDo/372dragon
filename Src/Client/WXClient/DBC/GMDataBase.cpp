#include "CysTitleMetadata.h"
#include "StdAfx.h"
#include "GMDataBase.h"
#include "TDException.h"
#include "TDUtil.h"
#include "TLBB_DBC.h"
#include "GameStruct_Skill.h"	// CYS: record structs of the skill/impact/bullet tables (sizeof in the table list)
#include "../Global.h"
#include "../Procedure/GameProcedure.h"
#include "TDResourceProvider.h"
#include "../WxRender/ResourceProvider.h"

//============================================================================
CDataBase::CDataBase(INT id)
{
	m_pFileDBC = new DBC::DBCFile(id);
}

CDataBase::~CDataBase()
{
	delete m_pFileDBC;
}

const tDataBase::DBC_FIELD* CDataBase::Search_Index_EQU(INT iIndexValue) const 
{
	return (DBC_FIELD*)m_pFileDBC->Search_Index_EQU(iIndexValue);
}

const tDataBase::DBC_FIELD* CDataBase::Search_LineNum_EQU(INT iLineNum) const
{
	return  (DBC_FIELD*)m_pFileDBC->Search_Posistion(iLineNum, 0); 
}

//查找某列等于指定值的第一行
const tDataBase::DBC_FIELD* CDataBase::Search_First_Column_Equ(INT nColumnNum, const DBC_FIELD& value) const
{
	return (DBC_FIELD*)m_pFileDBC->Search_First_Column_Equ(nColumnNum, value.iValue);
}

//取得ID
INT CDataBase::GetID(VOID) const
{
	return m_pFileDBC->GetID(); 
}

//取得列数
UINT CDataBase::GetFieldsNum(VOID)const
{ 
	return m_pFileDBC->GetFieldsNum(); 
}

//取得记录的条数
UINT CDataBase::GetRecordsNum(VOID)const
{ 
	return m_pFileDBC->GetRecordsNum(); 
}

//直接打开一个dbc文件
BOOL CDataBase::Util_OpenDBCFromTxt(LPCTSTR szFileName, DBC::DBCFile* pDBCFile)
{
	TDAssert(szFileName && pDBCFile);

	char* lpAddress = NULL;
	DWORD dwSize = CGameProcedure::s_pResourceProvider->loadResource(szFileName, lpAddress, "General");
	if( dwSize > 0 )
	{
		BOOL bRet = pDBCFile->OpenFromMemory( lpAddress, lpAddress + dwSize + 1, szFileName);	// CYS: name in loader diagnostics
		CGameProcedure::s_pResourceProvider->unloadResource( lpAddress, dwSize );
		return bRet;
	}
	return FALSE;
}

BOOL CDataBase::OpenFromTXT(LPCTSTR szFileName)
{
	return Util_OpenDBCFromTxt(szFileName, m_pFileDBC);
}

//============================================================================
WX_IMPLEMENT_DYNAMIC(CDataBaseSystem, GETCLASS(tDataBaseSystem));
CDataBaseSystem* CDataBaseSystem::s_pMe = NULL;

CDataBaseSystem::CDataBaseSystem()
{
	s_pMe = this;
}

CDataBaseSystem::~CDataBaseSystem()
{
}

VOID CDataBaseSystem::Initial(VOID*)
{
	OpenAllDataBase();
}

VOID CDataBaseSystem::Release(VOID)
{
	CloseAllDataBase();
}

// CYS-CY 14/09 (cs1-tables): the record structs and schema strings follow CY 3.71 (Assets/CanonicalCY/Data, built from
// CYS-CY: S4 = CY 3.71.9609 + the GUI layer of client_GL; Docs/specs/cy-switch_vi.md 3.4, Registry/abi/dbc_columns_cy.tsv).
// CYS-CY: GUI tables follow CY 3.71 as well (user directive 14/09 "Mọi thứ như CY"): InterfaceEx 10 columns; StrDictionary
// CYS-CY: (SS) and StrFilter (ISI) have the same columns in CY and client_GL.
// CYS-CY: HairStyle/CampAndStand do not exist in CY 3.71 (CY Game.exe does not name them). HairStyle: NULL schema, empty
// CYS-CY: table. CampAndStand (cs2-world 14/09): CY keeps the same data under another name - ReputationTable.txt, read
// CYS-CY: by CY Game.exe through GetDataBase(0xbb) into the very TemplateManager_T<U>::InitFromDB of this source
// CYS-CY: (FUN_140784410); DBC_CAMP_AND_STAND now opens that table, so no client_GL table is staged any more.
// CYS 13/09 (game-data): the table list follows client_GL (B), whose data set Assets/Canonical/Data is the target of
// CYS: CY-Source (Docs/specs/game/canonical-data_vi.md). File names are B's (CharModelEx, CharFaceGeo, SceneDefineEx,
// CYS: InterfaceEx, plus EquipBase and ActionSetFile) and every record struct follows the client_GL columns. Each row
// CYS: carries sizeof(record struct) and the column types of the client_GL table (I = INT, F = FLOAT, S = STRING,
// CYS: generated from Canonical). After loading, both are compared with the table; a mismatch is logged as
// CYS: "DBC ERROR" in WXClient.log (the struct overlay would misread that table). Tests/abi/check_dbc_layout.py
// CYS: --strict checks the same rows against the data and the struct layouts offline. A NULL schema marks a 0.85
// CYS: table that client_GL does not have (B does not load it): it is opened empty (0 records, lookups return NULL).
static BOOL _CysOpenEmptyTable(DBC::DBCFile* pDBC)
{
	static const CHAR s_szEmpty[] = "INT\r\nINT\r\n";
	return pDBC->OpenFromMemory(s_szEmpty, s_szEmpty + sizeof(s_szEmpty) - 1);
}

static VOID _CysColumnTypes(const DBC::DBCFile* pDBC, CHAR* szOut, INT nOutSize)
{
	INT n = 0;
	for(INT i = 0; i < pDBC->GetFieldsNum() && n < nOutSize - 1; i++)
	{
		const DBC::DBCFile::FIELD_TYPE eType = pDBC->GetFieldType(i);
		szOut[n++] = (eType == DBC::DBCFile::T_INT) ? 'I' : ((eType == DBC::DBCFile::T_FLOAT) ? 'F' : 'S');
	}
	szOut[n] = '\0';
}

VOID CDataBaseSystem::OpenAllDataBase(VOID)
{
	//所有需要打开的数据库定义
	struct _DATABASE_DEFINE
	{
		INT			idDatabase;
		const CHAR*		pFileName;
		size_t			nRecordSize;	// CYS: sizeof(record struct)
		const CHAR*		pSchema;		// CYS-CY: CY 3.71 column types; NULL = absent from the CY data set
	};

	_DATABASE_DEFINE  s_dbToLoad[] =
	{
		{ DBC_CHARACTER_RACE,	"CharRace.txt",	sizeof(_DBC_CHAR_RACE),	"IIIIIIIIII" },
		{ DBC_CHARACTER_HAIR_GEO,	"CharHairGeo.txt",	sizeof(_DBC_CHAR_HAIR_GEO),	"IISSSSSIIISIII" },
		{ DBC_CHARACTER_HEAD_GEO,	"CharFaceGeo.txt",	sizeof(_DBC_CHAR_HEAD_GEO),	"IISSSIIISIII" },	// B table 103; 0.85: CharHeadGeo.txt
		{ DBC_CHARACTER_ACTION_SET,	"CharActionSet.txt",	sizeof(_DBC_CHAR_ACTION_SET_TABLE),	"ISSSSSSSSS" },
		{ DBC_CHARACTER_MODEL,	"CharModelEx.txt",	sizeof(_DBC_CHARACTER_MODEL),	"ISSFFFFIIIIIIIIIIIIII" },	// 0.85: CharModel.txt
		{ DBC_ACTION_SET_FILE,	"ActionSetFile.txt",	sizeof(_DBC_ACTION_SET_FILE),	"IS" },	// CharModelEx column 9 -> action-set file
		{ DBC_CHARACTER_MOUNT,	"CharMount.txt",	sizeof(_DBC_CHARACTER_MOUNT),	"ISIIFIIISIISSSSSIIIIIIFI" },
		{ DBC_MISSION_LIST,	"MissionList.txt",	sizeof(_DBC_MISSION_LIST),	NULL },	// absent from client_GL (B does not load it): empty table
		{ DBC_MISSION_DATA,	"MissionData.txt",	sizeof(_DBC_MISSION_DATA),	"IIIIII" },
		{ DBC_MISSION_REWARD,	"MissionReward.txt",	sizeof(_DBC_MISSION_REWARD),	NULL },	// absent from client_GL (B does not load it): empty table
		{ DBC_MISSION_PUNISH,	"MissionPunish.txt",	sizeof(_DBC_MISSION_PUNISH),	NULL },	// absent from client_GL (B does not load it): empty table
		{ DBC_MISSION_DIALOG,	"MissionDialog.txt",	sizeof(_DBC_MISSION_DIALOG),	NULL },	// absent from client_GL (B does not load it): empty table
		{ DBC_CHARACTER_EFFECT,	"CharEffect.txt",	sizeof(_DBC_CHARACTER_EFFECT),	"IIIISS" },
		{ DBC_CHARACTER_EXPLEVEL,	"PlayerExpLevel.txt",	sizeof(_DBC_CHARACTER_EXPLEVEL),	"IS" },
		{ DBC_CHARACTER_FACE,	"CharacterFace.txt",	sizeof(_DBC_CHAR_FACE),	"IISIIS" },	// 头像信息
		{ DBC_SYSTEM_COLOR,	"SystemColour.txt",	sizeof(_DBC_SYSTEM_COLOR),	"ISSS" },
		{ DBC_CREATURE_ATT,	"MonsterAttrExTable.txt",	sizeof(_DBC_CREATURE_ATT),	"ISIIFIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIFFFSIIIIIIIIIIIIIIIIIIIIIIIIIIIIII" },
		{ DBC_PET_EX_ATT,	"PetAttrTable.txt",	sizeof(_DBC_PET_EX_ATT),	"ISIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIISIIIIIIIIII" },
		{ DBC_CREATURE_SOUND,	"CreatureSound.txt",	sizeof(_DBC_CREATURE_SOUND),	"IIII" },
		{ DBC_ITEM_VISUAL_CHAR,	"ItemVisualChar.txt",	sizeof(_DBC_ITEM_VISUAL_CHAR),	"ISSSSSSSSSSSSSSSSSSSSSS" },
		{ DBC_ITEM_VISUAL_LOCATOR,	"ItemVisualLocator.txt",	sizeof(_DBC_ITEM_VISUAL_LOCATOR),	"ISSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS" },
		{ DBC_ITEM_EQUIP_DRESS,	"EquipDress.txt",	sizeof(_DBC_ITEM_EQUIP_DRESS),	"IIIIIII" },	// CYS-DRESS: fashion Visual -> ItemVisualChar
		{ DBC_ITEM_EQUIP_BASE,	"EquipBase.txt",	sizeof(_DBC_ITEM_EQUIP_BASE),	"IIIIIIIIIISISSIIIISSIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII" },	// the equipment table B uses
		{ DBC_ITEM_EQUIP_WHITE,	"WhiteEquipBase.txt",	sizeof(_DBC_ITEM_EQUIP_WHITE),	"IIIIIIIIIISISIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIISSIII" },	// legacy: B does not load it
		{ DBC_ITEM_EQUIP_GREEN,	"GreenEquipBase.txt",	sizeof(_DBC_ITEM_EQUIP_GREEN),	"IIIIIIIIIISISIIIIIIISSIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII" },	// legacy: B does not load it
		{ DBC_ITEM_EQUIP_BLUE,	"BlueEquipBase.txt",	sizeof(_DBC_ITEM_EQUIP_BLUE),	"IIIIIIIIIISISIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIISSIII" },	// legacy: B does not load it
		{ DBC_ITEM_MEDIC,	"CommonItem.txt",	sizeof(_DBC_ITEM_MEDIC),	"IIIIISSSIIIIIIIIIIISIIIIIIII" },
		{ DBC_ITEM_GEM,	"GemInfo.txt",	sizeof(_DBC_ITEM_GEM),	"IIIIISISSIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIISSIIIIIII" },
		{ DBC_ITEM_STOREMAP,	"StoreMapItem.txt",	sizeof(_DBC_ITEM_STOREMAP),	"IIIIISSSIIFFIII" },
		{ DBC_ITEM_SETATT,	"EquipSetAttr.txt",	sizeof(_DBC_ITEM_SETATT),	"ISIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII" },
		{ DBC_SOUND_INFO,	"SoundInfo.txt",	sizeof(_DBC_SOUND_INFO),	"ISS" },
		{ DBC_EFFECT_DEFINE,	"EffectDefine.txt",	sizeof(_DBC_EFFECT_DEFINE),	"ISII" },
		{ DBC_SKILL_XINFA,	"XinFa_V1.txt",	sizeof(_DBC_SKILL_XINFA),	"IISSSIFIIIFIFIFIFIFIFIFIFIFIFIFIFIFIF" },
		{ DBC_SKILL_ADDIMPACT,	"SkillAddImpact.txt",	sizeof(_DBC_SKILL_ADDIMPACT),	"ISIISSSSIS" },
		{ DBC_BUFF_IMPACT,	"ImpactSEData_V1.txt",	sizeof(_DBC_BUFF_IMPACT),	"IIISSSSSSSIIIIISSIIIIIISISII" },
		{ DBC_DIRECTLY_IMPACT,	"ImpactDirectly.txt",	sizeof(_DBC_DIRECT_IMPACT),	"ISSSISSSISSSISSSISSSISSSI" },
		{ DBC_BULLET_DATA,	"Bullet.txt",	sizeof(_DBC_BULLET_DATA),	"IIISSFSSSIIIISIS" },
		{ DBC_SKILL_DATA,	"SkillTemplate_V1.txt",	sizeof(_DBC_SKILL_DATA),	"IISSIIIIIIIIIISSSSSIIIIIIIIIIIIISIIFIIIIIIIFIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIISIFIIIIIIIIIIIIFIIIFIII" },
		{ DBC_SKILL_DEPLETE,	"SkillDeplete.txt",	sizeof(_DBC_SKILL_DEPLETE),	"IIIIII" },
		{ DBC_SPECIAL_OBJ_DATA,	"SpecialObjData.txt",	sizeof(_DBC_SPECIAL_OBJ_DATA),	"ISSIIIIISISISIIIIIIIFFIIISISISISISISISISISISISISISISISISISIIIII" },
		{ DBC_SCENE_DEFINE,	"SceneDefineEx.txt",	sizeof(_DBC_SCENE_DEFINE),	"ISIISSSSIISIIIIIISSSSSSSI" },	// 0.85: SceneDefine.txt
		{ DBC_SCENE_POS_DEFINE,	"ScenePosDefine.txt",	sizeof(_DBC_SCENE_POS_DEFINE),	"ISIIIS" },
		{ DBC_UI_LAYOUTDEFINE,	"InterfaceEx.txt",	sizeof(_DBC_UI_LAYOUTDEFINE),	"ISSSISIIIS" },	// 0.85: Interface.txt; CYS-CY: CY 3.71 10 columns
		{ DBC_LIFEABILITY_GROWPOINT,	"GrowPoint.txt",	sizeof(_DBC_LIFEABILITY_GROWPOINT),	"ISSIISIIIIIIIIIIIII" },
		{ DBC_LIFEABILITY_DEFINE,	"Ability.txt",	sizeof(_DBC_LIFEABILITY_DEFINE),	"ISIISIIIFIISISISIIIII" },
		{ DBC_LIFEABILITY_ITEMCOMPOSE,	"ItemCompound.txt",	sizeof(_DBC_LIFEABILITY_ITEMCOMPOSE),	"ISIIIIIIIIIIIIIIIIIIIIIISIIIIIIIIIIIII" },
		{ DBC_LIFEABILITY_PLATFORM,	"Platform.txt",	sizeof(_DBC_LIFEABILITY_PLATFORM),	"IISSI" },
		{ DBC_CODE_CONVERT,	"CodeConvert.txt",	sizeof(_DBC_CODE_CONVERT),	"ISS" },
		// CYS-CY 16/09 (menpai-verify): 心法升级花费. CY Game.exe opens the same file in the same place of its own
		// table list (CY id 0x97, between Platform.txt and CharTitle.txt; Build/re/menpai-verify/out/xinfa-disasm.txt,
		// full CY list Build/Logs/2026-09-16-menpai-verify/23-cy-dbc-list.tsv). Without this row GetDataBase(907)
		// dereferenced map::end() and Lua_GetUplevelXinfaSpend* could not show a cost.
		{ DBC_XINFA_STUDYSPEND,	"XinFaStudySpend_V1.txt",	sizeof(_DBC_XINFA_STUDYSPEND),	"IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII" },
		{ DBC_TITLE_NAME,	"CharTitle.txt",	sizeof(_DBC_TITLE_NAME),	"IISSIIISISIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII" },
		{ DBC_SKILLDATA_V1_DEPLETE,	"SkillData_V1.txt",	sizeof(_DBC_SKILLDATA_V1_DEPLETE),	"ISSISIIIISIIISIIISIIIIIISISISISISISISISISISISISISISISI" },
		{ DBC_MISSION_KIND,	"MissionKind.txt",	sizeof(_DBC_MISSION_KIND),	"IS" },
		{ DBC_STRING_DICT,	"StrDictionary.txt",	sizeof(_DBC_STRING_DICT),	"SS" },	// 字典
		{ DBC_ITEM_RULE,	"ItemRule.txt",	sizeof(_DBC_ITEM_RULE),	"IIIIIIIIIIIIIII" },	// 物品规则
		{ DBC_TALK_FILTER,	"StrFilter.txt",	sizeof(_DBC_TALK_FILTER),	"ISI" },	// 过滤词汇文件
		{ DBC_LV_MAXMONEY,	"LvMaxMoney.txt",	sizeof(_DBC_LV_MAXMONEY),	"IIIIIIIIIIII" },	// 等级金钱对应表
		{ DBC_TALK_ACT,	"ChatMood.txt",	sizeof(_DBC_TALK_ACT),	"ISSSSIISSSSSIS" },	// 聊天动作命令文件
		{ DBC_TALK_CONFIG,	"ChatConfig.txt",	sizeof(_DBC_TALK_CONFIG),	"ISSIIIIIIII" },	// 聊天配置文件
		{ DBC_MONSTER_PAOPAO,	"MonsterPaoPao.txt",	sizeof(_DBC_MONSTER_PAOPAO),	"IS" },	// 怪物聊天泡泡
		{ DBC_HAIR_STYLE,	"HairStyle.txt",	sizeof(_DBC_HAIR_STYLE),	NULL },	// 发型消耗表 CYS-CY: absent from CY 3.71
		{ DBC_BUILDING_DEINFE,	"BuildingDefine.txt",	sizeof(_DBC_BUILDING_DEFINE),	"ISSSSSSS" },	// 城市建筑物定义表
		{ DBC_CITY_BUILDING,	"CityBuilding.txt",	sizeof(_DBC_CITY_BUILDING),	"IISIIISSIIIIIIIIIIIIIII" },	// 城市建筑物表
		{ DBC_CAMP_AND_STAND,	"ReputationTable.txt",	sizeof(_DBC_CAMP_AND_STAND),	"ISIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIS" },	// 阵营/声望配置表 CYS-CY: CY 3.71 camp relations (cs2-world; CY Game.exe GetDataBase(0xbb) -> TemplateManager_T<U>::InitFromDB)
		{ DBC_FULLCMP_FILTER,	"FullCompareFilter.txt",	sizeof(_DBC_FULLCMP_FILTER),	"ISS" },	// 完全匹配过滤表
		{ DBC_PET_LEVELUP,	"PetLevelUpTable.txt",	sizeof(_DBC_PET_LEVELUP),	"II" },	// 宠物升级所需经验表
		// CYS-PETSKILL 19/09 (pet-skill-12): the two CY-only pet tables of the 珍兽 window. CY Game.exe opens them in
		// its own table list as 0xbe / 0xfe (Build/re/host-pet/decomp-b.c: s_pAttackTrait at
		// GMGameInterface_Script_Pet.cpp:0x801, s_pLxUp at :0x16a6); the ids here are ours, the files are CY's.
		// Without these rows Pet:GetAttackTrait / Pet:GetPercent_Lx had nothing to read and stayed stubs.
		{ DBC_PET_ATTACK_TRAIT,	"AttackTraits.txt",	sizeof(_DBC_PET_ATTACK_TRAIT),	"ISSIIIIIII" },	// 攻击特性表
		{ DBC_PET_LINGXING,	"PetLingXing.txt",	sizeof(_DBC_PET_LINGXING),	"IIIIIIIIIIIIIIIIIIIIIIII" },	// 珍兽灵性表
	};

	//打开所有数据库
	INT nNum = sizeof(s_dbToLoad)/sizeof(_DATABASE_DEFINE);
	INT nCysChecked = 0, nCysErrors = 0, nCysAbsent = 0;
	for(INT i=0; i<nNum; i++)
	{
		const _DATABASE_DEFINE& def = s_dbToLoad[i];
		CDataBase* pDataBase = new CDataBase(def.idDatabase);

		if(def.pSchema == NULL)
		{
			// CYS-CY: absent from the CY data set: always empty, even if an older data set still has the file
			if(!_CysOpenEmptyTable(pDataBase->m_pFileDBC))
				TDThrow("Open %s Error!", def.pFileName);
			TDU_Log("DBC: %s absent from the CY 3.71 data set; empty table", def.pFileName);
			nCysAbsent++;
		}
		else if(!(pDataBase->OpenFromTXT(def.pFileName)))
		{
			if(!_CysOpenEmptyTable(pDataBase->m_pFileDBC))
				TDThrow("Open %s Error!", def.pFileName);
			TDU_Log("DBC ERROR: %s not found; opened as an empty table", def.pFileName);
			nCysErrors++;
		}
		else
		{
			CHAR szTypes[256];
			_CysColumnTypes(pDataBase->m_pFileDBC, szTypes, (INT)sizeof(szTypes));
			const INT nRecord = pDataBase->m_pFileDBC->GetRecordSize();
			if(strcmp(szTypes, def.pSchema) != 0 || nRecord != (INT)def.nRecordSize)
			{
				TDU_Log("DBC ERROR: %s schema %s (expected %s), record %d bytes (struct %d)",
					def.pFileName, szTypes, def.pSchema, nRecord, (INT)def.nRecordSize);
				nCysErrors++;
			}
			else
			{
				TDU_Log("DBC: %s OK columns=%d records=%d record=%d", def.pFileName,
					pDataBase->m_pFileDBC->GetFieldsNum(), pDataBase->m_pFileDBC->GetRecordsNum(), nRecord);
			}
			nCysChecked++;
		}
		if(m_mapDataBaseBuf.find(def.idDatabase) != m_mapDataBaseBuf.end())
		{
			TDThrow("DBC ID Multi define(%s)", def.pFileName);
		}
		m_mapDataBaseBuf.insert(std::make_pair(def.idDatabase, pDataBase));
	}
	TDU_Log("DBC: %d table(s) checked against the CY 3.71 schema, %d error(s), %d absent from the CY data set",
		nCysChecked, nCysErrors, nCysAbsent);
	// CYS: world-entry proof (Docs/specs/net/world-gui-howto_vi.md): the WSL clone spawns in scene 2. Resolve it the way
	// CWorldManager::EnterScene does, so an offline smoke shows whether SceneDefineEx can serve the first live scene.
	{
		std::map< INT, CDataBase* >::iterator itScene = m_mapDataBaseBuf.find(DBC_SCENE_DEFINE);
		const _DBC_SCENE_DEFINE* pScene2 = (itScene == m_mapDataBaseBuf.end()) ? NULL :
			(const _DBC_SCENE_DEFINE*)itScene->second->Search_First_Column_Equ(_DBC_SCENE_DEFINE::SCENE_SERVER_ID_COLUMN, 2);
		if(pScene2)
			TDU_Log("DBC: SceneDefineEx scene 2 resolved name=%s scene=%s path=%s size=%dx%d (EnterScene can find it)",
				pScene2->szName ? pScene2->szName : "", pScene2->szWXObjectName ? pScene2->szWXObjectName : "",
				pScene2->szRegionFile ? pScene2->szRegionFile : "", pScene2->nXSize, pScene2->nZSize);
		else
			TDU_Log("DBC ERROR: SceneDefineEx has no row for scene 2; CWorldManager::EnterScene would throw");
	}
}

VOID CDataBaseSystem::CloseAllDataBase(VOID)
{
	std::map< INT, CDataBase* >::iterator it;
	for(it = m_mapDataBaseBuf.begin(); it!=m_mapDataBaseBuf.end(); it++)
	{
		delete (CDataBase*)(it->second);
		it->second = NULL;
	}

	m_mapDataBaseBuf.clear();
}

const tDataBase* CDataBaseSystem::GetDataBase(INT idDataBase) const
{
	std::map< INT, CDataBase* >::const_iterator it = m_mapDataBaseBuf.find(idDataBase);
	// CYS-CY 16/09 (menpai-verify): a table id that is not in the list used to dereference map::end() (garbage
	// pointer, then a read through it). Every caller goes through DBC_DEFINEHANDLE, which asserts on NULL.
	if(it == m_mapDataBaseBuf.end())
	{
		TDU_Log("DBC ERROR: GetDataBase(%d): table not opened", idDataBase);
		return NULL;
	}
	return (const tDataBase*)it->second;
}

LPCTSTR TransTitleStr(LPCTSTR szTitle)
{
	if(!szTitle) return ""; // CYS
	if(szTitle[0] == '#')
	{//这个字符串是id需要读表转换
		STRINGTOID(szTitle, TBIndex);
		if(TBIndex>0)
		{
			if(auto entry=CysTitleMetadata::Find(TBIndex))return entry->name;
			DBC_DEFINEHANDLE(pTitleDBC, DBC_TITLE_NAME);
			// CYS: a title id absent from the client_GL table (or the table itself) crashed on the first
			// CYS: GCCharBaseAttrib of the world (world-replay 14/09); an unknown title shows empty.
			const _DBC_TITLE_NAME* pTitle = pTitleDBC ? (const _DBC_TITLE_NAME*)pTitleDBC->Search_Index_EQU(TBIndex) : NULL;
			return (pTitle && pTitle->szTitle) ? pTitle->szTitle : "";
		}
		return "";
	}
	return szTitle;	
}