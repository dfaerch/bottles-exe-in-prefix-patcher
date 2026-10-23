#include <windows.h>
#include <stdio.h>

int WINAPI WinMain(HINSTANCE h, HINSTANCE p, LPSTR cmd, int show)
{
    char exe[MAX_PATH];
    char cwd[MAX_PATH];
    char msg[MAX_PATH * 2 + 128];

    GetModuleFileNameA(NULL, exe, sizeof(exe));
    GetCurrentDirectoryA(sizeof(cwd), cwd);

    snprintf(msg, sizeof(msg),
        "Executable:\n%s\n\nWorking directory:\n%s",
        exe, cwd);

    MessageBoxA(NULL, msg, "Bottles test", MB_OK);
    return 0;
}
