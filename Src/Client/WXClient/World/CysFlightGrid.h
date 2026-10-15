#pragma once
#include <vector>
#include <cstdint>
#include <cstring>
#include <cmath>
// CY Render.dll 18008e020: scene basename + .fly; u32 count, 16 reserved bytes,
// then count absolute Y floats. Older canonical scenes omit the reserved header.
// Both formats are recognized by exact size, never by guessing float contents.
class CysFlightGrid {
    std::vector<float> heights;
    int width=0, depth=0;
    float plane=0;
public:
    bool Load(const void* bytes, size_t size, int x, int z) {
        heights.clear(); width=depth=0;plane=0;
        if(!bytes || size<4 || x<1 || z<1 || x>8192 || z>8192) return false;
        uint32_t count=0; memcpy(&count,bytes,4);
        if(count!=uint64_t(x+1)*(z+1)) return false;
        size_t offset=size==size_t(count)*4+20 ? 20 : 4;
        if(size!=size_t(count)*4+offset) return false;
        std::vector<float> data(count); memcpy(data.data(),static_cast<const char*>(bytes)+offset,count*4);
        for(float h:data) if(!std::isfinite(h) || std::fabs(h)>100000) return false;
        plane=data[0];for(float h:data) if(h>plane) plane=h;
        heights.swap(data); width=x+1; depth=z+1; return true;
    }
    // One absolute flight plane per map, as requested for CY. Use the highest
    // authored flight sample, retaining the same finite grid/boundary checks.
    bool FlatSample(float x,float z,float& y) const {
        if(heights.empty() || !std::isfinite(x) || !std::isfinite(z) || x<0 || z<0 || x>width-1 || z>depth-1) return false;
        y=plane;return true;
    }
    bool Sample(float x,float z,float& y) const {
        if(heights.empty() || !std::isfinite(x) || !std::isfinite(z) || x<0 || z<0 || x>width-1 || z>depth-1) return false;
        int ix=static_cast<int>(x), iz=static_cast<int>(z);
        if(ix==width-1)--ix;if(iz==depth-1)--iz;
        float a=x-ix,b=z-iz;
        size_t n=size_t(iz)*width+ix;
        y=(1-b)*((1-a)*heights[n]+a*heights[n+1])+b*((1-a)*heights[n+width]+a*heights[n+width+1]);
        return true;
    }
};
