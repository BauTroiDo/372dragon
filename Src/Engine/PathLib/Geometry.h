



#ifndef CYS_PATHLIB_GEOMETRY_H
#define CYS_PATHLIB_GEOMETRY_H

#pragma once

#include <cmath>

namespace PathLib {
namespace geom {

// Constants read out of PathLib.dll's .rdata (see report):
constexpr float kDenomEps = 1.1920929e-07f;  // DAT_1800459ac : parallel-segment threshold
constexpr float kCollinEps = 1.0e-6f;        // DAT_180044500 : collinearity threshold
constexpr float kUnitEps = 1.0e-8;           // DAT_1800459b0 : min length before normalise
constexpr float kOne = 1.0f;                 // DAT_180043c14

inline bool nearlyEqual(float a, float b, float eps) { return std::fabs(b - a) <= eps; }

inline float dist2(const float* a, const float* b) {
    const float dx = a[0] - b[0];
    const float dz = a[1] - b[1];
    return dx * dx + dz * dz;
}

inline float dist(const float* a, const float* b) { return std::sqrt(dist2(a, b)); }




inline bool segSeg(const float* a, const float* b, const float* c, const float* d, float* out) {
    const float denom = (d[1] - c[1]) * (b[0] - a[0]) - (b[1] - a[1]) * (d[0] - c[0]);
    if (nearlyEqual(denom, 0.0f, kDenomEps)) return false;
    const float ac_z = a[1] - c[1];
    const float ac_x = a[0] - c[0];
    const float t = ((d[0] - c[0]) * ac_z - (d[1] - c[1]) * ac_x) / denom;
    const float u = ((b[0] - a[0]) * ac_z - (b[1] - a[1]) * ac_x) / denom;
    out[0] = a[0] + (b[0] - a[0]) * t;
    out[1] = a[1] + (b[1] - a[1]) * t;
    return t >= 0.0f && t <= kOne && u >= 0.0f && u <= kOne;
}


inline float orient(const float* a, const float* b, const float* c) {
    return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0]);
}

inline bool segCross(const float* p1, const float* p2, const float* p3, const float* p4) {
    const float d1 = orient(p3, p4, p1);
    const float d2 = orient(p3, p4, p2);
    const float d3 = orient(p1, p2, p3);
    const float d4 = orient(p1, p2, p4);
    if (((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
        ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0)))
        return true;
    // Collinear/touching cases are treated as "not a proper crossing", matching the
    // original which uses a small epsilon and equal-sign short-circuits.
    return false;
}

// Point (px,pz) inside triangle (three (x,z) pairs).  Same sign convention as probe/path_query.
inline bool pointInTri(float px, float pz,
                       const float* v0, const float* v1, const float* v2) {
    const float d1 = (v1[0] - v0[0]) * (pz - v0[1]) - (v1[1] - v0[1]) * (px - v0[0]);
    const float d2 = (v2[0] - v1[0]) * (pz - v1[1]) - (v2[1] - v1[1]) * (px - v1[0]);
    const float d3 = (v0[0] - v2[0]) * (pz - v2[1]) - (v0[1] - v2[1]) * (px - v2[0]);
    const bool neg = d1 < 0.0f || d2 < 0.0f || d3 < 0.0f;
    const bool pos = d1 > 0.0f || d2 > 0.0f || d3 > 0.0f;
    return !(neg && pos);
}

inline bool pointInAabb(const float* p, const float* box /*minx,minz,maxx,maxz*/) {
    return box[0] <= p[0] && p[0] <= box[2] && box[1] <= p[1] && p[1] <= box[3];
}

}  // namespace geom
}  // namespace PathLib

#endif  // CYS_PATHLIB_GEOMETRY_H
