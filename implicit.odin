package main

import "core:fmt"
import "core:log"
import "core:strings"

import "gfx"

import gl "vendor:OpenGL"

@(private)
implicit_vss := #load("shaders/implicit_vs.glsl", cstring)

@(private)
implicit_fss_template := #load("shaders/implicit_fs_template.glsl", string)

ImplictPlot :: struct {
	expression: string,
	s_program:  u32,
	color:      float_var(3),
	thickness:  float_var(1),
}

create_implicit :: proc(
	func: string,
	color: [3]f32 = {1.0, 1.0, 1.0},
	thickness: f32 = 1.0,
) -> (
	plot: ImplictPlot,
	ok: bool = true,
) {
	plot.expression = func
	color := color

	v_shader, f_shader, s_program: u32
	err_msg: string

	v_shader, ok, err_msg = gfx.make_vertex_shader(implicit_vss)

	if !ok {log.error(err_msg);return}
	defer gl.DeleteShader(v_shader)

	f_source := strings.unsafe_string_to_cstring(fmt.tprintf(implicit_fss_template, func))
	f_shader, ok, err_msg = gfx.make_fragment_shader(f_source)

	if !ok {log.error(err_msg);return}
	defer gl.DeleteShader(f_shader)

	s_program, ok, err_msg = gfx.make_shader_program({v_shader, f_shader})
	if !ok {log.error(err_msg);return}
	plot.s_program = s_program

	uniforms := gl.get_uniforms_from_program(plot.s_program)

	// Setup uniforms
	plot.thickness = make_float_var(thickness)
	plot.color = make_float_var(color)

	link_program_float_var(plot.s_program, uniforms["width"].location, &state.width)
	link_program_float_var(plot.s_program, uniforms["offset"].location, &state.grid_offset)
	link_program_float_var(plot.s_program, uniforms["thickness"].location, &plot.thickness)
	link_program_float_var(plot.s_program, uniforms["line_color"].location, &plot.color)

	free_all(context.temp_allocator)
	return
}

delete_implicit :: proc(plot: ^ImplictPlot) {
	delete_float_var(&plot.color)
	delete_float_var(&plot.thickness)

	unlink_program_float_var(plot.s_program, &state.width)
	unlink_program_float_var(plot.s_program, &state.grid_offset)

	gl.DeleteProgram(plot.s_program)
}
