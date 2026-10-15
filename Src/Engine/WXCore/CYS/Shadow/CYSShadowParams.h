#ifndef __CYS_SHADOW_PARAMS_H__
#define __CYS_SHADOW_PARAMS_H__

// CY-Source (shadow agent): what the shadow system hands to the receivers each frame (the provider side of the
// shadow_* auto constants, Docs\specs\render\01-materials.md §4 and 03-shadows.md §3-§4), as plain data.
//
// Contract with ShaderLib\CalcShadow.inc of client_GL's MaterialTemplates.zip (FACT, 03 §4) and
// OgreAutoParamExternalProvider.h:
//  * one light view (shadow_view_matrix) shared by all cascades; the atlas stores the linear light-view depth
//    (-z in light view space, world units) of the nearest caster in .r, 0 = no caster;
//  * cascade i: t = posInLightView * shadow_csm_proj_scale[i] + shadow_csm_proj_offset[i] (component-wise)
//    must land in [0,1]^3 for the receivers it covers; the first cascade that contains the point is used;
//  * tiles sit side by side: atlas = (mapSize * count) x mapSize; the shader keeps a 1-texel border inside each
//    tile, i.e. t in [0,1] addresses tile texels [1, mapSize-1]. The scale/offset rows are therefore the
//    orthographic formula of OgreAutoParamExternalProvider.h applied to the tile INTERIOR, while the tile itself
//    is rendered with a projection one texel larger on each side (the border holds real depth);
//  * shadow_param = (strength, PBR strength, mapSize, 0); shadow_csm_param = (count, 1/count, blend band,
//    max distance); isystem_userdata.x = constant depth bias, .w = normal-offset bias (world units).
// The atlas texture is "CYS/Shadow/0": texture units with `content_type shadow` (bound at s5 by the WXRender
// material system when SHADOWMAP_TYPE is 1 or 2) sample it.

#include <OgrePrerequisites.h>
#include <OgreAutoParamExternalProvider.h>
#include <OgreMatrix4.h>
#include <OgreString.h>
#include <OgreVector3.h>
#include <OgreVector4.h>

namespace WX
{
    const size_t CYS_SHADOW_MAX_CASCADES = 4;

    struct CYSShadowCascade
    {
        Ogre::Real splitNear;           ///< camera view-depth range of this cascade's frustum slice
        Ogre::Real splitFar;
        Ogre::Vector3 centre;           ///< world centre of the covered region (after texel snapping)
        Ogre::Real halfWidth;           ///< light-space half extents of the region receivers use (tile interior)
        Ogre::Real halfHeight;
        Ogre::Real texelWidth;          ///< world units per shadow texel
        Ogre::Real texelHeight;
        Ogre::Real depthFar;            ///< light-view depth range [0, depthFar] rendered into the tile
        Ogre::Matrix4 proj;             ///< light view -> clip of the whole tile (GL convention, no texel offset)
        Ogre::Vector4 texScale;         ///< light view -> [0,1]^3 of the tile interior (shadow_csm_proj_scale row)
        Ogre::Vector4 texOffset;        ///< (shadow_csm_proj_offset row)
        Ogre::Vector4 atlasRect;        ///< tile in atlas UV (u0, v0, u1, v1)
        size_t casters;                 ///< renderables drawn into the tile in the last update

        CYSShadowCascade(void);
    };

    struct CYSShadowParams
    {
        bool enabled;
        int shaderType;                 ///< SHADOWMAP_TYPE the receivers use (0 none, 1 CSM, 2 simple)
        size_t cascadeCount;
        size_t mapSize;                 ///< tile size in texels
        size_t atlasWidth;
        size_t atlasHeight;
        Ogre::String textureName;       ///< "CYS/Shadow/0"
        Ogre::Vector3 lightDirection;   ///< direction the light travels (normalised)
        Ogre::Matrix4 lightView;        ///< shadow_view_matrix
        Ogre::Matrix4 simpleProj;       ///< shadow_proj_matrix (SIMPLE receivers: cascade 0 over the whole tile)
        CYSShadowCascade cascades[CYS_SHADOW_MAX_CASCADES];
        Ogre::Real maxDistance;         ///< shadows fade out over 0.95..1.0 of this distance from the camera
        Ogre::Real constBias;           ///< isystem_userdata.x
        Ogre::Real normalBias;          ///< isystem_userdata.w
        Ogre::Real strength;            ///< shadow_param.x
        Ogre::Real pbrStrength;         ///< shadow_param.y
        Ogre::Real blendBand;           ///< shadow_csm_param.z (unused by B's CalcShadow.inc, used by CYSShadowLib)
        int pcfRadius;                  ///< CYSShadowLib.inc softness (B's CalcShadow.inc is a fixed 3x3)
        unsigned long frame;            ///< update counter

        // Packed exactly like the auto constants (filled by pack()).
        Ogre::Vector4 shadowParam;      ///< shadow_param
        Ogre::Vector4 csmParam;         ///< shadow_csm_param
        Ogre::Matrix4 csmProjScale;     ///< shadow_csm_proj_scale (row i = cascade i)
        Ogre::Matrix4 csmProjOffset;    ///< shadow_csm_proj_offset

        CYSShadowParams(void);
        void pack(void);
        /// Fills an OgreMain shadow block (all four valid bits).
        void fill(Ogre::ShadowParamBlock& block) const;
    };

    /// Receives the per-frame parameters (the OgreMain provider below, or a test hook).
    class CYSShadowParamSink
    {
    public:
        virtual ~CYSShadowParamSink() {}
        virtual void applyShadowParams(const CYSShadowParams& params) = 0;
    };

    /** Default sink: an Ogre::AutoParamExternalProvider registered with Ogre::Root. OgreMain asks it for the
        shadow_* and isystem_userdata.x/.w auto constants once per rendered camera; it answers with the
        parameters of the last atlas update. */
    class CYSShadowAutoParamProvider : public CYSShadowParamSink, public Ogre::AutoParamExternalProvider
    {
    public:
        CYSShadowAutoParamProvider(void);
        ~CYSShadowAutoParamProvider();

        /// Ogre::Root::addAutoParamExternalProvider (idempotent; needs Root)
        void registerWithRoot(void);
        void unregisterFromRoot(void);
        bool isRegistered(void) const { return mRegistered; }
        /// Answer nothing (OgreMain keeps its own values) until the next applyShadowParams
        void clear(void) { mHasParams = false; }

        // CYSShadowParamSink
        void applyShadowParams(const CYSShadowParams& params);
        // Ogre::AutoParamExternalProvider
        bool getShadowParams(const Ogre::Camera* camera, Ogre::ShadowParamBlock& out) const;

    private:
        CYSShadowParams mParams;
        bool mHasParams;
        bool mRegistered;
    };
}

#endif // __CYS_SHADOW_PARAMS_H__
