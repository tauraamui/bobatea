module bobatea

import term.ui as tui
import lib.draw

pub struct KeyMsg {
pub:
	runes []rune

	// legacy/existing fields
	code      tui.KeyCode
	modifiers tui.Modifiers
	utf8      string
	ascii     u8
}

pub fn (k KeyMsg) string() string {
	prefix := if k.modifiers.has(.alt) { "alt+" } else { "" }
	return "${prefix}${k.runes.string()}"
}

fn resolve_key_msg(e draw.Event) KeyMsg {
	// if modifiers is either ctrl or shift then the only character rep field we want to pay attention to
	// is `code`.
	prefix := if e.modifiers.has(.ctrl) { "ctrl+" } else { "" }
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

