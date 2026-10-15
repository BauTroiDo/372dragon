///////////////////////////////////////////////////////////////////////////////
// 文件名：CampAndStand.h
// 功能说明：阵营数据表结构
//
// 修改记录：
//
//
//
///////////////////////////////////////////////////////////////////////////////
/** \file CampAndStand.h
*		\brief the defination camp and stand record structure 
*/

#ifndef CAMPANDSTAND_H
#define CAMPANDSTAND_H

#include "Type.h"
#include "TemplateManager.h"

namespace DBC
{
	class DBCFile;
}

namespace Combat_Module
{
	using namespace DBC;
	namespace Camp_Stand
	{
		class CampStandRecord_T
		{
			public:
				enum
				{
					// CYS-CY 14/09 (cs2-world): CY 3.71 keeps the camp relations in ReputationTable.txt with 64 rows
					// (CY Game.exe FUN_140784410 checks the id against 0..0x3f and the matrix at 0x14103e0b8 has 64
					// rows of 0x120 bytes). 0.85/client_GL CampAndStand had IDs 0..15, which fit in this range.
					MAX_ID = 63,
					MAX_SIZE = MAX_ID+1,
					// A reputation score below this is hostile (CY FUN_1407785a0: "score < -159999" -> attack allowed;
					// the hostile cells of the shipped table hold -160000).
					HOSTILE_BELOW = -159999,
				};
				
				CampStandRecord_T();
				~CampStandRecord_T(){};
				BOOL IsInited(VOID) const{return m_bInited;};
				BOOL InitFromDB(const DBCFile* pDB, INT const nRow);
				BOOL StandByCampID(CampID_t const nCampID)const;
			protected:
			private:
				BOOL m_bInited;
				BOOL m_aStands[MAX_SIZE];
		};
	};
};

using namespace Combat_Module;
using namespace Combat_Module::Camp_Stand;
using namespace Combat_Module::Skill_Module;
typedef class TemplateManager_T<CampStandRecord_T> CampAndStandDataMgr_T;

struct _CAMP_DATA;
ENUM_RELATION CalcRelationType( INT nObj1Type, INT nObj2Type, CampAndStandDataMgr_T* pCampAndStandDataMgr );

#endif //CAMPANDSTAND_H
