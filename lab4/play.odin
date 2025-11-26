package main

import "core:c/libc"
import "core:fmt"
import ma "vendor:miniaudio"

Play_context :: struct {
	engine: ^ma.engine,
	sounds: [dynamic]^ma.sound,
}

Play_error :: struct {
	cause:  Causes,
	ma_err: ma.result,
}

Causes :: enum {
	Failed_engine_init,
}

play :: proc(ctx: ^Play_context) {
	for &sound in ctx.sounds {
		if err := ma.sound_start(sound); err != nil {

			fmt.println("Failed to start sound:", err)
			return
		}
	}
	if err := ma.engine_start(ctx.engine); err != nil {
		fmt.println("Failed to start engine:", err)
		return
	}


	libc.getwchar()

}

reg_note :: proc(ctx: ^Play_context, freq, amp, start, duration: f64) -> bool {
	new_sound, err := init_sound(ctx.engine, freq, amp)

	if err != nil {
		return false
	}

	rate := cast(u64)ctx.engine.sampleRate

	start := start * f64(rate)
	duration := duration * f64(rate)

	ma.sound_set_start_time_in_pcm_frames(new_sound, u64(start))
	ma.sound_set_stop_time_in_pcm_frames(new_sound, u64(start + duration))

	append(&ctx.sounds, new_sound)

	return true
}

pcontext_init :: proc(measure: [2]u8 = {4, 4}) -> (pc: ^Play_context, err: Play_error) {
	pc = new(Play_context)

	engine_conf := ma.engine_config_init()
	engine_conf.noAutoStart = true

	pc.engine = new(ma.engine)

	if err := ma.engine_init(&engine_conf, pc.engine); err != nil {
		return nil, {.Failed_engine_init, err}
	}

	return
}

pcontext_deinit :: proc(pc: ^Play_context, err: Play_error) {
	ma.engine_uninit(pc.engine)
}

init_sound :: proc(
	engine: ^ma.engine,
	fr, amp: f64,
	type: ma.waveform_type = .square,
	allocator := context.allocator,
) -> (
	sound: ^ma.sound,
	err: ma.result,
) {

	waveform_conf := ma.waveform_config_init(.f32, 2, engine.sampleRate, type, amp, fr)
	wave := new(ma.waveform)

	if err := ma.waveform_init(&waveform_conf, wave); err != nil {
		free(wave)
		return nil, err
	}

	sound = new(ma.sound)

	if err := ma.sound_init_from_data_source(
		engine,
		cast(^ma.data_source)wave,
		ma.sound_flags{},
		nil,
		sound,
	); err != nil {
		fmt.println("Failed to init sound:", err)
		ma.sound_uninit(sound)
		free(sound)

		return nil, err
	}

	return

}
