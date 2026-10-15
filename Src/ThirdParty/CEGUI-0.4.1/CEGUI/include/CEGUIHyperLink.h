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
#ifndef _CEGUIHyperLink_h_
#define _CEGUIHyperLink_h_

#include "CEGUIBase.h"
#include "CEGUIString.h"
#include "CEGUIRect.h"
#include "CEGUIWindow.h"
#include <vector>
#include <map>
// Start of CEGUI namespace section
namespace CEGUI
{
class Window;
const int MAX_CELL_NUM = 256;

struct CEGUIEXPORT HyperLink
{
	String		d_name;
	//	点击区域后，push out的key word

	Rect		d_rectBuf[MAX_CELL_NUM];

	const Window*	d_pOwnerWindow[MAX_CELL_NUM];

	int			d_length;

	void addNewRect(const Window* pOwnerWindow,const Rect newRect)
	{
		// CYS-INFOPARITY 19/09: one cell per VISIBLE GLYPH of every link that shares this key in the current
		// frame (CEGUIFontBase.cpp drawTextLine calls addHyperLink once per glyph; HyperLinkManager merges equal
		// keys into one HyperLink). Before this line the 257th glyph wrote past d_rectBuf into d_pOwnerWindow
		// and then out of the object - silently. Measured 19/09: 63/256 for the busiest StrDictionary row
		// (NJBZ_220816_09, 7 x "[160,159]"), but the bound is per frame, keys collide across quests, and the
		// glyph count grows with the coordinates. Extra glyphs simply stop being clickable.
		if (d_length >= MAX_CELL_NUM) return;

		d_rectBuf[d_length] = newRect;
		d_pOwnerWindow[d_length] = pOwnerWindow;
		d_length++;

	}

	void CleanUp()
	{
		d_name = "";
		d_length = 0;
		for(int i = 0;i < MAX_CELL_NUM;i++)
		{
			Rect newRect(0,0,0,0);
			d_rectBuf[i] = newRect;
			d_pOwnerWindow[i] = NULL;
		}
	}

	bool isInRange(const Window* pOwnerWindow,const Point& position)
	{

		// CYS-INFOPARITY 19/09: only the filled cells. The old loop ran over all 256 and called
		// isCapturedByThis() through the NULL owner of every empty cell (UB that happened to work because the
		// method only compares 'this' with a static).
		for(int i = 0; i < d_length && i < MAX_CELL_NUM; i++)
		{
			if(	(d_rectBuf[i].isPointInRect(position)) &&
//				(pOwnerWindow != NULL) &&
				(d_pOwnerWindow[i] == pOwnerWindow))
				return true;
		}
		return false;
	}

};

}// End of  CEGUI namespace section

#endif	// end of guard _CEGUIHyperLink_h_