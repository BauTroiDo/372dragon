// CY-Source (shadow agent): cascade geometry. See CYSShadowFitting.h.
#include "CYSShadowFitting.h"

#include <algorithm>
#include <cmath>
#include <cstdlib> // CYS-SHADOW-FINISH: getenv (basis A/B)

namespace WX
{
    namespace CYSShadowFitting
    {
        //-----------------------------------------------------------------------------------------------------------
        ViewDesc::ViewDesc(void)
            : position(Ogre::Vector3::ZERO)
            , direction(Ogre::Vector3::NEGATIVE_UNIT_Z)
            , up(Ogre::Vector3::UNIT_Y)
            , right(Ogre::Vector3::UNIT_X)
            , fovY(0.785398f)
            , aspect(1.0f)
            , orthographic(false)
            , orthoHalfHeight(1.0f)
        {
        }
        //-----------------------------------------------------------------------------------------------------------
        void computeSplits(Ogre::Real nearDist, Ogre::Real farDist, size_t count, Ogre::Real lambda,
                           const std::vector<Ogre::Real>& explicitSplits, Ogre::Real* outFar)
        {
            if (!count)
                return;
            if (explicitSplits.size() >= count)
            {
                for (size_t i = 0; i < count; ++i)
                    outFar[i] = explicitSplits[i];
                return;
            }
            const double n = std::max(double(nearDist), 0.01);
            const double f = std::max(double(farDist), n + 1.0);
            for (size_t i = 1; i <= count; ++i)
            {
                const double s = double(i) / double(count);
                const double logSplit = n * std::pow(f / n, s);
                const double linSplit = n + (f - n) * s;
                outFar[i - 1] = Ogre::Real(lambda * logSplit + (1.0 - lambda) * linSplit);
            }
            outFar[count - 1] = Ogre::Real(f); // exact far end
        }
        //-----------------------------------------------------------------------------------------------------------
        void sliceSphere(const ViewDesc& view, Ogre::Real a, Ogre::Real b, Ogre::Vector3& centre, Ogre::Real& radius)
        {
            const double da = a, db = b;
            if (view.orthographic)
            {
                const double h = view.orthoHalfHeight, w = h * view.aspect;
                centre = view.position + view.direction * Ogre::Real(0.5 * (da + db));
                radius = Ogre::Real(std::sqrt(0.25 * (db - da) * (db - da) + h * h + w * w));
                return;
            }
            // Corner rays of a symmetric frustum leave the axis with slope k: k^2 = tan^2(fovY/2) (1 + aspect^2).
            // A centre on the axis at depth z is equidistant from the near and far corner rings when
            // z = (a + b)(1 + k^2) / 2; beyond b the sphere around the far ring alone already holds the near ring.
            const double t = std::tan(0.5 * double(view.fovY));
            const double k2 = t * t * (1.0 + double(view.aspect) * double(view.aspect));
            double z = 0.5 * (da + db) * (1.0 + k2);
            if (z > db)
                z = db;
            centre = view.position + view.direction * Ogre::Real(z);
            radius = Ogre::Real(std::sqrt((db - z) * (db - z) + db * db * k2));
        }
        //-----------------------------------------------------------------------------------------------------------
        void sliceCorners(const ViewDesc& view, Ogre::Real a, Ogre::Real b, Ogre::Vector3 corners[8])
        {
            const Ogre::Real t = std::tan(0.5f * view.fovY);
            for (int s = 0; s < 2; ++s)
            {
                const Ogre::Real d = s ? b : a;
                const Ogre::Real hh = view.orthographic ? view.orthoHalfHeight : d * t;
                const Ogre::Real hw = hh * view.aspect;
                const Ogre::Vector3 c = view.position + view.direction * d;
                corners[s * 4 + 0] = c + view.up * hh - view.right * hw;
                corners[s * 4 + 1] = c + view.up * hh + view.right * hw;
                corners[s * 4 + 2] = c - view.up * hh + view.right * hw;
                corners[s * 4 + 3] = c - view.up * hh - view.right * hw;
            }
        }
        //-----------------------------------------------------------------------------------------------------------
        void lightBasis(const Ogre::Vector3& dir, Ogre::Vector3& x, Ogre::Vector3& y, Ogre::Vector3& z)
        {
            Ogre::Vector3 d = dir;
            d.normalise();
            z = -d;
            // CYS-SHADOW-FINISH: CY 3.71 aims its light camera with Ogre::Camera::setDirection (Render.dll
            // FUN_1800d90b0), and a Camera keeps the fixed yaw axis +Y, so Node::setDirection yields
            // x = normalise(Y x z), y = z x x. FACT: CY's shadow_view_matrix at Dali w09 is
            // row0 (0.8759, 0, -0.4824), row1 (-0.3084, 0.7690, -0.5599), row2 = -dir, which is exactly that basis
            // (row0.y = 0). Anchoring x to world Z instead only rotates the tile around the light, but the tight fit
            // is an AABB in this basis, so the old basis made the box 3.0 % / 1.7 % wider than CY's 9422 x 7555 at
            // that camera (coarser texels, more terrain tiles in the map). CYS_SHADOW_BASIS=z restores it for A/B.
            static const bool cyBasis = []() {
                const char* v = getenv("CYS_SHADOW_BASIS");
                return !(v && (v[0] == 'z' || v[0] == 'Z'));
            }();
            if (cyBasis && std::fabs(d.y) < 0.999f)
            {
                x = Ogre::Vector3::UNIT_Y.crossProduct(z);
                x.normalise();
                y = z.crossProduct(x);
                y.normalise();
                return;
            }
            const Ogre::Vector3 hint = std::fabs(d.z) < 0.95f ? Ogre::Vector3::UNIT_Z : Ogre::Vector3::UNIT_X;
            y = hint - z * z.dotProduct(hint);
            y.normalise();
            x = y.crossProduct(z); // x cross y = z: right-handed, camera looks down -z = dir
            x.normalise();
        }
        //-----------------------------------------------------------------------------------------------------------
        Ogre::Matrix4 lightViewMatrix(const Ogre::Vector3& x, const Ogre::Vector3& y, const Ogre::Vector3& z,
                                      Ogre::Real depthOrigin)
        {
            // view z = dot(z, p) + depthOrigin = -(dot(dir, p) - depthOrigin): the stored depth is -view z
            return Ogre::Matrix4(x.x, x.y, x.z, 0,
                                 y.x, y.y, y.z, 0,
                                 z.x, z.y, z.z, depthOrigin,
                                 0, 0, 0, 1);
        }
        //-----------------------------------------------------------------------------------------------------------
        Ogre::Matrix4 orthoProjection(double l, double r, double b, double t, double n, double f)
        {
            const double w = r - l, h = t - b, d = f - n;
            return Ogre::Matrix4(Ogre::Real(2.0 / w), 0, 0, Ogre::Real(-(r + l) / w),
                                 0, Ogre::Real(2.0 / h), 0, Ogre::Real(-(t + b) / h),
                                 0, 0, Ogre::Real(-2.0 / d), Ogre::Real(-(f + n) / d),
                                 0, 0, 0, 1);
        }
        //-----------------------------------------------------------------------------------------------------------
        double snap(double value, double step)
        {
            return step > 0 ? std::floor(value / step + 0.5) * step : value;
        }
    }
}
