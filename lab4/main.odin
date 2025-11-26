package main

import "base:runtime"
import "core:c/libc"
import "core:fmt"
import "core:os/os2"
import ma "vendor:miniaudio"


main :: proc() {
	ctx, _ := pcontext_init()

	// #command
	commands := make([dynamic]^Cmd)

	append(&commands, new_note_cmd(ctx, F4, 0.1, 0.5, 0.5))
	append(&commands, new_chord_cmd(ctx, {G4, F4, DS4}, {0.1, 0.1, 0.1}, 1, 0.5))

	exec_all(ctx, commands[:])

	play(ctx)
}
