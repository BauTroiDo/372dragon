/* CYS-CRTGUARD probe: do TRUC TIEP tren CRT that (MSVC 2022 /MD, UCRT) - khong suy dien.
 *
 * Cach dung:  crtprobe.exe <che-do>
 *    off-n   : KHONG cai handler, dinh dang co %n   -> ky vong: chet 0xC0000409, khong in duoc dong SAU
 *    on-n    : CO cai handler,    dinh dang co %n   -> ky vong: handler no ra, rc=-1, tien trinh SONG
 *    off-s   : KHONG cai handler, %s thieu doi so   -> ky vong: doc con tro rac (co the AV, co the in rac)
 *    on-d    : CO cai handler,    %d thieu doi so   -> ky vong: in rac, handler KHONG no (doi chung am)
 *    dll-on  : CO cai handler trong EXE, %n duoc goi TU DLL  -> handler co no khong?
 *    dll-off : KHONG cai handler, %n duoc goi tu DLL          -> doi chung
 *
 * MOI dong deu in TRUOC khi hanh dong, va fflush ngay, de "khong co dong tiep theo" la
 * bang chung chu khong phai suy doan (ky luat do dem muc 3).
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <windows.h>

static long g_hits = 0;

static void __cdecl probe_handler(const wchar_t* expr, const wchar_t* func,
                                  const wchar_t* file, unsigned int line, uintptr_t r)
{
    (void)expr; (void)func; (void)file; (void)line; (void)r;
    ++g_hits;
    printf("HANDLER: no ra lan %ld (expr/func/file deu NULL o CRT Release)\n", g_hits);
    fflush(stdout);
}

typedef int (*pfn_trigger)(char* buf, int cap, char which);

int main(int argc, char** argv)
{
    char buf[64];
    char fmt[8];
    int  rc = -777;
    const char* mode = (argc > 1) ? argv[1] : "off-n";
    int  want_handler = (strncmp(mode, "on", 2) == 0) || (strcmp(mode, "dll-on") == 0);
    char which = 'n';
    if (strstr(mode, "-s")) which = 's';
    else if (strstr(mode, "-d")) which = 'd';

    memset(buf, 0, sizeof(buf));

    printf("MODE=%s handler=%d\n", mode, want_handler);
    fflush(stdout);

    if (want_handler) {
        _set_invalid_parameter_handler(probe_handler);
        printf("STATE-TRUOC: da cai handler, hits=%ld\n", g_hits);
    } else {
        printf("STATE-TRUOC: KHONG cai handler, hits=%ld\n", g_hits);
    }
    fflush(stdout);

    fmt[0] = 'A'; fmt[1] = '%'; fmt[2] = which; fmt[3] = 'B'; fmt[4] = 0;

    if (strncmp(mode, "dll", 3) == 0) {
        HMODULE h = LoadLibraryA("crtprobe_dll.dll");
        pfn_trigger fn;
        printf("SAP GOI qua DLL. Neu khong co dong nao sau dong nay -> chet o day.\n");
        fflush(stdout);
        if (!h) { printf("KHONG nap duoc crtprobe_dll.dll\n"); return 2; }
        fn = (pfn_trigger)GetProcAddress(h, "CrtProbeTrigger");
        if (!fn) { printf("KHONG tim thay CrtProbeTrigger\n"); return 3; }
        rc = fn(buf, (int)sizeof(buf) - 1, which);
    } else {
        printf("SAP GOI _snprintf voi dinh dang [%s] va 0 doi so. "
               "Neu khong co dong nao sau dong nay -> chet o day.\n", fmt);
        fflush(stdout);
        if (which == 'n') {
            int written = 0;
            rc = _snprintf(buf, sizeof(buf) - 1, fmt, &written);
        } else {
            rc = _snprintf(buf, sizeof(buf) - 1, fmt);
        }
    }

    printf("SONG SOT: rc=%d out=[%s] hits=%ld\n", rc, buf, g_hits);
    fflush(stdout);
    return 0;
}
