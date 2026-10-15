/********************************************************************
filename:   WXEffect.h

purpose:    a effect contains a lot of effect elements, the info of effect will
			be keep in the .effect files.
*********************************************************************/

#ifndef __FAIRYEFFECT_H__
#define __FAIRYEFFECT_H__

// fairy header
#include "Core/WXPrerequisites.h"
#include "WXEffectBasic.h"

#include <OgreStringInterface.h>

namespace WX	{

	class EffectElement;	

	class Effect : public Ogre::StringInterface, public EffectBasic
	{
	public:
		typedef std::vector<EffectElement *> ElementList;
		typedef ElementList::iterator ElementIterator;

	public:

		class CmdLifeTime : public Ogre::ParamCommand
		{
		public:
			String doGet(const void* target) const;
			void doSet(void* target, const String& val);
#if OGRE_STRING_INTERFACE_COPY
            virtual void doCopy(void* target, const void* source);
#endif
		};

        // CYS: "use_scale" (8525/13014 client_GL effects). B's Effect keeps a bool at +0xe4, default true, set by
        // the CmdUseScale getter/setter; when true the effect inherits the owner logic-model's scale ("scale
        // depend on logicmode"). 0.85 dropped the key entirely, so effects on scaled models rendered at 1.0.
        class CmdUseScale : public Ogre::ParamCommand
        {
        public:
            String doGet(const void* target) const;
            void doSet(void* target, const String& val);
#if OGRE_STRING_INTERFACE_COPY
            virtual void doCopy(void* target, const void* source);
#endif
        };

		//////////////////////////////////////////////////////////////////////////
		Effect(const String &templateName, System *system);
		virtual ~Effect();

		const String& getTemplateName(void) const	{	return mTemplateName;	}
		void setTemplateName( const String &name )	{	mTemplateName = name;	}

		void dump(std::ofstream &of) const;		

		/// update the effect and its elements, will be called by a controller.
		void updateEffect(Real value);
		
		/** Assignment operator for copying.
		@remarks
		This operator deep copies all info of the effect.
		*/
        Effect& operator=(const Effect& rhs);

		virtual void setTransformInfo( const TransformInfo &info );

		void setExtraTransformInfos( const TransformInfos &infos );

		void reborn(void);

		/** add a child element */
		void addElement( EffectElement *element );
		void addElement( const String &type );

		void removeAllElements(void);

		/// remove the element,not destroy,just sleep
		void removeElement( EffectElement *element );

		/// 把effect主节点从它的父节点上卸下来，以便在之后可以挂上别的父节点
		void removeParentSceneNode(void);

		/// destroy the child element
		ElementIterator destroyElement( ElementIterator i );
		void destroyElement( EffectElement *element );
		void destroyElement( unsigned short index );

		void destroyAllElements(void);

		/**	get the number of child elements */
		unsigned short getNumElements(void) const
		{
			return static_cast<unsigned short>( mElementList.size() );
		}
	
		EffectElement *getElement( unsigned short index );

		Ogre::SceneNode* createSceneNode(void);
		void createSceneNode( Ogre::SceneNode *parentNode );

		/**	set the life time of this element
		@param time second
		*/
		void setLifeTime(Real time)	{	mLifeTime = time;	}
		/**	get the born time of this element
		@param time second
		*/
		Real getLifeTime(void) const	{	return mLifeTime;	}

		bool isAlive(void)	{ return mAliveEffect;	}

		// CYS: use_scale (parsed + stored). B keeps this bool at Effect+0xe4 (default true) and, when set, makes the
		// effect follow the owner model's scale. NOT applied yet: the effect base node stays at the origin while
		// each element node is positioned in WORLD coordinates (Effect::setTransformInfo -> EffectElement), so
		// scaling the base node would multiply world positions - wrong. The correct mechanism scales each element's
		// offset (mRelPos) and its internal sizes; it needs a scaled-model GPU check (viewer has no --scale) before
		// it can be turned on. See Docs/specs/render/07c-effects_vi.md muc 3. Kept parsed so it is not logged as
		// an unknown attribute for 8525 client_GL effects.
		void setUseScale(bool use)	{	mUseScale = use;	}
		bool getUseScale(void) const	{	return mUseScale;	}

		virtual bool existVisualElements(void);

		static void setDefaultIterativeInterval(Real time)
		{
			msDefaultIterativeInterval = time;
		}

		static Real getDefaultIterativeInterval(void)
		{
			return msDefaultIterativeInterval;
		}

		void setIterativeInterval(Real time)
		{
			mIterativeInterval = time;
		}

		Real getIterativeInterval(void)
		{
			return mIterativeInterval;
		}

		void shutdown(void);

        virtual void setVisible(bool visible);

        /** 设置特效上各种元素的颜色
        @remarks 会遍历所有的元素，改变各种元素的颜色
        */
        virtual void setColour( const Ogre::ColourValue& colour );

        /// 设置visible flag
        virtual void setVisibleFlag(uint32 flags);
        uint32 getVisibleFlag() const { return mVisibleFlags; }

        void setRemoveParentNode(bool removeParentNode)
        {
            mRemoveParentNode = removeParentNode;
        }
        bool getRemoveParentNode(void)
        {
            return mRemoveParentNode;
        }

        void setDelayRemove(bool delayRemove)
        {
            mDelayRemove = delayRemove;
        }
        bool getDelayRemove(void)
        {
            return mDelayRemove;
        }

        /// 特效是否在删除时回收
        bool mPutIntoFreePool;

	protected:

		bool initDefaults(void);

		void _updateSelf(Real time);

		void _updateElements(Real time);

	protected:

		String mTemplateName;

		TransformInfo mTransformInfo;

		/// child elements
		ElementList mElementList;

		/// the life time of this element, is zero by default, if it is zero, the element will live forever.
		Real mLifeTime;

		/// current life time of this element.
		Real mCurrentLifeTime;

		bool mAliveEffect;

		Real mIterateRemainTime;
		Real mIterativeInterval;

        bool mNeedSetVisibleFlags;
        uint32 mVisibleFlags;

        bool mRemoveParentNode;

        bool mDelayRemove;

		static Real msDefaultIterativeInterval;

		/// CYS: use_scale flag (default true, as B). Parsed + stored; application pending (see setUseScale note).
		bool mUseScale;

		////////////////////////////////////////////////////////////////
		static CmdLifeTime msLifeTimeCmd;
		static CmdUseScale msUseScaleCmd;	// CYS
	};
}

#endif
