module draw

import arrays

pub interface Offsetter {
	compact_offsets() Offset
	compact_offsets_to(id int) Offset
	compact_offsets_from(id int) Offset
mut:
	push_offset(o Offset) int
	pop_offset() ?Offset
	clear_to_offset(id int)
	clear_from_offset(id int)
	clear_all_offsets()
}

type Offsets = []Offset

pub fn (l_o Offsets) compact() Offset {
	return arrays.sum(l_o) or { Offset{} }
}

pub struct Offset {
	id int
pub mut:
	x int
	y int
}

pub fn (o Offset) id() int { return o.id }

pub fn (a Offset) + (b Offset) Offset {
    return Offset{ x: a.x + b.x, y: a.y + b.y }
}


