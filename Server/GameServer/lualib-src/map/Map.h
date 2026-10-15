

#ifndef __MAP_H__
#define __MAP_H__
#include "stdint.h"
#include <cmath>
#define MAX_ROUTES 1024 * 2
#define MAX_CHAR_PATH_NODE_NUMBER	(16)

extern "C"
{
	struct WORLD_POS
	{
		float m_fX;
		float m_fZ;

		WORLD_POS(void) : m_fX(0.0f), m_fZ(0.0f) {}
		WORLD_POS(float fX, float fZ) : m_fX(fX), m_fZ(fZ) {}
		void CleanUp()
		{
			m_fX = 0.0f;
			m_fZ = 0.0f;
		};
		WORLD_POS &operator=(WORLD_POS const &rhs)
		{
			m_fX = rhs.m_fX;
			m_fZ = rhs.m_fZ;
			return *this;
		}
		bool operator==(WORLD_POS &Ref)
		{
			return (fabs(m_fX - Ref.m_fX) + fabs(m_fZ - Ref.m_fZ)) < 0.0001f;
		}
		bool operator==(const WORLD_POS &Ref)
		{
			return (fabs(m_fX - Ref.m_fX) + fabs(m_fZ - Ref.m_fZ)) < 0.0001f;
		}
	};

	class PathFinder;
	class Map
	{
	public:
		Map();
		~Map();

		void CleanUp();

		bool Load(const char *filename);

		uint32_t CX() { return m_CX; };
		uint32_t CZ() { return m_CZ; };

	private:
		//
		//						(0,m_CZ)	(m_CX,m_CZ)
		//         y  z			    -------------
		//         | /	     	    |			|
		//         |/		        |			|
		//         +-------> x		|			|
		//        					|			|
		//       					|			|
		//                          -------------
		//						 (0,0)	   (m_CX,0)
		//

		uint32_t m_CX;
		uint32_t m_CZ; 

		PathFinder *m_pPathFinder;
	public:
		void VerifyPos(WORLD_POS *Pos)
		{
			Pos->m_fX = Pos->m_fX < 0 ? 0 : Pos->m_fX;
			Pos->m_fZ = Pos->m_fZ < 0 ? 0 : Pos->m_fZ;
			Pos->m_fX = ((Pos->m_fX > (float)m_CX) ? ((float)m_CX - 0.1f) : Pos->m_fX);
			Pos->m_fZ = ((Pos->m_fZ > (float)m_CZ) ? ((float)m_CZ - 0.1f) : Pos->m_fZ);
		};

		PathFinder *GetPathFinder() { return m_pPathFinder; }
		bool IsCanGo(const WORLD_POS &pos, const int nLevel);
		bool FindPath(WORLD_POS *startPt, WORLD_POS *endPos, WORLD_POS *posNode, int &numNode, int nLevel, bool bLine = false, int maxRoute = MAX_ROUTES);
		bool FindEmptyPos(WORLD_POS *pos, const int nLevel);
		bool IsPosLogicValid(const WORLD_POS *pos);
	};
}
#endif
