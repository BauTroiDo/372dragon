// CYS-AUDIO (audio-cy 15/09/2026): sound as CY 3.71 (Docs/specs/game/audio-cy_vi.md).
// Event log of every play/stop/missing file ("CYS audio:" lines in WXClient.log, with ms since the sound system
// started), output level meter (RMS/peak of the master channel group head DSP), optional WAV capture of the mixed
// output for test runs (CYS_AUDIO_OUTPUT=wav:<file> or nosound) and CPU time of the per-frame sound tick.
// Without FMOD (no CYS_HAVE_FMOD) only the log lines remain.
#pragma once

#include "TDBasicType.h"

namespace FMOD { class System; }

namespace CysAudio
{
    // ms since the sound system was initialised
    unsigned long NowMs(void);

    // Before System::init: CYS_AUDIO_OUTPUT = "wav:<file>" (FMOD WAV writer, nothing reaches the speakers) or
    // "nosound". Returns the extradriverdata for System::init (the WAV file name) or NULL.
    void* ConfigureOutput(FMOD::System* pSystem);

    void OnInitialised(FMOD::System* pSystem, int nInitResult);
    void OnRelease(FMOD::System* pSystem);

    // Around CSoundSystemFMod::Tick: CPU time of the tick, every ~2 s one meter/perf line.
    void TickBegin(void);
    void TickEnd(FMOD::System* pSystem, int nSources);

    // Events
    void NotePlay(const char* szWhat, int nSoundID, const char* szFile, int nType, int nSourceID, int nChannel,
                  float fVolume, bool bLoop, bool b3D);
    void NoteStop(int nSourceID, const char* szWhy);
    void NoteMissing(const char* szWhat, int nSoundID, const char* szFile);
    void NoteMute(bool bMute, const char* szWhy);

    const char* TypeName(int nType);
}
