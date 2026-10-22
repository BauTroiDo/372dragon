





























#ifndef __CYS_MATERIAL_SYSTEM_H__
#define __CYS_MATERIAL_SYSTEM_H__

#include <OgrePrerequisites.h>
#include <OgreFrameListener.h>
#include <OgreMaterialManager.h>
#include <OgreHighLevelGpuProgram.h>
#include <OgreColourValue.h>
#include <OgreVector4.h>

#include <map>
#include <unordered_map>
#include <vector>

namespace CYS
{

    struct InstanceParamInfo
    {
        const char* name;
        int components;    ///< 1..4 (Render.dll type codes 0xb..0xe)
        float defaults[4]; ///< Render.dll default value
    };

    class MaterialSystem : public Ogre::MaterialVariantResolver
    {
    public:
        static MaterialSystem& getSingleton(void);

        /** Installs the variant hook in Ogre::MaterialManager and configures the shader microcode
            cache (call before resource scripts are parsed: they compile programs). cacheDir "" = no
            cache; a file "DISABLED" in it disables the cache as in B. materialTemplatesZip = file whose
            change resets the cache ("" = looked up next to the executable). */
        void install(const Ogre::String& cacheDir, const Ogre::String& materialTemplatesZip);
        void uninstall(void);
        bool isInstalled(void) const { return mInstalled; }

        /// Runtime variants on/off (off = OGRE 0.85 behaviour, for comparisons)
        void setVariantsEnabled(bool on) { mVariantsEnabled = on; }
        bool getVariantsEnabled(void) const { return mVariantsEnabled; }
        /// Quaternion skinning for 75..105 bones per sub-mesh (default on)
        void setQuaternionSkinning(bool on) { mAllowQuatSkin = on; }
        /** Program-less (fixed-function) passes of meshes rendered by the Model_* ubershaders with
            the macros derived from their state (BLEND_OP_0/1, DIFFUSE_2_ENABLE, TEX_EFFECT_0/1,
            SPHEREMAPPING_ENABLE, ALPHATEST_ENABLE, LIGHT_CALC_TYPE, USE_VERTEXCOLOR). Default on. */
        void setFixedFunctionConversion(bool on);
        bool getFixedFunctionConversion(void) const { return mConvertFixedFunction; }
        /** Macro added to every generated variant (SHADOWMAP_TYPE, LUT_ENABLE, ...); affects materials
            resolved afterwards. Empty value removes it. */
        void setGlobalDefine(const Ogre::String& name, const Ogre::String& value);






        void setShadowReceiverLighting(bool on);
        bool getShadowReceiverLighting(void) const { return mShadowReceiverLighting; }

        // Ogre::MaterialVariantResolver
        void resolveEntity(Ogre::Entity* ent);
        Ogre::Technique* resolveTechnique(Ogre::Renderable* rend, Ogre::Technique* tech);
        void forgetMaterial(Ogre::Material* mat); // CYS-PERF-FIX fogvariant

        // Per-instance constants
        static size_t getInstanceParamCount(void);
        static const InstanceParamInfo& getInstanceParam(size_t i);
        static const InstanceParamInfo* findInstanceParam(const Ogre::String& name);
        /** Sets a named constant on this entity only (its materials are cloned once per entity).
            Returns false if none of its programs declares the constant. */
        bool setEntityParam(Ogre::Entity* ent, const Ogre::String& name, const Ogre::Vector4& value);
        /// Drops the per-entity clones and resolves the entity again
        void resetEntityParams(Ogre::Entity* ent);

        /// One-line statistics for logs
        Ogre::String getStats(void) const;

        /// CYS fx-render: per-frame cost of the render-queue hook (calls, average ns per call, state writes
        /// followed from sources since install) and cache sizes, for the performance report.
        Ogre::String getFrameStats(void) const;
        /// Drops the variants whose source material nobody else holds (also done automatically as the caches grow).
        size_t purgeDeadVariants(void);

    private:
        MaterialSystem();

        enum SkinMode { SKIN_NONE = 0, SKIN_LBS = 1, SKIN_QUAT = 2 };
        enum Family { FAMILY_UNKNOWN = 0, FAMILY_MODEL, FAMILY_DEPTH, FAMILY_PARTICLE };
        typedef std::map<Ogre::String, Ogre::String> DefineMap;

        // ---- CYS fx-render: runtime state of the source followed onto the variant ----
        /// The pass state the game changes at run time (fixed-function colours / blending / depth / alpha test).
        struct PassState
        {
            Ogre::ColourValue ambient, diffuse, specular, emissive;
            Ogre::Real shininess;
            int tracking;
            int srcBlend, dstBlend, srcBlendAlpha, dstBlendAlpha;
            bool separateBlend;
            bool depthCheck, depthWrite, colourWrite;
            int depthFunc, alphaFunc, alphaValue, cull, manualCull;
            void read(const Ogre::Pass* p);
            bool operator==(const PassState& o) const;
        };
        struct ConstSync
        {
            size_t src, dst;          ///< real-constant register of the source / variant program parameters
            float last[4];            ///< value last seen on the source
        };
        struct PassSync
        {
            Ogre::Pass* src;
            Ogre::Pass* dst;
            PassState last;           ///< source state last followed
            std::vector<Ogre::String> textures;   ///< source texture names last followed (named units)
            std::vector<ConstSync> fp, vp;        ///< per-instance constants declared by both programs
        };
        struct TechEntry
        {
            Ogre::Technique* result;        ///< technique to render
            Ogre::Technique* syncFrom;      ///< source technique followed (0 = none)
            Ogre::Material* srcMat;         ///< its material (kept alive by the variant entry)
            unsigned short techIndex;
            unsigned long keyHandle;        ///< handle of the key technique's material (address-reuse guard)
            Ogre::Material* owner;          ///< variant material the entry belongs to (0 = no variant)
            bool built;
            unsigned int lastFrame;         ///< frame of the last check (one check per frame for all renderables)
            unsigned int quietChecks;       ///< checks without a change (>= 30: checked every 8th frame)
            std::vector<PassSync> passes;
        };
        /// Frame counter for the once-per-frame check (Root frameStarted).
        class FrameCounter : public Ogre::FrameListener
        {
        public:
            explicit FrameCounter(MaterialSystem& owner) : mOwner(owner) {}
            bool frameStarted(const Ogre::FrameEvent& evt);

        private:
            FrameCounter& operator=(const FrameCounter&);
            MaterialSystem& mOwner;
        };
        struct VariantEntry
        {
            Ogre::MaterialPtr source;
            Ogre::MaterialPtr variant;
        };
        typedef std::unordered_map<Ogre::Technique*, TechEntry> TechniqueCache;
        typedef std::map<Ogre::String, VariantEntry> VariantCache;

        void registerVariantTechniques(const Ogre::MaterialPtr& src, const Ogre::MaterialPtr& variant);
        void buildSync(TechEntry& e);
        void followSource(TechEntry& e);
        void forgetVariant(VariantCache::iterator it, bool removeFromManager);
        void maybePurge(void);

        struct VertexFeatures
        {
            bool tangent;
            bool colour;
            bool mesh; ///< resolved for a mesh (false = billboards / particles / manual objects)
            /// CYS-PARITY (d3d9-trace L6): entity lit as an actor (imodel_userdata.x = 1): the authored programs, no
            /// shadow-receiver promotion, no SHADOWMAP_TYPE / LUT_ENABLE. FACT: CY 3.71 draws every x = 1 model with
            /// the vertex-lit template (light arrays in the VS) and a pixel shader without shadow or LUT constants.
            bool actor;
        };

        Family classify(const Ogre::HighLevelGpuProgramPtr& fp) const;
        bool needsVertexProgram(const Ogre::MaterialPtr& mat) const;
        /// needsVertexProgram, or a fixed-function pass the ubershader takes over (meshes only)
        bool needsVariant(const Ogre::MaterialPtr& mat, bool mesh) const;
        /// fixed-function pass -> Model_* ubershader variant; false = left to fixed function
        bool convertFixedFunction(Ogre::Pass* pass);
        bool needsTangents(const Ogre::MaterialPtr& mat) const;
        Ogre::MaterialPtr getVariantMaterial(const Ogre::MaterialPtr& src, SkinMode mode, const VertexFeatures& vf);
        Ogre::String pickVertexProgram(Ogre::Pass* pass, SkinMode mode, const VertexFeatures& vf);
        Ogre::String getProgramVariant(const Ogre::String& baseName, const DefineMap& extra);
        void applyGlobalDefines(Ogre::Pass* pass);
        static bool actorVariantsEnabled(void); // CYS-PARITY
        static bool alphaTestVariantsEnabled(void); // CYS-PARITY
        /// CYS-SHADOW: the pass's pixel shader is promoted to LIGHT_CALC_TYPE 2 (see setShadowReceiverLighting)
        bool promotesToPixelLighting(const Ogre::HighLevelGpuProgramPtr& fp) const;
        /// CYS-SHADOW: FairyTerrainColorMap pass still compiled without shadows while SHADOWMAP_TYPE is 1 or 2
        bool isTerrainShadowPass(const Ogre::Pass* pass) const;
        /// CYS-LOOK: SHADOWMAP_TYPE 1 or 2 is a global define (the receiver programs are in use)
        bool isReceiverDefineSet(void) const;
        /// CYS-LOOK: receiver pixel shaders get LUT_ENABLE=1 + luttex.png at s4 as in CY (CYS_SHADOW_LUT=0 turns it off)
        bool receiverLutEnabled(void) const;
        /// s4 LUT / s5 shadow map / s12 SSAO units of the Model_* pixel shaders
        void bindEngineSamplers(Ogre::Pass* pass);
        bool ensureTangents(Ogre::Mesh* mesh, Ogre::SubMesh* sub);

        bool mInstalled;
        bool mVariantsEnabled;
        bool mAllowQuatSkin;
        bool mConvertFixedFunction;
        bool mShadowReceiverLighting; // CYS-SHADOW
        bool mBuildingActorVariant;   // CYS-PARITY: getVariantMaterial is building an actor variant
        DefineMap mGlobalDefines;
        VariantCache mMaterialCache;                                ///< "<src>|<state>" -> source + variant
        TechniqueCache mTechniqueCache;                             ///< queued technique -> rendered technique
        /// CYS-PERF-FIX fogvariant: variants dropped by forgetMaterial, kept alive two frames (a render queue of the
        /// current frame may still hold one of their techniques)
        std::vector<std::pair<unsigned int, Ogre::MaterialPtr> > mRetiredVariants;
        size_t mNextPurge;                                          ///< cache sizes that trigger the next purge
        size_t mNextTechniquePurge;
        size_t mStatResolveCalls;
        unsigned long long mStatResolveTicks;                       ///< __rdtsc ticks spent in resolveTechnique
        size_t mStatHitCalls;                                       ///< of which cache hits (steady state)
        unsigned long long mStatHitTicks;
        size_t mStatFollowed;                                       ///< state changes followed source -> variant
        size_t mStatPurged;
        size_t mStatChecks;                                         ///< source checks actually made
        FrameCounter mFrameCounter;
        unsigned int mFrame;                                        ///< frames seen (Root frameStarted)
        bool mFrameEvents;                                          ///< frame events arrive (else check every call)
        bool mFrameListenerAdded;
        std::map<Ogre::Entity*, std::vector<Ogre::MaterialPtr> > mInstanceMaterials;
        std::map<Ogre::String, bool> mLoggedOnce;
        size_t mStatVariantPrograms;
        size_t mStatVariantMaterials;
        size_t mStatEntities;
        size_t mStatTangentSets;
        size_t mStatFallbacks;
        size_t mStatEngineUnits;
        size_t mStatFFPasses;
        size_t mStatDroppedPasses;  // CYS-LOGIN: texture-less passes appended to a shader template
    };
}

#endif
