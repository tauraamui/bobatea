module spinner

import bobatea as tea

pub const line = Spinner{
	frames: ["|", "/", "-", "\\"]
}

pub const dot = Spinner{
	frames: ['⣾ ', '⣽ ', '⣻ ', '⢿ ', '⡿ ', '⣟ ', '⣯ ', '⣷ ']
}

pub const mini_dot = Spinner{
	frames: ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
}

pub const jump = Spinner{
	frames: ["⢄", "⢂", "⢁", "⡁", "⡈", "⡐", "⡠"]
}

pub const pulse = Spinner{
	frames: ["█", "▓", "▒", "░"]
}

pub const points = Spinner{
	frames: ["∙∙∙", "●∙∙", "∙●∙", "∙∙●"]
}

pub const globe = Spinner{
	frames: ["🌍", "🌎", "🌏"]
}

pub const moon = Spinner{
	frames: ["🌑", "🌒", "🌓", "🌔", "🌕", "🌖", "🌗", "🌘"]
}

pub const monkey = Spinner{
	frames: ["🙈", "🙉", "🙊"]
	offset: tea.Offset{ x: -1 }
}

struct Spinner {
	frames []string
	offset tea.Offset
}

pub struct Model {
pub mut:
	spinner Spinner
mut:
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
	ctx.push_offset(m.spinner.offset)
	ctx.draw_text(0, 0, m.spinner.frames[m.frame])
	ctx.pop_offset()
}

pub fn (m Model) tick() tea.Msg {
	return TickMsg{}
}

pub fn (m Model) clone() tea.Model {
	return Model{
		...m
	}
}
