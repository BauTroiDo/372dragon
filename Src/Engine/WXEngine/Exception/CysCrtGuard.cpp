/****************************************************************************************\
*  CYS-CRTGUARD 20/09/2026 - xem Engine/Interface/CysCrtGuard.h cho ly do va so do do.    *
\****************************************************************************************/
#include "StdAfx.h"
#include "CysCrtGuard.h"
#include "TDCrashReport.h"
#include "TDUtil.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <set>
#include <windows.h>

#ifndef STATUS_INVALID_CRUNTIME_PARAMETER
#define STATUS_INVALID_CRUNTIME_PARAMETER  ((DWORD)0xC0000417L)
#endif

// --------------------------------------------------------------------------------------
// Che do lam viec, doc MOT LAN luc cai (khong doc lai giua chung de mot lan chay chi co
// dung mot hanh vi - neu khong thi khong con la A/B mot bien so nua).
// --------------------------------------------------------------------------------------
enum CysCrtGuardMode
{
	CYS_CRTGUARD_OFF      = 0,	// khong cai gi ca (nhanh doi chung)
	CYS_CRTGUARD_CONTINUE = 1,	// ghi log + minidump roi tra ve (loi goi CRT that bai co kiem soat)
	CYS_CRTGUARD_FATAL    = 2	// ghi log + minidump roi chet QUA duong SEH co san
};

static CysCrtGuardMode	g_CysCrtGuardMode   = CYS_CRTGUARD_CONTINUE;
static BOOL				g_bCysCrtGuardArmed = FALSE;
static LONG				g_nCysCrtGuardHits  = 0;
static LONG				g_nCysCrtGuardDumps = 0;

// Toi da bao nhieu bo ba bao cao duoc sinh trong mot phien. Moi diem goi MOI van luon
// duoc ghi MOT dong log; gioi han nay chi chan viec ghi hang tram minidump 60 MB.
#define CYS_CRTGUARD_MAX_DUMPS	3

// Chong de quy: mot loi CRT xay ra BEN TRONG handler (TDU_Log cung dung _vsnprintf) khong
// duoc phep goi lai handler. Dem theo TUNG LUONG, khong phai toan cuc, vi hai luong co the
// cung no ra.
static DWORD g_dwCysCrtGuardTls = TLS_OUT_OF_INDEXES;

// --------------------------------------------------------------------------------------
// Mau `static std::set` cua ef3c2b9e: moi diem goi ghi log DUNG MOT LAN, nhung KHONG BAO
// GIO im lang hoan toan. Khoa la ba dia chi trả về dau tien - du de phan biet cac chuoi
// dinh dang khac nhau ma khong phinh vo han.
// --------------------------------------------------------------------------------------
struct CysCrtSiteKey
{
	ULONG_PTR a, b, c;
	bool operator<(const CysCrtSiteKey& o) const
	{
		if(a != o.a) return a < o.a;
		if(b != o.b) return b < o.b;
		return c < o.c;
	}
};

static CysCrtSiteKey CysCrtCaptureSite(PVOID* pFrames, USHORT nWant, USHORT* pnGot)
{
	CysCrtSiteKey key = {0, 0, 0};
	USHORT n = ::RtlCaptureStackBackTrace(1, nWant, pFrames, NULL);
	if(pnGot) *pnGot = n;
	if(n > 0) key.a = (ULONG_PTR)pFrames[0];
	if(n > 1) key.b = (ULONG_PTR)pFrames[1];
	if(n > 2) key.c = (ULONG_PTR)pFrames[2];
	return key;
}

// "<ten module>+0x<RVA>" - dung dung dinh dang ma CYS-CRASHRPT 19/09 da chon, de dan
// thang vao llvm-symbolizer duoc.
static VOID CysCrtFormatAddr(ULONG_PTR addr, CHAR* szOut, size_t nOut)
{
	szOut[0] = 0;
	if(!addr) { _snprintf(szOut, nOut - 1, "<null>"); szOut[nOut - 1] = 0; return; }

	HMODULE hMod = NULL;
	if(::GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
			(LPCSTR)addr, &hMod) && hMod)
	{
		CHAR szPath[MAX_PATH] = {0};
		if(::GetModuleFileNameA(hMod, szPath, MAX_PATH))
		{
			const CHAR* szBase = strrchr(szPath, '\\');
			szBase = szBase ? (szBase + 1) : szPath;
			_snprintf(szOut, nOut - 1, "%s+0x%llX", szBase,
				(unsigned __int64)(addr - (ULONG_PTR)hMod));
			szOut[nOut - 1] = 0;
			return;
		}
	}
	_snprintf(szOut, nOut - 1, "0x%016llX", (unsigned __int64)addr);
	szOut[nOut - 1] = 0;
}

// --------------------------------------------------------------------------------------
// Sinh du bo ba bao cao (WXC_*.txt tom tat + WXC_*.detail.txt ngan xep + WXC_*.dmp) tu
// mot ngu canh TU DUNG. Day KHONG phai mot ngoai le SEH that, nen phai dung
// RtlCaptureContext + mot EXCEPTION_RECORD tu dung; ca ba ham cua TDCrashReport chi doc
// ExceptionRecord/ContextRecord nen chung hoat dong binh thuong.
// --------------------------------------------------------------------------------------
static VOID CysCrtWriteReport(ULONG_PTR addrSite)
{
	CONTEXT ctx;
	::RtlCaptureContext(&ctx);

	EXCEPTION_RECORD rec;
	::ZeroMemory(&rec, sizeof(rec));
	rec.ExceptionCode    = STATUS_INVALID_CRUNTIME_PARAMETER;
	rec.ExceptionFlags   = 0;
	rec.ExceptionAddress = (PVOID)addrSite;
	rec.NumberParameters = 0;

	EXCEPTION_POINTERS ep;
	ep.ExceptionRecord = &rec;
	ep.ContextRecord   = &ctx;

	UINT dwLastError = ::GetLastError();

	TCHAR szSmall[MAX_PATH] = {0};
	TCHAR szBig[MAX_PATH]   = {0};
	TCHAR szDump[MAX_PATH]  = {0};

	CreateSmallDumpInfo(&ep, szSmall, dwLastError);
	CreateBigInfoFile(&ep, szBig, dwLastError);
	CreateDumpHelpFile(&ep, szDump);

	// In duong dan tuyet doi cua ca ba vao WXClient.log. Bai hoc 18/09: mot bo ba khong
	// duoc goi ten thi coi nhu khong ton tai.
	CysReportCrashArtifacts();
}

// --------------------------------------------------------------------------------------
// Handler
// --------------------------------------------------------------------------------------
static VOID __cdecl CysCrtInvalidParameter(const wchar_t* expression,
                                           const wchar_t* function,
                                           const wchar_t* file,
                                           unsigned int   line,
                                           uintptr_t      pReserved)
{
	(VOID)pReserved;

	// --- chong de quy theo luong
	if(g_dwCysCrtGuardTls != TLS_OUT_OF_INDEXES)
	{
		if(::TlsGetValue(g_dwCysCrtGuardTls) != NULL)
			return;					// da o trong handler - thoat im lang, day la ngoai le DUY NHAT
		::TlsSetValue(g_dwCysCrtGuardTls, (LPVOID)1);
	}

	const LONG nHit = ::InterlockedIncrement(&g_nCysCrtGuardHits);

	PVOID  frames[8] = {0};
	USHORT nFrames   = 0;
	const CysCrtSiteKey key = CysCrtCaptureSite(frames, 8, &nFrames);

	// Diem goi nay da thay bao gio chua?
	static std::set<CysCrtSiteKey>* s_pSeen = NULL;
	BOOL bNewSite = TRUE;
	try
	{
		if(!s_pSeen) s_pSeen = new std::set<CysCrtSiteKey>();
		bNewSite = (s_pSeen->insert(key).second) ? TRUE : FALSE;
	}
	catch(...)
	{
		bNewSite = TRUE;			// het bo nho -> coi nhu moi, tha ghi thua con hon im lang
	}

	// Trong ban Release cua UCRT, ba con tro expression/function/file deu la NULL (thong tin
	// do chi co o CRT Debug). Ghi ra khi co, va noi ro khi khong co - khong de nguoi doc sau
	// nay tuong la phep do hong.
	CHAR szExpr[256] = {0};
	CHAR szFunc[128] = {0};
	CHAR szFile[MAX_PATH] = {0};
	if(expression) ::WideCharToMultiByte(CP_ACP, 0, expression, -1, szExpr, sizeof(szExpr) - 1, NULL, NULL);
	if(function)   ::WideCharToMultiByte(CP_ACP, 0, function,   -1, szFunc, sizeof(szFunc) - 1, NULL, NULL);
	if(file)       ::WideCharToMultiByte(CP_ACP, 0, file,       -1, szFile, sizeof(szFile) - 1, NULL, NULL);

	CHAR szF0[160] = {0}, szF1[160] = {0}, szF2[160] = {0};
	CysCrtFormatAddr(key.a, szF0, sizeof(szF0));
	CysCrtFormatAddr(key.b, szF1, sizeof(szF1));
	CysCrtFormatAddr(key.c, szF2, sizeof(szF2));

	if(bNewSite)
	{
		TDU_Log("CYS-CRTGUARD: tham so CRT khong hop le (lan %ld, DIEM GOI MOI). "
		        "Khong co handler thi day la __fastfail 0xC0000409 - chet khong minidump.",
		        (long)nHit);
		TDU_Log("CYS-CRTGUARD:   expr=[%s] func=[%s] file=[%s] line=%u  "
		        "(rong = CRT Release khong giu thong tin nay, KHONG phai phep do hong)",
		        szExpr[0] ? szExpr : "", szFunc[0] ? szFunc : "", szFile[0] ? szFile : "",
		        (unsigned)line);
		TDU_Log("CYS-CRTGUARD:   ngan xep: %s <- %s <- %s  (frames=%u)",
		        szF0, szF1, szF2, (unsigned)nFrames);
	}
	else
	{
		// Da thay diem goi nay roi -> van ghi mot dong ngan. "Nuot im lang la tao ra lop
		// loi ke tiep" (1eb6858a nam im 5 ngay vi TDAssert khong ghi log).
		TDU_Log("CYS-CRTGUARD: tham so CRT khong hop le (lan %ld, diem goi da biet %s)",
		        (long)nHit, szF0);
	}

	if(bNewSite && ::InterlockedIncrement(&g_nCysCrtGuardDumps) <= CYS_CRTGUARD_MAX_DUMPS)
	{
		CysCrtWriteReport(key.a);
	}

	if(g_CysCrtGuardMode == CYS_CRTGUARD_FATAL)
	{
		if(g_dwCysCrtGuardTls != TLS_OUT_OF_INDEXES)
			::TlsSetValue(g_dwCysCrtGuardTls, NULL);
		// Chet, nhung chet QUA SEH: __except o _tWinMain se bat duoc va chay not bao cao.
		::RaiseException(STATUS_INVALID_CRUNTIME_PARAMETER, 0, 0, NULL);
		return;
	}

	if(g_dwCysCrtGuardTls != TLS_OUT_OF_INDEXES)
		::TlsSetValue(g_dwCysCrtGuardTls, NULL);
	// Tra ve => loi goi CRT that bai co kiem soat (vi du _vsnprintf tra -1, errno=EINVAL).
}

// `pure virtual function called` cung la mot duong chet cua CRT khong qua SEH.
static VOID __cdecl CysCrtPureCall(VOID)
{
	TDU_Log("CYS-CRTGUARD: _purecall - goi ham ao thuan tuy. Sinh bao cao roi de chet.");
	PVOID  frames[8] = {0};
	USHORT nFrames   = 0;
	const CysCrtSiteKey key = CysCrtCaptureSite(frames, 8, &nFrames);
	CysCrtWriteReport(key.a);
	::RaiseException(STATUS_INVALID_CRUNTIME_PARAMETER, 0, 0, NULL);
}

// --------------------------------------------------------------------------------------
INT CysCrtGuard_Install(VOID)
{
	CHAR szMode[16] = {0};
	const DWORD n = ::GetEnvironmentVariableA("CYS_CRTGUARD", szMode, sizeof(szMode) - 1);
	if(n > 0 && n < sizeof(szMode))
	{
		if(szMode[0] == '0')      g_CysCrtGuardMode = CYS_CRTGUARD_OFF;
		else if(szMode[0] == '2') g_CysCrtGuardMode = CYS_CRTGUARD_FATAL;
		else                      g_CysCrtGuardMode = CYS_CRTGUARD_CONTINUE;
	}

	if(g_CysCrtGuardMode == CYS_CRTGUARD_OFF)
	{
		TDU_Log("CYS-CRTGUARD: TAT (CYS_CRTGUARD=0). Mot tham so CRT khong hop le se goi "
		        "__fastfail 0xC0000409: KHONG log, KHONG minidump. Day la nhanh doi chung.");
		g_bCysCrtGuardArmed = FALSE;
		return 0;
	}

	if(g_dwCysCrtGuardTls == TLS_OUT_OF_INDEXES)
		g_dwCysCrtGuardTls = ::TlsAlloc();

	INT nInstalled = 0;
	_set_invalid_parameter_handler(CysCrtInvalidParameter);
	++nInstalled;
	_set_purecall_handler(CysCrtPureCall);
	++nInstalled;

	g_bCysCrtGuardArmed = TRUE;
	TDU_Log("CYS-CRTGUARD: ARM=%d che do=%s. Tu day mot tham so CRT khong hop le se ghi log "
	        "+ sinh WXC_*.txt/.detail.txt/.dmp thay vi bien mat (0xC0000409).",
	        nInstalled,
	        (g_CysCrtGuardMode == CYS_CRTGUARD_FATAL) ? "2/chet-qua-SEH" : "1/chay-tiep");
	return nInstalled;
}

BOOL CysCrtGuard_IsArmed(VOID) { return g_bCysCrtGuardArmed; }
INT  CysCrtGuard_HitCount(VOID) { return (INT)g_nCysCrtGuardHits; }

// --------------------------------------------------------------------------------------
// Dem dac ta. Mot bo phan tich printf toi thieu nhung DU:
//     % [co] [be rong | *] [. do chinh xac | . *] [bo dai] <chu chuyen doi>
// Quy tac giu dung theo UCRT:
//   - "%%" khong doc doi so nao;
//   - moi "*" doc them MOT doi so (int);
//   - cac chu chuyen doi doc doi so: d i o u x X e E f F g G a A c C s S p n Z;
//   - "%" di truoc mot byte KHONG phai dac ta hop le (vi du byte dau UTF-8 cua chu Han,
//     hoac dau cach) thi KHONG thanh dac ta - dung dung co che ma `printf-fix` dua vao.
// --------------------------------------------------------------------------------------
static const CHAR* CysFmt_ScanOne(const CHAR* p, INT* pnArgs, BOOL* pbFatal)
{
	// p tro vao ky tu NGAY SAU dau '%'
	if(*p == '%') return p + 1;					// "%%" - khong doi so

	const CHAR* q = p;
	while(*q == '-' || *q == '+' || *q == ' ' || *q == '#' || *q == '0') ++q;	// co
	if(*q == '*') { ++(*pnArgs); ++q; }
	else while(*q >= '0' && *q <= '9') ++q;										// be rong
	if(*q == '.')
	{
		++q;
		if(*q == '*') { ++(*pnArgs); ++q; }
		else while(*q >= '0' && *q <= '9') ++q;									// do chinh xac
	}
	// bo dai
	if(*q == 'I')
	{
		++q;
		if(q[0] == '6' && q[1] == '4') q += 2;
		else if(q[0] == '3' && q[1] == '2') q += 2;
	}
	else if(*q == 'h' || *q == 'l')
	{
		const CHAR c = *q; ++q;
		if(*q == c) ++q;						// hh / ll
	}
	else if(*q == 'L' || *q == 'w' || *q == 'z' || *q == 't' || *q == 'j') ++q;

	const CHAR conv = *q;
	if(conv == 0) return q;						// "%" o cuoi chuoi - khong phai dac ta

	if(conv == 'n')
	{
		if(pbFatal) *pbFatal = TRUE;
		++(*pnArgs);
		return q + 1;
	}
	if(strchr("diouxXeEfFgGaAcCsSpZ", conv) != NULL)
	{
		++(*pnArgs);
		return q + 1;
	}
	// Khong phai dac ta hop le => "%" chi la mot dau phan tram binh thuong. KHONG cong doi so,
	// va quay lai ngay sau dau '%' de khong nuot mat ky tu.
	*pnArgs += 0;
	return p;
}

INT CysFmt_CountArgs(LPCSTR szFmt)
{
	if(!szFmt) return 0;
	INT nArgs = 0;
	BOOL bFatal = FALSE;
	for(const CHAR* p = szFmt; *p; )
	{
		if(*p != '%') { ++p; continue; }
		const CHAR* next = CysFmt_ScanOne(p + 1, &nArgs, &bFatal);
		p = (next > p) ? next : (p + 1);
	}
	return nArgs;
}

BOOL CysFmt_HasFatal(LPCSTR szFmt)
{
	if(!szFmt) return FALSE;
	INT nArgs = 0;
	BOOL bFatal = FALSE;
	for(const CHAR* p = szFmt; *p; )
	{
		if(*p != '%') { ++p; continue; }
		const CHAR* next = CysFmt_ScanOne(p + 1, &nArgs, &bFatal);
		if(bFatal) return TRUE;
		p = (next > p) ? next : (p + 1);
	}
	return FALSE;
}

// --------------------------------------------------------------------------------------
// DOI CHUNG DUONG - chi chay khi duoc goi ten tren dong lenh.
// --------------------------------------------------------------------------------------
BOOL CysCrtGuard_SelfTestFromCmdLine(LPCSTR szCmdLine)
{
	if(!szCmdLine) return FALSE;
	const CHAR* p = strstr(szCmdLine, "-cys-crt-selftest=");
	if(!p) return FALSE;
	const CHAR mode = p[strlen("-cys-crt-selftest=")];

	CHAR buf[64];
	::ZeroMemory(buf, sizeof(buf));

	TDU_Log("CYS-CRTGUARD-SELFTEST: bat dau, che do='%c', armed=%d", mode, (int)g_bCysCrtGuardArmed);
	// In trang thai TRUOC, khong chi SAU (ky luat do dem muc 3): neu dong duoi day la dong
	// cuoi cua log thi phep thu da giet tien trinh.
	TDU_Log("CYS-CRTGUARD-SELFTEST: SAP GOI _snprintf. Neu khong co dong nao sau dong nay, "
	        "tien trinh da chet tai day (0xC0000409, khong minidump).");

	int rc = -777;
	switch(mode)
	{
	case 'n':
		{
			// `%n` bi UCRT vo hieu hoa -> invalid parameter -> __fastfail neu khong co handler.
			// Viet tach ra de trinh bien dich khong loai bo / khong canh bao chuoi dinh dang.
			CHAR fmt[8]; fmt[0]='A'; fmt[1]='%'; fmt[2]='n'; fmt[3]='B'; fmt[4]=0;
			int nWritten = 0;
			rc = _snprintf(buf, sizeof(buf) - 1, fmt, &nWritten);
		}
		break;
	case 's':
		{
			CHAR fmt[8]; fmt[0]='A'; fmt[1]='%'; fmt[2]='s'; fmt[3]='B'; fmt[4]=0;
			rc = _snprintf(buf, sizeof(buf) - 1, fmt);		// doi so khong ton tai
		}
		break;
	default:
		{
			CHAR fmt[8]; fmt[0]='A'; fmt[1]='%'; fmt[2]='d'; fmt[3]='B'; fmt[4]=0;
			rc = _snprintf(buf, sizeof(buf) - 1, fmt);		// doi so khong ton tai
		}
		break;
	}

	TDU_Log("CYS-CRTGUARD-SELFTEST: SONG SOT. rc=%d out=[%s] hits=%d",
	        rc, buf, (int)g_nCysCrtGuardHits);
	return TRUE;
}
