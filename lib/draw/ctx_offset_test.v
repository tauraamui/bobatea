module draw

fn test_context_offset_push_affects_apply() {
	mut t_ctx := Context{
		ref: unsafe { nil }
	}
	t_ctx.setup_grid()!

	t_ctx.push_offset(Offset{ x: 10, y: 21 })

	mut xx, mut yy := apply_offsets(t_ctx.offsets, 0, 0)
	assert xx == 10
	assert yy == 21

	xx, yy = apply_offsets(t_ctx.offsets, 99, 72)
	assert xx == 109
	assert yy == 93
}

fn test_context_sequential_offset_last_on_first_off() {
	mut t_ctx := Context{
		ref: unsafe { nil }
	}
	t_ctx.setup_grid()!

	mut xx, mut yy := apply_offsets(t_ctx.offsets, 0, 0)
	assert xx == 0
	assert yy == 0

	t_ctx.push_offset(Offset{ x: 1, y: 1 })

	xx, yy = apply_offsets(t_ctx.offsets, 0, 0)
	assert xx == 1
	assert yy == 1

	t_ctx.push_offset(Offset{ x: 2, y: 2 })

	xx, yy = apply_offsets(t_ctx.offsets, 0, 0)
	assert xx == 3
	assert yy == 3

	t_ctx.push_offset(Offset{ x: 5, y: 5 })

	xx, yy = apply_offsets(t_ctx.offsets, 0, 0)
	assert xx == 8
	assert yy == 8

	t_ctx.push_offset(Offset{ x: 8, y: 8 })

	xx, yy = apply_offsets(t_ctx.offsets, 0, 0)
	assert xx == 16
	assert yy == 16

	t_ctx.pop_offset()

	xx, yy = apply_offsets(t_ctx.offsets, 0, 0)
	assert xx == 8
	assert yy == 8

	t_ctx.pop_offset()

	xx, yy = apply_offsets(t_ctx.offsets, 0, 0)
	assert xx == 3
	assert yy == 3

	t_ctx.pop_offset()

	xx, yy = apply_offsets(t_ctx.offsets, 0, 0)
	assert xx == 1
	assert yy == 1

	t_ctx.pop_offset()

	xx, yy = apply_offsets(t_ctx.offsets, 0, 0)
	assert xx == 0
	assert yy == 0
}

fn test_context_offset_clear_from_offset() {
	mut t_ctx := Context{
		ref: unsafe { nil }
	}
	t_ctx.setup_grid()!

	t_ctx.push_offset(Offset{ x: 1, y: 1 })
	t_ctx.push_offset(Offset{ x: 2, y: 2 })
	bookmark_id := t_ctx.push_offset(Offset{ x: 5, y: 5 })
	assert t_ctx.map_id_to_index(bookmark_id)? == 2 // ensure correct index resolved from id lookup
	t_ctx.push_offset(Offset{ x: 8, y: 8 })
	t_ctx.push_offset(Offset{ x: 11, y: 11 })

	// NOTE(tauraamui): pre-clearing offsets from given id, they all exist and apply
	mut xx, mut yy := apply_offsets(t_ctx.offsets, 0, 0)
	assert xx == 27
	assert yy == 27

	t_ctx.clear_from_offset(bookmark_id)

	xx, yy = apply_offsets(t_ctx.offsets, 0, 0)
	assert xx == 3
	assert yy == 3
}

fn test_context_offset_clear_to_offset() {
	mut t_ctx := Context{
		ref: unsafe { nil }
	}
	t_ctx.setup_grid()!

	t_ctx.push_offset(Offset{ x: 1, y: 1 })
	t_ctx.push_offset(Offset{ x: 2, y: 2 })
	t_ctx.push_offset(Offset{ x: 5, y: 5 })
	bookmark_id := t_ctx.push_offset(Offset{ x: 8, y: 8 })
	assert t_ctx.map_id_to_index(bookmark_id)? == 3 // ensure correct index resolved from id lookup
	t_ctx.push_offset(Offset{ x: 11, y: 11 })

	// NOTE(tauraamui): pre-clearing offsets from given id, they all exist and apply
	mut xx, mut yy := apply_offsets(t_ctx.offsets, 0, 0)
	assert xx == 27
	assert yy == 27

	t_ctx.clear_to_offset(bookmark_id)

	xx, yy = apply_offsets(t_ctx.offsets, 0, 0)
	assert xx == 19
	assert yy == 19
}

fn test_context_offset_compact() {
	mut t_ctx := Context{
		ref: unsafe { nil }
	}
	t_ctx.setup_grid()!

	t_ctx.push_offset(Offset{ x: 1, y: 1 })
	t_ctx.push_offset(Offset{ x: 2, y: 2 })
	t_ctx.push_offset(Offset{ x: 5, y: 5 })

	assert t_ctx.compact_offsets() == Offset{ x: 8, y: 8 }
}

