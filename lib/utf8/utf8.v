// Copyright 2025 The Lilly Edtior contributors
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

module utf8

pub fn str_clamp_to_visible_length(s string, max_width int) string {
	if max_width <= 0 {
		return ''
	}

	if utf8_str_visible_length(s) <= max_width {
		return s
	}

	mut result := []rune{}
	mut current_width := 0

	for r in s.runes() {
		visual_width := utf8_str_visible_length(r.str())
		if current_width + visual_width > max_width {
			break
		}
		result << r
		current_width += visual_width
	}

	return result.string()
}
