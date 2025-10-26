module draw

pub struct Offset {
	x int
	y int
}

pub fn (a Offset) + (b Offset) Offset {
    return Offset{ x: a.x + b.x, y: a.y + b.y }
}


