#include <windows.h>

int bobatea_SetConsoleOutputCP(unsigned int code_page_id) {
	return SetConsoleOutputCP(code_page_id) != 0;
}

unsigned int bobatea_GetConsoleOutputCP(void) {
	return (unsigned int)(GetConsoleOutputCP());
}

int bobatea_SetConsoleCP(unsigned int code_page_id) {
	return SetConsoleCP(code_page_id) != 0;
}

unsigned int bobatea_GetConsoleCP(void) {
	return (unsigned int)(GetConsoleCP());
}

int bobatea_ReadConsoleInput(HANDLE hConsoleInput, PINPUT_RECORD lpBuffer, unsigned int nLength, unsigned int *lpNumberOfEventsRead) {
	return ReadConsoleInputW(hConsoleInput, lpBuffer, (DWORD)nLength, (LPDWORD)lpNumberOfEventsRead) != 0;
}

int bobatea_GetNumberOfConsoleInputEvents(HANDLE hConsoleInput, unsigned int *lpcNumberOfEvents) {
	return GetNumberOfConsoleInputEvents(hConsoleInput, (LPDWORD)lpcNumberOfEvents) != 0;
}

int bobatea_GetConsoleScreenBufferInfo(HANDLE handle, CONSOLE_SCREEN_BUFFER_INFO *info) {
	return GetConsoleScreenBufferInfo(handle, info) != 0;
}

int bobatea_GetConsoleMode(HANDLE handle, unsigned int *mode) {
	return GetConsoleMode(handle, (LPDWORD)mode) != 0;
}

int bobatea_SetConsoleMode(HANDLE handle, unsigned int mode) {
	return SetConsoleMode(handle, (DWORD)mode) != 0;
}
