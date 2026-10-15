// Prototypes for windows_wrappers.c. That file is linked in as its own
// translation unit via #flag, so without these the generated C calls the
// wrappers undeclared, which gcc 14 (and so mingw-w64) rejects as an error.
#ifndef BOBATEA_WINDOWS_WRAPPERS_H
#define BOBATEA_WINDOWS_WRAPPERS_H

#include <windows.h>

int bobatea_SetConsoleOutputCP(unsigned int code_page_id);
unsigned int bobatea_GetConsoleOutputCP(void);
int bobatea_SetConsoleCP(unsigned int code_page_id);
unsigned int bobatea_GetConsoleCP(void);
int bobatea_ReadConsoleInput(HANDLE hConsoleInput, PINPUT_RECORD lpBuffer, unsigned int nLength, unsigned int *lpNumberOfEventsRead);
int bobatea_GetNumberOfConsoleInputEvents(HANDLE hConsoleInput, unsigned int *lpcNumberOfEvents);
int bobatea_GetConsoleScreenBufferInfo(HANDLE handle, CONSOLE_SCREEN_BUFFER_INFO *info);
int bobatea_GetConsoleMode(HANDLE handle, unsigned int *mode);
int bobatea_SetConsoleMode(HANDLE handle, unsigned int mode);

#endif
