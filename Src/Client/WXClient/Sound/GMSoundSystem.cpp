/****************************************\
*										*
* 			声音/音效管理器				*
*										*
\****************************************/

//
//ref NEL(R) Copyright, 2001 Nevrax Ltd.
//
#include "StdAfx.h"
#include "GMSoundSystem.h"
#include "GMSoundBuffer.h"
#include "GMSoundSource.h"
#include "../DBC/GMDataBase.h"
#include "TDException.h"
#include "../Procedure/GameProcedure.h"
#include "../Object/ObjectManager.h"
#include "../Object/Character/Obj_PlayerMySelf.h"
// CYS: FMOD 3.75 (x86-only fmodvc.lib) -> FMOD Core 2.02 (fmod_vc.lib/fmod.dll x64, imported target cys_fmod).
// CYS: Built without the SDK (no CYS_HAVE_FMOD) the sound system keeps all its bookkeeping but plays nothing.
#ifdef CYS_HAVE_FMOD
#include <fmod.hpp>
#include <fmod_errors.h>
#endif
#include "..\Procedure\GameProcedure.h"
#include "..\Variable\GMVariable.h"
#include "..\Event\GMEventSystem.h"
#include "..\Script\GMScriptSystem.h"
#include "..\WxRender\RenderSystem.h"
#include "CysAudio.h"	// CYS-AUDIO
#include "TDUtil.h"
using namespace LuaPlus;

// CYS: removed #pragma comment(lib, "Sound/fmod375/fmodvc.lib") - FMOD Core is linked by wxclient.cmake.

const CHAR CSoundSystemFMod::szAllSoundDisable[] = "DisableAllSound"; //关闭所有音效的开关
const CHAR CSoundSystemFMod::szBKSoundVar[] = "EnableBGSound";	//背景音效
const CHAR CSoundSystemFMod::sz3DSoundVar[] = "Enable3DSound";	//环境音效
const CHAR CSoundSystemFMod::szSKSoundVar[] = "EnableSKSound";	//技能音效
const CHAR CSoundSystemFMod::szUISoundVar[] = "EnableUISound";	//事件音效

const CHAR CSoundSystemFMod::szBKVolumeVar[] = "VOLUME_BG";	//背景音量
const CHAR CSoundSystemFMod::sz3DVolumeVar[] = "VOLUME_3D";	//环境音量
const CHAR CSoundSystemFMod::szSKVolumeVar[] = "VOLUME_SK";	//技能音量
const CHAR CSoundSystemFMod::szUIVolumeVar[] = "VOLUME_UI";	//事件音量

WX_IMPLEMENT_DYNAMIC(CSoundSystemFMod, GETCLASS(tSoundSystem));
CSoundSystemFMod* CSoundSystemFMod::s_pMe = NULL;
CSoundSystemFMod::CSoundSystemFMod()
{
	s_pMe = this;

	m_bMuteAll = FALSE;
	m_fMasterGain = 1.0f;
	m_vListenerPos = fVector3(0.0f, 0.0f, 0.0f);

	m_strSoundPath = "..\\Sound\\";

	m_pMetaTable = 0;
	m_pFModSystem = NULL;	// CYS
	m_bCysTestOutput = FALSE;	// CYS-AUDIO
}

CSoundSystemFMod::~CSoundSystemFMod()
{
	if(m_pMetaTable) delete m_pMetaTable;
	m_pMetaTable = 0;
}

VOID CSoundSystemFMod::Initial(VOID*)
{
#ifdef CYS_HAVE_FMOD
	// CYS: FSOUND_GetVersion/SetOutput(WINMM)/SetDriver/SetMixer/3D_SetRolloffFactor/Init(44100, 32, 0)
	// CYS: -> FMOD Core: System_Create + init(32 channels). Default output (WASAPI) instead of WinMM; 3D rolloff was
	// CYS: disabled and is still computed by hand. If no audio device is usable the game keeps running silent
	// CYS: (NOSOUND output, then no FMOD at all) instead of throwing like 0.85 did.
	m_pFModSystem = NULL;
	FMOD::System* pSystem = NULL;
	int nInitResult = -1;
	if(FMOD::System_Create(&pSystem) == FMOD_OK && pSystem)
	{
		unsigned int nVersion = 0;
		pSystem->getVersion(&nVersion);
		if(nVersion < FMOD_VERSION)
		{
			TDThrow("FMOD: You are using the wrong DLL version (%08x < %08x)!", nVersion, (UINT)FMOD_VERSION);
		}
		// CYS-AUDIO: CY 3.71 FUN_140687500: setOutput(AUTODETECT), init(32, FMOD_INIT_NORMAL), log output type and
		// CYS-AUDIO: every driver, NOSOUND when no driver, set3DSettings(1, 1, 1). Test runs may redirect the mix to a
		// CYS-AUDIO: WAV file (CYS_AUDIO_OUTPUT=wav:<file>) so the evidence needs no speakers.
		void* pExtra = CysAudio::ConfigureOutput(pSystem);
		m_bCysTestOutput = (GetEnvironmentVariableA("CYS_AUDIO_OUTPUT", NULL, 0) > 0);
		nInitResult = (int)pSystem->init(32, FMOD_INIT_NORMAL, pExtra);
		if(nInitResult != FMOD_OK)
		{
			pSystem->setOutput(FMOD_OUTPUTTYPE_NOSOUND);
			nInitResult = (int)pSystem->init(32, FMOD_INIT_NORMAL, NULL);
			if(nInitResult != FMOD_OK)
			{
				pSystem->release();
				pSystem = NULL;
			}
		}
		if(pSystem)
		{
			int nDrivers = 0;
			if(pSystem->getNumDrivers(&nDrivers) != FMOD_OK || nDrivers == 0)
				TDU_Log("Sound System can't find any sound driver, output type index : %i", nDrivers);
			pSystem->set3DSettings(1.0f, 1.0f, 1.0f);
			TDU_Log("Sound System x64 init succeed!");
		}
		m_pFModSystem = pSystem;
	}
	CysAudio::OnInitialised(m_pFModSystem, nInitResult);
#else
	CysAudio::OnInitialised(NULL, -1);
#endif

	//查询资源定义
	DBC_DEFINEHANDLE(s_dbcSound, DBC_SOUND_INFO);
	INT nLineNum = (INT)s_dbcSound->GetRecordsNum();
	for(INT i=0; i<nLineNum; i++)
	{
		const _DBC_SOUND_INFO* pDefine = (const _DBC_SOUND_INFO*)s_dbcSound->Search_LineNum_EQU(i);
		if(!pDefine) continue;

		SOUND_BUFFER newSound;
		newSound.pDefine = pDefine;
		newSound.pSoundBuf = NULL;

		//加入列表
		m_listSoundBuffer.push_back(newSound);

		//加入索引
		m_mapSoundID[pDefine->nID] = &(m_listSoundBuffer.back());
		m_mapSoundFile[pDefine->pSoundFile] = &(m_listSoundBuffer.back());
	}

	// CYS-AUDIO: SoundUI.txt (CY 3.71 GetDataBase(0x7b), 3 columns I/I/S): Sound:PlayUISound(n) plays row n
	{
		DBC::DBCFile dbcUI(0x7b);
		if(CDataBase::Util_OpenDBCFromTxt("SoundUI.txt", &dbcUI))
		{
			for(INT i = 0; i < (INT)dbcUI.GetRecordsNum(); i++)
			{
				const DBC::DBCFile::FIELD* pID = dbcUI.Search_Posistion(i, 0);
				const DBC::DBCFile::FIELD* pSnd = dbcUI.Search_Posistion(i, 1);
				if(pID && pSnd) m_mapCysSoundUI[pID->iValue] = pSnd->iValue;
			}
		}
		TDU_Log("CYS audio: SoundInfo rows=%d SoundUI rows=%d", nLineNum, (int)m_mapCysSoundUI.size());
	}

	//挂接变量系统
	CEventSystem::GetMe()->RegisterEventHandle("VARIABLE_CHANGED", _OnVariableChangedEvent);

	//设置如果未定义变量初试值
	CVariableSystem::GetMe()->SetVariableDefault(szBKSoundVar, "1");
	CVariableSystem::GetMe()->SetVariableDefault(sz3DSoundVar, "1");
	CVariableSystem::GetMe()->SetVariableDefault(szSKSoundVar, "1");
	CVariableSystem::GetMe()->SetVariableDefault(szUISoundVar, "1");
	// CYS-AUDIO: CY 3.71 Bin/System.cfg ships VOLUME_BG/3D/SK/UI = 0.5; without a value the channel would be silent.
	CVariableSystem::GetMe()->SetVariableDefault(szBKVolumeVar, "0.500000");
	CVariableSystem::GetMe()->SetVariableDefault(sz3DVolumeVar, "0.500000");
	CVariableSystem::GetMe()->SetVariableDefault(szSKVolumeVar, "0.500000");
	CVariableSystem::GetMe()->SetVariableDefault(szUIVolumeVar, "0.500000");
	CVariableSystem::GetMe()->SetVariableDefault("DisableMainSound", "0");
    CVariableSystem::GetMe()->SetVariableDefault(szAllSoundDisable, "0");
	TDU_Log("CYS audio: config EnableBGSound=%d Enable3DSound=%d EnableSKSound=%d EnableUISound=%d DisableMainSound=%d "
		"VOLUME_BG=%.2f VOLUME_3D=%.2f VOLUME_SK=%.2f VOLUME_UI=%.2f",
		CVariableSystem::GetMe()->GetAs_Int(szBKSoundVar), CVariableSystem::GetMe()->GetAs_Int(sz3DSoundVar),
		CVariableSystem::GetMe()->GetAs_Int(szSKSoundVar), CVariableSystem::GetMe()->GetAs_Int(szUISoundVar),
		CVariableSystem::GetMe()->GetAs_Int("DisableMainSound"),
		CVariableSystem::GetMe()->GetAs_Float(szBKVolumeVar), CVariableSystem::GetMe()->GetAs_Float(sz3DVolumeVar),
		CVariableSystem::GetMe()->GetAs_Float(szSKVolumeVar), CVariableSystem::GetMe()->GetAs_Float(szUIVolumeVar));

	//-----------------------------------------------------------
	//导出函数
	m_pMetaTable = new LuaPlus::LuaObject;
	*m_pMetaTable = CScriptSystem::GetMe()->GetLuaState()->GetGlobals().CreateTable("Sound");
	m_pMetaTable->SetObject("__index", *m_pMetaTable);

	m_pMetaTable->RegisterObjectFunctor("PlaySound", &CSoundSystemFMod::Lua_PlaySound);
	m_pMetaTable->RegisterObjectFunctor("StopSound", &CSoundSystemFMod::Lua_StopSound);
	// CYS-AUDIO: the two other host functions of CY 3.71 CNewSoundSystemFMod (FUN_140687500 registers PlaySound,
	// PlaySoundEffect, StopSound, PlayUISound); LuaApiGen_Sound.cpp only fills names still missing (stubs).
	m_pMetaTable->RegisterObjectFunctor("PlaySoundEffect", &CSoundSystemFMod::Lua_PlaySoundEffect);
	m_pMetaTable->RegisterObjectFunctor("PlayUISound", &CSoundSystemFMod::Lua_PlayUISound);

	LuaObject obj_Variable = CScriptSystem::GetMe()->GetLuaState()->BoxPointer(this);
	obj_Variable.SetMetaTable(*m_pMetaTable);
	CScriptSystem::GetMe()->GetLuaState()->GetGlobals().SetObject("Sound", obj_Variable);
}

VOID CSoundSystemFMod::Release(VOID)
{
	//---------------------------------
	//释放所有声音源
	std::list< SOUND_SOURCE >::iterator itSndSource;
	for(itSndSource=m_listSoundSource.begin(); itSndSource!=m_listSoundSource.end(); itSndSource++)
	{
		SOUND_SOURCE& sndSource = *itSndSource;

		if(sndSource.pSoundSource)
		{
			delete sndSource.pSoundSource;
			sndSource.pSoundSource = NULL;
		}
	}
	m_listSoundSource.clear();

	//---------------------------------
	//释放所有声音资源
	std::list< SOUND_BUFFER >::iterator itSndBuffer;
	for(itSndBuffer = m_listSoundBuffer.begin(); itSndBuffer!=m_listSoundBuffer.end(); itSndBuffer++)
	{
		SOUND_BUFFER& sndBuffer= *itSndBuffer;

		//释放声音资源
		if(sndBuffer.pSoundBuf)
		{
			delete sndBuffer.pSoundBuf;
			sndBuffer.pSoundBuf = NULL;
		}
	}

	//释放列表
	m_listSoundBuffer.clear();
	m_mapSoundID.clear();
	m_mapSoundFile.clear();

	//释放FMod
	CysAudio::OnRelease(m_pFModSystem);	// CYS-AUDIO
#ifdef CYS_HAVE_FMOD
	if(m_pFModSystem)	// CYS: was FSOUND_Close()
	{
		m_pFModSystem->close();
		m_pFModSystem->release();
		m_pFModSystem = NULL;
	}
#endif
}

BOOL CSoundSystemFMod::IsTypeEnabled(tSoundSource::Type type)
{
	CVariableSystem* pVarSystem = CVariableSystem::GetMe();
	bool bRet = false;
	switch(type)
	{
	case tSoundSource::type_background:
		bRet = (pVarSystem->GetAs_Int(szBKSoundVar)==1);
		break;

	case tSoundSource::type_circumstance:
		bRet = (pVarSystem->GetAs_Int(sz3DSoundVar)==1);
		break;

	case tSoundSource::type_skill:
		bRet = (pVarSystem->GetAs_Int(szSKSoundVar)==1);
		break;

	case tSoundSource::type_UI:
		bRet = (pVarSystem->GetAs_Int(szUISoundVar)==1);
		break;

	default:
		bRet = false;
		break;
	}

	return bRet;
}

float CSoundSystemFMod::GetTypeVolume(tSoundSource::Type type)
{
	if(m_bMuteAll || CVariableSystem::GetMe()->GetAs_Int(szAllSoundDisable)!=0 || !IsTypeEnabled(type)) return 0.0f;

	CVariableSystem* pVarSystem = CVariableSystem::GetMe();
	float gain = 0.0f;
	switch(type)
	{
	case tSoundSource::type_background:
		gain = pVarSystem->GetAs_Float(szBKVolumeVar);
		break;

	case tSoundSource::type_circumstance:
		gain = pVarSystem->GetAs_Float(sz3DVolumeVar);
		break;

	case tSoundSource::type_skill:
		gain = pVarSystem->GetAs_Float(szSKVolumeVar);
		break;

	case tSoundSource::type_UI:
		gain = pVarSystem->GetAs_Float(szUIVolumeVar);
		break;

	default:
		gain = 0.0f;
		break;
	}

	return gain;
}

VOID CSoundSystemFMod::Tick(VOID)
{
	CysAudio::TickBegin();	// CYS-AUDIO: CPU time of the sound tick (FMOD update included)
	//------------------------------------
	//刷新听者位置
	CObject_PlayerMySelf* pMySelf = CObjectManager::GetMe()->GetMySelf();
	if(pMySelf)
	{
		Listener_SetPos(pMySelf->GetPosition());
	}

	//------------------------------------
	//更新声音源音量
	{
		std::list< SOUND_SOURCE >::iterator it, itNext;
		for(it = m_listSoundSource.begin(); it!=m_listSoundSource.end(); it=itNext)
		{
			itNext = it; itNext++;

			SOUND_SOURCE& theSnd = *it;

			//如果是自动销毁的声音源,自动销毁
			theSnd.pSoundSource->UpdateStatus();

			if(theSnd.bAutoDestroy && theSnd.pSoundSource->IsStopped())
			{
				theSnd.pSoundSource->Stop();
				delete theSnd.pSoundSource;
				m_listSoundSource.erase(it);
				continue;
			}

			//更新音量
			theSnd.pSoundSource->UpdateVolume();
		}
	}

	//------------------------------------
	//销毁没有被引用的声音资源
	{
		std::list< SOUND_BUFFER >::iterator it;

		for(it = m_listSoundBuffer.begin(); it!=m_listSoundBuffer.end(); it++)
		{
			SOUND_BUFFER& theBuf = *it;

			//如果引用计数为0，销毁
			// CYS-AUDIO: CY 3.71 keeps an unreferenced buffer 60 ticks before releasing it (see GMSoundBuffer.h)
			if(theBuf.pSoundBuf && theBuf.pSoundBuf->GetRefrence() == 0)
			{
				if(++theBuf.pSoundBuf->m_nCysIdleTicks < 60) continue;
				delete theBuf.pSoundBuf;
				theBuf.pSoundBuf = 0;
			}
			else if(theBuf.pSoundBuf)
			{
				theBuf.pSoundBuf->m_nCysIdleTicks = 0;
			}
		}
	}

	//------------------------------------
	//如果窗口非激活，静音
	// CYS-AUDIO: test runs with CYS_AUDIO_OUTPUT (WAV writer / nosound) never mute: the smoke window is not the
	// foreground window, and the evidence is the mixed signal.
	BOOL bActive = CGameProcedure::IsWindowActive() || m_bCysTestOutput;
	if(!bActive && !m_bMuteAll)
	{
		MuteAll(TRUE);
		CysAudio::NoteMute(true, "window inactive");
	}
	else if(bActive && m_bMuteAll)
	{
		MuteAll(FALSE);
		CysAudio::NoteMute(false, "window active");
	}

#ifdef CYS_HAVE_FMOD
	// CYS: FMOD Core needs one update() per frame (channel status, stream feeding); FMOD 3.75 mixed on its own thread.
	if(m_pFModSystem) m_pFModSystem->update();
#endif
	CysAudio::TickEnd(m_pFModSystem, (int)m_listSoundSource.size());	// CYS-AUDIO
	_CysProbeTick();	// CYS-AUDIO
}

// CYS-AUDIO: CYS_AUDIO_PROBE=1 (evidence runs only): 8 s after MySelf exists, drive the real entry points once each,
// 1.5 s apart, for sound kinds the offline replay never triggers: Lua Sound:PlayUISound(19) (SoundUI "window open"),
// the LogicModel/impact entry _PlaySoundFunc with a CY skill file 5 m from the player, Lua Sound:PlaySoundEffect,
// PlaySoundFileAtGame (bullet/special/skill-start path) and a CEGUI ClickSound callback with SoundUI row 17.
VOID CSoundSystemFMod::_CysProbeTick(VOID)
{
	static INT s_nStep = -1;
	static ULONGLONG s_uStart = 0;
	if(s_nStep == -1)
	{
		s_nStep = (GetEnvironmentVariableA("CYS_AUDIO_PROBE", NULL, 0) > 0) ? 0 : 99;
		if(s_nStep == 0) TDU_Log("CYS audio: probe armed");
	}
	if(s_nStep >= 99) return;
	CObject_PlayerMySelf* pMySelf = CObjectManager::GetMe()->GetMySelf();
	if(!pMySelf) return;
	if(s_uStart == 0) s_uStart = GetTickCount64();
	ULONGLONG uAt = s_uStart + 8000 + (ULONGLONG)s_nStep * 1500;
	if(GetTickCount64() < uAt) return;
	fVector3 fvGame = pMySelf->GetPosition();
	fvGame.x += 3.0f; fvGame.z += 4.0f;
	switch(s_nStep)
	{
	case 0:
		TDU_Log("CYS audio: probe step 0 lua Sound:PlayUISound(19)");
		CScriptSystem::GetMe()->GetLuaState()->DoString("Sound:PlayUISound(19)");
		break;
	case 1:
		{
			fVector3 fvGfx;
			if(CGameProcedure::s_pGfxSystem->Axis_Trans(CRenderSystem::AX_GAME, fvGame, CRenderSystem::AX_GFX, fvGfx))
			{
				TDU_Log("CYS audio: probe step 1 _PlaySoundFunc(Skills\\Common\\lighting_2.wav) at 5 m");
				_PlaySoundFunc("Skills\\Common\\lighting_2.wav", &fvGfx.x, false);
			}
		}
		break;
	case 2:
		TDU_Log("CYS audio: probe step 2 lua Sound:PlaySoundEffect(66, false)");
		CScriptSystem::GetMe()->GetLuaState()->DoString("Sound:PlaySoundEffect(66, false)");
		break;
	case 3:
		TDU_Log("CYS audio: probe step 3 PlaySoundFileAtGame(weapon_shake_03.wav) at 5 m");
		PlaySoundFileAtGame("weapon_shake_03.wav", fvGame, FALSE, "probe-file");
		break;
	case 4:
		TDU_Log("CYS audio: probe step 4 CEGUI ClickSound callback row 17");
		_PlayUISoundIndexFunc(17);
		break;
	default:
		TDU_Log("CYS audio: probe done");
		s_nStep = 99;
		return;
	}
	s_nStep++;
}

//当窗口不激活时，将所有声音静音
VOID CSoundSystemFMod::MuteAll(BOOL bMute)
{
	if(bMute == m_bMuteAll) return;

	std::list< SOUND_SOURCE >::iterator it;
	for(it=m_listSoundSource.begin(); it!=m_listSoundSource.end(); it++)
	{
		SOUND_SOURCE& sndSource = *it;

#ifdef CYS_HAVE_FMOD
		// CYS: was GetFModChannel() >= 0 / FSOUND_SetMute(channel, mute)
		if(sndSource.pSoundSource && sndSource.pSoundSource->GetFModChannel())
			sndSource.pSoundSource->GetFModChannel()->setMute(bMute ? true : false);
#endif
	}
	m_bMuteAll = bMute;
}

//创建一个声音资源
tSoundBuffer* CSoundSystemFMod::Buffer_Create(INT nID)
{
	std::map< INT, SOUND_BUFFER* >::iterator it;
	it = m_mapSoundID.find(nID);

	//非法ID
	if(it == m_mapSoundID.end())
	{
		// CYS-AUDIO: CY 3.71 FUN_140689490 logs "Invalid sound source id: %d" and returns NULL (0.85 threw)
		CysAudio::NoteMissing("id", nID, "(not in SoundInfo.txt)");
		return NULL;
	}

	return Source_Load(*(it->second));
}

tSoundBuffer* CSoundSystemFMod::Buffer_Create(LPCTSTR szFileName)
{
	std::map< STRING, SOUND_BUFFER* >::iterator it;
	it = m_mapSoundFile.find(szFileName);

	//非法文件名
	if(it == m_mapSoundFile.end())
	{
		CysAudio::NoteMissing("name", -1, szFileName);	// CYS-AUDIO
		return NULL;
	}

	return Source_Load(*(it->second));
}

tSoundBuffer* CSoundSystemFMod::Source_Load(SOUND_BUFFER& sndBuffer)
{
	//尚未加载
	if(sndBuffer.pSoundBuf == NULL)
	{
		//加载资源
		CSoundBufferFMod* pSoundBuf = new CSoundBufferFMod;
		pSoundBuf->m_nCysSoundID = sndBuffer.pDefine->nID;	// CYS-AUDIO

		if(!(pSoundBuf->ReadWavBuffer(sndBuffer.pDefine->pSoundFile)))
		{
			// CYS-AUDIO: file absent from SoundFolder (or not decodable) -> log, skip
			CysAudio::NoteMissing("file", sndBuffer.pDefine->nID, sndBuffer.pDefine->pSoundFile);
			delete pSoundBuf;	// CYS: 0.85 leaked the buffer here
			return NULL;
		}

		//放入声音map
		sndBuffer.pSoundBuf = pSoundBuf;
	}

	return sndBuffer.pSoundBuf;
}


//创建一个播放源
tSoundSource* CSoundSystemFMod::Source_Create(tSoundSource::Type type, BOOL b3DMode, 
												BOOL bAutoDestroy)
{
	static INT s_idSource = 1;

	CSoundSourceFMod* pSource = new CSoundSourceFMod(s_idSource++, type, b3DMode);

	SOUND_SOURCE newSource;
	newSource.bAutoDestroy = bAutoDestroy;
	newSource.pSoundSource = pSource;

	m_listSoundSource.push_back(newSource);
	return (tSoundSource*)pSource;
}

VOID CSoundSystemFMod::Source_Destroy(tSoundSource* pSource)
{
	//查询ID
	std::list< SOUND_SOURCE >::iterator it;
	for(it=m_listSoundSource.begin(); it!=m_listSoundSource.end(); it++)
	{
		SOUND_SOURCE& theSnd = *it;

		if(theSnd.pSoundSource == pSource)
		{
			CysAudio::NoteStop(theSnd.pSoundSource->GetID(), theSnd.pSoundSource->GetCysWhat());	// CYS-AUDIO
			//删除实例
			delete theSnd.pSoundSource;
			m_listSoundSource.erase(it);
			return;
		}
	}
}

VOID CSoundSystemFMod::Source_Destroy(INT id)
{
	//查询ID
	std::list< SOUND_SOURCE >::iterator it;
	for(it=m_listSoundSource.begin(); it!=m_listSoundSource.end(); it++)
	{
		SOUND_SOURCE& theSnd = *it;

		if(theSnd.pSoundSource && theSnd.pSoundSource->GetID() == id)
		{
			CysAudio::NoteStop(id, theSnd.pSoundSource->GetCysWhat());	// CYS-AUDIO
			//删除实例
			delete theSnd.pSoundSource;
			m_listSoundSource.erase(it);
			return;
		}
	}
}

void CSoundSystemFMod::PlayUISoundFunc( INT nID )
{
	//-----------------------------------------------------------------------
	//创建3d声音播放源
	if(CVariableSystem::GetMe()->GetAs_Int(szUISoundVar) != TRUE) return;

	//加载资源
	tSoundBuffer* pSndBuffer = Buffer_Create(nID);
	if(!pSndBuffer) return;

	//创建一个声音源，自动删除
	tSoundSource* pSndSource = Source_Create(CSoundSourceFMod::type_UI, FALSE, TRUE);
	if(!pSndSource) return;
	((CSoundSourceFMod*)pSndSource)->SetCysWhat("ui");	// CYS-AUDIO

	//设置参数开始播放
	pSndSource->SetBuffer(pSndBuffer);
	pSndSource->SetLooping(FALSE);

	pSndSource->Play();
}

// CYS-AUDIO: CY 3.71 FUN_140687110 / FUN_140686c40: SoundUI row -> FUN_140688e00(sound id) (UI type, 2D, auto destroy)
VOID CSoundSystemFMod::PlayUISoundByIndex(INT nIndex)
{
	std::map< INT, INT >::iterator it = m_mapCysSoundUI.find(nIndex);
	if(it == m_mapCysSoundUI.end())
	{
		CysAudio::NoteMissing("ui-index", nIndex, "(not in SoundUI.txt)");
		return;
	}
	PlayUISoundFunc(it->second);
}

// CYS-AUDIO: CY 3.71 FUN_1406897c0: file name -> SoundInfo id
INT CSoundSystemFMod::FindSoundID(LPCTSTR szFileName)
{
	if(!szFileName) return -1;
	std::map< STRING, SOUND_BUFFER* >::iterator it = m_mapSoundFile.find(szFileName);
	if(it == m_mapSoundFile.end() || !it->second || !it->second->pDefine) return -1;
	return it->second->pDefine->nID;
}

// CYS-AUDIO: CY 3.71 FUN_140688ce0 (EnableSKSound checked, GFX->GAME position done by the caller here): skill type,
// 3D, max distance 20.0, loop as asked, auto destroy; returns the handle (source id) or -1.
INT CSoundSystemFMod::PlaySkillSound3D(INT nSoundID, const fVector3& fvGamePos, BOOL bLoop, const char* szWhat)
{
	if(CVariableSystem::GetMe()->GetAs_Int(szSKSoundVar) != 1) return -1;
	tSoundBuffer* pSndBuffer = Buffer_Create(nSoundID);
	if(!pSndBuffer) return -1;
	CSoundSourceFMod* pSndSource = (CSoundSourceFMod*)Source_Create(CSoundSourceFMod::type_skill, TRUE, TRUE);
	if(!pSndSource) return -1;
	pSndSource->SetCysWhat(szWhat);
	pSndSource->SetBuffer(pSndBuffer);
	pSndSource->SetMaxDistance(20.0f);
	pSndSource->SetPos(fvGamePos);
	pSndSource->SetLooping(bLoop);
	pSndSource->Play();
	return pSndSource->GetID();
}

INT CSoundSystemFMod::PlaySoundFileAtGame(const char* szFile, const fVector3& fvGamePos, BOOL bLoop, const char* szWhat)
{
	if(!s_pMe || !szFile || !szFile[0]) return -1;
	INT nID = s_pMe->FindSoundID(szFile);
	if(nID < 0)
	{
		CysAudio::NoteMissing(szWhat, -1, szFile);
		return -1;
	}
	return s_pMe->PlaySkillSound3D(nID, fvGamePos, bLoop, szWhat);
}

VOID CSoundSystemFMod::StopSoundHandle(INT& nHandle)
{
	if(s_pMe && nHandle > 0) s_pMe->Source_Destroy(nHandle);
	nHandle = -1;
}

INT CSoundSystemFMod::PlaySoundFunc(LPCTSTR szSoundFile, FLOAT* fvPos, BOOL bLoop)
{
	//-----------------------------------------------------------------------
	//坐标转换
	fVector3 fvGfx(fvPos[0], fvPos[1], fvPos[2]);
	fVector3 fvGame;
	if(!CGameProcedure::s_pGfxSystem->Axis_Trans(CRenderSystem::AX_GFX, fvGfx, 
			CRenderSystem::AX_GAME, fvGame))
	{
		return -1;
	}

	//-----------------------------------------------------------------------
	//创建3d声音播放源

	//加载资源
	tSoundBuffer* pSndBuffer = Buffer_Create(szSoundFile);
	if(!pSndBuffer) return -1;

	//创建一个声音源，自动删除
	tSoundSource* pSndSource = Source_Create(CSoundSourceFMod::type_skill, TRUE, TRUE);
	if(!pSndSource) return -1;
	// CYS-AUDIO: CY 3.71 FUN_1400a02c0 (effect/skill sound by file name) -> FUN_140688ce0: max distance 20.0
	((CSoundSourceFMod*)pSndSource)->SetCysWhat("skill-3d");
	((CSoundSourceFMod*)pSndSource)->SetMaxDistance(20.0f);

	//设置参数开始播放
	pSndSource->SetBuffer(pSndBuffer);
	pSndSource->SetPos(fvGame);
	pSndSource->SetLooping(bLoop);

	pSndSource->Play();

	// CYS: was (INT)(INT_PTR)pSndSource: a heap pointer does not fit an int on x64 (StopSoundFunc then never found
	// CYS: the source, so looping skill sounds were never stopped). The handle is the source id (>= 1) instead.
	return pSndSource->GetID();
}

VOID CSoundSystemFMod::StopSoundFunc(INT nHandle)
{
	if(nHandle == -1) return;

	// CYS: handle = source id (see PlaySoundFunc); was cast back to a CSoundSourceFMod pointer.
	//查找是否有该声音正在播放
	Source_Destroy(nHandle);
}

VOID WINAPI CSoundSystemFMod::_OnVariableChangedEvent(const EVENT* pEvent, UINT_PTR dwOwnerData)
{
	if(pEvent && pEvent->pEventDef && pEvent->pEventDef->idEvent == GE_VARIABLE_CHANGED)
	{
		const STRING& strVariable = pEvent->vArg[0];
		const STRING& strValue = pEvent->vArg[1];

		BOOL bEnable = (strValue=="1");

		//停止指定声音
		if(!bEnable)
		{
			if(strVariable == szSKSoundVar) 
			{
				GetMe()->StopSpecialSounds(tSoundSource::type_skill);
			}
			else if(strVariable == szUISoundVar)
			{
				GetMe()->StopSpecialSounds(tSoundSource::type_UI);
			}
		}
	}
}

VOID CSoundSystemFMod::StopSpecialSounds(tSoundSource::Type type)
{
	//更新声音源音量
	std::list< SOUND_SOURCE >::iterator it, itNext;
	for(it = m_listSoundSource.begin(); it!=m_listSoundSource.end(); it=itNext)
	{
		itNext = it; itNext++;
		SOUND_SOURCE& theSnd = *it;
	
		//各种音效的开关
		if(type == theSnd.pSoundSource->GetType())
		{
			theSnd.pSoundSource->Stop();
			delete theSnd.pSoundSource;
			m_listSoundSource.erase(it);
			continue;
		}
	}

}

INT CSoundSystemFMod::Lua_PlaySound(LuaPlus::LuaState* state)
{
	LuaStack args(state);
	if(!args[2].IsNumber())	// CYS-AUDIO: CY checks lua_type == LUA_TNUMBER
	{
		TDThrow("LUA:CSoundSystemFMod::Lua_PlaySound[2] param parameter error");
		return 0;
	}
	if(!args[3].IsBoolean())
	{
		TDThrow("LUA:CSoundSystemFMod::Lua_PlaySound[3] param parameter error");
		return 0;
	}

	int idSource = (int)args[2].GetNumber();
	bool bLoop =  args[3].GetBoolean();

	// CYS-AUDIO: CY 3.71 FUN_1406871b0: an optional 4th boolean marks "main" music (SelectServer.lua
	// CYS-AUDIO: Sound:PlaySound(2110, true, true)); it is skipped while DisableMainSound = 1.
	if(args[4].IsBoolean() && args[4].GetBoolean() && CVariableSystem::GetMe()->GetAs_Int("DisableMainSound") != 0)
	{
		TDU_Log("CYS audio: lua PlaySound id=%d skipped (DisableMainSound=1)", idSource);
		state->PushInteger(-1);
		return 1;
	}

	//生成Source
	tSoundBuffer* pSndBuffer = CSoundSystemFMod::GetMe()->Buffer_Create(idSource);
	if(!pSndBuffer)
	{
		state->PushInteger(-1);
		return 1;
	}

	//设置资源
	tSoundSource* pSound = Source_Create(CSoundSourceFMod::type_background, FALSE, !bLoop);
	if(pSndBuffer)
	{
		((CSoundSourceFMod*)pSound)->SetCysWhat("lua-PlaySound");	// CYS-AUDIO
		pSound->SetBuffer(pSndBuffer);
		pSound->SetLooping(bLoop);
		pSound->Play();
		state->PushInteger(pSound->GetID());
		return 1;
	}

	state->PushInteger(-1);
	return 1;
}

// CYS-AUDIO: CY 3.71 FUN_1406873d0
INT CSoundSystemFMod::Lua_PlaySoundEffect(LuaPlus::LuaState* state)
{
	LuaStack args(state);
	if(!args[2].IsNumber())
	{
		TDThrow("LUA:CNewSoundSystemFMod::Lua_PlaySoundEffect[2] param parameter error");
		return 0;
	}
	if(!args[3].IsBoolean())
	{
		TDThrow("LUA:CNewSoundSystemFMod::Lua_PlaySoundEffect[3] param parameter error");
		return 0;
	}
	int idSource = (int)args[2].GetNumber();
	bool bLoop = args[3].GetBoolean();
	tSoundBuffer* pSndBuffer = Buffer_Create(idSource);
	if(!pSndBuffer)
	{
		state->PushInteger(-1);
		return 1;
	}
	CSoundSourceFMod* pSound = (CSoundSourceFMod*)Source_Create(CSoundSourceFMod::type_skill, FALSE, !bLoop);
	pSound->SetCysWhat("lua-PlaySoundEffect");
	pSound->SetBuffer(pSndBuffer);
	pSound->SetLooping(bLoop);
	pSound->Play();
	state->PushInteger(pSound->GetID());
	return 1;
}

// CYS-AUDIO: CY 3.71 FUN_140687380 ("LUA: Lua_PlayUISound Wrong Param")
INT CSoundSystemFMod::Lua_PlayUISound(LuaPlus::LuaState* state)
{
	LuaStack args(state);
	if(!args[2].IsNumber())
	{
		TDThrow("LUA: Lua_PlayUISound Wrong Param");
		return 0;
	}
	PlayUISoundByIndex((int)args[2].GetNumber());
	return 0;
}

INT CSoundSystemFMod::Lua_StopSound(LuaPlus::LuaState* state)
{
	LuaStack args(state);
	if(!args[2].IsInteger()) 
	{
		TDThrow("LUA:CSoundSystemFMod::Lua_StopSound[2] param parameter error");
		return 0;
	}

	int idSound = args[2].GetInteger();

	Source_Destroy(idSound);
	return 0;
}


