/*
CYS: Dissolve affector - see WXDissolveAffector.h.
*/
#include "WXDissolveAffector.h"

#include <OgreParticleSystem.h>
#include <OgreParticle.h>
#include <OgreParticleIterator.h>
#include <OgreParticleSystemRenderer.h>
#include <OgreBillboardParticleRenderer.h>
#include <OgreBillboardSet.h>
#include <OgreTechnique.h>
#include <OgrePass.h>
#include <OgreException.h>

#include "OgreExt/OgreMeshParticleVisualData.h"

namespace WX {

    DissolveAffector::CmdTime           DissolveAffector::msTimeCmd[DissolveAffector::NUM_STAGES];
    DissolveAffector::CmdClip           DissolveAffector::msClipCmd[DissolveAffector::NUM_STAGES];
    DissolveAffector::CmdColourA        DissolveAffector::msColourACmd;
    DissolveAffector::CmdColourB        DissolveAffector::msColourBCmd;
    DissolveAffector::CmdParams         DissolveAffector::msParamsCmd;
    DissolveAffector::CmdUVRepeat       DissolveAffector::msUVRepeatCmd;
    DissolveAffector::CmdSoftEdgeWidth  DissolveAffector::msSoftEdgeWidthCmd;

    //-----------------------------------------------------------------------
    DissolveAffector::DissolveAffector(Ogre::ParticleSystem* psys)
        : Ogre::ParticleAffector(psys)
        , mColourA(0.0f, 0.0f, 0.0f, 1.0f)
        , mColourB(1.0f, 1.0f, 1.0f, 1.0f)
        , mParams(0.02f, 0.005f, 0.02f, 0.01f)
        , mSoftEdgeWidth(0.0f)
    {
        mType = "Dissolve";

        for (size_t i = 0; i < NUM_STAGES; ++i)
        {
            mTimes[i] = (i == 0) ? 0.0f : 1.0f;
            mClips[i] = (i == 0) ? 0.0f : 1.0f;
        }
        mUVRepeat.x = mUVRepeat.y = 1.0f;

        if (createParamDictionary("DissolveAffector"))
        {
            addBaseParameters();
            Ogre::ParamDictionary* dict = getParamDictionary();

            for (size_t i = 0; i < NUM_STAGES; ++i)
            {
                const Ogre::String index = Ogre::StringConverter::toString(i);
                msTimeCmd[i].mIndex = i;
                msClipCmd[i].mIndex = i;
                dict->addParameter(Ogre::ParameterDef("time" + index,
                    "stage time in normalised particle age.", Ogre::PT_REAL), &msTimeCmd[i]);
                dict->addParameter(Ogre::ParameterDef("clip" + index,
                    "dissolve threshold at this stage.", Ogre::PT_REAL), &msClipCmd[i]);
            }
            dict->addParameter(Ogre::ParameterDef("colora",
                "dissolve edge colour A.", Ogre::PT_COLOURVALUE), &msColourACmd);
            dict->addParameter(Ogre::ParameterDef("colorb",
                "dissolve edge colour B.", Ogre::PT_COLOURVALUE), &msColourBCmd);
            dict->addParameter(Ogre::ParameterDef("params",
                "four dissolve shader parameters.", Ogre::PT_STRING), &msParamsCmd);
            dict->addParameter(Ogre::ParameterDef("uv_repeat",
                "dissolve noise repeat (u v).", Ogre::PT_STRING), &msUVRepeatCmd);
            dict->addParameter(Ogre::ParameterDef("soft_edge_width",
                "width of the soft dissolve edge.", Ogre::PT_REAL), &msSoftEdgeWidthCmd);
        }
    }
    //-----------------------------------------------------------------------
    Fx::Real DissolveAffector::_clipAt(const Ogre::Particle* p) const
    {
        const Fx::Real t = Fx::normalisedAge(p->timeToLive, p->totalTimeToLive);
        Fx::Real clip = mClips[0];
        Fx::evalStages(mTimes, mClips, NUM_STAGES, t, clip);
        return clip;
    }
    //-----------------------------------------------------------------------
    void DissolveAffector::_applyTo(const Ogre::GpuProgramParametersSharedPtr& params, Fx::Real clip) const
    {
        if (params.isNull())
            return;

        if (params->hasNamedConstant("dissolveClip"))
            params->setNamedConstant("dissolveClip", clip);
        if (params->hasNamedConstant("dissolveColorA"))
            params->setNamedConstant("dissolveColorA", mColourA);
        if (params->hasNamedConstant("dissolveColorB"))
            params->setNamedConstant("dissolveColorB", mColourB);
        if (params->hasNamedConstant("dissolveParams"))
            params->setNamedConstant("dissolveParams", mParams);
        if (params->hasNamedConstant("dissolveUVRepeat"))
            params->setNamedConstant("dissolveUVRepeat", Ogre::Vector4(mUVRepeat.x, mUVRepeat.y, 0.0f, 0.0f));
        if (params->hasNamedConstant("dissolveSoftEdgeWidth"))
            params->setNamedConstant("dissolveSoftEdgeWidth", mSoftEdgeWidth);
        // CY 3.71 programs may declare a dissolve box; no data sets it, B leaves it at zero
        if (params->hasNamedConstant("dissolveBox"))
            params->setNamedConstant("dissolveBox", Ogre::Vector4(0.0f, 0.0f, 0.0f, 0.0f));
    }
    //-----------------------------------------------------------------------
    void DissolveAffector::_apply(const Ogre::MaterialPtr& material, Fx::Real clip) const
    {
        if (material.isNull())
            return;

        try
        {
            Ogre::Material::TechniqueIterator ti = material->getTechniqueIterator();
            while (ti.hasMoreElements())
            {
                Ogre::Technique::PassIterator pi = ti.getNext()->getPassIterator();
                while (pi.hasMoreElements())
                {
                    Ogre::Pass* pass = pi.getNext();
                    const bool vs = pass->hasVertexProgram();
                    const bool fs = pass->hasFragmentProgram();

                    // B: the constants are only pushed to passes whose programs declare dissolveClip
                    const bool declared =
                        (vs && pass->getVertexProgramParameters()->hasNamedConstant("dissolveClip")) ||
                        (fs && pass->getFragmentProgramParameters()->hasNamedConstant("dissolveClip"));
                    if (!declared)
                        continue;

                    if (vs)
                        _applyTo(pass->getVertexProgramParameters(), clip);
                    if (fs)
                        _applyTo(pass->getFragmentProgramParameters(), clip);
                }
            }
        }
        catch (Ogre::Exception& e)
        {
            Fx::logOnce("Dissolve.exception." + material->getName(),
                "Dissolve: material '" + material->getName() + "': " + e.getDescription());
        }
    }
    //-----------------------------------------------------------------------
    void DissolveAffector::_initParticle(Ogre::Particle* pParticle)
    {
        // a recycled mesh particle keeps its cloned material: reset it to the first stage at once
        Ogre::ParticleSystemRenderer* renderer = mParent->getRenderer();
        if (renderer && renderer->getType() == "mesh")
        {
            Ogre::MeshParticleVisualData* vd = static_cast<Ogre::MeshParticleVisualData*>(pParticle->getVisualData());
            if (vd && vd->isInit())
                _apply(vd->getMaterial(), _clipAt(pParticle));
        }
    }
    //-----------------------------------------------------------------------
    void DissolveAffector::_affectParticles(Ogre::ParticleSystem* pSystem, Fx::Real timeElapsed)
    {
        Ogre::ParticleSystemRenderer* renderer = pSystem->getRenderer();
        if (!renderer)
            return;

        const Ogre::String& type = renderer->getType();
        if (type == "mesh")
        {
            Ogre::ParticleIterator it = pSystem->_getIterator();
            while (!it.end())
            {
                Ogre::Particle* p = it.getNext();
                Ogre::MeshParticleVisualData* vd = static_cast<Ogre::MeshParticleVisualData*>(p->getVisualData());
                // the renderer creates the visual (and its material clone) after the affectors ran for new particles
                if (vd && vd->isInit())
                    _apply(vd->getMaterial(), _clipAt(p));
            }
        }
        else if (type == "billboard" || type == "texcoord_billboard")
        {
            bool any = false;
            Fx::Real clip = mClips[0];
            Ogre::ParticleIterator it = pSystem->_getIterator();
            while (!it.end())
            {
                clip = _clipAt(it.getNext());
                any = true;
            }
            if (any)
                _apply(static_cast<Ogre::BillboardParticleRenderer*>(renderer)->getBillboardSet()->getMaterial(), clip);
        }
        else
        {
            Fx::logOnce("Dissolve.renderer=" + type, "Dissolve: renderer '" + type + "' is not supported, ignored");
        }
    }

}
