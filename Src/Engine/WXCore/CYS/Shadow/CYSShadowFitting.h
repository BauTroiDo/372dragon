#ifndef __CYS_SHADOW_FITTING_H__
#define __CYS_SHADOW_FITTING_H__

// CY-Source (shadow agent): cascade geometry - split distances, frustum-slice bounds, light basis, matrices.
// Pure functions (no scene state), so they can be checked in isolation.

#include <OgrePrerequisites.h>
#include <OgreMatrix4.h>
#include <OgreVector3.h>

#include <vector>

namespace WX
{
    namespace CYSShadowFitting
    {
        /// The camera whose view the cascades cover.
        struct ViewDesc
        {
            Ogre::Vector3 position;
            Ogre::Vector3 direction;    ///< normalised
            Ogre::Vector3 up;
            Ogre::Vector3 right;
            Ogre::Real fovY;            ///< radians
            Ogre::Real aspect;          ///< width / height
            bool orthographic;
            Ogre::Real orthoHalfHeight;

            ViewDesc(void);
        };

        /** Far view depth of each of 'count' cascades between nearDist and farDist: the "practical" scheme,
            lambda * logarithmic + (1 - lambda) * linear. explicitSplits (>= count values) win when given. */
        void computeSplits(Ogre::Real nearDist, Ogre::Real farDist, size_t count, Ogre::Real lambda,
                           const std::vector<Ogre::Real>& explicitSplits, Ogre::Real* outFar);

        /** Smallest sphere containing the view-frustum slice between view depths a and b. Depends only on the
            projection and the two depths, never on the camera orientation, so its size is constant while the
            camera turns (the basis of shimmer-free cascades). */
        void sliceSphere(const ViewDesc& view, Ogre::Real a, Ogre::Real b, Ogre::Vector3& centre, Ogre::Real& radius);

        /// The 8 world-space corners of the slice (near 0-3, far 4-7).
        void sliceCorners(const ViewDesc& view, Ogre::Real a, Ogre::Real b, Ogre::Vector3 corners[8]);

        /** Right-handed light basis for a camera looking along 'dir' (the direction the light travels):
            x = right, y = up, z = -dir. The up hint is world +Z (world +X when dir is nearly parallel to Z), so
            the basis only changes with the light direction itself. */
        void lightBasis(const Ogre::Vector3& dir, Ogre::Vector3& x, Ogre::Vector3& y, Ogre::Vector3& z);

        /** View matrix with rows x, y, z whose origin lies on the line through the world origin along the light:
            light-space x/y are anchored to the world (texel snapping stays valid while the camera moves) and
            the linear depth of a point p is dot(dir, p) - depthOrigin. */
        Ogre::Matrix4 lightViewMatrix(const Ogre::Vector3& x, const Ogre::Vector3& y, const Ogre::Vector3& z,
                                      Ogre::Real depthOrigin);

        /// OpenGL-style orthographic projection of the light-view box [l,r]x[b,t], depths [n,f] (view z = -depth).
        Ogre::Matrix4 orthoProjection(double l, double r, double b, double t, double n, double f);

        /// Nearest multiple of 'step'.
        double snap(double value, double step);
    }
}

#endif // __CYS_SHADOW_FITTING_H__
