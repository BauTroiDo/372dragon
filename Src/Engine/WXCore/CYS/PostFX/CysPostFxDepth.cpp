// CY-Source (post-processing agent, 2026-09-12): CysDepthMaterials - see CysPostFxDepth.h.
#include "CysPostFxDepth.h"
#include "CysPostFxStage.h"
#include "CysPostFx.h"

#include <OgreRenderable.h>
#include <OgreEntity.h>
#include <OgreSubEntity.h>
#include <OgreTechnique.h>
#include <OgrePass.h>
#include <OgreMaterialManager.h>
#include <OgreHighLevelGpuProgram.h>
#include <OgreTextureUnitState.h>
#include <OgreRenderOperation.h>
#include <OgreHardwareVertexBuffer.h>
#include <OgreVertexIndexData.h>
#include <OgreStringConverter.h>

namespace WX
{
    using Ogre::StringConverter;

    namespace
    {
        /// Alpha-tested when the pass rejects by alpha, or when its pixel shader was compiled with
        /// ALPHATEST_ENABLE=1 (B's templates test alpha in the shader, 01 3 P3). The test uses texture unit 0.
        bool isAlphaTested(Ogre::Pass* p, String& texture, unsigned char& ref)
        {
            if (p->getNumTextureUnitStates() == 0)
                return false;
            bool tested = p->getAlphaRejectFunction() != Ogre::CMPF_ALWAYS_PASS;
            ref = tested ? p->getAlphaRejectValue() : (unsigned char)128;
            if (!tested && p->hasFragmentProgram())
            {
                Ogre::HighLevelGpuProgram* hl =
                    dynamic_cast<Ogre::HighLevelGpuProgram*>(p->getFragmentProgram().getPointer());
                if (hl)
                    tested = hl->getParameter("preprocessor_defines").find("ALPHATEST_ENABLE=1") != String::npos;
            }
            if (!tested)
                return false;
            texture = p->getTextureUnitState(0)->getTextureName();
            return !texture.empty();
        }
    }
    //-----------------------------------------------------------------------
    const String& CysDepthMaterials::getSchemeName(void)
    {
        static const String scheme("Depth");
        return scheme;
    }
    //-----------------------------------------------------------------------
    CysDepthMaterials::CysDepthMaterials(void)
        : mWarnedLimit(false)
    {
    }
    //-----------------------------------------------------------------------
    CysDepthMaterials::~CysDepthMaterials()
    {
        // The materials stay in the MaterialManager (group CysPostFX) and are reused by the next pipeline.
    }
    //-----------------------------------------------------------------------
    Ogre::Technique* CysDepthMaterials::choose(Ogre::Renderable* rend)
    {
        Ogre::Technique* t = rend->getTechnique();     // resolved with the active scheme ("Depth")
        if (!t)
            return 0;
        if (t->getSchemeName() == getSchemeName())
            return t;                                   // the material system provides the depth pass

        int weights = 0;
        Ogre::SubEntity* se = dynamic_cast<Ogre::SubEntity*>(rend);
        if (se && se->getParent()->hasSkeleton() && se->getParent()->isHardwareAnimationEnabled())
        {
            // Hardware-skinned: the vertex data is the bind pose with blend indices / weights and the
            // world transforms are the bone matrices; the depth vertex shader must skin as well.
            Ogre::RenderOperation op;
            rend->getRenderOperation(op);
            Ogre::VertexDeclaration* decl = op.vertexData ? op.vertexData->vertexDeclaration : 0;  // 1.2: non-const find
            const Ogre::VertexElement* w = decl ? decl->findElementBySemantic(Ogre::VES_BLEND_WEIGHTS) : 0;
            if (!w || !decl->findElementBySemantic(Ogre::VES_BLEND_INDICES))
                return 0;
            weights = (int)Ogre::VertexElement::getTypeCount(w->getType());
            if (weights < 1 || weights > 4 || rend->getNumWorldTransforms() > MAX_BONES)
                return 0;
        }

        const SourceKey key(t, weights);
        std::map<SourceKey, Ogre::Technique*>::iterator it = mBySource.find(key);
        if (it != mBySource.end())
            return it->second;

        Ogre::Technique* result = 0;
        if (t->getNumPasses() > 0 && !t->isTransparent() && t->isDepthWriteEnabled())
        {
            Ogre::Pass* p = t->getPass(0);
            String texture;
            unsigned char ref = 128;
            const bool tested = isAlphaTested(p, texture, ref);
            result = get(weights, p->getCullingMode() == Ogre::CULL_NONE, tested ? texture : String(), ref);
        }
        mBySource[key] = result;
        return result;
    }
    //-----------------------------------------------------------------------
    Ogre::Technique* CysDepthMaterials::get(int weights, bool noCull, const String& alphaTexture,
                                            unsigned char alphaRef)
    {
        String key = "CysPostFX/DepthMat/W" + StringConverter::toString(weights) + (noCull ? "N" : "C");
        if (!alphaTexture.empty())
            key += "/A" + StringConverter::toString((int)alphaRef) + "/" + alphaTexture;

        std::map<String, Ogre::MaterialPtr>::iterator it = mMaterials.find(key);
        if (it != mMaterials.end())
            return it->second.isNull() ? 0 : it->second->getBestTechnique();

        if (!alphaTexture.empty() && mMaterials.size() >= 4096)
        {
            if (!mWarnedLimit)
                CysPostFxUtil::log("CysPostFX: depth node: 4096 depth materials, alpha test dropped for the rest");
            mWarnedLimit = true;
            return get(weights, noCull, String(), 128);
        }

        Ogre::MaterialManager& mm = Ogre::MaterialManager::getSingleton();
        Ogre::MaterialPtr m = mm.getByName(key);
        if (m.isNull())
        {
            m = mm.create(key, CysPostFx::getResourceGroup());
            if (m->getNumTechniques() == 0)
                m->createTechnique();
            Ogre::Technique* t = m->getTechnique(0);
            if (t->getNumPasses() == 0)
                t->createPass();
            Ogre::Pass* p = t->getPass(0);
            p->setLightingEnabled(false);
            p->setFog(true, Ogre::FOG_NONE);
            p->setCullingMode(noCull ? Ogre::CULL_NONE : Ogre::CULL_CLOCKWISE);
            p->setManualCullingMode(noCull ? Ogre::MANUAL_CULL_NONE : Ogre::MANUAL_CULL_BACK);
            const bool uv = !alphaTexture.empty();
            p->setVertexProgram("CysPostFX/Depth/VS_W" + StringConverter::toString(weights) + (uv ? "_UV" : ""));
            p->setFragmentProgram(uv ? "CysPostFX/Depth/PS_AT" : "CysPostFX/Depth/PS");
            if (uv)
            {
                Ogre::TextureUnitState* tu = p->createTextureUnitState(alphaTexture);
                tu->setTextureFiltering(Ogre::TFO_BILINEAR);
                CysPostFxUtil::setConst(p->getFragmentProgramParameters(), "alphaRef", alphaRef / 255.0f);
            }
            m->load();
        }
        if (m->getNumSupportedTechniques() == 0)
        {
            CysPostFxUtil::log("CysPostFX: depth material " + key + " is not supported (see the program errors above)");
            mMaterials[key].setNull();
            return 0;
        }
        mMaterials[key] = m;
        return m->getBestTechnique();
    }
}
