#!/usr/bin/env -S v run

import build

mut context := build.context(
	default: 'test'
)

context.task(name: 'run', run: |self| system('v -g run .'))

context.task(name: 'check', run: |self| exit(system('v -check -shared .')))

context.task(name: 'format', run: |self| system('v fmt -w .'))

context.task(name: 'verify-format', run: |self| exit(system('v fmt -verify .')))

context.task(
	name: 'test-root'
	run:  |self| exit(system('v test ./key_test.v && v test ./tea_test.v'))
)

context.task(name: 'test-term', run: |self| exit(system('v test ./lib/term')))

context.task(name: 'test-ext', run: |self| exit(system('v test ./tests')))

context.task(
	name: 'test'
	run:  |self| exit(system('v test ./key_test.v && v test ./tea_test.v && v test ./lib/term && v test ./tests && v -check -shared .'))
)

context.task(name: 'test-all', run: |self| exit(system('v test .')))

context.task(name: 'compile-make', run: |self| system('v -prod -skip-running make.vsh -o make'))

context.run()
