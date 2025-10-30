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

pub fn (k KeyMsg) str() string {
	mut sb := strings.new_builder(k.runes.len)
	if k.modifiers.has(.alt) { sb.write_string("alt+") }
	sb.write_runes(k.runes)
	return sb.str()
}

fn resolve_key_msg(e draw.Event) KeyMsg {
	// if modifiers is either ctrl or shift then the only character rep field we want to pay attention to
	// is `code`.
	prefix := if e.modifiers.has(.ctrl) { "ctrl+" } else { "" }
	key_code := e.code
	v := match e.code {
		.null { e.utf8 }
		else  {
			code_str := e.code.str()
			if code_str == "unknown enum value" { e.utf8 } else { code_str }
		}
	}
	return KeyMsg{
		runes: "${prefix}${v}".runes()
	}
}

