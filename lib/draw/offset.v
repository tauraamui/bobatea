module draw

pub interface Offsetter {
	compact_offsets() Offset
mut:
	push_offset(o Offset)
	pop_offset() ?Offset
	clear_offsets()
}

pub struct Offset {
	x int
	y int
}

pub fn (a Offset) + (b Offset) Offset {
    return Offset{ x: a.x + b.x, y: a.y + b.y }
}


