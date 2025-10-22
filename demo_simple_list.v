module main

import bobatea as tea

struct SimpleListModel {
    items            []string
mut:
    selected_index   int
}

fn new_simple_list_model() SimpleListModel {
    return SimpleListModel{
        items: [
            "Ramen",
            "Tomato Soup",
            "Hamburgers",
            "Cheeseburgers",
            "Currywurst",
            "Okonomiyaki",
            "Pasta",
            "Fillet Mignon",
            "Caviar",
            "Just Wine"
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
                .q { return SimpleListModel{}, tea.quit }
                .enter {
                    // we have no non-fullscreen yet, nor any ability to render post full screen close
                }
                .down {
                    m.selected_index = if m.selected_index + 1 > m.items.len { 0 } else { m.selected_index + 1 }
                }
                .up {
                    m.selected_index = if m.selected_index - 1 < 0 { m.items.len } else { m.selected_index - 1 }
                }
                else{}
            }
        }
        else {}
    }
    return m.clone(), none
}

fn (m SimpleListModel) view(mut ctx tea.Context) {
    ctx.push_offset(tea.Offset{ x: 2, y: 1 })
    ctx.draw_text(0, 0, "What do you want for dinner?")
    ctx.push_offset(tea.Offset{ x: 1, y: 2 })
    for y, item in m.items {
        if y == m.selected_index {
            ctx.set_color(tea.Color.ansi(170))
            ctx.draw_text(0, y, ">")
        }
        ctx.draw_text(2, y, "${y + 1}. ${item}")
        ctx.reset_color()
    }

    ctx.pop_offset()
    ctx.pop_offset()
}

fn (m SimpleListModel) clone() tea.Model {
    return SimpleListModel{
        ...m
    }
}

