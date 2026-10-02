module bobatea

#flag windows @VMODROOT/windows_wrappers.c

fn C.bobatea_SetConsoleOutputCP(code_page_id u32) int
fn C.bobatea_GetConsoleOutputCP() u32
fn C.bobatea_SetConsoleCP(code_page_id u32) int
fn C.bobatea_GetConsoleCP() u32

fn switch_codepage_to_65001() {
	C.bobatea_SetConsoleOutputCP(65001)
	C.bobatea_SetConsoleCP(65001)
	codepage_output := C.bobatea_GetConsoleOutputCP()
	codepage_input := C.bobatea_GetConsoleCP()
	assert codepage_output == u32(65001)
	assert codepage_input == u32(65001)
}
