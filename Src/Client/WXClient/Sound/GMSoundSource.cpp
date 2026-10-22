#include "StdAfx.h"
#include "GMSoundSource.h"
#include "GMSoundBuffer.h"
#include "GMSoundSystem.h"
#include "TDUtil.h"
// CYS: FMOD 3.75 FSOUND_* channel API -> FMOD Core 2.02 FMOD::Channel (x64). Without CYS_HAVE_FMOD every channel
// CYS: stays NULL and the source is silent.
#ifdef CYS_HAVE_FMOD
#include <fmod.hpp>
#endif
#include <assert.h>
#include <math.h>
#include "TDException.h"
#include "CysAudio.h"	// CYS-AUDIO

CSoundSourceFMod::CSoundSourceFMod(INT id, Type type, BOOL b3DMode) 
{
	_ID = id;
	_Sample = 0;
	_State = source_stoped;

	_Loop = TRUE;
	_b3DMode = b3DMode;
	_Alpha = 0.0;
	_Pos= fVector3(0.0f, 0.0f, 0.0f);

	_FModChannel= NULL;	// CYS: was -1
	_nType = type;
	_MaxDistance = 10.0f;
	_Gain = 1.0f;			// CYS-AUDIO: +0x6c = 1.0
	_szCysWhat = "source";
	_nCysPlayMs = 0;
}

CSoundSourceFMod::~CSoundSourceFMod()
{
	//减少对资源的引用
	if(_Sample)
	{
		((CSoundBufferFMod*)_Sample)->DecRefrence(this);
	}

	Stop();
}

void CSoundSourceFMod::SetBuffer(tSoundBuffer *buffer)
{
	TDAssert(buffer);

	if(_Sample)
	{
		((CSoundBufferFMod*)_Sample)->DecRefrence(this);
	}

	_Sample = buffer;
	((CSoundBufferFMod*)_Sample)->AddRefrence(this);
}

tSoundBuffer *CSoundSourceFMod::GetBuffer(VOID)
{
	return _Sample;
}

void CSoundSourceFMod::SetLooping( BOOL loop )
{
	if(_Loop!=loop)
	{
		_Loop = loop;
#ifdef CYS_HAVE_FMOD
		if(_FModChannel)	// CYS: FSOUND_SetPaused/SetLoopMode -> FMOD::Channel
		{
			//首先暂停
			_FModChannel->setPaused(true);
			_FModChannel->setMode(_Loop?FMOD_LOOP_NORMAL:FMOD_LOOP_OFF);
			if(_Loop) _FModChannel->setLoopCount(-1);
			_FModChannel->setPaused(false);
		}
#endif
	}
}

VOID CSoundSourceFMod::Play(VOID)
{
	//停止
	Stop();

	//播放
	if(_Sample && CSoundSystemFMod::GetMe()->IsTypeEnabled(GetType()))
	{
		CSoundBufferFMod* bufFMod= static_cast<CSoundBufferFMod*>(_Sample);

		_State= source_playing;
		_nCysPlayMs = CysAudio::NowMs() + 1;	// CYS-AUDIO
#ifdef CYS_HAVE_FMOD
		// CYS: FSOUND_PlaySoundEx(FSOUND_FREE, sample, NULL, paused) -> System::playSound(sound, NULL, paused, &ch)
		FMOD::System* pFMod = CSoundSystemFMod::GetMe()->GetFModSystem();
		//以暂停模式开始播放声音
		if(pFMod && bufFMod->m_pFModSample)
		{
			if(pFMod->playSound(bufFMod->m_pFModSample, NULL, true, &_FModChannel) != FMOD_OK)
				_FModChannel = NULL;
		}

		//在Channel播放
		if(_FModChannel)
		{
			_FModChannel->setMode(_Loop?FMOD_LOOP_NORMAL:FMOD_LOOP_OFF);
			if(_Loop) _FModChannel->setLoopCount(-1);
			//音量
			UpdateVolume();
			//开始播放
			_FModChannel->setPaused(false);
		}
#endif
		// CYS-AUDIO: event log (file, type, channel, volume) for the audio evidence runs
		{
			int nChannel = -1;
			float fVol = -1.0f;
#ifdef CYS_HAVE_FMOD
			if(_FModChannel) { _FModChannel->getIndex(&nChannel); _FModChannel->getVolume(&fVol); }
#endif
			CysAudio::NotePlay(_szCysWhat, bufFMod->m_nCysSoundID, bufFMod->m_strCysFile.c_str(), (int)_nType, _ID,
				nChannel, fVol, _Loop ? true : false, _b3DMode ? true : false);
		}
	}
	else if(_Sample)
	{
		CSoundBufferFMod* bufFMod= static_cast<CSoundBufferFMod*>(_Sample);
		TDU_Log("CYS audio: disabled t_ms=%lu what=%s id=%d type=%s (Enable*Sound=0)", CysAudio::NowMs(), _szCysWhat,
			bufFMod->m_nCysSoundID, CysAudio::TypeName((int)_nType));
	}
}

void CSoundSourceFMod::Stop()
{
	_State= source_stoped;

	// Stop the FMod channel
	if(_FModChannel)	// CYS: was != -1 / FSOUND_StopSound
	{
#ifdef CYS_HAVE_FMOD
		_FModChannel->stop();
#endif
		_FModChannel= NULL;
	}
}

BOOL CSoundSourceFMod::IsPlaying(VOID) const
{
	return _State == source_playing;
}

BOOL CSoundSourceFMod::IsStopped(VOID) const
{
	return _State == source_silencing || _State == source_stoped;
}

void CSoundSourceFMod::SetPos( const fVector3& pos )
{
	_Pos = pos;

	//3d模式
	if(_b3DMode)
	{
		UpdateVolume();
	}
}

void CSoundSourceFMod::UpdateVolume()
{
	// only if channel active
	if(!_FModChannel)	// CYS: was == -1
		return;

	float fGain = CSoundSystemFMod::GetMe()->GetTypeVolume(GetType());

	//3D模式
	if(_b3DMode)
	{



		const fVector3& vL = CSoundSystemFMod::GetMe()->Listener_GetPos();
		const fVector3& vS = GetPos();
		FLOAT dx = vL.x - vS.x, dz = vL.z - vS.z;
		FLOAT fDist = (FLOAT)sqrt(dx*dx + dz*dz);
		FLOAT fAtt = 0.0f;
		if(fDist <= _MaxDistance) fAtt = (1.0f - fDist / _MaxDistance) * fGain;
		fAtt *= _Gain;
		TDU_Clamp(fAtt, 0.0f, 1.0f);

#ifdef CYS_HAVE_FMOD
		_FModChannel->setVolume(fAtt);	// CYS: FSOUND_SetVolume(ch, 0..255) -> setVolume(0..1)
#endif
	}
	else
	{
#ifdef CYS_HAVE_FMOD
		fGain *= _Gain;	// CYS-AUDIO: CY 2D volume = type volume * gain (+0x6c)
		TDU_Clamp(fGain, 0.0f, 1.0f);
		_FModChannel->setVolume(fGain);	// CYS: FSOUND_SetVolume(ch, 0..255) -> setVolume(0..1)
#endif
	}
}

VOID CSoundSourceFMod::UpdateStatus(VOID)
{
	if(_FModChannel && IsPlaying())	// CYS: was != -1
	{
		//播放完毕
		// CYS: FSOUND_IsPlaying -> Channel::isPlaying; a finished/stolen channel returns an invalid-handle error.
		bool bPlaying = false;
#ifdef CYS_HAVE_FMOD
		if(_FModChannel->isPlaying(&bPlaying) != FMOD_OK) bPlaying = false;
		// CYS-AUDIO: once per play, 150 ms in (or at the end): proof that FMOD is mixing this channel -
		// CYS-AUDIO: playback position advanced, audibility = final gain after volume/attenuation/mute.
		if(_nCysPlayMs && (!bPlaying || CysAudio::NowMs() + 1 >= _nCysPlayMs + 150))
		{
			unsigned int nPosMs = 0;
			float fAud = -1.0f;
			_FModChannel->getPosition(&nPosMs, FMOD_TIMEUNIT_MS);
			_FModChannel->getAudibility(&fAud);
			TDU_Log("CYS audio: mixed t_ms=%lu source=%d what=%s position_ms=%u audibility=%.3f playing=%d",
				CysAudio::NowMs(), _ID, _szCysWhat, nPosMs, fAud, bPlaying ? 1 : 0);
			_nCysPlayMs = 0;
		}
#endif
		if(!bPlaying)
		{
			_State= source_silencing;
		}
	}
}

INT CSoundSourceFMod::_ComputeManualRollOff(INT volumeDB, INT dbMin, INT dbMax, DOUBLE alpha, FLOAT sqrdist) const
{
	FLOAT min = 0.0;
	FLOAT max = 40.0f;
	
	if (sqrdist < min * min) 
	{
		// no attenuation
		return volumeDB;
	}
	else if (sqrdist > max * max)
	{
		// full attenuation
		return dbMin;
	}
	else
	{
		DOUBLE dist = (DOUBLE) sqrt(sqrdist);
		
		// linearly descending volume on a dB scale
		DOUBLE db1 = dbMin * (dist - min) / (max - min);
		
		if (alpha == 0.0) {
			volumeDB += (INT) db1;
			
		} else if (alpha > 0.0) {
			DOUBLE amp2 = 0.0001 + 0.9999 * (max - dist) / (max - min); // linear amp between 0.00001 and 1.0
			DOUBLE db2 = 2000.0 * log10(amp2); // convert to 1/100th decibels
			volumeDB += (INT) ((1.0 - alpha) * db1 + alpha * db2);
			
		} else if (alpha < 0.0) {
			DOUBLE amp3 = min / dist; // linear amplitude is 1/distance
			DOUBLE db3 = 2000.0 * log10(amp3); // convert to 1/100th decibels
			volumeDB += (INT) ((1.0 + alpha) * db1 - alpha * db3);
		}
		
		TDU_Clamp(volumeDB, dbMin, dbMax);
		
		return volumeDB;
	}
}