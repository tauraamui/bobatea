module bobatea

import term.ui as tui
import lib.draw

fn test_resolve_key_msg_ctrl_and_a() {
	assert resolve_key_msg(draw.Event{
		modifiers: .ctrl
		code: .a
	}).string() == "ctrl+a"
}

fn test_resolve_key_msg_ctrl_and_symbol() {
	assert resolve_key_msg(draw.Event{
		modifiers: .ctrl
		code: .null
		utf8: "🦈" // inserted char is just shark emoji
	}).string() == "ctrl+🦈"
}

fn test_resolve_key_msg_to_string_no_modifiers() {
	assert resolve_key_msg(draw.Event{ utf8: "a" }).string() == "a"
	assert resolve_key_msg(draw.Event{ utf8: "b" }).string() == "b"
	assert resolve_key_msg(draw.Event{ utf8: "á" }).string() == "á"

	assert resolve_key_msg(draw.Event{ code: .a }).string() == "a"
	assert resolve_key_msg(draw.Event{ code: .tab }).string() == "tab"
	assert resolve_key_msg(draw.Event{ code: .enter }).string() == "enter"
	assert resolve_key_msg(draw.Event{ code: .escape }).string() == "escape"
	assert resolve_key_msg(draw.Event{ code: .space }).string() == "space"
	assert resolve_key_msg(draw.Event{ code: .backspace }).string() == "backspace"
	assert resolve_key_msg(draw.Event{ code: .exclamation }).string() == "!"
	assert resolve_key_msg(draw.Event{ code: .double_quote }).string() == "\""
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
	assert resolve_key_msg(draw.Event{ code: .a }).string() == 'a'
	assert resolve_key_msg(draw.Event{ code: .b }).string() == 'b'
	assert resolve_key_msg(draw.Event{ code: .c }).string() == 'c'
	assert resolve_key_msg(draw.Event{ code: .d }).string() == 'd'
	assert resolve_key_msg(draw.Event{ code: .e }).string() == 'e'
	assert resolve_key_msg(draw.Event{ code: .f }).string() == 'f'
	assert resolve_key_msg(draw.Event{ code: .g }).string() == 'g'
	assert resolve_key_msg(draw.Event{ code: .h }).string() == 'h'
	assert resolve_key_msg(draw.Event{ code: .i }).string() == 'i'
	assert resolve_key_msg(draw.Event{ code: .j }).string() == 'j'
	assert resolve_key_msg(draw.Event{ code: .k }).string() == 'k'
	assert resolve_key_msg(draw.Event{ code: .l }).string() == 'l'
	assert resolve_key_msg(draw.Event{ code: .m }).string() == 'm'
	assert resolve_key_msg(draw.Event{ code: .n }).string() == 'n'
	assert resolve_key_msg(draw.Event{ code: .o }).string() == 'o'
	assert resolve_key_msg(draw.Event{ code: .p }).string() == 'p'
	assert resolve_key_msg(draw.Event{ code: .q }).string() == 'q'
	assert resolve_key_msg(draw.Event{ code: .r }).string() == 'r'
	assert resolve_key_msg(draw.Event{ code: .s }).string() == 's'
	assert resolve_key_msg(draw.Event{ code: .t }).string() == 't'
	assert resolve_key_msg(draw.Event{ code: .u }).string() == 'u'
	assert resolve_key_msg(draw.Event{ code: .v }).string() == 'v'
	assert resolve_key_msg(draw.Event{ code: .w }).string() == 'w'
	assert resolve_key_msg(draw.Event{ code: .x }).string() == 'x'
	assert resolve_key_msg(draw.Event{ code: .y }).string() == 'y'
	assert resolve_key_msg(draw.Event{ code: .z }).string() == 'z'
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

