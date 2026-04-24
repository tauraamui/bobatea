// Copyright (c) 2020-2024 Raúl Hernández. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module ui

import strings

pub struct Color {
pub:
	r u8
	g u8
	b u8
}

// hex returns `c`'s RGB color in hex format.
pub fn (c Color) hex() string {
	return '#${c.r.hex()}${c.g.hex()}${c.b.hex()}'
}

// Synchronized Updates spec, designed to avoid tearing during renders
// https://gitlab.com/gnachman/iterm2/-/wikis/synchronized-updates-spec
const bsu = '\x1bP=1s\x1b\\'

const esu = '\x1bP=2s\x1b\\'

// write puts the string `s` into the print buffer.
@[inline]
pub fn (mut ctx Context) write(s string) {
	if s == '' {
		return
	}
	unsafe { ctx.print_buf.push_many(s.str, s.len) }
}

// flush displays the accumulated print buffer to the screen.
@[inline]
pub fn (mut ctx Context) flush() {
	// TODO: Diff the previous frame against this one, and only render things that changed?
	if !ctx.enable_su {
		C.write(1, ctx.print_buf.data, ctx.print_buf.len)
	} else {
		C.write(1, bsu.str, bsu.len)
		C.write(1, ctx.print_buf.data, ctx.print_buf.len)
		C.write(1, esu.str, esu.len)
	}
	ctx.print_buf.clear()
}

// bold sets the character state to bold.
@[inline]
pub fn (mut ctx Context) bold() {
	ctx.write('\x1b[1m')
}

// write_int_digits writes the decimal digits of a non-negative integer
// directly into print_buf without allocating a string.
@[inline]
fn (mut ctx Context) write_int_digits(n int) {
	if n < 10 {
		ctx.print_buf << u8(n) + `0`
		return
	}
	// Stack buffer for up to 10 digits (covers all 32-bit ints).
	mut buf := [10]u8{}
	mut pos := 10
	mut val := n
	for val > 0 {
		pos -= 1
		buf[pos] = u8(val % 10) + `0`
		val /= 10
	}
	for i in pos .. 10 {
		ctx.print_buf << buf[i]
	}
}

// set_cursor_position positions the cusor at the given coordinates `x`,`y`.
@[inline]
pub fn (mut ctx Context) set_cursor_position(x int, y int) {
	ctx.print_buf << 0x1b // ESC
	ctx.print_buf << `[`
	ctx.write_int_digits(y)
	ctx.print_buf << `;`
	ctx.write_int_digits(x)
	ctx.print_buf << `H`
}

// show_cursor will make the cursor appear if it is not already visible
@[inline]
pub fn (mut ctx Context) show_cursor() {
	ctx.write('\x1b[?25h')
}

// hide_cursor will make the cursor invisible
@[inline]
pub fn (mut ctx Context) hide_cursor() {
	ctx.write('\x1b[?25l')
}

// write_sgr_color writes an SGR color escape (38 for fg, 48 for bg) directly
// into print_buf without allocating a string.
@[inline]
fn (mut ctx Context) write_sgr_color(kind u8, c Color) {
	if ctx.enable_rgb {
		// \x1b[{kind};2;{r};{g};{b}m
		ctx.print_buf << 0x1b
		ctx.print_buf << `[`
		ctx.write_int_digits(int(kind))
		ctx.print_buf << `;`
		ctx.print_buf << `2`
		ctx.print_buf << `;`
		ctx.write_int_digits(int(c.r))
		ctx.print_buf << `;`
		ctx.write_int_digits(int(c.g))
		ctx.print_buf << `;`
		ctx.write_int_digits(int(c.b))
		ctx.print_buf << `m`
	} else if ctx.enable_ansi256 {
		// \x1b[{kind};5;{ansi}m
		ctx.print_buf << 0x1b
		ctx.print_buf << `[`
		ctx.write_int_digits(int(kind))
		ctx.print_buf << `;`
		ctx.print_buf << `5`
		ctx.print_buf << `;`
		ctx.write_int_digits(rgb2ansi(c.r, c.g, c.b))
		ctx.print_buf << `m`
	} else {
		// \x1b[{30|40+index}m - basic 8-color fallback (kind-8 = 30 for fg, 40 for bg)
		ctx.print_buf << 0x1b
		ctx.print_buf << `[`
		ctx.write_int_digits(int(kind) - 8 + rgb2basic_ansi(int(c.r), int(c.g), int(c.b)))
		ctx.print_buf << `m`
	}
}

fn rgb2basic_ansi(r int, g int, b int) int {
	mut best_index := 0
	mut best_distance := -1
	for i in 0 .. 8 {
		ref := color_table[i]
		dr := r - int((ref >> 16) & 0xff)
		dg := g - int((ref >> 8) & 0xff)
		db := b - int(ref & 0xff)
		distance := dr * dr + dg * dg + db * db
		if best_distance == -1 || distance < best_distance {
			best_distance = distance
			best_index = i
		}
	}
	return best_index
}

// set_color sets the current foreground color used by any succeeding `draw_*` calls.
@[inline]
pub fn (mut ctx Context) set_color(c Color) {
	ctx.write_sgr_color(38, c)
}

// set_color sets the current background color used by any succeeding `draw_*` calls.
@[inline]
pub fn (mut ctx Context) set_bg_color(c Color) {
	ctx.write_sgr_color(48, c)
}

// reset_color sets the current foreground color back to it's default value.
@[inline]
pub fn (mut ctx Context) reset_color() {
	ctx.write('\x1b[39m')
}

// reset_bg_color sets the current background color back to it's default value.
@[inline]
pub fn (mut ctx Context) reset_bg_color() {
	ctx.write('\x1b[49m')
}

// reset restores the state of all colors and text formats back to their default values.
@[inline]
pub fn (mut ctx Context) reset() {
	ctx.write('\x1b[0m')
}

// clear erases the entire terminal window and any saved lines.
@[inline]
pub fn (mut ctx Context) clear() {
	ctx.write('\x1b[2J\x1b[3J')
}

// set_window_title sets the string `s` as the window title.
@[inline]
pub fn (mut ctx Context) set_window_title(s string) {
	if !ctx.supports_window_title {
		return
	}
	print('\x1b]0;${s}\x07')
	flush_stdout()
}

// draw_point draws a point at position `x`,`y`.
@[inline]
pub fn (mut ctx Context) draw_point(x int, y int) {
	ctx.set_cursor_position(x, y)
	ctx.write(' ')
}

// draw_text draws the string `s`, starting from position `x`,`y`.
@[inline]
pub fn (mut ctx Context) draw_text(x int, y int, s string) {
	ctx.set_cursor_position(x, y)
	ctx.write(s)
}

// draw_line draws a line segment, starting at point `x`,`y`, and ending at point `x2`,`y2`.
pub fn (mut ctx Context) draw_line(x int, y int, x2 int, y2 int) {
	min_x, min_y := if x < x2 { x } else { x2 }, if y < y2 { y } else { y2 }
	max_x, _ := if x > x2 { x } else { x2 }, if y > y2 { y } else { y2 }
	if y == y2 {
		// Horizontal line, performance improvement
		ctx.set_cursor_position(min_x, min_y)
		ctx.write(strings.repeat(` `, max_x + 1 - min_x))
		return
	}
	// Draw the various points with Bresenham's line algorithm:
	mut x0, x1 := x, x2
	mut y0, y1 := y, y2
	sx := if x0 < x1 { 1 } else { -1 }
	sy := if y0 < y1 { 1 } else { -1 }
	dx := if x0 < x1 { x1 - x0 } else { x0 - x1 }
	dy := if y0 < y1 { y0 - y1 } else { y1 - y0 } // reversed
	mut err := dx + dy
	for {
		// res << Segment{ x0, y0 }
		ctx.draw_point(x0, y0)
		if x0 == x1 && y0 == y1 {
			break
		}
		e2 := 2 * err
		if e2 >= dy {
			err += dy
			x0 += sx
		}
		if e2 <= dx {
			err += dx
			y0 += sy
		}
	}
}

// draw_dashed_line draws a dashed line segment, starting at point `x`,`y`, and ending at point `x2`,`y2`.
pub fn (mut ctx Context) draw_dashed_line(x int, y int, x2 int, y2 int) {
	// Draw the various points with Bresenham's line algorithm:
	mut x0, x1 := x, x2
	mut y0, y1 := y, y2
	sx := if x0 < x1 { 1 } else { -1 }
	sy := if y0 < y1 { 1 } else { -1 }
	dx := if x0 < x1 { x1 - x0 } else { x0 - x1 }
	dy := if y0 < y1 { y0 - y1 } else { y1 - y0 } // reversed
	mut err := dx + dy
	mut i := 0
	for {
		if i % 2 == 0 {
			ctx.draw_point(x0, y0)
		}
		if x0 == x1 && y0 == y1 {
			break
		}
		e2 := 2 * err
		if e2 >= dy {
			err += dy
			x0 += sx
		}
		if e2 <= dx {
			err += dx
			y0 += sy
		}
		i++
	}
}

// draw_rect draws a rectangle, starting at top left `x`,`y`, and ending at bottom right `x2`,`y2`.
pub fn (mut ctx Context) draw_rect(x int, y int, x2 int, y2 int) {
	if y == y2 || x == x2 {
		ctx.draw_line(x, y, x2, y2)
		return
	}
	min_y, max_y := if y < y2 { y, y2 } else { y2, y }
	for y_pos in min_y .. max_y + 1 {
		ctx.draw_line(x, y_pos, x2, y_pos)
	}
}

// draw_empty_dashed_rect draws a rectangle with dashed lines, starting at top left `x`,`y`, and ending at bottom right `x2`,`y2`.
pub fn (mut ctx Context) draw_empty_dashed_rect(x int, y int, x2 int, y2 int) {
	if y == y2 || x == x2 {
		ctx.draw_dashed_line(x, y, x2, y2)
		return
	}

	min_x, max_x := if x < x2 { x, x2 } else { x2, x }
	min_y, max_y := if y < y2 { y, y2 } else { y2, y }

	ctx.draw_dashed_line(min_x, min_y, max_x, min_y)
	ctx.draw_dashed_line(min_x, min_y, min_x, max_y)
	if (max_y - min_y) & 1 == 0 {
		ctx.draw_dashed_line(min_x, max_y, max_x, max_y)
	} else {
		ctx.draw_dashed_line(min_x + 1, max_y, max_x, max_y)
	}
	if (max_x - min_x) & 1 == 0 {
		ctx.draw_dashed_line(max_x, min_y, max_x, max_y)
	} else {
		ctx.draw_dashed_line(max_x, min_y + 1, max_x, max_y)
	}
}

// draw_empty_rect draws a rectangle with no fill, starting at top left `x`,`y`, and ending at bottom right `x2`,`y2`.
pub fn (mut ctx Context) draw_empty_rect(x int, y int, x2 int, y2 int) {
	if y == y2 || x == x2 {
		ctx.draw_line(x, y, x2, y2)
		return
	}
	ctx.draw_line(x, y, x2, y)
	ctx.draw_line(x, y2, x2, y2)
	ctx.draw_line(x, y, x, y2)
	ctx.draw_line(x2, y, x2, y2)
}

// horizontal_separator draws a horizontal separator, spanning the width of the screen.
@[inline]
pub fn (mut ctx Context) horizontal_separator(y int) {
	ctx.set_cursor_position(0, y)
	ctx.write(strings.repeat(`-`, ctx.window_width)) // /* `⎽` */
}
