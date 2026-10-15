// ActionSetMgr.cpp
//
//////////////////////////////////////////////////////

#include "StdAfx.h"
#include "../DBC/GMDataBase.h"
#include "TLBB_DBC.h"
#include "ActionSetMgr.h"
#include "TDUtil.h"
#include "../Procedure/GameProcedure.h"	// CYS: s_pResourceProvider for the B tables
#include "TDResourceProvider.h"
#include "../WxRender/ResourceProvider.h"	// CYS: CResourceProvider::loadResource
#include "ObjectDef.h"					// CYS: ENUM_WEAPON_TYPE
#include <set>

// CYS: action-set files that failed to open, so each is tried and logged once. client_GL keeps its action sets in
// CYS: ActionSet/ActionSet.txt + ActionSetLine.txt + ActionSetKV.txt (B), not in 0.85 per-model files.
static std::set<STRING> s_cysMissingActionSets;

static BOOL CysOpenActionSetFile(const STRING& strPathName, DBC::DBCFile* pDBCFile)
{
	if(s_cysMissingActionSets.count(strPathName)) return FALSE;
	if(CDataBase::Util_OpenDBCFromTxt(strPathName.c_str(), pDBCFile)) return TRUE;
	s_cysMissingActionSets.insert(strPathName);
	TDU_Log("CYS action-set: %s not found (client_GL uses ActionSet/ActionSet*.txt; per-model files are 0.85 only)", strPathName.c_str());
	return FALSE;
}

#pragma warning(disable:4996)

CActionSetMgr *CActionSetMgr::s_pActionSetMgr	= NULL;
CActionSetMgr::CActionSetMgr( VOID )
{
	s_pActionSetMgr	= this;
}

CActionSetMgr::~CActionSetMgr( VOID )
{
	s_pActionSetMgr = NULL;
}

BOOL CActionSetMgr::Init( STRING strResPath )
{
	m_strResPath = strResPath;
	CysLoadTables();	// CYS: client_GL ActionSet/ActionSet*.txt; missing tables only log (0.85 per-model files stay)
	return TRUE;
}

// CYS: reads one General-group resource into memory (same path as CDataBase::Util_OpenDBCFromTxt). The B loader
// CYS: (FUN_1400e35b0) builds "<res path>ActionSet.txt" and opens it through the same "General" group; the OGRE index
// CYS: also resolves the bare base name of a file in a recursive location, so that is tried second.
static BOOL CysReadResource(const STRING& strPath, const STRING& strBaseName, CHAR*& pData, DWORD& dwSize, STRING& strUsed)
{
	pData = NULL;
	dwSize = 0;
	if(CGameProcedure::s_pResourceProvider == NULL) return FALSE;
	const STRING candidates[2] = { strPath + strBaseName, strBaseName };
	for(int i = 0; i < 2; ++i)
	{
		dwSize = CGameProcedure::s_pResourceProvider->loadResource(candidates[i].c_str(), pData, "General");
		if(dwSize > 0 && pData != NULL)
		{
			strUsed = candidates[i];
			return TRUE;
		}
		pData = NULL;
		dwSize = 0;
	}
	return FALSE;
}

BOOL CActionSetMgr::CysLoadTables( VOID )
{
	m_cysTable.Clear();
	static const CHAR* s_aszFiles[3] = { "ActionSet.txt", "ActionSetLine.txt", "ActionSetKV.txt" };
	int nLoaded = 0;
	for(int i = 0; i < 3; ++i)
	{
		CHAR* pData = NULL;
		DWORD dwSize = 0;
		STRING strUsed;
		if(!CysReadResource(m_strResPath, s_aszFiles[i], pData, dwSize, strUsed))
		{
			TDU_Log("CYS action-set: %s%s not found (no B action-set tables in this data set)", m_strResPath.c_str(), s_aszFiles[i]);
			continue;
		}
		bool bOK = false;
		switch(i)
		{
		case 0: bOK = m_cysTable.LoadActionSet(pData, dwSize); break;
		case 1: bOK = m_cysTable.LoadActionSetLine(pData, dwSize); break;
		case 2: bOK = m_cysTable.LoadActionSetKV(pData, dwSize); break;
		}
		CGameProcedure::s_pResourceProvider->unloadResource(pData, dwSize);
		if(bOK) ++nLoaded;
		else TDU_Log("CYS action-set: %s has no usable rows", strUsed.c_str());
	}
	m_cysTable.Finish();
	const CysActionSet::Stats& st = m_cysTable.GetStats();
	TDU_Log("CYS action-set: B tables %s: %d sets, %d actions, %d lines x %d slots, %d names (%d empty); "
		"row-id mismatch %d, short rows %d, extra cells %d, bad numbers %d, dangling lines %d, dangling names %d, duplicate actions %d",
		m_cysTable.IsReady() ? "loaded" : "NOT loaded", st.nSets, st.nActions, st.nLines, st.nSlots, st.nNames, st.nEmptyNames,
		st.nLineIdMismatch, st.nShortRows, st.nExtraCells, st.nBadNumbers, st.nDanglingLines, st.nDanglingNames, st.nDuplicateActions);
	for(size_t i = 0; i < st.messages.size(); ++i)
		TDU_Log("CYS action-set: note: %s", st.messages[i].c_str());
	return m_cysTable.IsReady();
}

LPCSTR CActionSetMgr::CysGetActionName( INT nSetID, INT nActionID, INT nSlot, BOOL *pbHideWeapon, INT *pnAppointedWeaponID ) const
{
	if(!m_cysTable.IsReady() || nSetID < 0 || nActionID < 0) return NULL;
	bool bHide = false;
	int nAppointed = INVALID_ID;
	LPCSTR pszName = m_cysTable.Resolve(nSetID, nActionID, nSlot, &bHide, &nAppointed);
	if(pszName == NULL) return NULL;
	if(pbHideWeapon) *pbHideWeapon = bHide ? TRUE : FALSE;
	if(pnAppointedWeaponID) *pnAppointedWeaponID = nAppointed;
	return pszName;
}

INT CActionSetMgr::CysSlotFromWeaponType( INT nWeaponType )
{
	switch(nWeaponType)
	{
	case WEAPON_TYPE_NONE:		return CysActionSet::SLOT_NONE;
	case WEAPON_TYPE_SPEAR:		return CysActionSet::SLOT_SPEAR;
	case WEAPON_TYPE_LONG:		return CysActionSet::SLOT_LONG;
	case WEAPON_TYPE_DSHORT:	return CysActionSet::SLOT_DSHORT;
	case WEAPON_TYPE_SHORT:		return CysActionSet::SLOT_SHORT;
	case WEAPON_TYPE_FAN:		return CysActionSet::SLOT_FAN;
	case WEAPON_TYPE_RING:		return CysActionSet::SLOT_RING;
	case WEAPON_TYPE_MONSTER:	return CysActionSet::SLOT_SHARED;	// CYS-CY: CY FUN_1405e3230: monsters -> 13
	case WEAPON_TYPE_NPC:		return CysActionSet::SLOT_SHARED;
	case WEAPON_TYPE_QIN:		return CysActionSet::SLOT_QIN;	// CYS-CY: CY FUN_1405c6df0 slots
	case WEAPON_TYPE_SICKLE:		return CysActionSet::SLOT_SICKLE;
	case WEAPON_TYPE_CY_DAOZU:	return CysActionSet::SLOT_CY_DAOZU;
	case WEAPON_TYPE_CY_STAFF:	return CysActionSet::SLOT_CY_STAFF;
	case WEAPON_TYPE_CY_TYPE10:	return CysActionSet::SLOT_CY_TYPE10;
	case WEAPON_TYPE_CY_CROSSBOW:	return CysActionSet::SLOT_CY_CROSSBOW;
	case WEAPON_TYPE_CY_SWORD:	return CysActionSet::SLOT_CY_SWORD;
	default:					return CysActionSet::SLOT_NONE;
	}
}

VOID CActionSetMgr::CleanUp( VOID )
{
	CActionSetMap::iterator itCur, itEnd;
	DBC::DBCFile *pDBFile;
	itEnd = m_mapActionSet.end();
	for ( itCur = m_mapActionSet.begin(); itCur != itEnd; itCur++ )
	{
		pDBFile = (itCur->second);
		delete pDBFile;
	}
	m_mapActionSet.erase( m_mapActionSet.begin(), m_mapActionSet.end() );
}

const _DBC_CHARACTER_ACTION_SET *CActionSetMgr::GetActionSet( std::string strFileName, UINT dwID )
{
	CActionSetMap::const_iterator itFind;
	itFind = m_mapActionSet.find( strFileName );
	if ( itFind == m_mapActionSet.end() )
	{
		DBC::DBCFile *pDBCFile = new DBC::DBCFile( -1 );
		STRING strPathName = m_strResPath + strFileName;
		const CHAR *pszPathName = strPathName.c_str();
		(void)pszPathName;
		BOOL bResult = CysOpenActionSetFile(strPathName, pDBCFile);	// CYS: try/log missing files once
		if ( bResult )
		{
			itFind = m_mapActionSet.insert( m_mapActionSet.end(), CActionSetMap::value_type( strFileName, pDBCFile ) );
		}
		else
		{
			delete pDBCFile;
			pDBCFile = NULL;
		}
	}

	if ( itFind == m_mapActionSet.end() )
		return NULL;

	const DBC::DBCFile *pDBCFile = itFind->second;
	const _DBC_CHARACTER_ACTION_SET *pActionSet = (const _DBC_CHARACTER_ACTION_SET*)(pDBCFile->Search_Index_EQU( dwID ));
	return pActionSet;
}

const DBC::DBCFile *CActionSetMgr::GetActionSetFile(std::string strFileName)
{
	CActionSetMap::const_iterator itFind;
	itFind = m_mapActionSet.find( strFileName );
	if ( itFind == m_mapActionSet.end() )
	{
		DBC::DBCFile *pDBCFile = new DBC::DBCFile( -1 );
		STRING strPathName = m_strResPath + strFileName;
		const CHAR *pszPathName = strPathName.c_str();
		(void)pszPathName;
		BOOL bResult = CysOpenActionSetFile(strPathName, pDBCFile);	// CYS: try/log missing files once
		if ( bResult )
		{
			itFind = m_mapActionSet.insert( m_mapActionSet.end(), CActionSetMap::value_type( strFileName, pDBCFile ) );
		}
		else
		{
			delete pDBCFile;
			pDBCFile = NULL;
		}
	}

	if ( itFind == m_mapActionSet.end() )
		return NULL;

	return itFind->second;
}