# Behavioral Design Patterns


## Author: Burduja Adrian

----

## Objectives:

1. Study and understand the Behavioral Design Patterns.

2. As a continuation of the previous laboratory work, think about what communication between software entities might be involed in your system.

3. Implement some additional functionalities using behavioral design patterns.

## Used Design Patterns: 

* command
* iterator
* strategy

## Implementation

I wrote a library to write and play music.

The command pattern is used to define how create the sounds.
All commands implement the interface:
```odin
// #command
Cmd :: struct {
	exec: proc(cmd: ^Cmd, ctx: ^Play_context) -> bool,
	free: proc(cmd: ^Cmd),
}
```

An array of commands can be executed with the use of the iterator pattern:
```odin
exec_all :: proc(ctx: ^Play_context, cmds: []^Cmd) -> bool {
	for cmd in cmds {
		if !cmd->exec(ctx) {return false}
		cmd->free()
	}
	return true
}
```

These are some of the concrete commands I've implemented:
```odin
Chord_cmd :: struct {
	using base:Cmd, freqs, amps:[]f64, duration:f64, start:f64,
}

new_chord_cmd :: proc( ctx: ^Play_context, freqs, amps: []f64, start: f64, duration: f64,) -> ( res: ^Cmd,) {
	return new_clone(Chord_cmd{{exec_chord, free_chord_cmd}, freqs, amps, duration, start})
}

exec_chord :: proc(cmd: ^Cmd, ctx: ^Play_context) -> (ok: bool) {
	cmd := cast(^Chord_cmd)cmd
	for i in 0 ..< len(cmd.freqs) {
		if !reg_note(ctx, cmd.freqs[i], cmd.amps[i], cmd.start, cmd.duration) { return false }
	}
	return
}

free_chord_cmd :: proc(cmd: ^Cmd) {
	cmd := cast(^Chord_cmd)cmd
	free(cmd)
}

Note_cmd :: struct {
	using base: Cmd, freq, amp:f64, duration, start: f64, 
}

new_note_cmd :: proc(ctx: ^Play_context, freq, amp, start, duration: f64) -> (res: ^Cmd) {
	return new_clone(Note_cmd{{exec_note, free_note_cmd}, freq, amp, duration, start})
}

exec_note :: proc(cmd: ^Cmd, ctx: ^Play_context) -> (ok: bool) {
	cmd := cast(^Note_cmd)cmd
	if !reg_note(ctx, cmd.freq, cmd.amp, cmd.start, cmd.duration) do return false
	return true
}

free_note_cmd :: proc(cmd: ^Cmd) {
	cmd := cast(^Note_cmd)cmd
	free(cmd)
}
```

I've also implemented Iterator pattern, by levereging polymorthism
```odin
// #iterator
Iterator :: struct($T: typeid) {
	items:   T,
	counter: int,
}

into_iter :: proc(items: []$T) -> Iterator([]T) { return {items, 0} }

next :: proc(iter: ^Iterator($A/[]$T)) -> (item: T, ok: bool) {
	iter.counter += 1
	if iter.counter > len(iter.items) do return
	return iter.items[iter.counter - 1], true
}
```

In order to generalise how sounds are created, I factored out the wave logic into 
different strategies:
```odin
// #strategy
Wave_strategy :: struct {
	generate: proc(_: ^Wave_strategy, _: ^ma.engine, _: f64, _: f64) -> (^ma.sound, ma.result),
}
Square_wave :: struct { using base: Wave_strategy, }
Sine_wave :: struct { using base: Wave_strategy, }
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
```

## Demo program
```odin
main :: proc() {
	ctx, _ := pcontext_init()

	// #command
	commands := make([dynamic]^Cmd)

	append(&commands, new_note_cmd(ctx, F4, 0.1, 0.5, 0.5))
	append(&commands, new_chord_cmd(ctx, {G4, F4, DS4}, {0.1, 0.1, 0.1}, 1, 0.5))

	exec_all(ctx, commands[:])
	delete(commands)

	ctx.wave_gen = new_square_wave()

	append(&commands, new_note_cmd(ctx, F4, 0.1, 1.5, 0.5))
	append(&commands, new_chord_cmd(ctx, {G4, F4, DS4}, {0.1, 0.1, 0.1}, 2, 0.5))

	exec_all(ctx, commands[:])
	

	play(ctx)
}
```

Output: some sounds


## Conclusions
In this laboratory I have implemented the command,iterator and strategy patterns for my
music library. 

The command pattern is usefull to define the parameters of a computation
without actually executing it, as well as agregating multiple such commands to be 
executed later,at the same time.
For this laboratory, I used the command pattern in order to be able to define different
types of commands(computations) and let them be executed sequentially together.

The iterator pattern is used to define how to iterate over a collection of objects
in a correct way and decoupled from the implementation of the objects themselves.
Here, I use the generic iterator to be able to iterate over any collection.

The strategy pattern can be used to define an interface for an algorithm and let the 
user implement multiple different implementations for it, which can be substituted at
runtime as needed. For my library, I use it to change the strategy of sound generation
for different wave forms.
