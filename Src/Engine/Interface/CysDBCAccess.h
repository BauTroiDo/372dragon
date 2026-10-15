// CysDBCAccess.h
// CYS: accessors for client_GL DBC records whose 0.85 member arrays are no longer contiguous columns.
// CYS: Include after TDDBC_Struct.h (StdAfx). Evidence per column: Registry/abi/dbc_inventory_gl.json.
#pragma once

// CYS: 0.85 read ItemVisualChar as pVisualEntity[race*2+part] (part 0 = mesh, 1 = material). client_GL stores race 0
// CYS: (female) in columns 1/2 and race 1 (male) in columns 12/13, with nine dye materials after each pair.
inline LPCSTR CysItemVisualEntity(const _DBC_ITEM_VISUAL_CHAR* pVisual, INT nRace, INT nPart)
{
	if(pVisual == NULL) return "";
	LPCSTR pValue = (nRace == 0) ? (nPart == 0 ? pVisual->pMeshFile_Race0 : pVisual->pMatName_Race0)
								 : (nPart == 0 ? pVisual->pMeshFile_Race1 : pVisual->pMatName_Race1);
	return pValue ? pValue : "";
}

// CYS-DRESS: material of a fashion outfit for one dye slot. EquipDress column 5 holds the slot: 1 means the row's
// CYS-DRESS: base material (ItemVisualChar column 2 female / 13 male) and 2..10 select pDyeMat_RaceN[slot-2]
// CYS-DRESS: (columns 3..11 / 14..22). Measured on CY data: a nine-row dye group (EquipDress 33/63..70 -> IVC 284)
// CYS-DRESS: maps slot 1 -> "女主角时装清凉", slot 2 -> "...清凉1" ... slot 9 -> "...清凉8". An empty dye column
// CYS-DRESS: falls back to the base material, which is what the 441 single-slot outfits need.
inline LPCSTR CysDressMaterial(const _DBC_ITEM_VISUAL_CHAR* pVisual, INT nRace, INT nDyeSlot)
{
	if(pVisual == NULL) return "";
	LPCSTR pBase = CysItemVisualEntity(pVisual, nRace, 1);
	if(nDyeSlot < 2) return pBase;
	const INT nIndex = nDyeSlot - 2;
	if(nIndex < 0 || nIndex >= 9) return pBase;
	LPCSTR pDye = (nRace == 0) ? pVisual->pDyeMat_Race0[nIndex] : pVisual->pDyeMat_Race1[nIndex];
	return (pDye && pDye[0]) ? pDye : pBase;
}

// CYS-CY: CY 3.71 PlayerExpLevel.txt column 1 is a STRING (decimal); client_GL had INT. Values above INT_MAX clamp.
inline INT CysExpNeed(const _DBC_CHARACTER_EXPLEVEL* pLevel)
{
	if(pLevel == NULL || pLevel->szExpNeed == NULL || pLevel->szExpNeed[0] == '\0') return -1;
	const __int64 nValue = _strtoi64(pLevel->szExpNeed, NULL, 10);
	if(nValue > 0x7FFFFFFF) return 0x7FFFFFFF;
	return (nValue < 0) ? -1 : (INT)nValue;
}

// CYS: GemInfo attribute value by ITEM_ATTRIBUTE index. client_GL inserts 降低目标冰/火/玄/毒抵抗 (4 columns)
// CYS: between attribute 53 and the base attributes 54..59; -1 means "no such attribute".
inline INT CysGemAttr(const _DBC_ITEM_GEM* pGem, INT nAttr)
{
	if(pGem == NULL || nAttr < 0) return -1;
	if(nAttr < 54) return pGem->nAttr[nAttr];
	if(nAttr < 60) return pGem->nBaseAttr[nAttr - 54];
	return -1;
}
