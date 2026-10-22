#include "StdAfx.h"
#include "../RenderSystem.h"
#include "Camera_Scene.h"
#include "TDMath.h"
#include <OgreCamera.h>
#include <OgreRoot.h>
#include "TDUtil.h"
#include "TDException.h"
#include "Core/WXSystem.h"
#include "Core/TerrainData.h"
#include "../Global.h"
#include "TDProfile.h"
#include "TDVariable.h"
//============================================================================================
FLOAT CCamera_Scene::STATIC_PITCH	= -38.5f*TDU_PI/180.0f;	//固定视角
FLOAT CCamera_Scene::MIN_DISTANCE	= 6.0f;					//极限情况，摄像机能够离人物的最近距离
FLOAT CCamera_Scene::MAX_DISTANCE	= 14.0f;				//极限情况，摄像机能够远离人物的最远距离
FLOAT CCamera_Scene::MIN_ANGLE		= 0.1f*TDU_PI/180.0f;	//角度最小计算误差
FLOAT CCamera_Scene::STEP_ANGLE		= 1.0f*TDU_PI/180.0f;	//角度最小调动范围

// CYS: CY 3.71 Render.dll (Docs/specs/render/camera3d_vi.md)
BOOL  CCamera_Scene::COLLIDE_BY_DISTANCE	= FALSE;	// DAT_1803b4cec = 0 (canh Type 0, vd Dai Ly)
FLOAT CCamera_Scene::DESIRED_DISTANCE		= 1750.0f;	// DAT_1803b01f4
FLOAT CCamera_Scene::NEAR_CLIP				= 5.0f;		// constructor @180026600: +0x54
FLOAT CCamera_Scene::FAR_CLIP				= 15000.0f;	// constructor @180026600: +0x50

//震荡专用局部变量
static	FLOAT	fCurBias			= 0;
static	FLOAT	fBiasStep			= 0;
static	BOOL	bCurDirIsUp			= TRUE;
static	UINT	uAlreadyVibTimes	= 0;


CCamera_Scene::CCamera_Scene(Ogre::Camera* pOgreCamera, const fVector3& fvPos, FLOAT fAddHeight, FLOAT fPitch, FLOAT fDistance, FLOAT fDirection)
	: CCamera(pOgreCamera)
{
	// CYS: thanh vien phai co gia tri truoc lan Update dau tien (setter goi Update)
	m_fvLookatPos = fVector3(0.0f, 0.0f, 0.0f);
	m_fAddHeight = fAddHeight;
	m_fPitch = fPitch;
	m_fDistance = fDistance;
	m_fDirection = fDirection;
	m_fvEye = fVector3(0.0f, 0.0f, 0.0f);
	m_fvLookAtGfx = fVector3(0.0f, 0.0f, 0.0f);
	m_status = NORMAL_STATUS;

	//-----------------------------------------------
	//进行初始化设置
	SetLookAt(fvPos);
	SetAddHeight(fAddHeight);
	SetPitch(fPitch);
	SetDistance(fDistance);
	SetDirection(fDirection);

	m_status = NORMAL_STATUS;
}

CCamera_Scene::~CCamera_Scene(VOID)
{
}

VOID CCamera_Scene::SetLookAt(const fVector3& fvPos)
{
	fVector3 fvTemp;
	if(!CRenderSystem::GetMe()->Axis_Trans(CRenderSystem::AX_GAME, 
		fVector3(fvPos.x, fvPos.y, fvPos.z), CRenderSystem::AX_GFX, fvTemp)) return;

	//位置相同而且眼睛也不用回归则直接返回
	if(fvTemp == m_fvLookatPos && STATIC_PITCH-m_fPitch<MIN_ANGLE && m_status == NORMAL_STATUS) return;

	m_fvLookatPos = fvTemp;
	Update();
}

VOID CCamera_Scene::SetAddHeight(FLOAT fAddHeight)
{
	TDAssert(fAddHeight >= 0.0f);


	m_fAddHeight = fAddHeight;

	Update();
}

VOID CCamera_Scene::SetPitch(FLOAT fPitch)
{
	m_fPitch = fPitch;
	Update();
}

VOID CCamera_Scene::SetDistance(FLOAT fDistance)
{
	TDAssert(fDistance>0.0f);

	//取得放缩系数
	fVector3 fvScale = CRenderSystem::GetMe()->GetSacle();

	//Attention!!!
	//一般来说，fvScale的三个值都是一样的，so...
	m_fDistance = fDistance*fvScale.y;



	const WX::TerrainData* pTerrainData = CRenderSystem::GetMe()->GetRenderSystem()->getTerrainData();
	if(COLLIDE_BY_DISTANCE && pTerrainData && !pTerrainData->isEmpty())
	{
		fVector3 fvLook = m_fvLookatPos;
		fvLook.y += m_fAddHeight*fvScale.y;
		const FLOAT fNear = m_pOgreCamera->getNearClipDistance();
		if(!_IsValidEye(pTerrainData, _GetEyePos(fvLook, m_fDistance, m_fDirection, m_fPitch), fNear))
		{
			while(m_fDistance > MIN_DISTANCE*fvScale.y)
			{
				if(_IsValidEye(pTerrainData, _GetEyePos(fvLook, m_fDistance, m_fDirection, m_fPitch), fNear)) break;
				m_fDistance -= 0.1f;
				if(m_fDistance <= MIN_DISTANCE*fvScale.y) { m_fDistance = MIN_DISTANCE*fvScale.y; break; }
			}
		}
		else
		{
			DESIRED_DISTANCE = m_fDistance;
		}
	}
	Update();
}

FLOAT CCamera_Scene::GetDistance(VOID) const
{
	//取得放缩系数
	fVector3 fvScale = CRenderSystem::GetMe()->GetSacle();

	return m_fDistance/fvScale.y;
}

VOID CCamera_Scene::SetDirection(FLOAT fDirection)
{
	m_fDirection = fDirection;

	Update();
}

VOID CCamera_Scene::Update(VOID)
{
	//-----------------------------------------
	//地形是否加载
	if(CRenderSystem::GetMe()->GetRenderSystem()->getTerrainData()->isEmpty()) return;

	//-----------------------------------------
	//取得放缩系数
	fVector3 fvScale = CRenderSystem::GetMe()->GetSacle();

	//-----------------------------------------
	//将相机所看的点转化为渲染系统坐标系
	fVector3 fvGfxLookatPos = m_fvLookatPos;

	//增加附加的高度(一般是人物高度)
	fvGfxLookatPos.y += m_fAddHeight*fvScale.y;

	// CYS: C CCamera_Scene::Update @180003d00 - near/far clip moi lan cap nhat
	m_pOgreCamera->setNearClipDistance(NEAR_CLIP);
	m_pOgreCamera->setFarClipDistance(FAR_CLIP);

	if(COLLIDE_BY_DISTANCE)
	{
		// CYS: C nhanh DAT_1803b4cec != 0: giu pitch, rut ngan khoang cach
		m_fDistance = _GetValidDistance(
						CRenderSystem::GetMe()->GetRenderSystem()->getTerrainData(),
						fvGfxLookatPos, m_fDistance, m_fDirection, m_fPitch, DESIRED_DISTANCE,
						m_pOgreCamera->getNearClipDistance());
	}
	else
	//-------------------------------------------------
	//根据与地形的物理碰计算出最接近的Pitch
	m_fPitch = _GetValidPitch(
						CRenderSystem::GetMe()->GetRenderSystem()->getTerrainData(),	//地形数据
						fvGfxLookatPos,												//关注点
						m_fDistance,												//距离
						m_fDirection,												//旋转角度
						m_fPitch,													//目前的Pitch(尽量接近此值)
						STATIC_PITCH,												//要趋近的Pitch
						m_pOgreCamera->getNearClipDistance()
						);

	//-------------------------------------------------
	//计算出眼睛所在的位置
	fVector3 vEyePos = _GetEyePos(fvGfxLookatPos, m_fDistance, m_fDirection, m_fPitch);

	//-------------------------------------------------
	//根据当前摄像机状态计算偏移
	_UpdateCurStatus(vEyePos, fvGfxLookatPos);
	m_fvEye = vEyePos;				// CYS
	m_fvLookAtGfx = fvGfxLookatPos;	// CYS
	
	//-------------------------------------------------
	//设置OGRE像机
	m_pOgreCamera->setPosition(Ogre::Vector3(vEyePos.x, vEyePos.y, vEyePos.z));
	m_pOgreCamera->lookAt(Ogre::Vector3(fvGfxLookatPos.x, fvGfxLookatPos.y, fvGfxLookatPos.z));

	BOOL bHave;
	FLOAT fCamera_FOV = g_pVaribleSys->GetAs_Float("Camera_FOV", &bHave);
	float fAR;
	if(bHave)
		fAR = fCamera_FOV;
	else
		fAR = 45.0;


//	float fAR = m_pOgreCamera->getFOVy().valueDegrees();
	m_pOgreCamera->setFOVy(Ogre::Radian(Ogre::Degree(fAR).valueRadians()));


	//-------------------------------------------------
	//Info

	//--- for debug
	//fVector3 vGameEye;
	//CRenderSystem::GetMe()->Axis_Trans(CRenderSystem::AX_GFX, vEyePos, CRenderSystem::AX_GAME, vGameEye);

	//char szTemp[32];
	//_snprintf(szTemp, 32, "%.1f,%.1f,%.1f", 
	//	vGameEye.x, vGameEye.y, vGameEye.z);

	//CRenderSystem::GetMe()->SetDebugString("Eye", szTemp);
	//--- for debug



	CHAR szTemp[MAX_PATH];

	_snprintf(szTemp, MAX_PATH, "%.1f", -m_fPitch*180/TDU_PI);
	CRenderSystem::GetMe()->SetDebugString("CamPitch", szTemp);

	_snprintf(szTemp, MAX_PATH, "%.1f", m_fDistance);
	CRenderSystem::GetMe()->SetDebugString("CamDist", szTemp);

	//fVector3 fvEyeGame;
	//CRenderSystem::GetMe()->Axis_Trans(tGfxSystem::AX_GFX, vEyePos, 
	//	tGfxSystem::AX_GAME, fvEyeGame);

	//fVector3 fvEyeTerrain;
	//CRenderSystem::GetMe()->Axis_Trans(tGfxSystem::AX_PLAN, fvEyeGame, 
	//	tGfxSystem::AX_GAME, fvEyeTerrain);

//	_snprintf(szTemp, MAX_PATH, "%.1f[%s]", fvEyeGame.y-fvEyeTerrain.y, (bValid?"TRUE":"FALSE"));
//	CRenderSystem::GetMe()->SetDebugString("CamHeight", szTemp);


}

//===============================================================================

fVector3 CCamera_Scene::_GetEyePos(
							const fVector3& fvLookAt,
							FLOAT fDistance,
							FLOAT fDirection,
							FLOAT fPitch)
{
	FLOAT y		= fDistance * ::sin(-fPitch);
	FLOAT r_xy	= fDistance * ::cos(-fPitch);
	FLOAT x		= -r_xy * ::sin(fDirection);
	FLOAT z		= -r_xy * ::cos(fDirection);

	return fVector3 (	fvLookAt.x + x, 
						fvLookAt.y + y,
						fvLookAt.z + z);
}

FLOAT CCamera_Scene::_GetValidPitch(
							const WX::TerrainData* pTerrainData,	//地形数据
							const fVector3& fvLookAt,				//关注点
							FLOAT fDistance,						//距离
							FLOAT fDirection,						//旋转角度
							FLOAT fPitchNow,						//目前的Pitch(尽量接近此值)
							FLOAT fPitchApproch,					//要趋近的Pitch
							FLOAT fCameraNearDis)					//眼睛的近裁减距离
{
	TDAssert(pTerrainData && !pTerrainData->isEmpty());
	
	//-----------------------------------------------
	//当前眼睛位置
	fVector3 fvCurrentEye = _GetEyePos(fvLookAt, fDistance, fDirection, fPitchNow);
	//判断当前眼睛是否合理
	BOOL bIsCurrentValid = _IsValidEye(pTerrainData, fvCurrentEye, fCameraNearDis);

	if(bIsCurrentValid)
	{
		//当前Pitch是否足够接近最终Pitch
		BOOL bNearEnough = (::abs(fPitchApproch-fPitchNow) <= MIN_ANGLE);

		//当前位置合理直接返回
		if(bNearEnough)
			return fPitchApproch;
		else
		{
			//向最终Pitch靠近一个STEP
			FLOAT fPitch = fPitchNow+STEP_ANGLE;
			if(fPitch > fPitchApproch) fPitch = fPitchApproch;

			//眼睛
			fVector3 fvTempEye = _GetEyePos(fvLookAt, fDistance, fDirection, fPitch);
			//判断当前眼睛是否合理
			BOOL bIsTempValid = _IsValidEye(pTerrainData, fvTempEye, fCameraNearDis);
			if(bIsTempValid) return fPitch;
			else return fPitchNow;
		}

	}
	//如果不合理则计算出合理位置
	else
	{
		//按照STEP累加的方法计算出合法的眼睛
		INT nNum = 0;
		FLOAT fPitch;
		for(fPitch = fPitchNow-STEP_ANGLE; fPitch > -(TDU_PI/2.0f-MIN_ANGLE); fPitch-=STEP_ANGLE)
		{
			//眼睛位置
			fVector3 fvTempEye = _GetEyePos(fvLookAt, fDistance, fDirection, fPitch);
			//判断当前眼睛是否合理
			BOOL bIsTempValid = _IsValidEye(pTerrainData, fvTempEye, fCameraNearDis);

			nNum++;
			if(bIsTempValid) break;
		}
		return fPitch;
	}


	return 0;
}



FLOAT CCamera_Scene::_GetValidDistance(
							const WX::TerrainData* pTerrainData,
							const fVector3& fvLookAt,
							FLOAT fDistance,
							FLOAT fDirection,
							FLOAT fPitch,
							FLOAT fDesiredDistance,
							FLOAT fCameraNearDis)
{
	TDAssert(pTerrainData && !pTerrainData->isEmpty());
	const FLOAT fMin = MIN_DISTANCE*CRenderSystem::GetMe()->GetSacle().y;
	FLOAT d = fDistance;
	if(!_IsValidEye(pTerrainData, _GetEyePos(fvLookAt, d, fDirection, fPitch), fCameraNearDis))
	{
		while(fMin < d)
		{
			if(_IsValidEye(pTerrainData, _GetEyePos(fvLookAt, d, fDirection, fPitch), fCameraNearDis)) break;
			d -= 1.0f;
			if(d <= fMin) { d = fMin; break; }
		}
		return d;
	}
	d = d + 10.0f;
	if(fDesiredDistance < d) d = fDesiredDistance;
	while(fMin < d)
	{
		if(_IsValidEye(pTerrainData, _GetEyePos(fvLookAt, d, fDirection, fPitch), fCameraNearDis)) break;
		d -= 0.1f;
		if(d <= fMin) { d = fMin; break; }
	}
	return d;
}

BOOL CCamera_Scene::_IsValidEye(
							const WX::TerrainData* pTerrainData,	//地形数据
							const fVector3& fvEye,					//眼睛点
							FLOAT fCameraNearDis)					//近距离
{
	//近距碰撞球
	Ogre::Sphere ballNear;	
	ballNear.setCenter(Ogre::Vector3(fvEye.x, fvEye.y, fvEye.z));
	ballNear.setRadius(fCameraNearDis);

	CAMERA_INTER_GRIDS gridsTerrain;
	if(!_GetInterPatch(
			pTerrainData, 
			fvEye, 
			gridsTerrain))
	{
		//眼睛在地形外面
		return !COLLIDE_BY_DISTANCE;
	}

	//近距球是否在地形下面
	for(INT i=0; i<(INT)gridsTerrain.m_fvGrid.size(); i++)
	{
		const Ogre::AxisAlignedBox& theGridBox = gridsTerrain.m_fvGrid[i];

		//是否相交
		if(Ogre::Math::intersects(ballNear, theGridBox)) return FALSE;
	}

	return TRUE;
}

BOOL CCamera_Scene::_GetInterPatch(
							const WX::TerrainData* pTerrainData,		//地形数据
							const fVector3& fvEyePos,					//眼睛的投影位置
							CAMERA_INTER_GRIDS& theInterPatch)			//地形数据
{
	theInterPatch.m_fvGrid.clear();

	//是否在地形外面
	if(!pTerrainData || !(pTerrainData->isValidCoord(fvEyePos.x, fvEyePos.z))) return FALSE;

	//取得最近的Grid交点
	std::pair<INT, INT> pJunction = pTerrainData->getJunction(fvEyePos.x, fvEyePos.z);

	//最多四个个Grid
	theInterPatch.m_fvGrid.reserve(4);

	FLOAT fPatchX = pTerrainData->mScale.x*1.0f;
	FLOAT fPatchZ = pTerrainData->mScale.z*1.0f;

	//取得附近的八个三角形
	for(INT i=-1; i<=0; i++)
	{
		for(INT j=-1; j<=0; j++)
		{
			INT nGridX = pJunction.first  + i;
			INT nGridZ = pJunction.second + j;

			if(pTerrainData->isValidGrid(nGridX, nGridZ))
			{
				Ogre::AxisAlignedBox newGridBox;
				const WX::TerrainData::GridInfo& grid = pTerrainData->getGridInfo(nGridX, nGridZ);

				//转化为一个绑定盒
				FLOAT fMaxY = -std::numeric_limits<FLOAT>::max();

				FLOAT fTemp;
				fTemp = pTerrainData->getHeight(nGridX, nGridZ);
				if(fTemp > fMaxY) fMaxY = fTemp;

				fTemp = pTerrainData->getHeight(nGridX+1, nGridZ);
				if(fTemp > fMaxY) fMaxY = fTemp;

				fTemp = pTerrainData->getHeight(nGridX, nGridZ+1);
				if(fTemp > fMaxY) fMaxY = fTemp;

				fTemp = pTerrainData->getHeight(nGridX+1, nGridZ+1);
				if(fTemp > fMaxY) fMaxY = fTemp;

				newGridBox.setExtents(	
					nGridX*(pTerrainData->mScale.x) + pTerrainData->mPosition.x,
					-std::numeric_limits<FLOAT>::max(), 
					nGridZ*(pTerrainData->mScale.z) + pTerrainData->mPosition.z,
					
					(nGridX+1)*(pTerrainData->mScale.x) + pTerrainData->mPosition.x, 
					fMaxY, 
					(nGridZ+1)*(pTerrainData->mScale.z) + pTerrainData->mPosition.z);
										
				theInterPatch.m_fvGrid.push_back(newGridBox);
			}
		}
	}

	if(theInterPatch.m_fvGrid.size() == 2 || theInterPatch.m_fvGrid.size() == 4) return TRUE;

	return FALSE;
}

//设置加入一次震荡
VOID CCamera_Scene::AddOneVib(FLOAT VibRange, FLOAT StepLen, UINT Times )
{
	if( VibRange <=0 || Times <= 0 || StepLen<=0)
		return;

	if(m_status == VIBRATION_STATUS)
	{
		//以后再考虑多个震荡的融合
		return;
	}

	m_CurVibParam.fMaxBiasY	=	VibRange;
	m_CurVibParam.fMinBiasY	=	-VibRange;
	m_CurVibParam.nTimes	=	Times;
	m_CurVibParam.fBiasStep =	StepLen;

	_SetStatus(VIBRATION_STATUS);

}

//设置当前摄像机状态
BOOL CCamera_Scene::_SetStatus(CAMERA_STATUS nStatus )
{
	switch(nStatus)
	{
	case NORMAL_STATUS:
		{
			switch(m_status)
			{
			case VIBRATION_STATUS:
				{
					//...
					m_CurVibParam.fMaxBiasY	=	0.0;
					m_CurVibParam.fMinBiasY	=	0.0;
					m_CurVibParam.nTimes	=	0;
					m_CurVibParam.fBiasStep =	0.0;

					fCurBias			= 0.0;
					fBiasStep			= 0.0;
					bCurDirIsUp			= TRUE;
					uAlreadyVibTimes	= 0;
				}
				break;
			default:
				TDAssert(0);
				return FALSE;
			}
			m_status = nStatus;
			return TRUE;
		}
		break;
	case VIBRATION_STATUS:
		{
			switch(m_status)
			{
			case NORMAL_STATUS:
				{
					//开始第一次震荡
					fCurBias			= 0.0;
					fBiasStep			= m_CurVibParam.fBiasStep;
					bCurDirIsUp			= TRUE;
					uAlreadyVibTimes	= 0;
				}
				break;
			default:
				TDAssert(0);
				return FALSE;
			}
			m_status = nStatus;
			return TRUE;
		}
		break;
	default:
		TDAssert(0);
		return FALSE;
	}
	return TRUE;
}

//根据当前状态刷新摄像机
VOID CCamera_Scene::_UpdateCurStatus( fVector3& vEyePos, fVector3& vLookatPos)
{
	switch(m_status)
	{
	case NORMAL_STATUS:
		{
			return;
		}
		break;
	case VIBRATION_STATUS:
		{
			if( uAlreadyVibTimes == m_CurVibParam.nTimes)
			{
				_SetStatus(NORMAL_STATUS);
				return;
			}

			//计算本桢偏移
			fCurBias += fBiasStep;

			//根据当前位置更改方向
			if( bCurDirIsUp == FALSE && fCurBias > 0)
			{
				uAlreadyVibTimes++;
				bCurDirIsUp	=	TRUE;
			}
			else if( bCurDirIsUp == TRUE && fCurBias < 0)
			{
				bCurDirIsUp	=	FALSE;
			}

			//根据当前位置更改下次步长
			if(fCurBias > m_CurVibParam.fMaxBiasY)
			{
				fCurBias	=	m_CurVibParam.fMaxBiasY;
				fBiasStep	=	-m_CurVibParam.fBiasStep;
			}
			else if(fCurBias < m_CurVibParam.fMinBiasY)
			{
				fCurBias	=	m_CurVibParam.fMinBiasY;
				fBiasStep	=	m_CurVibParam.fBiasStep;
			}

			//返回新的位置
			vLookatPos.y += fCurBias;
			vEyePos.y	 += fCurBias;	
			return;
		}
		break;
	default:
		TDAssert(0);
		return;
	}
	return;
}
