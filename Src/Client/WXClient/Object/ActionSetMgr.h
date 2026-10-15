// ActionSetMgr.h
//
//////////////////////////////////////////////////////

#pragma once

#include <string>
#include <hash_map>
#include "../Action/CysActionSetTable.h"	// CYS: client_GL ActionSet/ActionSet*.txt tables

struct _DBC_CHARACTER_ACTION_SET;
namespace DBC
{
	class DBCFile;
}

class CActionSetMgr
{
protected:
	static CActionSetMgr		*s_pActionSetMgr;
public:
	static CActionSetMgr *GetActionSetMgr( VOID ){
		return s_pActionSetMgr;
	}
public:
	CActionSetMgr( VOID );
	virtual ~CActionSetMgr( VOID );

	BOOL Init( STRING strResPath );
	VOID CleanUp( VOID );

	const _DBC_CHARACTER_ACTION_SET *GetActionSet( std::string strFileName, UINT dwID );
	const DBC::DBCFile *GetActionSetFile(std::string strFileName);

	// CYS: B (client_GL) path. Init() loads ActionSet.txt + ActionSetLine.txt + ActionSetKV.txt from m_strResPath
	// CYS: (the per-model files above stay as the 0.85 fallback). nSetID = ActionSetFile.txt id (CharModelEx column 9,
	// CYS: CharMount columns 5/6/7); nActionID = ENUM_BASE_ACTION or a skill/chat-mood action; nSlot = CysActionSet::Slot.
	// CYS: Returns NULL when the tables are absent or the (set, action, slot) has no entry -> the caller keeps its
	// CYS: current animation, like B's FUN_1400f7860. An empty name is a valid result (B: the model stops animating).
	BOOL CysHasTables( VOID ) const { return m_cysTable.IsReady(); }
	BOOL CysHasSet( INT nSetID ) const { return m_cysTable.IsReady() && m_cysTable.HasSet(nSetID); }
	LPCSTR CysGetActionName( INT nSetID, INT nActionID, INT nSlot, BOOL *pbHideWeapon, INT *pnAppointedWeaponID ) const;
	const CysActionSet::Table& CysGetTable( VOID ) const { return m_cysTable; }
	// CYS: 0.85 ENUM_WEAPON_TYPE -> B slot (WEAPON_TYPE_MONSTER / NPC -> 9, invalid -> 0).
	static INT CysSlotFromWeaponType( INT nWeaponType );

protected:
#ifdef __SGI_STL_PORT
	typedef std::hash_map< std::string, DBC::DBCFile* > CActionSetMap;
#else
	typedef stdext::hash_map< std::string, DBC::DBCFile* > CActionSetMap;
#endif
	CActionSetMap			m_mapActionSet;

	STRING					m_strResPath;

	CysActionSet::Table		m_cysTable;		// CYS: B tables (empty when the data set has none)
	BOOL					CysLoadTables( VOID );
};

inline CActionSetMgr *GetActionSetMgr( VOID ){
	return CActionSetMgr::GetActionSetMgr();
}
