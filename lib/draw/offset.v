module draw

import arrays

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

pub fn (o Offset) id() int {
	return o.id
}

pub fn (a Offset) + (b Offset) Offset {
	return Offset{
		x: a.x + b.x
		y: a.y + b.y
	}
}
