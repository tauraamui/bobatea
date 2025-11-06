module main

import bobatea
import bobatea.lib.draw
import time

struct Model {
mut:
	counter int
	ticks   int
}

fn (m Model) init() ?bobatea.Cmd {
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

fn (m Model) view(mut ctx draw.Contextable) {
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

fn do_tick() bobatea.Cmd {
	return bobatea.tick(time.second, fn (t time.Time) bobatea.Msg {
		return bobatea.TickMsg{
			time: t
		}
	})
}

fn main() {
	mut model := Model{}
	mut app := bobatea.new_program(mut model)
	app.run() or { panic(err) }
}
