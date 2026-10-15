// CYS-AUDIO (audio-cy 15/09/2026): see CysAudio.h and Docs/specs/game/audio-cy_vi.md.
#include "StdAfx.h"
#include "CysAudio.h"
#include "TDUtil.h"
#ifdef CYS_HAVE_FMOD
#include <fmod.hpp>
#include <fmod_errors.h>
#endif
#include <windows.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

namespace
{
    ULONGLONG g_uStartTick = 0;

    // output meter (sampled once per tick from the master channel group head DSP)
    double g_fRmsSum = 0.0;       // sum of per-sample-window RMS (max over channels)
    double g_fRmsMax = 0.0;
    double g_fPeakMax = 0.0;
    unsigned long g_nMeterWindows = 0;
    unsigned long g_nSignalWindows = 0;   // windows with RMS above -60 dBFS
    unsigned long g_nTotalSignalWindows = 0;
    unsigned long g_nTotalWindows = 0;
    double g_fTotalRmsMax = 0.0;

    // CPU of CSoundSystemFMod::Tick
    LARGE_INTEGER g_liFreq = { 0 };
    LARGE_INTEGER g_liTickStart = { 0 };
    double g_fTickMsSum = 0.0;
    double g_fTickMsMax = 0.0;
    unsigned long g_nTicks = 0;
    double g_fAllTickMsSum = 0.0;
    double g_fAllTickMsMax = 0.0;
    unsigned long g_nAllTicks = 0;
    unsigned long g_nTicksOver1ms = 0;
    ULONGLONG g_uLastReport = 0;

    unsigned long g_nPlays = 0;
    unsigned long g_nMissing = 0;
    char g_szOutputMode[300] = "";

    double ToDb(double f) { return f > 1e-9 ? 20.0 * log10(f) : -180.0; }
}

namespace CysAudio
{
    unsigned long NowMs(void)
    {
        if (g_uStartTick == 0) return 0;
        return (unsigned long)(GetTickCount64() - g_uStartTick);
    }

    const char* TypeName(int nType)
    {
        switch (nType)
        {
        case 0: return "bg";
        case 1: return "skill";
        case 2: return "env";
        case 3: return "ui";
        default: return "?";
        }
    }

    void* ConfigureOutput(FMOD::System* pSystem)
    {
        g_uStartTick = GetTickCount64();
        QueryPerformanceFrequency(&g_liFreq);
        g_szOutputMode[0] = 0;
        char szEnv[300];
        DWORD n = GetEnvironmentVariableA("CYS_AUDIO_OUTPUT", szEnv, sizeof(szEnv));
        if (n == 0 || n >= sizeof(szEnv)) return NULL;
#ifdef CYS_HAVE_FMOD
        if (_strnicmp(szEnv, "wav:", 4) == 0 && szEnv[4])
        {
            strncpy(g_szOutputMode, szEnv + 4, sizeof(g_szOutputMode) - 1);
            g_szOutputMode[sizeof(g_szOutputMode) - 1] = 0;
            FMOD_RESULT r = pSystem->setOutput(FMOD_OUTPUTTYPE_WAVWRITER);
            TDU_Log("CYS audio: test output = FMOD WAV writer file=%s result=%d", g_szOutputMode, (int)r);
            return r == FMOD_OK ? (void*)g_szOutputMode : NULL;
        }
        if (_stricmp(szEnv, "nosound") == 0)
        {
            FMOD_RESULT r = pSystem->setOutput(FMOD_OUTPUTTYPE_NOSOUND);
            TDU_Log("CYS audio: test output = nosound result=%d", (int)r);
        }
#endif
        return NULL;
    }

    void OnInitialised(FMOD::System* pSystem, int nInitResult)
    {
#ifdef CYS_HAVE_FMOD
        if (!pSystem)
        {
            TDU_Log("CYS audio: FMOD not available (init result %d) - silent", nInitResult);
            return;
        }
        unsigned int nVersion = 0;
        pSystem->getVersion(&nVersion);
        FMOD_OUTPUTTYPE eOutput = FMOD_OUTPUTTYPE_UNKNOWN;
        pSystem->getOutput(&eOutput);
        const char* szOut = "other";
        switch (eOutput)
        {
        case FMOD_OUTPUTTYPE_WASAPI: szOut = "Windows Audio Session API"; break;
        case FMOD_OUTPUTTYPE_NOSOUND: szOut = "nosound"; break;
        case FMOD_OUTPUTTYPE_WAVWRITER: szOut = "wav writer"; break;
        case FMOD_OUTPUTTYPE_ASIO: szOut = "ASIO"; break;
        case FMOD_OUTPUTTYPE_WINSONIC: szOut = "WinSonic"; break;
        default: break;
        }
        int nDrivers = 0;
        pSystem->getNumDrivers(&nDrivers);
        int nRate = 0, nRaw = 0;
        FMOD_SPEAKERMODE eMode = FMOD_SPEAKERMODE_DEFAULT;
        pSystem->getSoftwareFormat(&nRate, &eMode, &nRaw);
        TDU_Log("CYS audio: FMOD %x.%02x.%02x init=%d output=%d (%s) drivers=%d rate=%d speakers=%d channels=32",
            nVersion >> 16, (nVersion >> 8) & 0xff, nVersion & 0xff, nInitResult, (int)eOutput, szOut, nDrivers,
            nRate, nRaw);
        for (int i = 0; i < nDrivers && i < 8; i++)
        {
            char szName[256] = "";
            if (pSystem->getDriverInfo(i, szName, sizeof(szName), NULL, NULL, NULL, NULL) == FMOD_OK)
                TDU_Log("CYS audio: driver %d = %s", i, szName[0] ? szName : "(no name)");
        }
        FMOD::ChannelGroup* pMaster = NULL;
        if (pSystem->getMasterChannelGroup(&pMaster) == FMOD_OK && pMaster)
        {
            FMOD::DSP* pHead = NULL;
            if (pMaster->getDSP(FMOD_CHANNELCONTROL_DSP_HEAD, &pHead) == FMOD_OK && pHead)
            {
                FMOD_RESULT r = pHead->setMeteringEnabled(false, true);
                TDU_Log("CYS audio: output meter on master head DSP result=%d", (int)r);
            }
        }
#else
        TDU_Log("CYS audio: built without FMOD SDK - silent (init result %d)", nInitResult);
#endif
    }

    void OnRelease(FMOD::System* pSystem)
    {
        static bool s_bDone = false;
        if (s_bDone) return;
        s_bDone = true;
        double fAvg = g_nAllTicks ? g_fAllTickMsSum / g_nAllTicks : 0.0;
        TDU_Log("CYS audio: release t_ms=%lu plays=%lu missing=%lu meter_windows=%lu signal_windows=%lu "
            "rms_max_db=%.1f tick_avg_ms=%.4f tick_max_ms=%.3f ticks=%lu ticks_over_1ms=%lu", NowMs(), g_nPlays, g_nMissing,
            g_nTotalWindows, g_nTotalSignalWindows, ToDb(g_fTotalRmsMax), fAvg, g_fAllTickMsMax, g_nAllTicks, g_nTicksOver1ms);
    }

    void TickBegin(void)
    {
        QueryPerformanceCounter(&g_liTickStart);
    }

    void TickEnd(FMOD::System* pSystem, int nSources)
    {
        LARGE_INTEGER liNow;
        QueryPerformanceCounter(&liNow);
        double fMs = g_liFreq.QuadPart ? (double)(liNow.QuadPart - g_liTickStart.QuadPart) * 1000.0 / (double)g_liFreq.QuadPart : 0.0;
        g_fTickMsSum += fMs; g_nTicks++;
        if (fMs > g_fTickMsMax) g_fTickMsMax = fMs;
        g_fAllTickMsSum += fMs; g_nAllTicks++;
        if (fMs > g_fAllTickMsMax) g_fAllTickMsMax = fMs;
        if (fMs > 1.0) g_nTicksOver1ms++;

#ifdef CYS_HAVE_FMOD
        if (pSystem)
        {
            FMOD::ChannelGroup* pMaster = NULL;
            FMOD::DSP* pHead = NULL;
            if (pSystem->getMasterChannelGroup(&pMaster) == FMOD_OK && pMaster &&
                pMaster->getDSP(FMOD_CHANNELCONTROL_DSP_HEAD, &pHead) == FMOD_OK && pHead)
            {
                FMOD_DSP_METERING_INFO out;
                memset(&out, 0, sizeof(out));
                if (pHead->getMeteringInfo(NULL, &out) == FMOD_OK && out.numsamples > 0)
                {
                    double fRms = 0.0, fPeak = 0.0;
                    for (int c = 0; c < out.numchannels && c < 32; c++)
                    {
                        if (out.rmslevel[c] > fRms) fRms = out.rmslevel[c];
                        if (out.peaklevel[c] > fPeak) fPeak = out.peaklevel[c];
                    }
                    g_fRmsSum += fRms; g_nMeterWindows++; g_nTotalWindows++;
                    if (fRms > g_fRmsMax) g_fRmsMax = fRms;
                    if (fRms > g_fTotalRmsMax) g_fTotalRmsMax = fRms;
                    if (fPeak > g_fPeakMax) g_fPeakMax = fPeak;
                    if (fRms > 0.001) { g_nSignalWindows++; g_nTotalSignalWindows++; }
                }
            }
        }
#endif

        ULONGLONG uNow = GetTickCount64();
        if (g_uLastReport == 0) g_uLastReport = uNow;
        if (uNow - g_uLastReport >= 2000)
        {
            int nPlaying = 0;
            float fDsp = 0.0f, fUpdate = 0.0f;
#ifdef CYS_HAVE_FMOD
            if (pSystem)
            {
                int nReal = 0;
                pSystem->getChannelsPlaying(&nPlaying, &nReal);
                FMOD_CPU_USAGE cpu;
                memset(&cpu, 0, sizeof(cpu));
                if (pSystem->getCPUUsage(&cpu) == FMOD_OK) { fDsp = cpu.dsp; fUpdate = cpu.update; }
            }
#endif
            double fAvg = g_nMeterWindows ? g_fRmsSum / g_nMeterWindows : 0.0;
            TDU_Log("CYS audio: meter t_ms=%lu channels_playing=%d sources=%d windows=%lu signal_windows=%lu "
                "rms_avg_db=%.1f rms_max_db=%.1f peak_max_db=%.1f tick_avg_ms=%.4f tick_max_ms=%.3f ticks=%lu "
                "fmod_dsp_pct=%.2f fmod_update_pct=%.2f", NowMs(), nPlaying, nSources, g_nMeterWindows,
                g_nSignalWindows, ToDb(fAvg), ToDb(g_fRmsMax), ToDb(g_fPeakMax),
                g_nTicks ? g_fTickMsSum / g_nTicks : 0.0, g_fTickMsMax, g_nTicks, fDsp, fUpdate);
            g_fRmsSum = 0.0; g_fRmsMax = 0.0; g_fPeakMax = 0.0; g_nMeterWindows = 0; g_nSignalWindows = 0;
            g_fTickMsSum = 0.0; g_fTickMsMax = 0.0; g_nTicks = 0;
            g_uLastReport = uNow;
        }
    }

    void NotePlay(const char* szWhat, int nSoundID, const char* szFile, int nType, int nSourceID, int nChannel,
                  float fVolume, bool bLoop, bool b3D)
    {
        g_nPlays++;
        TDU_Log("CYS audio: play t_ms=%lu what=%s id=%d file=%s type=%s source=%d channel=%d volume=%.3f loop=%d 3d=%d",
            NowMs(), szWhat ? szWhat : "-", nSoundID, szFile ? szFile : "-", TypeName(nType), nSourceID, nChannel,
            fVolume, bLoop ? 1 : 0, b3D ? 1 : 0);
    }

    void NoteStop(int nSourceID, const char* szWhy)
    {
        TDU_Log("CYS audio: stop t_ms=%lu source=%d why=%s", NowMs(), nSourceID, szWhy ? szWhy : "-");
    }

    void NoteMissing(const char* szWhat, int nSoundID, const char* szFile)
    {
        g_nMissing++;
        if (g_nMissing <= 200)
            TDU_Log("CYS audio: missing t_ms=%lu what=%s id=%d file=%s (skipped)", NowMs(), szWhat ? szWhat : "-",
                nSoundID, szFile ? szFile : "-");
    }

    void NoteMute(bool bMute, const char* szWhy)
    {
        TDU_Log("CYS audio: mute t_ms=%lu mute=%d why=%s", NowMs(), bMute ? 1 : 0, szWhy ? szWhy : "-");
    }
}
