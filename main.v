module main

import os
import flag
import bobatea as tea
import spinner

enum SessionState as u8 {
	timer
	spinner
}

const state_colors = [tea.Color.ansi(69), tea.Color.ansi(82)]

struct SpinnerModel {
mut:
	state   SessionState
	spinner spinner.Model
	spinner_index int
}

fn new_spinner_model() SpinnerModel {
	return SpinnerModel{
		state:   .spinner
		spinner: spinner.Model.new()
	}
}

fn (mut m SpinnerModel) init() ?tea.Cmd {
    m.spinner.spinner = spinner.monkey
	return m.spinner.tick
}

fn (mut m SpinnerModel) update(msg tea.Msg) (tea.Model, ?tea.Cmd) {
	mut cmds := []tea.Cmd{}
	match msg {
		tea.KeyMsg {
			match msg.code {
				.q {
					return SpinnerModel{}, tea.quit
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

    cmds << m.spinner.tick // I don't understand how the Go version doesn't also need this
	return m.clone(), tea.batch_array(cmds)
}

const bordered_layout := tea.new_layout()
    .size(17, 7)
    .center()
    .border(.normal)
    .border_color(tea.Color.ansi(69))
    .padding_all(1)

const borderless_layout = bordered_layout.border(.none)

fn (m SpinnerModel) view(mut ctx tea.Context) {
	mut layout := if m.state == .spinner { bordered_layout } else { borderless_layout }

	layout.render(mut ctx, fn [m] (mut ctx tea.Context) {
	    m.spinner.view(mut ctx)
	})

	ctx.push_offset(tea.Offset{ x: 17 })
	layout = if m.state == .spinner { borderless_layout } else { bordered_layout }

	layout.render(mut ctx, fn [m] (mut ctx tea.Context) {
        ctx.push_offset(tea.Offset{ x: -1 })
        ctx.draw_text(0, 0, shark_g)
        ctx.pop_offset()
	})
	ctx.pop_offset()

	ctx.set_color(tea.Color.ansi(241))
	ctx.push_offset(tea.Offset{ y: 7 })
	ctx.draw_text(1, 0, 'tab: focus next • n: new <name> • q: exit')
	ctx.pop_offset()

	ctx.reset_color()
}

fn (m SpinnerModel) clone() tea.Model {
	return SpinnerModel{
		...m
	}
}

fn main() {
	mut fp := flag.new_flag_parser(os.args)
	fp.application('bobatea')
	fp.version('0.1.0')
	fp.description('Bobatea example applications')
	fp.skip_executable()
	
	spinner_demo := fp.bool('spinner', `s`, false, 'Run the spinner demo')
	simple_list := fp.bool('simple-list', `l`, false, 'Run the simple list demo')
	
	fp.finalize() or {
		eprintln(err)
		exit(1)
	}
	
	match true {
		spinner_demo {
			run_spinner_demo()
		}
		simple_list {
			run_simple_list_demo()
		}
		else {
			eprintln('Please specify a demo to run:')
			eprintln('  --spinner, -s    Run the spinner demo')
			eprintln('  --simple-list, -l Run the simple list demo')
			eprintln('  --help, -h       Show this help')
			exit(1)
		}
	}
}

fn run_spinner_demo() {
	mut entry_model := new_spinner_model()
	mut app := tea.new_program(mut entry_model)
	app.run() or { panic('something went wrong! ${err}') }
}

fn run_simple_list_demo() {
	eprintln('Simple list demo not implemented yet')
	exit(1)
}
