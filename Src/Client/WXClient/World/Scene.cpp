#include "StdAfx.h"
#include <Float.h>
#include "WorldManager.h"
#include "Scene.h"
#include "TDException.h"
#include "TDDBC_Struct.h"
#include "TDDebuger.h"
#include "TLBB_DBC.h"
#include "TDUtil.h"
#include "../WxRender/ResourceProvider.h"
#include "..\Global.h"
#include "..\Procedure\GameProcedure.h"
#include "..\Object\ObjectManager.h"
#include "..\Object\Object.h"
#include "..\Object\Character\Obj_PlayerMySelf.h"
#include "..\Object\Obj_Building.h"
#include "..\Sound\GMSoundSystem.h"
#include "..\dbc\GMDataBase.h"
#include "..\Variable\GMVariable.h"
#include "..\WxRender\RenderSystem.h"
#include "..\Procedure\CysLoginScene.h"	// CYS-CHARSEL
#include "CysNavMesh.h"	// CYS: navmesh *.path qua PathLib clean-room

CScene::CScene(const _DBC_SCENE_DEFINE* pDefScene, bool bUserCity)
{
	TDAssert(pDefScene);
	m_pTheDefine = pDefScene;
	m_pBackSound = NULL;
	m_nCysBackSoundID = -1;	// CYS-AUDIO
	m_nCysMusicRegion = -1;
	m_pEnvSoundList.resize(0);
	m_bUserCity = bUserCity;
	m_Weights = NULL;
	m_Dist = NULL;
	m_pNavMesh = NULL;	// CYS
}

CScene::~CScene()
{
	SAFE_DELETE_ARRAY( m_Weights );
	SAFE_DELETE_ARRAY( m_Dist );
	SAFE_DELETE( m_pNavMesh );	// CYS
}

VOID CScene::Initial(VOID)
{
	LoadFlightGrid();
	//------------
	//创建网格数据
	//------------
	const _DBC_SCENE_DEFINE* pSceneDefine = GetSceneDefine();

	//预先分配好内存
	m_nZoneXSize = pSceneDefine->nXSize / SIZE_OF_ZONE;
	if(m_nZoneXSize*SIZE_OF_ZONE < pSceneDefine->nXSize) m_nZoneXSize++;

	m_nZoneZSize = pSceneDefine->nZSize / SIZE_OF_ZONE;
	if(m_nZoneZSize*SIZE_OF_ZONE < pSceneDefine->nZSize) m_nZoneZSize++;

	m_theZoneBuf.resize(m_nZoneXSize * m_nZoneZSize);

	//设置网格数据
	for(INT i=0; i<(INT)m_theZoneBuf.size(); i++)
	{
		CZone& theZone = m_theZoneBuf[i];

		//网格初始化
		theZone.Initial();
	}

	//m_nPathXSize = (INT)((float)pSceneDefine->nXSize / SIZE_OF_PATH);
	//m_nPathZSize = (INT)((float)pSceneDefine->nZSize / SIZE_OF_PATH);
	//m_thePathBuf.

	//加载Region和行走面
	LoadRegionBinary(m_pTheDefine->szRegionFile);
	m_WalkCollisionMng.ClearData();
	m_WalkCollisionMng.LoadCollisionTriInfoFromFile(m_pTheDefine->szCollisionfile);

	//加载环境音效
	LoadEnvSound();

	//加载玩家建筑物数据
	if(m_bUserCity)
	{
		//查找本场景中所有可能会出现的玩家建筑物
		DBC_DEFINEHANDLE(s_pCityBuilding, DBC_CITY_BUILDING);

		unsigned int nLineNum = s_pCityBuilding->GetRecordsNum();
		for(unsigned int i=0; i<nLineNum; i++)
		{
			const _DBC_CITY_BUILDING* pDefine = (const _DBC_CITY_BUILDING*)s_pCityBuilding->Search_LineNum_EQU((int)i);
			//是否是属于该城市的建筑物
			if(pDefine->nCityID != m_pTheDefine->nServerID) continue;

			//加入
			BUILDING newBuilding;
			newBuilding.pDefine = pDefine;
			newBuilding.nLevel = -1;
			newBuilding.nObjID = -1;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
			m_allBuilding.insert(std::make_pair(pDefine->nID, newBuilding));
		}
	}
}

bool CScene::UpdateUserCity(int nNewLevel) //const _DBC_SCENE_DEFINE* pDefScene)
{
	//不是玩家城市
	if(!m_bUserCity) return false;

	//查找城市场景
	DBC_DEFINEHANDLE(s_pSceneDBC, DBC_SCENE_DEFINE);
	const _DBC_SCENE_DEFINE* pSceneDef = 0;
	for(int i=0; i<(int)s_pSceneDBC->GetRecordsNum(); i++)
	{
		const _DBC_SCENE_DEFINE* pTempSceneDef = (const _DBC_SCENE_DEFINE*)s_pSceneDBC->Search_LineNum_EQU(i);

		//Id和等级相同
		if(pTempSceneDef->nServerID==m_pTheDefine->nServerID)	// CYS: client_GL SceneDefineEx has no city-level column
		{
			pSceneDef = pTempSceneDef;
			break;
		}
	}
	if(!pSceneDef) return false;

	//同一个场景
	if(m_pTheDefine->nServerID == pSceneDef->nServerID) return false;	// CYS: client_GL column 0

	//大小必须相同
	if(	pSceneDef->nXSize != m_pTheDefine->nXSize ||
		pSceneDef->nZSize != m_pTheDefine->nZSize) return false;

	//设置网格数据
	for(INT i=0; i<(INT)m_theZoneBuf.size(); i++)
	{
		CZone& theZone = m_theZoneBuf[i];
		//网格初始化
		theZone.Initial();
	}

	//是否是同一个阻挡区
	if(_stricmp(m_pTheDefine->szRegionFile, pSceneDef->szRegionFile))
	{
		LoadRegionBinary(m_pTheDefine->szRegionFile);
	}

	//是否是同一个行走面
	if(_stricmp(m_pTheDefine->szCollisionfile, pSceneDef->szCollisionfile))
	{
		m_WalkCollisionMng.ClearData();
		m_WalkCollisionMng.LoadCollisionTriInfoFromFile(m_pTheDefine->szCollisionfile);
	}

	//是否是同一个背景音乐
	if(m_pTheDefine->nBackSound != pSceneDef->nBackSound)
	{
		//销毁背景音乐资源
		ControlBkgSound(FALSE);
	}

	//加载场景资源
	m_pTheDefine = pSceneDef;
	EnterScene();

	//环境音效
	LoadEnvSound();

	return true;
}

bool CScene::UpdateCityBuilding(int nBuildingID, int nBuildingLevel)
{
	//不是玩家城市
	if(!m_bUserCity) return false;

	//该建筑物是否存在
	BUILDING_REGISTER::iterator itFind = m_allBuilding.find(nBuildingID);
	if(itFind == m_allBuilding.end()) return false;

	BUILDING& theBuilding = itFind->second;

	//等级相同
	if(theBuilding.nLevel == nBuildingLevel) return true;

	//如果尚未创建
	CObject_Building* pBuilding = (CObject_Building*)CObjectManager::GetMe()->FindObject(theBuilding.nObjID);
	if(!pBuilding)
	{
		pBuilding = (CObject_Building*)CObjectManager::GetMe()->NewObject("CObject_Building");
		if(!pBuilding) return false;
		
		//设置资源
		pBuilding->SetLogicData_Define(theBuilding.pDefine);

		//保存
		theBuilding.nObjID = pBuilding->GetID();
	}

	//设置等级
	pBuilding->SetLogicData_Level(nBuildingLevel);

	return true;
}

VOID CScene::EnterScene(VOID)
{
	//----------------
	//在渲染层创建地形
	//----------------

	//加载场景文件
	CGameProcedure::s_pGfxSystem->Scene_Load(m_pTheDefine->nServerID, m_pTheDefine->szWXObjectName);	// CYS: client_GL column 0
	CysLoginScene::NoteSceneLoaded(m_pTheDefine->szWXObjectName);	// CYS-CHARSEL: a later login/selection screen reloads its scene
	// CYS camera3d: CY 3.71 CScene::EnterScene dat far/near cua camera canh tu SceneDefineEx cot 15/16 ngay sau khi nap canh
	CGameProcedure::s_pGfxSystem->Camera_SetClip((FLOAT)m_pTheDefine->nCameraFarClip, (FLOAT)m_pTheDefine->nCameraNearClip);

	//预加载所有Npc资源
	char szPreLoadFile[MAX_PATH];
	strncpy(szPreLoadFile, m_pTheDefine->szWXObjectName, MAX_PATH);
	char* pSzExt = ::PathFindExtension(szPreLoadFile);
	if(pSzExt)
	{
		*pSzExt = 0;
		//***_monster.preload
		strncat(szPreLoadFile, "_monster.preload", MAX_PATH);

		CGameProcedure::s_pGfxSystem->Scene_PreLoad(szPreLoadFile);
	}

	//----------------
	//播放背景音乐  , 使用系统保存的变量来控制是否播放
	//----------------	
	STRING strVar;
	CVariableSystem::GetMe()->GetVariable(CSoundSystemFMod::szBKSoundVar, strVar);
	if(strVar == "1")
	{
		ControlBkgSound(TRUE);
	}
}

VOID CScene::LeaveScene(VOID)
{
	//销毁背景音乐资源
	ControlBkgSound(FALSE);
	//销毁环境音效
	DestroyEnvSound();

	//-------------------
	// 销毁网格上的物体
	for(INT i=0; i<(INT)m_theZoneBuf.size(); i++)
	{
		CZone& theZone = m_theZoneBuf[i];

		register std::set< INT >::iterator it = theZone.m_setRegisterObject.begin();
		while(it != theZone.m_setRegisterObject.end())
		{
			//销毁物体
			CObject* pObj = (CObject*)CObjectManager::GetMe()->FindObject(*it);
			if(pObj && !(pObj->GetFakeObjectFlag()))
			{
				pObj->Release();
				CObjectManager::GetMe()->DestroyObject( pObj );
			}
			it++;
		}
	}
	m_theZoneBuf.clear();
}

//场景位置是否合法
BOOL CScene::IsValidPosition(const fVector2& fvPos)
{
	if(fvPos.x < 0.0f || fvPos.x > (FLOAT)(m_pTheDefine->nXSize)) return FALSE;
	if(fvPos.y < 0.0f || fvPos.y > (FLOAT)(m_pTheDefine->nZSize)) return FALSE;
	return true;
}

// CYS-AUDIO: CScene::DestroyEnvSound/Tick/ControlBkgSound/ControlBkgSoundVol/ControlEnvSound/ControlEnvSoundVol/LoadEnvSound
// CYS-AUDIO: moved to CysSceneAudio.cpp (CY 3.71 ESD environment sounds and music regions).

VOID CScene::LoadRegionBinary(LPCTSTR szRegionFile)
{
	if(!szRegionFile || szRegionFile[0] == '\0') return;
	// CYS: client_GL SceneDefineEx column 5 names the PathLib navmesh (*.path), never a 0.85 *.region file.
	// *.path -> LoadNavMesh (PathLib clean-room); *.region -> the 0.85 polygon loader below is kept as a fallback.
	{
		const char* pExt = strrchr(szRegionFile, '.');
		if(pExt != NULL && _stricmp(pExt, ".path") == 0)
		{
			LoadNavMesh(szRegionFile);
			return;
		}
		if(pExt == NULL || _stricmp(pExt, ".region") != 0)
		{
			TDU_Log("CYS scene: %s is neither *.path nor *.region; no navigation data loaded", szRegionFile);
			return;
		}
		TDU_Log("CYS scene: %s is a 0.85 *.region file; using the legacy polygon loader (fallback)", szRegionFile);
	}
	SAFE_DELETE( m_pNavMesh );	// CYS: a *.region scene has no navmesh
	m_theRegion.clear();

	char* lpAddress = NULL;
	DWORD dwSize = CGameProcedure::s_pResourceProvider->loadResource(szRegionFile, lpAddress, "General");
	if(dwSize > 0)
	{
		INT			iRegionCount = 0;
		INT			iPointCount  = 0;
		INT         iId			 = 0;
		INT			FlyLevel	 = 0;
		bool        NewVer       = false;
		FLOAT       fTemp = 0;
		fVector2	fvp;
		char*		pPoint = lpAddress;
		//判断版本
		int			iVerLen = (int)sizeof("REGION_EDIT_01");
		char*		pVer = new char[iVerLen];
		memcpy(pVer, pPoint, iVerLen-1);
		pVer[iVerLen-1] = 0;

		if( strcmp( pVer, "REGION_EDIT_01" ) == 0 )
		{
			pPoint += (iVerLen-1);
			NewVer = true;
		}

		delete [] pVer;

		// 读取区域的个数
		memcpy(&iRegionCount, pPoint, sizeof(iRegionCount));
		pPoint += sizeof(iRegionCount);

		m_theRegion.reserve( iRegionCount );
		for(INT i = 0; i < iRegionCount; i++)
		{
			//读取区域的id
			//memcpy(&(iId), pPoint, sizeof(iId));
			pPoint += sizeof(INT); //skip regionid
			CRegion cr;					
			cr.m_RegionID = i;

			if (NewVer)
			{
				memcpy(&FlyLevel, pPoint, sizeof(FlyLevel));
				pPoint += sizeof(FlyLevel);
				cr.m_nPassRegionLevel = FlyLevel;
			}
			
			// 读取点的个数.
			memcpy(&iPointCount, pPoint, sizeof(iPointCount));
			pPoint += sizeof(iPointCount);

			for(INT k = 0; k < iPointCount; k++)
			{
				// 读取x， z 数据
				memcpy(&fvp.x, pPoint, sizeof(fvp.x)); pPoint += sizeof(fvp.x);
				memcpy(&fvp.y, pPoint, sizeof(fvp.y)); pPoint += sizeof(fvp.y);
				memcpy(&fTemp, pPoint, sizeof(fTemp)); pPoint += sizeof(fTemp);

				cr.AddPoint(&fvp);
			}
			m_theRegion.push_back(cr);
		}
		CGameProcedure::s_pResourceProvider->unloadResource( lpAddress, dwSize );
	}

	//将Region注册到Zone
	RegisteAllRegion();

	LoadDijk();
}

// CYS: navmesh *.path (client_GL) qua PathLib clean-room. Không ném ngoại lệ: thiếu/hỏng thì log rồi chạy tiếp,
// khi đó CPath rơi về kiểm biên cảnh (IsValidPosition) như cảnh không có dữ liệu chặn.
VOID CScene::LoadFlightGrid()
{
    std::string path=m_pTheDefine->szWXObjectName;
    const size_t dot=path.find_last_of('.');
    if(dot==std::string::npos) return;
    path.resize(dot); path+=".fly";
    char* bytes=NULL; DWORD size=0;
    try { size=CGameProcedure::s_pResourceProvider->loadResource(path.c_str(),bytes,"Scene"); }
    catch(...) { bytes=NULL;size=0; }
    bool ok=m_cysFlightGrid.Load(bytes,size,m_pTheDefine->nXSize,m_pTheDefine->nZSize);
    if(bytes) CGameProcedure::s_pResourceProvider->unloadResource(bytes,size);
    TDU_Log("CYS-MOUNT-FLIGHT: grid scene=%d file=%s bytes=%u valid=%d",m_pTheDefine->nServerID,path.c_str(),size,ok?1:0);
}

VOID CScene::LoadNavMesh(LPCTSTR szPathFile)
{
	SAFE_DELETE( m_pNavMesh );
	m_theRegion.clear();
	if(!szPathFile || szPathFile[0] == '\0') return;

	char* lpAddress = NULL;
	DWORD dwSize = 0;
	// CYS: client_GL FairyResources.cfg (and stage_game.py) put SceneFolder in the "Scene" group; the 0.85 layout
	// CYS: kept scene files in "General". Try both (world3b replay 14/09: dali.path was only in "Scene").
	static const char* const cysGroups[] = { "General", "Scene" };
	for(int cysGroup = 0; cysGroup < 2 && (dwSize == 0 || lpAddress == NULL); ++cysGroup)
	{
		try
		{
			dwSize = CGameProcedure::s_pResourceProvider->loadResource(szPathFile, lpAddress, cysGroups[cysGroup]);
		}
		catch(...)
		{
			dwSize = 0;
			lpAddress = NULL;
		}
	}
	if(dwSize == 0 || lpAddress == NULL)
	{
		TDU_Log("CYS: navmesh %s missing (resource groups General, Scene); click-to-move limited to scene bounds", szPathFile);
		return;
	}

	cys::NavMesh* pMesh = new cys::NavMesh();
	const bool bLoaded = pMesh->LoadFromMemory(lpAddress, (size_t)dwSize, szPathFile);
	CGameProcedure::s_pResourceProvider->unloadResource( lpAddress, dwSize );
	if(!bLoaded)
	{
		TDU_Log("CYS: navmesh %s corrupt (%u bytes); click-to-move limited to scene bounds", szPathFile, (unsigned)dwSize);
		delete pMesh;
		return;
	}
	m_pNavMesh = pMesh;
	const cys::NavStats& st = pMesh->Stats();
	TDU_Log("CYS: navmesh %s %s", szPathFile, pMesh->Summary().c_str());
	if(st.invariantBlockedExtra || st.invariantWalkableZero)
	{
		TDU_Log("CYS: navmesh %s invariant warning: blocked_with_region=%u walkable_without_region=%u (original PathLib.dll would misbehave; clean-room tolerates it)",
			szPathFile, (unsigned)st.invariantBlockedExtra, (unsigned)st.invariantWalkableZero);
	}
	// Kiểm hệ số toạ độ: navmesh phải phủ đúng kích thước cảnh (1 đơn vị .path = 1 đơn vị thế giới).
	if(m_pTheDefine && (st.maxX > (FLOAT)m_pTheDefine->nXSize + 1.0f || st.maxZ > (FLOAT)m_pTheDefine->nZSize + 1.0f))
	{
		TDU_Log("CYS: navmesh %s bounds exceed SceneDefineEx size %dx%d (units mismatch?)", szPathFile, m_pTheDefine->nXSize, m_pTheDefine->nZSize);
	}
}

VOID CScene::RegisteAllRegion(VOID)
{	
	fVector2 sp,ep;
	INT sGridX=0,sGridZ=0,eGridX=0,eGridZ=0;	
	FLOAT div=0,dividend=0;
	INT tempint0;
	FLOAT fb,fk;
	//所有多边形	
	std::vector<CRegion>::iterator itCRegion;
	for(itCRegion = m_theRegion.begin();itCRegion!=m_theRegion.end();itCRegion++)
	{	
		CRegion pCRegion = *itCRegion;
		//所有边
		for(INT i =0;i<(INT)(pCRegion.m_vfPoints.size());i++)
		{
			//起点和终点
			sp = pCRegion.m_vfPoints[i];			
			ep = pCRegion.m_vfPoints[(i+1)%(INT)(pCRegion.m_vfPoints.size())];
			sGridX=GetZoneX(sp.x);
			eGridX=GetZoneX(ep.x);
			sGridZ=GetZoneZ(sp.y);
			eGridZ=GetZoneZ(ep.y);
			if(sGridZ==eGridZ)
			{
				//Zone水平的情况,在同一Zone内必然是同一水平ZONE
				for(tempint0 = min(sGridX,eGridX);tempint0<=max(sGridX,eGridX);tempint0++)
				{						
					CZone * pcz;
					pcz = GetZone(tempint0,sGridZ);
					if(pcz!=NULL)
					{
						pcz->AddRegion(pCRegion.m_RegionID);						
					}						
				}				
			}
			else if(sGridX==eGridX)
			{
				//Zone垂直的情况			
				for(tempint0 = min(sGridZ,eGridZ);tempint0<=max(sGridZ,eGridZ);tempint0++)
				{
					CZone * pcz;
					pcz = GetZone(sGridX,tempint0);
					if(pcz!=NULL)
					{
						pcz->AddRegion(pCRegion.m_RegionID);
					}						
				}
			}
			else
			{		
				//斜边的情况,用区域内的网格切割多边形边
				//计算斜率和位移					
				fk = (sp.y-ep.y)/(sp.x-ep.x);
				fb = ep.y - ep.x*fk;					
				for (tempint0=min(sGridZ,eGridZ)+1;tempint0<=max(sGridZ,eGridZ);tempint0++)
				{	
					//计算多边形边同垂直切线的交点,将切点上下的两个zone注册
					FLOAT cross= (tempint0*SIZE_OF_ZONE-fb)/fk;					

					CZone * pcz;
					pcz = GetZone(GetZoneX(cross),tempint0);
					if(pcz!=NULL)
					{
						pcz->AddRegion(pCRegion.m_RegionID);
					}
					pcz = GetZone(GetZoneX(cross),tempint0-1);
					if(pcz!=NULL)
					{
						pcz->AddRegion(pCRegion.m_RegionID);
					}

				}					
				for (tempint0=min(sGridX,eGridX)+1;tempint0<=max(sGridX,eGridX);tempint0++)
				{	
					//计算多边形边同垂直切线的交点,将切点左右两个zone注册
					FLOAT cross = ((tempint0)*SIZE_OF_ZONE)*fk+fb;					
					CZone * pcz;
					pcz = GetZone(tempint0,GetZoneZ(cross));
					if(pcz!=NULL)
					{
						pcz->AddRegion(pCRegion.m_RegionID);

					}
					pcz = GetZone(tempint0-1,GetZoneZ(cross));
					if(pcz!=NULL)
					{
						pcz->AddRegion(pCRegion.m_RegionID);
					}						
				}
			}				
		}
	}	
}

CZone* CScene::GetZone(INT nXPos, INT nZPos)
{
	//物体位置非法
	if(	nXPos<0 || nXPos >= m_nZoneXSize ||
		nZPos<0 || nZPos >= m_nZoneZSize )
	{
		//Warning.... 该物体定义的位置不在地图之内
		return NULL;
	}

	return &(m_theZoneBuf[ nZPos*m_nZoneXSize + nXPos ]);
}


BOOL CScene::GetMapHeight(const fVector2& fvMapPos, FLOAT& fHeight)
{
	//检测坐标是否非法
	if(fvMapPos.x < 0 || fvMapPos.x > GetSceneDefine()->nXSize) return FALSE;
	if(fvMapPos.y < 0 || fvMapPos.y > GetSceneDefine()->nZSize) return FALSE;

	fVector3 fvTerrain;
	if(!CGameProcedure::s_pGfxSystem->Axis_Trans(CRenderSystem::AX_PLAN, 
			fVector3(fvMapPos.x, 0.0f, fvMapPos.y), CRenderSystem::AX_GAME, fvTerrain)) return FALSE;

	FLOAT fBuildHeight;
	BOOL bOnBuild = m_WalkCollisionMng.GetHeight(fvMapPos.x, fvMapPos.y, fBuildHeight);
	if(bOnBuild && fBuildHeight>=fvTerrain.y)
	{
		fHeight = fBuildHeight;
	}
	else
	{
		fHeight = fvTerrain.y;
	}
	return TRUE;
}

VOID CScene::LoadDijk()
{
	//return;

	//计算名字
	STRING	strFileName = m_pTheDefine->szRegionFile;
	STRING::size_type nValidEnd = strFileName.find(".region", 0);
	if(nValidEnd == STRING::npos) 
	{
		return ;
	}
	STRING::size_type nFinalEnd	= strFileName.size();
	strFileName.replace(nValidEnd, nFinalEnd, ".Dijkstra");
	STRING	leftFileName ="..\\..\\Public\\Scene\\";
	strFileName = leftFileName + strFileName;
	FILE* pFile = fopen( strFileName.c_str(), "rb" );

	if(NULL == pFile)
	{
		// 不能打开文件.
		return;
	}
	//的版本信息
	int			iVerLen = (int)sizeof("DIJKSTRA_EDIT_01");
	char*		pVer = new char[iVerLen];
	::fread( pVer, 1, iVerLen, pFile );
	delete [] pVer;
	INT dwPoint =0;
	fVector3   position;
	::fread(&dwPoint, sizeof(dwPoint), 1, pFile);
	fVector2 v;
	//1. 读出所有的点
	m_Points.clear();
	for( INT dw = 0; dw < dwPoint; dw ++ )
	{
		::fread(&position.x, sizeof(position.x), 1, pFile);
		::fread(&position.z, sizeof(position.z), 1, pFile);
		::fread(&position.y, sizeof(position.y), 1, pFile);
		v.x = position.x;
		v.y = position.z;
		m_Points.push_back( v );
	}
	if( m_Points.size() == 0 ) return;

	//2. 建立表
	SAFE_DELETE_ARRAY( m_Weights );
	m_Weights = new FLOAT[(m_Points.size()+2)*(m_Points.size()+2)];
	//memset( m_Weights, 0, (m_Points.size()+2)*(m_Points.size()+2)*sizeof(FLOAT) );
	float* JuLi = new float[dwPoint*dwPoint];
	::fread(JuLi, sizeof(float),dwPoint*dwPoint, pFile);
	//3. 计算路径权重
	size_t s = 0;
	for( s = 0; s < m_Points.size()-1; s ++ )
	{
		for( size_t t = s+1; t < m_Points.size(); t ++ )
		{
			//填入表中
			m_Weights[(s+1) + (t+1)*(m_Points.size()+2)] = JuLi[s + t * dwPoint];
			m_Weights[(t+1) + (s+1)*(m_Points.size()+2)] = JuLi[s + t * dwPoint];
		}
		m_Weights[(s+1) + (s+1)*(m_Points.size()+2)] = 0.0f; //自己到自己权重是 0
	}
	delete [] JuLi;
	for (int i=0;i<dwPoint+2;++i)
	{
		for (int j=0;j<dwPoint+2;++j)
		{
			if (i == 0 || i == dwPoint+1 || j == 0 || j == dwPoint+1)
			{
				m_Weights[j + i*(dwPoint+2)] = FLT_MAX;
			}
		}
	}
	m_Weights[(s+1) + (s+1)*(m_Points.size()+2)] = 0.0f;
	m_Weights[(s+2) + (s+2)*(m_Points.size()+2)] = 0.0f; //自己到自己权重是 0
	m_Weights[0] = 0.0f;

	//4. 初始化最短路径
	SAFE_DELETE_ARRAY( m_Dist );
	m_Dist = new FLOAT[m_Points.size()+2]; //最短路径保存处
}







