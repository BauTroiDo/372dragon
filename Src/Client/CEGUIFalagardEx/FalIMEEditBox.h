#ifndef _FalIMEEditBox_h_
#define _FalIMEEditBox_h_

#include "FalModule.h"
#include "CEGUIWindowFactory.h"
#include "FalIMEEditBoxProperties.h"
#include "FalEditbox.h"

// Start of CEGUI namespace section
namespace CEGUI
{

    class FALAGARDBASE_API FalagardIMEEditBox : public FalagardEditbox
    {
    public:
        bool isCopyPasteDisabled() const { return d_copyPasteDisabled; }
        void setCopyPasteDisabled(bool disabled) { d_copyPasteDisabled = disabled; }
        // CYS-CHATENTER 20/09/2026 (bang vi sai dong D3). Hoc tu cay song bang KY HIEU export:
        //   ?setClearOffset@FalagardIMEEditBox@CEGUI@@UEAAX_N@Z / ?getClearOffset@...@UEBA_NXZ
        //   (client_GL\Bin64\CEGUIFalagard.dll sha256 82b61321..., co tai this+0x50C;
        //    CY 3.71 Bin64 sha256 4adc5a34..., co tai this+0x514) - hai ban dung khop nhau:
        //   set: if (b != co) { co = b; requestRedraw(); }     get: tra co.
        // Khong de `virtual` nhu ban song: ta khong co lop nao ghi de no, va them o ao vao giua
        // bang ao cua mot lop co lop con (FalagardSafeIMEEditBox) la rui ro khong mua duoc gi.
        bool getClearOffset() const { return d_clearOffset; }
        void setClearOffset(bool clear);
        static const utf8   WidgetTypeName[];       //!< type name for this widget.

        /*!
        \brief
            Constructor
        */
        FalagardIMEEditBox(const String& type, const String& name);

        /*!
        \brief
            Destructor
        */
        ~FalagardIMEEditBox();

		/*************************************************************************
			Accessors
		*************************************************************************/
		
		/*!
		\brief
			Reset the caret flash time.

		\return
			None.
		*/
		virtual void	resetCaretBlink(void);

		/*!
		\brief
			return true if the Editbox has input focus.

		\return
			true if the Editbox has keyboard input focus, false if the Editbox does not have keyboard input focus.
		*/
		virtual bool	hasInputFocus(void) const;

    protected:
        /*************************************************************************
        	Implementation of abstract methods in Window
        *************************************************************************/
		virtual	void			onMouseButtonDown(MouseEventArgs& e);
        virtual void			populateRenderCache();
		virtual void			updateSelf(float elapsed);
		virtual void			onActivated(ActivationEventArgs& e);
		virtual void			onDeactivated(ActivationEventArgs& e);
		virtual void			onParentHidden(void);

        virtual size_t			getTextIndexFromPosition(const Point& pt) const;

        // rendering internal vars
        float	d_lastTextOffset;			//!< x rendering offset used last time we drew the widget.
		

		double	d_blinkTime;				//!< Caret blink time in milliseconds
		double	d_lastBlink;				//!< Last timestamp of caret blink
		bool	d_caretOn;					//!< Flag to indicate whether caret is currently visible

		int		d_lastTextLen;				//!< Store the text length.

		/*!
		\brief
		Return whether this window was inherited from the given class name at some point in the inheritance heirarchy.

		\param class_name
		The class name that is to be checked.

		\return
		true if this window was inherited from \a class_name. false if not.
		*/
		virtual bool	testClassName_impl(const String& class_name) const
		{
			if (class_name==(const utf8*)"FalagardIMEEditBox")	return true;
			return FalagardEditbox::testClassName_impl(class_name);
		}

	private:
        bool d_copyPasteDisabled;
        bool d_clearOffset;		// CYS-CHATENTER: co MOT LAN, populateRenderCache tieu thu
        static FalagardIMEEditBoxProperties::DisableCopyPaste d_disableCopyPasteProperty;
        static FalagardIMEEditBoxProperties::ClearOffset d_clearOffsetProperty;	// CYS-CHATENTER
        /*************************************************************************
            Static properties for the ChatEditBox widget
        *************************************************************************/
		static FalagardIMEEditBoxProperties::DefaultEditBox	d_defaultEditBoxProperty;

       /*************************************************************************
        	Implementation methods
        *************************************************************************/

        /*!
        \brief
            Adds properties specific to the IMEEditBox base class.
        
        \return
            Nothing.
        */
        void addIMEEditBoxProperties(void);
	};

    /*!
    \brief
        WindowFactory for FalagardIMEEditBox type Window objects.
    */
    class FALAGARDBASE_API FalagardIMEEditBoxFactory : public WindowFactory
    {
    public:
        FalagardIMEEditBoxFactory(void) : WindowFactory(FalagardIMEEditBox::WidgetTypeName) { }
        ~FalagardIMEEditBoxFactory(void){}
        Window* createWindow(const String& name);
        void destroyWindow(Window* window);
    };
}

#endif