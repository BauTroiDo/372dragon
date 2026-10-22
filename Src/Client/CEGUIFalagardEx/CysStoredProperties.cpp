// CYS-HUD: stored GL properties. See the header and Docs/specs/ui/hud-widgets_vi.md (table 3).
#include "CysStoredProperties.h"
#include "CEGUIWindow.h"
#include "CEGUIWindowFactory.h"
#include "CEGUIWindowFactoryManager.h"
#include "CEGUIExceptions.h"
#include "CEGUILogger.h"
#include <map>
#include <vector>

namespace CEGUI
{
    namespace
    {
        typedef std::map<String, String> ValueMap;
        typedef std::map<const Window*, ValueMap> WindowValues;

        WindowValues& values()
        {
            static WindowValues s_values;
            return s_values;
        }

        bool forget(const EventArgs& e)
        {
            values().erase(static_cast<const WindowEventArgs&>(e).window);
            return false;
        }

        class StoredProperty : public Property
        {
        public:
            StoredProperty(const char* name, const char* help, const char* initial, bool multi)
                : Property(name, help, initial), d_multi(multi) {}
            String get(const PropertyReceiver* r) const
            {
                const Window* w = static_cast<const Window*>(r);
                WindowValues::const_iterator i = values().find(w);
                if (i == values().end()) return getDefault(r);
                ValueMap::const_iterator v = i->second.find(getName());
                return v == i->second.end() ? getDefault(r) : v->second;
            }
            void set(PropertyReceiver* r, const String& value)
            {
                Window* w = static_cast<Window*>(r);
                WindowValues::iterator i = values().find(w);
                if (i == values().end())
                {
                    i = values().insert(std::make_pair(static_cast<const Window*>(w), ValueMap())).first;
                    w->subscribeEvent(Window::EventDestructionStarted, Event::Subscriber(&forget));
                }
                String& slot = i->second[getName()];
                if (d_multi && !slot.empty()) slot += "\n" + value; // repeated entries (ChildItem, IconImage ...)
                else slot = value;
                if (getName() == "BackImage" || getName() == "ShowDurability" || getName() == "EquipmentDurability") w->requestRedraw();
            }
        private:
            bool d_multi;
        };

        struct Entry { const char* type; const char* name; const char* help; const char* initial; bool multi; };

        // type, property, meaning (from client_GL), default, repeated?
        const Entry kEntries[] = {
            { "Falagard/ComplexWindow", "QuestButtonImage", "GL: image of a quest-list button state (\"set: image:\" per state), used by the quest log ComplexWindow.", "", true },
            { "Falagard/ComplexWindow", "ChildItem", "GL: \"key:K name:WindowType\" - window type the ComplexWindow creates for element kind K.", "", true },
            { "Falagard/SceneMap", "IconImage", "GL: \"type:IconN set:S image:I\" - minimap flag icon per icon type (NPC, teammate, ...).", "", true },
            { "Falagard/SceneMap", "AnimateImage", "GL: \"type:K name:Animate\" - animated minimap marker per type.", "", true },
            { "Falagard/SceneMap", "FlashAnimateImage", "GL: flashing marker animation per type.", "", true },
            { "Falagard/SceneMap", "BlueCircleImage", "GL: image of the blue search circle drawn around a target on the map.", "", true },
            { "Falagard/SceneMap", "ChildItem", "GL: \"key:K name:WindowType\" - window type created for map children of kind K (Image, Animate).", "", true },
            { "Falagard/SceneMap", "AutoReset", "GL: True - the map re-centres on the player automatically.", "False", false },
            { "Falagard/SceneMap", "RoundEnabled", "GL: True - the minimap is clipped to a round mask.", "False", false },
            { "Falagard/ActionButton", "BackImage", "GL: \"set: image:\" drawn behind an empty action slot.", "", false },
            { "Falagard/ActionButton", "ShowDurability", "Draw remaining equipment durability inside this slot.", "False", false },
            { "Falagard/ActionButton", "EquipmentDurability", "Current/max durability; negative means no equipment data.", "-1", false },
            { "Falagard/ActionButton", "Image", "GL: fixed icon image of the button (B logs this one as unknown too).", "", false },
            { "Falagard/Money", "AlignFix", "GL: True - money digits and coin icons keep a fixed alignment.", "False", false },
            { "Falagard/Money", "MoneyMaxColour", "GL: colour used when the amount exceeds MoneyMaxNumber.", "FFFFFFFF", false },
            { "Falagard/Money", "MoneyColor", "GL: colour of the money text.", "FFFFFFFF", false },
            { "Falagard/Money", "VertFormatting", "GL: vertical formatting name of the money text (B logs this one as unknown too).", "VertCentred", false },
            { "Falagard/BoundWindow", "AttachEnabled", "GL: True - the window snaps to the frame it is bound to.", "False", false },
            { "Falagard/StaticImage", "AttachEnabled", "GL: True - the image window snaps to its bound frame.", "False", false },
            { "Falagard/StaticImage", "TextColor", "GL: text colour of the static image label.", "FFFFFFFF", false },
            { "Falagard/AnimateImage", "UseImageSize", "GL: True - the window takes the size of the animation frames.", "False", false },
            { "Falagard/AnimateButton", "WarningAnimation", "GL: animation played while the button warns (new item).", "", false },
            { "Falagard/CheckBox", "TextColor", "GL: text colour of the check box label.", "FFFFFFFF", false },
            { "Falagard/SimpleText", "ColorTrans", "GL: True - colour markup in the text is translated.", "False", false },
            { "Falagard/SimpleText", "VertScrollbar", "GL: True - the text shows a vertical scrollbar.", "False", false },
            { "Falagard/SuperProgress", "EffectColorType", "GL: type of the effect colour applied to the bar (see EffectColor).", "0", false },
            { "Falagard/SuperProgress", "FlashPoint", "GL: progress value at which the bar starts flashing.", "0", false },
            { "Falagard/SuperProgress", "FlashSetting", "GL: flash parameters of the bar.", "", false },
            { "Falagard/SuperProgress", "UseUninterruptedEffectColor", "GL: True - the effect colour is not interrupted by progress changes.", "False", false },
            { "Falagard/IMEEditBox", "SoftKeyOnly", "GL: True - the box accepts input from the soft keyboard only.", "False", false },
            { "Falagard/MultiColumnList", "LineDrawOffset", "GL: pixel offset of the row separator lines.", "0", false },
            { "Falagard/ChatBoard", "TextColor", "GL: text colour of the chat board.", "FFFFFFFF", false },
            { "Falagard/MultiIMEEditBox", "DisableCopyPaste", "GL: True - clipboard is disabled for the box.", "False", false },
            { "Falagard/MultiIMEEditBox", "HorzFormatting", "GL: horizontal formatting name of the text.", "WordWrapLeftAligned", false },
            { "Falagard/MultiIMEEditBox", "VertScrollbar", "GL: True - a vertical scrollbar is shown (B logs this one as unknown too).", "False", false },
            { "Falagard/SelfFitWindow", "MinWidth", "GL: minimum width the self-fitting window shrinks to.", "0", false },
            { "Falagard/WorldMap", "ChildItem", "GL: \"key:K name:WindowType\" - window type created for world-map children of kind K.", "", true },
            { "Falagard/ScrollInfo", "ChildItem", "GL: \"key:Child name:TLBB_ChatBoard\" - board type B draws each notice with.", "", true },
            { "Falagard/ScrollInfoFixed", "ChildItem", "GL: \"key:Child name:TLBB_ChatBoard\" - board type B draws each notice with.", "", true },
            // CYS-CYGUI: properties the CY 3.71 layouts set and 0.85/GL does not know
            // (Build/Logs/2026-09-14-cy-gui/census-all-1/causes.txt).
            { "Falagard/StopWatch", "TimerShowType", "CY: format of the countdown (0 = mm:ss, 1 = with hours, ...).", "0", false },
            { "Falagard/StopWatch", "HourText", "CY: text appended after the hour field of the countdown.", "", false },
            { "Falagard/ActionButton", "EnableCtrlRightClick", "CY: True - Ctrl+right click on the slot is sent to the script.", "False", false },
            { "Falagard/CheckBox", "ShowPush", "CY: True - the box also draws the Pushed imagery while checked.", "False", false },
            { "Falagard/WorldMap", "CommanderFlagImage", "CY: \"set:S image:I\" flag of a commander on the world map.", "", true },
            { "Falagard/WorldMap", "HostileImage", "CY: \"set:S image:I\" marker of a hostile force on the world map.", "", true },
            { "Falagard/ChatHistory", "ForceVertScrollbar", "CY: True - the vertical scrollbar is always shown.", "False", false },
            { "Falagard/Button", "HorzFormatting", "CY: horizontal formatting name of the button text.", "HorzCentred", false },
            { "DefaultWindow", "Image", "CY: \"set:S image:I\" drawn by the plain container window.", "", false },
            { "DefaultWindow", "TweenPosition", "CY: target position of the tween animation of the window.", "", false },
            { "Falagard/ChatChannel", "AutoResizeEnabled", "CY: True - the channel bar resizes itself to its tabs.", "False", false },
            { "Falagard/ChatChannel", "ChildItem", "CY: \"key:K name:WindowType\" - window type of a channel tab.", "", true },
            { "Falagard/ChatChannel", "DelButtonSize", "CY: pixel size of the tab close button.", "", false },



            { "Falagard/CheckBox", "MinHeight", "CY: smallest height of the check box inside a CreatureBoard.", "0", false },
            { "Falagard/ActionButton", "HorzLabelFormatting", "CY: horizontal formatting of the button label.", "HorzCentred", false },
            { "Falagard/SimpleText", "HorzLabelFormatting", "CY: horizontal formatting of the label text.", "HorzCentred", false },
            { "Falagard/AchievementBarWindowButton", "HorzLabelFormatting", "CY: horizontal formatting of the item label.", "HorzCentred", false },
            { "Falagard/AchievementBarCompareWindowButton", "HorzLabelFormatting", "CY: horizontal formatting of the item label.", "HorzCentred", false },
        };
    }

    String cysStoredProperty(const Window* window, const String& name)
    {
        WindowValues::const_iterator i = values().find(window);
        if (i == values().end()) return "";
        ValueMap::const_iterator v = i->second.find(name);
        return v == i->second.end() ? String("") : v->second;
    }

    bool cysHasStoredProperty(const Window* window, const String& name)
    {
        WindowValues::const_iterator i = values().find(window);
        return i != values().end() && i->second.find(name) != i->second.end();
    }

    void cysRegisterStoredProperties()
    {
        static std::vector<StoredProperty*> s_properties;
        if (s_properties.empty())
            for (size_t i = 0; i < sizeof(kEntries) / sizeof(kEntries[0]); ++i)
                s_properties.push_back(new StoredProperty(kEntries[i].name, kEntries[i].help, kEntries[i].initial, kEntries[i].multi));
        WindowFactoryManager& wfm = WindowFactoryManager::getSingleton();
        for (size_t i = 0; i < s_properties.size(); ++i)
        {
            if (!wfm.isFactoryPresent(kEntries[i].type)) continue;
            WindowFactory* factory = wfm.getFactory(kEntries[i].type);
            if (!factory->isPropertyPresent(kEntries[i].name))
                factory->addProperty(s_properties[i]);
        }
    }
}
