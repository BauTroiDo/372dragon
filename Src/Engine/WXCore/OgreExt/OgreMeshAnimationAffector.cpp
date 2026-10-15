/*
-----------------------------------------------------------------------------
This source file is part of OGRE
(Object-oriented Graphics Rendering Engine)
For the latest info, see http://www.ogre3d.org/

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
#include "OgreMeshAnimationAffector.h"
#include "OgreParticleSystem.h"
#include "OgreParticle.h"
#include "OgreStringConverter.h"
#include "OgreExt/OgreMeshParticleVisualData.h"
#include "OgreExt/OgreMeshParticleRenderer.h"	// CYS: mesh name of the renderer
#include "OgreParticleEmitter.h"				// CYS
#include "OgreParticleSystemRenderer.h"			// CYS
#include "OgreMeshManager.h"					// CYS
#include "OgreMesh.h"							// CYS
#include "OgreSkeleton.h"						// CYS
#include "OgreAnimation.h"						// CYS
#include <math.h>								// CYS

namespace Ogre {

    // Instantiate statics
    MeshAnimationAffector::CmdAnimationName	MeshAnimationAffector::msAnimationNameCmd;
    MeshAnimationAffector::CmdAnimationLoop	MeshAnimationAffector::msAnimationLoopCmd;
    MeshAnimationAffector::CmdAnimationSpeedFactor	MeshAnimationAffector::msAnimationSpeedFactorCmd;
    MeshAnimationAffector::CmdAnimationRangeBegin MeshAnimationAffector::msAnimationRangeBeginCmd; // CYS
    MeshAnimationAffector::CmdAnimationRangeEnd MeshAnimationAffector::msAnimationRangeEndCmd;     // CYS

    //-----------------------------------------------------------------------
    MeshAnimationAffector::MeshAnimationAffector(ParticleSystem* psys)
		:ParticleAffector(psys),
		mAnimationName(""),
        mAnimationLoop(false),
        mAnimationSpeedFactor(1.0f),
        mRangeBegin(0.0f),
        mRangeEnd(1.0f)
    {
        mType = "MeshAnimationAffector";
        for (int i = 0; i < 8; ++i)
            mCysKeys[i] = 0.0f;

		// Init parameters
		if (createParamDictionary("MeshAnimationAffector"))
		{
			ParamDictionary* dict = getParamDictionary();

			dict->addParameter(ParameterDef("animation_name",
				"the name of the animation.", PT_STRING),
				&msAnimationNameCmd);

            // CYS: client_GL keys (Render.dll 18013d7d0); 'anim_pos' is registered in a side list there that
            // no code reads, so client_GL rejects anim_posN lines as well
            dict->addParameter(ParameterDef("animation_range_begin",
                "set the beginning time pos (s) of the animation.", PT_REAL),
                &msAnimationRangeBeginCmd);

            dict->addParameter(ParameterDef("animation_range_end",
                "set the ending time pos (s) of the animation.", PT_REAL),
                &msAnimationRangeEndCmd);

			dict->addParameter(ParameterDef("animation_loop",
				"set the looping of the animation.", PT_BOOL),
				&msAnimationLoopCmd);

            dict->addParameter(ParameterDef("animation_speed",
                "set the speed factor of the animation.", PT_REAL),
                &msAnimationSpeedFactorCmd);
		}
    }
    //-----------------------------------------------------------------------
    void MeshAnimationAffector::_cysSetupKeys(Real length, Real timeToLive)
    {
        // CYS: client_GL (Render.dll 18013ddc0) - keys are (position, life) pairs
        for (int i = 0; i < 8; ++i)
            mCysKeys[i] = 0.0f;
        if (!mAnimationLoop && !(length > timeToLive))
        {
            // the animation plays once at its own speed, then holds its last frame
            mCysKeys[2] = 1.0f;
            mCysKeys[3] = length / timeToLive;
            mCysKeys[4] = 1.0f;
            mCysKeys[5] = 1.0f;
        }
        else
        {
            // the position follows the life; one cycle lasts the animation length
            mCysKeys[2] = 1.0f;
            mCysKeys[3] = 1.0f;
            mAnimationSpeedFactor *= timeToLive / length;
        }
    }
    //-----------------------------------------------------------------------
    bool MeshAnimationAffector::_cysBuildKeys(ParticleSystem* pSystem)
    {
        // CYS: client_GL takes the animation length from the renderer's mesh skeleton and the life of the
        // first emitter (a random life between its minimum and maximum)
        ParticleSystemRenderer* renderer = pSystem->getRenderer();
        if (!renderer || renderer->getType() != "mesh")
            return false;
        MeshPtr mesh = MeshManager::getSingleton().getByName(
            static_cast<MeshParticleRenderer*>(renderer)->getMeshName());
        if (mesh.isNull())
            return false;
        mesh->load();
        Real length = 0.0f;
        SkeletonPtr skeleton = mesh->getSkeleton();
        if (!skeleton.isNull() && skeleton->hasAnimation(mAnimationName))
            length = skeleton->getAnimation(mAnimationName)->getLength();
        if (length == 0.0f || pSystem->getNumEmitters() == 0)
            return false;
        ParticleEmitter* emitter = pSystem->getEmitter(0);
        Real ttl = emitter->getMinTimeToLive();
        const Real ttlMax = emitter->getMaxTimeToLive();
        if (ttl != ttlMax)
            ttl = ttl + (ttlMax - ttl) * Math::UnitRandom();
        _cysSetupKeys(length, ttl);
        return true;
    }
    //-----------------------------------------------------------------------
    Real MeshAnimationAffector::_animationPosition(Real age) const
    {
        // CYS: client_GL (Render.dll 18013ddc0)
        const Real range = mRangeEnd - mRangeBegin;
        Real t = age * mAnimationSpeedFactor / range;
        if (mAnimationLoop)
        {
            while (t < 0.0f)
                t += 1.0f;
            t = (Real)fmod((double)t, 1.0);
        }
        else if (t < 0.0f)
        {
            t = 0.0f;
        }
        else if (t > 1.0f)
        {
            t = 0.999f; // client_GL stops just before the end
        }

        Real value = mCysKeys[6];
        if (mCysKeys[1] > t)
        {
            value = mCysKeys[0];
        }
        else
        {
            for (int i = 0; i < 3; ++i)
            {
                const Real t0 = mCysKeys[2 * i + 1];
                const Real t1 = mCysKeys[2 * i + 3];
                if (!(t < t0) && t1 > t)
                {
                    const Real f = (t - t0) / (t1 - t0);
                    value = (1.0f - f) * mCysKeys[2 * i] + f * mCysKeys[2 * i + 2];
                    break;
                }
            }
        }
        Real pos = value * range + mRangeBegin;
        if (pos < 0.0f)
            pos = 0.0f;
        else if (pos > 1.0f)
            pos = 1.0f;
        return pos;
    }
	//-----------------------------------------------------------------------
	void MeshAnimationAffector::_affectParticles(ParticleSystem* pSystem, Real timeElapsed)
	{
        // CYS: client_GL - nothing happens until the curve could be built (mesh and animation loaded)
        bool empty = true;
        for (int i = 0; i < 8 && empty; ++i)
            empty = (mCysKeys[i] == 0.0f);
        if (empty && !_cysBuildKeys(pSystem))
            return;

		ParticleIterator pi = pSystem->_getIterator();
		Particle *p;

		while (!pi.end())
		{
			p = pi.getNext();

			MeshParticleVisualData *data = static_cast<MeshParticleVisualData *>(p->getVisualData());

            data->mAnimationName = mAnimationName;

            data->mDeltaTime = timeElapsed;

            data->mAnimationLoop = mAnimationLoop;

            data->mAnimationSpeedFactor = mAnimationSpeedFactor;

            // CYS: normalised animation position from the particle life (MeshParticleVisualData::updateAnimation)
            const Real age = (p->totalTimeToLive > 0.0f) ? 1.0f - p->timeToLive / p->totalTimeToLive : 1.0f;
            data->mCysAnimPos = _animationPosition(age);

            data->mAnimationUpdated = true;
		}
	}
	//-----------------------------------------------------------------------
	String MeshAnimationAffector::CmdAnimationName::doGet(const void* target) const
	{
		return static_cast<const MeshAnimationAffector*>(target)->getAnimationName();
	}
	void MeshAnimationAffector::CmdAnimationName::doSet(void* target, const String& val)
	{
		static_cast<MeshAnimationAffector*>(target)->setAnimationName(val);
	}
	//-----------------------------------------------------------------------
	String MeshAnimationAffector::CmdAnimationLoop::doGet(const void* target) const
	{
		return StringConverter::toString(
			static_cast<const MeshAnimationAffector*>(target)->getAnimationLoop() );
	}
	void MeshAnimationAffector::CmdAnimationLoop::doSet(void* target, const String& val)
	{
		static_cast<MeshAnimationAffector*>(target)->setAnimationLoop(StringConverter::parseBool(val));
	}
    //-----------------------------------------------------------------------
    String MeshAnimationAffector::CmdAnimationSpeedFactor::doGet(const void* target) const
    {
        return StringConverter::toString(
            static_cast<const MeshAnimationAffector*>(target)->getAnimationSpeedFactor() );
    }
    void MeshAnimationAffector::CmdAnimationSpeedFactor::doSet(void* target, const String& val)
    {
        static_cast<MeshAnimationAffector*>(target)->setAnimationSpeedFactor(StringConverter::parseReal(val));
    }
    //-----------------------------------------------------------------------
    // CYS: client_GL range keys
    String MeshAnimationAffector::CmdAnimationRangeBegin::doGet(const void* target) const
    {
        return StringConverter::toString(
            static_cast<const MeshAnimationAffector*>(target)->getAnimationRangeBegin() );
    }
    void MeshAnimationAffector::CmdAnimationRangeBegin::doSet(void* target, const String& val)
    {
        static_cast<MeshAnimationAffector*>(target)->setAnimationRangeBegin(StringConverter::parseReal(val));
    }
    String MeshAnimationAffector::CmdAnimationRangeEnd::doGet(const void* target) const
    {
        return StringConverter::toString(
            static_cast<const MeshAnimationAffector*>(target)->getAnimationRangeEnd() );
    }
    void MeshAnimationAffector::CmdAnimationRangeEnd::doSet(void* target, const String& val)
    {
        static_cast<MeshAnimationAffector*>(target)->setAnimationRangeEnd(StringConverter::parseReal(val));
    }
}

