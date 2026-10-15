// GameStruct_Skill.h

#ifndef __GAMESTRUCT_SKILL_H__
#define __GAMESTRUCT_SKILL_H__

#include "Type.h"
#include "GameDefine2.h"

/////////////////////////////////////////////////////////////////////////////////
// 客户端与服务器共用的DBC结构

// CYS-CY: one (effect, sound, locator, INT) group of CY 3.71 ImpactDirectly.txt (client_GL had triples).
struct _DBC_DIRECT_IMPACT_GROUP
{
	CHAR	*m_pszEffect;
	CHAR	*m_pszSound;
	CHAR	*m_pszEffectLocator;
	INT	m_nParam;	// meaning not recovered; -1 in CY rows
};

// 技能伤害结构
// CYS (history, before CY 3.71): client_GL ImpactDirectly.txt (20 columns; Reference has the first 19). Evidence: row values.
// CYS-CY: CY 3.71 column layout (Assets/CanonicalCY ImpactDirectly.txt, 25 columns; evidence and client_GL alignment in Registry/abi/dbc_columns_cy.tsv, Docs/specs/cy-switch_vi.md 3.4). unk_N = meaning not recovered, never read.
struct _DBC_DIRECT_IMPACT
{
	UINT	m_uID;	// [0] ID
	CHAR*	m_pszEffect;	// [1] 特效ID
	CHAR*	m_pszSound;	// [2] 音效ID
	CHAR*	m_pszEffectLocator;	// [3] 特效绑定点
	INT	unk_4;	// [4] INT after each (effect, sound, locator) group
	_DBC_DIRECT_IMPACT_GROUP	m_aEffectEx[4];	// [5..20] four more (effect, sound, locator, INT) groups
	CHAR*	m_pszReserved1;	// [21]
	CHAR*	m_pszReserved2;	// [22]
	CHAR*	m_pszInfo;	// [23] 效果描述
	INT	m_nCol24;	// [24] client_GL col 19
};
typedef _DBC_DIRECT_IMPACT	SDirectImpact;
typedef _DBC_DIRECT_IMPACT	_DIRECT_IMPACT;


// 技能BUFF结构
// CYS-CY: CY 3.71 column layout (Assets/CanonicalCY ImpactSEData_V1.txt, 28 columns; evidence and client_GL alignment in Registry/abi/dbc_columns_cy.tsv, Docs/specs/cy-switch_vi.md 3.4). unk_N = meaning not recovered, never read.
struct _DBC_BUFF_IMPACT
{
	UINT	m_uID;	// [0] ID
	UINT	m_uMutexID;	// [1] 互斥标记
	INT	m_nPri;	// [2] 优先级参数
	LPCSTR	m_szIconName;	// [3]
	LPCSTR	m_lpszEffect_Active;	// [4]
	LPCSTR	m_lpszSound_Active;	// [5]
	LPCSTR	m_lpszBind_Active;	// [6]
	LPCSTR	m_lpszEffect_Continuous;	// [7]
	LPCSTR	m_lpszSound_Continuous;	// [8]
	LPCSTR	m_lpszBind_Continuous;	// [9]
	BOOL	m_bStillOnWhenOwnerDead;	// [10]
	BOOL	m_bCanBeDispeled;	// [11]
	BOOL	m_bHostileFlag;	// [12]
	BOOL	m_bCanBeManualCancel;	// [13]
	BOOL	m_bLineEffect;	// [14]
	CHAR*	m_pszCreatorLocator;	// [15]
	CHAR*	m_pszInfo;	// [16] 效果描述
	INT	unk_17;	// [17] meaning not recovered; not used
	INT	unk_18;	// [18] meaning not recovered; not used
	INT	unk_19;	// [19] meaning not recovered; not used
	INT	unk_20;	// [20] meaning not recovered; not used
	INT	unk_21;	// [21] meaning not recovered; not used
	INT	unk_22;	// [22] meaning not recovered; not used
	LPCSTR	unk_23;	// [23] meaning not recovered; not used
	INT	unk_24;	// [24] meaning not recovered; not used
	LPCSTR	unk_25;	// [25] meaning not recovered; not used
	INT	unk_26;	// [26] meaning not recovered; not used
	INT	unk_27;	// [27] meaning not recovered; not used
};
typedef _DBC_BUFF_IMPACT SBuffImpact;
typedef _DBC_BUFF_IMPACT _BUFF_IMPACT;

// 子弹轨迹类型
enum ENUM_BULLET_CONTRAIL_TYPE
{
	BULLET_CONTRAIL_TYPE_INVALID = -1,
	BULLET_CONTRAIL_TYPE_BEELINE,			// 直线
	BULLET_CONTRAIL_TYPE_PARABOLA,			// 抛物线
	BULLET_CONTRAIL_TYPE_NONE,				// 无轨迹，直接爆炸

	BULLET_CONTRAIL_TYPE_NUMBERS
};

// 子弹
// CYS-CY: CY 3.71 column layout (Assets/CanonicalCY Bullet.txt, 16 columns; evidence and client_GL alignment in Registry/abi/dbc_columns_cy.tsv, Docs/specs/cy-switch_vi.md 3.4). unk_N = meaning not recovered, never read.
struct _DBC_BULLET_DATA
{
	INT	m_nID;	// [0] ID
	INT	m_nContrailType;	// [1] ENUM_BULLET_CONTRAIL_TYPE
	INT	m_nContrailParam;	// [2] CY 3.71: INT (client_GL FLOAT); 0 in every CY row
	CHAR const*	m_szFlyEffect;	// [3]
	CHAR const*	m_szFlySound;	// [4]
	FLOAT	m_fSpeed;	// [5] (m/s)
	CHAR const*	m_szHitEffect;	// [6]
	CHAR const*	m_szHitSound;	// [7]
	CHAR const*	m_szHitEffectLocator;	// [8]
	INT	unk_9;	// [9] meaning not recovered; not used
	INT	unk_10;	// [10] meaning not recovered; not used
	INT	unk_11;	// [11] meaning not recovered; not used
	INT	unk_12;	// [12] meaning not recovered; not used
	CHAR const*	m_szDesc;	// [13] 说明和描述
	INT	m_nFlag;	// [14] client_GL col 15
	LPCSTR	unk_15;	// [15] meaning not recovered; not used
};
typedef _DBC_BULLET_DATA SSkillObjData;
typedef _DBC_BULLET_DATA _SKILLOBJ_DATA;

enum ENUM_SKILL_TYPE
{
	SKILL_TYPE_INVALID	= -1,
	SKILL_TYPE_GATHER,
	SKILL_TYPE_LEAD,
	SKILL_TYPE_LAUNCH,
	SKILL_TYPE_PASSIVE,

	SKILL_TYPE_NUMBERS
};

enum ENUM_SELECT_TYPE
{
	SELECT_TYPE_INVALID	= -1,
	SELECT_TYPE_NONE,			// 无需选择
	SELECT_TYPE_CHARACTER,		// 角色
	SELECT_TYPE_POS,			// 位置
	SELECT_TYPE_DIR,			// 方向
	SELECT_TYPE_SELF,			// 对自己进行操作
	SELECT_TYPE_HUMAN_GUID,		// 玩家
	SELECT_TYPE_NUMBERS
};
enum ENUM_TARGET_LOGIC
{
	TARGET_LOGIC_INVALID	= -1,
	TARGET_SELF,	//只对自己有效
	TARGET_MY_PET,  //只对自己的宠物有效
	TARGET_MY_SHADOW_GUARD, //只对自己的分身有效
	TARGET_MY_MASTER, //只对自己的主人有效，宠物专用
	TARGET_AE_AROUND_SELF, //以自己为中心，范围有效
	TARGET_SPECIFIC_UNIT, //瞄准的对象有效
	TARGET_AE_AROUND_UNIT, //以瞄准的对象为中心，范围有效
	TARGET_AE_AROUND_POSITION, //以瞄准的位置点为中心，范围有效
	TARGET_LOGIC_NUMBERS //逻辑总数
};

enum ENUM_BEHAVIOR_TYPE
{
	BEHAVIOR_TYPE_HOSTILITY = -1, //敌对行为
	BEHAVIOR_TYPE_NEUTRALITY = 0, //中立行为
	BEHAVIOR_TYPE_AMITY = 1, //友好行为
};
// 招式类型
enum ENUM_SKILL_ACTION_TYPE
{
	SKILL_ACTION_TYPE_INVALID	= -1,
	SKILL_ACTION_TYPE_NONE,					// 普通招式(无序随机)
	SKILL_ACTION_TYPE_CONCATENATION_EX,		// 连招(1,2,2,2,2,3)
	SKILL_ACTION_TYPE_CONCATENATION,		// 连招(1,2,3,1,2,3)

	SKILL_ACTION_TYPE_NUMBERS
};

#define MAX_SKILL_FRIEND_TMPACT		(2)
#define MAX_SKILL_ENEMY_TMPACT		(2)
// CYS-CY: CY 3.71 SkillTemplate_V1.txt carries 31 skill ids per xinfa level (columns 48..78; client_GL 16).
#define CYS_SKILL_BY_LEVEL_NUM		(31)
// CYS-CY: bounds-checked m_anSkillByLevel[nIndex]; INVALID_ID outside the table.
#define CYS_SKILL_BY_LEVEL(pDef, nIndex)	(((nIndex) >= 0 && (nIndex) < CYS_SKILL_BY_LEVEL_NUM) ? (pDef)->m_anSkillByLevel[(nIndex)] : INVALID_ID)

// 技能 只是供客户端使用的技能模板结构
// CYS (history, before CY 3.71): client_GL SkillTemplate_V1.txt (82 columns, names from its header row; B passes 368 =
// CYS: the natural size of its first 81 columns to GetDataBase(131)).
// CYS-CY: CY 3.71 column layout (Assets/CanonicalCY SkillTemplate_V1.txt, 102 columns; evidence and client_GL alignment in Registry/abi/dbc_columns_cy.tsv, Docs/specs/cy-switch_vi.md 3.4). unk_N = meaning not recovered, never read.
struct _DBC_SKILL_DATA
{
	INT	m_nID;	// [0] ID
	INT	m_nMenPai;	// [1] client_GL col 2
	const CHAR*	m_lpszName;	// [2]
	const CHAR*	m_lpszIconName;	// [3]
	INT	m_nLevelRequirement;	// [4]
	INT	m_nSkillActionType;	// [5]
	INT	m_bMustUseWeapon;	// [6]
	INT	m_nDisableByFlag1;	// [7]
	INT	m_nDisableByFlag2;	// [8]
	INT	m_nDisableByFlag3;	// [9]
	INT	m_nSkillClass;	// [10] 心法ID
	INT	m_nXinFaParam_Nouse;	// [11]
	INT	m_nType;	// [12] ENUM_SKILL_TYPE (client_GL col 15)
	INT	m_nCooldownID;	// [13]
	const CHAR*	m_lpszStartEffect;	// [14]
	const CHAR*	m_lpszStartEffectLocator;	// [15]
	const CHAR*	m_lpszStartSound;	// [16]
	const CHAR*	m_lpszGatherLeadActionSetID;	// [17]
	const CHAR*	m_lpszSendActionSetID;	// [18]
	INT	m_nTargetMustInSpecialState;	// [19] client_GL col 23
	INT	m_nClassByUser;	// [20]
	INT	m_nPassiveFlag;	// [21]
	INT	m_nSelectType;	// [22]
	INT	m_nOperateModeForPetSkill;	// [23]
	INT	m_nPetRateOfSkill;	// [24]
	INT	m_nTypeOfPetSkill;	// [25]
	INT	m_nImpactIDOfSkill;	// [26]
	INT	m_nReserved1;	// [27] 技能组ID
	INT	m_nReserved2;	// [28] 技能组等级
	INT	m_nReserved3;	// [29] 是否直接学会
	INT	m_nReserved4;	// [30] 使用前是否需要学会
	INT	m_nBulletID;	// [31]
	const CHAR*	m_pszBulletSendLocator;	// [32]
	INT	m_nTargetingLogic;	// [33] client_GL col 38
	INT	m_nSendTime;	// [34] 动作时间(ms)
	FLOAT	m_fMaxAttackRange;	// [35] client_GL col 41
	INT	m_nFriendness;	// [36] client_GL col 42
	INT	m_nRelationshipLogic;	// [37]
	INT	m_nTargetCheckByObjType;	// [38]
	BOOL	m_bAutoRedo;	// [39] client_GL col 47
	INT	m_nCriticalRate;	// [40] client_GL col 49
	BOOL	m_bUseNormalAttackRate;	// [41]
	INT	m_nActiveTime;	// [42] client_GL col 51
	FLOAT	m_fDamageRange;	// [43] client_GL col 52
	INT	m_nTargetNum;	// [44] client_GL col 54
	INT	m_nReserved7;	// [45] client_GL col 55
	INT	m_nCanInterruptAutoShot;	// [46]
	INT	m_nDelayTime;	// [47]
	INT	m_anSkillByLevel[31];	// [48..78] skill id per xinfa level (client_GL 16)
	CHAR*	m_pszDesc;	// [79]
	INT	m_nShowHitName;	// [80]
	FLOAT	m_fDisturbTimePercent;	// [81]
	INT	unk_82;	// [82] meaning not recovered; not used
	INT	unk_83;	// [83] meaning not recovered; not used
	INT	unk_84;	// [84] meaning not recovered; not used
	INT	unk_85;	// [85] meaning not recovered; not used
	INT	unk_86;	// [86] meaning not recovered; not used
	INT	unk_87;	// [87] meaning not recovered; not used
	INT	m_nCol88;	// [88] client_GL col 79
	INT	m_nIDForManagement;	// [89] 策划专用ID (client_GL col 1)
	INT	m_nRangeSkillFlag;	// [90] client_GL col 13
	BOOL	m_bBreakPreSkill;	// [91] client_GL col 14
	INT	unk_92;	// [92] meaning not recovered; not used
	INT	unk_93;	// [93] meaning not recovered; not used
	FLOAT	m_fMinAttackRange;	// [94] client_GL col 40
	INT	m_nIsPartyOnly;	// [95] client_GL col 45
	INT	m_nHitsOrINTerval;	// [96] client_GL col 46
	INT	m_nHitRate;	// [97] client_GL col 48
	FLOAT	m_fDamageAngle;	// [98] client_GL col 53
	INT	m_nDisturbRate;	// [99] client_GL col 77
	INT	m_nDisturbTimeFloat;	// [100] client_GL col 78
	INT	m_nCol101;	// [101] client_GL col 81
};
typedef _DBC_SKILL_DATA SSkillData;
typedef _DBC_SKILL_DATA _SKILL_DATA;

///////////////////////////////////////////////////////////////////////
// 心法
struct _DBC_XINFA_DATA
{
	//
	UINT		m_uID;							// ID
	UINT		m_uIDMenpai;					// 门派ID
	const CHAR	*m_lpszName;					// 名称
	CHAR		*m_pszDesc;						// 技能描述
	const CHAR	*m_lpszIconName;				// Icon名称
};
///////////////////////////////////////////////////////////////////////
struct _SKILL_EXPERIENCE
{
	BYTE		m_SkillLevel;	//技能等级
	BYTE		m_SkillExp;		//技能熟练度
	USHORT		m_SkillPoints;	//技能使用次数
};

struct _OWN_SKILL
{
	SkillID_t		m_nSkillID;			//拥有的技能ID
	union
	{
		UINT				m_nSkillTime;		//一个INT，但是目前没有使用，可以存盘
		_SKILL_EXPERIENCE	m_SkillExp;		
	};

	_OWN_SKILL()
	{
		m_nSkillID = 0;
		m_SkillExp.m_SkillLevel		= 1;
		m_SkillExp.m_SkillExp		= 0;
		m_SkillExp.m_SkillPoints	= 0;
	}

	VOID	SetSkillLevel(BYTE nLevel)
	{
		Assert(nLevel<=MAX_SKILL_LEVEL);
		m_SkillExp.m_SkillLevel = nLevel;
	}
	const BYTE	GetSkillLevel(VOID)
	{
		return m_SkillExp.m_SkillLevel;
	}

	VOID	SetSkillExp(BYTE nSkillExp)
	{
		m_SkillExp.m_SkillExp = nSkillExp;
	}
	const BYTE	GetSkillExp(VOID)
	{
		return m_SkillExp.m_SkillExp;
	}

	VOID	SetSkillPoints(USHORT nSkillPoints)
	{
		m_SkillExp.m_SkillPoints = nSkillPoints;
	}
	const USHORT	GetSkillPoints(VOID)
	{
		return m_SkillExp.m_SkillPoints;
	}
};

//这个结构暂时不用了。。。。
struct _OWN_XINFA
{
	union
	{
		SkillID_t		m_nXinFaID ;		//拥有的心法ID
		//BYTE			m_SkillPoint[2];	
	};
	USHORT				m_nXinFaLevel ;			//心法等级

	//VOID		SetSkillPointBelow( INT nPoint )
	//{
	//	m_SkillPoint[0] = nPoint;
	//}
	//const BYTE		GetSkillPointBelow() const
	//{
	//	return m_SkillPoint[0];
	//}
	//VOID		SetSkillPointHeigh( INT nPoint )
	//{
	//	m_SkillPoint[1] = nPoint;
	//}
	//const BYTE		GetSkillPointHeigh() const
	//{
	//	return m_SkillPoint[1];
	//}
};



////////////////////////////////////////////
// 伤害的结构
#define DAMAGE_INFO_PARAM_NUMBER	(8)

struct _DAMAGE_INFO
{
	enum
	{
		TYPE_INVALID = INVALID_ID,
		TYPE_EFFECT = 0,
		TYPE_HEAL_AND_DAMAGE = 1,
		TYPE_DROP_BOX = 2,
		TYPE_SKILL_TEXT = 3,
		TYPE_DIE = 4,
	};
	SkillID_t		m_nSkillID;				// 技能ID
	ObjID_t 		m_nTargetID;			// 目标对象的ID
	ObjID_t			m_nSenderID;			// 攻击者的ID
	INT				m_nSenderLogicCount;	// 攻击者的逻辑计数
	ImpactID_t		m_nImpactID;			// 效果ID //参考GameStruct_Impact.h的DIRECT_IMPACT_SEID
	ID_t			m_nType;				// 效果、伤害和治疗数值、掉落盒
	INT				m_nHealthIncrement;
	BOOL			m_bHealthDirty;
	INT				m_nManaIncrement;
	BOOL			m_bManaDirty;
	INT				m_nRageIncrement;
	BOOL			m_bRageDirty;
	INT				m_nStrikePointIncrement;
	BOOL			m_bStrikePointDirty;
	BOOL			m_bIsCriticalHit;

	INT 			m_aAttachedParams[DAMAGE_INFO_PARAM_NUMBER]; // 附加的参数

	_DAMAGE_INFO( VOID )
	{
		Reset();
	}

	VOID Reset( VOID )
	{
		m_nTargetID				= INVALID_ID;
		m_nSenderID				= INVALID_ID;
		m_nSenderLogicCount		= -1;
		m_nImpactID				= INVALID_ID;
		m_nType					= TYPE_INVALID;
		m_nHealthIncrement		= 0;
		m_bHealthDirty			= FALSE;
		m_nManaIncrement		= 0;
		m_bManaDirty			= FALSE;
		m_nRageIncrement		= 0;
		m_bRageDirty			= FALSE;		
		m_nStrikePointIncrement	= 0;
		m_bStrikePointDirty		= FALSE;
		m_bIsCriticalHit		= FALSE;
		memset( m_aAttachedParams, 0, sizeof( m_aAttachedParams ) );
	}

	const _DAMAGE_INFO &operator = ( const _DAMAGE_INFO &in )
	{
		if ( this != &in )
		{
			m_nTargetID				= in.m_nTargetID;
			m_nSenderID				= in.m_nSenderID;
			m_nSenderLogicCount		= in.m_nSenderLogicCount;
			m_nImpactID				= in.m_nImpactID;
			m_nType					= in.m_nType;
			m_nHealthIncrement		= in.m_nHealthIncrement;
			m_bHealthDirty			= in.m_bHealthDirty;
			m_nManaIncrement		= in.m_nManaIncrement;
			m_bManaDirty			= in.m_bManaDirty;
			m_nRageIncrement		= in.m_nRageIncrement;
			m_bRageDirty			= in.m_bRageDirty;
			m_nStrikePointIncrement = in.m_nStrikePointIncrement;
			m_bStrikePointDirty		= in.m_bStrikePointDirty;
			m_bIsCriticalHit		= in.m_bIsCriticalHit;

			memcpy( m_aAttachedParams, in.m_aAttachedParams, sizeof( m_aAttachedParams ) );
		}
		return *this;
	}
};

////////////////////////////////////////////
// 技能BUFF的结构
#define BUFF_IMPACT_INFO_PARAM_NUMBER	(8)

struct _BUFF_IMPACT_INFO
{
	ObjID_t			m_nReceiverID;										// 效果接受者的ID
	ObjID_t			m_nSenderID;										// 效果释放者的ID
	ImpactID_t		m_nBuffID;											// 特效数据的ID(索引)
	SkillID_t		m_nSkillID;  										// Skill ID
	INT				m_nSenderLogicCount;								// 效果创建者的逻辑计数
	UINT			m_nSN;												// 效果序列号
	INT				m_nTimer;											// 剩余时间

	_BUFF_IMPACT_INFO( VOID )
	{
		Reset();
	}

	VOID Reset( VOID )
	{
		m_nReceiverID			= INVALID_ID;
		m_nSenderID				= INVALID_ID;
		m_nBuffID				= INVALID_ID;
		m_nSkillID				= INVALID_ID;
		m_nSenderLogicCount		= -1;
		m_nSN					= -1;
		m_nTimer				= 0;
	}

	const _BUFF_IMPACT_INFO &operator = ( const _BUFF_IMPACT_INFO &in )
	{
		if ( &in != this )
		{
			m_nReceiverID			= in.m_nReceiverID;
			m_nSenderID				= in.m_nSenderID;
			m_nBuffID				= in.m_nBuffID;
			m_nSkillID				= in.m_nSkillID;
			m_nSenderLogicCount		= in.m_nSenderLogicCount;
			m_nSN					= in.m_nSN;
			m_nTimer				= in.m_nTimer;
		}
		return *this;
	}
};

// 传说中的拉人的信息结构
struct _CALLOF_INFO
{
	GUID_t			m_guidCaller;	// 召唤者的GUID
	SceneID_t		m_SceneID;		// 场景ID
	WORLD_POS		m_Pos;			// 场景位置
	UINT			m_uDuration;	// 持续时间

	_CALLOF_INFO( VOID )
	{
		m_guidCaller		= INVALID_GUID;
		m_SceneID			= INVALID_ID;
		m_Pos				= WORLD_POS( -1.f, -1.f );
		m_uDuration			= 0;
	}

	VOID Reset( VOID )
	{
		m_guidCaller		= INVALID_GUID;
		m_SceneID			= INVALID_ID;
		m_Pos				= WORLD_POS( -1.f, -1.f );
		m_uDuration			= 0;
	}
};

//cooldown
class Cooldown_T
{
	public:
		Cooldown_T(VOID): m_nID(INVALID_ID), m_nCooldown(0), m_nCooldownElapsed(0){};
		Cooldown_T(Cooldown_T const& rhs)
		{
			m_nID = rhs.GetID();
			m_nCooldown = rhs.GetCooldownTime();
			m_nCooldownElapsed = rhs.GetCooldownElapsed();
		};
		~Cooldown_T(VOID){}
		Cooldown_T& operator=(Cooldown_T const& rhs)
		{
			m_nID = rhs.GetID();
			m_nCooldown = rhs.GetCooldownTime();
			m_nCooldownElapsed = rhs.GetCooldownElapsed();
			return *this;
		};
		VOID HeartBeat(Time_t nDeltaTime)
		{
			if(0>m_nID)
			{
				return;
			}
			if(m_nCooldown<=m_nCooldownElapsed)
			{
				return;
			}
			m_nCooldownElapsed +=nDeltaTime;
			if(m_nCooldown<m_nCooldownElapsed)
			{
				m_nCooldown=m_nCooldownElapsed;
			}
		};
		BOOL IsCooldowned(VOID) const
		{
			return m_nCooldown<=m_nCooldownElapsed;
		};
		Time_t GetRemainTime(VOID) const
		{
			return m_nCooldown - m_nCooldownElapsed;
		};
		VOID Reset(VOID)
		{
			m_nID = INVALID_ID;
			m_nCooldown = 0;
			m_nCooldownElapsed = 0;
		};
		ID_t GetID(VOID) const {return m_nID;}
		VOID SetID(ID_t nID) {m_nID = nID;}
		Time_t GetCooldownTime(VOID) const {return m_nCooldown;}
		VOID SetCooldownTime(Time_t nTime) {m_nCooldown = nTime;}
		Time_t GetCooldownElapsed(VOID) const {return m_nCooldownElapsed;}
		VOID SetCooldownElapsed(Time_t nTime){m_nCooldownElapsed = nTime;}
	protected:
	private:
		ID_t	m_nID;
		Time_t	m_nCooldown;
		Time_t	m_nCooldownElapsed;
};
template <INT nSize>
class CooldownList_T
{
	public:
		enum
		{
			LIST_SIZE = nSize,
		};
		CooldownList_T(VOID){}
		CooldownList_T(CooldownList_T const& rhs)
		{
			for(INT nIdx=0;LIST_SIZE>nIdx;++nIdx)
			{
				m_aCooldown[nIdx] = rhs.GetCooldownInfoByIndex(nIdx);
			}
		}
		~CooldownList_T(VOID){}
		VOID CleanUp(VOID) {Reset();}
		VOID Reset(VOID)
		{
			for(INT nIdx=0;LIST_SIZE>nIdx;++nIdx)
			{
				m_aCooldown[nIdx].Reset();
			}
		}
		CooldownList_T& operator=(CooldownList_T const& rhs)
		{
			for(INT nIdx=0;LIST_SIZE>nIdx;++nIdx)
			{
				m_aCooldown[nIdx] = rhs.GetCooldownInfoByIndex(nIdx);
			}
			return *this;
		}
		Cooldown_T const& GetCooldownInfoByIndex(INT nIdx) const
		{
			if(0>nIdx || LIST_SIZE<=nIdx)
			{
				AssertEx(FALSE,"[CooldownList_T::GetCooldownByIndex]:Illegal index found!!");
				return m_aCooldown[0];
			}
			return m_aCooldown[nIdx];
		}
		Time_t GetRemainTimeByID(CooldownID_t nCooldown) const
		{
			for(INT nIdx=0;LIST_SIZE>nIdx;++nIdx)
			{
				if(m_aCooldown[nIdx].GetID()==nCooldown)
				{
					return m_aCooldown[nIdx].GetRemainTime();
				}
			}
			return TRUE;
		}
		INT GetSlotSize(VOID)
		{
			return LIST_SIZE;
		}
		INT GetByteSize(VOID)
		{
			return sizeof(CooldownList_T);
		}
		VOID HeartBeat(Time_t nDeltaTime)
		{
			for(INT nIdx=0;LIST_SIZE>nIdx;++nIdx)
			{
				m_aCooldown[nIdx].HeartBeat(nDeltaTime);
			}
		}
		BOOL IsSpecificSlotCooldownedByID(CooldownID_t nCooldown) const
		{
			if(0 > nCooldown)
			{
				return TRUE;
			}
			for(INT nIdx=0;LIST_SIZE>nIdx;++nIdx)
			{
				if(m_aCooldown[nIdx].GetID()==nCooldown)
				{
					return m_aCooldown[nIdx].IsCooldowned();
				}
			}
			return TRUE;
		}
		VOID RegisterCooldown(CooldownID_t nCooldown, Time_t nCooldownTime)
		{
			INT nEmptySlot = INVALID_ID;
			if(0 > nCooldown)
			{
				return;
			}
			for(INT nIdx=0;LIST_SIZE>nIdx;++nIdx)
			{
				if(INVALID_ID==nEmptySlot)
				{
					if(INVALID_ID==m_aCooldown[nIdx].GetID())
					{
						nEmptySlot = nIdx;
					}
					else if(TRUE==m_aCooldown[nIdx].IsCooldowned())
					{
						nEmptySlot = nIdx;
					}
				}
				if(m_aCooldown[nIdx].GetID()==nCooldown)
				{
					m_aCooldown[nIdx].Reset();
					m_aCooldown[nIdx].SetID(nCooldown);
					m_aCooldown[nIdx].SetCooldownTime(nCooldownTime);
					return;
				}
			}
			if(INVALID_ID!=nEmptySlot)
			{
					m_aCooldown[nEmptySlot].Reset();
					m_aCooldown[nEmptySlot].SetID(nCooldown);
					m_aCooldown[nEmptySlot].SetCooldownTime(nCooldownTime);
					return;
			}
			AssertEx(FALSE, "[CooldownList_T::RegisterCooldown]: Cooldown list full!!");
		}
	protected:
	private:
		Cooldown_T m_aCooldown[LIST_SIZE];
};

class MissFlag_T //empty class for wrap constants
{
	public:
		enum
		{
			FLAG_NORMAL =0,
			FLAG_MISS,
			FLAG_IMMU,
			FLAG_ABSORB,
			FLAG_COUNTERACT,
			FLAG_TRANSFERED,
		};
};
#endif
