//TDDBC_Struct.h
//基本数据库结构


#pragma once

//*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-//
//								主角相关								//
//*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-//

/////////////////////////////////////////////////////////////////////
//主角种族							(CHAR_01)
/////////////////////////////////////////////////////////////////////
#define DBC_CHARACTER_RACE			(101)		//主角种族(男，女)
struct _DBC_CHAR_RACE
{
	INT		nID;
	INT		nGender;
	INT		nIsPlayer;
	INT		nModelID;
	INT		nDefHeadGeo;
	INT		nDefHairGeo;
	INT		nDefBody;
	INT		nDefArm;
	INT		nDefFoot;
	INT		nIdleInterval;
};

/////////////////////////////////////////////////////////////////////
//主角头发模型						(CHAR_02)
/////////////////////////////////////////////////////////////////////
#define DBC_CHARACTER_HAIR_GEO		(102)		//主角头发模型
// CYS-CY: CY 3.71 column layout (Assets/CanonicalCY CharHairGeo.txt, 14 columns; evidence and client_GL alignment in Registry/abi/dbc_columns_cy.tsv, Docs/specs/cy-switch_vi.md 3.4). unk_N = meaning not recovered, never read.
struct _DBC_CHAR_HAIR_GEO
{
	INT	nID;	// [0]
	INT	nRace;	// [1] RaceID
	LPCSTR	pMeshFile;	// [2] mesh (GBK resource key)
	LPCSTR	pMeshFile_IV;	// [3] "_iv" variant of [2]
	LPCSTR	pMeshFile2;	// [4] second mesh (scalp / ornament), often empty
	LPCSTR	pMeshFile2_IV;	// [5] "_iv" variant of [4]
	LPCSTR	pShowName;	// [6] ShowName (client_GL col 4)
	INT	nCostItemID;	// [7]
	INT	nCostItemCount;	// [8]
	INT	nSelectable;	// [9] 0..3: selectable at creation / in game
	LPCSTR	pIcon;	// [10]
	INT	nCostMoney;	// [11]
	INT	nExteriorID;	// [12] client_GL col 12
	INT	unk_13;	// [13] meaning not recovered; not used
};

/////////////////////////////////////////////////////////////////////
//主角脸部模型						(CHAR_04)
/////////////////////////////////////////////////////////////////////
#define DBC_CHARACTER_HEAD_GEO		(104)		//主角脸部模型
// CYS: DBC_CHARACTER_HEAD_GEO opens CharFaceGeo.txt like B (table 103); CharHeadGeo.txt is a 4-column legacy
// CYS-CY: CY 3.71 column layout (Assets/CanonicalCY CharFaceGeo.txt, 12 columns; evidence and client_GL alignment in Registry/abi/dbc_columns_cy.tsv, Docs/specs/cy-switch_vi.md 3.4). unk_N = meaning not recovered, never read.
struct _DBC_CHAR_HEAD_GEO
{
	INT	nID;	// [0]
	INT	nRace;	// [1] RaceID
	LPCSTR	pMeshFile;	// [2] mesh (GBK resource key)
	LPCSTR	pMeshFile_IV;	// [3] "_iv" variant of [2]
	LPCSTR	pShowName;	// [4] ShowName (client_GL col 3)
	INT	nCostItemID;	// [5]
	INT	nCostItemCount;	// [6]
	INT	nSelectable;	// [7] 0..3: selectable at creation / in game
	LPCSTR	pIcon;	// [8]
	INT	nCostMoney;	// [9]
	INT	nExteriorID;	// [10] client_GL col 10
	INT	unk_11;	// [11] meaning not recovered; not used
};

/////////////////////////////////////////////////////////////////////
//主角动作组						(CHAR_06)
/////////////////////////////////////////////////////////////////////
#define DBC_CHARACTER_ACTION_SET	(106)
#define MAX_WEAPON_TYPE_NUMBER		(9)
struct _DBC_CHARACTER_ACTION_SET
{
	INT		nID;
	LPCSTR	pWeapon_Set[MAX_WEAPON_TYPE_NUMBER];
	BOOL	bHideWeapon;
	INT		nAppointedWeaponID;		// 指定的武器ID
	LPCSTR	pszDesc;
};

// CYS: CharActionSet.txt (DBC_CHARACTER_ACTION_SET) in client_GL and Reference has 10 columns: id + one action
// CYS: name per weapon type. _DBC_CHARACTER_ACTION_SET above stays the 13-column per-model file format
// CYS: (Reference Config/ActionSet/*.txt) read by CActionSetMgr.
struct _DBC_CHAR_ACTION_SET_TABLE
{
	INT	nID;	// [0]
	LPCSTR	pWeapon_Set[MAX_WEAPON_TYPE_NUMBER];	// [1..9]
};

/////////////////////////////////////////////////////////////////////
//动作组文件索引 (client_GL)
/////////////////////////////////////////////////////////////////////
// CYS: ActionSetFile.txt (B table 108): row id -> action-set file name; CharModelEx column 9 indexes it.
#define DBC_ACTION_SET_FILE		(112)
struct _DBC_ACTION_SET_FILE
{
	INT	nID;	// [0]
	LPCSTR	pszFileName;	// [1] *.txt (GBK)
};

/////////////////////////////////////////////////////////////////////
//主角特效							(CHAR_07)
/////////////////////////////////////////////////////////////////////
#define DBC_CHARACTER_EFFECT		(107)
struct _DBC_CHARACTER_EFFECT
{
	INT		nID;
	INT		nEffect1;
	INT		nEffect2;
	INT		nSoundID;
	LPCSTR	pLocator;
	LPCSTR	pWeaponLocator;
};

/////////////////////////////////////////////////////////////////////
//主角升级经验值						(CHAR_08)
/////////////////////////////////////////////////////////////////////
#define DBC_CHARACTER_EXPLEVEL		(108)
// CYS-CY: CY 3.71 column layout (Assets/CanonicalCY PlayerExpLevel.txt, 2 columns; evidence and client_GL alignment in Registry/abi/dbc_columns_cy.tsv, Docs/specs/cy-switch_vi.md 3.4). unk_N = meaning not recovered, never read.
struct _DBC_CHARACTER_EXPLEVEL
{
	INT	nID;	// [0] level
	LPCSTR	szExpNeed;	// [1] CY 3.71: STRING (decimal); client_GL had INT. Use CysExpNeed()
};

/////////////////////////////////////////////////////////////////////
//外形ID对应模型名称					(CHAR_09)
/////////////////////////////////////////////////////////////////////
#define DBC_CHARACTER_MODEL			(109)
#define MAX_MOUNT_NUMBER			(20)
// CYS-CY: CY 3.71 column layout (Assets/CanonicalCY CharModelEx.txt, 21 columns; evidence and client_GL alignment in Registry/abi/dbc_columns_cy.tsv, Docs/specs/cy-switch_vi.md 3.4). unk_N = meaning not recovered, never read.
struct _DBC_CHARACTER_MODEL
{
	INT	m_nID;	// [0]
	LPCSTR	m_pszModelName;	// [1] *.obj (GBK); CY Game.exe row+0x08
	LPCSTR	m_pszModelName_IV;	// [2] "_iv" *.obj; CY row+0x10, used instead of [1] when a global mode flag is set
	FLOAT	m_fFuseTime;	// [3] client_GL col 2; CY row+0x18
	FLOAT	m_fCol4;	// [4] client_GL col 3
	FLOAT	m_fCol5;
	FLOAT	m_fCol6;




	INT	m_nLinkedID[13];	// [7..19]
	INT	m_nActionSetFileID;
};

/////////////////////////////////////////////////////////////////////
//主角头像
/////////////////////////////////////////////////////////////////////
#define DBC_CHARACTER_FACE		(110)		//主角头像
// CYS: client_GL column layout (Canonical CharacterFace.txt, 6 columns; B GetDataBase(109, 32)). Registry/abi/dbc_inventory_gl.json holds the evidence.
struct _DBC_CHAR_FACE
{
	INT	nID;	// [0]
	INT	nRace;	// [1]
	LPCSTR	pImageSetName;	// [2] portrait image descriptor; B reads it at +0x08
	INT	nSelectable;	// [3] 1/3 = offered at creation (CY creation profile rule)
	INT	nCol4;	// [4]
	LPCSTR	pImageSetName2;	// [5] second image descriptor
};

/////////////////////////////////////////////////////////////////////
//坐骑表
/////////////////////////////////////////////////////////////////////
#define DBC_CHARACTER_MOUNT		(111)
// CYS: the 0.85 m_nPassLevel column does not exist in client_GL (B reads CharMount only for model/camera).
// CYS-CY: CY 3.71 column layout (Assets/CanonicalCY CharMount.txt, 24 columns; evidence and client_GL alignment in Registry/abi/dbc_columns_cy.tsv, Docs/specs/cy-switch_vi.md 3.4). unk_N = meaning not recovered, never read.
struct _DBC_CHARACTER_MOUNT
{
	INT	m_nID;	// [0]
	LPCSTR	m_pszName;	// [1]
	INT	m_nPassengerNum;	// [2] 准乘人数; CY row+0x10 == 2 selects seat 2
	INT	m_nModelID;	// [3] CharModelEx id
	FLOAT	m_fAddHeight;	// [4]
	INT	m_nMountActionSetID;	// [5]
	INT	m_nRiderActionSetF;	// [6] main seat action set, female (client_GL col 6)
	INT	m_nRiderActionSetM;	// [7] main seat action set, male (client_GL col 7)
	LPCSTR	m_pszRiderLocator;	// [8] main seat locator; CY row+0x28
	INT	m_nRider2ActionSetF;	// [9] second seat
	INT	m_nRider2ActionSetM;	// [10]
	LPCSTR	m_pszRider2Locator;	// [11] CY row+0x38
	LPCSTR	m_pszRiderLocatorEx[4];	// [12..15] seats 3..6 locators (values attach3..attach6)

	INT	unk_16;	// [16] always -1 in CY data (354 rows); no reader found
	INT	m_nRideAllowMain;
	INT	m_nRideAllowPassenger;	// [18] 1/-1; same check reads row+0x68 for a passenger (vtable+0x288 != 0) [SL: name]
	INT	m_nCanFly;	// [19] CY 3.71 140613380: row+0x6c >= 1 permits CGFlyOperation (high flight).
	INT	unk_20;	// [20] always 0 in CY data; no reader found
	INT	m_nMonsterFormID;	// [21] [SL] MonsterAttrExTable id of the mount as a creature (52 rows: 变异废柴 22744 ...); no reader in CY Game.exe











	FLOAT	m_fFlyHeight;	// [22] client_GL col 14
	INT	m_nPetPossPositionID;
};

//*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-//
//								生物相关								//
//*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-//

/////////////////////////////////////////////////////////////////////
//生物定义总表						(CREATURE_01)
/////////////////////////////////////////////////////////////////////
#define DBC_CREATURE_ATT			(201)
// CYS-CY: CY 3.71 column layout (Assets/CanonicalCY MonsterAttrExTable.txt, 73 columns; evidence and client_GL alignment in Registry/abi/dbc_columns_cy.tsv, Docs/specs/cy-switch_vi.md 3.4). unk_N = meaning not recovered, never read.
struct _DBC_CREATURE_ATT
{
	INT	nID;	// [0] 怪物编号
	LPCSTR	pName;	// [1] 名称
	INT	nGender;	// [2]
	INT	nLevel;	// [3]
	FLOAT	fMinHurtPercent;	// [4]
	INT	nCanHandle;	// [5] 是否可以交互
	INT	nMonsterBossFlag;	// [6]
	INT	nAttackRate_P;	// [7]
	INT	nDefence_P;	// [8]
	INT	nAttackRate_M;	// [9]
	INT	nDefence_M;	// [10]
	INT	nMaxHP;	// [11]
	INT	nMaxMP;	// [12]
	INT	nRestoreHP;	// [SL] position
	INT	nRestoreMP;	// [SL] position
	INT	nHit;	// [15]
	INT	nMiss;	// [16]
	INT	nCritrate;	// [17]
	INT	nCritDefence;	// [18]
	INT	nSpeed;	// [19]
	INT	nMonsterWalkSpeed;	// [20]
	INT	nAttackSpeed;	// [SL] position
	INT	nAttackCold;	// [22]
	INT	nDefenceCold;	// [23]
	INT	nReduceColdResist;	// [24]
	INT	nAttackFire;	// [25]
	INT	nDefenceFire;	// [26]
	INT	nReduceFireResist;	// [27]
	INT	nAttackLight;	// [28]
	INT	nDefenceLight;	// [29]
	INT	nReduceLightResist;	// [30]
	INT	nAttackPoison;	// [31]
	INT	nDefencePoison;	// [32]
	INT	nReducePoisonResist;	// [33]
	INT	nMonsterBossSnapImmID;	// [34]
	INT	nMonsterBossDurationImmID;	// [35]
	INT	nModelID;	// [36] 外型ID
	INT	nIsDisplayerName;	// [37]
	INT	nIsCanSwerve;	// [38]
	FLOAT	fBoardHeight;	// [39]
	FLOAT	fProjTexRange;	// [40]
	FLOAT	fShadowRange;	// [41]
	LPCSTR	szIconName;	// [42] 人物头像
	INT	nAttackAnimTime;	// [43]
	INT	nAttackCooldown;	// [44]
	INT	nMaxLv;	// [45]
	INT	nMaxExp;	// [46]
	INT	nMaxAtt;	// [47]
	INT	nMaxDef;	// [48]
	INT	nMaxMag;	// [49]
	INT	nMaxRes;	// [50]
	INT	nMaxHPLimit;	// [51]
	INT	nShowInMiniMap;	// [52]
	INT	nForceID;	// [53] 势力ID
	INT	nAttackTraitID;	// [54]
	INT	nAttackNPC;	// [55]
	INT	nPlayFuseDodgeParry;	// [56]
	INT	nAppearanceType;	// [57]
	INT	nStrengthType;	// [58]
	INT	nInteractMode;	// [59]
	INT	nActiveTime;	// [60]
	INT	nCombatMode;	// [61]
	INT	unk_62;	// [62] meaning not recovered; not used
	INT	nAssignedSkill;	// [63] 指定技能
	INT	nIdleInterval;	// [64] client_GL col 6
	INT	unk_65;	// [65] meaning not recovered; not used
	INT	nBaseExp;	// [66] client_GL col 4
	INT	nFriendValue;	// [SL] position (client_GL col 5, constant)
	INT	nBaseAI;	// [68]
	INT	nExtAI;	// [69]
	INT	nCamp;	// [70]
	INT	nDropRadius;	// [71]
	INT	nDropGroupMax;	// [72]
};

/////////////////////////////////////////////////////////////////////
//宠物附加属性						(DBC_PET_EX_ATT)
/////////////////////////////////////////////////////////////////////
#define DBC_PET_EX_ATT				(202)
// CYS-CY: CY 3.71 column layout (Assets/CanonicalCY PetAttrTable.txt, 54 columns; evidence and client_GL alignment in Registry/abi/dbc_columns_cy.tsv, Docs/specs/cy-switch_vi.md 3.4). unk_N = meaning not recovered, never read.
struct _DBC_PET_EX_ATT
{
	INT	m_Type;	// [0] 宠物编号
	LPCSTR	m_Name;	// [1]
	INT	unk_2;	// [2] meaning not recovered; not used
	INT	m_PetType;	// [3] client_GL col 2
	INT	m_TakeLevel;	// [4]
	INT	m_Camp;	// [5]
	INT	m_Reserve1;	// [6] 是否变异
	INT	m_Reserve2;	// [7] 是否宝宝
	INT	m_FoodType;	// [8]
	INT	m_SkillLearnNum;	// [9]
	INT	m_PositiveSkill;	// [10]
	INT	m_PositiveSkillRate;	// [11] 1/1000000
	INT	m_PositiveSkill2;	// [12]
	INT	m_PositiveSkill2Rate;	// [13]
	INT	m_PassiveSkill1;	// [14]
	INT	m_PassiveSkill1Rate;	// [15]
	INT	m_PassiveSkill2;	// [16]
	INT	m_PassiveSkill2Rate;	// [17]
	INT	m_PassiveSkill3;	// [18]
	INT	m_PassiveSkill3Rate;	// [19]
	INT	m_PassiveSkill4;	// [20]
	INT	m_PassiveSkill4Rate;	// [21]
	INT	unk_22;	// [22] meaning not recovered; not used
	INT	unk_23;	// [23] meaning not recovered; not used
	INT	m_Life;	// [24]
	INT	m_StrPerception;	// [25]
	INT	m_ConPerception;	// [26]
	INT	m_DexPerception;	// [27]
	INT	m_SprPerception;	// [28]
	INT	m_IntPerception;	// [29]
	INT	m_GrowRate0;	// [30]
	INT	m_GrowRate1;	// [31]
	INT	m_GrowRate2;	// [32]
	INT	m_GrowRate3;	// [33]
	INT	m_GrowRate4;	// [34]
	INT	m_CowardiceRate;	// [35]
	INT	m_WarinessRate;	// [36]
	INT	m_LoyalismRate;	// [37]
	INT	m_CanninessRate;	// [38]
	INT	m_ValourRate;	// [39]
	INT	unk_40;	// [40] meaning not recovered; not used
	INT	m_RefPetType;	// [41] client_GL col 50
	INT	unk_42;	// [42] meaning not recovered; not used
	LPCSTR	unk_43;	// [43] meaning not recovered; not used
	INT	unk_44;	// [44] meaning not recovered; not used
	INT	unk_45;	// [45] meaning not recovered; not used
	INT	unk_46;	// [46] meaning not recovered; not used
	INT	unk_47;	// [47] meaning not recovered; not used
	INT	unk_48;	// [48] meaning not recovered; not used
	INT	unk_49;	// [49] meaning not recovered; not used
	INT	unk_50;	// [50] meaning not recovered; not used
	INT	unk_51;	// [51] meaning not recovered; not used
	INT	unk_52;	// [52] meaning not recovered; not used
	INT	unk_53;	// [53] meaning not recovered; not used
};

/////////////////////////////////////////////////////////////////////
//生物声音定义表					(CREATURE_03)
/////////////////////////////////////////////////////////////////////
#define DBC_CREATURE_SOUND			(203)
struct _DBC_CREATURE_SOUND
{
	INT		nID;
	INT		nAttack;
	INT		nUnderAttack;
	INT		nDeath;
};

//*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-//
//								物品相关								//
//*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-//

/////////////////////////////////////////////////////////////////////
//装备类物品显示定义				(ITEM_01)
/////////////////////////////////////////////////////////////////////
#define	DBC_ITEM_VISUAL_CHAR		(301)
// CYS: client_GL column layout (Canonical ItemVisualChar.txt, 23 columns; B GetDataBase(114, 184)). Registry/abi/dbc_inventory_gl.json holds the evidence.
// CYS: race 0 (female) mesh/material + 9 dye materials, then race 1 (male). The 0.85 pVisualEntity[race*2+part]
// CYS: array and the 30 gem-effect columns do not exist; use CysItemVisualEntity() from CysDBCAccess.h.
struct _DBC_ITEM_VISUAL_CHAR
{
	#define CHAR_RACE_NUM	(2)

	INT	nID;	// [0]
	LPCSTR	pMeshFile_Race0;	// [1] female mesh (GBK key)
	LPCSTR	pMatName_Race0;	// [2] female material list
	LPCSTR	pDyeMat_Race0[9];	// [3..11] dye variants
	LPCSTR	pMeshFile_Race1;	// [12] male mesh
	LPCSTR	pMatName_Race1;	// [13] male material list
	LPCSTR	pDyeMat_Race1[9];	// [14..22] dye variants
};

/////////////////////////////////////////////////////////////////////
//时装外形定义					(CYS-DRESS)
/////////////////////////////////////////////////////////////////////
#define	DBC_ITEM_EQUIP_DRESS		(309)
// CYS-DRESS: CY/GL EquipDress.txt (Canonical: 7 INT columns, 1050 records, id 1..1062). A fashion item's
// CYS-DRESS: EquipBase.Visual is an INDEX INTO THIS TABLE, not an ItemVisualChar id - writing the IVC id into
// CYS-DRESS: Visual makes the game wear a different outfit (tlbb-costume-add-pipeline, trap 1). Column 5 is the
// CYS-DRESS: dye slot (1..9) selecting which of ItemVisualChar's nine dye material columns applies; column 6 is
// CYS-DRESS: the dye group (all nine rows of one outfit share it). Evidence: Docs/specs/server/costumes-all_vi.md.
struct _DBC_ITEM_EQUIP_DRESS
{
	INT	nID;			// [0] index referenced by EquipBase.Visual of an EquipPoint-16 item
	INT	nUnknow_1;		// [1] always -1 in CY
	INT	nVisualID;		// [2] -> DBC_ITEM_VISUAL_CHAR id
	INT	nUnknow_3;		// [3] always -1 in CY
	INT	nUnknow_4;		// [4] always -1 in CY
	INT	nDyeSlot;		// [5] 1..9 dye column of the ItemVisualChar row
	INT	nDyeGroup;		// [6] dye group (nine rows per outfit)
};

/////////////////////////////////////////////////////////////////////
//挂接类物品显示定义				(ITEM_02)
/////////////////////////////////////////////////////////////////////
#define	DBC_ITEM_VISUAL_LOCATOR		(302)
// CYS-CY: CY 3.71 column layout (Assets/CanonicalCY ItemVisualLocator.txt, 63 columns; evidence and client_GL alignment in Registry/abi/dbc_columns_cy.tsv, Docs/specs/cy-switch_vi.md 3.4). unk_N = meaning not recovered, never read.
struct _DBC_ITEM_VISUAL_LOCATOR
{
	INT	nID;	// [0]
	LPCSTR	unk_1;	// [1] empty in every CY row
	LPCSTR	pObjFile_Right;
	LPCSTR	pMatName_Right;	// [3] [SL] empty in CY
	LPCSTR	unk_4;	// [4] empty in CY
	LPCSTR	pObjFile_Left;
	LPCSTR	pMatName_Left;
	LPCSTR	unk_7;	// [7] empty in every CY row
	LPCSTR	unk_8;	// [8] empty in every CY row




	LPCSTR	pObjFile_KFS;	// [9] 武魂 object (KFSObj)
	LPCSTR	pMatName_KFS;	// [10]
	LPCSTR	unk_11;	// [11] empty
	LPCSTR	unk_12;	// [12] empty
	LPCSTR	pObjFile_Foot;	// [13] [SL] FootWeaponObj (toy_*.obj)
	LPCSTR	pMatName_Foot;	// [14]
	LPCSTR	unk_15;	// [15] empty
	LPCSTR	unk_16;	// [16] empty
	LPCSTR	pObjFile_Back;	// [17] [SL] NewBackWeaponObj (大刀 on the back)
	LPCSTR	pMatName_Back;	// [18]
	LPCSTR	pFlag_Back;	// [19] "1" when [17] is set
	LPCSTR	unk_20;	// [20] empty
	LPCSTR	pObjFile_Waist1;	// [21] [SL] WaistWeaponObj1 (双刀右)
	LPCSTR	pMatName_Waist1;	// [22]
	LPCSTR	pFlag_Waist1;	// [23] "1" when [21] is set
	LPCSTR	unk_24;	// [24] empty
	LPCSTR	pObjFile_Waist2;	// [25] [SL] WaistWeaponObj2 (双刀左)
	LPCSTR	pMatName_Waist2;	// [26]
	LPCSTR	pFlag_Waist2;	// [27] "1" when [25] is set
	LPCSTR	unk_28;	// [28] empty
	LPCSTR	pEffectName[30];
	LPCSTR	pTail[4];	// [59..62] kang* effects (client_GL cols 49..52)
};

/////////////////////////////////////////////////////////////////////
//物品定义表_白装					(ITEM_03)
/////////////////////////////////////////////////////////////////////
#define	DBC_ITEM_EQUIP_WHITE		(303)
// CYS: client_GL column layout (Canonical WhiteEquipBase.txt, 93 columns; legacy table, B loads EquipBase.txt instead). Registry/abi/dbc_inventory_gl.json holds the evidence.
struct _DBC_ITEM_EQUIP_WHITE
{
	INT	nID;	// [0]
	INT	nClass;	// [1]
	INT	nQuality;	// [2]
	INT	nType;	// [3]
	INT	nIndex;	// [4]
	INT	nEquipPoint;	// [5]
	INT	nVisualID;	// [6]
	INT	nRule;	// [7] 适应规则
	INT	nSetID;	// [8]
	INT	nSetNum;	// [9]
	LPCSTR	szName;	// [10] (the 0.85 nJob column is gone)
	INT	nLevelRequire;	// [11]
	LPCSTR	szDesc;	// [12]
	INT	nBasePrice;	// [13] 基本价格
	INT	nSalePrice;	// [14] 出售价格
	INT	nBMaxDur;	// [15]
	INT	nBMaxRepair;	// [16]
	INT	nBMaxGem;	// [17]
	INT	nSkillID;	// [18]
	INT	nScriptID;	// [19]
	INT	nBagSlot;	// [20] 行囊
	INT	nBoxSlot;	// [21] 格箱
	INT	NOTCARE[66];	// [22..87] attribute values in ITEM_ATTRIBUTE order + base min/max pairs (0.85 meaning kept)
	LPCTSTR	szIcon;	// [88]
	LPCTSTR	szTypeDesc;	// [89]
	INT	nNameID;	// [90]
	INT	nColor;	// [91]
	INT	nBroadcast;	// [92]
};

/////////////////////////////////////////////////////////////////////
//物品定义表_绿装					(ITEM_04)
/////////////////////////////////////////////////////////////////////
#define	DBC_ITEM_EQUIP_GREEN		(304)
// CYS: client_GL column layout (Canonical GreenEquipBase.txt, 93 columns; legacy table, B loads EquipBase.txt instead). Registry/abi/dbc_inventory_gl.json holds the evidence.
struct _DBC_ITEM_EQUIP_GREEN
{
	INT	nID;	// [0]
	INT	nClass;	// [1]
	INT	nQuality;	// [2]
	INT	nType;	// [3]
	INT	nIndex;	// [4]
	INT	nEquipPoint;	// [5]
	INT	nVisualID;	// [6]
	INT	nRule;	// [7] 适应规则
	INT	nSetID;	// [8]
	INT	nSetNum;	// [9]
	LPCSTR	szName;	// [10] (the 0.85 nJob column is gone)
	INT	nLevelRequire;	// [11]
	LPCSTR	szDesc;	// [12]
	INT	nBasePrice;	// [13] 基本价格
	INT	nSalePrice;	// [14] 出售价格
	INT	nBMaxDur;	// [15]
	INT	nBMaxRepair;	// [16]
	INT	nBMaxGem;	// [17]
	INT	nSkillID;	// [18]
	INT	nScriptID;	// [19]
	LPCTSTR	szIcon;	// [20]
	LPCTSTR	szTypeDesc;	// [21]
	INT	NOTCARE[66];	// [22..87] attribute values in ITEM_ATTRIBUTE order + base min/max pairs (0.85 meaning kept)
	INT	nTail[5];	// [88..92] (WhiteEquipBase: 行囊/格箱/NameID/颜色/广播 - unverified here)
};


/////////////////////////////////////////////////////////////////////
//物品定义表_蓝装					(ITEM_05)
/////////////////////////////////////////////////////////////////////
#define	DBC_ITEM_EQUIP_BLUE		(305)
// CYS: client_GL column layout (Canonical BlueEquipBase.txt, 91 columns; legacy table, B loads EquipBase.txt instead). Registry/abi/dbc_inventory_gl.json holds the evidence.
struct _DBC_ITEM_EQUIP_BLUE
{
	INT	nID;	// [0]
	INT	nClass;	// [1]
	INT	nQuality;	// [2]
	INT	nType;	// [3]
	INT	nIndex;	// [4]
	INT	nEquipPoint;	// [5]
	INT	nVisualID;	// [6]
	INT	nRule;	// [7] 适应规则
	INT	nSetID;	// [8]
	INT	nSetNum;	// [9]
	LPCSTR	szName;	// [10] (the 0.85 nJob column is gone)
	INT	nLevelRequire;	// [11]
	LPCSTR	szDesc;	// [12]
	INT	nBasePrice;	// [13] 基本价格
	INT	nSalePrice;	// [14] 出售价格
	INT	nBMaxDur;	// [15]
	INT	nBMaxRepair;	// [16]
	INT	nBMaxGem;	// [17]
	INT	nSkillID;	// [18]
	INT	nScriptID;	// [19]
	INT	NOTCARE[66];	// [20..85] attribute values in ITEM_ATTRIBUTE order + base min/max pairs (0.85 meaning kept)
	LPCTSTR	szIcon;	// [86]
	LPCTSTR	szTypeDesc;	// [87]
	INT	nTail[3];	// [88..90]
};

/////////////////////////////////////////////////////////////////////
//物品定义表_装备 (client_GL)			(ITEM_16)
/////////////////////////////////////////////////////////////////////
// CYS: B loads EquipBase.txt (table 116) for every equipment item; names from its header row.
#define	DBC_ITEM_EQUIP_BASE		(316)
// CYS-CY: CY 3.71 column layout (Assets/CanonicalCY EquipBase.txt, 103 columns; evidence and client_GL alignment in Registry/abi/dbc_columns_cy.tsv, Docs/specs/cy-switch_vi.md 3.4). unk_N = meaning not recovered, never read.
struct _DBC_ITEM_EQUIP_BASE
{
	INT	nID;	// [0] Index
	INT	nClass;	// [1]
	INT	nQuality;	// [2]
	INT	nType;	// [3]
	INT	nIndex;	// [4]
	INT	nEquipPoint;	// [5]
	INT	nVisualID;	// [6]
	INT	nRule;	// [7]
	INT	nSetID;	// [8]
	INT	nSetEffect;	// [9]
	LPCSTR	szName;	// [10]
	INT	nLevelRequire;	// [11]
	LPCSTR	szMenpaiNeed;	// [12]
	LPCSTR	szDesc;	// [13]
	INT	nBasePrice;	// [14]
	INT	nSalePrice;	// [15]
	INT	nBMaxDur;	// [16]
	INT	nBMaxRepair;	// [17]
	LPCSTR	szIcon;	// [18] client_GL col 21
	LPCSTR	szTypeDesc;	// [19] client_GL col 22
	INT	nHasAptitude;	// [20]
	INT	nQualityAffect;	// [21]
	INT	unk_22;	// [22] meaning not recovered; not used
	INT	unk_23;	// [23] meaning not recovered; not used
	INT	nBaseAttackP;	// [24] client_GL col 25
	INT	nBaseAttackM;	// [25]
	INT	nBaseDefenceP;	// [26]
	INT	nBaseDefenceM;	// [27]
	INT	nBaseHit;	// [28]
	INT	nBaseMiss;	// [29]
	INT	nAttr[58];	// [30..87] client_GL cols 31..88 (ITEM_ATTRIBUTE order; the last four pairs are ambiguous)
	INT	nQualityRule;	// [88]
	INT	nStartValueSeg;	// [89]
	INT	nAttrCountMin;	// [90]
	INT	nAttrCountMax;	// [91]
	INT	nAptitudeMin;	// [92]
	INT	nAptitudeMax;	// [93]
	INT	nUpgradeResID;	// [94]
	INT	nBagSlot;	// [95]
	INT	nBoxSlot;	// [96]
	INT	nBroadcast;	// [97]
	INT	nFloatSpace;	// [98]
	INT	nGrade;	// [99]
	INT	nBMaxGem;	// [100] client_GL col 18
	INT	nSkillID;	// [101] client_GL col 19
	INT	nScriptID;	// [102] client_GL col 20
};

/////////////////////////////////////////////////////////////////////
//物品定义表_药瓶				(ITEM_06)
/////////////////////////////////////////////////////////////////////
#define	DBC_ITEM_MEDIC			(306)
// CYS-CY: CY 3.71 column layout (Assets/CanonicalCY CommonItem.txt, 28 columns; evidence and client_GL alignment in Registry/abi/dbc_columns_cy.tsv, Docs/specs/cy-switch_vi.md 3.4). unk_N = meaning not recovered, never read.
struct _DBC_ITEM_MEDIC
{
	INT	nID;	// [0]
	INT	nClass;	// [1]
	INT	nQuality;	// [2]
	INT	nType;	// [3]
	INT	nIndex;	// [4] Medindex
	LPCSTR	szIcon;	// [5]
	LPCSTR	szName;	// [6]
	LPCSTR	szDesc;	// [7]
	INT	nLevelRequire;	// [8]
	INT	nBasePrice;	// [9]
	INT	nSalePrice;	// [SL] position
	INT	nRule;	// [11] 适应规则
	INT	nPileCount;	// [12]
	INT	nScriptID;	// [13]
	INT	nSkillID;	// [14]
	INT	nNeedSkill;	// [15]
	INT	nNeedSkillLevel;	// [16]
	INT	nMaxHold;	// [17]
	INT	nTargetType;	// [18] ENUM_ITEM_TARGET_TYPE
	LPCSTR	szTypeDesc;	// [19]
	INT	nGradeLevel;	// [20]
	INT	nRecipeID;	// [21]
	INT	nColor;	// [22]
	INT	nSubClass;	// [23]
	INT	nBroadcast;	// [24]
	INT	unk_25;	// [25] meaning not recovered; not used
	INT	unk_26;	// [26] meaning not recovered; not used
	INT	nConsume;	// [27] 是否消耗 (client_GL col 15)
};

/////////////////////////////////////////////////////////////////////
//物品定义表_宝石				(ITEM_07)
/////////////////////////////////////////////////////////////////////
#define	DBC_ITEM_GEM			(307)
// CYS-CY: CY 3.71 column layout (Assets/CanonicalCY GemInfo.txt, 84 columns; evidence and client_GL alignment in Registry/abi/dbc_columns_cy.tsv, Docs/specs/cy-switch_vi.md 3.4). unk_N = meaning not recovered, never read.
struct _DBC_ITEM_GEM
{
	INT	nID;	// [0]
	INT	nClass;	// [1]
	INT	nQuality;	// [2]
	INT	nType;	// [3]
	INT	nGemIndex;	// [4]
	LPCSTR	szIcon;	// [5]
	INT	nRule;	// [6]
	LPCSTR	szName;	// [7]
	LPCSTR	szDesc;	// [8]
	INT	nPrice;	// [9]
	INT	nSalePrice;	// [10]
	INT	nAttr[54];	// [11..64] ITEM_ATTRIBUTE 0..53
	INT	nReduceResist[4];	// [65..68] 降低目标冰/火/玄/毒抵抗
	INT	nBaseAttr[6];	// [69..74] ITEM_ATTRIBUTE 54..59 (use CysGemAttr())
	LPCSTR	szColor;	// [75]
	LPCSTR	szTypeDesc;	// [76]
	INT	nEffectIndex;	// [77]
	INT	nColor;	// [78]
	INT	nBroadcast;	// [79]
	INT	unk_80;	// [80] meaning not recovered; not used
	INT	unk_81;	// [81] meaning not recovered; not used
	INT	unk_82;	// [82] meaning not recovered; not used
	INT	nPileCount;	// [83] client_GL col 80
};

/////////////////////////////////////////////////////////////////////
//物品定义表_地图				(ITEM_08)
/////////////////////////////////////////////////////////////////////
#define	DBC_ITEM_STOREMAP			(308)
// CYS: client_GL column layout (Canonical StoreMapItem.txt, 15 columns). Registry/abi/dbc_inventory_gl.json holds the evidence.
struct _DBC_ITEM_STOREMAP
{
	INT	nID;	// [0]
	INT	nClass;	// [1]
	INT	nQuality;	// [2]
	INT	nType;	// [3]
	INT	nIndex;	// [4]
	LPCSTR	szIcon;	// [5]
	LPCSTR	szName;	// [6]
	LPCSTR	szDesc;	// [7]
	INT	nLevelRequire;	// [8]
	INT	nRule;	// [9]
	FLOAT	fCol10;	// [10]
	FLOAT	fCol11;	// [11]
	INT	nCol12;	// [12]
	INT	nCol13;	// [13]
	INT	nCol14;	// [14]
};

/////////////////////////////////////////////////////////////////////
//套装组合后附加属性			(ITEM_15)
/////////////////////////////////////////////////////////////////////
#define	DBC_ITEM_SETATT			(315)
// CYS: client_GL column layout (Canonical EquipSetAttr.txt, 37 columns; names from the server header). Registry/abi/dbc_inventory_gl.json holds the evidence.
struct _DBC_ITEM_SETATT
{
	INT	nID;	// [0] 套装编号
	LPCSTR	szName;	// [1] 套装名字
	INT	nPartNum;	// [2] 组件数
	INT	nEffectID;	// [3] 特效
	INT	nBindPoint;	// [4] 绑定点
	INT	nAttrPair[32];	// [5..36] 16 x (效果类型, 效果值); 0.85 had one column per attribute
};


//*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-//
//								声音相关								//
//*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-//

/////////////////////////////////////////////////////////////////////
//声音文件定义						(SOUND_01)
/////////////////////////////////////////////////////////////////////
#define DBC_SOUND_INFO				(401)
// CYS: client_GL column layout (Canonical SoundInfo.txt, 3 columns). Registry/abi/dbc_inventory_gl.json holds the evidence.
struct _DBC_SOUND_INFO
{
	INT	nID;	// [0]
	LPCSTR	pSoundFile;	// [1]
	LPCSTR	pDesc;	// [2] optional description
};


//*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-//
//								特效相关								//
//*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-//

/////////////////////////////////////////////////////////////////////
//特效定义							(EFFECT_01)
/////////////////////////////////////////////////////////////////////
#define DBC_EFFECT_DEFINE			(501)
// CYS: client_GL column layout (Canonical EffectDefine.txt, 4 columns; Reference has the same INT/STRING/INT/INT layout). Registry/abi/dbc_inventory_gl.json holds the evidence.
struct _DBC_EFFECT_DEFINE
{
	INT	nID;	// [0]
	LPCSTR	pEffectType;	// [1]
	INT	nParam1;	// [2]
	INT	nParam2;	// [3]
};

//*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-//
//								技能相关								//
//*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-//
/////////////////////////////////////////////////////////////////////
//心法定义表						(SKILL_01)
/////////////////////////////////////////////////////////////////////
#define DBC_SKILL_XINFA				(601)
struct _DBC_XINFA_LEVEL_RATE
{
	INT	nLevel;	// 心法等级段
	FLOAT	fRate;	// 心法修正率
};
// CYS-CY: CY 3.71 column layout (Assets/CanonicalCY XinFa_V1.txt, 37 columns; evidence and client_GL alignment in Registry/abi/dbc_columns_cy.tsv, Docs/specs/cy-switch_vi.md 3.4). unk_N = meaning not recovered, never read.
struct _DBC_SKILL_XINFA
{
	INT	nID;	// [0]
	INT	nMenpaiID;	// [1]
	LPCSTR	pszName;	// [2]
	LPCSTR	pszDesc;	// [3]
	LPCSTR	pszIconName;	// [4]
	INT	nAttrLogic;	// [5]
	FLOAT	fModifyRate;	// [6] (unused)
	INT	nLearnDirect;	// [7]
	INT	nLevelLimit;	// [8]
	_DBC_XINFA_LEVEL_RATE	aLevelRate[14];	// [9..36] 14 (level, rate) pairs; client_GL had 10
};

/////////////////////////////////////////////////////////////////////
//附加效果							(SKILL_02)
/////////////////////////////////////////////////////////////////////
#define DBC_SKILL_ADDIMPACT			(602)
struct _DBC_SKILL_ADDIMPACT
{
	INT		nID;
	LPCSTR	pDesc;
	INT		nParamNum;
	INT		nAddAttributeNum;
	LPCSTR	pAddAttribute1;
	LPCSTR	pAddAttribute2;
	LPCSTR	pAddAttribute3;
	LPCSTR	pAddAttribute4;
	INT		nSpliceID;
	LPCSTR	pIcon;
};
//
///////////////////////////////////////////////////////////////////////
////子弹效果定义						(SKILL_03)
///////////////////////////////////////////////////////////////////////
//#define DBC_SKILL_BULLET			(603)
//struct _DBC_SKILL_BULLET
//{
//	INT		nID;							//子弹类型
//	INT		nType;							/*
//											|	0 - 瞬间到达
//											|	1 - 移动到达
//											*/
//	INT		nEffect;						//特效ID
//	FLOAT	fSpeed;							//移动速度	(m/s)
//	INT		nHitEffect;						//击中特效
//	INT		nHitEffectLiveTime;				//击中特效维持时间
//};

/////////////////////////////////////////////////////////////////////
//BUFF附加效果						(BUFF_IMPACT)
/////////////////////////////////////////////////////////////////////
#define DBC_BUFF_IMPACT					(604)
//_DBC_BUFF_IMPACT

/////////////////////////////////////////////////////////////////////
//DIRECTLY附加效果						(DIRECTLY_IMPACT)
/////////////////////////////////////////////////////////////////////
#define DBC_DIRECTLY_IMPACT				(605)
//_DBC_DIRECTLY_IMPACT

/////////////////////////////////////////////////////////////////////
//子弹						(BULLET)
/////////////////////////////////////////////////////////////////////
#define DBC_BULLET_DATA					(606)
//_DBC_BULLET_DATA

/////////////////////////////////////////////////////////////////////
//技能						(SKILL)
/////////////////////////////////////////////////////////////////////
#define DBC_SKILL_DATA					(607)
//_DBC_SKILL_DATA

/////////////////////////////////////////////////////////////////////
//技能						(SKILL_DEPLETE)
/////////////////////////////////////////////////////////////////////
#define DBC_SKILL_DEPLETE					(608)
// CYS-CY: CY 3.71 column layout (Assets/CanonicalCY SkillDeplete.txt, 6 columns; evidence and client_GL alignment in Registry/abi/dbc_columns_cy.tsv, Docs/specs/cy-switch_vi.md 3.4). unk_N = meaning not recovered, never read.
struct _DBC_SKILL_DEPLETE
{
	INT	m_nID;	// [0]
	INT	m_nHP;	// [1]
	INT	m_nMP;	// [2]
	INT	m_nSP;	// [3]
	INT	m_nStrikePoint;	// [4]
	INT	m_nItemID;	// [5]
};

/////////////////////////////////////////////////////////////////////
//任务						(MISSION)
/////////////////////////////////////////////////////////////////////
#define DBC_MISSION_LIST				(610)
struct _DBC_MISSION_LIST
{
	INT				nScriptID;
	INT				nMissionID;
	INT				nReward;
	INT				nPunish;
	INT				nDialog;
	INT				nPromulgatorScene;
	INT				nPromulgatorID;
	INT				nSubmitorScene;
	INT				nSubmitorID;
	INT				nDestScene;
	INT				nDestX;
	INT				nDestZ;
};

#define DBC_MISSION_DATA				(611)
// CYS: client_GL MissionData.txt has 6 columns / 1 row; the 0.85 43-column mission tables are gone (B does not
// CYS: load MissionList/Reward/Punish/Dialog). Names of these 6 columns are the 0.85 ones, unverified.
struct _DBC_MISSION_DATA
{
	INT	nMissionID;	// [0]
	INT	nMissionClass;	// [1]
	INT	nMissionSubClass;	// [2]
	INT	nMissionType;	// [3]
	INT	nMissionLevel;	// [4]
	INT	nLevel;	// [5]
};

#define DBC_MISSION_REWARD				(612)
struct _DBC_MISSION_REWARD
{
	INT			nRewardID;
	INT			nMoney;
	INT			nItem1ID;
	INT			nItem1Num;
	INT			nItem2ID;
	INT			nItem2Num;
	INT			nItem3ID;
	INT			nItem3Num;
	INT			nItem4ID;
	INT			nItem4Num;
	INT			nItem5ID;
	INT			nItem5Num;
	INT			nItem6ID;
	INT			nItem6Num;
	INT			nExp;
	INT			nLevel;
	INT			nGuildExp1;
	INT			nGuildExp2;
	INT			nGuildExp3;
	INT			nBuff1ID;
	INT			nBuff2ID;
	INT			nBuff3ID;
};

#define DBC_MISSION_PUNISH				(613)
struct _DBC_MISSION_PUNISH
{
	INT		nPunishID;
	INT		nMoney;
	INT		nItem1ID;
	INT		nItem1Num;
	INT		nItem2ID;
	INT		nItem2Num;
	INT		nItem3ID;
	INT		nItem3Num;
	INT		nExp;
	INT		nLevel;
	INT		nMissionTag;
};

#define DBC_MISSION_DIALOG				(614)
struct _DBC_MISSION_DIALOG
{
	INT			nDialogID;
	LPCSTR		szMissionName;		//任务名称
	LPCSTR		szMissionDesc;	//任务描述
	LPCSTR		szMissionTarget;	//任务目标
	LPCSTR		szMissionContinue;	//继续任务
	LPCSTR		szMissionAbandon;	//放弃任务
	LPCSTR		szMissionSuccess;	//完成任务
};

/////////////////////////////////////////////////////////////////////
//法术OBJ数据						(SPECIAL_OBJ_DATA)
/////////////////////////////////////////////////////////////////////
#define DBC_SPECIAL_OBJ_DATA			(630)
// CYS-CY: (参数说明 STRING, 参数值 INT) pair of CY 3.71 SpecialObjData.txt.
struct _DBC_SPECIAL_OBJ_PARAM
{
	LPCSTR	szDesc;
	INT	nValue;
};

// CYS-CY: CY 3.71 column layout (Assets/CanonicalCY SpecialObjData.txt, 63 columns; evidence and client_GL alignment in Registry/abi/dbc_columns_cy.tsv, Docs/specs/cy-switch_vi.md 3.4). unk_N = meaning not recovered, never read.
struct _DBC_SPECIAL_OBJ_DATA
{
	INT	m_nID;	// [0]
	LPCSTR	m_lpszName;	// [1]
	LPCSTR	m_lpszToolTips;	// [2]
	INT	m_nType;	// [3]
	INT	m_nLogicID;	// [4]
	INT	m_nStealthLevel;	// [5]
	INT	m_nTrapFlags;	// [6]
	INT	m_nActiveTimes;	// [7]
	LPCSTR	m_lpszEffect_Normal;	// [8]
	INT	m_nSound_Normal;	// [9]
	LPCSTR	m_lpszEffect_Active;	// [10]
	INT	m_nSound_Active;	// [11]
	LPCSTR	m_lpszEffect_Die;	// [12]
	INT	m_nSound_Die;	// [13]
	INT	m_nReserve1;	// [14]
	INT	m_nReserve2;	// [15]
	INT	m_nReserve3;	// [16]
	INT	m_nBulletID;	// [17]
	INT	m_nDuration;	// [18]
	INT	m_nInterval;	// [19]
	FLOAT	m_nTriggerRadius;	// [20]
	FLOAT	m_nEffectRadius;	// [21]
	INT	m_nReserveA;	// [22]
	INT	m_nReserveB;	// [23]
	INT	m_nEffectUnitNum;	// [24]
	_DBC_SPECIAL_OBJ_PARAM	m_aParam[16];	// [25..56] 16 (参数说明 STRING, 参数值 INT); client_GL had 6 reserve INTs before them
	LPCSTR	unk_57;	// [57] meaning not recovered; not used
	INT	unk_58;	// [58] meaning not recovered; not used
	INT	unk_59;	// [59] meaning not recovered; not used
	INT	unk_60;	// [60] meaning not recovered; not used
	INT	unk_61;	// [61] meaning not recovered; not used
	INT	unk_62;	// [62] meaning not recovered; not used
};

//*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-//
//								场景相关相关							//
//*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-//

/////////////////////////////////////////////////////////////////////
//场景定义							(SCENE_01)
/////////////////////////////////////////////////////////////////////
#define DBC_SCENE_DEFINE			(701)
// CYS: B looks scenes up with Search_Index_EQU(<scene id sent by the server>): column 0 is both the local and the
// CYS: server scene id. The 0.85 nLocalID/nServerID/nCityLevel columns do not exist.
// CYS-CY: CY 3.71 column layout (Assets/CanonicalCY SceneDefineEx.txt, 25 columns; evidence and client_GL alignment in Registry/abi/dbc_columns_cy.tsv, Docs/specs/cy-switch_vi.md 3.4). unk_N = meaning not recovered, never read.
struct _DBC_SCENE_DEFINE
{
	static const int SCENE_SERVER_ID_COLUMN = 0;

	INT	nServerID;	// [0] scene id
	LPCSTR	szName;	// [1]
	INT	nXSize;	// [2]
	INT	nZSize;	// [3]
	LPCSTR	szWXObjectName;	// [4] *.Scene
	LPCSTR	szRegionFile;	// [5] *.path navmesh
	LPCSTR	szCollisionfile;	// [6]
	LPCSTR	szMiniMap;	// [7]
	INT	nBackSound;	// [8]
	INT	nCol9;	// [9]
	LPCSTR	szSceneMap;	// [10]
	INT	nWroldMapPosX;	// [11]
	INT	nWroldMapPosY;	// [12]
	INT	nNameWroldMapPosX;	// [13]
	INT	nNameWroldMapPosY;	// [14]
	INT	nCameraFarClip;	// [15] CY 3.71 Game.exe 1406be4ff..1406bec17: CScene +0x8c = (float)row[+0x58] -> far clip
	INT	nCameraNearClip;	// [16] CScene +0x90 = (float)row[+0x5c] -> near clip
	LPCSTR	szSceneType;	// [17]
	LPCSTR	szCityNameNormalImageSet;	// [18]
	LPCSTR	szCityNameNormalImage;	// [19]
	LPCSTR	szCityNameHoverImageSet;	// [20]
	LPCSTR	szCityNameHoverImage;	// [21]
	LPCSTR	szDisplayName;	// [22]
	LPCSTR	szCol23;	// [23]
	INT	unk_24;	// [24] new in CY 3.71 (0/1/4); meaning not recovered
};

/////////////////////////////////////////////////////////////////////
//场景建筑物定义					(SCENE_02)
/////////////////////////////////////////////////////////////////////
#define DBC_BUILDING_DEINFE			(702)
// CYS: client_GL column layout (Canonical BuildingDefine.txt, 8 columns). Registry/abi/dbc_inventory_gl.json holds the evidence.
struct _DBC_BUILDING_DEFINE
{
	static const int MAX_LEVEL = 5;

	INT	nID;	// [0]
	LPCSTR	szResType;	// [1]
	LPCSTR	szLevel[MAX_LEVEL];	// [2..6]
	LPCSTR	szCol7;	// [7]
};

/////////////////////////////////////////////////////////////////////
//城市建筑物定义					(SCENE_03)
/////////////////////////////////////////////////////////////////////
#define DBC_CITY_BUILDING			(703)
// CYS: client_GL column layout (Canonical CityBuilding.txt, 23 columns; names from the server header). Registry/abi/dbc_inventory_gl.json holds the evidence.
struct _DBC_CITY_BUILDING
{
	INT	nID;	// [0]
	INT	nCityID;	// [1]
	LPCSTR	szName;	// [2]
	INT	nBuildingType;	// [3]
	INT	nBuildingID;	// [4]
	INT	nInitLevel;	// [5]
	LPCSTR	szGfxPosition;	// [6]
	LPCSTR	szGfxOrientation;	// [7]
	INT	nLevelRequire[5];	// [8..12]
	INT	nResearchItem[5];	// [13..17]
	INT	nMaintain[5];	// [18..22]
};

/////////////////////////////////////////////////////////////////////
//场景传送点定义							(SCENE_02)
/////////////////////////////////////////////////////////////////////
#define DBC_SCENE_POS_DEFINE			(917)
struct _DBC_SCENE_POS_DEFINE
{
	INT		nID;				// id
	LPCSTR	szSceneName;		// 场景的名字
	INT		nSceneID;			// 场景的id
	INT		nXPos;				// 传送点的位置
	INT		nZPos;				// 传送点的位置
	LPCSTR	szAimName;			// 传送到哪个场景
};

//*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-//
//								UI相关									//
//*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-//
/////////////////////////////////////////////////////////////////////
//UI组定义						(UI_01)
/////////////////////////////////////////////////////////////////////
#define DBC_UI_LAYOUTDEFINE		(801)
// CYS-CY 14/09: user directive "Mọi thứ như CY": the GUI tables follow CY 3.71 too. CY InterfaceEx.txt has 10 columns
// CYS-CY: (S2 DataCY Config/InterfaceEx.txt header INT STRING STRING STRING INT STRING INT INT INT STRING; S4 10 columns,
// CYS-CY: 1975 rows). client_GL had 9 (no column 8). CUIWindowItem reads only [0..4], whose offsets are the same in both.
struct _DBC_UI_LAYOUTDEFINE
{
	INT	nID;	// [0]
	LPCSTR	szName;	// [1] window name
	LPCSTR	szLayout;	// [2] *.layout.xml
	LPCSTR	szScript;	// [3] *.lua
	INT	nDemise;	// [4]
	LPCSTR	szCol5;	// [5] group key (wgzs, jbsx, ltzs...)
	INT	nCol6;	// [6]
	INT	nCol7;	// [7]
	INT	unk_8;	// [8] new in CY 3.71 (-1 in the S2 rows read); meaning not recovered, not used
	LPCSTR	szDesc;	// [9] description (GBK)
};


//*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-//
//								生活技能相关							//
//*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-//
/////////////////////////////////////////////////////////////////////
//资源生长点							(LIFE_01)
/////////////////////////////////////////////////////////////////////
#define DBC_LIFEABILITY_GROWPOINT		(901)
// CYS-CY: CY 3.71 column layout (Assets/CanonicalCY GrowPoint.txt, 19 columns; evidence and client_GL alignment in Registry/abi/dbc_columns_cy.tsv, Docs/specs/cy-switch_vi.md 3.4). unk_N = meaning not recovered, never read.
struct _DBC_LIFEABILITY_GROWPOINT
{
	INT	nID;	// [0]
	LPCSTR	szName;	// [1]
	LPCSTR	szMeshFile;	// [2]
	INT	nLifeAbility;	// [3]
	INT	nMissionID;	// [4]
	LPCSTR	szTips;	// [5]
	INT	nTimeNeed;	// [6]
	INT	nScriptID;	// [7]
	INT	nAnimOpen;	// [8]
	INT	unk_9;	// [9] meaning not recovered; not used
	INT	unk_10;	// [10] meaning not recovered; not used
	INT	unk_11;	// [11] meaning not recovered; not used
	INT	unk_12;	// [12] meaning not recovered; not used
	INT	unk_13;	// [13] meaning not recovered; not used
	INT	unk_14;	// [14] meaning not recovered; not used
	INT	unk_15;	// [15] meaning not recovered; not used
	INT	unk_16;	// [16] meaning not recovered; not used
	INT	unk_17;	// [17] meaning not recovered; not used
	INT	unk_18;	// [18] meaning not recovered; not used
};

/////////////////////////////////////////////////////////////////////
//生活技能								(LIFE_02)
/////////////////////////////////////////////////////////////////////
#define DBC_LIFEABILITY_DEFINE	(902)
// CYS: client_GL column layout (Canonical Ability.txt, 21 columns; names from the server header). Registry/abi/dbc_inventory_gl.json holds the evidence.
struct _DBC_LIFEABILITY_DEFINE
{
	INT	nID;	// [0]
	LPCSTR	szName;	// [1]
	INT	nLevelNeed;	// [2]
	INT	nLevelMax;	// [3]
	LPCSTR	szLevelUpTable;	// [4] 升级需求和消耗表
	INT	nTimeOperation;	// [5] 操作时间基数
	INT	nToolNeed;	// [6]
	INT	nToolNeed2;	// [7]
	FLOAT	fPlatformDist;	// [8]
	INT	nPlatformID;	// [9]
	INT	nAnimOperation;	// [10]
	LPCSTR	szIconName;	// [11]
	INT	nItemVisualLocator;	// [12]
	LPCSTR	szExplain;	// [13]
	INT	nPopup;	// [14]
	LPCSTR	szProgressbarName;	// [15]
	INT	nConsumeType;	// [16]
	INT	nSoundStart;	// [17]
	INT	nSoundLoop;	// [18]
	INT	nSoundSuccess;	// [19]
	INT	nSoundFail;	// [20]
};

/////////////////////////////////////////////////////////////////////
//生活技能								(LIFE_03)
/////////////////////////////////////////////////////////////////////
#define DBC_LIFEABILITY_ITEMCOMPOSE		(903)
// CYS-CY: CY 3.71 column layout (Assets/CanonicalCY ItemCompound.txt, 38 columns; evidence and client_GL alignment in Registry/abi/dbc_columns_cy.tsv, Docs/specs/cy-switch_vi.md 3.4). unk_N = meaning not recovered, never read.
struct _DBC_LIFEABILITY_ITEMCOMPOSE
{
	INT	nID;	// [0]
	LPCSTR	szName;	// [1]
	INT	nResultID;	// [2]
	INT	nResultNum;	// [3]
	INT	nLifeAbility;	// [4]
	INT	nLifeAbility_Level;	// [5]
	INT	nStuff1ID;	// [6]
	INT	nStuff1num;	// [7]
	INT	nStuff2ID;	// [8]
	INT	nStuff2num;	// [9]
	INT	nStuff3ID;	// [10]
	INT	nStuff3num;	// [11]
	INT	nStuff4ID;	// [12]
	INT	nStuff4num;	// [13]
	INT	nStuff5ID;	// [14]
	INT	nStuff5num;	// [15]
	INT	nAttribute_ID1;	// [16]
	INT	unk_17;	// [17] meaning not recovered; not used
	INT	unk_18;	// [18] meaning not recovered; not used
	INT	unk_19;	// [19] meaning not recovered; not used
	INT	NOTCARE;	// [20] client_GL col 25
	INT	nProficiencyTime;	// [21] 配方时间 (client_GL col 26, 3000)
	INT	nScriptID;	// [22] client_GL col 27
	INT	nFailItem;	// [23] client_GL col 28
	LPCSTR	szExplain;	// [24] client_GL col 29
	INT	unk_25;	// [25] meaning not recovered; not used
	INT	unk_26;	// [26] meaning not recovered; not used
	INT	unk_27;	// [27] meaning not recovered; not used
	INT	unk_28;	// [28] meaning not recovered; not used
	INT	unk_29;	// [29] meaning not recovered; not used
	INT	unk_30;	// [30] meaning not recovered; not used
	INT	unk_31;	// [31] meaning not recovered; not used
	INT	unk_32;	// [32] meaning not recovered; not used
	INT	unk_33;	// [33] meaning not recovered; not used
	INT	unk_34;	// [34] meaning not recovered; not used
	INT	nProficiencyRequire;	// [35] client_GL col 23
	INT	nProficiencyIncrease;	// [36] client_GL col 24
	INT	nQualityRule;	// [37] client_GL col 30
};

/////////////////////////////////////////////////////////////////////
//生活技能								(LIFE_04)
/////////////////////////////////////////////////////////////////////
#define DBC_LIFEABILITY_PLATFORM		(904)
struct _DBC_LIFEABILITY_PLATFORM
{
	INT		nID;
	INT		nType;
	LPCSTR	szName;
	LPCSTR	szMeshFile;
	INT		nClickType;
};
/////////////////////////////////////////////////////////////////////
// 表情和颜色转换字符
/////////////////////////////////////////////////////////////////////
#define DBC_CODE_CONVERT			( 905 )
struct _DBC_CODE_CONVERT
{
	INT		nID;		// ID
	LPCSTR  szName;		// 介绍
	LPCSTR  szCode;		// 字符串形式的十六进制数字
};






















#define DBC_XINFA_XINFADEFINE	DBC_SKILL_XINFA	// = 601, XinFa_V1.txt; see _DBC_SKILL_XINFA for the full 37 columns
// Makes the conclusion above self-enforcing: give this name a number of its own again and the build stops here,
// instead of the clash being found years later (the 0.85 one never was).
static_assert(DBC_XINFA_XINFADEFINE == DBC_SKILL_XINFA,
	"DBC_XINFA_XINFADEFINE must stay an alias of DBC_SKILL_XINFA (601, XinFa_V1.txt); it owned 902, the id of "
	"DBC_LIFEABILITY_DEFINE / Ability.txt. See Timeline/handoff/dbc-id-dup.md.");
static_assert(DBC_LIFEABILITY_DEFINE != DBC_SKILL_XINFA,
	"Ability.txt and XinFa_V1.txt are two tables and may never share one DBC id.");
struct _DBC_XINFA_XINFADEFINE	// prefix of _DBC_SKILL_XINFA; kept for the record, no loader uses it
{
	INT		nID;			//心法ID
	INT		nIDMenpai;		//门派ID
	LPCSTR	szName;			//心法名称
	LPCSTR	szTips;			//心法描述
	LPCSTR	szIconName;		//图标名称
};
/////////////////////////////////////////////////////////////////////
//心法升级花费						(XINFA_02)
/////////////////////////////////////////////////////////////////////
struct Spend
{
	INT		dwSpendMoney;			// 需要花费的金钱数
	INT		dwSpendExperience;		// 需要花费的经验值
};
#define DBC_XINFA_STUDYSPEND	(907)










#define DBC_XINFA_STUDYSPEND_SLOTS	(121)
struct _DBC_XINFA_STUDYSPEND
{
	INT		nLineNum;				// 行号 (1..302)
	INT		nStudyLevel;			// 要学习的等级 (888 = 心法槽索引行, 999 = 钱/经验标志行)
	Spend	StudySpend[DBC_XINFA_STUDYSPEND_SLOTS];
};

/////////////////////////////////////////////////////////////////////
//称号列表						(TITLE)
/////////////////////////////////////////////////////////////////////
#define DBC_TITLE_NAME			(908)
// CYS-CY: CY 3.71 column layout (Assets/CanonicalCY CharTitle.txt, 50 columns; evidence and client_GL alignment in Registry/abi/dbc_columns_cy.tsv, Docs/specs/cy-switch_vi.md 3.4). unk_N = meaning not recovered, never read.
struct _DBC_TITLE_NAME
{
	INT	nTitleIndex;	// [0]
	INT	nReserve;	// [1]
	LPCSTR	szTitle;	// [2]
	LPCSTR	szTitleDesc;	// [3]
	INT	nLogicType;	// [4]
	INT	nLevel;	// [5]
	INT	nTime;	// [6]
	LPCSTR	szComment;	// [7]
	INT	nCol8;	// [8]
	LPCSTR	szCol9;	// [9]
	INT	nColEx[40];	// [10..49]
};
/////////////////////////////////////////////////////////////////////
//阵营数据	
/////////////////////////////////////////////////////////////////////
#define DBC_CAMP_DATA	(909)

/////////////////////////////////////////////////////////////////////
//技能	skillData_v1.txt(读取表)					
/////////////////////////////////////////////////////////////////////
#define DBC_SKILLDATA_V1_DEPLETE					(910)
// CYS: client_GL pairs are (参数说明 STRING, 参数值 INT); 0.85 declared (INT, STRING).
struct _DBC_SKILLDATA_V1_DATA_PAIR
{
	LPCSTR	szDesc;
	INT	nData;
};
// CYS: the 0.85 nNeedLevel/nNeedMoney columns do not exist (columns 3/4 are descriptions).
// CYS: the three condition groups (条件或消耗参数说明 STRING, 条件和消耗逻辑 INT, 值1 INT, 值2 INT) are plain members: a
// CYS: nested {LPCSTR, INT, INT, INT} struct is padded to 24 bytes on x64, but the record puts column 21 at +20.
// CYS-CY: CY 3.71 column layout (Assets/CanonicalCY SkillData_V1.txt, 54 columns; evidence and client_GL alignment in Registry/abi/dbc_columns_cy.tsv, Docs/specs/cy-switch_vi.md 3.4). unk_N = meaning not recovered, never read.
struct _DBC_SKILLDATA_V1_DEPLETE
{
	INT	nId;	// [0]
	LPCSTR	szSkillDesc_Tip;	// [1] 技能描述(FOR TIP) (client_GL col 3)
	LPCSTR	Skill_Desc_Interface;	// [2] 技能描述(FOR Interface) (client_GL col 4)
	INT	nCeHuaId;	// [3] client_GL col 1
	LPCSTR	szEffectDesc;	// [4] client_GL col 2
	INT	nSkillLogicid;	// [5]
	INT	nCooldownTime;	// [6]
	INT	nJuqiTime;	// [7]
	INT	nDirectTime;	// [8]
	LPCSTR	szCondition1Desc;	// [9]
	INT	nCondition1Logic;	// [10]
	INT	nCondition1Value1;	// [11]
	INT	nCondition1Value2;	// [12]
	LPCSTR	szCondition2Desc;	// [13]
	INT	nCondition2Logic;	// [14]
	INT	nCondition2Value1;	// [15]
	INT	nCondition2Value2;	// [16]
	LPCSTR	szCondition3Desc;	// [17]
	INT	nCondition3Logic;	// [18]
	INT	nCondition3Value1;	// [19]
	INT	nCondition3Value2;	// [20]
	INT	nTargetLevel;	// [21]
	INT	nReserved1;	// [22]
	INT	nReserved2;	// [23]
	_DBC_SKILLDATA_V1_DATA_PAIR	paraPair[15];	// [24..53] 15 (参数说明, 参数值) pairs; client_GL had 12
};

/////////////////////////////////////////////////////////////////////
//称号列表						(MissionKind)
/////////////////////////////////////////////////////////////////////
#define DBC_MISSION_KIND			(911)
struct _DBC_MISSION_KIND
{
	INT		nIndex;					// 任务种类的索引
	LPCSTR	szKindName;				// 任务种类的名字
};

/////////////////////////////////////////////////////////////////////
// 表情和颜色转换字符
/////////////////////////////////////////////////////////////////////
#define DBC_STRING_DICT			( 912 )
// CYS: client_GL column layout (Canonical StrDictionary.txt, 2 columns; the 0.85 INT id column is gone). Registry/abi/dbc_inventory_gl.json holds the evidence.
struct _DBC_STRING_DICT
{
	LPCSTR	szKey;	// [0] 关键字 (UTF-8)
	LPCSTR	szString;	// [1]
};


/////////////////////////////////////////////////////////////////////
// 环境音效列表
/////////////////////////////////////////////////////////////////////
#define DBC_ENV_SOUND			( 913 )
struct _DBC_ENV_SOUND
{
	INT		nID;			// ID
	UINT	nSoundID;		// 音效ID
	UINT	nXPos;			// 声源的X坐标
	UINT	nZPos;			// 声源的Z坐标
	UINT	nDistance;		// 能听到声音的最大距离
};

/////////////////////////////////////////////////////////////////////
// 物品规则表
/////////////////////////////////////////////////////////////////////
#define DBC_ITEM_RULE			( 914 )
// CYS-CY: CY 3.71 column layout (Assets/CanonicalCY ItemRule.txt, 15 columns; evidence and client_GL alignment in Registry/abi/dbc_columns_cy.tsv, Docs/specs/cy-switch_vi.md 3.4). unk_N = meaning not recovered, never read.
struct _DBC_ITEM_RULE
{
	INT	nID;	// [0]
	INT	bCanDrop;	// [1]
	INT	bCanOverLay;	// [2]
	INT	bCanQuick;	// [3]
	INT	bCanSale;	// [4]
	INT	bCanExchange;	// [5]
	INT	bCanUse;	// [6]
	INT	bPickBind;	// [7]
	INT	bEquipBind;	// [8]
	INT	bUnique;	// [9]
	INT	bNeedIdentify;	// [10]
	INT	bVirtual;	// [11]
	INT	bCanBank;	// [12]
	INT	bQuickStack;	// [13]
	INT	unk_14;	// [14] meaning not recovered; not used
};

/////////////////////////////////////////////////////////////////////
// 过滤词词汇表
/////////////////////////////////////////////////////////////////////
#define DBC_TALK_FILTER			( 915 )
// CYS: client_GL column layout (Canonical StrFilter.txt, 3 columns; names from its header row). Registry/abi/dbc_inventory_gl.json holds the evidence.
struct _DBC_TALK_FILTER
{
	INT	nID;	// [0] 序号
	LPCSTR	szString;	// [1] 检测内容
	INT	nFilterRule;	// [2] 过滤规则
};

/////////////////////////////////////////////////////////////////////
// 等级金钱对应表
/////////////////////////////////////////////////////////////////////
#define DBC_LV_MAXMONEY			( 916 )
// CYS-CY: CY 3.71 column layout (Assets/CanonicalCY LvMaxMoney.txt, 12 columns; evidence and client_GL alignment in Registry/abi/dbc_columns_cy.tsv, Docs/specs/cy-switch_vi.md 3.4). unk_N = meaning not recovered, never read.
struct _DBC_LV_MAXMONEY
{
	INT	nID;	// [0]
	INT	nLv;	// [1]
	INT	nMaxMoney;	// [2] client_GL col 2
	INT	nMaxMoneyEx[9];	// [3..11] further money limits (values grow with column); meaning not recovered
};

/////////////////////////////////////////////////////////////////////
// 聊天动作命令表
/////////////////////////////////////////////////////////////////////
#define DBC_TALK_ACT			( 918 )
// CYS: client_GL column layout (Canonical ChatMood.txt, 14 columns). Registry/abi/dbc_inventory_gl.json holds the evidence.
struct _DBC_TALK_ACT
{
	INT	nID;	// [0]
	LPCSTR	szCmd;	// [1]
	LPCSTR	szNobody;	// [2]
	LPCSTR	szMyself;	// [3]
	LPCSTR	szOther;	// [4]
	INT	nCol5;	// [5] new
	INT	nCol6;	// [6] (Reference col 5)
	LPCSTR	szAct;	// [7] action command (Reference col 6)
	LPCSTR	szAct2;	// [8]
	LPCSTR	szAct3;	// [9]
	LPCSTR	szIconName;	// [10]
	LPCSTR	szToolTip;	// [11]
	INT	nCol12;	// [12]
	LPCSTR	szCol13;	// [13]
};

/////////////////////////////////////////////////////////////////////
// 聊天限制配置表
/////////////////////////////////////////////////////////////////////
#define DBC_TALK_CONFIG			( 919 )
struct _DBC_TALK_CONFIG
{
	INT		nID;			//ID 依据ENUM_CHAT_TYPE
	LPCSTR	szChannelName;	//频道名称
	LPCSTR	szChannelHeader;	//频道前导字符
	INT		nTimeSlice;		//时间间隔（单位：秒）
	INT		nNeedType1;		//消耗类型1 依据CHAT_NEED_TYPE
	INT		nNeedValue1;	//消耗数值1
	INT		nNeedType2;		//消耗类型2 依据CHAT_NEED_TYPE
	INT		nNeedValue2;	//消耗数值2
	INT		nNeedType3;		//消耗类型3 依据CHAT_NEED_TYPE
	INT		nNeedValue3;	//消耗数值3
	INT		nNeedLv;		//等级限制，这里标称的是最低多少级才能在此频道发言
};

/////////////////////////////////////////////////////////////////////
// 发型改变消耗表
/////////////////////////////////////////////////////////////////////
#define DBC_HAIR_STYLE			( 920 )
struct _DBC_HAIR_STYLE
{
	INT		nID;			//ID索引
	INT		nRaceID;		//性别区分
	INT		nItemTableID;	//消耗物品ID
	INT		nItemCount;		//消耗物品数量
};

/////////////////////////////////////////////////////////////////////
// 怪物头顶泡泡表
/////////////////////////////////////////////////////////////////////
#define DBC_MONSTER_PAOPAO		( 921 )
struct _DBC_MONSTER_PAOPAO
{
	INT		nID;			//ID索引
	LPCSTR	szPaoPaoTxt;	//怪物要说的头顶文字
};


#define DBC_CAMP_AND_STAND		(922)	//阵营









struct _DBC_CAMP_AND_STAND
{
	INT	nCampID;	// [0]
	LPCSTR	pszName;	// [1]
	INT	nEnabled;	// [2]
	INT	nRelation[64];	// [3..66] reputation score of this camp towards camp i
	LPCSTR	pszDesc;	// [67]
};


/////////////////////////////////////////////////////////////////////
//字体信息颜色表
/////////////////////////////////////////////////////////////////////
#define DBC_SYSTEM_COLOR		(923)
struct _DBC_SYSTEM_COLOR
{
	const static INT NAME_PLAYER_MYSELF		 = 1;	//名字_主角
	const static INT NAME_PLAYER_OTHER		 = 2;	//名字_其他玩家
	const static INT NAME_NPC_PEACE			 = 3;	//名字_和平NPC
	const static INT NAME_NPC_ATTACK_ACTIVE	 = 4;	//名字_主动攻击NPC
	const static INT NAME_NPC_ATTACK_PASS	 = 5;	//名字_不主动攻击NPC
	const static INT NAME_NPC_CANNT_ATTACK	 = 6;	//不可攻击的NPC
	const static INT NAME_PET				 = 7;	//宠物名字
	const static INT NANE_SELF_PET			 = 8;	//自己的宠物

	const static INT NANE_ISACK_NOTRETORT_PLAYER	 = 10;	//可以攻击_不还击的玩家
	const static INT NANE_ISACK_ISTRETORT_PLAYER	 = 11;	//可以攻击_会还击的玩家
	const static INT NANE_NOTACK_ISTRETORT_PLAYER	 = 12;	//不可攻击_会还击的玩家
	const static INT NANE_NOTACK_NOTRETORT_PLAYER	 = 13;	//不可攻击_不还击的玩家
	const static INT NANE_ISACK_NOTRETORT_MONSTER	 = 14;	//可攻击、不还击、不主动
	const static INT NANE_ISACK_ISRETORT_MONSTER	 = 15;	//可攻击、会还击、不主动
	const static INT NANE_ISACK_ISACK_MONSTER		 = 16;	//可攻击、会还击、会主动
	const static INT NANE_NOTACK_ISACK_MONSTER		 = 17;	//不可攻击、会还击、会主动
	const static INT NANE_NOTACK_NOTRETORT_MONSTER	 = 18;	//不可攻击、不会还击、不会主动

	const static INT TITLE_NORMAL			 = 100;	//称号_普通
	const static INT TITLE_BANGPAI			 = 101;	//称号_帮派职称
	const static INT TITLE_MOOD				 = 102;	//称号_玩家自定义心情
	const static INT TITLE_PLAYER_SHOP		 = 103;	//称号_玩家商店

	const static INT UI_DEBUGLISTBOX		 = 1000; //debuglistbox的颜色

	INT		m_nID;
	LPCSTR  strDesc;
	LPCSTR	strFontColor;
	LPCSTR	strExtenColor;
};

/////////////////////////////////////////////////////////////////////
// 完全匹配过滤表，用在创建帮会、起名字之类的地方，避免使用系统词组
/////////////////////////////////////////////////////////////////////
#define DBC_FULLCMP_FILTER		( 924 )
struct _DBC_FULLCMP_FILTER
{
	INT		nID;			//ID索引
	LPCSTR	szFilterType;	//用在什么地方，例如：all,guild,team,.....表示用在所有地方，仅帮会，仅组队等等。
	LPCSTR	szFullTxt;		//完全屏蔽词
};

/////////////////////////////////////////////////////////////////////
// 宠物升级需要的经验表
/////////////////////////////////////////////////////////////////////
#define DBC_PET_LEVELUP			( 925 )
struct _DBC_PET_LEVELUP
{
	INT		nID;			//ID索引
	INT		nExp;			//所需要经验
};










#define DBC_PET_ATTACK_TRAIT	( 926 )
struct _DBC_PET_ATTACK_TRAIT
{
	INT		nID;				// [0] 攻击特性ID, = MonsterAttrExTable 攻击特性ID
	LPCSTR	szName;				// [1] 名称 / 描述 (tooltip)
	LPCSTR	szIcon;				// [2] imageset entry, "" for the rows the pet window does not show
	INT		nAttPhysicsRate;	// [3] 外功系数
	INT		nAttMagicRate;		// [4] 内功系数
	INT		nRate1;				// [5]
	INT		nRate2;				// [6]
	INT		nRate3;				// [7]
	INT		nRate4;				// [8]
	INT		nRate5;				// [9]
};












#define DBC_PET_LINGXING		( 927 )
struct _DBC_PET_LINGXING
{
	INT		nID;					// [0] 行号
	INT		nPetType;				// [1] 宠物编号 (= SDATA_PET::m_nDataID)
	INT		nMainPerceptionMin;		// [2] inclusive
	INT		nMainPerceptionMax;		// [3] exclusive
	INT		nBonus[10];				// [4..13] 灵性 1..10 bonus, per mille
	INT		nUpPercent[10];			// [14..23] 灵性 1..10 upgrade chance, percent (PetLingXingUp)
};
