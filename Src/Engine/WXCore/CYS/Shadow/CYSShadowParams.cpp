// CY-Source (shadow agent): shadow parameters and the OgreMain auto-parameter provider. See CYSShadowParams.h.
#include "CYSShadowParams.h"

#include <OgreRoot.h>

namespace WX
{
    //---------------------------------------------------------------------------------------------------------------
    CYSShadowCascade::CYSShadowCascade(void)
        : splitNear(0)
        , splitFar(0)
        , centre(Ogre::Vector3::ZERO)
        , halfWidth(0)
        , halfHeight(0)
        , texelWidth(0)
        , texelHeight(0)
        , depthFar(0)
        , proj(Ogre::Matrix4::IDENTITY)
        , texScale(0, 0, 0, 0)
        , texOffset(0, 0, 0, 0)
        , atlasRect(0, 0, 0, 0)
        , casters(0)
    {
    }
    //---------------------------------------------------------------------------------------------------------------
    CYSShadowParams::CYSShadowParams(void)
        : enabled(false)
        , shaderType(0)
        , cascadeCount(0)
        , mapSize(0)
        , atlasWidth(0)
        , atlasHeight(0)
        , textureName("CYS/Shadow/0")
        , lightDirection(0, -1, 0)
        , lightView(Ogre::Matrix4::IDENTITY)
        , simpleProj(Ogre::Matrix4::IDENTITY)
        , maxDistance(0)
        , constBias(0)
        , normalBias(0)
        , strength(1)
        , pbrStrength(1)
        , blendBand(0)
        , pcfRadius(1)
        , frame(0)
        , shadowParam(0, 0, 0, 0)
        , csmParam(0, 1, 0, 0)
        , csmProjScale(Ogre::Matrix4::ZERO)
        , csmProjOffset(Ogre::Matrix4::ZERO)
    {
    }
    //---------------------------------------------------------------------------------------------------------------
    void CYSShadowParams::pack(void)
    {
        // Disabled: strength 0 and no cascade to find, so receivers compiled with shadows stay fully lit
        // (CalcShadow.inc: shadowFactor = (1 - s) + shadow * s; the CSM loop runs shadow_csm_param.x times).
        shadowParam = Ogre::Vector4(enabled ? strength : 0.0f, enabled ? pbrStrength : 0.0f, Ogre::Real(mapSize), 0);
        const Ogre::Real count = (enabled && shaderType == 1) ? Ogre::Real(cascadeCount) : 0.0f;
        csmParam = Ogre::Vector4(count, cascadeCount ? 1.0f / Ogre::Real(cascadeCount) : 1.0f, blendBand, maxDistance);
        csmProjScale = Ogre::Matrix4::ZERO;
        csmProjOffset = Ogre::Matrix4::ZERO;
        for (size_t i = 0; i < cascadeCount && i < CYS_SHADOW_MAX_CASCADES; ++i)
        {
            for (int c = 0; c < 4; ++c)
            {
                csmProjScale[i][c] = cascades[i].texScale[c];
                csmProjOffset[i][c] = cascades[i].texOffset[c];
            }
        }
    }
    //---------------------------------------------------------------------------------------------------------------
    void CYSShadowParams::fill(Ogre::ShadowParamBlock& block) const
    {
        block.viewMatrix = lightView;
        block.projMatrix = simpleProj;
        block.viewProjMatrix = simpleProj * lightView;
        block.params = shadowParam;
        block.csmParams = csmParam;
        for (size_t i = 0; i < Ogre::ShadowParamBlock::MAX_CASCADES; ++i)
        {
            block.csmProjScale[i] = Ogre::Vector4(csmProjScale[i][0], csmProjScale[i][1], csmProjScale[i][2],
                                                  csmProjScale[i][3]);
            block.csmProjOffset[i] = Ogre::Vector4(csmProjOffset[i][0], csmProjOffset[i][1], csmProjOffset[i][2],
                                                   csmProjOffset[i][3]);
        }
        block.constantBias = enabled ? constBias : 0.0f;
        block.normalBias = enabled ? normalBias : 0.0f;
        block.valid |= Ogre::ShadowParamBlock::SP_MATRICES | Ogre::ShadowParamBlock::SP_PARAMS |
                       Ogre::ShadowParamBlock::SP_CSM | Ogre::ShadowParamBlock::SP_BIAS;
    }
    //---------------------------------------------------------------------------------------------------------------
    CYSShadowAutoParamProvider::CYSShadowAutoParamProvider(void)
        : mHasParams(false)
        , mRegistered(false)
    {
    }
    //---------------------------------------------------------------------------------------------------------------
    CYSShadowAutoParamProvider::~CYSShadowAutoParamProvider()
    {
        // Root may already be gone at static destruction time; unregisterFromRoot() is called by the owner.
    }
    //---------------------------------------------------------------------------------------------------------------
    void CYSShadowAutoParamProvider::registerWithRoot(void)
    {
        if (mRegistered || !Ogre::Root::getSingletonPtr())
            return;
        Ogre::Root::getSingleton().addAutoParamExternalProvider(this);
        mRegistered = true;
    }
    //---------------------------------------------------------------------------------------------------------------
    void CYSShadowAutoParamProvider::unregisterFromRoot(void)
    {
        if (!mRegistered)
            return;
        if (Ogre::Root::getSingletonPtr())
            Ogre::Root::getSingleton().removeAutoParamExternalProvider(this);
        mRegistered = false;
    }
    //---------------------------------------------------------------------------------------------------------------
    void CYSShadowAutoParamProvider::applyShadowParams(const CYSShadowParams& params)
    {
        mParams = params;
        mHasParams = true;
    }
    //---------------------------------------------------------------------------------------------------------------
    bool CYSShadowAutoParamProvider::getShadowParams(const Ogre::Camera* camera, Ogre::ShadowParamBlock& out) const
    {
        (void)camera; // world-space data: identical for every camera
        if (!mHasParams)
            return false;
        mParams.fill(out);
        return true;
    }
}
