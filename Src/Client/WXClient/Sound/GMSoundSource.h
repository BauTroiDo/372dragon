/****************************************\
*										*
* 			声音播放源					*
*										*
\****************************************/

#pragma once

#include "TDSound.h"

namespace FMOD { class Channel; }	// CYS: FMOD Core 2.02 channel replaces the FMOD 3.75 channel index

class CSoundSourceFMod : public tSoundSource
{
	friend class CSoundSystemFMod;

public:
	//返回id
	virtual INT				GetID(void) const { return _ID; }
 	//所使用的声音源
	/*
	|	!!!如果在播放中设置该项，则不会马上生效，
	|需要执行Stop(); Play()后才会生效
	|
	*/
	virtual VOID			SetBuffer(tSoundBuffer *buffer);
	virtual tSoundBuffer*	GetBuffer(VOID);

    //是否循环播放
	virtual VOID			SetLooping(BOOL loop);
	virtual BOOL			GetLooping(VOID) const { return _Loop; }

    //播放
	virtual VOID			Play(VOID);
    //停止播放
	virtual VOID			Stop(VOID);
    //是否在播放中
	virtual BOOL			IsPlaying(VOID) const;
    //是否已经停止
	virtual BOOL			IsStopped(VOID) const;

	//播放源位置(default(0,0,0))
	virtual VOID			SetPos(const fVector3& pos);
	virtual const fVector3& GetPos(VOID) { return _Pos; }

	//更新音量
	virtual VOID			UpdateVolume(VOID);
	//更新状态
	virtual VOID			UpdateStatus(VOID);

	//声音类型
	virtual Type			GetType(void)const		{return _nType;}

protected:
	CSoundSourceFMod(INT id, Type type, BOOL b3DMode);
	virtual ~CSoundSourceFMod();

	//得到Channel
	FMOD::Channel*	GetFModChannel(VOID) const { return _FModChannel; }	// CYS: was INT (-1 = none), now NULL = none

	//播放源音量([0, 1], default:1)
	VOID			_SetGain(FLOAT gain);

private:
	enum TSourceState
	{
		source_stoped,			//停止中
		source_playing,			//正在播放
		source_silencing,		//播放完毕
	};
	TSourceState			_State;

	INT						_ID;
	tSoundBuffer			*_Sample;
	FMOD::Channel*			_FModChannel;	// CYS: was INT channel index
	
    // States
	BOOL					_b3DMode;	//TRUE- 3D模式,		 FALSE - 2D模式
    BOOL					_Loop;
	DOUBLE					_Alpha;
	fVector3				_Pos;

	// Type
	Type					_nType;

protected:
	//根据距离计算音量
	INT		_ComputeManualRollOff(INT volumeDB, INT dbMin, INT dbMax, DOUBLE alpha, FLOAT sqrdist) const;

public:
	// CYS-AUDIO: CY 3.71 CSoundSourceFMod (0xb0 bytes, ctor FUN_14068a880): max distance +0x64 (default 10.0,
	// skill 3D sounds 20.0 via FUN_140688ce0, ESD sounds the table distance), gain +0x6c (1.0). UpdateVolume
	// (FUN_14068a1d0): 2D = type volume * gain; 3D = type volume * (1 - d/max) * gain, 0 beyond max (d = listener
	// distance on the ground plane).
	VOID	SetMaxDistance(FLOAT fMax) { _MaxDistance = fMax > 0.01f ? fMax : 0.01f; }
	FLOAT	GetMaxDistance(VOID) const { return _MaxDistance; }
	VOID	SetGain(FLOAT fGain) { _Gain = fGain; }
	const char*	GetCysWhat(VOID) const { return _szCysWhat; }
	VOID	SetCysWhat(const char* szWhat) { _szCysWhat = szWhat; }	// static string: caller kind for the event log
private:
	FLOAT					_MaxDistance;
	unsigned long			_nCysPlayMs;		// CYS-AUDIO: NowMs at Play, 0 = mix already reported
	FLOAT					_Gain;
	const char*				_szCysWhat;
};