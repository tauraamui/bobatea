module list

import tauraamui.bobatea as tea

pub interface Item {
	title() string
	filter_value() string
}

@[noinit]
pub struct Model {
	width  int
	height int
	items  []Item
}

pub fn Model.new(items []Item, width int, height int) Model {
	return Model{
		width: width
		height: height
		items: items
	}
}

pub fn (m Model) init() fn () tea.Msg {
	return tea.noop_cmd
}

pub fn (mut m Model) update(msg tea.Msg) (tea.Model, fn () tea.Msg) {
	return m.clone(), tea.noop_cmd
}

pub fn (m Model) view(mut ctx tea.Context) {
	offset_id := ctx.push_offset(y: 0)
	for i in m.items {
		ctx.push_offset(y: 1)
		ctx.draw_text(0, 0, i.title())
	}
	ctx.clear_offsets_from(offset_id)
}

pub fn (m Model) clone() tea.Model {
	return Model{ ...m }
}


