package gfx

import gl "vendor:OpenGL"

@(private)
err_buf: [1024]u8

make_vertex_shader :: proc(
	source: cstring,
) -> (
	v_shader: u32,
	ok: bool = true,
	error: string = "",
) {
	success: i32
	source := source

	v_shader = gl.CreateShader(gl.VERTEX_SHADER)
	gl.ShaderSource(v_shader, 1, &source, nil)
	gl.CompileShader(v_shader)

	gl.GetShaderiv(v_shader, gl.COMPILE_STATUS, &success)
	if success == 0 {
		gl.GetShaderInfoLog(v_shader, 512, nil, raw_data(err_buf[:]))
		error = string(err_buf[:])
		ok = false
	}

	return
}

make_fragment_shader :: proc(
	source: cstring,
) -> (
	f_shader: u32,
	ok: bool = true,
	error: string = "",
) {
	success: i32
	source := source

	f_shader = gl.CreateShader(gl.FRAGMENT_SHADER)
	gl.ShaderSource(f_shader, 1, &source, nil)
	gl.CompileShader(f_shader)

	gl.GetShaderiv(f_shader, gl.COMPILE_STATUS, &success)
	if success == 0 {
		gl.GetShaderInfoLog(f_shader, 512, nil, raw_data(err_buf[:]))
		error = string(err_buf[:])
		ok = false
	}

	return
}

make_geometry_shader :: proc(
	source: cstring,
) -> (
	g_shader: u32,
	ok: bool = true,
	error: string = "",
) {
	success: i32
	source := source

	g_shader = gl.CreateShader(gl.GEOMETRY_SHADER)
	gl.ShaderSource(g_shader, 1, &source, nil)
	gl.CompileShader(g_shader)

	gl.GetShaderiv(g_shader, gl.COMPILE_STATUS, &success)
	if success == 0 {
		gl.GetShaderInfoLog(g_shader, 512, nil, raw_data(err_buf[:]))
		error = string(err_buf[:])
		ok = false
	}

	return
}

make_shader_program :: proc(
	shaders: []u32,
) -> (
	s_program: u32,
	ok: bool = true,
	error: string = "",
) {
	success: i32

	s_program = gl.CreateProgram()

	for shader in shaders {
		gl.AttachShader(s_program, shader)
	}

	gl.LinkProgram(s_program)

	gl.GetProgramiv(s_program, gl.LINK_STATUS, &success)
	if success == 0 {
		gl.GetProgramInfoLog(s_program, 512, nil, raw_data(err_buf[:]))
		error = string(err_buf[:])
		ok = false
	}

	return
}
