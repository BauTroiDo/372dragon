// CY-Source (post-processing agent, 2026-09-12): CysPostFxStage - see CysPostFxStage.h.
#include "CysPostFxStage.h"
#include "CysPostFxPipeline.h"

#include <OgreException.h>
#include <OgreStringConverter.h>
#include <OgreLogManager.h>
#include <OgreTechnique.h>
#include <OgrePass.h>

#include <cstdio>

namespace WX
{
    using Ogre::StringConverter;

    CysPostFxStage::CysPostFxStage(const String& name, const String& type, int order)
        : PostFilter(name, type)
        , mType(type)
        , mOrder(order)
        , mEnabled(false)
        , mBroken(false)
        , mPipeline(0)
    {
    }
    //-----------------------------------------------------------------------
    CysPostFxStage::~CysPostFxStage()
    {
        detach();
    }
    //-----------------------------------------------------------------------
    void CysPostFxStage::detach(void)
    {
        if (mPipeline)
        {
            CysPostFxPipeline* p = mPipeline;
            mPipeline = 0;
            p->removeStage(this);
        }
    }
    //-----------------------------------------------------------------------
    void CysPostFxStage::_init(Ogre::Viewport* vp)
    {
        detach();
        mViewport = vp;
        mCompositorInstance = 0;    // no compositor of its own: ~PostFilter must not remove one
        if (vp)
        {
            mPipeline = CysPostFxPipeline::get(vp, true);
            mPipeline->addStage(this);
        }
    }
    //-----------------------------------------------------------------------
    void CysPostFxStage::_notifyViewportSizeChanged(void)
    {
        if (mPipeline)
            mPipeline->markDirty();
    }
    //-----------------------------------------------------------------------
    void CysPostFxStage::setEnabled(bool enable)
    {
        mBroken = false;
        if (enable == mEnabled)
            return;
        mEnabled = enable;
        onEnabledChanged(enable);
        if (mPipeline)
            mPipeline->markDirty();
        CysPostFxUtil::log("CysPostFX: " + mName + (enable ? " enabled" : " disabled"));
    }
    //-----------------------------------------------------------------------
    void CysPostFxStage::setOrder(int order)
    {
        if (order == mOrder)
            return;
        mOrder = order;
        requestRebuild();
    }
    //-----------------------------------------------------------------------
    void CysPostFxStage::requestRebuild(void)
    {
        if (mPipeline && mEnabled)
            mPipeline->markDirty();
    }
    //-----------------------------------------------------------------------
    void CysPostFxStage::addParam(const String& name, Real* value, bool rebuild)
    {
        Param p = { name, PT_REAL, value, rebuild };
        mParams.push_back(p);
    }
    void CysPostFxStage::addParam(const String& name, bool* value, bool rebuild)
    {
        Param p = { name, PT_BOOL, value, rebuild };
        mParams.push_back(p);
    }
    void CysPostFxStage::addParam(const String& name, int* value, bool rebuild)
    {
        Param p = { name, PT_INT, value, rebuild };
        mParams.push_back(p);
    }
    void CysPostFxStage::addParam(const String& name, Ogre::ColourValue* value, bool rebuild)
    {
        Param p = { name, PT_COLOUR, value, rebuild };
        mParams.push_back(p);
    }
    void CysPostFxStage::addParam(const String& name, Ogre::Vector3* value, bool rebuild)
    {
        Param p = { name, PT_VECTOR3, value, rebuild };
        mParams.push_back(p);
    }
    void CysPostFxStage::addParam(const String& name, Ogre::Vector4* value, bool rebuild)
    {
        Param p = { name, PT_VECTOR4, value, rebuild };
        mParams.push_back(p);
    }
    void CysPostFxStage::addParam(const String& name, String* value, bool rebuild)
    {
        Param p = { name, PT_STRING, value, rebuild };
        mParams.push_back(p);
    }
    //-----------------------------------------------------------------------
    const CysPostFxStage::Param* CysPostFxStage::findParam(const String& name) const
    {
        const String key = CysPostFxUtil::toLowerAscii(name);
        for (size_t i = 0; i < mParams.size(); ++i)
        {
            if (CysPostFxUtil::toLowerAscii(mParams[i].name) == key)
                return &mParams[i];
        }
        return 0;
    }
    //-----------------------------------------------------------------------
    void CysPostFxStage::getParameterNames(std::vector<String>& names) const
    {
        names.push_back("Order");
        for (size_t i = 0; i < mParams.size(); ++i)
            names.push_back(mParams[i].name);
    }
    //-----------------------------------------------------------------------
    void CysPostFxStage::setParameter(const String& name, const String& value)
    {
        if (CysPostFxUtil::toLowerAscii(name) == "order")
        {
            setOrder(StringConverter::parseInt(value));
            return;
        }
        const Param* p = findParam(name);
        if (!p)
        {
            if (!setCustomParameter(name, value))
                PostFilter::setParameter(name, value);  // throws ERR_INVALIDPARAMS
            return;
        }

        bool changed = false;
        switch (p->type)
        {
        case PT_REAL:
            {
                Real& d = *static_cast<Real*>(p->ptr);
                const Real v = StringConverter::parseReal(value);
                changed = (d != v);
                d = v;
            }
            break;
        case PT_BOOL:
            {
                bool& d = *static_cast<bool*>(p->ptr);
                const bool v = CysPostFxUtil::parseBool(value, d);
                changed = (d != v);
                d = v;
            }
            break;
        case PT_INT:
            {
                int& d = *static_cast<int*>(p->ptr);
                const int v = StringConverter::parseInt(value);
                changed = (d != v);
                d = v;
            }
            break;
        case PT_COLOUR:
            {
                Ogre::ColourValue& d = *static_cast<Ogre::ColourValue*>(p->ptr);
                const Ogre::ColourValue v = StringConverter::parseColourValue(value);
                changed = (d != v);
                d = v;
            }
            break;
        case PT_VECTOR3:
            {
                Ogre::Vector3& d = *static_cast<Ogre::Vector3*>(p->ptr);
                const Ogre::Vector3 v = StringConverter::parseVector3(value);
                changed = (d != v);
                d = v;
            }
            break;
        case PT_VECTOR4:
            {
                Ogre::Vector4& d = *static_cast<Ogre::Vector4*>(p->ptr);
                float f[4] = { d.x, d.y, d.z, d.w };
                std::sscanf(value.c_str(), "%f %f %f %f", &f[0], &f[1], &f[2], &f[3]);
                const Ogre::Vector4 v(f[0], f[1], f[2], f[3]);
                changed = (d.x != v.x || d.y != v.y || d.z != v.z || d.w != v.w);
                d = v;
            }
            break;
        case PT_STRING:
            {
                String& d = *static_cast<String*>(p->ptr);
                changed = (d != value);
                d = value;
            }
            break;
        }
        if (changed)
        {
            mBroken = false;
            if (p->rebuild)
                requestRebuild();
            onParameterChanged(p->name);
        }
    }
    //-----------------------------------------------------------------------
    String CysPostFxStage::getParameter(const String& name) const
    {
        if (CysPostFxUtil::toLowerAscii(name) == "order")
            return StringConverter::toString(mOrder);
        const Param* p = findParam(name);
        if (!p)
        {
            String v;
            if (getCustomParameter(name, v))
                return v;
            return PostFilter::getParameter(name);      // throws ERR_INVALIDPARAMS
        }
        switch (p->type)
        {
        case PT_REAL:
            return StringConverter::toString(*static_cast<const Real*>(p->ptr));
        case PT_BOOL:
            return StringConverter::toString(*static_cast<const bool*>(p->ptr));
        case PT_INT:
            return StringConverter::toString(*static_cast<const int*>(p->ptr));
        case PT_COLOUR:
            return StringConverter::toString(*static_cast<const Ogre::ColourValue*>(p->ptr));
        case PT_VECTOR3:
            return StringConverter::toString(*static_cast<const Ogre::Vector3*>(p->ptr));
        case PT_VECTOR4:
            {
                const Ogre::Vector4& v = *static_cast<const Ogre::Vector4*>(p->ptr);
                return StringConverter::toString(v.x) + " " + StringConverter::toString(v.y) + " " +
                       StringConverter::toString(v.z) + " " + StringConverter::toString(v.w);
            }
        case PT_STRING:
            return *static_cast<const String*>(p->ptr);
        }
        return String();
    }

    //=======================================================================
    namespace CysPostFxUtil
    {
        namespace
        {
            Ogre::Pass* firstPass(const Ogre::MaterialPtr& mat)
            {
                if (mat.isNull() || mat->getNumTechniques() == 0)
                    return 0;
                Ogre::Technique* t = mat->getTechnique(0);
                return (t && t->getNumPasses() > 0) ? t->getPass(0) : 0;
            }
        }

        Ogre::GpuProgramParametersSharedPtr fragmentParams(const Ogre::MaterialPtr& mat)
        {
            Ogre::Pass* p = firstPass(mat);
            if (p && p->hasFragmentProgram())
                return p->getFragmentProgramParameters();
            return Ogre::GpuProgramParametersSharedPtr();
        }

        Ogre::GpuProgramParametersSharedPtr vertexParams(const Ogre::MaterialPtr& mat)
        {
            Ogre::Pass* p = firstPass(mat);
            if (p && p->hasVertexProgram())
                return p->getVertexProgramParameters();
            return Ogre::GpuProgramParametersSharedPtr();
        }

        void setConst(const Ogre::GpuProgramParametersSharedPtr& p, const char* name, Real value)
        {
            if (!p.isNull() && p->hasNamedConstant(name))
                p->setNamedConstant(name, value);
        }

        void setConst(const Ogre::GpuProgramParametersSharedPtr& p, const char* name, const Ogre::Vector3& value)
        {
            if (!p.isNull() && p->hasNamedConstant(name))
                p->setNamedConstant(name, value);
        }

        void setConst(const Ogre::GpuProgramParametersSharedPtr& p, const char* name, const Ogre::Vector4& value)
        {
            if (!p.isNull() && p->hasNamedConstant(name))
                p->setNamedConstant(name, value);
        }

        void setConst(const Ogre::GpuProgramParametersSharedPtr& p, const char* name, const Ogre::ColourValue& value)
        {
            if (!p.isNull() && p->hasNamedConstant(name))
                p->setNamedConstant(name, value);
        }

        void setConst(const Ogre::GpuProgramParametersSharedPtr& p, const char* name, const Ogre::Matrix4& value)
        {
            if (!p.isNull() && p->hasNamedConstant(name))
                p->setNamedConstant(name, value);
        }

        void log(const String& message)
        {
            if (Ogre::LogManager::getSingletonPtr())
                Ogre::LogManager::getSingleton().logMessage(message, Ogre::LML_CRITICAL);
        }

        bool parseBool(const String& value, bool def)
        {
            const String v = toLowerAscii(value);
            if (v == "1" || v == "true" || v == "yes" || v == "on")
                return true;
            if (v == "0" || v == "false" || v == "no" || v == "off")
                return false;
            return def;
        }

        String toLowerAscii(const String& s)
        {
            String r = s;
            for (size_t i = 0; i < r.size(); ++i)
            {
                if (r[i] >= 'A' && r[i] <= 'Z')
                    r[i] = char(r[i] - 'A' + 'a');
            }
            return r;
        }
    }
}
