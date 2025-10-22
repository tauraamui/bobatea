module spinner

import bobatea as tea

struct Spinner {
	frames []string
}

pub struct Model {
mut:
	spinner Spinner
	frame   int
}

pub fn Model.new() Model {
	return Model{
		spinner: Spinner{
			frames: ['⣾ ', '⣽ ', '⣻ ', '⢿ ', '⡿ ', '⣟ ', '⣯ ', '⣷ ']
		}
	}
}

pub fn (m Model) init() ?tea.Cmd {
	return none
}

pub struct TickMsg {
	tag int
}

pub fn (mut m Model) update(msg tea.Msg) (tea.Model, ?tea.Cmd) {
	match msg {
		TickMsg {
			m.frame += 1
			if m.frame >= m.spinner.frames.len {
				m.frame = 0
			}
		}
		else {}
	}

	return m.clone(), m.tick
}

pub fn (m Model) view(mut ctx tea.Context) {
	ctx.draw_text(0, 0, m.spinner.frames[m.frame])
}

pub fn (m Model) tick() tea.Msg {
	return TickMsg{}
}

pub fn (m Model) clone() tea.Model {
	return Model{
		...m
	}
}
