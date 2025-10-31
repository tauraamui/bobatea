module bobatea

import term.ui as tui
import lib.draw

fn test_resolve_key_msg_ctrl_and_a() {
	assert resolve_key_msg(draw.Event{
		modifiers: .ctrl
		code:      .a
		utf8:      'a'
	}).string() == 'ctrl+a'
}

fn test_resolve_key_msg_ctrl_and_symbol() {
	assert resolve_key_msg(draw.Event{
		modifiers: .ctrl
		code:      .null
		utf8:      '🦈' // inserted char is just shark emoji
	}).string() == 'ctrl+🦈'
}

fn test_resolve_key_msg_modifiers_make_key_special() {
	assert resolve_key_msg(draw.Event{ utf8: 'z' }).k_type == .runes
	assert resolve_key_msg(draw.Event{ modifiers: .ctrl, utf8: 'z' }).k_type == .special
	assert resolve_key_msg(draw.Event{ code: .z, modifiers: .shift, utf8: 'Z' }).k_type == .runes

	assert resolve_key_msg(draw.Event{ code: .c, modifiers: .ctrl, utf8: 'c' }) == KeyMsg{
		runes:  [`c`, `t`, `r`, `l`, `+`, `c`]
		k_type: .special
	}
	assert resolve_key_msg(draw.Event{ code: .c, modifiers: .ctrl, utf8: 'c' }).string() == 'ctrl+c'
}

fn test_resolve_key_msg_to_string_no_modifiers() {
	assert resolve_key_msg(draw.Event{ utf8: 'a' }).string() == 'a'
	assert resolve_key_msg(draw.Event{ utf8: 'b' }).string() == 'b'
	assert resolve_key_msg(draw.Event{ utf8: 'á' }).string() == 'á'

	assert resolve_key_msg(draw.Event{ code: .tab }).string() == 'tab'
	assert resolve_key_msg(draw.Event{ code: .enter }).string() == 'enter'
	assert resolve_key_msg(draw.Event{ code: .escape }).string() == 'escape'
	assert resolve_key_msg(draw.Event{ code: .space }).string() == ' '
	assert resolve_key_msg(draw.Event{ code: .backspace }).string() == 'backspace'
	assert resolve_key_msg(draw.Event{ code: .exclamation }).string() == '!'
	assert resolve_key_msg(draw.Event{ code: .double_quote }).string() == '"'
	assert resolve_key_msg(draw.Event{ code: .hashtag }).string() == '#'
	assert resolve_key_msg(draw.Event{ code: .dollar }).string() == '$'
	assert resolve_key_msg(draw.Event{ code: .percent }).string() == '%'
	assert resolve_key_msg(draw.Event{ code: .ampersand }).string() == '&'
	assert resolve_key_msg(draw.Event{ code: .single_quote }).string() == "'"
	assert resolve_key_msg(draw.Event{ code: .left_paren }).string() == '('
	assert resolve_key_msg(draw.Event{ code: .right_paren }).string() == ')'
	assert resolve_key_msg(draw.Event{ code: .asterisk }).string() == '*'
	assert resolve_key_msg(draw.Event{ code: .plus }).string() == '+'
	assert resolve_key_msg(draw.Event{ code: .comma }).string() == ','
	assert resolve_key_msg(draw.Event{ code: .minus }).string() == '-'
	assert resolve_key_msg(draw.Event{ code: .period }).string() == '.'
	assert resolve_key_msg(draw.Event{ code: .slash }).string() == '/'
	assert resolve_key_msg(draw.Event{ code: ._0 }).string() == '0'
	assert resolve_key_msg(draw.Event{ code: ._1 }).string() == '1'
	assert resolve_key_msg(draw.Event{ code: ._2 }).string() == '2'
	assert resolve_key_msg(draw.Event{ code: ._3 }).string() == '3'
	assert resolve_key_msg(draw.Event{ code: ._4 }).string() == '4'
	assert resolve_key_msg(draw.Event{ code: ._5 }).string() == '5'
	assert resolve_key_msg(draw.Event{ code: ._6 }).string() == '6'
	assert resolve_key_msg(draw.Event{ code: ._7 }).string() == '7'
	assert resolve_key_msg(draw.Event{ code: ._8 }).string() == '8'
	assert resolve_key_msg(draw.Event{ code: ._9 }).string() == '9'
	assert resolve_key_msg(draw.Event{ code: .colon }).string() == ':'
	assert resolve_key_msg(draw.Event{ code: .semicolon }).string() == ';'
	assert resolve_key_msg(draw.Event{ code: .less_than }).string() == '<'
	assert resolve_key_msg(draw.Event{ code: .equal }).string() == '='
	assert resolve_key_msg(draw.Event{ code: .greater_than }).string() == '>'
	assert resolve_key_msg(draw.Event{ code: .question_mark }).string() == '?'
	assert resolve_key_msg(draw.Event{ code: .at }).string() == '@'
	assert resolve_key_msg(draw.Event{ code: .a, utf8: 'a' }).string() == 'a'
	assert resolve_key_msg(draw.Event{ code: .a, utf8: 'A' }).string() == 'A'
	assert resolve_key_msg(draw.Event{ code: .b, utf8: 'b' }).string() == 'b'
	assert resolve_key_msg(draw.Event{ code: .b, utf8: 'B' }).string() == 'B'
	assert resolve_key_msg(draw.Event{ code: .c, utf8: 'c' }).string() == 'c'
	assert resolve_key_msg(draw.Event{ code: .c, utf8: 'C' }).string() == 'C'
	assert resolve_key_msg(draw.Event{ code: .d, utf8: 'd' }).string() == 'd'
	assert resolve_key_msg(draw.Event{ code: .d, utf8: 'D' }).string() == 'D'
	assert resolve_key_msg(draw.Event{ code: .e, utf8: 'e' }).string() == 'e'
	assert resolve_key_msg(draw.Event{ code: .e, utf8: 'E' }).string() == 'E'
	assert resolve_key_msg(draw.Event{ code: .f, utf8: 'f' }).string() == 'f'
	assert resolve_key_msg(draw.Event{ code: .f, utf8: 'F' }).string() == 'F'
	assert resolve_key_msg(draw.Event{ code: .g, utf8: 'g' }).string() == 'g'
	assert resolve_key_msg(draw.Event{ code: .g, utf8: 'G' }).string() == 'G'
	assert resolve_key_msg(draw.Event{ code: .h, utf8: 'h' }).string() == 'h'
	assert resolve_key_msg(draw.Event{ code: .h, utf8: 'H' }).string() == 'H'
	assert resolve_key_msg(draw.Event{ code: .i, utf8: 'i' }).string() == 'i'
	assert resolve_key_msg(draw.Event{ code: .i, utf8: 'I' }).string() == 'I'
	assert resolve_key_msg(draw.Event{ code: .j, utf8: 'j' }).string() == 'j'
	assert resolve_key_msg(draw.Event{ code: .j, utf8: 'J' }).string() == 'J'
	assert resolve_key_msg(draw.Event{ code: .k, utf8: 'k' }).string() == 'k'
	assert resolve_key_msg(draw.Event{ code: .k, utf8: 'K' }).string() == 'K'
	assert resolve_key_msg(draw.Event{ code: .l, utf8: 'l' }).string() == 'l'
	assert resolve_key_msg(draw.Event{ code: .l, utf8: 'L' }).string() == 'L'
	assert resolve_key_msg(draw.Event{ code: .m, utf8: 'm' }).string() == 'm'
	assert resolve_key_msg(draw.Event{ code: .m, utf8: 'M' }).string() == 'M'
	assert resolve_key_msg(draw.Event{ code: .n, utf8: 'n' }).string() == 'n'
	assert resolve_key_msg(draw.Event{ code: .n, utf8: 'N' }).string() == 'N'
	assert resolve_key_msg(draw.Event{ code: .o, utf8: 'o' }).string() == 'o'
	assert resolve_key_msg(draw.Event{ code: .o, utf8: 'O' }).string() == 'O'
	assert resolve_key_msg(draw.Event{ code: .p, utf8: 'p' }).string() == 'p'
	assert resolve_key_msg(draw.Event{ code: .p, utf8: 'P' }).string() == 'P'
	assert resolve_key_msg(draw.Event{ code: .q, utf8: 'q' }).string() == 'q'
	assert resolve_key_msg(draw.Event{ code: .q, utf8: 'Q' }).string() == 'Q'
	assert resolve_key_msg(draw.Event{ code: .r, utf8: 'r' }).string() == 'r'
	assert resolve_key_msg(draw.Event{ code: .r, utf8: 'R' }).string() == 'R'
	assert resolve_key_msg(draw.Event{ code: .s, utf8: 's' }).string() == 's'
	assert resolve_key_msg(draw.Event{ code: .s, utf8: 'S' }).string() == 'S'
	assert resolve_key_msg(draw.Event{ code: .t, utf8: 't' }).string() == 't'
	assert resolve_key_msg(draw.Event{ code: .t, utf8: 'T' }).string() == 'T'
	assert resolve_key_msg(draw.Event{ code: .u, utf8: 'u' }).string() == 'u'
	assert resolve_key_msg(draw.Event{ code: .u, utf8: 'U' }).string() == 'U'
	assert resolve_key_msg(draw.Event{ code: .v, utf8: 'v' }).string() == 'v'
	assert resolve_key_msg(draw.Event{ code: .v, utf8: 'V' }).string() == 'V'
	assert resolve_key_msg(draw.Event{ code: .w, utf8: 'w' }).string() == 'w'
	assert resolve_key_msg(draw.Event{ code: .w, utf8: 'W' }).string() == 'W'
	assert resolve_key_msg(draw.Event{ code: .x, utf8: 'x' }).string() == 'x'
	assert resolve_key_msg(draw.Event{ code: .x, utf8: 'X' }).string() == 'X'
	assert resolve_key_msg(draw.Event{ code: .y, utf8: 'y' }).string() == 'y'
	assert resolve_key_msg(draw.Event{ code: .y, utf8: 'Y' }).string() == 'Y'
	assert resolve_key_msg(draw.Event{ code: .z, utf8: 'z' }).string() == 'z'
	assert resolve_key_msg(draw.Event{ code: .z, utf8: 'Z' }).string() == 'Z'
	assert resolve_key_msg(draw.Event{ code: .left_square_bracket }).string() == '['
	assert resolve_key_msg(draw.Event{ code: .backslash }).string() == '\\'
	assert resolve_key_msg(draw.Event{ code: .right_square_bracket }).string() == ']'
	assert resolve_key_msg(draw.Event{ code: .caret }).string() == '^'
	assert resolve_key_msg(draw.Event{ code: .underscore }).string() == '_'
	assert resolve_key_msg(draw.Event{ code: .backtick }).string() == '`'
	assert resolve_key_msg(draw.Event{ code: .left_curly_bracket }).string() == '{'
	assert resolve_key_msg(draw.Event{ code: .vertical_bar }).string() == '|'
	assert resolve_key_msg(draw.Event{ code: .right_curly_bracket }).string() == '}'
	assert resolve_key_msg(draw.Event{ code: .tilde }).string() == '~'
	assert resolve_key_msg(draw.Event{ code: .vertical_bar }).string() == '|'
	assert resolve_key_msg(draw.Event{ code: .insert }).string() == 'insert'
	assert resolve_key_msg(draw.Event{ code: .delete }).string() == 'delete'
	assert resolve_key_msg(draw.Event{ code: .up }).string() == 'up'
	assert resolve_key_msg(draw.Event{ code: .down }).string() == 'down'
	assert resolve_key_msg(draw.Event{ code: .right }).string() == 'right'
	assert resolve_key_msg(draw.Event{ code: .left }).string() == 'left'
	assert resolve_key_msg(draw.Event{ code: .page_up }).string() == 'page_up'
	assert resolve_key_msg(draw.Event{ code: .page_down }).string() == 'page_down'
	assert resolve_key_msg(draw.Event{ code: .home }).string() == 'home'
	assert resolve_key_msg(draw.Event{ code: .end }).string() == 'end'
	assert resolve_key_msg(draw.Event{ code: .f1 }).string() == 'f1'
	assert resolve_key_msg(draw.Event{ code: .f2 }).string() == 'f2'
	assert resolve_key_msg(draw.Event{ code: .f3 }).string() == 'f3'
	assert resolve_key_msg(draw.Event{ code: .f4 }).string() == 'f4'
	assert resolve_key_msg(draw.Event{ code: .f5 }).string() == 'f5'
	assert resolve_key_msg(draw.Event{ code: .f6 }).string() == 'f6'
	assert resolve_key_msg(draw.Event{ code: .f7 }).string() == 'f7'
	assert resolve_key_msg(draw.Event{ code: .f8 }).string() == 'f8'
	assert resolve_key_msg(draw.Event{ code: .f9 }).string() == 'f9'
	assert resolve_key_msg(draw.Event{ code: .f10 }).string() == 'f10'
	assert resolve_key_msg(draw.Event{ code: .f11 }).string() == 'f11'
	assert resolve_key_msg(draw.Event{ code: .f12 }).string() == 'f12'
	assert resolve_key_msg(draw.Event{ code: .f13 }).string() == 'f13'
	assert resolve_key_msg(draw.Event{ code: .f14 }).string() == 'f14'
	assert resolve_key_msg(draw.Event{ code: .f15 }).string() == 'f15'
	assert resolve_key_msg(draw.Event{ code: .f16 }).string() == 'f16'
	assert resolve_key_msg(draw.Event{ code: .f17 }).string() == 'f17'
	assert resolve_key_msg(draw.Event{ code: .f18 }).string() == 'f18'
	assert resolve_key_msg(draw.Event{ code: .f19 }).string() == 'f19'
	assert resolve_key_msg(draw.Event{ code: .f20 }).string() == 'f20'
	assert resolve_key_msg(draw.Event{ code: .f21 }).string() == 'f21'
	assert resolve_key_msg(draw.Event{ code: .f22 }).string() == 'f22'
	assert resolve_key_msg(draw.Event{ code: .f23 }).string() == 'f23'
	assert resolve_key_msg(draw.Event{ code: .f24 }).string() == 'f24'
}

fn test_resolve_key_msg_to_string_with_ctrl_modifier() {
	assert resolve_key_msg(draw.Event{ utf8: 'a', modifiers: .ctrl }).string() == 'ctrl+a'
	assert resolve_key_msg(draw.Event{ utf8: 'b', modifiers: .ctrl }).string() == 'ctrl+b'
	assert resolve_key_msg(draw.Event{ utf8: 'á', modifiers: .ctrl }).string() == 'ctrl+á'

	assert resolve_key_msg(draw.Event{ code: .tab, modifiers: .ctrl }).string() == 'ctrl+tab'
	assert resolve_key_msg(draw.Event{ code: .enter, modifiers: .ctrl }).string() == 'ctrl+enter'
	assert resolve_key_msg(draw.Event{ code: .escape, modifiers: .ctrl }).string() == 'ctrl+escape'
	assert resolve_key_msg(draw.Event{ code: .space, modifiers: .ctrl }).string() == 'ctrl+ '
	assert resolve_key_msg(draw.Event{ code: .backspace, modifiers: .ctrl }).string() == 'ctrl+backspace'
	assert resolve_key_msg(draw.Event{ code: .exclamation, modifiers: .ctrl }).string() == 'ctrl+!'
	assert resolve_key_msg(draw.Event{ code: .double_quote, modifiers: .ctrl }).string() == 'ctrl+"'
	assert resolve_key_msg(draw.Event{ code: .hashtag, modifiers: .ctrl }).string() == 'ctrl+#'
	assert resolve_key_msg(draw.Event{ code: .dollar, modifiers: .ctrl }).string() == 'ctrl+$'
	assert resolve_key_msg(draw.Event{ code: .percent, modifiers: .ctrl }).string() == 'ctrl+%'
	assert resolve_key_msg(draw.Event{ code: .ampersand, modifiers: .ctrl }).string() == 'ctrl+&'
	assert resolve_key_msg(draw.Event{ code: .single_quote, modifiers: .ctrl }).string() == "ctrl+'"
	assert resolve_key_msg(draw.Event{ code: .left_paren, modifiers: .ctrl }).string() == 'ctrl+('
	assert resolve_key_msg(draw.Event{ code: .right_paren, modifiers: .ctrl }).string() == 'ctrl+)'
	assert resolve_key_msg(draw.Event{ code: .asterisk, modifiers: .ctrl }).string() == 'ctrl+*'
	assert resolve_key_msg(draw.Event{ code: .plus, modifiers: .ctrl }).string() == 'ctrl++'
	assert resolve_key_msg(draw.Event{ code: .comma, modifiers: .ctrl }).string() == 'ctrl+,'
	assert resolve_key_msg(draw.Event{ code: .minus, modifiers: .ctrl }).string() == 'ctrl+-'
	assert resolve_key_msg(draw.Event{ code: .period, modifiers: .ctrl }).string() == 'ctrl+.'
	assert resolve_key_msg(draw.Event{ code: .slash, modifiers: .ctrl }).string() == 'ctrl+/'
	assert resolve_key_msg(draw.Event{ code: ._0, modifiers: .ctrl }).string() == 'ctrl+0'
	assert resolve_key_msg(draw.Event{ code: ._1, modifiers: .ctrl }).string() == 'ctrl+1'
	assert resolve_key_msg(draw.Event{ code: ._2, modifiers: .ctrl }).string() == 'ctrl+2'
	assert resolve_key_msg(draw.Event{ code: ._3, modifiers: .ctrl }).string() == 'ctrl+3'
	assert resolve_key_msg(draw.Event{ code: ._4, modifiers: .ctrl }).string() == 'ctrl+4'
	assert resolve_key_msg(draw.Event{ code: ._5, modifiers: .ctrl }).string() == 'ctrl+5'
	assert resolve_key_msg(draw.Event{ code: ._6, modifiers: .ctrl }).string() == 'ctrl+6'
	assert resolve_key_msg(draw.Event{ code: ._7, modifiers: .ctrl }).string() == 'ctrl+7'
	assert resolve_key_msg(draw.Event{ code: ._8, modifiers: .ctrl }).string() == 'ctrl+8'
	assert resolve_key_msg(draw.Event{ code: ._9, modifiers: .ctrl }).string() == 'ctrl+9'
	assert resolve_key_msg(draw.Event{ code: .colon, modifiers: .ctrl }).string() == 'ctrl+:'
	assert resolve_key_msg(draw.Event{ code: .semicolon, modifiers: .ctrl }).string() == 'ctrl+;'
	assert resolve_key_msg(draw.Event{ code: .less_than, modifiers: .ctrl }).string() == 'ctrl+<'
	assert resolve_key_msg(draw.Event{ code: .equal, modifiers: .ctrl }).string() == 'ctrl+='
	assert resolve_key_msg(draw.Event{ code: .greater_than, modifiers: .ctrl }).string() == 'ctrl+>'
	assert resolve_key_msg(draw.Event{ code: .question_mark, modifiers: .ctrl }).string() == 'ctrl+?'
	assert resolve_key_msg(draw.Event{ code: .at, modifiers: .ctrl }).string() == 'ctrl+@'
	assert resolve_key_msg(draw.Event{ code: .a, modifiers: .ctrl, utf8: 'a' }).string() == 'ctrl+a'
	assert resolve_key_msg(draw.Event{ code: .a, modifiers: .ctrl, utf8: 'A' }).string() == 'ctrl+A'
	assert resolve_key_msg(draw.Event{ code: .b, modifiers: .ctrl, utf8: 'b' }).string() == 'ctrl+b'
	assert resolve_key_msg(draw.Event{ code: .b, modifiers: .ctrl, utf8: 'B' }).string() == 'ctrl+B'
	assert resolve_key_msg(draw.Event{ code: .c, modifiers: .ctrl, utf8: 'c' }).string() == 'ctrl+c'
	assert resolve_key_msg(draw.Event{ code: .c, modifiers: .ctrl, utf8: 'C' }).string() == 'ctrl+C'
	assert resolve_key_msg(draw.Event{ code: .d, modifiers: .ctrl, utf8: 'd' }).string() == 'ctrl+d'
	assert resolve_key_msg(draw.Event{ code: .d, modifiers: .ctrl, utf8: 'D' }).string() == 'ctrl+D'
	assert resolve_key_msg(draw.Event{ code: .e, modifiers: .ctrl, utf8: 'e' }).string() == 'ctrl+e'
	assert resolve_key_msg(draw.Event{ code: .e, modifiers: .ctrl, utf8: 'E' }).string() == 'ctrl+E'
	assert resolve_key_msg(draw.Event{ code: .f, modifiers: .ctrl, utf8: 'f' }).string() == 'ctrl+f'
	assert resolve_key_msg(draw.Event{ code: .f, modifiers: .ctrl, utf8: 'F' }).string() == 'ctrl+F'
	assert resolve_key_msg(draw.Event{ code: .g, modifiers: .ctrl, utf8: 'g' }).string() == 'ctrl+g'
	assert resolve_key_msg(draw.Event{ code: .g, modifiers: .ctrl, utf8: 'G' }).string() == 'ctrl+G'
	assert resolve_key_msg(draw.Event{ code: .h, modifiers: .ctrl, utf8: 'h' }).string() == 'ctrl+h'
	assert resolve_key_msg(draw.Event{ code: .h, modifiers: .ctrl, utf8: 'H' }).string() == 'ctrl+H'
	assert resolve_key_msg(draw.Event{ code: .i, modifiers: .ctrl, utf8: 'i' }).string() == 'ctrl+i'
	assert resolve_key_msg(draw.Event{ code: .i, modifiers: .ctrl, utf8: 'I' }).string() == 'ctrl+I'
	assert resolve_key_msg(draw.Event{ code: .j, modifiers: .ctrl, utf8: 'j' }).string() == 'ctrl+j'
	assert resolve_key_msg(draw.Event{ code: .j, modifiers: .ctrl, utf8: 'J' }).string() == 'ctrl+J'
	assert resolve_key_msg(draw.Event{ code: .k, modifiers: .ctrl, utf8: 'k' }).string() == 'ctrl+k'
	assert resolve_key_msg(draw.Event{ code: .k, modifiers: .ctrl, utf8: 'K' }).string() == 'ctrl+K'
	assert resolve_key_msg(draw.Event{ code: .l, modifiers: .ctrl, utf8: 'l' }).string() == 'ctrl+l'
	assert resolve_key_msg(draw.Event{ code: .l, modifiers: .ctrl, utf8: 'L' }).string() == 'ctrl+L'
	assert resolve_key_msg(draw.Event{ code: .m, modifiers: .ctrl, utf8: 'm' }).string() == 'ctrl+m'
	assert resolve_key_msg(draw.Event{ code: .m, modifiers: .ctrl, utf8: 'M' }).string() == 'ctrl+M'
	assert resolve_key_msg(draw.Event{ code: .n, modifiers: .ctrl, utf8: 'n' }).string() == 'ctrl+n'
	assert resolve_key_msg(draw.Event{ code: .n, modifiers: .ctrl, utf8: 'N' }).string() == 'ctrl+N'
	assert resolve_key_msg(draw.Event{ code: .o, modifiers: .ctrl, utf8: 'o' }).string() == 'ctrl+o'
	assert resolve_key_msg(draw.Event{ code: .o, modifiers: .ctrl, utf8: 'O' }).string() == 'ctrl+O'
	assert resolve_key_msg(draw.Event{ code: .p, modifiers: .ctrl, utf8: 'p' }).string() == 'ctrl+p'
	assert resolve_key_msg(draw.Event{ code: .p, modifiers: .ctrl, utf8: 'P' }).string() == 'ctrl+P'
	assert resolve_key_msg(draw.Event{ code: .q, modifiers: .ctrl, utf8: 'q' }).string() == 'ctrl+q'
	assert resolve_key_msg(draw.Event{ code: .q, modifiers: .ctrl, utf8: 'Q' }).string() == 'ctrl+Q'
	assert resolve_key_msg(draw.Event{ code: .r, modifiers: .ctrl, utf8: 'r' }).string() == 'ctrl+r'
	assert resolve_key_msg(draw.Event{ code: .r, modifiers: .ctrl, utf8: 'R' }).string() == 'ctrl+R'
	assert resolve_key_msg(draw.Event{ code: .s, modifiers: .ctrl, utf8: 's' }).string() == 'ctrl+s'
	assert resolve_key_msg(draw.Event{ code: .s, modifiers: .ctrl, utf8: 'S' }).string() == 'ctrl+S'
	assert resolve_key_msg(draw.Event{ code: .t, modifiers: .ctrl, utf8: 't' }).string() == 'ctrl+t'
	assert resolve_key_msg(draw.Event{ code: .t, modifiers: .ctrl, utf8: 'T' }).string() == 'ctrl+T'
	assert resolve_key_msg(draw.Event{ code: .u, modifiers: .ctrl, utf8: 'u' }).string() == 'ctrl+u'
	assert resolve_key_msg(draw.Event{ code: .u, modifiers: .ctrl, utf8: 'U' }).string() == 'ctrl+U'
	assert resolve_key_msg(draw.Event{ code: .v, modifiers: .ctrl, utf8: 'v' }).string() == 'ctrl+v'
	assert resolve_key_msg(draw.Event{ code: .v, modifiers: .ctrl, utf8: 'V' }).string() == 'ctrl+V'
	assert resolve_key_msg(draw.Event{ code: .w, modifiers: .ctrl, utf8: 'w' }).string() == 'ctrl+w'
	assert resolve_key_msg(draw.Event{ code: .w, modifiers: .ctrl, utf8: 'W' }).string() == 'ctrl+W'
	assert resolve_key_msg(draw.Event{ code: .x, modifiers: .ctrl, utf8: 'x' }).string() == 'ctrl+x'
	assert resolve_key_msg(draw.Event{ code: .x, modifiers: .ctrl, utf8: 'X' }).string() == 'ctrl+X'
	assert resolve_key_msg(draw.Event{ code: .y, modifiers: .ctrl, utf8: 'y' }).string() == 'ctrl+y'
	assert resolve_key_msg(draw.Event{ code: .y, modifiers: .ctrl, utf8: 'Y' }).string() == 'ctrl+Y'
	assert resolve_key_msg(draw.Event{ code: .z, modifiers: .ctrl, utf8: 'z' }).string() == 'ctrl+z'
	assert resolve_key_msg(draw.Event{ code: .z, modifiers: .ctrl, utf8: 'Z' }).string() == 'ctrl+Z'
	assert resolve_key_msg(draw.Event{ code: .left_square_bracket, modifiers: .ctrl }).string() == 'ctrl+['
	assert resolve_key_msg(draw.Event{ code: .backslash, modifiers: .ctrl }).string() == 'ctrl+\\'
	assert resolve_key_msg(draw.Event{ code: .right_square_bracket, modifiers: .ctrl }).string() == 'ctrl+]'
	assert resolve_key_msg(draw.Event{ code: .caret, modifiers: .ctrl }).string() == 'ctrl+^'
	assert resolve_key_msg(draw.Event{ code: .underscore, modifiers: .ctrl }).string() == 'ctrl+_'
	assert resolve_key_msg(draw.Event{ code: .backtick, modifiers: .ctrl }).string() == 'ctrl+`'
	assert resolve_key_msg(draw.Event{ code: .left_curly_bracket, modifiers: .ctrl }).string() == 'ctrl+{'
	assert resolve_key_msg(draw.Event{ code: .vertical_bar, modifiers: .ctrl }).string() == 'ctrl+|'
	assert resolve_key_msg(draw.Event{ code: .right_curly_bracket, modifiers: .ctrl }).string() == 'ctrl+}'
	assert resolve_key_msg(draw.Event{ code: .tilde, modifiers: .ctrl }).string() == 'ctrl+~'
	assert resolve_key_msg(draw.Event{ code: .vertical_bar, modifiers: .ctrl }).string() == 'ctrl+|'
	assert resolve_key_msg(draw.Event{ code: .insert, modifiers: .ctrl }).string() == 'ctrl+insert'
	assert resolve_key_msg(draw.Event{ code: .delete, modifiers: .ctrl }).string() == 'ctrl+delete'
	assert resolve_key_msg(draw.Event{ code: .up, modifiers: .ctrl }).string() == 'ctrl+up'
	assert resolve_key_msg(draw.Event{ code: .down, modifiers: .ctrl }).string() == 'ctrl+down'
	assert resolve_key_msg(draw.Event{ code: .right, modifiers: .ctrl }).string() == 'ctrl+right'
	assert resolve_key_msg(draw.Event{ code: .left, modifiers: .ctrl }).string() == 'ctrl+left'
	assert resolve_key_msg(draw.Event{ code: .page_up, modifiers: .ctrl }).string() == 'ctrl+page_up'
	assert resolve_key_msg(draw.Event{ code: .page_down, modifiers: .ctrl }).string() == 'ctrl+page_down'
	assert resolve_key_msg(draw.Event{ code: .home, modifiers: .ctrl }).string() == 'ctrl+home'
	assert resolve_key_msg(draw.Event{ code: .end, modifiers: .ctrl }).string() == 'ctrl+end'
	assert resolve_key_msg(draw.Event{ code: .f1, modifiers: .ctrl }).string() == 'ctrl+f1'
	assert resolve_key_msg(draw.Event{ code: .f2, modifiers: .ctrl }).string() == 'ctrl+f2'
	assert resolve_key_msg(draw.Event{ code: .f3, modifiers: .ctrl }).string() == 'ctrl+f3'
	assert resolve_key_msg(draw.Event{ code: .f4, modifiers: .ctrl }).string() == 'ctrl+f4'
	assert resolve_key_msg(draw.Event{ code: .f5, modifiers: .ctrl }).string() == 'ctrl+f5'
	assert resolve_key_msg(draw.Event{ code: .f6, modifiers: .ctrl }).string() == 'ctrl+f6'
	assert resolve_key_msg(draw.Event{ code: .f7, modifiers: .ctrl }).string() == 'ctrl+f7'
	assert resolve_key_msg(draw.Event{ code: .f8, modifiers: .ctrl }).string() == 'ctrl+f8'
	assert resolve_key_msg(draw.Event{ code: .f9, modifiers: .ctrl }).string() == 'ctrl+f9'
	assert resolve_key_msg(draw.Event{ code: .f10, modifiers: .ctrl }).string() == 'ctrl+f10'
	assert resolve_key_msg(draw.Event{ code: .f11, modifiers: .ctrl }).string() == 'ctrl+f11'
	assert resolve_key_msg(draw.Event{ code: .f12, modifiers: .ctrl }).string() == 'ctrl+f12'
	assert resolve_key_msg(draw.Event{ code: .f13, modifiers: .ctrl }).string() == 'ctrl+f13'
	assert resolve_key_msg(draw.Event{ code: .f14, modifiers: .ctrl }).string() == 'ctrl+f14'
	assert resolve_key_msg(draw.Event{ code: .f15, modifiers: .ctrl }).string() == 'ctrl+f15'
	assert resolve_key_msg(draw.Event{ code: .f16, modifiers: .ctrl }).string() == 'ctrl+f16'
	assert resolve_key_msg(draw.Event{ code: .f17, modifiers: .ctrl }).string() == 'ctrl+f17'
	assert resolve_key_msg(draw.Event{ code: .f18, modifiers: .ctrl }).string() == 'ctrl+f18'
	assert resolve_key_msg(draw.Event{ code: .f19, modifiers: .ctrl }).string() == 'ctrl+f19'
	assert resolve_key_msg(draw.Event{ code: .f20, modifiers: .ctrl }).string() == 'ctrl+f20'
	assert resolve_key_msg(draw.Event{ code: .f21, modifiers: .ctrl }).string() == 'ctrl+f21'
	assert resolve_key_msg(draw.Event{ code: .f22, modifiers: .ctrl }).string() == 'ctrl+f22'
	assert resolve_key_msg(draw.Event{ code: .f23, modifiers: .ctrl }).string() == 'ctrl+f23'
	assert resolve_key_msg(draw.Event{ code: .f24, modifiers: .ctrl }).string() == 'ctrl+f24'
}

fn test_resolve_key_msg_from_c() {
	c := single_char('c')
	c_msg := resolve_key_msg(draw.Event{
		code:      c.code
		modifiers: c.modifiers
		utf8:      c.utf8
		ascii:     c.ascii
	})
	assert c_msg == KeyMsg{
		runes:  [`c`]
		k_type: .runes
	}
}

fn test_resolve_key_msg_from_accent_e() {
	// Simulate what happens when a real TUI application receives UTF-8 input
	// In practice, the TUI library would provide the complete UTF-8 string
	original_utf8 := [u8(0xc3), 0xa9].bytestr()

	// Create an event that represents what a proper TUI implementation would provide
	accent_e_msg := resolve_key_msg(draw.Event{
		utf8: original_utf8
	})
	assert [u8(0xc3), 0xa9].byterune()! == `é`
	assert [u8(0xc3), 0xa9].bytestr() == 'é'
	assert accent_e_msg == KeyMsg{
		runes:  [`é`]
		k_type: .runes
	}
}

fn test_resolve_key_msg_from_ae() {
	// Simulate what happens when a real TUI application receives UTF-8 input
	// In practice, the TUI library would provide the complete UTF-8 string
	original_utf8 := [u8(0xc3), 0xa6].bytestr()

	// Create an event that represents what a proper TUI implementation would provide
	ae_msg := resolve_key_msg(draw.Event{
		utf8: original_utf8
	})
	assert [u8(0xc3), 0xa6].byterune()! == `æ`
	assert [u8(0xc3), 0xa6].bytestr() == 'æ'
	assert ae_msg == KeyMsg{
		runes:  [`æ`]
		k_type: .runes
	}
}

fn test_resolve_key_msg_from_ctrl_and_c() {
	e := single_char(u8(3).ascii_str())
	ctrl_and_c_msg := resolve_key_msg(draw.Event{
		code:      e.code
		modifiers: e.modifiers
		utf8:      e.utf8
		ascii:     e.ascii
	})
	assert ctrl_and_c_msg == KeyMsg{
		runes:  [`c`, `t`, `r`, `l`, `+`, `c`]
		k_type: .special
	}
}

fn test_single_char_ctrl_and_c() {
	e := single_char(u8(3).ascii_str())
	assert e.modifiers == .ctrl
	assert e.code == .c
}
