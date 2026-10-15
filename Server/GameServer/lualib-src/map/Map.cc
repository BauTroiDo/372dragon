#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include "Map.h"
#ifndef __PATHFINDER_H__
#include "PathFinder.h"
#endif

Map::Map()
{
	m_CX = 0;
	m_CZ = 0;

	m_pPathFinder = NULL;
}

Map::~Map()
{
	if (m_pPathFinder){
		delete m_pPathFinder;
	}
}

void Map::CleanUp()
{
	m_CX = 0;
	m_CZ = 0;
	m_pPathFinder = NULL;
}

bool Map::Load(const char *filename)
{
	if (m_pPathFinder == NULL)
	{
		m_pPathFinder = new PathFinder(this);
		if (m_pPathFinder == NULL)
		{
			return false;
		}
		bool ret = m_pPathFinder->ReadNavMap(filename, m_CX, m_CZ);
		if (!ret){
			delete m_pPathFinder;
			m_pPathFinder = NULL;
			return false;
		}
		m_pPathFinder->InitEightDirections();
		return true;
	}
	return false;
}

bool Map::IsCanGo(const WORLD_POS &pos, const int nLevel)
{
	if (m_pPathFinder)
		return m_pPathFinder->IsCanGo(pos, nLevel);

	return false;
}

bool Map::FindPath(WORLD_POS *startPt, WORLD_POS *endPos, WORLD_POS *posNode, int &numNode, int nLevel, bool bLine, int maxRoute)
{
	if(startPt->m_fX > m_CX || startPt->m_fZ > m_CZ)
		return false;
	if(endPos->m_fX > m_CX || endPos->m_fZ > m_CZ)
		return false;
	if (m_pPathFinder)
		return m_pPathFinder->FindPath(startPt, endPos, posNode, numNode, nLevel, bLine, maxRoute);
	return false;
}

bool Map::FindEmptyPos(WORLD_POS *pos, const int nLevel)
{
#define MAX_FIND_SIZE 64

	if (IsCanGo(*pos, nLevel))
		return true;

	for (int i = 0; i < MAX_FIND_SIZE; i++)
	{
		WORLD_POS pTest;

		pTest.m_fX = pos->m_fX + i;
		pTest.m_fZ = pos->m_fZ;
		VerifyPos(&pTest);
		if (IsCanGo(pTest, nLevel))
		{
			*pos = pTest;
			return true;
		}
		pTest.m_fX = pos->m_fX;
		pTest.m_fZ = pos->m_fZ + i;
		VerifyPos(&pTest);
		if (IsCanGo(pTest, nLevel))
		{
			*pos = pTest;
			return true;
		}

		pTest.m_fX = pos->m_fX - i;
		pTest.m_fZ = pos->m_fZ;
		VerifyPos(&pTest);
		if (IsCanGo(pTest, nLevel))
		{
			*pos = pTest;
			return true;
		}
		pTest.m_fX = pos->m_fX;
		pTest.m_fZ = pos->m_fZ - i;
		VerifyPos(&pTest);
		if (IsCanGo(pTest, nLevel))
		{
			*pos = pTest;
			return true;
		}

		pTest.m_fX = pos->m_fX + i;
		pTest.m_fZ = pos->m_fZ + i;
		VerifyPos(&pTest);
		if (IsCanGo(pTest, nLevel))
		{
			*pos = pTest;
			return true;
		}
		pTest.m_fX = pos->m_fX - i;
		pTest.m_fZ = pos->m_fZ - i;
		VerifyPos(&pTest);
		if (IsCanGo(pTest, nLevel))
		{
			*pos = pTest;
			return true;
		}

		pTest.m_fX = pos->m_fX + i;
		pTest.m_fZ = pos->m_fZ - i;
		VerifyPos(&pTest);
		if (IsCanGo(pTest, nLevel))
		{
			*pos = pTest;
			return true;
		}
		pTest.m_fX = pos->m_fX - i;
		pTest.m_fZ = pos->m_fZ + i;
		VerifyPos(&pTest);
		if (IsCanGo(pTest, nLevel))
		{
			*pos = pTest;
			return true;
		}
	}

	return false;
}

bool Map::IsPosLogicValid(const WORLD_POS *pos)
{
	#define VALID_SIZE 10
	if (pos->m_fX < VALID_SIZE || (pos->m_fX + VALID_SIZE) > CX() || pos->m_fZ < VALID_SIZE || (pos->m_fZ + VALID_SIZE) > CZ())
	{
		return false;
	}

	return true;
}
