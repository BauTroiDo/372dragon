/****************************************\
*										*
*				游戏世界				*
*										*
\****************************************/
#pragma once
#include "TDWorldSystem.h"
#include "Scene.h"
#include "TDEventSystem.h"
class CObject_PlayerOther;

class CActivePosManager
{
public:
	CActivePosManager();
	virtual ~CActivePosManager();

	static CActivePosManager* GetMe(VOID) { return s_pMe; }

	void   Initial();
	void   Release();

	void   AddActivePos( bool bOnNPC, const char* pPosName, float fX, float fY, int nSceneID );
	void   AddFlashPos( bool bOnNPC, const char* pPosName, float fX, float fY, int nSceneID );

	void   update();
	
	
protected:
	static CActivePosManager*		s_pMe;
	typedef std::list< MAP_POS_DEFINE >   POS_LIST;
	POS_LIST   m_listActiveObj;
	POS_LIST   m_listFlashObj;

	int			m_nDistance;
public:
	void   GetActiveList( int nSceneID, POS_LIST* pReturnList );
	void   GetFlashList( int nSceneID, POS_LIST* pReturnList );
private:
	void   update( POS_LIST* pList );


};

class CWorldManager : public tWorldSystem
{
public:
	/**
		进入某场景
		\param nSceneID	
			场景ID/玩家城市id

		\param nCityLevel
			玩家城市等级，如果小于0，表示是普通场景!

		\param nResID
			CYS-SCENERES: GCEnterScene.client_res. Pho ban (copyscene) duoc cap ID chay
			10001..10020 (define.COPY_SCENE_BEGIN=10000), ID do KHONG bao gio co dong trong
			SceneDefineEx; luc ay client_res moi la thu chi ra ban do. Chi tra bang nResID khi
			tra bang nSceneID khong ra gi, nen 195 canh thuong khong doi hanh vi.
			Bang chung: Docs/specs/server/maps-instance_vi.md muc 3.
	*/
	virtual BOOL							EnterScene(INT nSceneID, INT nCityLevel, INT nResID = -1);
	//升级玩家城市
	virtual BOOL							UpdateUserCity(int nNewLevel);
	///取得当前激活的场景
	virtual tScene*							GetActiveScene(VOID) { return (tScene*)m_pActiveScene; }
	///游戏过程中切换场景
	virtual VOID							ChangeScene(INT idTargetScene, const fVector2& fvPos, INT nDirection, BYTE bFlag);
	///取得当前状态
	virtual WORLD_STATION					GetStation(VOID) const		{ return m_Station; }
	//对外提供的地形高度查询接口(使用渲染系统坐标，考虑地形和行走面)
	virtual FUNC_GETTERRAINHEIGHT			GetTerrainHeightFunc(void) { return _GetTerrainHeight; }
	//当前场景的ServerID
	virtual INT								GetActiveSceneID(void) const;

public:
	//---- for debug
	//取得即将要去的场景ID
	INT		GetNextSenceID(VOID) const { return m_idNextScene; }
	fVector2	GetNextScenePos(VOID) const { return m_fvNextPos; }			
	FLOAT		GetNextSceneFaceDir(VOID) const { return m_fNextDir; }

public:
	//节点初始化
	virtual VOID	Initial(VOID*);
	//逻辑轮循函数
	virtual VOID	Tick(VOID);
	//释放自己所所拥有的资源
	virtual VOID	Release(VOID);

	virtual std::list< MAP_POS_DEFINE >* GetObjectListByClass( INT nType );
	virtual void setMinimapSerachRange( int nRange ){ m_nSearchRange = nRange; };
	virtual void UpdateMinimapData();
	virtual void MinimapNeedFresh();
	virtual fVector3 GetMyselfPos();
	virtual int GetMyselfDir();
	virtual const CHAR* GetSceneName( INT nSceneID );

public:
	//系统级别场景转移事件处理
	static VOID	WINAPI	_OnSceneTransEvent(const EVENT* pEvent, UINT_PTR dwOwnerData);
	//对外提供的地形高度查询接口(使用渲染系统坐标，考虑地形和行走面)
	static bool WINAPI 	_GetTerrainHeight(float fX, float fZ, float& fY);
	//给GAME层提供的高度查询接口
	static bool WINAPI 	GetTerrainHeight_GamePos(float fX, float fZ, float& fY);
	//---------------------------------------------------------
	//变量截获函数，用于控制各种音效的开关
	static VOID	WINAPI	_OnVariableChangedEvent(const EVENT* pEvent, UINT_PTR dwOwnerData);
	
public:
	CWorldManager();
	virtual ~CWorldManager();
	static CWorldManager* GetMe(VOID) { return s_pMe; }

protected:
	static CWorldManager*		s_pMe;

	///当前激活的场景
	CScene*						m_pActiveScene;
	// CYS-SCENERES: ID canh phia SERVER cua canh dang o. Voi canh thuong no bang
	// m_pActiveScene->GetSceneDefine()->nServerID; voi pho ban thi dinh nghia canh duoc tra bang
	// client_res nen hai so KHAC nhau, va thu server can (CGAskChangeScene.SourSceneID, so sanh
	// voi GCNotifyChangeScene.scene_from, doi chieu scene id cua thanh vien to doi) la so NAY.
	INT							m_nActiveServerSceneID;
	//当前状态
	WORLD_STATION				m_Station;

	//--- for debug
	//即将要去的场景ID
	INT							m_idNextScene;
	//即将要去的场景位置
	fVector2					m_fvNextPos;
	//即将要去的场景方向
	FLOAT						m_fNextDir;
	//--- for debug
	bool						m_bAnimyNeedFresh;
	std::list< MAP_POS_DEFINE > m_AnimylistObj;			// 敌人列表
	std::list< MAP_POS_DEFINE > m_ExpNPClistObj;		// NPC列表
	std::list< MAP_POS_DEFINE > m_FriendlistObj;		// 队友列表
	std::list< MAP_POS_DEFINE > m_PlayerlistObj;		// 别的玩家
	std::list< MAP_POS_DEFINE > m_ExpObjlistObj;		// 特殊道具列表
	std::list< MAP_POS_DEFINE > m_ActivelistObj;		// 激活点列表
	std::list< MAP_POS_DEFINE > m_ScenePoslistObj;		// 场景点列表
	std::list< MAP_POS_DEFINE > m_FlashlistObj;			// 激活点列表
	std::list< MAP_POS_DEFINE > m_PetlistObj;			// 宠物点列表

	
	CActivePosManager*			m_pActiveManager;
	int		m_nSearchRange;
private:
	bool	CheckIsFriend( INT id );
	void    AddFriend( CObject_PlayerOther* pObj );
protected:
	WX_DECLARE_DYNAMIC(CWorldManager);
};

