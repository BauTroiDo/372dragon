/************************************************************************
    filename:   FalModule.cpp
    created:    Wed Jun 22 2005
    author:     Paul D Turner <paul@cegui.org.uk>
*************************************************************************/
/*************************************************************************
    Crazy Eddie's GUI System (http://www.cegui.org.uk)
    Copyright (C)2004 - 2005 Paul D Turner (paul@cegui.org.uk)
 
    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.
 
    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.
 
    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*************************************************************************/
#include "FalModule.h"
#include "CEGUIExceptions.h"
#include "CEGUIWindowFactoryManager.h"
// includes for types we create
#include "FalButton.h"
#include "FalCheckbox.h"
#include "FalComboDropList.h"
#include "FalCombobox.h"
#include "FalEditbox.h"
#include "FalFrameWindow.h"
#include "FalListHeader.h"
#include "FalListHeaderSegment.h"
#include "FalListbox.h"
#include "FalMenuBar.h"
#include "FalMenuItem.h"
#include "FalMultiColumnList.h"
#include "FalMultiLineEditbox.h"
#include "FalPopupMenu.h"
#include "FalProgressBar.h"
#include "FalRadioButton.h"
#include "FalScrollablePane.h"
#include "FalScrollbar.h"
#include "FalSlider.h"
#include "FalSpinner.h"
#include "FalStaticImage.h"
#include "FalStaticText.h"
#include "FalSystemButton.h"
#include "FalTabButton.h"
#include "FalTabControl.h"
#include "FalTabPane.h"
#include "FalThumb.h"
#include "FalTitlebar.h"
#include "FalTooltip.h"

// CYS: 0.85 found these through the include dir <Client>/CEGUI/CEGUI/include + "../../../"; in CY-Source
// FalagardEx lives in Src/Client/CEGUIFalagardEx, and cegui.cmake puts Src/Client on this target's include path.
#include "CEGUIFalagardEx/FalActionButton.h"
#include "CEGUIFalagardEx/Falagardminimap.h"
#include "CEGUIFalagardEx/FalagardRewardItem.h"
#include "CEGUIFalagardEx/FalagardComplexWindow.h"
#include "CEGUIFalagardEx/falagardcheckbutton.h"
#include "CEGUIFalagardEx/FalagardBeHitBoard.h"
#include "CEGUIFalagardEx/FalSuperToolTip.h"
#include "CEGUIFalagardEx/FalMoney.h"
#include "CEGUIFalagardEx/FalSimpleText.h"
#include "CEGUIFalagardEx/FalDragTitle.h"
#include "CEGUIFalagardEx/FalagardMeshWindow.h"
#include "CEGUIFalagardEx/FalagardMapImage.h"
#include "CEGUIFalagardEx/FalBoundWindow.h"
#include "CEGUIFalagardEx/FalIMEEditBox.h"
#include "CEGUIFalagardEx/FalMultiIMEEditBox.h"
#include "CEGUIFalagardEx/FalChatBoard.h"
#include "CEGUIFalagardEx/FalChatHistory.h"
#include "CEGUIFalagardEx/FalChatChannel.h"
#include "CEGUIFalagardEx/FalagardSuperProgress.h"
#include "CEGUIFalagardEx/FalagardSceneMap.h"
#include "CEGUIFalagardEx/FalagardWorldmap.h"
#include "CEGUIFalagardEx/FalagardInfolist.h"
#include "CEGUIFalagardEx/FalCreatureBoard.h"
#include "CEGUIFalagardEx/FalStopWatch.h"
#include "CEGUIFalagardEx/FalagardAnimate.h"
#include "CEGUIFalagardEx/FalagardSelfFitWindow.h"
#include "CEGUIFalagardEx/FalagardPaoPao.h"
#include "CEGUIFalagardEx/FalagardSoftKeyBoard.h"
#include "CEGUIFalagardEx/FalagardRadar.h"
#include "CEGUIFalagardEx/FalagardStar.h"
#include "CEGUIFalagardEx/FalagardLoginWidgets.h"
// CYS-HUD: GL widgets for the HUD / system windows (NotSuperList, ListBoxEx, PS, ScrollInfo, AchievementWindow, drag & drop).
#include "CEGUIFalagardEx/FalagardNotSuperList.h"
#include "CEGUIFalagardEx/FalagardListBoxEx.h"
#include "CEGUIFalagardEx/FalagardParticleSystem.h"
#include "CEGUIFalagardEx/FalagardScrollInfo.h"
#include "CEGUIFalagardEx/FalagardAchievementWindow.h"
#include "CEGUIFalagardEx/FalagardDragDropTarget.h"
#include "CEGUIFalagardEx/FalagardSuperBarButton.h"
#include "CEGUIFalagardEx/CysStoredProperties.h"
// CYS-CYGUI: window types CY 3.71 has and GL does not (MeshWindow/ParentWindow, ActionButtonWindow, EventsWindow,
// the CY item buttons, MultiColumnListNew/Ex, ScrollText, DragCornerButton, Phone/SFZ soft keys, StaticUVImage,
// CircleProgress).
#include "CEGUIFalagardEx/FalagardCyWidgets.h"

/*************************************************************************
    Static factory objects
*************************************************************************/
static CEGUI::FalagardButtonFactory             s_ButtonFactory;
static CEGUI::FalagardCheckboxFactory           s_CheckboxFactory;
static CEGUI::FalagardComboDropListFactory      s_ComboDropListFactory;
static CEGUI::FalagardComboboxFactory           s_ComboboxFactory;
static CEGUI::FalagardEditboxFactory            s_EditboxFactory;
static CEGUI::FalagardFrameWindowFactory        s_FrameWindowFactory;
static CEGUI::FalagardListHeaderFactory         s_ListHeaderFactory;
static CEGUI::FalagardListHeaderSegmentFactory  s_ListHeaderSegmentFactory;
static CEGUI::FalagardListboxFactory            s_ListboxFactory;
static CEGUI::FalagardMenubarFactory            s_MenubarFactory;
static CEGUI::FalagardMenuItemFactory           s_MenuItemFactory;
static CEGUI::FalagardMapImageFactory           s_MapImageFactory;
static CEGUI::FalagardMultiColumnListFactory    s_MultiColumnListFactory;
static CEGUI::FalagardMultiLineEditboxFactory   s_MultiLineEditboxFactory;
static CEGUI::FalagardPopupMenuFactory          s_PopupMenuFactory;
static CEGUI::FalagardProgressBarFactory        s_ProgressBarFactory;
static CEGUI::FalagardRadioButtonFactory        s_RadioButtonFactory;
static CEGUI::FalagardScrollablePaneFactory     s_ScrollablePaneFactory;
static CEGUI::FalagardScrollbarFactory          s_ScrollbarFactory;
static CEGUI::FalagardSliderFactory             s_SliderFactory;
static CEGUI::FalagardSpinnerFactory            s_SpinnerFactory;
static CEGUI::FalagardStaticImageFactory        s_StaticImageFactory;
static CEGUI::FalagardStaticTextFactory         s_StaticTextFactory;
static CEGUI::FalagardSystemButtonFactory       s_SystemButtonFactory;
static CEGUI::FalagardTabButtonFactory          s_TabButtonFactory;
static CEGUI::FalagardTabControlFactory         s_TabControlFactory;
static CEGUI::FalagardTabPaneFactory            s_TabPaneFactory;
static CEGUI::FalagardThumbFactory              s_ThumbFactory;
static CEGUI::FalagardTitlebarFactory           s_TitlebarFactory;
static CEGUI::FalagardTooltipFactory            s_TooltipFactory;

//Falgard Ex
static CEGUI::FalagardActionButtonFactory       s_ActionButtonFactory;
static CEGUI::FalagardMinimapFactory			s_MinimapFactory;
static CEGUI::FalagardRewardItemWindowFactory	s_RewardItemFactory;
static CEGUI::FalagardComplexWindow::ParentWindowFactory		s_ComplexParentWindowFactory;
static CEGUI::FalagardComplexWindowFactory		s_ComplexWindowFactory;
static CEGUI::FalagardCheckButtonFactory		s_CheckbuttonFactory;
static CEGUI::FalagardBeHitFactory				s_BeHitFactory;
static CEGUI::FalagardSuperTooltipFactory		s_superTooltipFactory;
static CEGUI::FalagardSuperTooltip::ResizeTextFactory 		s_resizeTextFactory;
static CEGUI::FalagardMoneyFactory				s_MoneyFactory;
static CEGUI::FalagardSimpleTextFactory			s_SimpleTextFactory;
static CEGUI::FalagardDragTitleFactory			s_dragTitleFactory;
static CEGUI::FalagardMeshWindowFactory			s_meshWindowFactory;
static CEGUI::FalagardBoundWindowFactory		s_boundWindowFactory;
static CEGUI::FalagardIMEEditBoxFactory			s_imeEditBoxWindowFactory;
static CEGUI::FalagardMultiIMEEditBoxFactory	s_multiImeEditBoxWindowFactory;
static CEGUI::FalagardChatBoardFactory			s_chatBoardWindowFactory;
static CEGUI::FalagardChatHistoryFactory		s_chatHistoryWindowFactory;
static CEGUI::FalagardChatHistory::ParentWindowFactory			s_chatHistoryParentWindowFactory;
static CEGUI::FalagardChatChannelFactory		s_chatChannelWindowFactory;
static CEGUI::FalagardSuperProgressFactory		s_SuperProgressFactory;
static CEGUI::FalagardScenemapFactory			s_ScenemapFactory;
static CEGUI::FalagardWorldMapFactory 			s_WorldMapFactory;
static CEGUI::FalagardInfoListFactory			s_InfoListFactory;
static CEGUI::FalagardCreatureBoardFactory		s_CreatureBoardFactory;
static CEGUI::FalagardStopWatchFactory			s_StopWatchFactory;
static CEGUI::FalagardAnimateFactory			s_AnimateFactory;
static CEGUI::FalagardSelfFitFactory			s_SelfFitFactory;
static CEGUI::FalagardPaoPaoFactory				s_PaoPaoFactory;
static CEGUI::FalagardSoftKeyFactory			s_SoftKeyFactory;
static CEGUI::FalagardRadarFactory				s_RadarFactory;
static CEGUI::FalagardStarFactory s_StarFactory; // CYS: modern chat speaker.
static CEGUI::FalagardAnimateImageFactory s_AnimateImageFactory;
static CEGUI::FalagardAnimateButtonFactory s_AnimateButtonFactory;
static CEGUI::FalagardSafeIMEEditBoxFactory s_SafeIMEEditBoxFactory;
// CYS-HUD
static CEGUI::FalagardNotSuperListFactory s_NotSuperListFactory;
static CEGUI::FalagardNotSuperListItemFactory s_NotSuperListItemFactory;
static CEGUI::FalagardListBoxExFactory s_ListBoxExFactory;
static CEGUI::FalagardParticleSystemFactory s_ParticleSystemFactory;
static CEGUI::FalagardScrollInfoFactory s_ScrollInfoFactory;
static CEGUI::FalagardScrollInfoFixedFactory s_ScrollInfoFixedFactory;
static CEGUI::FalagardAchievementWindowFactory s_AchievementWindowFactory;
static CEGUI::FalagardDragDropTargetFactory s_DragDropTargetFactory;
static CEGUI::FalagardDragContainerFactory s_DragContainerFactory;
static CEGUI::FalagardSuperBarButtonFactory s_SuperBarButtonFactory;
static CEGUI::FalagardTripperTooltipFactory s_TripperTooltipFactory;
// CYS-CYGUI
static CEGUI::FalagardMeshWindowParentWindowFactory s_CyMeshWindowParentFactory;
static CEGUI::FalagardActionButtonWindowFactory s_CyActionButtonWindowFactory;
static CEGUI::FalagardEventsWindowFactory s_CyEventsWindowFactory;
static CEGUI::FalagardActionButtonItemFactory s_CyActionButtonItemFactory;
static CEGUI::FalagardGuildButtonFactory s_CyGuildButtonFactory;
static CEGUI::FalagardAchievementBarWindowButtonFactory s_CyAchvBarButtonFactory;
static CEGUI::FalagardAchievementBarCompareWindowButtonFactory s_CyAchvBarCompareButtonFactory;
static CEGUI::FalagardAchievementBarCompareWindowIntegrationButtonFactory s_CyAchvBarCompareIntegrationFactory;
static CEGUI::FalagardAchievementWindowCatalogButtonFactory s_CyAchvCatalogButtonFactory;
static CEGUI::FalagardAchievementWindowTextButtonFactory s_CyAchvTextButtonFactory;
static CEGUI::FalagardMultiColumnListNewFactory s_CyMultiColumnListNewFactory;
static CEGUI::FalagardMultiColumnListExFactory s_CyMultiColumnListExFactory;
static CEGUI::FalagardScrollTextFactory s_CyScrollTextFactory;
static CEGUI::FalagardDragCornerButtonFactory s_CyDragCornerButtonFactory;
static CEGUI::FalagardPhoneSoftKeyBoardFactory s_CyPhoneSoftKeyFactory;
static CEGUI::FalagardSFZSoftKeyBoardFactory s_CySFZSoftKeyFactory;
static CEGUI::FalagardStaticUVImageFactory s_CyStaticUVImageFactory;
static CEGUI::FalagardCircleProgressFactory s_CyCircleProgressFactory;
//Falgard Ex

	
using namespace CEGUI;

struct mapEntry
{
    const CEGUI::utf8* d_name;
    CEGUI::WindowFactory* d_factory;
};

mapEntry factoriesMap[] =
{
    {FalagardButton::WidgetTypeName, &s_ButtonFactory},
    {FalagardCheckbox::WidgetTypeName, &s_CheckboxFactory},
    {FalagardComboDropList::WidgetTypeName, &s_ComboDropListFactory},
    {FalagardCombobox::WidgetTypeName, &s_ComboboxFactory},
    {FalagardEditbox::WidgetTypeName, &s_EditboxFactory},
    {FalagardFrameWindow::WidgetTypeName, &s_FrameWindowFactory},
    {FalagardListHeader::WidgetTypeName, &s_ListHeaderFactory},
    {FalagardListHeaderSegment::WidgetTypeName, &s_ListHeaderSegmentFactory},
    {FalagardListbox::WidgetTypeName, &s_ListboxFactory},
    {FalagardMenubar::WidgetTypeName, &s_MenubarFactory},
    {FalagardMenuItem::WidgetTypeName, &s_MenuItemFactory},
    {FalagardMapImage::WidgetTypeName, &s_MapImageFactory},
    {FalagardMultiColumnList::WidgetTypeName, &s_MultiColumnListFactory},
    {FalagardMultiLineEditbox::WidgetTypeName, &s_MultiLineEditboxFactory},
    {FalagardPopupMenu::WidgetTypeName, &s_PopupMenuFactory},
    {FalagardProgressBar::WidgetTypeName, &s_ProgressBarFactory},
    {FalagardRadioButton::WidgetTypeName, &s_RadioButtonFactory},
    {FalagardScrollablePane::WidgetTypeName, &s_ScrollablePaneFactory},
    {FalagardScrollbar::WidgetTypeName, &s_ScrollbarFactory},
    {FalagardSlider::WidgetTypeName, &s_SliderFactory},
    {FalagardSpinner::WidgetTypeName, &s_SpinnerFactory},
    {FalagardStaticImage::WidgetTypeName, &s_StaticImageFactory},
    {FalagardStaticText::WidgetTypeName, &s_StaticTextFactory},
    {FalagardSystemButton::WidgetTypeName, &s_SystemButtonFactory},
    {FalagardTabButton::WidgetTypeName, &s_TabButtonFactory},
    {FalagardTabControl::WidgetTypeName, &s_TabControlFactory},
    {FalagardTabPane::WidgetTypeName, &s_TabPaneFactory},
    {FalagardThumb::WidgetTypeName, &s_ThumbFactory},
    {FalagardTitlebar::WidgetTypeName, &s_TitlebarFactory},
    {FalagardTooltip::WidgetTypeName, &s_TooltipFactory},
	

	//----Falagard Ex
    {FalagardActionButton::WidgetTypeName, &s_ActionButtonFactory},
	{FalagardMiniMap::WidgetTypeName, &s_MinimapFactory},
	{FalagardRewardItem::WidgetTypeName, &s_RewardItemFactory},
	{FalagardComplexWindow::ParentWindow::WidgetTypeName, &s_ComplexParentWindowFactory},
	{FalagardComplexWindow::WidgetTypeName, &s_ComplexWindowFactory},
	{FalagardCheckButton::WidgetTypeName, &s_CheckbuttonFactory},
	{FalagardBeHitBoard::WidgetTypeName, &s_BeHitFactory},
	{FalagardSuperTooltip::WidgetTypeName, &s_superTooltipFactory},
	{FalagardSuperTooltip::ResizeText::WidgetTypeName, &s_resizeTextFactory},
	{FalagardMoney::WidgetTypeName, &s_MoneyFactory},
	{FalagardSimpleText::WidgetTypeName, &s_SimpleTextFactory},
	{FalagardDragTitle::WidgetTypeName, &s_dragTitleFactory},
	{FalagardMeshWindow::WidgetTypeName, &s_meshWindowFactory},
	{FalagardBoundWindow::WidgetTypeName, &s_boundWindowFactory},
	{FalagardIMEEditBox::WidgetTypeName, &s_imeEditBoxWindowFactory},
	{FalagardMultiIMEEditBox::WidgetTypeName, &s_multiImeEditBoxWindowFactory},
	{FalagardChatBoard::WidgetTypeName, &s_chatBoardWindowFactory},
	{FalagardChatHistory::WidgetTypeName, &s_chatHistoryWindowFactory},
	{FalagardChatHistory::ParentWindow::WidgetTypeName, &s_chatHistoryParentWindowFactory},
	{FalagardChatChannel::WidgetTypeName, &s_chatChannelWindowFactory},
	{FalagardSuperProgress::WidgetTypeName, &s_SuperProgressFactory},
	{FalagardSceneMap::WidgetTypeName, &s_ScenemapFactory},
	{FalagardWorldMap::WidgetTypeName, &s_WorldMapFactory},
	{FalagardInfoList::WidgetTypeName, &s_InfoListFactory},
	{FalagardCreatureBoard::WidgetTypeName, &s_CreatureBoardFactory},
	{FalagardStopWatch::WidgetTypeName, &s_StopWatchFactory},
	{FalagardAnimate::WidgetTypeName, &s_AnimateFactory},
	{FalagardSelfFitWindow::WidgetTypeName, &s_SelfFitFactory},
	{FalagardPaoPao::WidgetTypeName, &s_PaoPaoFactory},
	{FalagardSoftKeyBoard::WidgetTypeName, &s_SoftKeyFactory},
	{FalagardRadar::WidgetTypeName, &s_RadarFactory},
    {FalagardStar::WidgetTypeName, &s_StarFactory},
    {FalagardAnimateImage::WidgetTypeName, &s_AnimateImageFactory},
    {FalagardAnimateButton::WidgetTypeName, &s_AnimateButtonFactory},
    {FalagardSafeIMEEditBox::WidgetTypeName, &s_SafeIMEEditBoxFactory},
    // CYS-HUD
    {FalagardNotSuperList::WidgetTypeName, &s_NotSuperListFactory},
    {FalagardNotSuperListItem::WidgetTypeName, &s_NotSuperListItemFactory},
    {FalagardListBoxEx::WidgetTypeName, &s_ListBoxExFactory},
    {FalagardParticleSystem::WidgetTypeName, &s_ParticleSystemFactory},
    {FalagardScrollInfo::WidgetTypeName, &s_ScrollInfoFactory},
    {FalagardScrollInfoFixed::WidgetTypeName, &s_ScrollInfoFixedFactory},
    {FalagardAchievementWindow::WidgetTypeName, &s_AchievementWindowFactory},
    {FalagardDragDropTarget::WidgetTypeName, &s_DragDropTargetFactory},
    {FalagardDragContainer::WidgetTypeName, &s_DragContainerFactory},
    {FalagardSuperBarButton::WidgetTypeName, &s_SuperBarButtonFactory},
    {FalagardTripperTooltip::WidgetTypeName, &s_TripperTooltipFactory},
    // CYS-CYGUI
    {FalagardMeshWindowParentWindow::WidgetTypeName, &s_CyMeshWindowParentFactory},
    {FalagardActionButtonWindow::WidgetTypeName, &s_CyActionButtonWindowFactory},
    {FalagardEventsWindow::WidgetTypeName, &s_CyEventsWindowFactory},
    {FalagardActionButtonItem::WidgetTypeName, &s_CyActionButtonItemFactory},
    {FalagardGuildButton::WidgetTypeName, &s_CyGuildButtonFactory},
    {FalagardAchievementBarWindowButton::WidgetTypeName, &s_CyAchvBarButtonFactory},
    {FalagardAchievementBarCompareWindowButton::WidgetTypeName, &s_CyAchvBarCompareButtonFactory},
    {FalagardAchievementBarCompareWindowIntegrationButton::WidgetTypeName, &s_CyAchvBarCompareIntegrationFactory},
    {FalagardAchievementWindowCatalogButton::WidgetTypeName, &s_CyAchvCatalogButtonFactory},
    {FalagardAchievementWindowTextButton::WidgetTypeName, &s_CyAchvTextButtonFactory},
    {FalagardMultiColumnListNew::WidgetTypeName, &s_CyMultiColumnListNewFactory},
    {FalagardMultiColumnListEx::WidgetTypeName, &s_CyMultiColumnListExFactory},
    {FalagardScrollText::WidgetTypeName, &s_CyScrollTextFactory},
    {FalagardDragCornerButton::WidgetTypeName, &s_CyDragCornerButtonFactory},
    {FalagardPhoneSoftKeyBoard::WidgetTypeName, &s_CyPhoneSoftKeyFactory},
    {FalagardSFZSoftKeyBoard::WidgetTypeName, &s_CySFZSoftKeyFactory},
    {FalagardStaticUVImage::WidgetTypeName, &s_CyStaticUVImageFactory},
    {FalagardCircleProgress::WidgetTypeName, &s_CyCircleProgressFactory},
	//----Falagard Ex

    {0,0}
};

/*************************************************************************
	Plugin access interface
*************************************************************************/
extern "C" void registerFactory(const CEGUI::String& type_name)
{
    mapEntry* entry = factoriesMap;

    while (entry->d_name)
    {
        if (entry->d_name == type_name)
        {
            doSafeFactoryRegistration(entry->d_factory);
            cysRegisterStoredProperties(); // CYS-HUD: GL layout properties accepted on the registered factories
            return;
        }

        ++entry;
    }

    throw UnknownObjectException((utf8*)"::registerFactory - The window factory for type '" + type_name + "' is not known in this module.");
}

extern "C" CEGUI::uint registerAllFactories(void)
{
    CEGUI::uint count = 0;
    mapEntry* entry = factoriesMap;

    while (entry->d_name)
    {
		doSafeFactoryRegistration(entry->d_factory);

        ++entry;
        ++count;
    }
    cysRegisterStoredProperties(); // CYS-HUD: GL layout properties accepted on the registered factories

    return count;
}

void doSafeFactoryRegistration(WindowFactory* factory)
{
	assert(factory != 0);

	WindowFactoryManager& wfm = WindowFactoryManager::getSingleton();

	// is this factory is already registered
	if (wfm.isFactoryPresent(factory->getTypeName()))
	{
		// log the fact that this type already appears to be registered
		Logger::getSingleton().logEvent(
			"Falagard widget factory '" + factory->getTypeName() + "' appears to be already registered, skipping.",
			Informative);
	}
	// factory not already registered,
	else
	{
		// add this factory to those available
		wfm.addFactory(factory);
	}
}
