package main

import "base:runtime"
import "core:log"

import gl "vendor:OpenGL"

uniform_marker :: struct {
	shader:   u32,
	location: i32,
}

float_var :: struct($Size: uint) where Size <= 4 {
	val:        [Size]f32,
	dependents: [dynamic]uniform_marker,
}

make_float_var :: proc {
	make_float_var_vec,
	make_float_var_single,
}

update_float_var :: proc {
	update_float_var_vec,
	update_float_var_single,
}

delete_float_var :: proc(var: ^float_var($N)) {
	delete(var.dependents)
}

link_program_float_var :: proc(program: u32, location: i32, var: ^float_var($N)) {
	append(&var.dependents, uniform_marker{shader = program, location = location})
	propogate_updates(var)
}

unlink_program_float_var :: proc(program: u32, var: ^float_var($N)) {
	to_delete := -1

	for marker, i in &var.dependents {
		if marker.shader == program {
			to_delete = i
		}
	}

	if to_delete != -1 {
		unordered_remove(&var.dependents, to_delete)
	}
}

make_float_var_single :: proc(val: f32) -> float_var(1) {
	return {val = {val}, dependents = make([dynamic]uniform_marker)}
}

make_float_var_vec :: proc(val: [$N]f32) -> float_var(N) {
	return {val = val, dependents = make([dynamic]uniform_marker)}
}

update_float_var_vec :: proc "contextless" (var: ^float_var($N), val: [N]f32) {
	var.val = val
	propogate_updates(var)
}

update_float_var_single :: proc "contextless" (var: ^float_var(1), val: f32) {
	var.val = val
	propogate_updates(var)
}

@(private)
propogate_updates :: proc "contextless" (var: ^float_var($N)) {
	for dep in &var.dependents {
		gl.UseProgram(dep.shader)
		switch N {
		case 1:
			gl.Uniform1f(dep.location, var.val[0])
		case 2:
			gl.Uniform2fv(dep.location, 1, raw_data(var.val[:]))
		case 3:
			gl.Uniform3fv(dep.location, 1, raw_data(var.val[:]))
		case 4:
			gl.Uniform4fv(dep.location, 1, raw_data(var.val[:]))
		}
	}
}
