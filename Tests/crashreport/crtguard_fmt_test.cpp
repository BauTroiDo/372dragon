// CYS-CRTGUARD 20/09/2026 - phep tu kiem cua bo dem dac ta, chay tren CHINH tep nguon se giao
// di (Src\Engine\WXEngine\Exception\CysCrtGuard.cpp duoc bien dich vao day, KHONG phai mot ban
// chep). Xem Timeline\handoff\crt-guard.md muc 4.2.
//
// Gom hai phan:
//   1) bang ca do   - so dac ta phai dem dung, va `%n` phai bi goi ten la GIET TIEN TRINH
//   2) DOI CHUNG AM - hai ky vong CO TINH SAI, de chung minh phep kiem BIET TRUOT
//
// Dung:  Tests\crashreport\build_crtguard_test.cmd  &&  <OUT>\crtguard_fmt_test.exe
#include "stdafx.h"
#include "CysCrtGuard.h"
#include <stdio.h>
#include <string.h>

// ---- stub cho nhung thu CysCrtGuard.cpp can khi link ngoai tuyen -----------------------
// (khong keo ca WXEngine.lib vao: phep kiem nay chi do BO DEM, khong do bo bao cao)
void TDU_Log(LPCSTR pszFmt, ...)
{
	va_list ap; va_start(ap, pszFmt);
	fputs("  [TDU_Log] ", stdout); vprintf(pszFmt, ap); fputc('\n', stdout);
	va_end(ap);
}
BOOL CreateSmallDumpInfo(PEXCEPTION_POINTERS, PTCHAR szOut, UINT) { if(szOut) szOut[0]=0; return FALSE; }
BOOL CreateBigInfoFile  (PEXCEPTION_POINTERS, PTCHAR szOut, UINT) { if(szOut) szOut[0]=0; return FALSE; }
BOOL CreateDumpHelpFile (PEXCEPTION_POINTERS, PTCHAR szOut)       { if(szOut) szOut[0]=0; return FALSE; }
VOID CysReportCrashArtifacts(VOID) {}
HINSTANCE g_hInstance = NULL;
BOOL g_IsFindLuaError = FALSE;
// ---------------------------------------------------------------------------------------

struct Case { const char* fmt; int args; int fatal; const char* note; };

static const Case kCases[] = {
	// --- chuoi lanh
	{ "khong co gi",                        0, 0, "khong dac ta" },
	{ "100%% hoan thanh",                   0, 0, "%% khong doc doi so" },
	{ "%s da danh bai %s",                  2, 0, "hai %s" },
	{ "#H%.2f%%",                           1, 0, "do chinh xac + %% (dong nguon Han that)" },
	{ "da to doi%3drnguoi",                 1, 0, "be rong co dinh" },
	{ "%02d:%02d",                          2, 0, "hai o co co dem 0" },
	{ "%I64d vang",                         1, 0, "bo dai I64 cua MSVC" },
	{ "%-10s|",                             1, 0, "co canh trai" },
	{ "%*d",                                2, 0, "* an them MOT doi so" },
	{ "%.*f",                               2, 0, "do chinh xac * an them mot doi so" },
	{ "%llu",                               1, 0, "bo dai ll" },
	{ "%p",                                 1, 0, "%p doc MOT doi so nhung KHONG giai tham chieu" },
	// --- hai co che ma printf-fix do duoc
	// KY VONG DAU CUA TOI SAI, KHONG PHAI BO DEM SAI: toi viet `mong 0` vi doc thay "50%" la
	// dau phan tram. Nhung `% g` = DAU CACH lam co + chu chuyen doi `g`, nen UCRT coi day la
	// MOT dac ta that va doc MOT doi so - dung co che printf-fix do duoc voi `% p`
	// ("A% pB" + 1 doi so -> rc=18). Da sua ky vong, giu lai ly do.
	{ "50% gia tri",                        1, 0, "`% g` - dac ta THAT (dau cach la co)" },
	{ "giam 50%\xE1\xBB\x9F day",           0, 0, "`%` truoc byte dau UTF-8 -> KHONG phai dac ta" },
	{ "100%#cfff263 thanh cong",            1, 0, "`%#c` - dac ta TAI NAN dinh ma mau" },
	{ "ket thuc bang %",                    0, 0, "`%` o cuoi chuoi" },
	// --- lop GIET TIEN TRINH
	{ "A%nB",                               1, 1, "%n tran" },
	{ "%s roi %n",                          2, 1, "%n nam sau" },
	{ "%-5n",                               1, 1, "%n co co" },
	{ "%ln",                                1, 1, "%n co bo dai" },
};

int main()
{
	int pass = 0, fail = 0;
	printf("== CYS-CRTGUARD crtguard_fmt_test: %d ca ==\n", (int)(sizeof(kCases)/sizeof(kCases[0])));
	for (size_t i = 0; i < sizeof(kCases)/sizeof(kCases[0]); ++i) {
		const Case& c = kCases[i];
		const int a = CysFmt_CountArgs(c.fmt);
		const int f = CysFmt_HasFatal(c.fmt) ? 1 : 0;
		const bool ok = (a == c.args) && (f == c.fatal);
		printf("%-4s args=%d(mong %d) fatal=%d(mong %d)  [%s]  %s\n",
		       ok ? "OK" : "FAIL", a, c.args, f, c.fatal, c.fmt, c.note);
		if (ok) ++pass; else ++fail;
	}

	printf("\n== DOI CHUNG AM (hai ky vong CO Y SAI, phai truot) ==\n");
	int negOk = 0;
	if (CysFmt_CountArgs("%s %s") != 3) { printf("OK   truot dung: \"%%s %%s\" KHONG phai 3 doi so\n"); ++negOk; }
	else                                 printf("FAIL bo dem bao \"%%s %%s\" = 3 doi so\n");
	if (!CysFmt_HasFatal("khong co n nao")) { printf("OK   truot dung: chuoi khong co %%n KHONG bi bao fatal\n"); ++negOk; }
	else                                     printf("FAIL bao fatal oan\n");

	printf("\nKET QUA: %d/%d ca do, %d/2 doi chung am\n", pass, pass+fail, negOk);
	if (fail == 0 && negOk == 2) { printf("SELFTEST OK - va phep kiem BIET TRUOT\n"); return 0; }
	printf("SELFTEST FAIL\n");
	return 1;
}
