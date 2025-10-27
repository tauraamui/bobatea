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

	t_ctx.push_offset(Offset{ x: 1, y: 1 })
	t_ctx.push_offset(Offset{ x: 2, y: 2 })
	t_ctx.push_offset(Offset{ x: 5, y: 5 })
	t_ctx.push_offset(Offset{ x: 8, y: 8 })

	mut xx, mut yy := apply_offsets(t_ctx.offsets, 0, 0)
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

