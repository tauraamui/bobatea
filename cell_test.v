module bobatea

// decode_rune_utf8 replaced a runes() call in write(), so it has to agree with
// runes() on everything the renderer might be handed - including the
// multi-byte characters the editor actually draws, and malformed input, which
// must advance rather than spin.
fn test_decode_rune_utf8_agrees_with_runes() {
	cases := [
		'a',
		'hello world',
		'⠀⣾⣿⣄', // braille, 3 bytes each
		'é', // 2 bytes
		'→', // 3 bytes
		'🦈', // 4 bytes
		'💕',
		'a🦈b→c',
		'👩‍💻', // ZWJ sequence
		'é́', // base plus combining acute
	]
	for c in cases {
		expected := c.runes()
		mut actual := []rune{}
		mut i := 0
		for i < c.len {
			r, size := decode_rune_utf8(c, i)
			assert size > 0, 'zero-size decode would loop forever on ${c}'
			actual << r
			i += size
		}
		assert actual == expected, 'decoding ${c}: expected ${expected}, got ${actual}'
	}
}

fn test_decode_rune_utf8_advances_past_malformed_bytes() {
	// a lone continuation byte is not a valid sequence start
	s := unsafe { tos(c'\x80\x41', 2) }
	r, size := decode_rune_utf8(s, 0)
	assert size == 1
	assert r == rune(0x80)

	// a lead byte promising more bytes than the string holds
	truncated := unsafe { tos(c'\xE2\x82', 2) }
	r2, size2 := decode_rune_utf8(truncated, 0)
	assert size2 == 1
	assert r2 == rune(0xE2)
}

fn test_blank_cell_renders_as_a_space() {
	assert Cell{}.str() == ' '
}

fn test_cell_renders_base_and_combiners_in_order() {
	assert Cell{ base: `a` }.str() == 'a'
	// a base rune with a combining mark is one cell holding both
	combined := Cell{
		base:      `e`
		combiners: &CombinerRunes{
			runes: [rune(0x0301)]
		}
	}
	assert combined.str() == 'é'
}

fn test_cell_equality_covers_base_and_combiners() {
	assert Cell{ base: `a` } == Cell{ base: `a` }
	assert Cell{ base: `a` } != Cell{ base: `b` }
	// a blank cell and a cell holding a space are different cells, even though
	// both render as a space
	assert Cell{} != Cell{ base: ` ` }
	assert Cell{
		base:      `a`
		combiners: &CombinerRunes{
			runes: [rune(0x0301)]
		}
	} != Cell{ base: `a` }
	// separate allocations holding the same marks are the same cell, so
	// equality must resolve the pointer rather than compare it
	assert Cell{
		base:      `a`
		combiners: &CombinerRunes{
			runes: [rune(0x0301)]
		}
	} == Cell{
		base:      `a`
		combiners: &CombinerRunes{
			runes: [rune(0x0301)]
		}
	}
	// an allocated-but-empty sequence is indistinguishable from no sequence
	assert Cell{ base: `a`, combiners: &CombinerRunes{} } == Cell{ base: `a` }
	// the fields the diffing relies on still take part
	assert Cell{ base: `a`, visual_width: 1 } != Cell{ base: `a`, visual_width: 2 }
	assert Cell{ base: `a` } != Cell{ base: `a`, is_continuation: true }
}

// A Cell is paid for width * height * 2 times over, so its size is a budget,
// not an implementation detail. This pins it so a field added without thought
// fails here rather than quietly costing megabytes on a large terminal.
fn test_cell_stays_small() {
	assert sizeof(Cell) == 24, 'Cell grew to ${sizeof(Cell)} bytes'
}

fn test_grid_footprint_counts_both_buffers() {
	one_cell := u64(sizeof(Cell))
	assert grid_footprint_bytes(1, 1) == one_cell * 2
	assert grid_footprint_bytes(200, 50) == one_cell * 10000 * 2
	// a degenerate size is not an error, it is just no grid
	assert grid_footprint_bytes(0, 50) == 0
	assert grid_footprint_bytes(-1, 50) == 0
}
