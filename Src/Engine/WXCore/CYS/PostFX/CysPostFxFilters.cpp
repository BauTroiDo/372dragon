




#include "CysPostFxPipeline.h"
#include "CYS/Scene/CYSEnvironment.h"
#include "CYS/Scene/CYSSceneFiles.h"
#include "CYS/Scene/CYSSceneCommon.h"

#include <OgreCamera.h>
#include <OgreViewport.h>
#include <OgreTechnique.h>
#include <OgrePass.h>
#include <OgreTextureUnitState.h>
#include <OgreStringConverter.h>
#include <OgreMath.h>
#include <OgreMatrix4.h>
#include <OgreQuaternion.h>
#include <OgreVector2.h>
#include <OgreMaterialManager.h>    // CYS fx-render: B's NewHDRBloom materials

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>     // CYS-PARITY (L2): getenv

namespace WX
{
    using Ogre::Vector3;
    using Ogre::Vector4;
    using Ogre::StringConverter;
    using CysPostFxUtil::setConst;
    using CysPostFxUtil::fragmentParams;
    using CysPostFxUtil::vertexParams;

    namespace
    {
        Real clampReal(Real v, Real lo, Real hi)
        {
            return v < lo ? lo : (v > hi ? hi : v);
        }

        Real smoothstepReal(Real e0, Real e1, Real x)
        {
            const Real t = clampReal((x - e0) / (e1 - e0), 0.0f, 1.0f);
            return t * t * (3.0f - 2.0f * t);
        }

        bool sceneLoaded(void)
        {
            return !CYSEnvironmentManager::getSingleton().getSceneName().empty();
        }

        Ogre::Pass* firstPass(Ogre::MaterialPtr& mat)
        {
            if (mat.isNull() || mat->getNumTechniques() == 0 || mat->getTechnique(0)->getNumPasses() == 0)
                return 0;
            return mat->getTechnique(0)->getPass(0);
        }
    }

    //=======================================================================
    // Anti-aliasing (B AntiAlias.hlsl, 02 2): FXAA / FXAAQuality / DLAA
    //=======================================================================
    /// CYS-PARITY (L2): CY 3.71 has no anti-aliasing pass; its chain is scene -> copy -> HeightFog -> copy, so a kept
    /// FXAA runs after the height fog (order 115) instead of B's 80. CYS_PARITY_AA_ORDER=0 = B's order.
    static int cysAaOrder(void)
    {
        const char* v = getenv("CYS_PARITY_AA_ORDER");
        return (v && v[0] == '0') ? CYS_ORDER_AA : CYS_ORDER_HEIGHTFOG + 5;
    }


    class CysFXAA : public CysPostFxStage
    {
    public:
        CysFXAA(const String& name, const String& type) : CysPostFxStage(name, type, cysAaOrder()) {}

        String buildChain(CysPostFxBuilder& b, const String& input, const String& free)
        {
            b.quad(free, "CysPostFX/FXAA", 1, input);
            return free;
        }
    };


    class CysFXAAQuality : public CysPostFxStage
    {
    public:
        CysFXAAQuality(const String& name, const String& type) : CysPostFxStage(name, type, cysAaOrder()) {}

        String buildChain(CysPostFxBuilder& b, const String& input, const String& free)
        {
            b.quad(free, "CysPostFX/FXAA/Luma", 1, input);
            b.quad(input, "CysPostFX/FXAA/Quality", 2, free);
            return input;
        }
    };



    class CysDLAA : public CysPostFxStage
    {
    public:
        CysDLAA(const String& name, const String& type) : CysPostFxStage(name, type, cysAaOrder()) {}

        String buildChain(CysPostFxBuilder& b, const String& input, const String& free)
        {
            b.quad(free, "CysPostFX/DLAA/Edge", 1, input);
            b.quad(input, "CysPostFX/DLAA/Blend", 2, free);
            return input;
        }
    };

    //=======================================================================
    // NewHDRBloom
    //=======================================================================
    namespace
    {
        const size_t kLumSizes[5] = { 81, 27, 9, 3, 1 };

        /// CYS fx-render: B OgreMain Math::GammaToLinearSpaceExact (constants 0.04045, 12.92, 0.055, 1.055, 2.4)
        Real gammaToLinearExact(Real v)
        {
            if (v <= 0.04045f)
                return v / 12.92f;
            if (v < 1.0f)
                return std::pow((v + 0.055f) / 1.055f, 2.4f);
            return std::pow(v, 2.2f);
        }

        /// CYS fx-render: B OgreMain Math::GammaToLinearSpace (Vector3), polynomial 0.305306 / 0.682171 / 0.012523
        Real gammaToLinearApprox(Real v)
        {
            return v * (v * (v * 0.305306011f + 0.682171111f) + 0.012522878f);
        }
    }




























    class CysNewHDRBloom : public CysPostFxStage
    {
    public:
        CysNewHDRBloom(const String& name, const String& type)
            : CysPostFxStage(name, type, CYS_ORDER_NEWHDRBLOOM)
            , mIntensity(0.0f)
            , mThreshold(1.0f)
            , mSoftKnee(0.5f)
            , mExposure(0.0f)
            , mUseHDR(true)
            , mUseAutoExposure(true)
            , mBloomColour(Ogre::ColourValue::White)
            , mSampleScale(1.0f)
            , mAdaptationSpeed(1.5f)
            , mKey(0.3f)
            , mCompression(0.693f)
            , mMinLuminance(0.02f)
            , mMaxLuminance(64.0f)
            , mUseSceneFile(true)
            , mHdrShading(true)
            , mClampScene(true)
            , mBuiltBloom(false)
            , mBuiltHdr(false)
            , mBuiltAuto(false)
            , mReset(true)
            , mDt(0.0f)
            , mHasApplied(false)
            , mMode(CysPostFxPipeline::isCinematic() ? "Cinematic" : "B")
            , mBSampleScale(0.0f)
            , mBLinearFP16(false)
            , mBuiltB(false)
            , mLoggedNoB(false)
            , mBThreshold(0.0f, 0.0f, 0.0f, 0.0f)
            , mBLoggedThreshold(-1.0f, -1.0f, -1.0f, -1.0f)
            , mBLoggedColour(-1.0f, -1.0f, -1.0f, -1.0f)
        {
            addParam("Mode", &mMode, true);                 // CYS fx-render: B (client_GL exact) | Cinematic
            addParam("BSampleScale", &mBSampleScale);
            addParam("BLinearFP16", &mBLinearFP16, true);
            addParam("Intensity", &mIntensity);
            addParam("Threshold", &mThreshold);
            addParam("SoftKnee", &mSoftKnee);
            addParam("Exposure", &mExposure);
            addParam("BloomColor", &mBloomColour);
            addParam("UseHDR", &mUseHDR, true);
            addParam("UseAutoExposure", &mUseAutoExposure, true);
            addParam("SampleScale", &mSampleScale);
            addParam("AdaptationSpeed", &mAdaptationSpeed);
            addParam("AutoExposureKey", &mKey);
            addParam("AutoExposureCompression", &mCompression);
            addParam("MinLuminance", &mMinLuminance);
            addParam("MaxLuminance", &mMaxLuminance);
            addParam("UseSceneFile", &mUseSceneFile);
            addParam("HDRShading", &mHdrShading, true);
            addParam("ClampScene", &mClampScene, true);
        }

        String buildChain(CysPostFxBuilder& b, const String& input, const String& free)
        {
            mBuiltB = wantB();                              // CYS fx-render: client_GL's chain (default)
            if (mBuiltB)
                return buildChainB(b, input, free);
            mBuiltHdr = mUseHDR;
            mBuiltAuto = mUseHDR && mUseAutoExposure;
            mBuiltBloom = mIntensity > 0.0f;
            const Ogre::PixelFormat f16 = Ogre::PF_FLOAT16_RGBA;

            // CYS fx-render: B's 8-bit scene_buffer holds [0, 1] only (see ClampScene)
            b.quad(free, (!mBuiltHdr && mClampScene) ? "CysPostFX/HDR/ToLinearClamp" : "CysPostFX/HDR/ToLinear",
                   ID_LINEAR, input);

            String lum;
            if (mBuiltAuto)
            {
                String level[5];
                for (int i = 0; i < 5; ++i)
                {
                    level[i] = b.textureFixed("lum" + StringConverter::toString(kLumSizes[i]), Ogre::PF_FLOAT16_R,
                                              kLumSizes[i], kLumSizes[i]);
                }
                const String adapted = b.textureFixed("adapted", Ogre::PF_FLOAT32_R, 1, 1);
                const String previous = b.textureFixed("adaptedPrev", Ogre::PF_FLOAT32_R, 1, 1);
                b.quad(level[0], "CysPostFX/HDR/LumInit", ID_LUM_INIT, free);
                for (int i = 1; i < 5; ++i)
                    b.quad(level[i], "CysPostFX/HDR/LumDown", ID_LUM_DOWN + i - 1, level[i - 1]);
                b.quad(adapted, "CysPostFX/HDR/LumAdapt", ID_LUM_ADAPT, level[4], previous);
                b.quad(previous, "CysPostFX/Copy", ID_LUM_COPY, adapted);
                lum = adapted;
            }

            String bloom;
            if (mBuiltBloom)
            {
                const String bright = b.texture("bright", f16, 1.0f / 3.0f);
                const String down2 = b.texture("down2", f16, 1.0f / 6.0f);
                const String down1 = b.texture("down1", f16, 1.0f / 12.0f);
                const String down0 = b.texture("down0", f16, 1.0f / 24.0f);
                const String up0 = b.texture("up0", f16, 1.0f / 12.0f);
                const String up1 = b.texture("up1", f16, 1.0f / 6.0f);
                const String up2 = b.texture("up2", f16, 1.0f / 3.0f);
                b.quad(bright, "CysPostFX/Bloom/Brightpass", ID_BRIGHT, free);
                b.quad(down2, "CysPostFX/Bloom/Down", ID_DOWN, bright);
                b.quad(down1, "CysPostFX/Bloom/Down", ID_DOWN + 1, down2);
                b.quad(down0, "CysPostFX/Bloom/Down", ID_DOWN + 2, down1);
                b.quad(up0, "CysPostFX/Bloom/Up", ID_UP, down0, down1);
                b.quad(up1, "CysPostFX/Bloom/Up", ID_UP + 1, up0, down2);
                b.quad(up2, "CysPostFX/Bloom/Up", ID_UP + 2, up1, bright);
                bloom = up2;
            }

            const char* finalMaterial = !mBuiltHdr ? "CysPostFX/HDR/Final"
                : (mBuiltAuto ? "CysPostFX/HDR/FinalHDRAuto" : "CysPostFX/HDR/FinalHDR");
            b.quad(input, finalMaterial, ID_FINAL, free, bloom, lum);
            mReset = true;
            return input;
        }

        void onBuilt(CysPostFxPipeline& pipeline)
        {
            // CYS fx-render: never in mode B (B's scene_buffer is 8-bit gamma)
            CysPostFxPipeline::setHdrShadingRequest(&pipeline, !mBuiltB && mBuiltHdr && mHdrShading);
            mReset = true;
        }

        void onFrame(Real dt)
        {
            mDt = dt;
            if (!mUseSceneFile || !sceneLoaded())
                return;
            CYSEnvironmentManager& em = CYSEnvironmentManager::getSingleton();
            const CYSNewHdrBloomParams& p = em.getEnvironment().sceneFiles.newHdrBloom;
            if (mHasApplied && em.getSceneName() == mAppliedScene && same(p, mApplied))
                return;
            mApplied = p;
            mAppliedScene = em.getSceneName();
            mHasApplied = true;
            applyFile(p);
        }

        void onMaterialRender(Ogre::uint32 id, Ogre::MaterialPtr& mat)
        {
            Ogre::GpuProgramParametersSharedPtr fp = fragmentParams(mat);
            if (mBuiltB)
            {
                renderB(id, fp);
                return;
            }
            if (id == ID_LUM_INIT)
            {
                const Real s = (Real)kLumSizes[0];
                setConst(fp, "dstTexel", Vector4(1.0f / s, 1.0f / s, s, s));
            }
            else if (id >= ID_LUM_DOWN && id < ID_LUM_DOWN + 4)
            {
                const Real s = (Real)kLumSizes[id - ID_LUM_DOWN];
                setConst(fp, "srcTexel", Vector4(1.0f / s, 1.0f / s, s, s));
            }
            else if (id == ID_LUM_ADAPT)
            {
                Real rate = 1.0f;
                if (!mReset && mAdaptationSpeed > 0.0f)
                    rate = 1.0f - std::exp(-std::max(mDt, 0.0f) * mAdaptationSpeed);
                mReset = false;
                const Real lo = std::max(mMinLuminance, 1e-4f);
                setConst(fp, "adaptParams", Vector4(rate, lo, std::max(mMaxLuminance, lo), 0.0f));
            }
            else if (id == ID_BRIGHT)
            {
                // B Bloom.hlsl QuadraticThreshold: curve = (threshold - knee, 2 knee, 0.25 / knee)
                const Real knee = mThreshold * mSoftKnee + 1e-5f;
                setConst(fp, "threshold", Vector4(mThreshold, mThreshold - knee, knee * 2.0f, 0.25f / knee));
            }
            else if (id >= ID_UP && id < ID_UP + 3)
            {
                setConst(fp, "sampleScale", mSampleScale);
            }
            else if (id == ID_FINAL)
            {
                setConst(fp, "bloomColor", Vector4(mBloomColour.r, mBloomColour.g, mBloomColour.b,
                                                   mBuiltBloom ? mIntensity : 0.0f));
                setConst(fp, "exposureParams", Vector4(std::pow(2.0f, mExposure), mKey, mCompression, 0.0f));
            }
        }

    protected:
        bool setCustomParameter(const String& name, const String& value)
        {
            if (CysPostFxUtil::toLowerAscii(name) != "scenefile")
                return false;
            CYSSceneFileParams files;
            CYSScene::loadSceneFileParams(CYSScene::baseName(value), "Scene", files);
            mSceneFile = value;
            mUseSceneFile = false;
            applyFile(files.newHdrBloom);
            return true;
        }

        bool getCustomParameter(const String& name, String& value) const
        {
            if (CysPostFxUtil::toLowerAscii(name) != "scenefile")
                return false;
            value = mSceneFile;
            return true;
        }

        void onParameterChanged(const String& name)
        {
            if (name == "UseHDR" && !mUseHDR)
                mUseAutoExposure = false;           // B: UseHDR off clears UseAutoExposure
            if (name == "UseAutoExposure" && mUseAutoExposure)
                mUseHDR = true;                     // B: auto exposure implies HDR
            if (name == "Intensity" && !mBuiltB && (mIntensity > 0.0f) != mBuiltBloom)
                requestRebuild();                   // the bloom chain is only built for Intensity > 0
            if (name == "UseSceneFile")
                mHasApplied = false;
            mReset = true;
        }

    private:


        enum
        {
            ID_B_LINEAR = 0x3e4,
            ID_B_LUM4 = 0x3e3,      // 0x3e3 .. 0x3df: rt_lum4 .. rt_lum0
            ID_B_BRIGHT = 0x323,
            ID_B_DOWN2 = 0x322,
            ID_B_DOWN1 = 0x321,
            ID_B_DOWN0 = 0x320,
            ID_B_UP0 = 0x2be,
            ID_B_UP1 = 0x2bd,
            ID_B_UP2 = 0x2bc,
            ID_B_FINAL = 500,
            ID_B_FINAL_HDR = 600
        };

        bool wantB(void)
        {
            if (CysPostFxUtil::toLowerAscii(mMode) == "cinematic")
                return false;

            static const char* const kMaterials[] = { "ConvertToLinearSpace", "Bloom/GrayDownScaleLum",
                "Bloom/Downscale3x3", "Bloom/DownsampleBrightpass", "Bloom/Downsample", "Bloom/Upsample",
                "Bloom/FinalPass", "Bloom/FinalPass_HDR", "Bloom/FinalPass_HDR_AutoExposure" };
            for (size_t i = 0; i < sizeof(kMaterials) / sizeof(kMaterials[0]); ++i)
            {
                if (Ogre::MaterialManager::getSingleton().getByName(kMaterials[i]).isNull())
                {
                    if (!mLoggedNoB)
                        CysPostFxUtil::log(String("CysPostFX: NewHDRBloom mode B needs B's material ") + kMaterials[i] +
                                           " (MaterialFolder all.material / std_quad.program); using the cinematic chain");
                    mLoggedNoB = true;
                    return false;
                }
            }
            return true;
        }

        String buildChainB(CysPostFxBuilder& b, const String& input, const String& free)
        {
            mBuiltHdr = mUseHDR;
            mBuiltAuto = mUseHDR && mUseAutoExposure;
            mBuiltBloom = true;
            const Ogre::PixelFormat f16 = Ogre::PF_FLOAT16_RGBA;    // B: PF_FLOAT16_RGB (no 3-channel FP16 in D3D9)
            // B: rt_input -> rt_output, i.e. the free chain target, 8-bit like B's ping-pong buffers
            const String linear = mBLinearFP16 ? b.texture("blinear", f16, 1.0f) : free;
            b.quad(linear, "ConvertToLinearSpace", ID_B_LINEAR, input);

            String lum[5];
            for (int i = 0; i < 5; ++i)
            {
                lum[i] = b.textureFixed("blum" + StringConverter::toString(kLumSizes[i]), Ogre::PF_FLOAT16_R,
                                        kLumSizes[i], kLumSizes[i]);
            }
            b.quad(lum[0], "Bloom/GrayDownScaleLum", ID_B_LUM4, linear);
            for (int i = 1; i < 5; ++i)
                b.quad(lum[i], "Bloom/Downscale3x3", ID_B_LUM4 - i, lum[i - 1]);

            const String bright = b.texture("bbright", f16, 1.0f / 3.0f);
            const String down2 = b.texture("bdown2", f16, 1.0f / 6.0f);
            const String down1 = b.texture("bdown1", f16, 1.0f / 12.0f);
            const String down0 = b.texture("bdown0", f16, 1.0f / 24.0f);
            const String up0 = b.texture("bup0", f16, 1.0f / 12.0f);
            const String up1 = b.texture("bup1", f16, 1.0f / 6.0f);
            const String up2 = b.texture("bup2", f16, 1.0f / 3.0f);
            b.quad(bright, "Bloom/DownsampleBrightpass", ID_B_BRIGHT, linear);
            b.quad(down2, "Bloom/Downsample", ID_B_DOWN2, bright);
            b.quad(down1, "Bloom/Downsample", ID_B_DOWN1, down2);
            b.quad(down0, "Bloom/Downsample", ID_B_DOWN0, down1);
            b.quad(up0, "Bloom/Upsample", ID_B_UP0, down0, down1);
            b.quad(up1, "Bloom/Upsample", ID_B_UP1, up0, down2);
            b.quad(up2, "Bloom/Upsample", ID_B_UP2, up1, bright);

            if (mBuiltAuto)
                b.quad(input, "Bloom/FinalPass_HDR_AutoExposure", ID_B_FINAL_HDR, linear, up2, lum[4]);
            else if (mBuiltHdr)
                b.quad(input, "Bloom/FinalPass_HDR", ID_B_FINAL_HDR, linear, up2);
            else
                b.quad(input, "Bloom/FinalPass", ID_B_FINAL, linear, up2);
            mReset = true;
            return input;
        }

        static bool same4(const Vector4& a, const Vector4& b)
        {
            return a.x == b.x && a.y == b.y && a.z == b.z && a.w == b.w;
        }

        static String str4(const Vector4& v)
        {
            return StringConverter::toString(v.x) + " " + StringConverter::toString(v.y) + " " +
                   StringConverter::toString(v.z) + " " + StringConverter::toString(v.w);
        }


        void renderB(Ogre::uint32 id, const Ogre::GpuProgramParametersSharedPtr& fp)
        {
            if (id == ID_B_BRIGHT)
            {
                const Real t = gammaToLinearExact(mThreshold);
                const Real knee = t * mSoftKnee + 1e-5f;
                mBThreshold = Vector4(t, t - knee, knee * 2.0f, 0.25f / knee);
                setConst(fp, "threshold", mBThreshold);
            }
            else if (id >= ID_B_UP2 && id <= ID_B_UP0)
            {
                setConst(fp, "sampleScale", mBSampleScale);
            }
            else if (id == ID_B_FINAL || id == ID_B_FINAL_HDR)
            {
                const Real weight = std::pow(2.0f, mIntensity / 10.0f) - 1.0f;
                const Vector4 colour(gammaToLinearApprox(mBloomColour.r), gammaToLinearApprox(mBloomColour.g),
                                     gammaToLinearApprox(mBloomColour.b), weight);
                setConst(fp, "bloomColor", colour);
                const Real exposure = std::pow(2.0f, mExposure);
                if (id == ID_B_FINAL_HDR)
                    setConst(fp, "exposure", exposure);
                if (!same4(colour, mBLoggedColour) || !same4(mBThreshold, mBLoggedThreshold))
                {
                    // evidence of the constants B's shaders get (once per change)
                    mBLoggedColour = colour;
                    mBLoggedThreshold = mBThreshold;
                    CysPostFxUtil::log("CysPostFX: NewHDRBloom B: Intensity " + StringConverter::toString(mIntensity) +
                        " Threshold " + StringConverter::toString(mThreshold) + " SoftKnee " +
                        StringConverter::toString(mSoftKnee) + " -> threshold (" + str4(mBThreshold) + "), bloomColor (" +
                        str4(colour) + "), sampleScale " + StringConverter::toString(mBSampleScale) +
                        (id == ID_B_FINAL_HDR ? ", exposure " + StringConverter::toString(exposure) +
                         (mBuiltAuto ? ", auto exposure" : "") : String(", LDR")));
                }
            }
        }

        enum
        {
            ID_LINEAR = 1,
            ID_LUM_INIT = 2,
            ID_LUM_DOWN = 3,    // 3..6
            ID_LUM_ADAPT = 7,
            ID_LUM_COPY = 8,
            ID_BRIGHT = 9,
            ID_DOWN = 10,       // 10..12
            ID_UP = 13,         // 13..15
            ID_FINAL = 16
        };

        static bool same(const CYSNewHdrBloomParams& a, const CYSNewHdrBloomParams& b)
        {
            return a.intensity == b.intensity && a.threshold == b.threshold && a.softKnee == b.softKnee &&
                   a.exposure == b.exposure && a.useHDR == b.useHDR && a.useAutoExposure == b.useAutoExposure &&
                   a.bloomColour == b.bloomColour;
        }

        void applyFile(const CYSNewHdrBloomParams& p)
        {
            const bool structural = p.useHDR != mUseHDR || (p.useHDR && p.useAutoExposure) != mUseAutoExposure ||
                                    (!mBuiltB && (p.intensity > 0.0f) != (mIntensity > 0.0f));
            mIntensity = p.intensity;
            mThreshold = p.threshold;
            mSoftKnee = p.softKnee;
            mExposure = p.exposure;
            mUseHDR = p.useHDR;
            mUseAutoExposure = p.useHDR && p.useAutoExposure;
            mBloomColour = p.bloomColour;
            mReset = true;
            if (structural)
                requestRebuild();
        }

        Real mIntensity, mThreshold, mSoftKnee, mExposure;
        bool mUseHDR, mUseAutoExposure;
        Ogre::ColourValue mBloomColour;
        Real mSampleScale, mAdaptationSpeed, mKey, mCompression, mMinLuminance, mMaxLuminance;
        bool mUseSceneFile, mHdrShading;
        bool mClampScene;
        bool mBuiltBloom, mBuiltHdr, mBuiltAuto;
        bool mReset;
        Real mDt;
        bool mHasApplied;
        CYSNewHdrBloomParams mApplied;
        String mAppliedScene;
        String mSceneFile;
        String mMode;                   ///< CYS fx-render: "B" (client_GL exact, default) or "Cinematic"
        Real mBSampleScale;             ///< mode B: Upsample sampleScale (B's factory field: 0)
        bool mBLinearFP16;              ///< mode B: linear scene in FP16 instead of B's 8-bit chain target
        bool mBuiltB;
        bool mLoggedNoB;
        Vector4 mBThreshold;            ///< mode B: threshold constant of the current frame
        Vector4 mBLoggedThreshold, mBLoggedColour;
    };









    class CysGenSSAO : public CysPostFxStage
    {
    public:
        CysGenSSAO(const String& name, const String& type)
            : CysPostFxStage(name, type, CYS_ORDER_SSAO)
            , mRadius(40.0f)
            , mBias(1.5f)
            , mIntensity(1.0f)
            , mPower(1.5f)
            , mResolution(0.5f)
            , mSensitivity(0.05f)
            , mComposite(true)
            , mCompositeStrength(1.0f)
            , mShowAO(false)
            , mFadeStart(3000.0f)
            , mFadeEnd(6000.0f)
            , mDepthBias(0.0015f)
            , mAoW(1), mAoH(1), mDepthW(1), mDepthH(1)
        {
            addParam("SSAOSamplingRadius", &mRadius);
            addParam("Bias", &mBias);
            addParam("DepthBias", &mDepthBias);
            addParam("FadeStart", &mFadeStart);
            addParam("FadeEnd", &mFadeEnd);
            addParam("Intensity", &mIntensity);
            addParam("Power", &mPower);
            addParam("Resolution", &mResolution, true);
            addParam("DepthSensitivity", &mSensitivity);
            addParam("Composite", &mComposite, true);
            addParam("CompositeStrength", &mCompositeStrength);
            addParam("ShowAO", &mShowAO, true);
        }

        bool needsDepth(void) const { return true; }

        void buildNode(CysPostFxBuilder& b)
        {
            const String depth = CysPostFxBuilder::external(b.getDepthTexture());
            b.beginNode(CysPostFxPipeline::SSAO_TEXTURE, Ogre::PF_FLOAT16_R, clampReal(mResolution, 0.25f, 1.0f));
            const String raw = b.texture("raw", Ogre::PF_FLOAT16_R, 1.0f);
            const String tmp = b.texture("tmp", Ogre::PF_FLOAT16_R, 1.0f);
            b.quad(raw, "CysPostFX/SSAO/Gen", ID_GEN, depth);
            b.quad(tmp, "CysPostFX/SSAO/Blur", ID_BLUR_H, raw, depth);
            b.quad(CysPostFxBuilder::NODE_OUTPUT, "CysPostFX/SSAO/Blur", ID_BLUR_V, tmp, depth);
            b.getSize(raw, mAoW, mAoH);
            b.endNode();
            mDepthW = b.getViewportWidth();
            mDepthH = b.getViewportHeight();
        }

        String buildChain(CysPostFxBuilder& b, const String& input, const String& free)
        {
            if (!mComposite && !mShowAO)
                return input;
            b.quad(free, "CysPostFX/SSAO/Apply", ID_APPLY, input,
                   CysPostFxBuilder::external(CysPostFxPipeline::SSAO_TEXTURE));
            return free;
        }

        void onMaterialRender(Ogre::uint32 id, Ogre::MaterialPtr& mat)
        {
            Ogre::GpuProgramParametersSharedPtr fp = fragmentParams(mat);
            switch (id)
            {
            case ID_GEN:
                {
                    const Vector4 pp = getPipeline()->getProjectionParams();
                    setConst(fp, "projParams", Vector4(pp.x, pp.y, 1.0f / (Real)mDepthW, 1.0f / (Real)mDepthH));
                    setConst(fp, "aoParams", Vector4(mRadius, mBias, getPipeline()->getDepthFarValue() * 0.999f, mIntensity));
                    setConst(fp, "noiseScale", Vector4((Real)mAoW / 4.0f, (Real)mAoH / 4.0f, 0.0f, 0.0f));
                    setConst(fp, "fadeParams", Vector4(mFadeStart, std::max(mFadeEnd, mFadeStart + 1.0f), mDepthBias, 0.0f));
                }
                break;
            case ID_BLUR_H:
                setConst(fp, "blurParams", Vector4(1.0f / (Real)mAoW, 0.0f, mSensitivity, 0.0f));
                break;
            case ID_BLUR_V:
                setConst(fp, "blurParams", Vector4(0.0f, 1.0f / (Real)mAoH, mSensitivity, 0.0f));
                break;
            case ID_APPLY:
                setConst(fp, "applyParams", Vector4(mCompositeStrength, mPower, mShowAO ? 1.0f : 0.0f, 0.0f));
                break;
            default:
                break;
            }
        }

    private:
        enum { ID_GEN = 1, ID_BLUR_H = 2, ID_BLUR_V = 3, ID_APPLY = 4 };

        Real mRadius, mBias, mIntensity, mPower, mResolution, mSensitivity;
        bool mComposite;
        Real mCompositeStrength;
        bool mShowAO;
        Real mFadeStart, mFadeEnd, mDepthBias;
        size_t mAoW, mAoH, mDepthW, mDepthH;
    };






    class CysColorLUT : public CysPostFxStage
    {
    public:
        CysColorLUT(const String& name, const String& type)
            : CysPostFxStage(name, type, CYS_ORDER_COLORLUT)
            , mLut("LUT_00.png")
            , mAmount(1.0f)
        {
            addParam("LUTImage", &mLut, true);
            addParam("destAmount", &mAmount);
        }

        String buildChain(CysPostFxBuilder& b, const String& input, const String& free)
        {
            b.quad(free, "CysPostFX/ColorLUT", 1, input);
            return free;
        }

        void onMaterialSetup(Ogre::uint32 id, Ogre::MaterialPtr& mat)
        {
            Ogre::Pass* p = firstPass(mat);
            if (p && p->getNumTextureUnitStates() > 1 && !mLut.empty())
                p->getTextureUnitState(1)->setTextureName(mLut);
        }

        void onMaterialRender(Ogre::uint32 id, Ogre::MaterialPtr& mat)
        {
            setConst(fragmentParams(mat), "dest_amount", mAmount);
        }

    private:
        String mLut;
        Real mAmount;
    };












    class CysHeightFog : public CysPostFxStage
    {
    public:
        CysHeightFog(const String& name, const String& type)
            : CysPostFxStage(name, type, CYS_ORDER_HEIGHTFOG)
            , mUseEnvironment(true)
            , mAuto(true)
            , mLightDirection(0.35f, -0.75f, -0.55f)
            , mFallbackSaved(false)
            , mPreviousFallback(true)
        {
            addParam("FogColor", &mFog.fogColour);
            addParam("HFogDensity", &mFog.hDensity);
            addParam("HFogHeight", &mFog.hHeight);
            addParam("HFogHeightFalloff", &mFog.hHeightFalloff);
            addParam("HFogPowFactor", &mFog.hPowFactor);
            addParam("DFogDensity", &mFog.dDensity);
            addParam("DFogHeightFalloff", &mFog.dHeightFalloff);
            addParam("DFogStartDistance", &mFog.dStartDistance);
            addParam("InscatteringFactor", &mFog.inscatteringFactor);
            addParam("DirectionalInscatteringColor", &mFog.dirInscatteringColour);
            addParam("UseEnvironment", &mUseEnvironment);
            addParam("LightDirection", &mLightDirection);
            addParam("Auto", &mAuto);
        }

        bool needsDepth(void) const { return true; }
        bool supportsIntzDepth(void) const { return true; }    // CYS-PARITY (L2): PostFilters/HeightFog_DSIntZ

        bool isActive(void) const
        {
            if (!mAuto || !mUseEnvironment || !sceneLoaded())
                return true;
            return CYSEnvironmentManager::getSingleton().getEnvironment().heightFogEnabled;
        }

        String buildChain(CysPostFxBuilder& b, const String& input, const String& free)
        {
            // CYS-PARITY (L2): CY HeightFog_DSIntZ (USE_DSINTZ=1) reads the INTZ scene depth ('content_type dsintz')
            if (CysPostFxPipeline::intzSceneDepth())
                b.quad(free, "CysPostFX/HeightFog_DSIntZ", 1, input);
            else
                b.quad(free, "CysPostFX/HeightFog", 1, input, CysPostFxBuilder::external(b.getDepthTexture()));
            return free;
        }

        void onMaterialSetup(Ogre::uint32 id, Ogre::MaterialPtr& mat)
        {



            Ogre::GpuProgramParametersSharedPtr fp = fragmentParams(mat);
            if (!fp.isNull() && fp->hasNamedConstant("light_direction0"))
                fp->clearAutoConstant(fp->getParamIndex("light_direction0"));
        }

        void onMaterialRender(Ogre::uint32 id, Ogre::MaterialPtr& mat)
        {
            CysPostFxPipeline* pl = getPipeline();
            Ogre::Camera* cam = pl ? pl->getCamera() : 0;
            if (!cam)
                return;
            CYSEnvironmentManager& em = CYSEnvironmentManager::getSingleton();
            const bool fromEnv = mUseEnvironment && sceneLoaded();
            const CYSHeightFogParams& fog = fromEnv ? em.getEnvironment().heightFog : mFog;
            const bool active = fromEnv ? em.getEnvironment().heightFogEnabled : true;

            // B HeightFog_vs: world ray = cWorldVecGen * (clip x, clip y, -1, 0); receiver = eye + linear depth * ray
            const Vector4 pp = pl->getProjectionParams();
            const Ogre::Quaternion q = cam->getDerivedOrientation();
            const Vector3 right = q * Vector3::UNIT_X;
            const Vector3 up = q * Vector3::UNIT_Y;
            const Vector3 back = q * Vector3::UNIT_Z;
            Ogre::Matrix4 m = Ogre::Matrix4::ZERO;
            m[0][0] = right.x * pp.x; m[1][0] = right.y * pp.x; m[2][0] = right.z * pp.x;
            m[0][1] = up.x * pp.y;    m[1][1] = up.y * pp.y;    m[2][1] = up.z * pp.y;
            m[0][2] = back.x;         m[1][2] = back.y;         m[2][2] = back.z;
            setConst(vertexParams(mat), "cWorldVecGen", m);

            Ogre::GpuProgramParametersSharedPtr fp = fragmentParams(mat);
            Vector4 h = fog.getHFogParams();
            if (!active)
                h.x = 0.0f;                         // EnvKey height_fog_enabled = 0: pass-through
            if (h.w <= 0.0f)
                h.w = 1.0f;                         // pow(0, 0) is undefined in the shader
            setConst(fp, "HFogParams", h);
            setConst(fp, "DFogParams", fog.getDFogParams());
            setConst(fp, "FogColorParams", fog.getFogColorParams());
            setConst(fp, "DirectionalInscatteringColor", fog.getDirectionalInscatteringColor());
            setConst(fp, "vfViewPos", cam->getDerivedPosition());
            if (!fp.isNull() && fp->hasNamedConstant("near_clip_distance")) // CYS-PARITY (L2): DSIntZ depth linearisation
            {
                setConst(fp, "near_clip_distance", cam->getNearClipDistance());
                setConst(fp, "far_clip_distance", cam->getFarClipDistance());
            }
            const Vector3 travel = -pl->getSunDirection(-mLightDirection);   // direction the sunlight travels
            setConst(fp, "light_direction0", Vector4(travel.x, travel.y, travel.z, 0.0f));
        }

    protected:
        bool setCustomParameter(const String& name, const String& value)
        {
            if (CysPostFxUtil::toLowerAscii(name) != "scenefile")
                return false;
            CYSSceneFileParams files;
            CYSScene::loadSceneFileParams(CYSScene::baseName(value), "Scene", files);
            mFog = files.heightFog;
            mSceneFile = value;
            mUseEnvironment = false;
            return true;
        }

        bool getCustomParameter(const String& name, String& value) const
        {
            if (CysPostFxUtil::toLowerAscii(name) != "scenefile")
                return false;
            value = mSceneFile;
            return true;
        }

        void onEnabledChanged(bool enabled)
        {
            CYSEnvironmentManager& em = CYSEnvironmentManager::getSingleton();
            if (enabled)
            {
                if (!mFallbackSaved)
                {
                    mPreviousFallback = em.isHeightFogFallbackEnabled();
                    mFallbackSaved = true;
                }
                em.setHeightFogFallbackEnabled(false);
            }
            else if (mFallbackSaved)
            {
                em.setHeightFogFallbackEnabled(mPreviousFallback);
                mFallbackSaved = false;
            }
        }

    private:
        CYSHeightFogParams mFog;
        bool mUseEnvironment;
        bool mAuto;
        Vector3 mLightDirection;
        bool mFallbackSaved;
        bool mPreviousFallback;
        String mSceneFile;
    };









    class CysGodRays : public CysPostFxStage
    {
    public:
        CysGodRays(const String& name, const String& type)
            : CysPostFxStage(name, type, CYS_ORDER_GODRAYS)
            , mDecay(0.98f)
            , mExposure(0.05f)
            , mWeight(1.0f)
            , mSunDirection(Vector3::ZERO)
            , mSunRadius(0.1f)
            , mSkyDepth(0.95f)
            , mBrightThreshold(0.7f)
            , mMaskIntensity(1.0f)
            , mResolution(512)
            , mUseDepth(true)
            , mUseSceneFile(true)
            , mSunUv(0.5f, 0.3f)
            , mFade(0.0f)
            , mAspect(1.0f)
        {
            addParam("Decay", &mDecay);
            addParam("Exposure", &mExposure);
            addParam("Weight", &mWeight);
            addParam("SunDirection", &mSunDirection);
            addParam("SunRadius", &mSunRadius);
            addParam("SkyDepth", &mSkyDepth);
            addParam("BrightThreshold", &mBrightThreshold);
            addParam("MaskIntensity", &mMaskIntensity);
            addParam("Resolution", &mResolution, true);
            addParam("UseDepth", &mUseDepth, true);
            addParam("UseSceneFile", &mUseSceneFile);
        }

        bool needsDepth(void) const { return mUseDepth; }

        String buildChain(CysPostFxBuilder& b, const String& input, const String& free)
        {
            const size_t r = (size_t)std::max(64, std::min(2048, mResolution));
            const String mask = b.textureFixed("mask", Ogre::PF_FLOAT16_RGBA, r, r);
            const String rays = b.textureFixed("rays", Ogre::PF_FLOAT16_RGBA, r, r);
            const String blurH = b.textureFixed("blurH", Ogre::PF_FLOAT16_RGBA, r, r);
            const String blurHV = b.textureFixed("blurHV", Ogre::PF_FLOAT16_RGBA, r, r);
            b.quad(mask, "CysPostFX/GodRays/Mask", ID_MASK, input,
                   mUseDepth ? CysPostFxBuilder::external(b.getDepthTexture()) : String());
            b.quad(rays, "CysPostFX/GodRays/Gen", ID_GEN, mask);
            b.quad(blurH, "CysPostFX/GodRays/BlurH", ID_BLUR_H, rays);
            b.quad(blurHV, "CysPostFX/GodRays/BlurV", ID_BLUR_V, blurH);
            b.quad(free, "CysPostFX/GodRays/Add", ID_ADD, input, blurHV);
            mAspect = (Real)b.getViewportWidth() / (Real)std::max<size_t>(1, b.getViewportHeight());
            return free;
        }

        void onFrame(Real dt)
        {
            if (mUseSceneFile && sceneLoaded())
            {
                const CYSSceneFileParams& f = CYSEnvironmentManager::getSingleton().getEnvironment().sceneFiles;
                if (f.hasGodRays)
                {
                    mDecay = f.godRays.decay;
                    mExposure = f.godRays.exposure;
                    mWeight = f.godRays.weight;
                }
            }
            CysPostFxPipeline* pl = getPipeline();
            Ogre::Camera* cam = pl ? pl->getCamera() : 0;
            mFade = 0.0f;
            if (!cam)
                return;
            const Vector3 sun = (mSunDirection.squaredLength() > 1e-6f) ? mSunDirection.normalisedCopy()
                                                                         : pl->getSunDirection(Vector3(0.3f, 0.5f, -0.8f));
            const Real facing = cam->getDerivedDirection().dotProduct(sun);
            const Real sunDistance = cam->getFarClipDistance() > 0.0f ? cam->getFarClipDistance() * 0.5f : 10000.0f;
            const Vector3 wp = cam->getDerivedPosition() + sun * sunDistance;
            const Ogre::Matrix4 vpm = cam->getProjectionMatrix() * cam->getViewMatrix();
            const Real cx = vpm[0][0] * wp.x + vpm[0][1] * wp.y + vpm[0][2] * wp.z + vpm[0][3];
            const Real cy = vpm[1][0] * wp.x + vpm[1][1] * wp.y + vpm[1][2] * wp.z + vpm[1][3];
            const Real cw = vpm[3][0] * wp.x + vpm[3][1] * wp.y + vpm[3][2] * wp.z + vpm[3][3];
            if (cw <= 1e-5f)
                return;                             // sun behind the camera: no rays (B checks the same)
            const Real x = cx / cw, y = cy / cw;
            mSunUv = Ogre::Vector2(x * 0.5f + 0.5f, 0.5f - y * 0.5f);
            const Real edge = std::max(std::fabs(x), std::fabs(y));
            mFade = smoothstepReal(0.0f, 0.2f, facing) * (1.0f - smoothstepReal(1.0f, 1.6f, edge));
        }

        void onMaterialRender(Ogre::uint32 id, Ogre::MaterialPtr& mat)
        {
            Ogre::GpuProgramParametersSharedPtr fp = fragmentParams(mat);
            switch (id)
            {
            case ID_MASK:
                setConst(fp, "sunParams", Vector4(mSunUv.x, mSunUv.y, mAspect, mSunRadius));
                setConst(fp, "maskParams", Vector4(getPipeline()->getDepthFarValue() * mSkyDepth, mBrightThreshold,
                                                   mUseDepth ? 1.0f : 0.0f, mMaskIntensity));
                break;
            case ID_GEN:
                setConst(fp, "sunPos_decay_exposure", Vector4(mSunUv.x, mSunUv.y, mDecay, mExposure * mFade));
                break;
            case ID_BLUR_H:
            case ID_BLUR_V:
                setConst(fp, "fStrength", mWeight);
                break;
            default:
                break;
            }
        }

    private:
        enum { ID_MASK = 1, ID_GEN = 2, ID_BLUR_H = 3, ID_BLUR_V = 4, ID_ADD = 5 };

        Real mDecay, mExposure, mWeight;
        Vector3 mSunDirection;
        Real mSunRadius, mSkyDepth, mBrightThreshold, mMaskIntensity;
        int mResolution;
        bool mUseDepth, mUseSceneFile;
        Ogre::Vector2 mSunUv;
        Real mFade;
        Real mAspect;
    };







    class CysDoF : public CysPostFxStage
    {
    public:
        CysDoF(const String& name, const String& type)
            : CysPostFxStage(name, type, CYS_ORDER_DOF)
            , mNear(0.3f), mFocal(500.0f), mFar(1000.0f), mMaxBlur(0.3f)
            , mW(1), mBW(1)
        {
            addParam("NearBlurDistance", &mNear);
            addParam("FocalDistance", &mFocal);
            addParam("FarBlurDistance", &mFar);
            addParam("MaxFarBlur", &mMaxBlur);
        }

        bool needsDepth(void) const { return true; }

        String buildChain(CysPostFxBuilder& b, const String& input, const String& free)
        {
            const String blur = b.texture("blur", b.getColourFormat(), 0.5f);
            size_t bh = 1;
            b.getSize(blur, mBW, bh);
            mW = b.getViewportWidth();
            b.quad(blur, "CysPostFX/DoF/Blur", ID_BLUR, input);
            b.quad(free, "CysPostFX/DoF/Combine", ID_COMBINE, input, blur,
                   CysPostFxBuilder::external(b.getDepthTexture()));
            return free;
        }

        void onMaterialRender(Ogre::uint32 id, Ogre::MaterialPtr& mat)
        {
            Ogre::GpuProgramParametersSharedPtr fp = fragmentParams(mat);
            if (id == ID_BLUR)
            {
                setConst(fp, "pixelSize", 1.0f / (Real)mBW);
            }
            else if (id == ID_COMBINE)
            {
                setConst(fp, "pixelSizeScene", 1.0f / (Real)mW);
                setConst(fp, "pixelSizeBlur", 1.0f / (Real)mBW);
                setConst(fp, "dofParams", Vector4(mNear, mFocal, mFar, mMaxBlur));
            }
        }

    protected:
        bool setCustomParameter(const String& name, const String& value)
        {
            if (CysPostFxUtil::toLowerAscii(name) != "dofparams")
                return false;
            float f[4] = { mNear, mFocal, mFar, mMaxBlur };
            std::sscanf(value.c_str(), "%f %f %f %f", &f[0], &f[1], &f[2], &f[3]);
            mNear = f[0];
            mFocal = f[1];
            mFar = f[2];
            mMaxBlur = f[3];
            return true;
        }

        bool getCustomParameter(const String& name, String& value) const
        {
            if (CysPostFxUtil::toLowerAscii(name) != "dofparams")
                return false;
            value = StringConverter::toString(mNear) + " " + StringConverter::toString(mFocal) + " " +
                    StringConverter::toString(mFar) + " " + StringConverter::toString(mMaxBlur);
            return true;
        }

    private:
        enum { ID_BLUR = 1, ID_COMBINE = 2 };

        Real mNear, mFocal, mFar, mMaxBlur;
        size_t mW, mBW;
    };











    class CysComplexBlur : public CysPostFxStage
    {
    public:
        CysComplexBlur(const String& name, const String& type)
            : CysPostFxStage(name, type, CYS_ORDER_COMPLEXBLUR),
              mDistance(24.0f), mUnblured(0.1f), mStrength(0.05f), mLoggedNoMaterial(false)   // material defaults
        {
            addParam("Distance", &mDistance);
            addParam("Unblured", &mUnblured);
            addParam("Strength", &mStrength);
        }

        bool isActive(void) const
        {
            if (!Ogre::MaterialManager::getSingleton().getByName(kMaterial).isNull())
                return true;
            if (!mLoggedNoMaterial)
                CysPostFxUtil::log(String("CysPostFX: ComplexBlur needs the game material ") + kMaterial +
                                   " (MaterialFolder all.material); the stage stays inactive");
            mLoggedNoMaterial = true;
            return false;
        }

        String buildChain(CysPostFxBuilder& b, const String& input, const String& free)
        {
            b.quad(free, kMaterial, ID_BLUR, input);
            return free;
        }

        void onMaterialRender(Ogre::uint32 id, Ogre::MaterialPtr& mat)
        {
            if (id != ID_BLUR)
                return;
            Ogre::GpuProgramParametersSharedPtr fp = fragmentParams(mat);
            setConst(fp, "fDistance", mDistance);
            setConst(fp, "fUnblured", mUnblured);
            setConst(fp, "fStrength", mStrength);
        }

    private:
        enum { ID_BLUR = 1 };
        static const char* const kMaterial;
        Real mDistance, mUnblured, mStrength;
        mutable bool mLoggedNoMaterial;
    };
    const char* const CysComplexBlur::kMaterial = "PostFilters/ComplexBlur";

    //=======================================================================
    // Factories
    //=======================================================================
    PostFilterFactory* getCysFXAAFactory(void)
    {
        static CysPostFxFactory<CysFXAA> f("FXAA");
        return &f;
    }
    PostFilterFactory* getCysFXAAQualityFactory(void)
    {
        static CysPostFxFactory<CysFXAAQuality> f("FXAAQuality");
        return &f;
    }
    PostFilterFactory* getCysDLAAFactory(void)
    {
        static CysPostFxFactory<CysDLAA> f("DLAA");
        return &f;
    }
    PostFilterFactory* getCysNewHDRBloomFactory(void)
    {
        static CysPostFxFactory<CysNewHDRBloom> f("NewHDRBloom");
        return &f;
    }
    PostFilterFactory* getCysGenSSAOFactory(void)
    {
        static CysPostFxFactory<CysGenSSAO> f("GenSSAO");
        return &f;
    }
    PostFilterFactory* getCysColorLUTFactory(void)
    {
        static CysPostFxFactory<CysColorLUT> f("ColorLUT");
        return &f;
    }
    PostFilterFactory* getCysHeightFogFactory(void)
    {
        static CysPostFxFactory<CysHeightFog> f("HeightFog");
        return &f;
    }
    PostFilterFactory* getCysGodRaysFactory(void)
    {
        static CysPostFxFactory<CysGodRays> f("GodRays");
        return &f;
    }
    PostFilterFactory* getCysDoFFactory(void)
    {
        static CysPostFxFactory<CysDoF> f("DoF");
        return &f;
    }
    PostFilterFactory* getCysComplexBlurFactory(void)   // CYS-FX (fx-cy)
    {
        static CysPostFxFactory<CysComplexBlur> f("ComplexBlur");
        return &f;
    }
}
