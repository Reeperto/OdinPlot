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
	uniforms:   gl.Uniforms,
	color:      [3]f32,
	thickness:  f32,
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

	plot.uniforms = gl.get_uniforms_from_program(plot.s_program)

	gl.UseProgram(plot.s_program)
	gl.Uniform2f(plot.uniforms["offset"].location, state.grid_offset[0], state.grid_offset[1])
	gl.Uniform1f(plot.uniforms["width"].location, state.width)
	gl.Uniform1f(plot.uniforms["thickness"].location, thickness)
	gl.Uniform3f(plot.uniforms["line_color"].location, color[0], color[1], color[2])
	gl.UseProgram(0)

	free_all(context.temp_allocator)
	return
}
