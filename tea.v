module bobatea

import term.ui as tui
import lib.draw

pub struct App {
    render_debug bool
mut:
	ui            &draw.Contextable = unsafe { nil }
    t_ref         &tui.Context
    initial_model Model
}

pub interface Model {
mut:
    init() ?Cmd
    update(Msg) (Model, ?Cmd)
    view(mut draw.Contextable)
}

pub interface Msg {}

pub struct KeyMsg {
pub:
    code tui.KeyCode
}

pub fn quit() Msg {
    return QuitMsg{}
}

pub struct QuitMsg {}

pub type Cmd = fn () Msg

struct NoopMsg {}

fn noop_cmd() Msg {
    return NoopMsg{}
}

pub fn (mut app App) run() ! {
    cmd := app.initial_model.init() or { noop_cmd }
    cmd() // TODO(tauraamui): something with the initial msg?

	ctx, run := draw.new_context(
		render_debug:         false
		user_data:            app
		event_fn:             event
		frame_fn:             frame
		capture_events:       true
		use_alternate_buffer: true
	)
	app.ui = ctx

    run()!
}

fn (mut app App) quit() ! {
    exit(0)
}

fn event(e draw.Event, mut app App) {
    msg := match e.typ {
		.key_down { Msg(KeyMsg{ code: e.code }) }
		.mouse_scroll { Msg(NoopMsg{}) }
		.resized { Msg(NoopMsg{}) }
		else { Msg(NoopMsg{}) }
    }
    m, cmd := app.initial_model.update(msg)
    app.initial_model = m
    u_cmd := cmd or { noop_cmd }
    models_msg := u_cmd()
    if models_msg is QuitMsg {
        app.quit() or { panic(err) }
    }
}

fn frame(mut app App) {
	app.ui.clear()
	app.ui.hide_cursor() // make it default, should think harder about this
	                     // when it comes time to implement dynamic input fields etc.,
	app.initial_model.view(mut app.ui)
	app.ui.reset()
	app.ui.flush()
}

pub fn new_program(mut m Model) App {
    return App{
        t_ref: tui.init(tui.Config{})
        initial_model: m
    }
}

