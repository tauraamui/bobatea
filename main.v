module main

import bobatea as tea
import strings

enum SessionState as u8 {
	timer
	spinner
}

const state_colors = [tea.Color.ansi(69), tea.Color.ansi(82)]

struct MainModel {
mut:
	state SessionState
}

fn new_model() MainModel {
	return MainModel{
		state: .timer
	}
}

fn (mut m MainModel) init() ?tea.Cmd {
	return none // no init required for now
}

fn (mut m MainModel) update(msg tea.Msg) (tea.Model, ?tea.Cmd) {
	if msg is tea.KeyMsg {
		if msg.code == .q {
			return MainModel{}, tea.quit
		}

		if msg.code == .tab {
			m.state = if m.state == .timer { .spinner } else { .timer }
			return m.clone(), none
		}
	}

	return m.clone(), none
}

fn (m MainModel) view(mut ctx tea.Context) {
	win_height := ctx.window_height()
	draw_text_in_box(mut ctx, 2, 2, '< ${strings.repeat_string(shark_g + ',', 10)} >')
	// draw_box(mut ctx, 2, 2, 15, 5, state_colors[m.state])
	// draw_box(mut ctx, 2, 2, 15, 5, draw.Color.ansi(69))
	// draw_box(mut ctx, 4, 4, 15, 5, tea.Color.ansi(162))
	ctx.set_color(tea.Color.ansi(241))
	mut help_text_y := win_height - 1
	help_text_y = 10
	ctx.draw_text(1, help_text_y, 'tab: focus next • n: new <name> • q: exit')

	ctx.reset_color()
}

fn draw_box(mut ctx tea.Context, x int, y int, width int, height int, border_color tea.Color) {
	ctx.set_color(border_color)
	defer { ctx.reset_color() }
	ctx.draw_text(x, y, '${tea.top_left}${strings.repeat_string(string(tea.top), width)}${tea.top_right}')
	for yy in 1 .. height {
		ctx.draw_text(x, y + yy, '${tea.left}')
		ctx.draw_text(x + width + 1, y + yy, '${tea.right}')
	}
	ctx.draw_text(x, y + height, '${tea.bottom_left}${strings.repeat_string(string(tea.bottom),
		width)}${tea.bottom_right}')
}

fn draw_text_in_box(mut ctx tea.Context, x int, y int, msg string) {
	visual_width := utf8_str_visible_length(msg)
	ctx.draw_text(x, y, '${tea.top_left}${strings.repeat_string(string(tea.top), visual_width)}${tea.top_right}')
	ctx.draw_text(x, y + 1, '${tea.left}${msg}${tea.right}')
	ctx.draw_text(x, y + 2, '${tea.bottom_left}${strings.repeat_string(string(tea.bottom),
		visual_width)}${tea.bottom_right}')
}

fn (m MainModel) clone() tea.Model {
	return MainModel{
		...m
	}
}

fn main() {
	mut entry_model := new_model()
	mut app := tea.new_program(mut entry_model)
	app.run() or { panic('something went wrong! ${err}') }
}
