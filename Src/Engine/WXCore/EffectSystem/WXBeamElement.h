/********************************************************************
filename:   WXBeamElement.h

purpose:    a billboard set effect element,this can use in weapon effect
*********************************************************************/

#ifndef __BEAMELEMENT_H__
#define __BEAMELEMENT_H__

#include "WXEffectElement.h"
#include "Core/WXPrerequisites.h"

// ogre header
#include <OgreColourValue.h>

namespace Ogre	{
	class EffectBillboardChain;
}

namespace WX	{
	
	class BeamElement : public EffectElement
	{
	public:		

		// 参数命令
		class CmdNoiseXMin : public Ogre::ParamCommand
		{
		public:
			String doGet(const void* target) const;
			void doSet(void* target, const String& val);
#if OGRE_STRING_INTERFACE_COPY
            virtual void doCopy(void* target, const void* source);
#endif
		};

		class CmdNoiseXMax : public Ogre::ParamCommand
		{
		public:
			String doGet(const void* target) const;
			void doSet(void* target, const String& val);
#if OGRE_STRING_INTERFACE_COPY
            virtual void doCopy(void* target, const void* source);
#endif	
        };

		class CmdNoiseYMin : public Ogre::ParamCommand
		{
		public:
			String doGet(const void* target) const;
			void doSet(void* target, const String& val);
#if OGRE_STRING_INTERFACE_COPY
            virtual void doCopy(void* target, const void* source);
#endif	
        };

		class CmdNoiseYMax : public Ogre::ParamCommand
		{
		public:
			String doGet(const void* target) const;
			void doSet(void* target, const String& val);
#if OGRE_STRING_INTERFACE_COPY
            virtual void doCopy(void* target, const void* source);
#endif	
        };

		class CmdNoiseZMin : public Ogre::ParamCommand
		{
		public:
			String doGet(const void* target) const;
			void doSet(void* target, const String& val);
#if OGRE_STRING_INTERFACE_COPY
            virtual void doCopy(void* target, const void* source);
#endif	
        };

		class CmdNoiseZMax : public Ogre::ParamCommand
		{
		public:
			String doGet(const void* target) const;
			void doSet(void* target, const String& val);
#if OGRE_STRING_INTERFACE_COPY
            virtual void doCopy(void* target, const void* source);
#endif	
        };

		class CmdNumElements : public Ogre::ParamCommand
		{
		public:
			String doGet(const void* target) const;
			void doSet(void* target, const String& val);
#if OGRE_STRING_INTERFACE_COPY
            virtual void doCopy(void* target, const void* source);
#endif	
        };

		class CmdWidth : public Ogre::ParamCommand
		{
		public:
			String doGet(const void* target) const;
			void doSet(void* target, const String& val);
#if OGRE_STRING_INTERFACE_COPY
            virtual void doCopy(void* target, const void* source);
#endif	
        };

		class CmdColour : public Ogre::ParamCommand
		{
		public:
			String doGet(const void* target) const;
			void doSet(void* target, const String& val);
#if OGRE_STRING_INTERFACE_COPY
            virtual void doCopy(void* target, const void* source);
#endif	
        };

		class CmdColourRangeStart : public Ogre::ParamCommand
		{
		public:
			String doGet(const void* target) const;
			void doSet(void* target, const String& val);
#if OGRE_STRING_INTERFACE_COPY
            virtual void doCopy(void* target, const void* source);
#endif	
        };

		class CmdColourRangeEnd : public Ogre::ParamCommand
		{
		public:
			String doGet(const void* target) const;
			void doSet(void* target, const String& val);
#if OGRE_STRING_INTERFACE_COPY
            virtual void doCopy(void* target, const void* source);
#endif	
        };

		class CmdMaterial : public Ogre::ParamCommand
		{
		public:
			String doGet(const void* target) const;
			void doSet(void* target, const String& val);
#if OGRE_STRING_INTERFACE_COPY
            virtual void doCopy(void* target, const void* source);
#endif	
        };

		class CmdFrequency : public Ogre::ParamCommand
		{
		public:
			String doGet(const void* target) const;
			void doSet(void* target, const String& val);
#if OGRE_STRING_INTERFACE_COPY
            virtual void doCopy(void* target, const void* source);
#endif	
        };


		// CYS: B Beam wave / curve / spline keys (parsed + stored; see WXBeamElement.cpp)
		class CmdCurveType : public Ogre::ParamCommand
		{
		public:
			String doGet(const void* target) const;
			void doSet(void* target, const String& val);
#if OGRE_STRING_INTERFACE_COPY
            virtual void doCopy(void* target, const void* source);
#endif
		};
		class CmdTexRepeat : public Ogre::ParamCommand
		{
		public:
			String doGet(const void* target) const;
			void doSet(void* target, const String& val);
#if OGRE_STRING_INTERFACE_COPY
            virtual void doCopy(void* target, const void* source);
#endif
		};
		class CmdIsVisable : public Ogre::ParamCommand
		{
		public:
			String doGet(const void* target) const;
			void doSet(void* target, const String& val);
#if OGRE_STRING_INTERFACE_COPY
            virtual void doCopy(void* target, const void* source);
#endif
		};
		class CmdIsSinPlay : public Ogre::ParamCommand
		{
		public:
			String doGet(const void* target) const;
			void doSet(void* target, const String& val);
#if OGRE_STRING_INTERFACE_COPY
            virtual void doCopy(void* target, const void* source);
#endif
		};
		class CmdWaveExtentY : public Ogre::ParamCommand
		{
		public:
			String doGet(const void* target) const;
			void doSet(void* target, const String& val);
#if OGRE_STRING_INTERFACE_COPY
            virtual void doCopy(void* target, const void* source);
#endif
		};
		class CmdWaveExtentZ : public Ogre::ParamCommand
		{
		public:
			String doGet(const void* target) const;
			void doSet(void* target, const String& val);
#if OGRE_STRING_INTERFACE_COPY
            virtual void doCopy(void* target, const void* source);
#endif
		};
		class CmdWaveFrequency : public Ogre::ParamCommand
		{
		public:
			String doGet(const void* target) const;
			void doSet(void* target, const String& val);
#if OGRE_STRING_INTERFACE_COPY
            virtual void doCopy(void* target, const void* source);
#endif
		};
		class CmdWaveVelocity : public Ogre::ParamCommand
		{
		public:
			String doGet(const void* target) const;
			void doSet(void* target, const String& val);
#if OGRE_STRING_INTERFACE_COPY
            virtual void doCopy(void* target, const void* source);
#endif
		};
		class CmdWaveShadeY : public Ogre::ParamCommand
		{
		public:
			String doGet(const void* target) const;
			void doSet(void* target, const String& val);
#if OGRE_STRING_INTERFACE_COPY
            virtual void doCopy(void* target, const void* source);
#endif
		};
		class CmdWaveShadeZ : public Ogre::ParamCommand
		{
		public:
			String doGet(const void* target) const;
			void doSet(void* target, const String& val);
#if OGRE_STRING_INTERFACE_COPY
            virtual void doCopy(void* target, const void* source);
#endif
		};
		class CmdSpLineEditor : public Ogre::ParamCommand
		{
		public:
			String doGet(const void* target) const;
			void doSet(void* target, const String& val);
#if OGRE_STRING_INTERFACE_COPY
            virtual void doCopy(void* target, const void* source);
#endif
		};
		class CmdBindElement : public Ogre::ParamCommand
		{
		public:
			String doGet(const void* target) const;
			void doSet(void* target, const String& val);
#if OGRE_STRING_INTERFACE_COPY
            virtual void doCopy(void* target, const void* source);
#endif
		};
		class CmdIsSubEleActive : public Ogre::ParamCommand
		{
		public:
			String doGet(const void* target) const;
			void doSet(void* target, const String& val);
#if OGRE_STRING_INTERFACE_COPY
            virtual void doCopy(void* target, const void* source);
#endif
		};
		class CmdSubElementFrequency : public Ogre::ParamCommand
		{
		public:
			String doGet(const void* target) const;
			void doSet(void* target, const String& val);
#if OGRE_STRING_INTERFACE_COPY
            virtual void doCopy(void* target, const void* source);
#endif
		};

		/////////////////////////////////////////////////////////////
		BeamElement(const String &type, System *system);
		~BeamElement();

		virtual bool createRenderInstance(void);
		virtual void destroyRenderInstance(void);
		virtual void updateRenderInstance( Real time, TransformInfo &info );

		virtual void updateExtraTransformInfos( const TransformInfos &infos );

		//////////////////////////////////////////////////////////////////////////
		void setNumBillboardElements( int num );
		int getNumBillboardElements(void) const
		{
			return mNumBillboardElements;
		}

		void setColour(const Ogre::ColourValue& colour);
		void setColour(const Ogre::ColourValue& colourStart, const Ogre::ColourValue& colourEnd);
		void setColourRangeStart(const Ogre::ColourValue& colour);
		void setColourRangeEnd(const Ogre::ColourValue& colour);
		const Ogre::ColourValue& getColour(void) const;
		const Ogre::ColourValue& getColourRangeStart(void) const;
		const Ogre::ColourValue& getColourRangeEnd(void) const;

		void setMaterialName(const String &matName);
		const String getMaterialName(void) const
		{
			return mMaterialName;
		}


		// CYS: B Beam wave / curve / spline keys
		void setCurveType(int v)	{	mCurveType = v;	}
		int getCurveType(void) const	{	return mCurveType;	}
		void setTexRepeat(int v)	{	mTexRepeat = v;	}
		int getTexRepeat(void) const	{	return mTexRepeat;	}
		void setIsVisable(bool v)	{	mIsVisable = v;	}
		bool getIsVisable(void) const	{	return mIsVisable;	}
		void setIsSinPlay(bool v)	{	mIsSinPlay = v;	}
		bool getIsSinPlay(void) const	{	return mIsSinPlay;	}
		void setWaveExtentY(float v)	{	mWaveExtentY = v;	}
		float getWaveExtentY(void) const	{	return mWaveExtentY;	}
		void setWaveExtentZ(float v)	{	mWaveExtentZ = v;	}
		float getWaveExtentZ(void) const	{	return mWaveExtentZ;	}
		void setWaveFrequency(float v)	{	mWaveFrequency = v;	}
		float getWaveFrequency(void) const	{	return mWaveFrequency;	}
		void setWaveVelocity(float v)	{	mWaveVelocity = v;	}
		float getWaveVelocity(void) const	{	return mWaveVelocity;	}
		void setWaveShadeY(float v)	{	mWaveShadeY = v;	}
		float getWaveShadeY(void) const	{	return mWaveShadeY;	}
		void setWaveShadeZ(float v)	{	mWaveShadeZ = v;	}
		float getWaveShadeZ(void) const	{	return mWaveShadeZ;	}
		void setSpLineEditor(const String& v)	{	mSpLineEditor = v;	}
		const String& getSpLineEditor(void) const	{	return mSpLineEditor;	}
		void setBindElement(const String& v)	{	mBindElement = v;	}
		const String& getBindElement(void) const	{	return mBindElement;	}
		void setIsSubEleActive(bool v)	{	mIsSubEleActive = v;	}
		bool getIsSubEleActive(void) const	{	return mIsSubEleActive;	}
		void setSubElementFrequency(float v)	{	mSubElementFrequency = v;	}
		float getSubElementFrequency(void) const	{	return mSubElementFrequency;	}

		void setFrequency(float frequency);
		float getFrequency(void) const
		{
			return mFrequency;
		}

        /// 设置visible flag
        virtual void setVisibleFlag(uint32 flags);

        virtual void sleep(void);

	protected:

		bool _createBillboardChains(void);
		void _destroyBillboardChains(void);
		void _updateBillboardChains( Real time );
		
		void genColour(Ogre::ColourValue& destColour);

	public:

		float mNoiseXMin;
		float mNoiseXMax;
		float mNoiseYMin;
		float mNoiseYMax;
		float mNoiseZMin;
		float mNoiseZMax;

		float mWidth;

	protected:

		int mNumBillboardElements;

		Ogre::EffectBillboardChain *mBillboardChain;

		Ogre::Vector3 mDestPos;		

		Ogre::ColourValue mColourRangeStart;
		Ogre::ColourValue mColourRangeEnd;

		String mMaterialName;

		float mFrequency;
		float mFrequencyTime;
		float mCurrentFrequencyTime;
		////////////////////////////////////////////////////////////////
		static CmdNoiseXMin msNoiseXMinCmd;
		static CmdNoiseXMax msNoiseXMaxCmd;
		static CmdNoiseYMin msNoiseYMinCmd;
		static CmdNoiseYMax msNoiseYMaxCmd;
		static CmdNoiseZMin msNoiseZMinCmd;
		static CmdNoiseZMax msNoiseZMaxCmd;
		static CmdNumElements msNumElementsCmd;
		static CmdWidth msWidthCmd;

		static CmdColour msColourCmd;
		static CmdColourRangeStart msColourRangeStartCmd;
		static CmdColourRangeEnd msColourRangeEndCmd;

		static CmdMaterial msMaterialCmd;

		static CmdFrequency msFrequencyCmd;

		// CYS: B Beam wave / curve / spline keys
		int mCurveType;
		int mTexRepeat;
		bool mIsVisable;
		bool mIsSinPlay;
		float mWaveExtentY;
		float mWaveExtentZ;
		float mWaveFrequency;
		float mWaveVelocity;
		float mWaveShadeY;
		float mWaveShadeZ;
		String mSpLineEditor;
		String mBindElement;
		bool mIsSubEleActive;
		float mSubElementFrequency;
		static CmdCurveType msCurveTypeCmd;
		static CmdTexRepeat msTexRepeatCmd;
		static CmdIsVisable msIsVisableCmd;
		static CmdIsSinPlay msIsSinPlayCmd;
		static CmdWaveExtentY msWaveExtentYCmd;
		static CmdWaveExtentZ msWaveExtentZCmd;
		static CmdWaveFrequency msWaveFrequencyCmd;
		static CmdWaveVelocity msWaveVelocityCmd;
		static CmdWaveShadeY msWaveShadeYCmd;
		static CmdWaveShadeZ msWaveShadeZCmd;
		static CmdSpLineEditor msSpLineEditorCmd;
		static CmdBindElement msBindElementCmd;
		static CmdIsSubEleActive msIsSubEleActiveCmd;
		static CmdSubElementFrequency msSubElementFrequencyCmd;
	};
}

#endif // __BeamElement_H__