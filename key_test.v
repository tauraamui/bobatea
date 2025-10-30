module bobatea

import term.ui as tui
import lib.draw

fn test_resolve_key_msg_ctrl_and_a() {
	assert resolve_key_msg(draw.Event{
		modifiers: .ctrl
		code: .a
	}).str() == "ctrl+a"
}

fn test_resolve_key_msg_ctrl_and_symbol() {
	assert resolve_key_msg(draw.Event{
		modifiers: .ctrl
		code: .null
		utf8: "🦈" // inserted char is just shark emoji
	}).str() == "ctrl+🦈"
}

fn test_resolve_key_msg_no_modifiers() {
	assert resolve_key_msg(draw.Event{ utf8: "a" }).str() == "a"
	assert resolve_key_msg(draw.Event{ utf8: "b" }).str() == "b"
	assert resolve_key_msg(draw.Event{ code: .escape }).str() == "escape"
}

