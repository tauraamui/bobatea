module bobatea

import term.ui as tui
import lib.draw
import strings

pub struct KeyMsg {
pub:
	runes []rune

	// legacy/existing fields
	code      tui.KeyCode
	modifiers tui.Modifiers
	utf8      string
	ascii     u8
}

fn (k KeyMsg) str() string {
	mut sb := strings.new_builder(k.runes.len)
	if k.modifiers.has(.alt) { sb.write_string("alt+") }
	sb.write_runes(k.runes)
	return sb.str()
}

fn resolve_key_msg(e draw.Event) KeyMsg {
	// if modifiers is either ctrl or shift then the only character rep field we want to pay attention to
	// is `code`.
	if e.modifiers.has(.ctrl) {
		key_code := e.code
		if e.code.str() != "unknown enum value" {
			v := match e.code {
				.null { e.utf8 }
				else  { e.code.str() }
			}
			return KeyMsg{
				runes: "ctrl+${v}".runes()
			}
		}
		return KeyMsg{}
	}
	return KeyMsg{
		code: e.code
		modifiers: e.modifiers
		utf8: e.utf8
		ascii: e.ascii
	}
}

