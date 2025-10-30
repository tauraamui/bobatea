module bobatea

import term.ui as tui
import lib.draw

enum KeyType as u8 {
	runes
	special
}

pub struct KeyMsg {
pub:
	alt    bool
	runes  []rune
	type KeyType
}

pub fn (k KeyMsg) string() string {
	prefix := if k.alt { "alt+" } else { "" }
	return "${prefix}${k.runes.string()}"
}

const special_keycodes = [tui.KeyCode.tab, .enter, .escape, .space, .backspace]

fn resolve_key_msg(e draw.Event) KeyMsg {
	// if modifiers is either ctrl or shift then the only character rep field we want to pay attention to
	// is `code`.
	prefix := if e.modifiers.has(.ctrl) { "ctrl+" } else { "" }
	is_special := special_keycodes.contains(e.code)
	return KeyMsg{
		alt:   e.modifiers.has(.alt)
		runes: "${prefix}${code_to_str(e.code, e.utf8, is_special)}".runes()
		type: if is_special { .special } else { .runes }
	}
}

fn code_to_str(code tui.KeyCode, fallback string, is_special bool) string {
	v := match code {
		.null { fallback }
		else  {
			code_str := if is_special { code.str() } else { u8(code).ascii_str() }
			if code_str == "unknown enum value" { fallback } else { code_str }
		}
	}
	return v
}

