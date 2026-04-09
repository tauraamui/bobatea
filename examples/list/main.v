module main

import tauraamui.bobatea as tea
import pearls.list

struct Item {
	label string
}

fn (i Item) title() string {
	return i.label
}

fn (i Item) filter_value() string {
	return i.label
}

struct Model {
mut:
	list list.Model
}

fn (mut m Model) init() fn () tea.Msg {
	return tea.noop_cmd
}

fn (mut m Model) update(msg tea.Msg) (tea.Model, fn () tea.Msg) {
	match msg {
		tea.KeyMsg {
			match msg.k_type {
				.special {
					if msg.string() == 'escape' {
						return m.clone(), tea.quit
					}
				}
				.runes {
					if msg.string() == 'q' {
						return m.clone(), tea.quit
					}
				}
			}
		}
		else {}
	}
	return m.clone(), tea.noop_cmd
}

fn (m Model) view(mut ctx tea.Context) {
	m.list.view(mut ctx)
}

fn (m Model) clone() tea.Model {
	return Model{ ...m }
}

fn main() {
	items := [
		list.Item(Item{ label: 'First item' }),
		list.Item(Item{ label: 'Second item' }),
		list.Item(Item{ label: 'Third item' }),
	]
	mut model := Model{
		list: list.Model.new(items, 80, 24)
	}
	mut app := tea.new_program(mut model)
	app.run() or { panic('something went wrong: ${err}') }
}

