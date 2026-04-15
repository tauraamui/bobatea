// Copyright 2024 The Lilly Editor contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

module bobatea

import gg
import gx
import math
import os

struct GUIContext {
	user_data voidptr
	frame_cb  fn (v voidptr) @[required]
mut:
	gg                         &gg.Context = unsafe { nil }
	txt_cfg                    gx.TextCfg
	foreground_color           Color
	background_color           Color
	text_draws_since_last_pass int
}

pub fn new_context(cfg Config) (&Context, fn () !) {
	mut ctx := &GUIContext{
		user_data: cfg.user_data
		frame_cb:  cfg.frame_fn
	}
	ctx.gg = gg.new_context(
		width:         800
		height:        600
		create_window: true
		window_title:  'Lilly Editor'
		user_data:     ctx
		bg_color:      gx.white
		font_path:     os.resource_abs_path('../experiment/RobotoMono-Regular.ttf')
		frame_fn:      frame
	)
	return ctx, unsafe { ctx.run_wrapper }
}

const font_size = 16

fn (mut ctx GUIContext) run_wrapper() ! {
	ctx.gg.run()
}

fn (mut ctx GUIContext) render_debug() bool {
	return true
}

fn frame(mut ctx GUIContext) {
	width := gg.window_size().width
	mut scale_factor := gg.dpi_scale()
	if scale_factor <= 0 {
		scale_factor = 1
	}
	ctx.txt_cfg = gx.TextCfg{
		size: font_size * int(scale_factor)
	}
	ctx.frame_cb(ctx.user_data)
	if ctx.text_draws_since_last_pass < 1000 {
		ctx.text_draws_since_last_pass = 0
		ctx.gg.end()
	}
}

fn (mut ctx GUIContext) rate_limit_draws() bool {
	return false
}

fn (mut ctx GUIContext) window_width() int {
	return gg.window_size().width
}

fn (mut ctx GUIContext) window_height() int {
	return gg.window_size().height
}

fn (mut ctx GUIContext) set_cursor_position(x int, y int) {}

fn (mut ctx GUIContext) draw_text(x int, y int, text string) {
	// this offsetting stuff is a bit mental but seems to be correct
	if ctx.text_draws_since_last_pass == 0 {
		ctx.gg.begin()
	}
	ctx.gg.draw_text((font_size / 2) + x - (font_size / 2), (y * font_size) - font_size,
		text, ctx.txt_cfg)
	if ctx.text_draws_since_last_pass >= 1000 {
		ctx.gg.end(how: .passthru)
		ctx.text_draws_since_last_pass = 0
		return
	}
	ctx.text_draws_since_last_pass += 1
}

fn (mut ctx GUIContext) write(c string) {}

fn (mut ctx GUIContext) clear_area(x int, y int, width int, height int) {}

fn (mut ctx GUIContext) draw_rect(x int, y int, width int, height int) {
	c := ctx.background_color
	ctx.gg.draw_rect_filled(x, y - 100, width, height / 16, gx.rgb(c.r, c.g, c.b))
}

fn (mut ctx GUIContext) draw_point(x int, y int) {}

fn (mut ctx GUIContext) bold() {}

fn (mut ctx GUIContext) set_color(c Color) {
	ctx.foreground_color = c
}

fn (mut ctx GUIContext) set_bg_color(c Color) {
	ctx.background_color = c
}

fn (mut ctx GUIContext) reset_color() {
	ctx.foreground_color = Color{}
}

fn (mut ctx GUIContext) reset_bg_color() {}

fn (mut ctx GUIContext) reset() {
	ctx.foreground_color = Color{}
	ctx.background_color = Color{}
}

fn (mut ctx GUIContext) run() ! {
	ctx.gg.run()
}

fn (mut ctx GUIContext) clear() {
	ctx.gg.begin()
	ctx.gg.end()
}

fn (mut ctx GUIContext) flush() {}

fn (ctx GUIContext) screen_text() string {
	return ''
}

fn (mut ctx GUIContext) clear_prev_data() {}
