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
#ifndef __AutoParamDataSource_H_
#define __AutoParamDataSource_H_

#include "OgrePrerequisites.h"
#include "OgreCommon.h"
#include "OgreMatrix4.h"
#include "OgreVector4.h"
#include "OgreLight.h"
#include "OgreColourValue.h"
#include "OgreAutoParamExternalProvider.h" // CYS

namespace Ogre {


    /** This utility class is used to hold the information used to generate the matrices
    and other information required to automatically populate GpuProgramParameters.
    @remarks
        This class exercises a lazy-update scheme in order to avoid having to update all
        the information a GpuProgramParameters class could possibly want all the time. 
        It relies on the SceneManager to update it when the base data has changed, and
        will calculate concatenated matrices etc only when required, passing back precalculated
        matrices when they are requested more than once when the underlying information has
        not altered.
    */
    class _OgreExport AutoParamDataSource
    {
    protected:
        mutable Matrix4 mWorldMatrix[256];
        mutable size_t mWorldMatrixCount;
        mutable const Matrix4* mWorldMatrixArray;
        mutable Matrix4 mWorldViewMatrix;
        mutable Matrix4 mViewProjMatrix;
        mutable Matrix4 mWorldViewProjMatrix;
        mutable Matrix4 mInverseWorldMatrix;
        mutable Matrix4 mInverseWorldViewMatrix;
        mutable Matrix4 mInverseViewMatrix;
        mutable Matrix4 mInverseTransposeWorldMatrix;
        mutable Matrix4 mInverseTransposeWorldViewMatrix;
        mutable Vector4 mCameraPositionObjectSpace;
        mutable Matrix4 mTextureViewProjMatrix;
        mutable Matrix4 mViewMatrix;
        mutable Matrix4 mProjectionMatrix;
		mutable Real mDirLightExtrusionDistance;
        mutable Vector4 mCameraPosition;

        mutable bool mWorldMatrixDirty;
        mutable bool mViewMatrixDirty;
        mutable bool mProjMatrixDirty;
        mutable bool mWorldViewMatrixDirty;
        mutable bool mViewProjMatrixDirty;
        mutable bool mWorldViewProjMatrixDirty;
        mutable bool mInverseWorldMatrixDirty;
        mutable bool mInverseWorldViewMatrixDirty;
        mutable bool mInverseViewMatrixDirty;
        mutable bool mInverseTransposeWorldMatrixDirty;
        mutable bool mInverseTransposeWorldViewMatrixDirty;
        mutable bool mCameraPositionObjectSpaceDirty;
        mutable bool mCameraPositionDirty;
        mutable bool mTextureViewProjMatrixDirty;
		mutable ColourValue mAmbientLight;
        mutable ColourValue mFogColour;
        mutable Vector4 mFogParams;
        mutable int mPassNumber;

        const Renderable* mCurrentRenderable;
        const Pass* mCurrentPass;
        const Camera* mCurrentCamera;
        const LightList* mCurrentLightList;
        const Frustum* mCurrentTextureProjector;
        const RenderTarget* mCurrentRenderTarget;
        const Viewport* mCurrentViewport;

        Light mBlankLight;

        // CYS: B/Fairy scene state behind the new auto constants (see OgreGpuProgram.h)
        mutable float mDualQuat[256 * 8];
        mutable bool mDualQuatDirty;
        Vector4 mFogType;
        ColourValue mActLightOne, mActLightTwo, mActAmbient, mPbrAmbient;
        bool mActLightOneSet, mActLightTwoSet, mActAmbientSet, mPbrAmbientSet;
        Vector4 mSkyDomeAmbient;
        Real mBrightness;
        bool mUseLinearColorSpace;
        bool mColorGreaterOne;
        Real mShadowConstBias, mShadowNormalBias;
        Matrix4 mShadowView, mShadowProj, mShadowViewProj;
        Vector4 mShadowParams, mShadowCSMParams;
        Matrix4 mShadowCSMProjScale, mShadowCSMProjOffset;
        Vector3 mWindControl;
        Vector4 mDepthCameraParams;
        int mWeightPerBone;
        // CYS: values pulled from the AutoParamExternalProvider list once per camera; a field
        // overrides the value above only while its valid bit is set
        ShadowParamBlock mExtShadow;
        EnvironmentParamBlock mExtEnv;
        RenderFlagsParamBlock mExtFlags;
        Matrix4 mExtCSMProjScale, mExtCSMProjOffset;
        void _pullExternalParams(void);
    public:
        AutoParamDataSource();
        ~AutoParamDataSource();
        /** Updates the current renderable */
        void setCurrentRenderable(const Renderable* rend);
        /** Updates the world matrices */
        void setWorldMatrices(const Matrix4* m, size_t count);
        /** Updates the current pass */
        void setCurrentPass(const Pass* pass);
        /** Updates the current camera */
        void setCurrentCamera(const Camera* cam);
        /** Sets the light list that should be used */
        void setCurrentLightList(const LightList* ll);
        /** Sets the current texture projector */
        void setTextureProjector(const Frustum* frust);
        /** Sets the current render target */
        void setCurrentRenderTarget(const RenderTarget* target);
        /** Sets the current viewport */
        void setCurrentViewport(const Viewport* viewport);
		/** Sets the shadow extrusion distance to be used for point lights. */
		void setShadowDirLightExtrusionDistance(Real dist);

        const Matrix4& getWorldMatrix(void) const;
        const Matrix4* getWorldMatrixArray(void) const;
        size_t getWorldMatrixCount(void) const;
        const Matrix4& getViewMatrix(void) const;
        const Matrix4& getViewProjectionMatrix(void) const;
        const Matrix4& getProjectionMatrix(void) const;
        const Matrix4& getWorldViewProjMatrix(void) const;
        const Matrix4& getWorldViewMatrix(void) const;
        const Matrix4& getInverseWorldMatrix(void) const;
        const Matrix4& getInverseWorldViewMatrix(void) const;
        const Matrix4& getInverseViewMatrix(void) const;
        const Matrix4& getInverseTransposeWorldMatrix(void) const;
        const Matrix4& getInverseTransposeWorldViewMatrix(void) const;
        const Vector4& getCameraPosition(void) const;
        const Vector4& getCameraPositionObjectSpace(void) const;
        /** Get the light which is 'index'th closest to the current object */
        const Light& getLight(size_t index) const;
		void setAmbientLightColour(const ColourValue& ambient);
		const ColourValue& getAmbientLightColour(void) const;
        const ColourValue& getSurfaceAmbientColour(void) const;
        const ColourValue& getSurfaceDiffuseColour(void) const;
        const ColourValue& getSurfaceSpecularColour(void) const;
        const ColourValue& getSurfaceEmissiveColour(void) const;
        Real getSurfaceShininess(void) const;
        ColourValue getDerivedAmbientLightColour(void) const;
        ColourValue getDerivedSceneColour(void) const;
        void setFog(FogMode mode, const ColourValue& colour, Real expDensity, Real linearStart, Real linearEnd);
        const ColourValue& getFogColour(void) const;
        const Vector4& getFogParams(void) const;
        const Matrix4& getTextureViewProjMatrix(void) const;
        const RenderTarget* getCurrentRenderTarget(void) const;
        const Renderable* getCurrentRenderable(void) const;
		Real getShadowExtrusionDistance(void) const;
		Matrix4 getInverseViewProjMatrix(void) const;
		Matrix4 getInverseTransposeViewProjMatrix() const;
		Matrix4 getTransposeViewProjMatrix() const;
		Matrix4 getTransposeViewMatrix() const;
        Matrix4 getInverseTransposeViewMatrix() const;
		Matrix4 getTransposeProjectionMatrix() const;
		Matrix4 getInverseProjectionMatrix() const;
		Matrix4 getInverseTransposeProjectionMatrix() const;
		Matrix4 getTransposeWorldViewProjMatrix() const;
		Matrix4 getInverseWorldViewProjMatrix() const;
		Matrix4 getInverseTransposeWorldViewProjMatrix() const;
		Matrix4 getTransposeWorldViewMatrix() const;
		Matrix4 getTransposeWorldMatrix() const;
        Real getTime(void) const;
		Real getTime_0_X(Real x) const;
		Real getCosTime_0_X(Real x) const;
		Real getSinTime_0_X(Real x) const;
		Real getTanTime_0_X(Real x) const;
		Vector4 getTime_0_X_packed(Real x) const;
		Real getTime_0_1(Real x) const;
		Real getCosTime_0_1(Real x) const;
		Real getSinTime_0_1(Real x) const;
		Real getTanTime_0_1(Real x) const;
		Vector4 getTime_0_1_packed(Real x) const;
		Real getTime_0_2Pi(Real x) const;
		Real getCosTime_0_2Pi(Real x) const;
		Real getSinTime_0_2Pi(Real x) const;
		Real getTanTime_0_2Pi(Real x) const;
		Vector4 getTime_0_2Pi_packed(Real x) const;
        Real getFrameTime(void) const;
		Real getFPS() const;
		Real getViewportWidth() const;
		Real getViewportHeight() const;
		Real getInverseViewportWidth() const;
		Real getInverseViewportHeight() const;
		Vector3 getViewDirection() const;
		Vector3 getViewSideVector() const;
		Vector3 getViewUpVector() const;
		Real getFOV() const;
		Real getNearClipDistance() const;
		Real getFarClipDistance() const;
        int getPassNumber(void) const;
        void setPassNumber(const int passNumber);
        void incPassNumber(void);

        // CYS: B/Fairy data (names follow B OgreMain's AutoParamDataSource exports) ---------------
        /** Engine-state providers (OgreAutoParamExternalProvider.h), shared by all scene managers;
            asked once per rendered camera. At most 8. */
        static void addExternalProvider(AutoParamExternalProvider* provider);
        static void removeExternalProvider(AutoParamExternalProvider* provider);
        static size_t getExternalProviderCount(void);
        /// Fog mode as weights (none, exp, exp2, linear), updated by setFog
        const Vector4& getFogType(void) const
        { return (mExtEnv.valid & EnvironmentParamBlock::EP_FOG) ? mExtEnv.fogType : mFogType; }
        /// Actor light colours / ambient (EnvKey actor_light_one/two); fall back to lights 0/1 and
        /// the scene ambient until set explicitly. Alpha of the light colours is the intensity.
        void setActLightOneColour(const ColourValue& c) { mActLightOne = c; mActLightOneSet = true; }
        void setActLightTwoColour(const ColourValue& c) { mActLightTwo = c; mActLightTwoSet = true; }
        void setActAmbientLightColour(const ColourValue& c) { mActAmbient = c; mActAmbientSet = true; }
        void setPbrAmbientLightColour(const ColourValue& c) { mPbrAmbient = c; mPbrAmbientSet = true; }
        void resetActorLighting(void) { mActLightOneSet = mActLightTwoSet = mActAmbientSet = mPbrAmbientSet = false; }
        ColourValue getActLightOneColour(void) const;
        ColourValue getActLightTwoColour(void) const;
        ColourValue getActAmbientLightColour(void) const;
        ColourValue getPbrAmbientLightColour(void) const;
        /// surface emissive + surface ambient * actor ambient; alpha = surface diffuse alpha
        ColourValue getActDerivedSceneColour(void) const;
        /// surface emissive + surface ambient * PBR ambient; alpha = surface diffuse alpha
        ColourValue getPbrDerivedSceneColour(void) const;
        void setSkyDomeAmbientColour(const Vector4& c) { mSkyDomeAmbient = c; }
        const Vector4& getSkyDomeAmbientColour(void) const
        { return (mExtEnv.valid & EnvironmentParamBlock::EP_SKYDOME) ? mExtEnv.skyDomeAmbient : mSkyDomeAmbient; }
        void setBrightness(Real b) { mBrightness = b; }
        Real getBrightness(void) const
        { return (mExtFlags.valid & RenderFlagsParamBlock::RF_BRIGHTNESS) ? mExtFlags.brightness : mBrightness; }
        void setUseLinearColorSpace(bool b) { mUseLinearColorSpace = b; }
        bool getUseLinearColorSpace(void) const
        { return (mExtFlags.valid & RenderFlagsParamBlock::RF_COLOUR_SPACE) ? mExtFlags.linearColourSpace != 0 : mUseLinearColorSpace; }
        void setColorGreaterOneEnable(bool b) { mColorGreaterOne = b; }
        bool getColorGreaterOneEnable(void) const
        { return (mExtFlags.valid & RenderFlagsParamBlock::RF_COLOUR_SPACE) ? mExtFlags.colourGreaterOne != 0 : mColorGreaterOne; }
        void setShadowConstBias(Real b) { mShadowConstBias = b; }
        Real getShadowConstBias(void) const
        { return (mExtShadow.valid & ShadowParamBlock::SP_BIAS) ? mExtShadow.constantBias : mShadowConstBias; }
        void setShadowNormalBias(Real b) { mShadowNormalBias = b; }
        Real getShadowNormalBias(void) const
        { return (mExtShadow.valid & ShadowParamBlock::SP_BIAS) ? mExtShadow.normalBias : mShadowNormalBias; }
        void setShadowViewMatrix(const Matrix4& m) { mShadowView = m; }
        void setShadowProjMatrix(const Matrix4& m) { mShadowProj = m; }
        void setShadowViewProjMatrix(const Matrix4& m) { mShadowViewProj = m; }
        const Matrix4& getShadowViewMatrix(void) const
        { return (mExtShadow.valid & ShadowParamBlock::SP_MATRICES) ? mExtShadow.viewMatrix : mShadowView; }
        const Matrix4& getShadowProjMatrix(void) const
        { return (mExtShadow.valid & ShadowParamBlock::SP_MATRICES) ? mExtShadow.projMatrix : mShadowProj; }
        const Matrix4& getShadowViewProjMatrix(void) const
        { return (mExtShadow.valid & ShadowParamBlock::SP_MATRICES) ? mExtShadow.viewProjMatrix : mShadowViewProj; }
        void setShadowParams(const Vector4& v) { mShadowParams = v; }
        const Vector4& getShadowParams(void) const
        { return (mExtShadow.valid & ShadowParamBlock::SP_PARAMS) ? mExtShadow.params : mShadowParams; }
        void setShadowCSMParams(const Vector4& v) { mShadowCSMParams = v; }
        const Vector4& getShadowCSMParams(void) const
        { return (mExtShadow.valid & ShadowParamBlock::SP_CSM) ? mExtShadow.csmParams : mShadowCSMParams; }
        /// 4 rows = per-cascade scale / offset, uploaded raw (row_major in the shaders)
        void setShadowCSMProjScale(const Matrix4& m) { mShadowCSMProjScale = m; }
        void setShadowCSMProjOffset(const Matrix4& m) { mShadowCSMProjOffset = m; }
        const Matrix4& getShadowCSMProjScale(void) const
        { return (mExtShadow.valid & ShadowParamBlock::SP_CSM) ? mExtCSMProjScale : mShadowCSMProjScale; }
        const Matrix4& getShadowCSMProjOffset(void) const
        { return (mExtShadow.valid & ShadowParamBlock::SP_CSM) ? mExtCSMProjOffset : mShadowCSMProjOffset; }
        /// (wind dir x, wind dir z, strength)
        void setWindControl(const Vector3& w) { mWindControl = w; }
        const Vector3& getWindControl(void) const
        { return (mExtEnv.valid & EnvironmentParamBlock::EP_WIND) ? mExtEnv.windControl : mWindControl; }
        void setDepthCameraParams(const Vector4& v) { mDepthCameraParams = v; }
        const Vector4& getDepthCameraParams(void) const
        { return (mExtFlags.valid & RenderFlagsParamBlock::RF_DEPTH_CAMERA) ? mExtFlags.depthCameraParams : mDepthCameraParams; }
        /// Blend weights per vertex of the current render operation (0 when not skinned)
        void setWeightPerBone(int n) { mWeightPerBone = n; }
        int getWeightPerBone(void) const { return mWeightPerBone; }
        /// Alpha reject value of the current pass
        unsigned char getSurfaceAlphaTestValue(void) const;
        /// imodel_userdata.x of the current renderable (0 scene lighting .. 1 actor lighting)
        Real getActorLightingFactor(void) const;
        /// Number of lights in the current light list
        size_t getLightCount(void) const;
        /// Texture transform of texture unit 'unit' of the current pass (identity if absent)
        const Matrix4& getTextureTransformMatrix(size_t unit) const;
        /** 8 floats per world matrix: rotation quaternion (w, x, y, z) and (translation, uniform
            scale) - the encoding ShaderLib/CalcPos.inc Calc_Quat_Skin expects. */
        const float* getWorldDualQuaternionArray(void) const;
    };
}

#endif
