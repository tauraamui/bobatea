module main

import bobatea as tea

struct SimpleListModel {
	items []string
mut:
	selected_index int
}

fn new_simple_list_model() SimpleListModel {
	return SimpleListModel{
		items: [
			'Ramen',
			'Tomato Soup',
			'Hamburgers',
			'Cheeseburgers',
			'Currywurst',
			'Okonomiyaki',
			'Pasta',
			'Fillet Mignon',
			'Caviar',
			'Just Wine',
		]
	}
}

fn (mut m SimpleListModel) init() ?tea.Cmd {
	return none
}

fn (mut m SimpleListModel) update(msg tea.Msg) (tea.Model, ?tea.Cmd) {
	match msg {
		tea.KeyMsg {
			match msg.code {
				.q {
					return SimpleListModel{}, tea.quit
				}
				.enter {
					// we have no non-fullscreen yet, nor any ability to render post full screen close
				}
				.j {
					m.down()
				}
				.k {
					m.up()
				}
				.down {
					m.down()
				}
				.up {
					m.up()
				}
				else {}
			}
		}
		else {}
	}
	return m.clone(), none
}

fn (mut m SimpleListModel) up() {
	m.selected_index = if m.selected_index - 1 < 0 { m.items.len - 1 } else { m.selected_index - 1 }
}

fn (mut m SimpleListModel) down() {
	m.selected_index = if m.selected_index + 1 > m.items.len { 0 } else { m.selected_index + 1 }
}

fn (m SimpleListModel) view(mut ctx tea.Context) {
	defer { ctx.clear_offset() }
	ctx.push_offset(tea.Offset{ x: 2, y: 1 })
	ctx.draw_text(2, 0, 'What do you want for dinner?')
	ctx.push_offset(tea.Offset{ x: 0, y: 2 })
	for y, item in m.items {
		if y == m.selected_index {
			ctx.set_color(tea.Color.ansi(170))
			ctx.draw_text(0, 0, '>')
		}
		ctx.draw_text(2, 0, '${y + 1}. ${item}')
		ctx.push_offset(tea.Offset{ y: 1 })
		ctx.reset_color()
	}

	ctx.push_offset(tea.Offset{ y: 1 })
	ctx.set_color(tea.Color.ansi(241))
	ctx.draw_text(2, 0, '↑/k up • ↓/j down • q: exit')
	ctx.reset_color()
}

fn (m SimpleListModel) clone() tea.Model {
	return SimpleListModel{
		...m
	}
}
