module main

import tauraamui.bobatea as tea
import time

struct PetalModel {
mut:
	counter int
	ticks int
	width int
	height int
}

fn new_petal_model() PetalModel {
	return PetalModel{
	}
}

fn (mut m PetalModel) init() ?tea.Cmd {
	// return do_tick()
	return tea.batch(do_tick())
}

fn (mut m PetalModel) update(msg tea.Msg) (tea.Model, ?tea.Cmd) {
	match msg {
		tea.TickMsg {
			m.ticks++
			m.counter++
			if m.counter < 10 {
				return m.clone(), do_tick()
			} else {
				return m.clone(), tea.quit
			}
		}
		tea.ResizedMsg {
			m.width = msg.window_width
			m.height = msg.window_height
		}
		tea.KeyMsg {
			if msg.k_type == .special && msg.string() == 'escape' {
					return m.clone(), tea.quit
			}
		}
		else {}
	}
	return m.clone(), none
}

fn (mut m PetalModel) view(mut ctx tea.Context) {
	ctx.draw_text(0, 0, "timer test")
	ctx.draw_text(0, 1, 'Tick Example\n')
	ctx.draw_text(0, 2, 'Counter: ${m.counter}\n')
	ctx.draw_text(0, 3, 'Total ticks: ${m.ticks}\n')
	ctx.draw_text(0, 4, 'WIDTH: ${m.width}')
	ctx.draw_text(0, 5, 'HEIGHT: ${m.height}')
	ctx.draw_text(0, 6, 'Press ESC or Ctrl+C to quit\n')
}

fn (m PetalModel) clone() tea.Model {
	return PetalModel{
		...m
	}
}

/*
struct Model {
mut:
	counter int
	ticks   int
}

fn (mut m Model) init() ?bobatea.Cmd {
	return do_tick()
}

fn (mut m Model) update(msg bobatea.Msg) (bobatea.Model, ?bobatea.Cmd) {
	match msg {
		bobatea.TickMsg {
			m.ticks++
			m.counter++
			if m.counter < 10 {
				return m, do_tick()
			} else {
				return m, bobatea.quit
			}
		}
		bobatea.KeyMsg {
			// Check if escape key was pressed
			key_str := msg.string()
			if key_str == 'escape' || key_str == 'ctrl+c' {
				return m, bobatea.quit
			}
		}
		else {}
	}
	return m, none
}

fn (m Model) view(mut ctx bobatea.Context) {
	ctx.write('Tick Example\n')
	ctx.write('Counter: ${m.counter}\n')
	ctx.write('Total ticks: ${m.ticks}\n')
	ctx.write('Press ESC or Ctrl+C to quit\n')
}

fn (m Model) clone() bobatea.Model {
	return Model{
		counter: m.counter
		ticks:   m.ticks
	}
}

*/

fn do_tick() tea.Cmd {
	return tea.tick(time.second, fn (t time.Time) tea.Msg {
		return tea.TickMsg{
			time: t
		}
	})
}

fn main() {
	mut model := PetalModel{}
	mut app := tea.new_program(mut model)
	app.run() or { panic(err) }
}
