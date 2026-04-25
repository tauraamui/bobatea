module bobatea

struct TestModel {}

fn (mut m TestModel) init() fn () Msg {
	return noop_cmd
}

fn (mut m TestModel) update(msg Msg) (Model, fn () Msg) {
	return TestModel{}, noop_cmd
}

fn (mut m TestModel) view(mut ctx Context) {}

fn (mut m TestModel) clone() Model {
	return TestModel{}
}

fn test_new_program_without_callback() {
	mut m := TestModel{}
	app := new_program(mut m)
	assert app.on_quit == none
}

fn test_new_program_with_callback() {
	mut m := TestModel{}
	ch := chan bool{cap: 1}
	app := new_program(mut m,
		on_quit: fn [ch] () {
			ch <- true
		}
	)
	assert app.on_quit != none

	if cb := app.on_quit {
		cb()
	}
	assert <-ch == true
}
