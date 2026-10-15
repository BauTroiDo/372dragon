/****************************************\
*										*
* 				声音资源				*
*										*
\****************************************/
#pragma once
#include "TDSound.h"

// CYS: FMOD 3.75 (FSOUND_SAMPLE, x86 only) -> FMOD Core 2.02 sound object (x64); see GMSoundSystem.cpp.
namespace FMOD { class Sound; }
class CSoundSourceFMod;

class CSoundBufferFMod : public tSoundBuffer
{
	friend class CSoundSystemFMod;
public:
	//读取wav资源
	virtual BOOL		ReadWavBuffer(const STRING& name);
	//释放资源
	virtual VOID		Release(VOID);
	//增加计数
	void				AddRefrence(CSoundSourceFMod* pSource) {m_nRefCount++;}
	//减少计数
	void				DecRefrence(CSoundSourceFMod* pSource) {m_nRefCount--;}
	//取得计数
	INT					GetRefrence(void) const { return m_nRefCount; }

protected:
	CSoundBufferFMod();
	virtual ~CSoundBufferFMod();

protected:
	friend class CSoundSourceFMod;

	//FMOD实例指针
	FMOD::Sound*		m_pFModSample;	// CYS: was FSOUND_SAMPLE*; NULL = silent (no FMOD / load failed)

	//引用计数
	INT					m_nRefCount;

public:
	// CYS-AUDIO: SoundInfo id / file of this buffer (event log); ticks spent unreferenced. CY 3.71 keeps an
	// unreferenced buffer 60 ticks (CSoundSourceFMod dtor sets buffer+8 = 0x3c, Tick FUN_140687f80 releases it when the
	// count runs out) so a repeated UI/skill sound is not reloaded every time.
	INT					m_nCysSoundID;
	STRING				m_strCysFile;
	INT					m_nCysIdleTicks;
};