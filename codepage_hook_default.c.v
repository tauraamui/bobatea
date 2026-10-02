module bobatea

// switch_codepage_to_65001 is a no-op away from Windows. The Windows variant
// lives in codepage_hook_windows.c.v; keeping the C declarations out of this
// build stops them from being emitted (and failing to link) elsewhere.
fn switch_codepage_to_65001() {}
