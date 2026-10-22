#include "StdAfx.h"
#include "GMSoundBuffer.h"
#include "GMSoundSystem.h"
#include "../Procedure/GameProcedure.h"
#include "../WXRender/ResourceProvider.h"
// CYS: FMOD 3.75 (fmod375/fmod.h, x86-only fmodvc.lib) replaced by FMOD Core 2.02 (fmod.hpp, fmod_vc.lib x64).
#ifdef CYS_HAVE_FMOD
#include <fmod.hpp>
#endif
#include "TDException.h"
#include "TDUtil.h"	// CYS-AUDIO: TDU_Log
#include <assert.h>
#pragma comment(lib, "Winmm.lib.")

CSoundBufferFMod::CSoundBufferFMod()
{
	m_pFModSample= NULL;
	m_nRefCount = 0;
	m_nCysSoundID = -1;	// CYS-AUDIO
	m_nCysIdleTicks = 0;
}

CSoundBufferFMod::~CSoundBufferFMod()
{
	Release();
}

VOID CSoundBufferFMod::Release(VOID)
{
	if(m_pFModSample)
	{
#ifdef CYS_HAVE_FMOD
		m_pFModSample->release();	// CYS: was FSOUND_Sample_Free
#endif
		m_pFModSample= NULL;
	}
}

BOOL CSoundBufferFMod::ReadWavBuffer(const STRING &name)
{
	Release();
	m_strCysFile = name;	// CYS-AUDIO

#ifdef CYS_HAVE_FMOD
	// CYS: no FMOD device (FMOD init failed) -> keep a silent buffer instead of throwing.
	FMOD::System* pFMod = CSoundSystemFMod::GetMe() ? CSoundSystemFMod::GetMe()->GetFModSystem() : NULL;
	if(!pFMod) return TRUE;




	STRING strSlash = name;
	for(size_t i = 0; i < strSlash.size(); i++) if(strSlash[i] == '\\') strSlash[i] = '/';
	char* lpAddress = NULL;
	DWORD dwSize = CGameProcedure::s_pResourceProvider->loadResource(strSlash.c_str(), lpAddress, "General");
	if(dwSize == 0 && strSlash != name)
		dwSize = CGameProcedure::s_pResourceProvider->loadResource(name.c_str(), lpAddress, "General");
	if(dwSize > 0)
	{
		// CYS: was FSOUND_Sample_Load(FSOUND_FREE, mem, FSOUND_HW3D|FSOUND_LOADMEMORY, 0, size). The volume of 3D
		// CYS: sources is computed by hand (CSoundSourceFMod::UpdateVolume), so a 2D sample is equivalent.
		// CYS: FMOD_OPENMEMORY copies the data, so the resource can be unloaded right away as before.
		// CYS-AUDIO: CY 3.71 creates the sound with mode 0x808 (FMOD_OPENMEMORY | FMOD_2D) and defaultfrequency
		// CYS-AUDIO: 44100: the whole file (wav or mp3) is decoded into memory, as FMOD_CREATESAMPLE does here.
		FMOD_CREATESOUNDEXINFO exinfo;
		memset(&exinfo, 0, sizeof(exinfo));
		exinfo.cbsize = sizeof(exinfo);
		exinfo.length = (unsigned int)dwSize;
		exinfo.defaultfrequency = 44100;
		FMOD::Sound* pSound = NULL;
		FMOD_RESULT r = pFMod->createSound(lpAddress, FMOD_OPENMEMORY | FMOD_CREATESAMPLE | FMOD_2D | FMOD_LOOP_OFF,
				&exinfo, &pSound);
		if(r == FMOD_OK)
		{
			m_pFModSample = pSound;
		}
		else
		{
			TDU_Log("CYS audio: decode failed file=%s bytes=%lu fmod=%d", name.c_str(), (unsigned long)dwSize, (int)r);
		}
		CGameProcedure::s_pResourceProvider->unloadResource( lpAddress, dwSize );
	}

	if(!m_pFModSample)
	{
		// CYS-AUDIO: missing/undecodable file -> logged by the caller and skipped (0.85 threw "Invalid sound file").
		return FALSE;
	}
	//缺省所有声音都是不循环的 (CYS: FMOD_LOOP_OFF is part of the createSound mode above)
#endif
	return TRUE;
}
