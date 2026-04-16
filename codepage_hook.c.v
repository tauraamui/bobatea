module bobatea

$if windows {
	#include <windows.h>
}

fn C.SetConsoleOutputCP(wCodePageID u32)
fn C.GetConsoleOutputCP() u32
fn C.SetConsoleCP(wCodePageID u32)
fn C.GetConsoleCP() u32

fn switch_codepage_to_65001() {
	C.SetConsoleOutputCP(65001)
	C.SetConsoleCP(65001)
	codepage_output := C.GetConsoleOutputCP()
	codepage_input := C.GetConsoleCP()
	assert codepage_output == 65001
	assert codepage_input == 65001
}
