/****************************************************************************************\
*  CYS-CRTGUARD 20/09/2026                                                               *
*                                                                                        *
*  Lop loi CRT "chet khong de lai dau vet".                                              *
*                                                                                        *
*  Do duoc (Build\Logs\2026-09-20-crt-guard):                                            *
*    - UCRT (ban dung cua du an) va msvcr110 (CRT ma CY 3.71 that su nap) DEU goi        *
*      __fastfail(FAST_FAIL_INVALID_ARG) = `int 29h` khi mot tham so CRT khong hop le     *
*      (vi du `%n` trong chuoi dinh dang). `int 29h` KHONG di qua SEH, nen                *
*      `__except` o `_tWinMain` KHONG bao gio thay no: khong unwind, khong bao cao,       *
*      khong minidump. Tien trinh bien mat voi exit code 0xC0000409.                      *
*    - CY 3.71 CUNG KHONG cai handler (do tren `Bin64\Game.exe` sha 9278c7f3..., hai      *
*      phep dem doc lap: bang import COFF va byte tho). Nen day KHONG phai "tro lai       *
*      giong CY" - day la mot buoc DI XA HON CY, va ly do la chan doan.                   *
*                                                                                        *
*  Cai mot invalid-parameter handler bien ca lop do thanh "co log + co minidump".         *
*  Handler nay KHONG NUOT IM LANG: moi diem goi moi deu ghi it nhat mot dong log          *
*  (mau `static std::set` cua ef3c2b9e), va cac lan dau tien con sinh du bo ba            *
*  WXC_*.txt / WXC_*.detail.txt / WXC_*.dmp qua dung duong CYS-CRASHRPT san co.           *
*                                                                                        *
*  Bien moi truong CYS_CRTGUARD (doc mot lan luc cai):                                    *
*    "0"          -> KHONG cai gi ca. Day la NHANH DOI CHUNG cua phep A/B: cung mot       *
*                    binary, mot bien so duy nhat.                                        *
*    khong dat/"1"-> cai; khi no ra: ghi log + minidump roi TRA VE, nen loi goi CRT       *
*                    that bai co kiem soat (vi du `_vsnprintf` tra -1, chuoi bi cat)      *
*                    thay vi giet tien trinh.                                             *
*    "2"          -> cai; ghi log + minidump roi RaiseException(0xC0000417) de tien trinh *
*                    van chet, nhung chet QUA duong SEH co san (co bao cao day du).       *
\****************************************************************************************/
#pragma once

#include "TDBasicType.h"

// Cai handler. Goi CANG SOM CANG TOT trong _tWinMain, truoc moi thu khac.
// Tra ve so handler da cai duoc (0 = tat bang CYS_CRTGUARD=0, hoac cai that bai).
INT CysCrtGuard_Install(VOID);

// TRUE neu handler dang duoc cai (dung cho dong log khoi dong va cho phep kiem).
BOOL CysCrtGuard_IsArmed(VOID);

// So lan handler da no ra trong phien nay (dung cho phep kiem, khong dung cho logic game).
INT CysCrtGuard_HitCount(VOID);

// ---------------------------------------------------------------------------------------
// Dem dac ta cua mot chuoi dinh dang.
//
// `printf-fix` (20/09) da dua so o du lieu nguy hiem ve 0, nhung cua `SrvMsg` van mo: SERVER
// TUY Y DAT TEN KHOA, client nhet thang vao `_vsnprintf` MA KHONG DEM DAC TA. Hai ham duoi
// day la phan dem con thieu, dung chung cho moi cho can no.
// ---------------------------------------------------------------------------------------

// So DOI SO ma chuoi dinh dang nay se DOC. `%%` khong tinh; `*` (be rong/do chinh xac lay
// tu doi so) duoc cong them. Tra ve 0 cho chuoi rong / NULL.
INT CysFmt_CountArgs(LPCSTR szFmt);

// TRUE neu chuoi dinh dang chua `%n` - dac ta GIET TIEN TRINH (UCRT vo hieu hoa no va goi
// invalid-parameter; mac dinh la __fastfail, khong SEH, khong minidump). `%n` khong bao gio
// hop le trong mot chuoi giao dien, nen cho phep chan cung.
BOOL CysFmt_HasFatal(LPCSTR szFmt);

// DOI CHUNG DUONG. Chi chay khi dong lenh co `-cys-crt-selftest=<che do>`:
//    n  -> `%n`  : lop GIET TIEN TRINH (0xC0000409) khi chua vá
//    s  -> `%s`  : doc con tro rac
//    d  -> `%d`  : chi in ra rac
// Binh thuong KHONG BAO GIO chay. Tra ve TRUE neu da chay mot phep thu.
BOOL CysCrtGuard_SelfTestFromCmdLine(LPCSTR szCmdLine);
