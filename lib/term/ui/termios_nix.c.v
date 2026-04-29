// Copyright (c) 2020-2024 Raúl Hernández. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module ui

import os
import strings
import time
import term.termios

#include <signal.h>

pub struct C.winsize {
	ws_row u16
	ws_col u16
}

const termios_at_startup = get_termios()

const kitty_keyboard_flags = 0b10 | 0b1000 | 0b10000

@[inline]
fn get_termios() termios.Termios {
	mut t := termios.Termios{}
	termios.tcgetattr(C.STDIN_FILENO, mut t)
	return t
}

@[inline]
fn get_terminal_size() (u16, u16) {
	winsz := C.winsize{}
	termios.ioctl(0, u64(termios.flag(C.TIOCGWINSZ)), voidptr(&winsz))
	return winsz.ws_row, winsz.ws_col
}

fn restore_terminal_state_signal(_ os.Signal) {
	restore_terminal_state()
}

fn restore_terminal_state() {
	termios_reset()
	mut c := ctx_ptr
	if unsafe { c != 0 } {
		c.paused = true
		load_title()
	}
	os.flush()
}

fn (mut ctx Context) termios_setup() ! {
	// store the current title, so restore_terminal_state can get it back
	save_title()

	if !ctx.cfg.skip_init_checks && !(os.is_atty(C.STDIN_FILENO) != 0
		&& os.is_atty(C.STDOUT_FILENO) != 0) {
		return error('not running under a TTY')
	}

	mut tios := get_termios()

	if ctx.cfg.capture_events {
		// Set raw input mode by unsetting ICANON and ECHO,
		// as well as disable e.g. ctrl+c and ctrl.z
		tios.c_iflag &=
			termios.invert(termios.flag(int(C.IGNBRK) | int(C.BRKINT) | int(C.PARMRK) | int(C.IXON)))
		tios.c_lflag &=
			termios.invert(termios.flag(int(C.ICANON) | int(C.ISIG) | int(C.ECHO) | int(C.IEXTEN) | int(C.TOSTOP)))
	} else {
		// Set raw input mode by unsetting ICANON and ECHO
		tios.c_lflag &= termios.invert(termios.flag(int(C.ICANON) | int(C.ECHO)))
	}

	if ctx.cfg.hide_cursor {
		ctx.hide_cursor()
		ctx.flush()
	}

	if ctx.cfg.window_title != '' {
		print('\x1b]0;${ctx.cfg.window_title}\x07')
		flush_stdout()
	}

	if !ctx.cfg.skip_init_checks {
		// prevent blocking during the feature detections, but allow enough time for the terminal
		// to send back the relevant input data
		tios.c_cc[C.VTIME] = 1
		tios.c_cc[C.VMIN] = 0
		termios.tcsetattr(C.STDIN_FILENO, C.TCSAFLUSH, mut tios)
		// feature-test the SU spec
		sx, sy := get_cursor_position()
		print('${bsu}${esu}')
		flush_stdout()
		ex, ey := get_cursor_position()
		if sx == ex && sy == ey {
			// the terminal either ignored or handled the sequence properly, enable SU
			ctx.enable_su = true
		} else {
			ctx.draw_line(sx, sy, ex, ey)
			ctx.set_cursor_position(sx, sy)
			ctx.flush()
		}
		// feature-test rgb (truecolor) support
		ctx.enable_rgb = supports_truecolor()
	}
	// Prevent stdin from blocking by making its read time 0
	tios.c_cc[C.VTIME] = 0
	tios.c_cc[C.VMIN] = 0
	termios.tcsetattr(C.STDIN_FILENO, C.TCSAFLUSH, mut tios)
	if ctx.cfg.mouse_enabled {
		// enable mouse input
		print('\x1b[?1003h\x1b[?1006h')
		flush_stdout()
	}
	// enable focus tracking
	print('\x1b[?1004h')
	flush_stdout()
	if ctx.cfg.use_alternate_buffer {
		// switch to the alternate buffer
		print('\x1b[?1049h')
		flush_stdout()
		// clear the terminal and set the cursor to the origin
		print('\x1b[2J\x1b[3J\x1b[1;1H')
		flush_stdout()
	}
	if ctx.cfg.capture_events {
		// Ask supporting terminals to report press/repeat/release in CSI-u form.
		print('\x1b[>${kitty_keyboard_flags}u')
		flush_stdout()
	}
	ctx.window_height, ctx.window_width = get_terminal_size()

	// Reset console on exit
	at_exit(restore_terminal_state) or {}
	os.signal_opt(.tstp, restore_terminal_state_signal) or {}
	os.signal_opt(.cont, fn (_ os.Signal) {
		mut c := ctx_ptr
		if unsafe { c != 0 } {
			c.termios_setup() or { panic(err) }
			c.window_height, c.window_width = get_terminal_size()
			mut event := &Event{
				typ:    .resized
				width:  c.window_width
				height: c.window_height
			}
			c.paused = false
			c.event(event)
		}
	}) or {}
	for code in ctx.cfg.reset {
		os.signal_opt(code, fn (_ os.Signal) {
			mut c := ctx_ptr
			if unsafe { c != 0 } {
				c.cleanup()
			}
			exit(0)
		}) or {}
	}

	os.signal_opt(.winch, fn (_ os.Signal) {
		mut c := ctx_ptr
		if unsafe { c != 0 } {
			// Just flag that a resize is pending, don't process immediately
			c.resize_pending = true
		}
	}) or {}

	os.flush()
}

fn get_cursor_position() (int, int) {
	print('\033[6n')
	flush_stdout()
	mut s := ''
	unsafe {
		buf := malloc_noscan(25)
		len := C.read(C.STDIN_FILENO, buf, 24)
		buf[len] = 0
		s = tos(buf, len)
	}
	if s.len == 0 {
		return -1, -1
	}
	a := s[2..].split(';')
	if a.len != 2 {
		return -1, -1
	}
	return a[0].int(), a[1].int()
}

fn supports_truecolor() bool {
	// faster/simpler, but less reliable, check
	if os.getenv('COLORTERM') in ['truecolor', '24bit'] {
		return true
	}
	// set the bg color to some arbitrary value (#010203), assumed not to be the default
	print('\x1b[48:2:1:2:3m')
	flush_stdout()
	// andquery the current color
	print('\x1bP\$qm\x1b\\')
	flush_stdout()
	mut s := ''
	unsafe {
		buf := malloc_noscan(25)
		len := C.read(C.STDIN_FILENO, buf, 24)
		buf[len] = 0
		s = tos(buf, len)
	}
	return s.contains('1:2:3')
}

fn termios_reset() {
	// C.TCSANOW ??
	mut startup := termios_at_startup
	termios.tcsetattr(C.STDIN_FILENO, C.TCSAFLUSH, mut startup)
	c := ctx_ptr
	if unsafe { c != 0 } && c.cfg.capture_events {
		// Pop the keyboard mode stack before leaving the current screen.
		print('\x1b[<u')
	}
	print('\x1b[?1003l\x1b[?1006l\x1b[?1004l\x1b[?25h')
	flush_stdout()
	if unsafe { c != 0 } && c.cfg.use_alternate_buffer {
		print('\x1b[?1049l')
	}
	os.flush()
}

///////////////////////////////////////////
// Input event loop - runs at higher frequency to capture input events
fn (mut ctx Context) input_loop() {
	input_poll_time := 1000 // 1ms polling interval for input events
	for {
		if !ctx.paused && ctx.cfg.event_fn != none {
			// Check for pending resize events
			if ctx.resize_pending {
				ctx.resize_pending = false
				ctx.window_height, ctx.window_width = get_terminal_size()

				mut event := &Event{
					typ:    .resized
					width:  ctx.window_width
					height: ctx.window_height
				}
				ctx.event(event)
			}

			unsafe {
				len := C.read(C.STDIN_FILENO, &u8(ctx.read_buf.data) + ctx.read_buf.len,
					ctx.read_buf.cap - ctx.read_buf.len)
				ctx.resize_arr(ctx.read_buf.len + len)
			}
			if ctx.read_buf.len > 0 {
				ctx.parse_events()
			}
		}
		time.sleep(input_poll_time * time.microsecond)
	}
}

// Combined update and render loop - runs at frame rate
fn (mut ctx Context) update_and_render_loop() {
	frame_time := 1_000_000 / ctx.cfg.frame_rate
	mut init_called := false
	mut sw := time.new_stopwatch(auto_start: false)
	mut sleep_len := 0
	for {
		if !init_called {
			ctx.init()
			init_called = true
		}
		if sleep_len > 0 {
			time.sleep(sleep_len * time.microsecond)
		}
		if !ctx.paused {
			sw.restart()
			// Update first, then render - ensures consistent state
			ctx.update()
			ctx.frame()
			sw.pause()
			e := sw.elapsed().microseconds()
			sleep_len = frame_time - int(e)

			ctx.frame_count++
		}
	}
}

// Main loop coordinator - starts input and combined update/render loops
fn (mut ctx Context) termios_loop() {
	// Start input loop in a separate thread
	spawn ctx.input_loop()

	// Run combined update and render loop in main thread
	ctx.update_and_render_loop()
}

fn (mut ctx Context) parse_events() {
	// Stop this from getting stuck in rare cases where something isn't parsed correctly
	mut nr_iters := 0
	for ctx.read_buf.len > 0 {
		nr_iters++
		if nr_iters > 100 {
			ctx.shift(1)
		}
		mut event := &Event(unsafe { nil })
		if ctx.read_buf[0] == 0x1b {
			e, len := escape_sequence(ctx.read_buf.bytestr())
			event = unsafe { e }
			ctx.shift(len)
		} else {
			if ctx.read_all_bytes {
				// When read_all_bytes is enabled, multi_char() processes the entire buffer as one event.
				// However, this causes issues when terminal multiplexers like tmux send compound sequences
				// that should be treated as separate key events. For example, when forwarding "C-w" + "j",
				// tmux might send it as "ctrl+\x17j" which should generate two separate events:
				// 1. The literal text "ctrl+" (if present) as a multi-char event
				// 2. Ctrl-W (byte 23) as a single control character event
				// 3. "j" as a multi-char event
				// This splitting logic ensures control characters in the buffer generate separate events.
				mut split_pos := -1
				for i := 0; i < ctx.read_buf.len; i++ {
					ch := ctx.read_buf[i]
					// Look for control characters (1-26), but skip tab(9) and enter(10)
					// which have special meaning and should not split the buffer
					if ch >= 1 && ch <= 26 && ch != 9 && ch != 10 {
						split_pos = i
						break
					}
				}

				if split_pos > 0 {
					// Process the prefix before the control character
					e, len := multi_char(ctx.read_buf.bytestr()[..split_pos])
					event = unsafe { e }
					ctx.shift(len)
				} else if split_pos == 0 {
					// The control character is at the start, process it as a single char
					event = single_char(ctx.read_buf.bytestr())
					ctx.shift(1)
				} else {
					// No control characters to split on, process the entire buffer
					e, len := multi_char(ctx.read_buf.bytestr())
					event = unsafe { e }
					ctx.shift(len)
				}
			} else {
				event = single_char(ctx.read_buf.bytestr())
				ctx.shift(1)
			}
		}
		if unsafe { event != 0 } {
			// Handle TMUX key forwarding: Ctrl+w followed by h/j/k/l
			// If we have a pending Ctrl+w and this is h/j/k/l, combine them
			if ctx.pending_ctrl_w && event.code in [KeyCode.h, .j, .k, .l] {
				// Create combined event: ctrl+w+h, ctrl+w+j, etc.
				combined_event := &Event{
					typ:       event.typ
					ascii:     event.ascii
					code:      KeyCode.w                  // Keep as w so resolve_key_msg can detect this case
					utf8:      '\x17' + event.utf8 // '\x17' is Ctrl+w + the second key
					modifiers: .ctrl
				}
				ctx.event(combined_event)
				ctx.pending_ctrl_w = false
			} else if ctx.pending_ctrl_w {
				// We had a pending Ctrl+w but the next key wasn't h/j/k/l
				// First emit the pending Ctrl+w event
				ctrl_w_event := &Event{
					typ:       .key_down
					ascii:     23 // Ctrl+w byte
					code:      KeyCode.w
					utf8:      'w'
					modifiers: .ctrl
				}
				ctx.event(ctrl_w_event)
				ctx.event(event) // Then emit the current event
				ctx.pending_ctrl_w = false
			} else if event.code == KeyCode.w && event.modifiers == .ctrl {
				// This is Ctrl+w - set pending flag and don't emit yet
				ctx.pending_ctrl_w = true
			} else {
				// Normal event - emit immediately
				ctx.event(event)
			}
			nr_iters = 0
		}
	}
}

fn single_char(buf string) &Event {
	ch := buf[0]

	mut event := &Event{
		typ:   .key_down
		ascii: ch
		code:  unsafe { KeyCode(ch) }
		utf8:  ch.ascii_str()
	}

	match ch {
		// special handling for `ctrl + letter`
		// TODO: Fix assoc in V and remove this workaround :/
		// 1  ... 26 { event = Event{ ...event, code: KeyCode(96 | ch), modifiers: .ctrl  } }
		// 65 ... 90 { event = Event{ ...event, code: KeyCode(32 | ch), modifiers: .shift } }
		// The bit `or`s here are really just `+`'s, just written in this way for a tiny performance improvement
		// don't treat tab, enter as ctrl+i, ctrl+j
		8 {
			return &Event{
				typ:   .key_down
				ascii: 127
				code:  .backspace
				utf8:  '\x7f'
			}
		}
		1...7, 9, 11...26 {
			event = &Event{
				typ:       event.typ
				ascii:     event.ascii
				utf8:      event.utf8
				code:      unsafe { KeyCode(96 | ch) }
				modifiers: .ctrl
			}
		}
		65...90 {
			event = &Event{
				typ:       event.typ
				ascii:     event.ascii
				utf8:      event.utf8
				code:      unsafe { KeyCode(32 | ch) }
				modifiers: .shift
			}
		}
		else {}
	}

	return event
}

fn multi_char(buf string) (&Event, int) {
	ch := buf[0]

	mut event := &Event{
		typ:   .key_down
		ascii: ch
		code:  unsafe { KeyCode(ch) }
		utf8:  buf
	}

	// handle backspace variants
	if ch == 8 {
		return &Event{
			typ:   .key_down
			ascii: 127
			code:  .backspace
			utf8:  '\x7f'
		}, 1
	}

	match ch {
		// special handling for `ctrl + letter`
		// TODO: Fix assoc in V and remove this workaround :/
		// 1  ... 26 { event = Event{ ...event, code: KeyCode(96 | ch), modifiers: .ctrl  } }
		// 65 ... 90 { event = Event{ ...event, code: KeyCode(32 | ch), modifiers: .shift } }
		// The bit `or`s here are really just `+`'s, just written in this way for a tiny performance improvement
		// don't treat tab, enter as ctrl+i, ctrl+j
		1...7, 9, 11...26 {
			event = &Event{
				typ:       event.typ
				ascii:     event.ascii
				utf8:      event.utf8
				code:      unsafe { KeyCode(96 | ch) }
				modifiers: .ctrl
			}
		}
		65...90 {
			event = &Event{
				typ:       event.typ
				ascii:     event.ascii
				utf8:      event.utf8
				code:      unsafe { KeyCode(32 | ch) }
				modifiers: .shift
			}
		}
		else {}
	}

	return event, buf.len
}

@[inline]
fn modifiers_from_report_param(param int) Modifiers {
	flags := if param > 0 { param - 1 } else { 0 }
	mut modifiers := unsafe { Modifiers(0) }
	if flags & 0b001 != 0 {
		modifiers.set(.shift)
	}
	if flags & 0b010 != 0 {
		modifiers.set(.alt)
	}
	if flags & 0b100 != 0 {
		modifiers.set(.ctrl)
	}
	return modifiers
}

@[inline]
fn key_event_type_from_report_param(param int) EventType {
	return match param {
		3 { .key_up }
		else { .key_down }
	}
}

@[inline]
fn parse_key_report_param(param string) (Modifiers, EventType) {
	if param.len == 0 {
		return unsafe { Modifiers(0) }, EventType.key_down
	}
	parts := param.split(':')
	modifiers := modifiers_from_report_param(parts[0].int())
	event_type := if parts.len > 1 {
		key_event_type_from_report_param(parts[1].int())
	} else {
		EventType.key_down
	}
	return modifiers, event_type
}

fn utf8_from_reported_text(param string) string {
	if param.len == 0 {
		return ''
	}
	mut builder := strings.new_builder(param.len)
	for part in param.split(':') {
		codepoint := part.int()
		if codepoint <= 0 || codepoint > 0x10ffff {
			continue
		}
		builder.write_string(utf32_to_str(u32(codepoint)))
	}
	return builder.str()
}

// key_code_from_kitty_modifier_codepoint maps kitty keyboard protocol PUA
// codepoints for standalone modifier and lock keys to their KeyCode value.
// Returns .null for codepoints outside that range.
@[inline]
fn key_code_from_kitty_modifier_codepoint(codepoint int) KeyCode {
	return match codepoint {
		57358 { KeyCode.caps_lock }
		57359 { KeyCode.scroll_lock }
		57360 { KeyCode.num_lock }
		57441 { KeyCode.left_shift }
		57442 { KeyCode.left_ctrl }
		57443 { KeyCode.left_alt }
		57444 { KeyCode.left_super }
		57445 { KeyCode.left_hyper }
		57446 { KeyCode.left_meta }
		57447 { KeyCode.right_shift }
		57448 { KeyCode.right_ctrl }
		57449 { KeyCode.right_alt }
		57450 { KeyCode.right_super }
		57451 { KeyCode.right_hyper }
		57452 { KeyCode.right_meta }
		else { KeyCode.null }
	}
}

@[inline]
fn event_from_reported_key(codepoint int, raw string, modifiers Modifiers, event_type EventType, text string) &Event {
	mut utf8 := raw
	if text.len > 0 {
		utf8 = text
	}
	mut ascii := u8(0)
	if text.len == 1 {
		ascii = text[0]
	}
	// Standalone modifier / lock key reports — surface them with a real KeyCode
	// so consumers can match on them instead of falling through to utf8 fallback
	// (which leaks the raw escape sequence as literal text in INSERT-mode editors).
	mod_code := key_code_from_kitty_modifier_codepoint(codepoint)
	if mod_code != .null {
		return &Event{
			typ:       event_type
			code:      mod_code
			utf8:      ''
			modifiers: modifiers
		}
	}
	if codepoint <= 0 || codepoint > 0x10ffff {
		return &Event{
			typ:       event_type
			ascii:     ascii
			utf8:      utf8
			modifiers: modifiers
		}
	}
	if codepoint <= 255 {
		ch := u8(codepoint)
		if ch == `\r` {
			return &Event{
				typ:       event_type
				ascii:     ch
				code:      .enter
				utf8:      utf8
				modifiers: modifiers
			}
		}
		base := single_char(ch.ascii_str())
		event_ascii := if ascii != 0 { ascii } else { base.ascii }
		return &Event{
			typ:       event_type
			ascii:     event_ascii
			code:      base.code
			utf8:      utf8
			modifiers: base.modifiers | modifiers
		}
	}
	return &Event{
		typ:       event_type
		ascii:     ascii
		utf8:      utf8
		modifiers: modifiers
	}
}

fn parse_csi_u_key_sequence(single string, buf string) &Event {
	if buf.len < 4 || buf[0] != `[` || buf[buf.len - 1] != `u` {
		return unsafe { nil }
	}
	parts := buf[1..buf.len - 1].split(';')
	if parts.len < 1 || parts.len > 3 {
		return unsafe { nil }
	}
	codepoint := parts[0].split(':')[0].int()
	mut modifiers := unsafe { Modifiers(0) }
	mut event_type := EventType.key_down
	if parts.len > 1 {
		modifiers, event_type = parse_key_report_param(parts[1])
	}
	text := if parts.len > 2 { utf8_from_reported_text(parts[2]) } else { '' }
	return event_from_reported_key(codepoint, single, modifiers, event_type, text)
}

fn parse_modify_other_keys_sequence(single string, buf string) &Event {
	if buf.len < 7 || buf[0] != `[` || buf[buf.len - 1] != `~` {
		return unsafe { nil }
	}
	parts := buf[1..buf.len - 1].split(';')
	if parts.len != 3 || parts[0] != '27' {
		return unsafe { nil }
	}
	return event_from_reported_key(parts[2].int(), single,
		modifiers_from_report_param(parts[1].int()), .key_down, '')
}

@[inline]
fn key_code_from_csi_final(final u8) KeyCode {
	return match final {
		`A` { .up }
		`B` { .down }
		`C` { .right }
		`D` { .left }
		`F` { .end }
		`H` { .home }
		`P` { .f1 }
		`Q` { .f2 }
		`R` { .f3 }
		`S` { .f4 }
		else { .null }
	}
}

@[inline]
fn key_code_from_tilde_param(param string) KeyCode {
	return match param {
		'2' { .insert }
		'3' { .delete }
		'5' { .page_up }
		'6' { .page_down }
		'11' { .f1 }
		'12' { .f2 }
		'13' { .f3 }
		'14' { .f4 }
		'15' { .f5 }
		'17' { .f6 }
		'18' { .f7 }
		'19' { .f8 }
		'20' { .f9 }
		'21' { .f10 }
		'23' { .f11 }
		'24' { .f12 }
		else { .null }
	}
}

fn parse_csi_modified_key_sequence(buf string) (KeyCode, Modifiers, EventType, bool) {
	if buf.len < 5 || buf[0] != `[` {
		return KeyCode.null, unsafe { Modifiers(0) }, EventType.key_down, false
	}
	final := buf[buf.len - 1]
	params := buf[1..buf.len - 1].split(';')
	if params.len != 2 {
		return KeyCode.null, unsafe { Modifiers(0) }, EventType.key_down, false
	}
	modifiers, event_type := parse_key_report_param(params[1])
	if final == `~` {
		code := key_code_from_tilde_param(params[0])
		return code, modifiers, event_type, code != .null
	}
	code := key_code_from_csi_final(final)
	return code, modifiers, event_type, code != .null
}

// Gets an entire, independent escape sequence from the buffer
// Normally, this just means reading until the first letter, but there are some exceptions...
fn escape_end(buf string) int {
	// Fast path for standalone ESC key (no following characters)
	// This makes the ESC key more responsive by not waiting for potential follow-up characters
	if buf.len == 1 {
		return 1
	}

	// If the second character isn't a special character that could start an escape sequence,
	// treat this as a standalone ESC key press
	if buf.len > 1 && !(buf[1] == `[` || buf[1] == `O` || buf[1] == `P`) {
		return 1
	}

	mut i := 0
	for {
		if i + 1 == buf.len {
			return buf.len
		}

		if buf[i].is_letter() || buf[i] == `~` {
			if buf[i] == `O` && i + 2 <= buf.len {
				n := buf[i + 1]
				if (n >= `A` && n <= `D`) || (n >= `P` && n <= `S`) || n == `F` || n == `H` {
					return i + 2
				}
			}
			return i + 1
			// escape hatch to avoid potential issues/crashes, although ideally this should never eval to true
		} else if buf[i + 1] == 0x1b {
			return i + 1
		}
		i++
	}
	// this point should be unreachable
	assert false
	return 0
}

fn escape_sequence(buf_ string) (&Event, int) {
	// Fast path for standalone ESC key
	if buf_.len == 1 {
		return &Event{
			typ:   .key_down
			ascii: 27
			code:  .escape
			utf8:  buf_
		}, 1
	}

	end := escape_end(buf_)
	single := buf_[..end] // read until the end of the sequence
	buf := single[1..] // skip the escape character

	if buf.len == 0 {
		return &Event{
			typ:   .key_down
			ascii: 27
			code:  .escape
			utf8:  single
		}, 1
	}

	if buf.len == 1 {
		c := single_char(buf)
		mut modifiers := c.modifiers
		modifiers.set(.alt)
		return &Event{
			typ:       c.typ
			ascii:     c.ascii
			code:      c.code
			utf8:      single
			modifiers: modifiers
		}, 2
	}
	// ----------------
	//   Focus events
	// ----------------
	if buf == '[I' {
		return &Event{
			typ: .focused
		}, end
	}
	if buf == '[O' {
		return &Event{
			typ: .unfocused
		}, end
	}
	// ----------------
	//   Mouse events
	// ----------------
	// Documentation: https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h2-Mouse-Tracking
	if buf.len > 2 && buf[1] == `<` {
		split := buf[2..].split(';')
		if split.len < 3 {
			return &Event(unsafe { nil }), 0
		}

		typ, x, y := split[0].int(), split[1].int(), split[2].int()
		lo := typ & 0b00011
		hi := typ & 0b11100

		mut modifiers := unsafe { Modifiers(0) }
		if hi & 4 != 0 {
			modifiers.set(.shift)
		}
		if hi & 8 != 0 {
			modifiers.set(.alt)
		}
		if hi & 16 != 0 {
			modifiers.set(.ctrl)
		}

		match typ {
			0...31 {
				last := buf[buf.len - 1]
				button := if lo < 3 { unsafe { MouseButton(lo + 1) } } else { MouseButton.unknown }
				event := if last == `m` || lo == 3 {
					EventType.mouse_up
				} else {
					EventType.mouse_down
				}

				return &Event{
					typ:       event
					x:         x
					y:         y
					button:    button
					modifiers: modifiers
					utf8:      single
				}, end
			}
			32...63 {
				button, event := if lo < 3 {
					unsafe { MouseButton(lo + 1), EventType.mouse_drag }
				} else {
					MouseButton.unknown, EventType.mouse_move
				}

				return &Event{
					typ:       event
					x:         x
					y:         y
					button:    button
					modifiers: modifiers
					utf8:      single
				}, end
			}
			64...95 {
				direction := if typ & 1 == 0 { Direction.down } else { Direction.up }
				return &Event{
					typ:       .mouse_scroll
					x:         x
					y:         y
					direction: direction
					modifiers: modifiers
					utf8:      single
				}, end
			}
			else {
				return &Event{
					typ:  .unknown
					utf8: single
				}, end
			}
		}
	}
	// ----------------------------
	//   Special key combinations
	// ----------------------------

	e := parse_csi_u_key_sequence(single, buf)
	if unsafe { e != nil } {
		return e, end
	}
	e2 := parse_modify_other_keys_sequence(single, buf)
	if unsafe { e2 != nil } {
		return e2, end
	}

	mut code := KeyCode.null
	mut modifiers := unsafe { Modifiers(0) }
	mut event_type := EventType.key_down
	match buf {
		'[91;5u' { code = .escape }
		'[A', 'OA' { code = .up }
		'[B', 'OB' { code = .down }
		'[C', 'OC' { code = .right }
		'[D', 'OD' { code = .left }
		'[5~', '[[5~' { code = .page_up }
		'[6~', '[[6~' { code = .page_down }
		'[F', 'OF', '[4~', '[[8~' { code = .end }
		'[H', 'OH', '[1~', '[[7~' { code = .home }
		'[2~' { code = .insert }
		'[3~' { code = .delete }
		'OP', '[11~' { code = .f1 }
		'OQ', '[12~' { code = .f2 }
		'OR', '[13~' { code = .f3 }
		'OS', '[14~' { code = .f4 }
		'[15~' { code = .f5 }
		'[17~' { code = .f6 }
		'[18~' { code = .f7 }
		'[19~' { code = .f8 }
		'[20~' { code = .f9 }
		'[21~' { code = .f10 }
		'[23~' { code = .f11 }
		'[24~' { code = .f12 }
		else {}
	}

	if buf == '[Z' {
		code = .tab
		modifiers.set(.shift)
	}

	if code == .null {
		parsed_code, parsed_modifiers, parsed_event_type, ok := parse_csi_modified_key_sequence(buf)
		if ok {
			code = parsed_code
			modifiers = parsed_modifiers
			event_type = parsed_event_type
		}
	}

	return &Event{
		typ:       event_type
		code:      code
		utf8:      single
		modifiers: modifiers
	}, end
}
