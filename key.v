module bobatea

import term.ui as tui
import lib.draw

pub fn visible_len(s string) int {
	return utf8_str_visible_length(s)
}

pub enum KeyType as u8 {
	runes
	special
}

pub struct KeyMsg {
pub:
	alt    bool
	runes  []rune
	k_type KeyType
}

pub fn (k KeyMsg) string() string {
	prefix := if k.alt { 'alt+' } else { '' }
	return '${prefix}${k.runes.string()}'
}

const special_keycodes = [
	tui.KeyCode.tab,
	.enter,
	.escape,
	.space,
	.backspace,
	.insert,
	.delete,
	.up,
	.down,
	.right,
	.left,
	.page_up,
	.page_down,
	.home,
	.end,
	.f1,
	.f2,
	.f3,
	.f4,
	.f5,
	.f6,
	.f7,
	.f8,
	.f9,
	.f10,
	.f11,
	.f12,
	.f13,
	.f14,
	.f15,
	.f16,
	.f17,
	.f18,
	.f19,
	.f20,
	.f21,
	.f22,
	.f22,
	.f23,
	.f24,
]

fn resolve_key_msg(e draw.Event) KeyMsg {
	// if modifiers is either ctrl or shift then the only character rep field we want to pay attention to
	// is `code`.
	prefix := if e.modifiers.has(.ctrl) { 'ctrl+' } else { '' }
	is_special := special_keycodes.contains(e.code)

	return KeyMsg{
		alt:    e.modifiers.has(.alt)
		runes:  '${prefix}${code_to_str(e.code, e.utf8, is_special)}'.runes()
		k_type: if is_special || e.modifiers.has(.alt | .ctrl) { .special } else { .runes }
	}
}

fn code_to_str(code tui.KeyCode, fallback string, is_special bool) string {
	return match code {
		.null {
			fallback
		}
		else {
			if is_special {
				code.str()
			} else {
				// For multi-byte UTF-8 characters, use the fallback (utf8 field)
				if fallback.len > 1 || (fallback.len == 1 && fallback.bytes()[0] >= 0x80) {
					fallback
				} else {
					code_str := u8(code).ascii_str()
					// Use fallback if it's an unknown enum value
					if code_str == 'unknown enum value' {
						fallback
					} else if fallback.len == 1 && fallback != code_str && fallback.bytes()[0] >= 32 {
						// Use fallback for printable characters that differ from code_str (like 'A' vs 'a')
						fallback
					} else {
						// For control characters or when fallback matches code_str, use code_str
						code_str
					}
				}
			}
		}
	}
}

/*
WARNING - just here to verify stdlib behaviour for testing, do not use directly, ever!!
*/
fn single_char(buf string) &tui.Event {
	ch := buf[0]

	mut event := &tui.Event{
		typ:   .key_down
		ascii: ch
		code:  unsafe { tui.KeyCode(ch) }
		utf8:  ch.ascii_str()
	}

	match ch {
		// special handling for `ctrl + letter`
		// TODO: Fix assoc in V and remove this workaround :/
		// 1  ... 26 { event = Event{ ...event, code: KeyCode(96 | ch), modifiers: .ctrl  } }
		// 65 ... 90 { event = Event{ ...event, code: KeyCode(32 | ch), modifiers: .shift } }
		// The bit `or`s here are really just `+`'s, just written in this way for a tiny performance improvement
		// don't treat tab, enter as ctrl+i, ctrl+j
		1...8, 11...26 {
			event = &tui.Event{
				typ:       event.typ
				ascii:     event.ascii
				utf8:      event.utf8
				code:      unsafe { tui.KeyCode(96 | ch) }
				modifiers: .ctrl
			}
		}
		65...90 {
			event = &tui.Event{
				typ:       event.typ
				ascii:     event.ascii
				utf8:      event.utf8
				code:      unsafe { tui.KeyCode(32 | ch) }
				modifiers: .shift
			}
		}
		else {}
	}

	return event
}

fn multi_char(buf string) (&tui.Event, int) {
	ch := buf[0]

	mut event := &tui.Event{
		typ:   .key_down
		ascii: ch
		code:  unsafe { tui.KeyCode(ch) }
		utf8:  buf
	}

	match ch {
		// special handling for `ctrl + letter`
		// TODO: Fix assoc in V and remove this workaround :/
		// 1  ... 26 { event = Event{ ...event, code: KeyCode(96 | ch), modifiers: .ctrl  } }
		// 65 ... 90 { event = Event{ ...event, code: KeyCode(32 | ch), modifiers: .shift } }
		// The bit `or`s here are really just `+`'s, just written in this way for a tiny performance improvement
		// don't treat tab, enter as ctrl+i, ctrl+j
		1...8, 11...26 {
			event = &tui.Event{
				typ:       event.typ
				ascii:     event.ascii
				utf8:      event.utf8
				code:      unsafe { tui.KeyCode(96 | ch) }
				modifiers: .ctrl
			}
		}
		65...90 {
			event = &tui.Event{
				typ:       event.typ
				ascii:     event.ascii
				utf8:      event.utf8
				code:      unsafe { tui.KeyCode(32 | ch) }
				modifiers: .shift
			}
		}
		else {}
	}

	return event, buf.len
}
