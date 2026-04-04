module bobatea

import lib.draw

pub type Color = draw.Color
pub type Offset = draw.Offset
pub type ClipArea = draw.ClipArea
pub type Style = draw.Style

pub interface Drawer {
mut:
	set_stroke(s string)
	draw_text(x int, y int, text string)
	write(c string)
	draw_rect(x int, y int, width int, height int)
	draw_point(x int, y int)
	draw_line(x int, y int, x2 int, y2 int, do_apply_offsets bool)
	clear_area(x int, y int, width int, height int)
}

pub interface Colorer {
mut:
	set_color(c draw.Color)
	set_bg_color(c draw.Color)
	set_default_fg_color(c draw.Color)
	set_default_bg_color(c draw.Color)
	get_default_fg_color() ?draw.Color
	get_default_bg_color() ?draw.Color
	reset_default_fg_color()
	reset_default_bg_color()
	reset_color()
	reset_bg_color()
}

pub interface Clipper {
mut:
	set_clip_area(c draw.ClipArea)
	clear_clip_area()
}

pub interface WindowSizer {
	window_width() int
	window_height() int
}

pub interface Offsetter {
	compact_offsets() draw.Offset
	compact_offsets_to(id int) draw.Offset
	compact_offsets_from(id int) draw.Offset
mut:
	push_offset(o draw.Offset) int
	pop_offset() ?draw.Offset
	clear_offsets_to(id int)
	clear_to_offset(id int)
	clear_offsets_from(id int)
	clear_from_offset(id int)
	clear_all_offsets()
}

pub interface Renderer {
	Drawer
	Colorer
	Clipper
	Offsetter
	WindowSizer
}

pub interface Context {
	Renderer
mut:
	render_debug() bool
	rate_limit_draws() bool

	set_cursor_position(x int, y int)
	set_cursor_to_block()
	set_cursor_to_underline()
	set_cursor_to_vertical_bar()
	show_cursor()
	hide_cursor()

	bold()
	set_style(s draw.Style)
	clear_style()

	reset()

	clear()
	flush()
	clear_prev_data()
}
