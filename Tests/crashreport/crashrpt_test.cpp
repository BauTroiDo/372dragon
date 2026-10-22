


























#include <windows.h>
#include <stdio.h>
#include <string.h>
#include "TDException.h"

// TDCrashReport.cpp pulls Client\WXClient\Global.h, which declares these; the real client
// defines them in WXClient.cpp. The harness supplies its own.
HINSTANCE	g_hInstance = 0;
HWND		g_hMainWnd  = 0;

// volatile + an external sink: the optimiser must not fold the dereference away under /O2.
static volatile unsigned __int64	g_sink = 0;

// A distinctive type so the _ThrowInfo that parameter [2] points at resolves, in this module, to a
// name a reader can recognise - exactly how "_TI2?AVException@Ogre@@" named the real crash's type.
struct CysCrashRptTestThrown { int marker; };

static unsigned __int64 CysWildAddress(const char* szMode)
{
	if (0 == strcmp(szMode, "noncanonical"))	return 0x420C0000420C0698ULL;
	if (0 == strcmp(szMode, "high"))			return 0x00007FF0DEADBEE8ULL;
	if (0 == strcmp(szMode, "write"))			return 0x00007FF0CAFEF008ULL;
	if (0 == strcmp(szMode, "cppthrow"))		return 1;	// no address involved; see below
	return 0;
}

static void CysTouchWildPointer(const char* szMode, unsigned __int64 uAddr)
{
	if (0 == strcmp(szMode, "cppthrow"))
	{
		CysCrashRptTestThrown obj; obj.marker = 0x5A5A;
		throw obj;														// SEH 0xE06D7363
	}
	volatile unsigned __int64* p = (volatile unsigned __int64*)(ULONG_PTR)uAddr;
	if (0 == strcmp(szMode, "write"))	*p = 0x5A5A5A5A5A5A5A5AULL;		// AV, Operate = Write
	else								g_sink = *p;					// AV, Operate = Read
}

int main(int argc, char** argv)
{
	const char* szMode = (argc > 1) ? argv[1] : "noncanonical";
	unsigned __int64 uAddr = CysWildAddress(szMode);
	if (0 == uAddr)
	{
		printf("usage: crashrpt_test.exe [noncanonical|high|write]\n");
		return 2;
	}

	g_hInstance = ::GetModuleHandle(NULL);

	char szExe[MAX_PATH] = {0};
	::GetModuleFileNameA(NULL, szExe, MAX_PATH);
	printf("CYS-CRASHRPT-TEST: module   = %s\n", szExe);
	printf("CYS-CRASHRPT-TEST: base     = 0x%016llX\n", (unsigned __int64)(ULONG_PTR)g_hInstance);
	printf("CYS-CRASHRPT-TEST: mode     = %s\n", szMode);
	printf("CYS-CRASHRPT-TEST: touching = 0x%016llX\n", uAddr);
	fflush(stdout);

	BOOL bHandled = FALSE;
	unsigned __int64 uExcAddr = 0, uDataAddr = 0;
	DWORD dwCode = 0, dwOp = 0;

	__try
	{
		CysTouchWildPointer(szMode, uAddr);
		printf("CYS-CRASHRPT-TEST: FAILED - no exception was raised.\n");
		return 3;
	}
	__except (
		// Record what the OS actually reported, then run the real reporter.
		dwCode    = GetExceptionInformation()->ExceptionRecord->ExceptionCode,
		uExcAddr  = (unsigned __int64)(ULONG_PTR)GetExceptionInformation()->ExceptionRecord->ExceptionAddress,
		dwOp      = (DWORD)GetExceptionInformation()->ExceptionRecord->ExceptionInformation[0],
		uDataAddr = (unsigned __int64)GetExceptionInformation()->ExceptionRecord->ExceptionInformation[1],
		// bRunCrashReport = false: never spawn CrashReport.exe from a test.
		tProcessException(GetExceptionInformation(), false),
		bHandled = TRUE,
		EXCEPTION_EXECUTE_HANDLER)
	{
	}

	if (!bHandled) return 4;

	// Ground truth from the OS, independent of anything the reporter printed. The report is
	// correct only if it reproduces these values in full.
	printf("CYS-CRASHRPT-TEST: OS ExceptionCode     = 0x%08X\n", dwCode);
	printf("CYS-CRASHRPT-TEST: OS ExceptionAddress  = 0x%016llX\n", uExcAddr);
	printf("CYS-CRASHRPT-TEST: OS RVA in module     = 0x%016llX\n",
		uExcAddr - (unsigned __int64)(ULONG_PTR)g_hInstance);
	printf("CYS-CRASHRPT-TEST: OS Operate           = %lu (0 read, 1 write, 8 DEP)\n", (unsigned long)dwOp);
	printf("CYS-CRASHRPT-TEST: OS faulting data addr= 0x%016llX\n", uDataAddr);
	printf("CYS-CRASHRPT-TEST: done.\n");
	return 0;
}
