module ui

fn test_get_cursor_position_reads_valid_row_column_data() ! {
	mut pipeset := [0, 0]
	mut original_stdin_fd := -1
	unsafe {
		if C.pipe(&pipeset[0]) == -1 {
			return error('unable to create pipe: ${C.strerror(C.errno)}')
		}

		fake_cursor_pos_data := '\033[45;70R'
		written_bytes := C.write(pipeset[1], fake_cursor_pos_data.str, fake_cursor_pos_data.len)
		if written_bytes == -1 {
			C.close(pipeset[0])
			C.close(pipeset[1])
			return error('error writing into pipe: ${C.strerror(C.errno)}')
		}

		C.close(pipeset[1])

		if C.dup2(pipeset[0], C.STDIN_FILENO) == -1 {
			C.close(pipeset[0])
			return error('error redirecting stdin with dup2: ${C.strerror(C.errno)}')
		}

		C.close(pipeset[0])

		cursor_pos_x, cursor_pos_y := get_cursor_position()
		assert cursor_pos_x == 45
		assert cursor_pos_y == 70
	}
}

fn test_escape_sequence_kitty_left_shift_press() {
	e, consumed := escape_sequence('\x1b[57441;2u')
	assert consumed == 10
	assert unsafe { e != nil }
	assert e.typ == .key_down
	assert e.code == .left_shift
	assert e.utf8 == ''
}

fn test_escape_sequence_kitty_left_shift_release() {
	e, consumed := escape_sequence('\x1b[57441;2:3u')
	assert consumed == 12
	assert unsafe { e != nil }
	assert e.typ == .key_up
	assert e.code == .left_shift
	assert e.utf8 == ''
}

fn test_escape_sequence_kitty_left_super_press() {
	e, _ := escape_sequence('\x1b[57444;9u')
	assert unsafe { e != nil }
	assert e.typ == .key_down
	assert e.code == .left_super
}

fn test_escape_sequence_kitty_caps_lock() {
	e, _ := escape_sequence('\x1b[57358u')
	assert unsafe { e != nil }
	assert e.code == .caps_lock
}

fn test_escape_sequence_kitty_modifier_codepoints_never_leak_utf8() {
	// Regression: before the fix, the parser fell through to the utf8 fallback
	// path and KeyMsg.runes carried the literal sequence, which INSERT-mode
	// editors would write to the buffer.
	for raw in ['\x1b[57441;2u', '\x1b[57442;5u', '\x1b[57443;3u', '\x1b[57444;9u',
		'\x1b[57447;2u', '\x1b[57358u'] {
		e, _ := escape_sequence(raw)
		assert unsafe { e != nil }
		assert e.utf8 == '', 'leaked utf8 ${e.utf8} for ${raw}'
	}
}

fn test_get_cursor_position_reads_empty_position_data() ! {
	mut pipeset := [0, 0]
	mut original_stdin_fd := -1
	unsafe {
		if C.pipe(&pipeset[0]) == -1 {
			return error('unable to create pipe: ${C.strerror(C.errno)}')
		}

		fake_cursor_pos_data := ''
		written_bytes := C.write(pipeset[1], fake_cursor_pos_data.str, fake_cursor_pos_data.len)
		if written_bytes == -1 {
			C.close(pipeset[0])
			C.close(pipeset[1])
			return error('error writing into pipe: ${C.strerror(C.errno)}')
		}

		C.close(pipeset[1])

		if C.dup2(pipeset[0], C.STDIN_FILENO) == -1 {
			C.close(pipeset[0])
			return error('error redirecting stdin with dup2: ${C.strerror(C.errno)}')
		}

		C.close(pipeset[0])

		cursor_pos_x, cursor_pos_y := get_cursor_position()
		assert cursor_pos_x == -1
		assert cursor_pos_y == -1
	}
}
