module bobatea

pub enum Alignment {
	start
	center
	end
}

pub enum BorderStyle {
	none
	normal
	rounded
	thick
	double
}

pub struct Padding {
pub:
	top    int
	bottom int
	left   int
	right  int
}

pub struct Layout {
pub:
	alignment_x Alignment = .start
	alignment_y Alignment = .start
	width       int
	height      int
	padding     Padding
	border      BorderStyle = .none
}

pub fn (l Layout) render(mut ctx Context, content_fn fn (mut Context)) {
	// Draw border if specified
	if l.border != .none {
		l.draw_border(mut ctx)
	}

	// Calculate content area dimensions
	border_offset := if l.border != .none { 1 } else { 0 }
	content_width := l.width - (l.padding.left + l.padding.right) - (border_offset * 2)
	content_height := l.height - (l.padding.top + l.padding.bottom) - (border_offset * 2)

	// Calculate alignment offset within content area
	alignment_offset_x := match l.alignment_x {
		.start { 0 }
		.center { content_width / 2 }
		.end { content_width }
	}

	alignment_offset_y := match l.alignment_y {
		.start { 0 }
		.center { content_height / 2 }
		.end { content_height }
	}

	// Total offset includes border, padding, and alignment
	total_offset_x := border_offset + l.padding.left + alignment_offset_x
	total_offset_y := border_offset + l.padding.top + alignment_offset_y

	ctx.push_offset(Offset{total_offset_x, total_offset_y})
	content_fn(mut ctx)
	ctx.pop_offset()
}

fn (l Layout) draw_border(mut ctx Context) {
	match l.border {
		.normal {
			l.draw_normal_border(mut ctx)
		}
		.rounded {
			l.draw_rounded_border(mut ctx)
		}
		.thick {
			l.draw_thick_border(mut ctx)
		}
		.double {
			l.draw_double_border(mut ctx)
		}
		.none {}
	}
}

fn (l Layout) draw_normal_border(mut ctx Context) {
	// Top and bottom lines
	for x in 0 .. l.width {
		ctx.draw_text(x, 0, if x == 0 {
			'┌'
		} else if x == l.width - 1 {
			'┐'
		} else {
			'─'
		})
		ctx.draw_text(x, l.height - 1, if x == 0 {
			'└'
		} else if x == l.width - 1 {
			'┘'
		} else {
			'─'
		})
	}
	// Left and right lines
	for y in 1 .. l.height - 1 {
		ctx.draw_text(0, y, '│')
		ctx.draw_text(l.width - 1, y, '│')
	}
}

fn (l Layout) draw_rounded_border(mut ctx Context) {
	// Top and bottom lines
	for x in 0 .. l.width {
		ctx.draw_text(x, 0, if x == 0 {
			'╭'
		} else if x == l.width - 1 {
			'╮'
		} else {
			'─'
		})
		ctx.draw_text(x, l.height - 1, if x == 0 {
			'╰'
		} else if x == l.width - 1 {
			'╯'
		} else {
			'─'
		})
	}
	// Left and right lines
	for y in 1 .. l.height - 1 {
		ctx.draw_text(0, y, '│')
		ctx.draw_text(l.width - 1, y, '│')
	}
}

fn (l Layout) draw_thick_border(mut ctx Context) {
	// Top and bottom lines
	for x in 0 .. l.width {
		ctx.draw_text(x, 0, if x == 0 {
			'┏'
		} else if x == l.width - 1 {
			'┓'
		} else {
			'━'
		})
		ctx.draw_text(x, l.height - 1, if x == 0 {
			'┗'
		} else if x == l.width - 1 {
			'┛'
		} else {
			'━'
		})
	}
	// Left and right lines
	for y in 1 .. l.height - 1 {
		ctx.draw_text(0, y, '┃')
		ctx.draw_text(l.width - 1, y, '┃')
	}
}

fn (l Layout) draw_double_border(mut ctx Context) {
	// Top and bottom lines
	for x in 0 .. l.width {
		ctx.draw_text(x, 0, if x == 0 {
			'╔'
		} else if x == l.width - 1 {
			'╗'
		} else {
			'═'
		})
		ctx.draw_text(x, l.height - 1, if x == 0 {
			'╚'
		} else if x == l.width - 1 {
			'╝'
		} else {
			'═'
		})
	}
	// Left and right lines
	for y in 1 .. l.height - 1 {
		ctx.draw_text(0, y, '║')
		ctx.draw_text(l.width - 1, y, '║')
	}
}

// Convenience constructors
pub fn box(width int, height int) Layout {
	return Layout{
		width:  width
		height: height
		border: .normal
	}
}

pub fn centered_box(width int, height int) Layout {
	return Layout{
		width:       width
		height:      height
		border:      .normal
		alignment_x: .center
		alignment_y: .center
	}
}

pub fn padded_box(width int, height int, padding Padding) Layout {
	return Layout{
		width:   width
		height:  height
		border:  .normal
		padding: padding
	}
}
