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

module draw

import lib.term.ui as tui

pub struct Event {
	tui.Event
}

pub struct Config {
pub:
	render_debug     bool
	default_fg_color ?Color
	default_bg_color ?Color
	user_data        voidptr
	frame_fn         fn (voidptr) @[required]
	update_fn        ?fn (voidptr) // Optional high-frequency update function
	event_fn         fn (Event, voidptr) @[required]

	capture_events       bool
	use_alternate_buffer bool = true
}

pub type Runner = fn () !

