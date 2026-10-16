module ui

fn test_get_cursor_position_reads_valid_row_column_data() ! {
	// pipe() fills two C ints, and V's int is 64 bits
	mut pipeset := [2]i32{}
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

fn test_get_cursor_position_reads_empty_position_data() ! {
	// pipe() fills two C ints, and V's int is 64 bits
	mut pipeset := [2]i32{}
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

// a key typed during startup can reach stdin before, or instead of, the
// terminal's reply; a lone byte used to panic slicing it with s[2..]
fn test_get_cursor_position_survives_a_lone_typed_byte() ! {
	// pipe() fills two C ints, and V's int is 64 bits
	mut pipeset := [2]i32{}
	unsafe {
		if C.pipe(&pipeset[0]) == -1 {
			return error('unable to create pipe: ${C.strerror(C.errno)}')
		}

		typed_ahead := 'x'
		written_bytes := C.write(pipeset[1], typed_ahead.str, typed_ahead.len)
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

fn test_parse_cursor_position_finds_the_report_among_typed_keys() {
	x1, y1 := parse_cursor_position('x\033[45;70R')
	assert x1 == 45
	assert y1 == 70
	x2, y2 := parse_cursor_position('\033[45;70Rjk')
	assert x2 == 45
	assert y2 == 70
	// an arrow key typed first is an escape sequence too, but not a report
	x3, y3 := parse_cursor_position('\033[A\033[3;9R')
	assert x3 == 3
	assert y3 == 9
}

fn test_parse_cursor_position_rejects_anything_but_a_report() {
	for s in ['', 'x', '\033', '\033[', '\033[R', '\033[45R', '\033[;70R', '\033[45;R', '\033[45;70',
		'\033[1;2;3R', '\033[A', 'hello'] {
		x, y := parse_cursor_position(s)
		assert x == -1, s
		assert y == -1, s
	}
}
