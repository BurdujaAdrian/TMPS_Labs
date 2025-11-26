package main

import ma "vendor:miniaudio"

// #strategy
Wave_strategy :: struct {
	generate: proc(_: ^Wave_strategy, _: ^ma.engine, _: f64, _: f64) -> (^ma.sound, ma.result),
}

Square_wave :: struct {
	using base: Wave_strategy,
}

Sine_wave :: struct {
	using base: Wave_strategy,
}

new_square_wave :: proc() -> ^Wave_strategy {
	return new_clone(Square_wave{{gen_square}})
}

new_sine_wave :: proc() -> ^Wave_strategy {
	return new_clone(Sine_wave{{gen_sine}})
}

gen_square :: proc(s: ^Wave_strategy, e: ^ma.engine, fr, amp: f64) -> (^ma.sound, ma.result) {
	return init_sound(e, fr, amp, .square)
}

gen_sine :: proc(s: ^Wave_strategy, e: ^ma.engine, fr, amp: f64) -> (^ma.sound, ma.result) {
	return init_sound(e, fr, amp, .sine)
}
