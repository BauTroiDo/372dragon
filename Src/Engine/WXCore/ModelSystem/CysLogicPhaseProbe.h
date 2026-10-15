#pragma once
#include <OgreLogManager.h>
#include <windows.h>
#include <map>

// Opt-in, aggregate attribution inside LogicModel::execute. No timing calls by default.
class CysLogicPhaseProbe
{
    struct Sample { LONGLONG ticks; unsigned long long calls;
        Sample() : ticks(0), calls(0) {} };
    typedef std::map<const char*, Sample> Samples;
    static Samples& samples() { static Samples value; return value; }
    LONGLONG last;
public:
    CysLogicPhaseProbe() : last(0)
    {
        static const bool enabled = []() { char v[8] = {}; return
            GetEnvironmentVariableA("CYS_CONTROLLER_PHASES", v, sizeof(v)) == 1 && v[0]=='1'; }();
        if (!enabled) return;
        LARGE_INTEGER now, frequency;
        QueryPerformanceCounter(&now); QueryPerformanceFrequency(&frequency);
        static LONGLONG window = 0;
        if (!window) window = now.QuadPart;
        if (now.QuadPart - window >= frequency.QuadPart * 5)
        {
            for (Samples::const_iterator i=samples().begin(); i!=samples().end(); ++i)
            {
                char line[256];
                _snprintf(line, sizeof(line), "CYS-LOGIC-PHASE: calls=%llu total_ms=%.4f per_call_ms=%.4f phase=%s",
                    i->second.calls, 1000.0*i->second.ticks/frequency.QuadPart,
                    1000.0*i->second.ticks/frequency.QuadPart/i->second.calls, i->first);
                line[sizeof(line)-1]=0;
                Ogre::LogManager::getSingleton().logMessage(line, Ogre::LML_CRITICAL);
            }
            samples().clear(); window=now.QuadPart;
        }
        QueryPerformanceCounter(&now); last=now.QuadPart;
    }
    void mark(const char* name)
    {
        if (!last) return;
        LARGE_INTEGER now; QueryPerformanceCounter(&now);
        Sample& sample=samples()[name];
        sample.ticks += now.QuadPart-last; ++sample.calls;
        QueryPerformanceCounter(&now); last=now.QuadPart;
    }
};
