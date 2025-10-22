module main

import os
import flag
import bobatea as tea

fn main() {
	mut fp := flag.new_flag_parser(os.args)
	fp.application('bobatea')
	fp.version('0.1.0')
	fp.description('Bobatea example applications')
	fp.skip_executable()

	spinner_demo := fp.bool('spinner', `s`, false, 'Run the spinner demo')
	simple_list := fp.bool('simple-list', `l`, false, 'Run the simple list demo')

	fp.finalize() or {
		eprintln(err)
		exit(1)
	}

	match true {
		spinner_demo {
			run_spinner_demo()
		}
		simple_list {
			run_simple_list_demo()
		}
		else {
			eprintln('Please specify a demo to run:')
			eprintln('  --spinner, -s    Run the spinner demo')
			eprintln('  --simple-list, -l Run the simple list demo')
			eprintln('  --help, -h       Show this help')
			exit(1)
		}
	}
}

fn run_spinner_demo() {
	mut entry_model := new_spinner_model()
	mut app := tea.new_program(mut entry_model)
	app.run() or { panic('something went wrong! ${err}') }
}

fn run_simple_list_demo() {
	mut entry_model := new_simple_list_model()
	mut app := tea.new_program(mut entry_model)
	app.run() or { panic('something went wrong! ${err}') }
}
