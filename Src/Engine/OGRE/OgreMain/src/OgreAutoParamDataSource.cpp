/*
-----------------------------------------------------------------------------
This source file is part of OGRE
    (Object-oriented Graphics Rendering Engine)
For the latest info, see http://ogre.sourceforge.net/

Copyright (c) 2000-2005 The OGRE Team
Also see acknowledgements in Readme.html

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU Lesser General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 59 Temple
Place - Suite 330, Boston, MA 02111-1307, USA, or go to
http://www.gnu.org/copyleft/lesser.txt.
-----------------------------------------------------------------------------
*/
#include "OgreStableHeaders.h"

#include "OgreAutoParamDataSource.h"
#include "OgreRenderable.h"
#include "OgreCamera.h"
#include "OgreRenderTarget.h"
#include "OgreControllerManager.h"
#include "OgreMath.h"
#include "OgreRoot.h"
#include "OgreRenderSystem.h"
#include "OgrePass.h"             // CYS
#include "OgreTextureUnitState.h" // CYS
#include "OgreMatrix3.h"          // CYS
#include "OgreQuaternion.h"       // CYS
#include "OgreLogManager.h"       // CYS
#include "OgreStringConverter.h"  // CYS
#include "OgreException.h"        // CYS

namespace Ogre {
    const Matrix4 PROJECTIONCLIPSPACE2DTOIMAGESPACE_PERSPECTIVE(
        0.5,    0,    0,  0.5, 
        0,   -0.5,    0,  0.5, 
        0,      0,  0.5,  0.5,
        0,      0,    0,    1);

    //-----------------------------------------------------------------------------
    AutoParamDataSource::AutoParamDataSource()
        : mWorldMatrixDirty(true),
         mViewMatrixDirty(true),
         mProjMatrixDirty(true),
         mWorldViewMatrixDirty(true),
         mViewProjMatrixDirty(true),
         mWorldViewProjMatrixDirty(true),
         mInverseWorldMatrixDirty(true),
         mInverseWorldViewMatrixDirty(true),
         mInverseViewMatrixDirty(true),
         mInverseTransposeWorldMatrixDirty(true),
         mInverseTransposeWorldViewMatrixDirty(true),
         mCameraPositionObjectSpaceDirty(true),
         mCameraPositionDirty(true),
         mTextureViewProjMatrixDirty(true),
         mCurrentRenderable(NULL),
         mCurrentPass(NULL),
         mCurrentCamera(NULL), 
         mCurrentTextureProjector(NULL), 
         mCurrentRenderTarget(NULL),
         mCurrentViewport(NULL)
    {
        mBlankLight.setDiffuseColour(ColourValue::Black);
        mBlankLight.setSpecularColour(ColourValue::Black);
        mBlankLight.setAttenuation(0,1,0,0);

        // CYS: B/Fairy defaults. Values not known from B are neutral and documented in
        // Docs\specs\render\01-materials.md (fog none, no shadows, gamma space, daylight).
        mCurrentLightList = 0;
        mDualQuatDirty = true;
        mFogType = Vector4(1, 0, 0, 0);
        mActLightOne = mActLightTwo = ColourValue::White;
        mActAmbient = mPbrAmbient = ColourValue::Black;
        mActLightOneSet = mActLightTwoSet = mActAmbientSet = mPbrAmbientSet = false;
        mSkyDomeAmbient = Vector4(1, 1, 1, 1);
        mBrightness = 1.0f;   // Model_Emissive_ps shows emissive only when brightness <= 0.4
        mUseLinearColorSpace = false;
        mColorGreaterOne = false;
        mShadowConstBias = 0.0f;
        mShadowNormalBias = 0.0f;
        mShadowView = mShadowProj = mShadowViewProj = Matrix4::IDENTITY;
        mShadowParams = Vector4(0, 0, 0, 0);
        mShadowCSMParams = Vector4(0, 0, 0, 0);
        mShadowCSMProjScale = Matrix4::IDENTITY;
        mShadowCSMProjOffset = Matrix4::ZERO;
        mWindControl = Vector3(1, 0, 16); // default initialiser of wind_control_params (ParamNamedAuto.inc)
        mDepthCameraParams = Vector4(0, 0, 0, 0);
        mWeightPerBone = 0;
        mPassNumber = 0;
        mExtShadow.valid = mExtEnv.valid = mExtFlags.valid = 0; // CYS: nothing from providers yet
        mExtCSMProjScale = Matrix4::IDENTITY;
        mExtCSMProjOffset = Matrix4::ZERO;
    }
    //-----------------------------------------------------------------------------
    AutoParamDataSource::~AutoParamDataSource()
    {
    }
    //-----------------------------------------------------------------------------
    void AutoParamDataSource::setCurrentRenderable(const Renderable* rend)
    {
		mCurrentRenderable = rend;
		mWorldMatrixDirty = true;
        mViewMatrixDirty = true;
        mProjMatrixDirty = true;
		mWorldViewMatrixDirty = true;
        mViewProjMatrixDirty = true;
		mWorldViewProjMatrixDirty = true;
		mInverseWorldMatrixDirty = true;
        mInverseViewMatrixDirty = true;
		mInverseWorldViewMatrixDirty = true;
		mInverseTransposeWorldMatrixDirty = true;
		mInverseTransposeWorldViewMatrixDirty = true;
		mCameraPositionObjectSpaceDirty = true;
        mDualQuatDirty = true; // CYS
    }
    //-----------------------------------------------------------------------------
    void AutoParamDataSource::setCurrentCamera(const Camera* cam)
    {
        mCurrentCamera = cam;
        mViewMatrixDirty = true;
        mProjMatrixDirty = true;
        mWorldViewMatrixDirty = true;
        mViewProjMatrixDirty = true;
        mWorldViewProjMatrixDirty = true;
        mInverseViewMatrixDirty = true;
        mInverseWorldViewMatrixDirty = true;
        mInverseTransposeWorldViewMatrixDirty = true;
        mCameraPositionObjectSpaceDirty = true;
        mCameraPositionDirty = true;
        _pullExternalParams(); // CYS: engine-state providers, once per rendered camera
    }
    //-----------------------------------------------------------------------------
    void AutoParamDataSource::setCurrentLightList(const LightList* ll)
    {
        mCurrentLightList = ll;
    }
    //-----------------------------------------------------------------------------
    void AutoParamDataSource::setWorldMatrices(const Matrix4* m, size_t count)
    {
        mWorldMatrixArray = m;
        mWorldMatrixCount = count;
        mWorldMatrixDirty = false;
        mDualQuatDirty = true; // CYS
    }
    //-----------------------------------------------------------------------------
    const Matrix4& AutoParamDataSource::getWorldMatrix(void) const
    {
        if (mWorldMatrixDirty)
        {
            mWorldMatrixArray = mWorldMatrix;
            mCurrentRenderable->getWorldTransforms(mWorldMatrix);
            mWorldMatrixCount = mCurrentRenderable->getNumWorldTransforms();
            mWorldMatrixDirty = false;
        }
        return mWorldMatrixArray[0];
    }
    //-----------------------------------------------------------------------------
    size_t AutoParamDataSource::getWorldMatrixCount(void) const
    {
        if (mWorldMatrixDirty)
        {
            mWorldMatrixArray = mWorldMatrix;
            mCurrentRenderable->getWorldTransforms(mWorldMatrix);
            mWorldMatrixCount = mCurrentRenderable->getNumWorldTransforms();
            mWorldMatrixDirty = false;
        }
        return mWorldMatrixCount;
    }
    //-----------------------------------------------------------------------------
    const Matrix4* AutoParamDataSource::getWorldMatrixArray(void) const
    {
        if (mWorldMatrixDirty)
        {
            mWorldMatrixArray = mWorldMatrix;
            mCurrentRenderable->getWorldTransforms(mWorldMatrix);
            mWorldMatrixCount = mCurrentRenderable->getNumWorldTransforms();
            mWorldMatrixDirty = false;
        }
        return mWorldMatrixArray;
    }
    //-----------------------------------------------------------------------------
    const Matrix4& AutoParamDataSource::getViewMatrix(void) const
    {
        if (mViewMatrixDirty)
        {
            if (mCurrentRenderable && mCurrentRenderable->useIdentityView())
                mViewMatrix = Matrix4::IDENTITY;
            else
                mViewMatrix = mCurrentCamera->getViewMatrix(true);
            mViewMatrixDirty = false;
        }
        return mViewMatrix;
    }
    //-----------------------------------------------------------------------------
    const Matrix4& AutoParamDataSource::getViewProjectionMatrix(void) const
    {
        if (mViewProjMatrixDirty)
        {
            mViewProjMatrix = getProjectionMatrix() * getViewMatrix();
            mViewProjMatrixDirty = false;
        }
        return mViewProjMatrix;
    }
    //-----------------------------------------------------------------------------
    const Matrix4& AutoParamDataSource::getProjectionMatrix(void) const
    {
        if (mProjMatrixDirty)
        {
            // NB use API-independent projection matrix since GPU programs
            // bypass the API-specific handedness and use right-handed coords
            if (mCurrentRenderable && mCurrentRenderable->useIdentityProjection())
            {
                // Use identity projection matrix, still need to take RS depth into account.
                RenderSystem* rs = Root::getSingleton().getRenderSystem();
                rs->_convertProjectionMatrix(Matrix4::IDENTITY, mProjectionMatrix, true);
            }
            else
            {
                mProjectionMatrix = mCurrentCamera->getProjectionMatrixWithRSDepth();
            }
            if (mCurrentRenderTarget && mCurrentRenderTarget->requiresTextureFlipping())
            {
                // Because we're not using setProjectionMatrix, this needs to be done here
                // Invert transformed y
                mProjectionMatrix[1][0] = -mProjectionMatrix[1][0];
                mProjectionMatrix[1][1] = -mProjectionMatrix[1][1];
                mProjectionMatrix[1][2] = -mProjectionMatrix[1][2];
                mProjectionMatrix[1][3] = -mProjectionMatrix[1][3];
            }
            mProjMatrixDirty = false;
        }
        return mProjectionMatrix;
    }
    //-----------------------------------------------------------------------------
    const Matrix4& AutoParamDataSource::getWorldViewMatrix(void) const
    {
        if (mWorldViewMatrixDirty)
        {
            mWorldViewMatrix = getViewMatrix().concatenateAffine(getWorldMatrix());
            mWorldViewMatrixDirty = false;
        }
        return mWorldViewMatrix;
    }
    //-----------------------------------------------------------------------------
    const Matrix4& AutoParamDataSource::getWorldViewProjMatrix(void) const
    {
        if (mWorldViewProjMatrixDirty)
        {
            mWorldViewProjMatrix = getProjectionMatrix() * getWorldViewMatrix();
            mWorldViewProjMatrixDirty = false;
        }
        return mWorldViewProjMatrix;
    }
    //-----------------------------------------------------------------------------
    const Matrix4& AutoParamDataSource::getInverseWorldMatrix(void) const
    {
        if (mInverseWorldMatrixDirty)
        {
            mInverseWorldMatrix = getWorldMatrix().inverseAffine();
            mInverseWorldMatrixDirty = false;
        }
        return mInverseWorldMatrix;
    }
    //-----------------------------------------------------------------------------
    const Matrix4& AutoParamDataSource::getInverseWorldViewMatrix(void) const
    {
        if (mInverseWorldViewMatrixDirty)
        {
            mInverseWorldViewMatrix = getWorldViewMatrix().inverseAffine();
            mInverseWorldViewMatrixDirty = false;
        }
        return mInverseWorldViewMatrix;
    }
    //-----------------------------------------------------------------------------
    const Matrix4& AutoParamDataSource::getInverseViewMatrix(void) const
    {
        if (mInverseViewMatrixDirty)
        {
            mInverseViewMatrix = getViewMatrix().inverseAffine();
            mInverseViewMatrixDirty = false;
        }
        return mInverseViewMatrix;
    }
    //-----------------------------------------------------------------------------
    const Matrix4& AutoParamDataSource::getInverseTransposeWorldMatrix(void) const
    {
        if (mInverseTransposeWorldMatrixDirty)
        {
            mInverseTransposeWorldMatrix = getInverseWorldMatrix().transpose();
            mInverseTransposeWorldMatrixDirty = false;
        }
        return mInverseTransposeWorldMatrix;
    }
    //-----------------------------------------------------------------------------
    const Matrix4& AutoParamDataSource::getInverseTransposeWorldViewMatrix(void) const
    {
        if (mInverseTransposeWorldViewMatrixDirty)
        {
            mInverseTransposeWorldViewMatrix = getInverseWorldViewMatrix().transpose();
            mInverseTransposeWorldViewMatrixDirty = false;
        }
        return mInverseTransposeWorldViewMatrix;
    }
    //-----------------------------------------------------------------------------
    const Vector4& AutoParamDataSource::getCameraPosition(void) const
    {
        if(mCameraPositionDirty)
        {
            Vector3 vec3 = mCurrentCamera->getDerivedPosition();
            mCameraPosition[0] = vec3[0];
            mCameraPosition[1] = vec3[1];
            mCameraPosition[2] = vec3[2];
            mCameraPosition[3] = 1.0;
            mCameraPositionDirty = false;
        }
        return mCameraPosition;
    }    
    //-----------------------------------------------------------------------------
    const Vector4& AutoParamDataSource::getCameraPositionObjectSpace(void) const
    {
        if (mCameraPositionObjectSpaceDirty)
        {
            mCameraPositionObjectSpace = 
                getInverseWorldMatrix().transformAffine(mCurrentCamera->getDerivedPosition());
            mCameraPositionObjectSpaceDirty = false;
        }
        return mCameraPositionObjectSpace;
    }
    //-----------------------------------------------------------------------------
    const Light& AutoParamDataSource::getLight(size_t index) const
    {
        // If outside light range, return a blank light to ensure zeroised for program
        if (!mCurrentLightList || mCurrentLightList->size() <= index) // CYS: no list before the first light pass
        {
            return mBlankLight;
        }
        else
        {
            return *((*mCurrentLightList)[index]);
        }
    }
    //-----------------------------------------------------------------------------
	void AutoParamDataSource::setAmbientLightColour(const ColourValue& ambient)
	{
		mAmbientLight = ambient;
	}
    //-----------------------------------------------------------------------------
	const ColourValue& AutoParamDataSource::getAmbientLightColour(void) const
	{
		return mAmbientLight;
		
	}
    //-----------------------------------------------------------------------------
    void AutoParamDataSource::setCurrentPass(const Pass* pass)
    {
        mCurrentPass = pass;
    }
    //-----------------------------------------------------------------------------
    const ColourValue& AutoParamDataSource::getSurfaceAmbientColour(void) const
    {
        return mCurrentPass->getAmbient();
    }
    //-----------------------------------------------------------------------------
    const ColourValue& AutoParamDataSource::getSurfaceDiffuseColour(void) const
    {
        return mCurrentPass->getDiffuse();
    }
    //-----------------------------------------------------------------------------
    const ColourValue& AutoParamDataSource::getSurfaceSpecularColour(void) const
    {
        return mCurrentPass->getSpecular();
    }
    //-----------------------------------------------------------------------------
    const ColourValue& AutoParamDataSource::getSurfaceEmissiveColour(void) const
    {
        return mCurrentPass->getSelfIllumination();
    }
    //-----------------------------------------------------------------------------
    Real AutoParamDataSource::getSurfaceShininess(void) const
    {
        return mCurrentPass->getShininess();
    }
    //-----------------------------------------------------------------------------
    ColourValue AutoParamDataSource::getDerivedAmbientLightColour(void) const
    {
        return getAmbientLightColour() * getSurfaceAmbientColour();
    }
    //-----------------------------------------------------------------------------
    ColourValue AutoParamDataSource::getDerivedSceneColour(void) const
    {
        ColourValue result = getDerivedAmbientLightColour() + getSurfaceEmissiveColour();
        result.a = getSurfaceDiffuseColour().a;
        return result;
    }
    //-----------------------------------------------------------------------------
    void AutoParamDataSource::setFog(FogMode mode, const ColourValue& colour,
        Real expDensity, Real linearStart, Real linearEnd)
    {
        // CYS: B also records the mode, as weights for ShaderLib/Fog.inc:
        // f = t0 + t1*exp(-d*density) + t2*exp(-(d*density)^2) + t3*saturate((end-d)/(end-start))
        switch (mode)
        {
        case FOG_EXP:    mFogType = Vector4(0, 1, 0, 0); break;
        case FOG_EXP2:   mFogType = Vector4(0, 0, 1, 0); break;
        case FOG_LINEAR: mFogType = Vector4(0, 0, 0, 1); break;
        default:         mFogType = Vector4(1, 0, 0, 0); break; // FOG_NONE: factor 1 = unfogged
        }
        mFogColour = colour;
        mFogParams.x = expDensity;
        mFogParams.y = linearStart;
        mFogParams.z = linearEnd;
        mFogParams.w = linearEnd != linearStart ? 1 / (linearEnd - linearStart) : 0;
    }
    //-----------------------------------------------------------------------------
    const ColourValue& AutoParamDataSource::getFogColour(void) const
    {
        if (mExtEnv.valid & EnvironmentParamBlock::EP_FOG) // CYS: provider
            return mExtEnv.fogColour;
        return mFogColour;
    }
    //-----------------------------------------------------------------------------
    const Vector4& AutoParamDataSource::getFogParams(void) const
    {
        if (mExtEnv.valid & EnvironmentParamBlock::EP_FOG) // CYS: provider
            return mExtEnv.fogParams;
        return mFogParams;
    }
    //-----------------------------------------------------------------------------
    void AutoParamDataSource::setTextureProjector(const Frustum* frust)
    {
        mCurrentTextureProjector = frust;
        mTextureViewProjMatrixDirty = true;

    }
    //-----------------------------------------------------------------------------
    const Matrix4& AutoParamDataSource::getTextureViewProjMatrix(void) const
    {
        if (mTextureViewProjMatrixDirty)
        {
            mTextureViewProjMatrix = 
                PROJECTIONCLIPSPACE2DTOIMAGESPACE_PERSPECTIVE * 
                mCurrentTextureProjector->getProjectionMatrixWithRSDepth() * 
				mCurrentTextureProjector->getViewMatrix();
            mTextureViewProjMatrixDirty = false;
        }
        return mTextureViewProjMatrix;
    }
    //-----------------------------------------------------------------------------
    void AutoParamDataSource::setCurrentRenderTarget(const RenderTarget* target)
    {
        mCurrentRenderTarget = target;
    }
    //-----------------------------------------------------------------------------
    const RenderTarget* AutoParamDataSource::getCurrentRenderTarget(void) const
    {
        return mCurrentRenderTarget;
    }
    //-----------------------------------------------------------------------------
    void AutoParamDataSource::setCurrentViewport(const Viewport* viewport)
    {
        mCurrentViewport = viewport;
    }
    //-----------------------------------------------------------------------------
	void AutoParamDataSource::setShadowDirLightExtrusionDistance(Real dist)
	{
		mDirLightExtrusionDistance = dist;
	}
    //-----------------------------------------------------------------------------
	Real AutoParamDataSource::getShadowExtrusionDistance(void) const
	{
		const Light& l = getLight(0); // only ever applies to one light at once
		if (l.getType() == Light::LT_DIRECTIONAL)
		{
			// use constant
			return mDirLightExtrusionDistance;
		}
		else
		{
			// Calculate based on object space light distance
			// compared to light attenuation range
			Vector3 objPos = getInverseWorldMatrix().transformAffine(l.getDerivedPosition());
			return l.getAttenuationRange() - objPos.length();
		}
	}
    //-----------------------------------------------------------------------------
    const Renderable* AutoParamDataSource::getCurrentRenderable(void) const
    {
        return mCurrentRenderable;
    }
	//-----------------------------------------------------------------------------
	Matrix4 AutoParamDataSource::getInverseViewProjMatrix(void) const
	{
		return this->getViewProjectionMatrix().inverse();
	}
	//-----------------------------------------------------------------------------
	Matrix4 AutoParamDataSource::getInverseTransposeViewProjMatrix(void) const
	{
		return this->getInverseViewProjMatrix().transpose();
	}
	//-----------------------------------------------------------------------------
	Matrix4 AutoParamDataSource::getTransposeViewProjMatrix(void) const
	{
		return this->getViewProjectionMatrix().transpose();
	}
	//-----------------------------------------------------------------------------
	Matrix4 AutoParamDataSource::getTransposeViewMatrix(void) const
	{
		return this->getViewMatrix().transpose();
	}
	//-----------------------------------------------------------------------------
	Matrix4 AutoParamDataSource::getInverseTransposeViewMatrix(void) const
	{
		return this->getInverseViewMatrix().transpose();
	}
	//-----------------------------------------------------------------------------
	Matrix4 AutoParamDataSource::getTransposeProjectionMatrix(void) const
	{
		return this->getProjectionMatrix().transpose();
	}
	//-----------------------------------------------------------------------------
	Matrix4 AutoParamDataSource::getInverseProjectionMatrix(void) const 
	{
		return this->getProjectionMatrix().inverse();
	}
	//-----------------------------------------------------------------------------
	Matrix4 AutoParamDataSource::getInverseTransposeProjectionMatrix(void) const
	{
		return this->getInverseProjectionMatrix().transpose();
	}
	//-----------------------------------------------------------------------------
	Matrix4 AutoParamDataSource::getTransposeWorldViewProjMatrix(void) const
	{
		return this->getWorldViewProjMatrix().transpose();
	}
	//-----------------------------------------------------------------------------
	Matrix4 AutoParamDataSource::getInverseWorldViewProjMatrix(void) const
	{
		return this->getWorldViewProjMatrix().inverse();
	}
	//-----------------------------------------------------------------------------
	Matrix4 AutoParamDataSource::getInverseTransposeWorldViewProjMatrix(void) const
	{
		return this->getInverseWorldViewProjMatrix().transpose();
	}
	//-----------------------------------------------------------------------------
	Matrix4 AutoParamDataSource::getTransposeWorldViewMatrix(void) const
	{
		return this->getWorldViewMatrix().transpose();
	}
	//-----------------------------------------------------------------------------
	Matrix4 AutoParamDataSource::getTransposeWorldMatrix(void) const
	{
		return this->getWorldMatrix().transpose();
	}
    //-----------------------------------------------------------------------------
    Real AutoParamDataSource::getTime(void) const
    {
        return ControllerManager::getSingleton().getElapsedTime();
    }
	//-----------------------------------------------------------------------------
	Real AutoParamDataSource::getTime_0_X(Real x) const
	{
		return fmod(this->getTime(), x);
	}
	//-----------------------------------------------------------------------------
	Real AutoParamDataSource::getCosTime_0_X(Real x) const
	{ 
		return cos(this->getTime_0_X(x)); 
	}
	//-----------------------------------------------------------------------------
	Real AutoParamDataSource::getSinTime_0_X(Real x) const
	{ 
		return sin(this->getTime_0_X(x)); 
	}
	//-----------------------------------------------------------------------------
	Real AutoParamDataSource::getTanTime_0_X(Real x) const
	{ 
		return tan(this->getTime_0_X(x)); 
	}
	//-----------------------------------------------------------------------------
	Vector4 AutoParamDataSource::getTime_0_X_packed(Real x) const
	{
		Real t = this->getTime_0_X(x);
		return Vector4(t, sin(t), cos(t), tan(t));
	}
	//-----------------------------------------------------------------------------
	Real AutoParamDataSource::getTime_0_1(Real x) const
	{ 
		return this->getTime_0_X(x)/x; 
	}
	//-----------------------------------------------------------------------------
	Real AutoParamDataSource::getCosTime_0_1(Real x) const
	{ 
		return cos(this->getTime_0_1(x)); 
	}
	//-----------------------------------------------------------------------------
	Real AutoParamDataSource::getSinTime_0_1(Real x) const
	{ 
		return sin(this->getTime_0_1(x)); 
	}
	//-----------------------------------------------------------------------------
	Real AutoParamDataSource::getTanTime_0_1(Real x) const
	{ 
		return tan(this->getTime_0_1(x)); 
	}
	//-----------------------------------------------------------------------------
	Vector4 AutoParamDataSource::getTime_0_1_packed(Real x) const
	{
		Real t = this->getTime_0_1(x);
		return Vector4(t, sin(t), cos(t), tan(t));
	}
	//-----------------------------------------------------------------------------
	Real AutoParamDataSource::getTime_0_2Pi(Real x) const
	{ 
		return this->getTime_0_X(x)/x*2*Math::PI; 
	}
	//-----------------------------------------------------------------------------
	Real AutoParamDataSource::getCosTime_0_2Pi(Real x) const
	{ 
		return cos(this->getTime_0_2Pi(x)); 
	}
	//-----------------------------------------------------------------------------
	Real AutoParamDataSource::getSinTime_0_2Pi(Real x) const
	{ 
		return sin(this->getTime_0_2Pi(x)); 
	}
	//-----------------------------------------------------------------------------
	Real AutoParamDataSource::getTanTime_0_2Pi(Real x) const
	{ 
		return tan(this->getTime_0_2Pi(x)); 
	}
	//-----------------------------------------------------------------------------
	Vector4 AutoParamDataSource::getTime_0_2Pi_packed(Real x) const
	{
		Real t = this->getTime_0_2Pi(x);
		return Vector4(t, sin(t), cos(t), tan(t));
	}
	//-----------------------------------------------------------------------------
	Real AutoParamDataSource::getFrameTime(void) const
	{
		return ControllerManager::getSingleton().getFrameTimeSource()->getValue();
	}
	//-----------------------------------------------------------------------------
	Real AutoParamDataSource::getFPS() const
	{
		return mCurrentRenderTarget->getLastFPS();
	}
	//-----------------------------------------------------------------------------
	Real AutoParamDataSource::getViewportWidth() const
	{ 
		return mCurrentViewport->getActualWidth(); 
	}
	//-----------------------------------------------------------------------------
	Real AutoParamDataSource::getViewportHeight() const
	{ 
		return mCurrentViewport->getActualHeight(); 
	}
	//-----------------------------------------------------------------------------
	Real AutoParamDataSource::getInverseViewportWidth() const
	{ 
		return 1.0f/mCurrentViewport->getActualWidth(); 
	}
	//-----------------------------------------------------------------------------
	Real AutoParamDataSource::getInverseViewportHeight() const
	{ 
		return 1.0f/mCurrentViewport->getActualHeight(); 
	}
	//-----------------------------------------------------------------------------
	Vector3 AutoParamDataSource::getViewDirection() const
	{
		return mCurrentCamera->getDerivedDirection();
	}
	//-----------------------------------------------------------------------------
	Vector3 AutoParamDataSource::getViewSideVector() const
	{ 
		return mCurrentCamera->getDerivedRight();
	}
	//-----------------------------------------------------------------------------
	Vector3 AutoParamDataSource::getViewUpVector() const
	{ 
		return mCurrentCamera->getDerivedUp();
	}
	//-----------------------------------------------------------------------------
	Real AutoParamDataSource::getFOV() const
	{ 
		return mCurrentCamera->getFOVy().valueRadians(); 
	}
	//-----------------------------------------------------------------------------
	Real AutoParamDataSource::getNearClipDistance() const
	{ 
		return mCurrentCamera->getNearClipDistance(); 
	}
	//-----------------------------------------------------------------------------
	Real AutoParamDataSource::getFarClipDistance() const
	{ 
		return mCurrentCamera->getFarClipDistance(); 
	}
	//-----------------------------------------------------------------------------
    int AutoParamDataSource::getPassNumber(void) const
    {
        return mPassNumber;
    }
	//-----------------------------------------------------------------------------
    void AutoParamDataSource::setPassNumber(const int passNumber)
    {
        mPassNumber = passNumber;
    }
	//-----------------------------------------------------------------------------
    void AutoParamDataSource::incPassNumber(void)
    {
        ++mPassNumber;
    }
	//-----------------------------------------------------------------------------
    // CYS: B/Fairy data
	//-----------------------------------------------------------------------------
    // CYS: external providers of the engine-state constants (OgreAutoParamExternalProvider.h)
    namespace
    {
        const size_t CYS_MAX_PROVIDERS = 8;
        AutoParamExternalProvider* gCysProviders[CYS_MAX_PROVIDERS] = { 0 };
        size_t gCysProviderCount = 0;
    }
	//-----------------------------------------------------------------------------
    void AutoParamDataSource::addExternalProvider(AutoParamExternalProvider* provider)
    {
        if (!provider)
            return;
        for (size_t i = 0; i < gCysProviderCount; ++i)
            if (gCysProviders[i] == provider)
                return;
        if (gCysProviderCount >= CYS_MAX_PROVIDERS)
            OGRE_EXCEPT(Exception::ERR_INVALIDPARAMS, "at most 8 auto-constant providers",
                "AutoParamDataSource::addExternalProvider");
        gCysProviders[gCysProviderCount++] = provider;
        if (LogManager::getSingletonPtr())
            LogManager::getSingleton().logMessage("CYS: auto-constant provider registered (" +
                StringConverter::toString(gCysProviderCount) + " active)");
    }
	//-----------------------------------------------------------------------------
    void AutoParamDataSource::removeExternalProvider(AutoParamExternalProvider* provider)
    {
        for (size_t i = 0; i < gCysProviderCount; ++i)
        {
            if (gCysProviders[i] != provider)
                continue;
            for (size_t j = i + 1; j < gCysProviderCount; ++j)
                gCysProviders[j - 1] = gCysProviders[j];
            gCysProviders[--gCysProviderCount] = 0;
            return;
        }
    }
	//-----------------------------------------------------------------------------
    size_t AutoParamDataSource::getExternalProviderCount(void)
    {
        return gCysProviderCount;
    }
	//-----------------------------------------------------------------------------
    void AutoParamDataSource::_pullExternalParams(void)
    {
        mExtShadow.valid = mExtEnv.valid = mExtFlags.valid = 0;
        if (gCysProviderCount == 0)
            return;
        // pre-fill with OGRE's own values (SceneManager setters / defaults)
        ShadowParamBlock& s = mExtShadow;
        s.viewMatrix = mShadowView;
        s.projMatrix = mShadowProj;
        s.viewProjMatrix = mShadowViewProj;
        s.params = mShadowParams;
        s.csmParams = mShadowCSMParams;
        for (size_t r = 0; r < ShadowParamBlock::MAX_CASCADES; ++r)
        {
            s.csmProjScale[r] = Vector4(mShadowCSMProjScale[r][0], mShadowCSMProjScale[r][1],
                mShadowCSMProjScale[r][2], mShadowCSMProjScale[r][3]);
            s.csmProjOffset[r] = Vector4(mShadowCSMProjOffset[r][0], mShadowCSMProjOffset[r][1],
                mShadowCSMProjOffset[r][2], mShadowCSMProjOffset[r][3]);
        }
        s.constantBias = mShadowConstBias;
        s.normalBias = mShadowNormalBias;
        EnvironmentParamBlock& e = mExtEnv;
        e.actorLightOne = mActLightOne;
        e.actorLightTwo = mActLightTwo;
        e.actorAmbient = mActAmbientSet ? mActAmbient : mAmbientLight;
        e.pbrAmbient = mPbrAmbientSet ? mPbrAmbient : mAmbientLight;
        e.skyDomeAmbient = mSkyDomeAmbient;
        e.windControl = mWindControl;
        e.fogType = mFogType;
        e.fogColour = mFogColour;
        e.fogParams = mFogParams;
        RenderFlagsParamBlock& f = mExtFlags;
        f.brightness = mBrightness;
        f.linearColourSpace = mUseLinearColorSpace ? 1 : 0;
        f.colourGreaterOne = mColorGreaterOne ? 1 : 0;
        f.depthCameraParams = mDepthCameraParams;
        for (size_t i = 0; i < gCysProviderCount; ++i)
        {
            const AutoParamExternalProvider* p = gCysProviders[i];
            p->getShadowParams(mCurrentCamera, s);
            p->getEnvironmentParams(mCurrentCamera, e);
            p->getRenderFlagsParams(mCurrentCamera, f);
        }
        if (s.valid & ShadowParamBlock::SP_CSM)
        {
            // uploaded raw (row_major float4x4 in ParamNamedAuto.inc): row r = cascade r
            for (size_t r = 0; r < ShadowParamBlock::MAX_CASCADES; ++r)
                for (size_t c = 0; c < 4; ++c)
                {
                    mExtCSMProjScale[r][c] = s.csmProjScale[r][c];
                    mExtCSMProjOffset[r][c] = s.csmProjOffset[r][c];
                }
        }
    }
	//-----------------------------------------------------------------------------
    ColourValue AutoParamDataSource::getActLightOneColour(void) const
    {
        if (mExtEnv.valid & EnvironmentParamBlock::EP_ACTOR_LIGHTS) // provider
            return mExtEnv.actorLightOne;
        if (mActLightOneSet)
            return mActLightOne;
        const Light& l = getLight(0);
        ColourValue c = l.getDiffuseColour();
        c.a = l.getPowerScale();
        return c;
    }
	//-----------------------------------------------------------------------------
    ColourValue AutoParamDataSource::getActLightTwoColour(void) const
    {
        if (mExtEnv.valid & EnvironmentParamBlock::EP_ACTOR_LIGHTS) // CYS: provider
            return mExtEnv.actorLightTwo;
        if (mActLightTwoSet)
            return mActLightTwo;
        const Light& l = getLight(1);
        ColourValue c = l.getDiffuseColour();
        c.a = l.getPowerScale();
        return c;
    }
	//-----------------------------------------------------------------------------
    ColourValue AutoParamDataSource::getActAmbientLightColour(void) const
    {
        if (mExtEnv.valid & EnvironmentParamBlock::EP_ACTOR_AMBIENT) // CYS: provider
            return mExtEnv.actorAmbient;
        return mActAmbientSet ? mActAmbient : mAmbientLight;
    }
	//-----------------------------------------------------------------------------
    ColourValue AutoParamDataSource::getPbrAmbientLightColour(void) const
    {
        if (mExtEnv.valid & EnvironmentParamBlock::EP_PBR_AMBIENT) // CYS: provider
            return mExtEnv.pbrAmbient;
        return mPbrAmbientSet ? mPbrAmbient : mAmbientLight;
    }
	//-----------------------------------------------------------------------------
    ColourValue AutoParamDataSource::getActDerivedSceneColour(void) const
    {
        ColourValue result = getSurfaceAmbientColour() * getActAmbientLightColour() + getSurfaceEmissiveColour();
        result.a = getSurfaceDiffuseColour().a;
        return result;
    }
	//-----------------------------------------------------------------------------
    ColourValue AutoParamDataSource::getPbrDerivedSceneColour(void) const
    {
        ColourValue result = getSurfaceAmbientColour() * getPbrAmbientLightColour() + getSurfaceEmissiveColour();
        result.a = getSurfaceDiffuseColour().a;
        return result;
    }
	//-----------------------------------------------------------------------------
    unsigned char AutoParamDataSource::getSurfaceAlphaTestValue(void) const
    {
        return mCurrentPass ? mCurrentPass->getAlphaRejectValue() : 0;
    }
	//-----------------------------------------------------------------------------
    Real AutoParamDataSource::getActorLightingFactor(void) const
    {
        return mCurrentRenderable ? mCurrentRenderable->getActorLightingFactor() : 0.0f;
    }
	//-----------------------------------------------------------------------------
    size_t AutoParamDataSource::getLightCount(void) const
    {
        return mCurrentLightList ? mCurrentLightList->size() : 0;
    }
	//-----------------------------------------------------------------------------
    const Matrix4& AutoParamDataSource::getTextureTransformMatrix(size_t unit) const
    {
        if (mCurrentPass && unit < mCurrentPass->getNumTextureUnitStates())
            return mCurrentPass->getTextureUnitState(static_cast<unsigned short>(unit))->getTextureTransform();
        return Matrix4::IDENTITY;
    }
	//-----------------------------------------------------------------------------
    const float* AutoParamDataSource::getWorldDualQuaternionArray(void) const
    {
        if (mDualQuatDirty)
        {
            const Matrix4* m = getWorldMatrixArray();
            size_t n = std::min(getWorldMatrixCount(), size_t(256));
            for (size_t i = 0; i < n; ++i)
            {
                Matrix3 m3;
                m[i].extract3x3Matrix(m3);
                // uniform scale = mean column length; B stores it in the 4th float of the dual part
                Real sx = Vector3(m3[0][0], m3[1][0], m3[2][0]).length();
                Real sy = Vector3(m3[0][1], m3[1][1], m3[2][1]).length();
                Real sz = Vector3(m3[0][2], m3[1][2], m3[2][2]).length();
                Real s = (sx + sy + sz) / 3.0f;
                if (s > 1e-8f)
                    m3 = m3 * (1.0f / s);
                Quaternion q;
                q.FromRotationMatrix(m3);
                q.normalise();
                float* d = mDualQuat + i * 8;
                d[0] = q.w; d[1] = q.x; d[2] = q.y; d[3] = q.z;   // shader swizzles .yzwx -> (x,y,z,w)
                d[4] = m[i][0][3]; d[5] = m[i][1][3]; d[6] = m[i][2][3];
                d[7] = s;
            }
            mDualQuatDirty = false;
        }
        return mDualQuat;
    }
	//-----------------------------------------------------------------------------

}

