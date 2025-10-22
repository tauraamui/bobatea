module main

import bobatea as tea
import lib.utf8
import rand
import time

struct EmojiGridModel {}

fn new_emoji_grid_model() EmojiGridModel {
	return EmojiGridModel{}
}

fn (mut m EmojiGridModel) init() ?tea.Cmd {
	return tick_cmd
}

fn tick_cmd() tea.Msg {
	time.sleep(100 * time.millisecond)
	return TickMsg{}
}

struct TickMsg {}

fn (mut m EmojiGridModel) update(msg tea.Msg) (tea.Model, ?tea.Cmd) {
	match msg {
		tea.KeyMsg {
			match msg.code {
				.q, .escape { return EmojiGridModel{}, tea.quit }
				else {}
			}
		}
		TickMsg {
			return m.clone(), tick_cmd
		}
		else {}
	}
	return m.clone(), none
}

fn (m EmojiGridModel) view(mut ctx tea.Context) {
	emoji_chars := utf8.emojis.values()

    width  := ctx.window_width()
    height := ctx.window_height()
	for y in 0 .. height {
		for x in 0 .. (width / 2) {
			index := rand.int_in_range(0, emoji_chars.len) or { 0 }
			emoji := emoji_chars[index]
			ctx.draw_text(x * 2, y, emoji)
		}
	}
}

fn (m EmojiGridModel) clone() tea.Model {
	return EmojiGridModel{
		...m
	}
}
