package main
import ma "vendor:miniaudio"

// #iterator
Iterator :: struct($T: typeid) {
	items:   T,
	counter: int,
}

into_iter :: proc(items: []$T) -> Iterator([]T) {
	return {items, 0}
}

next :: proc(iter: ^Iterator($A/[]$T)) -> (item: T, ok: bool) {
	iter.counter += 1
	if iter.counter > len(iter.items) do return
	return iter.items[iter.counter - 1], true
}

// #command
Cmd :: struct {
	exec: proc(cmd: ^Cmd, ctx: ^Play_context) -> bool,
	free: proc(cmd: ^Cmd),
}

exec_all :: proc(ctx: ^Play_context, cmds: []^Cmd) -> bool {
	cmds := into_iter(cmds)
	for cmd in next(&cmds) {
		if !cmd->exec(ctx) {return false}
		cmd->free()
	}

	return true
}

Chord_cmd :: struct {
	using base:  Cmd,
	freqs, amps: []f64,
	duration:    f64,
	start:       f64,
}

new_chord_cmd :: proc(
	ctx: ^Play_context,
	freqs, amps: []f64,
	start: f64,
	duration: f64,
) -> (
	res: ^Cmd,
) {
	return new_clone(Chord_cmd{{exec_chord, free_chord_cmd}, freqs, amps, duration, start})
}

exec_chord :: proc(cmd: ^Cmd, ctx: ^Play_context) -> (ok: bool) {
	cmd := cast(^Chord_cmd)cmd

	for i in 0 ..< len(cmd.freqs) {
		if !reg_note(ctx, cmd.freqs[i], cmd.amps[i], cmd.start, cmd.duration) {
			return false
		}
	}
	return
}

free_chord_cmd :: proc(cmd: ^Cmd) {
	cmd := cast(^Chord_cmd)cmd
	free(cmd)
}

Note_cmd :: struct {
	using base:      Cmd,
	freq, amp:       f64,
	duration, start: f64,
}

new_note_cmd :: proc(ctx: ^Play_context, freq, amp, start, duration: f64) -> (res: ^Cmd) {
	return new_clone(Note_cmd{{exec_note, free_note_cmd}, freq, amp, duration, start})
}

exec_note :: proc(cmd: ^Cmd, ctx: ^Play_context) -> (ok: bool) {
	cmd := cast(^Note_cmd)cmd

	if !reg_note(ctx, cmd.freq, cmd.amp, cmd.start, cmd.duration) {
		return false
	}

	return true
}

free_note_cmd :: proc(cmd: ^Cmd) {
	cmd := cast(^Note_cmd)cmd
	free(cmd)
}
