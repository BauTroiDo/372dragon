#ifndef _FalIMEEditBoxProperties_h_
#define _FalIMEEditBoxProperties_h_

#include "CEGUIProperty.h"

// Start of CEGUI namespace section
namespace CEGUI
{
	/*!
	\brief
		Properties for the Falagard IMEEditBox
	*/
	namespace FalagardIMEEditBoxProperties
	{

		/*!
		\brief
			Property to access the default editbox property.

			\par Usage:
				- Name: DefaultEditBox
				- Format: "bool".
		*/
        class DisableCopyPaste : public Property {
        public:
            DisableCopyPaste() : Property("DisableCopyPaste", "Disable clipboard copy, cut and paste.", "False") {}
            String get(const PropertyReceiver* receiver) const override;
            void set(PropertyReceiver* receiver, const String& value) override;
        };
        class DefaultEditBox : public Property
		{
		public:
			DefaultEditBox() : Property(
				"DefaultEditBox",
				"Property to get/set the default editbox property.",
				"")
			{}

			String	get(const PropertyReceiver* receiver) const;
			void	set(PropertyReceiver* receiver, const String& value);
		};

		// CYS-CHATENTER 20/09/2026 (bang vi sai dong D3): thuoc tinh thu hai trong 5 thuoc tinh ma
		// `FalagardIMEEditBox` cua MOI cay song dang ky (`?addIMEEditBoxProperties@FalagardIMEEditBox@CEGUI@@AEAAXXZ`,
		// client_GL\Bin64\CEGUIFalagard.dll sha256 82b61321...; CY 3.71 sha256 4adc5a34...). Lua cua ca ba the he
		// dat no = "True" ngay truoc khi ghi chu vao o nhap (CY ChatFrame.lua:1938, GL MainMenuBar.lua:1465).
		// Ngu nghia: co MOT LAN, xem FalagardIMEEditBox::populateRenderCache.
		class ClearOffset : public Property
		{
		public:
			ClearOffset() : Property(
				"ClearOffset",
				"One-shot flag: the next redraw drops the remembered horizontal text offset.",
				"False")
			{}

			String	get(const PropertyReceiver* receiver) const;
			void	set(PropertyReceiver* receiver, const String& value);
		};

	}
}

#endif