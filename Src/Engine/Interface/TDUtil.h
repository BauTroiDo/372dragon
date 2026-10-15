/****************************************\
*										*
*			  工具函数集				*
*										*
\****************************************/
#pragma once

#include "TDBasicType.h"
#include "TDMath.h"

//====================================
//运行Log
void	TDU_Log(LPCSTR pszFmt, ...);

// CYS-WARNSWEEP 19/09: TDU_Log la ham printf tu viet, nen trinh bien dich KHONG kiem
// chuoi dinh dang cua no (da do: C4477 chi phat cho ham CRT; SAL _Printf_format_string_
// tren mot ham nguoi dung KHONG lam C4477 phat trong ban dich thuong, chi trong /analyze).
// Voi -DCYS_FMTCHECK, moi loi goi TDU_Log duoc kem mot loi goi _snprintf trong nhanh CHET
// (0 ? ... : 0) chi de CRT kiem kieu. Khong sinh ma, khong doi hanh vi; chi dung de DO
// (Build\Logs\2026-09-19-warn-sweep). Mac dinh TAT.
#ifdef CYS_FMTCHECK
#include <stdio.h>
#define CYS_FMTCHECK_CALL(...) ((void)(0 ? _snprintf((char*)0, (size_t)0, __VA_ARGS__) : 0))
#define TDU_Log(...) (CYS_FMTCHECK_CALL(__VA_ARGS__), TDU_Log(__VA_ARGS__))
#endif

//====================================
//字符串相关
//将字符串按照关键字分割
INT		TDU_ConvertStringToVector(LPCTSTR strStrintgSource, std::vector< STRING >& vRet, LPCTSTR szKey=_T("\\/"), BOOL bOneOfKey = TRUE, BOOL bIgnoreEmpty = TRUE);

//====================================
//数学相关
#define TDU_PI			(3.1415926535)
#define TDU_MINFLOAT	(1.0E-9)

//取得两点间的距离
FLOAT TDU_GetDist(const fVector2& fvPos1, const fVector2& fvPos2);
FLOAT TDU_GetDist(const fVector3& fvPos1, const fVector3& fvPos2);

//取得两点间的距离平方
FLOAT TDU_GetDistSq(const fVector2& fvPos1, const fVector2& fvPos2);
FLOAT TDU_GetDistSq(const fVector3& fvPos1, const fVector3& fvPos2);

template<class T, class U, class V>	inline void TDU_Clamp(T &v, const U &min, const V &max)
{
	v = (v < min) ? min : v;
	v = (v > max) ? max : v;
}

/*
|
| 求两个向量的点积
|
*/
inline float TDU_DotProduct(const fVector2& vec1, const fVector2& vec2)
{
	return vec1.x * vec2.x + vec1.y * vec2.y;
}

/*
|
|取得从Pos1到Pos2的矢量相对于Y轴的旋转角度, 以z轴为0度
|   
|              ->x
|                  o pos1
|          |       |\
|       z  v       |  \
|                  |    \
|                  |      \
|                  |        o pos2
|
|  Return [0 ~ 2pi)
*/

FLOAT TDU_GetYAngle(const fVector2& fvPos1, const fVector2& fvPos2);


/*
|
|取得从Pos1与Pos2之间的中心点
|        
|             ->x
|                    o pos2
|          |       /    
|       z  v      o <- This point!    
|               /    
|              o 
|             pos1        
|
*/
fVector3 TDU_GetCenter(const fVector3& fvPos1, const fVector3& fvPos2);


/*
|
|取得v1相对于从Pos1与Pos2之间直线的镜像点
|        
|             ->x
|                       o pos2
|        |  v1        /    
|     z  v    \     / 
|                \/     
|               /  \
|              o      \ 
|             pos1      v2  <- This point!    
|
*/
fVector2 TDU_GetReflect(const fVector2& fvPos1, const fVector2& fvPos2, const fVector2& v1);

/*
|
| 从内存中读取一行文本(相当于fgets)
|
*/
const char* TDU_GetLineFromMemory(char* pStringBuf, int nBufSize, const char* pMemory, const char* pDeadEnd);

//检查字符串的非法字符
//返回值：
//TRUE	不含有非法字符
//FALSE	有非法字符
BOOL	TDU_CheckStringValid(const char* pStr);