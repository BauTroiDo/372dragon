/* DLL rieng, link /MD giong moi module cua game. Muc dich DUY NHAT: chung minh (hoac bac bo)
 * rang MOT lan `_set_invalid_parameter_handler` trong EXE co phu duoc loi CRT sinh ra
 * BEN TRONG mot DLL khac hay khong. Day la khoan phai DO, khong duoc suy tu "cung /MD".
 */
#include <stdio.h>
#include <windows.h>

__declspec(dllexport) int CrtProbeTrigger(char* buf, int cap, char which)
{
    char fmt[8];
    fmt[0] = 'A'; fmt[1] = '%'; fmt[2] = which; fmt[3] = 'B'; fmt[4] = 0;
    printf("DLL: sap goi _snprintf trong crtprobe_dll.dll\n");
    fflush(stdout);
    if (which == 'n') {
        int written = 0;
        return _snprintf(buf, (size_t)cap, fmt, &written);
    }
    return _snprintf(buf, (size_t)cap, fmt);
}
