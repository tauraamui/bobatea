module draw

import lib.term.ui as tui

pub struct Color {
pub:
	r u8
	g u8
	b u8
}

pub fn Color.ansi(c int) Color {
	r, g, b := ansi2rgb(c)
	return Color{r, g, b}
}

// converts an ANSI 256-color index back to RGB components
fn ansi2rgb(ansi_color int) (u8, u8, u8) {
	if ansi_color < 0 || ansi_color > 255 {
		return 0, 0, 0 // return black for invalid indices
	}

	color := tui.color_table[ansi_color]
	r := u8((color >> 16) & 0xff)
	g := u8((color >> 8) & 0xff)
	b := u8(color & 0xff)

	return r, g, b
}

fn (a Color) == (b Color) bool {
	return (a.r == b.r && a.g == b.g && a.b == b.b)
}

