#pragma once
#include <math.h>

// GL/CY Start_Fly and Tick_Fly. Evidence and binary hashes:
// Build/Logs/2026-09-20-qinggong-2/01-cay-song-lam-the-nao.md, M8-M14.
namespace CysQinggongCore
{
    inline float Speed(float wireSpeed)
    {
        const float speed = wireSpeed * 1.2f;
        return speed > 0.01f ? speed : 1.0f;
    }
    inline float Duration(float distance, float speed)
    {
        const float duration = distance / speed;
        return duration > 0.01f ? duration : 1.0f;
    }
    inline float Lift(float length, float distanceToMidpoint)
    {
        if(length <= 3.0f) return 0.0f;
        const float span = length - 2.0f;
        const float half = span * 0.5f;
        const float d = distanceToMidpoint < half ? distanceToMidpoint : half;
        const float height = span * 0.25f < 3.0f ? span * 0.25f : 3.0f;
        const float ratio = d / half;
        return (1.0f - ratio * ratio) * height;
    }
    inline int AirLoops(float duration, float takeoff, float air, float landing)
    {
        if(air <= 0.0f) return 0;
        const float count = (duration - takeoff - landing) / air;
        return count > 0.0f ? int(floorf(count + 0.5f)) : 0;
    }
}
