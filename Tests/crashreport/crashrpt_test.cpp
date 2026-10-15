// CYS-CRASHRPT 19/09/2026 - deliberate-crash harness for the engine crash reporter.
//
// Why this exists: the 18/09 "press Q" crash was chased for three days because
// TDCrashReport.cpp printed 64-bit addresses with "%08X". The report said
// "Address: 0xFFFFFFFF" while the faulting address was 0xFFFFFFFFFFFFFFFF, and the truncated
// value was read as a 32-bit npos index. (Timeline\handoff\qlog-crash.md muc 5.1)
//
// A crash reporter can only be tested by crashing. This harness raises a REAL access violation
// at an address we choose, hands the SEH record to the real tProcessException(), and lets the
// caller diff the files it produced. Run it against the pre-patch sources and it prints the
// truncated address, no module+RVA and no artifact index - i.e. the test knows how to fail.
//
// Modes (argv[1]):
//   noncanonical  read through 0x420C0000420C0698 - the EXACT 18/09 signature: a non-canonical
//                 address raises #GP, and Windows reports AV with data address -1
//                 (0xFFFFFFFFFFFFFFFF). 0x420C0000420C0698 is the real bogus "this" from that
//                 crash: CEGUI Size{35.0f,35.0f} reinterpreted as a pointer, + 0x698.
//   high          read through 0x00007FF0DEADBEE8 - a canonical, unmapped user address whose
//                 upper 32 bits are non-zero. "%08X" prints DEADBEE8 and silently drops 00007FF0;
//                 this is the digit-for-digit truncation proof.
//   write         write through 0x00007FF0CAFEF00D8 & ~7 - proves the Write/Read classification.
//   cppthrow      throw a C++ object => SEH code 0xE06D7363, whose FOUR parameters are the payload
//                 ([0] 0x19930520 EH magic, [1] thrown object, [2] _ThrowInfo, [3] image base).
//                 Added 19/09 after the real scene-1350 crash: the report printed "Code: 0xE06D7363"
//                 and NOTHING else, so naming the thrown C++ type still needed the minidump.
//
// Build: Tests\crashreport\build_test.cmd   (see that file for the A/B against HEAD)
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
