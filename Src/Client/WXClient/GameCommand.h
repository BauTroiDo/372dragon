// GameCommand.h
//
//////////////////////////////////////////////////////

#pragma once

#include "Type.h"

#define MAX_OBJ_CMD_PARAM_NUM	(16)

enum ENUM_GAME_COMMAD_TYPE
{
	GAME_COMMAD_TYPE_INVALID	= -1,
	GAME_COMMAD_TYPE_WORLD,
	GAME_COMMAD_TYPE_OBJECT,
	GAME_COMMAD_TYPE_AI,
	GAME_COMMAD_TYPE_DPC,			// Data pool
	GAME_COMMAD_TYPE_UI,
	GAME_COMMAD_TYPE_MOUSE,
};

// Run Command 的返回值
enum RC_RESULT
{
	RC_OK = 0,
	RC_ERROR,
	RC_SKIP,
	RC_WAIT, // 等待
};

// CYS: x64. The parameters used to be a union of 4-byte arrays (UINT/INT/FLOAT/BOOL) and pointer arrays. On x64
// CYS: m_apParam[k] covered the bytes of m_adwParam[2k] and [2k+1], so a command with a pointer at index k and a
// CYS: number at index 2k or 2k+1 lost one of them (MCT_USE_ITEM, MCT_SKILL_OBJ/AREA/DIR, DPC_UPDATE_MISSION_MODIFY;
// CYS: see Tests/abi/audit_command_params.py). Every view now indexes the same 8-byte slots, so index i names slot i
// CYS: through every view - the meaning the code has on x86. SCommand never leaves Game.exe (UI_CEGUI.dll only
// CYS: forward-declares SCommand_DPC), so its size is free to change.
union SCommandParamSlot
{
	UINT				u;
	INT					n;
	FLOAT				f;
	BOOL				b;
	VOID*				p;
	const VOID*			cp;
	unsigned __int64	uq;
	__int64				q;
};

template< typename T >
struct SCommandParamView
{
	SCommandParamSlot	m_aSlot[MAX_OBJ_CMD_PARAM_NUM];

	T&			operator[](INT i)		{ return *reinterpret_cast<T*>(&m_aSlot[i]); }
	const T&	operator[](INT i) const	{ return *reinterpret_cast<const T*>(&m_aSlot[i]); }
};

//游戏中逻辑指令基类
struct SCommand
{
public:
	//命令类型
	WORD		m_wID;		// 如：WC_NONE, OC_NONE, UIC_NONE
	//命令参数集合
	union{	// CYS: arrays -> views over one set of 8-byte slots (see SCommandParamSlot)
		SCommandParamView< UINT >				m_adwParam;
		SCommandParamView< UINT >				m_auParam;
		SCommandParamView< FLOAT >				m_afParam;
		SCommandParamView< INT >				m_anParam;
		SCommandParamView< BOOL >				m_abParam;
		SCommandParamView< unsigned __int64 >	m_auqParam;		// CYS: was [MAX/2]; unused
		SCommandParamView< __int64 >			m_aqParam;		// CYS: was [MAX/2]; unused
		SCommandParamView< VOID* >				m_apParam;
		SCommandParamView< const VOID* >		m_apConstParam;
	};

//------------------------------------------------
protected:
	ENUM_GAME_COMMAD_TYPE	m_eType;

public:
	SCommand( VOID ){
		m_eType = GAME_COMMAD_TYPE_INVALID;
	}

	ENUM_GAME_COMMAD_TYPE GetType( VOID )const{
		return m_eType;
	}

	VOID Cleanup( VOID ){
		m_wID	= 0xFFFF;
		memset( &m_adwParam, 0, sizeof ( m_adwParam ) );	// CYS: m_adwParam is a view object now (all 16 slots)
	}
};

//应用于object的命令
struct SCommand_Object :
	public SCommand
{
	SCommand_Object( VOID ){
		m_eType = GAME_COMMAD_TYPE_OBJECT;
	}
};

//应用于AI的命令
struct SCommand_AI :
	public SCommand
{
	SCommand_AI( VOID ){
		m_eType = GAME_COMMAD_TYPE_AI;
	}
};

//应用于UI的命令
struct SCommand_DPC :
	public SCommand
{
	SCommand_DPC( VOID ){
		m_eType = GAME_COMMAD_TYPE_DPC;
	}
};

//挂在鼠标上的命令
struct SCommand_Mouse :
	public SCommand
{
	enum MOUSE_CMD_TYPE
	{
		MCT_NULL,		

		MCT_PLAYER_MOVETO,	//移动到目标点
							//m_afParam[0][1] = The position of target area

		MCT_PLAYER_SELECT,	//选中物体
							//m_adwParam[0] = The ID of target object

		MCT_SKILL_OBJ,		//点选目标的技能
							//m_adwParam[0] = The ID of skill
							//m_adwParam[1] = The ID of target object
		MCT_SKILL_AREA,		//范围技能
							//m_adwParam[0] = The ID of skill
							//m_afParam[1][2] = The position of target area
		MCT_CANCEL_SKILL,	//取消当前Action技能，设置为缺省技能
		MCT_SKILL_DIR,		//方向技能
							//m_adwParam[0] = The ID of skill
							//m_afParam[1] = The direction

		MCT_HIT_TRIPPEROBJ,	//放在能够操作的TripperObj上(矿物，箱子...)
							//m_adwParam[0] = The ID of Tripper obj
							//...

		MCT_SPEAK,			//和NPC谈话
							//m_adwParam[0] = The ID of NPC

		MCT_CONTEXMENU,		//显示右键菜单
							//m_adwParam[0] = The ID of NPC

		MCT_REPAIR,			//修理指针
		MCT_CANCLE_REPAIR,	//修理指针

		MCT_USE_ITEM,		//物品使用
							//m_apParam[0] = Action Item
							//m_adwParam[1] = The ID of target object
							//m_afParam[2] = Pos X
							//m_afParam[3] = Pos Z
							//m_adwParam[4] = Is area

		MCT_CANCEL_USE_ITEM,//取消物品使用

		//
		// 鼠标在界面上的命令状态 2006－3－29
		//
		MCT_UI_USE_IDENTIFY,			// 使用鉴定卷轴 	
		MCT_UI_USE_CANCEL_IDENTIFY,		// 取消使用鉴定卷轴 		

		MCT_UI_USE_ADDFRIEND,			//添加好友
		MCT_UI_USE_CANCEL_ADDFRIEND,	//取消添加好友

		MCT_UI_USE_EXCHANGE,			//添加好友
		MCT_UI_USE_CANCEL_EXCHANGE,	//取消添加好友

		MCT_LEAP,						//轻功

		MCT_CATCH_PET,				// 捉宠

		MCT_SALE,					// 卖东西
		MCT_CANCEL_SALE,			// 取消买东西

		MCT_BUYMULT,				// 买东西
		MCT_CANCEL_BUYMULT,			// 取消买东西
	};


	SCommand_Mouse( VOID ){
		m_eType = GAME_COMMAD_TYPE_MOUSE;
	}

	//鼠标命令类型
	MOUSE_CMD_TYPE	m_typeMouse;
};


