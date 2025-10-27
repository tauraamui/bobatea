module draw

pub interface Offsetter {
	compact_offsets() Offset
mut:
	push_offset(o Offset) int
	pop_offset() ?Offset
	clear_to_offset(id int)
	clear_from_offset(id int)
	clear_all_offsets()
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


