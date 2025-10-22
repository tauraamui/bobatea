module main

import bobatea as tea
import spinner
import strings

enum SessionState as u8 {
	timer
	spinner
}

const state_colors = [tea.Color.ansi(69), tea.Color.ansi(82)]

struct MainModel {
mut:
	state   SessionState
	spinner spinner.Model
}

fn new_model() MainModel {
	return MainModel{
		state:   .spinner
		spinner: spinner.Model.new()
	}
}

fn (mut m MainModel) init() ?tea.Cmd {
	return m.spinner.tick
}

fn (mut m MainModel) update(msg tea.Msg) (tea.Model, ?tea.Cmd) {
	mut cmds := []tea.Cmd{}
	match msg {
		tea.KeyMsg {
			match msg.code {
				.q {
					return MainModel{}, tea.quit
				}
				.tab {
					m.state = if m.state == .timer { .spinner } else { .timer }
				}
				else {}
			}
			match m.state {
				.spinner {
					s, cmd := m.spinner.update(msg)
					if s is spinner.Model {
						m.spinner = s
					}
					u_cmd := cmd or { tea.noop_cmd }
					cmds << u_cmd
				}
				else {}
			}
		}
		spinner.TickMsg {
			s, cmd := m.spinner.update(msg)
			if s is spinner.Model {
				m.spinner = s
			}
			u_cmd := cmd or { tea.noop_cmd }
			cmds << u_cmd
		}
		else {}
	}

	return m.clone(), tea.batch_array(cmds)
}

fn (m MainModel) view(mut ctx tea.Context) {
	win_height := ctx.window_height()
	layout := tea.centered_box(17, 7)
	layout.render(mut ctx, fn [m] (mut ctx tea.Context) {
		match m.state {
			.spinner {
				m.spinner.view(mut ctx)
			}
			.timer {
				ctx.push_offset(tea.Offset{ x: -1 })
				ctx.draw_text(0, 0, shark_g)
				ctx.pop_offset()
			}
		}
		// m.spinner.view(mut ctx)
	})
	ctx.set_color(tea.Color.ansi(241))
	mut help_text_y := win_height - 1
	help_text_y = 10
	ctx.draw_text(1, help_text_y, 'tab: focus next • n: new <name> • q: exit')

	ctx.reset_color()
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
