#ifndef __CYS_POSTFX_STAGE_H__
#define __CYS_POSTFX_STAGE_H__

// CY-Source (post-processing agent, 2026-09-12): base class of the CY-Source post filters (02-postfx.md).
//
// A stage is a WX::PostFilter (so it is created, enabled and parameterised by name through WX::PostFilterManager
// exactly like the 0.85 filters) that does not own an OGRE compositor: CysPostFxPipeline compiles all enabled
// stages of a viewport into ONE compositor, ordered by getOrder() (B's chain order), with two shared ping-pong
// targets. A stage adds its passes with CysPostFxBuilder and pushes its shader constants from the
// compositor-instance listener callbacks, which the pipeline routes by pass identifier.

#include "PostFilter/WXPostFilter.h"
#include "PostFilter/WXPostFilterFactory.h"

#include <OgreMaterial.h>
#include <OgreGpuProgram.h>
#include <OgreColourValue.h>
#include <OgreVector3.h>
#include <OgreVector4.h>
#include <OgreMatrix4.h>

#include <vector>

namespace WX
{
    class CysPostFxPipeline;
    class CysPostFxBuilder;

    /// Chain order (02 1: Floodlighting, Fade, HDR, ComplexBlur, GaussianBlur, HeatHaze, TransSceneEffect, FXAA,
    /// NewHDRBloom, ColorLUT, HeightFog, GodRays). The gameplay filters of B that are not implemented yet would
    /// take 10..70. Every stage accepts the parameter "Order" to move it.
    enum CysPostFxOrder
    {
        CYS_ORDER_SSAO = 5,           ///< AO composite on the raw scene (B applies AO in the lighting shaders)
        CYS_ORDER_COMPLEXBLUR = 40,   ///< CYS-FX (fx-cy): skill ComplexBlur, between HDR and GaussianBlur/FXAA as B
        CYS_ORDER_AA = 80,            ///< FXAA / FXAAQuality / DLAA
        CYS_ORDER_DOF = 85,
        CYS_ORDER_NEWHDRBLOOM = 90,
        CYS_ORDER_COLORLUT = 100,
        CYS_ORDER_HEIGHTFOG = 110,
        CYS_ORDER_GODRAYS = 120,
    };

    class CysPostFxStage : public PostFilter
    {
    public:
        CysPostFxStage(const String& name, const String& type, int order);
        virtual ~CysPostFxStage();

        // ---- WX::PostFilter ----
        const String& getType(void) const { return mType; }
        virtual void setEnabled(bool enable);
        virtual bool getEnabled(void) const { return mEnabled; }
        /// Unknown names throw ERR_INVALIDPARAMS (like the 0.85 filters and B's base setParameter).
        virtual void setParameter(const String& name, const String& value);
        virtual String getParameter(const String& name) const;
        virtual void _init(Ogre::Viewport* vp);
        virtual void _notifyViewportSizeChanged(void);

        // ---- pipeline interface ----
        int getOrder(void) const { return mOrder; }
        void setOrder(int order);
        /// True if the stage reads the depth node (linear view depth, R32F).
        virtual bool needsDepth(void) const { return false; }
        /// CYS-PARITY (L2): true if the stage reads the INTZ scene depth ('content_type dsintz', CY "_DSIntZ"
        /// materials) when CysPostFxPipeline::intzSceneDepth(); the depth node is then not built for it.
        virtual bool supportsIntzDepth(void) const { return false; }
        /// CYS fx-render (2026-09-13): false while the stage is enabled but has nothing to do in this scene
        /// (HeightFog where the environment has no height fog); its passes and the render nodes it needs are then
        /// not built. The pipeline checks it every frame and rebuilds when it changes.
        virtual bool isActive(void) const { return true; }
        /// Passes that run before the scene colour is rendered (render nodes such as GenSSAO).
        virtual void buildNode(CysPostFxBuilder& b) {}
        /// Appends the stage's passes. `input` holds the colour so far, `free` is the other ping-pong target
        /// (free to write). Returns the target that holds the stage's result: `input` or `free`.
        virtual String buildChain(CysPostFxBuilder& b, const String& input, const String& free) = 0;
        virtual void onMaterialSetup(Ogre::uint32 localId, Ogre::MaterialPtr& mat) {}
        virtual void onMaterialRender(Ogre::uint32 localId, Ogre::MaterialPtr& mat) {}
        /// Once per frame (Root frameStarted) while enabled, before a possible rebuild.
        virtual void onFrame(Real dt) {}
        /// After the pipeline compositor containing this stage has been created.
        virtual void onBuilt(CysPostFxPipeline& pipeline) {}

        void getParameterNames(std::vector<String>& names) const;

        // pipeline bookkeeping
        bool _isBroken(void) const { return mBroken; }
        void _setBroken(bool broken) { mBroken = broken; }
        CysPostFxPipeline* getPipeline(void) const { return mPipeline; }

    protected:
        enum ParamType { PT_REAL, PT_BOOL, PT_INT, PT_COLOUR, PT_VECTOR3, PT_VECTOR4, PT_STRING };
        struct Param
        {
            String name;
            ParamType type;
            void* ptr;
            bool rebuild;   ///< a change rebuilds the pipeline (the stage's passes depend on it)
        };

        void addParam(const String& name, Real* value, bool rebuild = false);
        void addParam(const String& name, bool* value, bool rebuild = false);
        void addParam(const String& name, int* value, bool rebuild = false);
        void addParam(const String& name, Ogre::ColourValue* value, bool rebuild = false);
        void addParam(const String& name, Ogre::Vector3* value, bool rebuild = false);
        void addParam(const String& name, Ogre::Vector4* value, bool rebuild = false);
        void addParam(const String& name, String* value, bool rebuild = false);

        /// Parameters that are not plain values (e.g. "SceneFile"): return true when handled.
        virtual bool setCustomParameter(const String& name, const String& value) { return false; }
        virtual bool getCustomParameter(const String& name, String& value) const { return false; }
        /// After a table parameter changed.
        virtual void onParameterChanged(const String& name) {}
        virtual void onEnabledChanged(bool enabled) {}
        void requestRebuild(void);

        String mType;
        int mOrder;
        bool mEnabled;
        bool mBroken;
        CysPostFxPipeline* mPipeline;
        std::vector<Param> mParams;

    private:
        void detach(void);
        const Param* findParam(const String& name) const;
    };

    /// Factory for the WX::PostFilterManager; one static instance per filter type.
    template <class T>
    class CysPostFxFactory : public PostFilterFactory
    {
    public:
        explicit CysPostFxFactory(const char* type) : mType(type) {}
        const String& getType(void) const { return mType; }
        PostFilter* createInstance(const String& name) { return new T(name, mType); }
        void destroyInstance(PostFilter* filter) { delete filter; }
        void _init(void) {}

    private:
        String mType;
    };

    namespace CysPostFxUtil
    {
        /// Parameters of pass 0 of technique 0 (the compositor's local material); null if absent.
        Ogre::GpuProgramParametersSharedPtr fragmentParams(const Ogre::MaterialPtr& mat);
        Ogre::GpuProgramParametersSharedPtr vertexParams(const Ogre::MaterialPtr& mat);
        /// Guarded writes: nothing happens if the program does not declare the constant (OGRE would throw).
        void setConst(const Ogre::GpuProgramParametersSharedPtr& p, const char* name, Real value);
        void setConst(const Ogre::GpuProgramParametersSharedPtr& p, const char* name, const Ogre::Vector3& value);
        void setConst(const Ogre::GpuProgramParametersSharedPtr& p, const char* name, const Ogre::Vector4& value);
        void setConst(const Ogre::GpuProgramParametersSharedPtr& p, const char* name, const Ogre::ColourValue& value);
        void setConst(const Ogre::GpuProgramParametersSharedPtr& p, const char* name, const Ogre::Matrix4& value);
        /// Critical-level log line (kept by hosts that log at LL_LOW).
        void log(const String& message);
        bool parseBool(const String& value, bool def);
        String toLowerAscii(const String& s);
    }
}

#endif // __CYS_POSTFX_STAGE_H__
