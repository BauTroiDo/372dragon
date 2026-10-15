#include "PathFinder.h"
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>
#include <stdio.h>
#include <algorithm>

#ifndef __MAP_H__
#include "Map.h"
#endif

#define CAN_GO_EDGE

#define RECURETIMES (MAX_CHAR_PATH_NODE_NUMBER - 1)
#define OFFSETZ 128

PathFinder::PathFinder(Map *owner)
{
	mOwner = owner;
}

bool PathFinder::ReadNavMap(const char *filename, uint32_t &mx, uint32_t &mz)
{
	strcpy(mFileName, filename);
	FILE *fp = fopen(filename, "rb");
	if (NULL == fp)
	{
		return false;
	}

	_NAVMAP_HEAD head;
	fread(&head, sizeof(_NAVMAP_HEAD), 1, fp);

	mWidth = head.width;
	mHeight = head.height;
	mGridSize = 0.5;
	mInvGridSize = 1 / mGridSize;

	mx = (uint32_t)(mWidth * mGridSize);
	mz = (uint32_t)(mHeight * mGridSize);

	mLeftTopx = 0;
	mLeftTopz = 0;

	mMaxNode = mWidth * mHeight;

	mWorld = new _WORLD[mMaxNode];
	mWorkWorld = new _WORLD[mMaxNode];
	mNodes = new _NODES[mMaxNode + 1];

	int size = sizeof(struct _NAVMAP_HEAD);
	for (int j = 0; j < mHeight; j++)
	{
		for (int i = 0; i < mWidth; i++)
		{
			int info;
			fread(&info, size, 1, fp);

			_WORLD *pWorld = mWorld + j * mWidth + i;
			pWorld->state = info;
		}
	}

	mNodes[0].zx = 0;
	mNodes[0].f = 0;
	mNodes[0].g = 0;

	curStep = 0;
	fclose(fp);
	return true;
}

void PathFinder::InitEightDirections()
{
	int n;
	for (n = 0; n < 4; n++)
	{
		DZX[n].costmultiplier = 10;
	}
	for (n = 4; n < 8; n++)
	{
		DZX[n].costmultiplier = 14;
	}

	DZX[0].zx = -mWidth;
	DZX[0].route = 2;

	DZX[1].zx = 1;
	DZX[1].route = 3;

	DZX[2].zx = mWidth;
	DZX[2].route = 0;

	DZX[3].zx = -1;
	DZX[3].route = 1;

	DZX[4].zx = -mWidth + 1;
	DZX[4].route = 6;

	DZX[5].zx = mWidth + 1;
	DZX[5].route = 7;

	DZX[6].zx = mWidth - 1;
	DZX[6].route = 4;

	DZX[7].zx = -mWidth - 1;
	DZX[7].route = 5;
}

PathFinder::~PathFinder()
{
	if (mWorld)
		delete[] mWorld;
	if (mWorkWorld)
		delete[] mWorkWorld;
	if (mNodes)
		delete[] mNodes;
}

void PathFinder::Reset(int startz, int endz)
{
	memcpy((void *)(mWorkWorld + (startz * mWidth)), (void *)(mWorld + (startz * mWidth)), (endz - startz) * mWidth * sizeof(_WORLD));

	mBestFNode = 1;
	mNodes[mBestFNode].zx = mStartzx;
	mNodes[mBestFNode].g = 0;
	mNodes[mBestFNode].f = mNodes[mBestFNode].g + Distance(mStartzx);

	mWorkWorld[mStartzx].route = NO_ROUTE;

	mFreeNode = 1;

	mHeap[0] = EMPTY_NODE;
	mLastHeapLeaf = 1;
	mHeap[mLastHeapLeaf] = mBestFNode;
}

void PathFinder::RemoveRootFromHeap()
{
	mHeap[ROOT_HEAP] = mHeap[mLastHeapLeaf--];

	int k = ROOT_HEAP;
	while (NOTEMPTY_DOWN(k))
	{
		int leftk = LEFT(k);
		int rightk = RIGHT(k);
		int bestk;
		if (NOTEMPTY_DOWN(leftk) && NOTEMPTY_DOWN(rightk))
		{
			if (mNodes[mHeap[leftk]].f < mNodes[mHeap[rightk]].f)
				bestk = leftk;
			else
				bestk = rightk;
		}
		else if (NOTEMPTY_DOWN(leftk))
			bestk = leftk;
		else
			break;

		if (mNodes[mHeap[bestk]].f < mNodes[mHeap[k]].f)
		{
			SwapHeap(k, bestk);
			k = bestk;
		}
		else
			break;
	}
}

void PathFinder::InsertNodeToHeap(uint16_t node)
{
	if (mLastHeapLeaf < MAX_HEAP_LEAFS - 1){
		mLastHeapLeaf++;
		mHeap[mLastHeapLeaf] = node;

		int k = mLastHeapLeaf;
		while (NOTEMPTY_UP(k))
		{
			int parentk = PARENT(k);
			if (NOTEMPTY_UP(parentk))
			{
				if (mNodes[mHeap[k]].f < mNodes[mHeap[parentk]].f)
				{
					SwapHeap(k, parentk);
					k = parentk;
				}
				else
					break;
			}
			else
				break;
		}
	}
}

inline int PathFinder::LEFT(int k)
{
	return k << 1;
}
inline int PathFinder::RIGHT(int k)
{
	return (k << 1) + 1;
}
inline int PathFinder::PARENT(int k)
{
	return (k >> 1);
}
inline bool PathFinder::NOTEMPTY_UP(int k)
{
	return k != 0;
}
inline bool PathFinder::NOTEMPTY_DOWN(int k)
{
	return k <= mLastHeapLeaf;
}

inline void PathFinder::SwapHeap(const int k1, const int k2)
{
	uint16_t tmp = mHeap[k1];
	mHeap[k1] = mHeap[k2];
	mHeap[k2] = tmp;
}

bool PathFinder::FindPath(WORLD_POS *startPt, WORLD_POS *endPt, WORLD_POS *posNode, int &numNode, int nLevel, bool bLine, int maxRoute)
{
	mfStartX = startPt->m_fX;
	mfStartZ = startPt->m_fZ;
	mfEndX = endPt->m_fX;
	mfEndZ = endPt->m_fZ;

	mStartx = (uint16_t)((mfStartX - mLeftTopx) * mInvGridSize);
	mStartz = (uint16_t)((mfStartZ - mLeftTopz) * mInvGridSize);
	mEndx = (uint16_t)((mfEndX - mLeftTopx) * mInvGridSize);
	mEndz = (uint16_t)((mfEndZ - mLeftTopz) * mInvGridSize);
	mStartzx = mStartz * mWidth + mStartx;
	mEndzx = mEndz * mWidth + mEndx;

	numNode = 0;

	mDistance = 0;
	if (bLine)
	{
		if (IsCanGo(mWorld[mStartzx].state, nLevel))
		{
			if (IsStraightLine(mfStartX, mfStartZ, mfEndX, mfEndZ, false, nLevel))
			{
				posNode[numNode++] = WORLD_POS(mfEndX, mfEndZ);
				mDistance = RealDistance(mStartzx, mEndzx);
				return true;
			}
			else
			{
				posNode[numNode++] = mFirstCanGoPos;
				mDistance = RealDistance(mStartzx, (uint16_t)((mFirstCanGoPos.m_fZ - mLeftTopz) * mInvGridSize) * mWidth + (uint16_t)((mFirstCanGoPos.m_fX - mLeftTopx) * mInvGridSize));
				return true;
			}
		}
		else
			return false;
	}

	if (!IsCanGo(mWorld[mStartzx].state, nLevel) || !IsCanGo(mWorld[mEndzx].state, nLevel))
	{
		return false;
	}
	else
	{
		int deltax = abs(mEndx - mStartx);
		int deltaz = abs(mEndz - mStartz);

		// ̫Զ
		if ((deltax + deltaz) > maxRoute)
		{
			mDistance = RealDistance(mStartzx, (uint16_t)((mFirstCanGoPos.m_fZ - mLeftTopz) * mInvGridSize) * mWidth + (uint16_t)((mFirstCanGoPos.m_fX - mLeftTopx) * mInvGridSize));
			return false;
		}

		if (IsStraightLine(mfStartX, mfStartZ, mfEndX, mfEndZ, false, nLevel))
		{
			posNode[numNode++] = WORLD_POS(mfEndX, mfEndZ);
			mDistance = RealDistance(mStartzx, mEndzx);
			return true;
		}

		int minz = std::min(mStartz, mEndz);
		int maxz = std::max(mStartz, mEndz);
		minz = std::max(minz - OFFSETZ, 0);
		maxz = std::min(maxz + OFFSETZ, mHeight - 1);

		Reset(minz, maxz);
		int count = maxRoute;
		do
		{
			mBestFNode = mHeap[ROOT_HEAP];
			_NODES *pparent_node = mNodes + mBestFNode;
			if (pparent_node->zx == mEndzx)
			{
				PackRoute(posNode, numNode, nLevel);
				return true;
			}

			mWorkWorld[pparent_node->zx].state = CLOSED;
			RemoveRootFromHeap();
			for (uint8_t d = 0; d < EIGHT_DIRECTIONS; d++)
			{
				int32_t zx = pparent_node->zx + DZX[d].zx;
				if (zx >= 0 & zx < mMaxNode)
				{
					_WORLD *pworld = mWorkWorld + zx;

					if (pworld->state == UNKNOWN)
					{
						pworld->state = OPEN;
						pworld->route = d;

						mFreeNode++;

						_NODES *pfree_node = mNodes + mFreeNode;
						pfree_node->zx = zx;
						pfree_node->g = pparent_node->g + DZX[d].costmultiplier;
						pfree_node->f = pfree_node->g + Distance(zx);

						InsertNodeToHeap(mFreeNode);
					}
				}
			}

			if (mLastHeapLeaf <= 0)
			{
				posNode[numNode++] = mFirstCanGoPos;
				mDistance = RealDistance(mStartzx, (uint16_t)((mFirstCanGoPos.m_fZ - mLeftTopz) * mInvGridSize) * mWidth + (uint16_t)((mFirstCanGoPos.m_fX - mLeftTopx) * mInvGridSize));
				return true;
			}
		} while (--count > 0);
	}
	return false;
}

inline uint16_t PathFinder::Distance(const uint32_t zx)
{
	return (uint16_t)((abs((int)(zx & (mWidth - 1)) - (int)mEndx) + abs((int)(zx / mWidth) - (int)mEndz)) * 10);
}

inline uint16_t PathFinder::RealDistance(const uint32_t zxFirst, const uint32_t zxSecond)
{
	return (uint16_t)((abs((int)(zxFirst & (mWidth - 1)) - (int)(zxSecond & (mWidth - 1))) + abs((int)(zxFirst / mWidth) - (int)(zxSecond / mWidth))));
}

void PathFinder::PackRoute(WORLD_POS *posNode, int &numNode, int nLevel)
{
	AIROUTE airoute;
	memset(airoute.route, 0, MAX_ROUTES);

	uint32_t zx = mEndzx;
	uint8_t route = NO_ROUTE;

	mGridNum = 0;
	WORLD_POS firstPos;
	mGrids[mGridNum++] = zx;
	mDistance = 0;
	while (zx != mStartzx)
	{
		route = mWorkWorld[zx].route;
		zx += DZX[DZX[route].route].zx;

		int x = zx % mWidth;
		int z = zx / mWidth;

		WORLD_POS goPos;
		goPos.m_fX = mLeftTopx + x * mGridSize + mGridSize / 2;
		goPos.m_fZ = mLeftTopz + z * mGridSize + mGridSize / 2;

		if (IsStraightLine(mfStartX, mfStartZ, goPos.m_fX, goPos.m_fZ, true, nLevel))
		{
			firstPos.m_fX = mLeftTopx + x * mGridSize + mGridSize / 2;
			firstPos.m_fZ = mLeftTopz + z * mGridSize + mGridSize / 2;

			posNode[numNode++] = firstPos;
			mDistance += RealDistance(zx, mGrids[mGridNum - 1]);
			break;
		}
		else
		{
			mGrids[mGridNum++] = zx;
			mDistance += RealDistance(zx, mGrids[mGridNum - 1]);
		}
	}

	if (mGridNum)
	{
		mCallTimes = 0;
		curStep = mGridNum;

		EditAStarPathOpt(firstPos.m_fX, firstPos.m_fZ, posNode, numNode, nLevel);
	}
}

int PathFinder::GetDistance()
{
	return mDistance;
}

bool PathFinder::IsStraightLine(float mAStarBeginPtx, float mAStarBeginPty, float mAStarEndPtx, float mAStarEndPty, bool edit, int nLevel)
{
	int intersecttime = 0;

	WORLD_POS startPt(mAStarBeginPtx, mAStarBeginPty);
	WORLD_POS endPt(mAStarEndPtx, mAStarEndPty);

	int xinc1, yinc1;

	int x1, y1, x2, y2;
	x1 = (int)((startPt.m_fX - mLeftTopx) * mInvGridSize);
	y1 = (int)((startPt.m_fZ - mLeftTopz) * mInvGridSize);
	x2 = (int)((endPt.m_fX - mLeftTopx) * mInvGridSize);
	y2 = (int)((endPt.m_fZ - mLeftTopz) * mInvGridSize);

	float deltax, deltay;
	deltax = (endPt.m_fX - startPt.m_fX) * mInvGridSize;
	deltay = (endPt.m_fZ - startPt.m_fZ) * mInvGridSize;

	mFirstCanGoPos = startPt;
	if (fabs(deltax) >= fabs(deltay))
	{
		float slerp = deltay / deltax;

		if (x2 >= x1)
		{
			xinc1 = 1;

			for (int x = x1 + xinc1; x <= x2; x += xinc1)
			{
				int y = (int)(((mLeftTopx + x * mGridSize - startPt.m_fX) * slerp + startPt.m_fZ - mLeftTopz) * mInvGridSize);

				int index = x + y * mWidth;

				if (!IsCanGo(mWorld[index].state, nLevel) && (edit ? intersecttime++ : 1))
					return false;

				mFirstCanGoPos = WORLD_POS(mLeftTopx + x * mGridSize + mGridSize / 2,
										   mLeftTopz + y * mGridSize + mGridSize / 2);

				index = x - xinc1 + y * mWidth;
				if (!IsCanGo(mWorld[index].state, nLevel) && (edit ? intersecttime++ : 1))
					return false;

				mFirstCanGoPos = WORLD_POS(mLeftTopx + (x - xinc1) * mGridSize + mGridSize / 2,
										   mLeftTopz + y * mGridSize + mGridSize / 2);
			}
		}
		else
		{
			xinc1 = -1;
			for (int x = x1; x >= x2 - xinc1; x += xinc1)
			{
				int y = (int)((startPt.m_fZ + slerp * ((mLeftTopx + x * mGridSize) - startPt.m_fX) - mLeftTopz) * mInvGridSize);

				int index = x + y * mWidth;
				if (!IsCanGo(mWorld[x + y * mWidth].state, nLevel) && (edit ? intersecttime++ : 1))
					return false;

				mFirstCanGoPos = WORLD_POS(mLeftTopx + x * mGridSize + mGridSize / 2,
										   mLeftTopz + y * mGridSize + mGridSize / 2);

				index = x + xinc1 + y * mWidth;
				if (!IsCanGo(mWorld[index].state, nLevel) && (edit ? intersecttime++ : 1))
					return false;

				mFirstCanGoPos = WORLD_POS(mLeftTopx + (x + xinc1) * mGridSize + mGridSize / 2,
										   mLeftTopz + y * mGridSize + mGridSize / 2);
			}
		}
	}
	else
	{
		float slerpInv = deltax / deltay;

		if (y2 >= y1)
		{
			yinc1 = 1;
			for (int y = y1 + yinc1; y <= y2; y += yinc1)
			{
				int x = (int)((((mLeftTopz + y * mGridSize) - startPt.m_fZ) * slerpInv + startPt.m_fX - mLeftTopx) * mInvGridSize);
				int index = x + y * mWidth;
				if (!IsCanGo(mWorld[index].state, nLevel) && (edit ? intersecttime++ : 1))
					return false;

				mFirstCanGoPos = WORLD_POS(mLeftTopx + x * mGridSize + mGridSize / 2,
										   mLeftTopz + y * mGridSize + mGridSize / 2);

				index = x + (y - yinc1) * mWidth;
				if (!IsCanGo(mWorld[index].state, nLevel) && (edit ? intersecttime++ : 1))
					return false;

				mFirstCanGoPos = WORLD_POS(mLeftTopx + x * mGridSize + mGridSize / 2,
										   mLeftTopz + (y - yinc1) * mGridSize + mGridSize / 2);
			}
		}
		else
		{
			yinc1 = -1;
			for (int y = y1; y >= y2 - yinc1; y += yinc1)
			{
				int x = (int)((startPt.m_fX + slerpInv * ((mLeftTopz + y * mGridSize) - startPt.m_fZ) - mLeftTopx) * mInvGridSize);

				int index = x + y * mWidth;
				if (!IsCanGo(mWorld[index].state, nLevel) && (edit ? intersecttime++ : 1))
					return false;

				mFirstCanGoPos = WORLD_POS(mLeftTopx + x * mGridSize + mGridSize / 2,
										   mLeftTopz + y * mGridSize + mGridSize / 2);

				index = x + (y + yinc1) * mWidth;
				if (!IsCanGo(mWorld[index].state, nLevel) && (edit ? intersecttime++ : 1))
					return false;

				mFirstCanGoPos = WORLD_POS(mLeftTopx + x * mGridSize + mGridSize / 2,
										   mLeftTopz + (y + yinc1) * mGridSize + mGridSize / 2);
			}
		}
	}
	return true;
}

void PathFinder::EditAStarPathOpt(float startPtx, float startPty, WORLD_POS *posNode, int &numNode, int nLevel)
{
	if (numNode >= MAX_CHAR_PATH_NODE_NUMBER || mCallTimes++ >= RECURETIMES)
		return;

	for (int i = 0; i < curStep; i++)
	{
		int x = mGrids[i] % mWidth;
		int y = mGrids[i] / mWidth;

		WORLD_POS goPos;
		if (i != 0)
		{
			goPos.m_fX = mLeftTopx + x * mGridSize + mGridSize / 2;
			goPos.m_fZ = mLeftTopz + y * mGridSize + mGridSize / 2;
		}
		else
		{
			goPos = WORLD_POS(mfEndX, mfEndZ);
		}

		if (IsStraightLine(startPtx, startPty, goPos.m_fX, goPos.m_fZ, true, nLevel))
		{
			if (numNode < MAX_CHAR_PATH_NODE_NUMBER)
				posNode[numNode++] = goPos;
			curStep = i;

			break;
		}
	}

	if (curStep)
	{
		int x = mGrids[curStep] % mWidth;
		int y = mGrids[curStep] / mWidth;

		WORLD_POS startPos;
		startPos.m_fX = mLeftTopx + x * mGridSize + mGridSize / 2;
		startPos.m_fZ = mLeftTopz + y * mGridSize + mGridSize / 2;

		EditAStarPathOpt(startPos.m_fX, startPos.m_fZ, posNode, numNode, nLevel);
	}
}

bool PathFinder::IsCanGo(const WORLD_POS &pos, const int nLevel)
{

	int gridx = (uint16_t)((pos.m_fX - mLeftTopx) * mInvGridSize);
	int gridz = (uint16_t)((pos.m_fZ - mLeftTopz) * mInvGridSize);

	if ((gridx >= 0 && gridx < mWidth) && (gridz >= 0 && gridz < mHeight))
		// return mWorld[ gridz * mWidth + gridx].state != IMPASSABLE;
		return IsCanGo(mWorld[gridz * mWidth + gridx].state, nLevel);

	return false;
}

bool PathFinder::IsCanGo(const int state, const int nDriverLevel)
{
	return nDriverLevel >= state;
}
