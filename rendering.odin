package main

import imgui "imgui"
import imgl3 "imgui/gl3"
import imglfw "imgui/glfw"

import gl "vendor:OpenGL"
import "vendor:glfw"

import sa "core:container/small_array"
import "core:fmt"
import "core:log"
import "core:strings"

import "gfx"
import "maths"

init_imgui :: proc(window: glfw.WindowHandle) {
	imgui.CHECKVERSION()
	imgui.CreateContext()

	io := imgui.GetIO()
	io.ConfigFlags += {.NavEnableGamepad}
	io.ConfigFlags += {.NavEnableKeyboard}
	io.IniFilename = nil // Disable imgui config

	name: [40]u8
	{
		str: cstring = "PragamatoPro Mono"
		temp: [^]u8 = transmute([^]u8)str
		copy(name[:], temp[:len(str)])
	}

	// NOTE: FontConfig's have a special constructor that 
	// doesnt translate, so these fields have to be set manually
	cfg: imgui.FontConfig = {
		RasterizerDensity    = 4.0,
		FontDataOwnedByAtlas = false,
		GlyphMaxAdvanceX     = max(f32),
		EllipsisChar         = cast(imgui.Wchar)(max(u16)),
		PixelSnapH           = false,
		OversampleH          = 8,
		OversampleV          = 8,
		RasterizerMultiply   = 1.0,
		Name                 = name,
	}

	font := #load("fonts/regular.ttf")

	imgui.FontAtlas_AddFontFromMemoryTTF(
		io.Fonts,
		raw_data(font),
		i32(len(font) * size_of(u8)),
		15,
		&cfg,
	)

	imgui.StyleColorsDark()
	imglfw.InitForOpenGL(window, false)
	imgl3.Init("#version 150")
}

screen_quad_init :: proc() -> (vao: u32) {
	vertices := [?]f32 {
		1.0,
		1.0,
		0.0, // top right
		1.0,
		-1.0,
		0.0, // bottom right
		-1.0,
		-1.0,
		0.0, // bottom left
		-1.0,
		1.0,
		0.0, // top left
	}

	indices := [?]u32 {
		0,
		1,
		3, // first
		1,
		2,
		3, // second
	}

	gl.GenVertexArrays(1, &vao)

	vbo, ebo: u32

	gl.GenBuffers(1, &vbo)
	gl.GenBuffers(1, &ebo)

	gl.BindVertexArray(vao)

	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.STATIC_DRAW)

	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(indices), &indices, gl.STATIC_DRAW)

	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)

	gl.BindVertexArray(0)
	return
}

parameteric_test_setup :: proc() -> (vao: u32) {
	coarseness :: 512
	domain := maths.generate_gl_domain(-1.0, 1.0, coarseness)
	defer delete(domain)

	vbo: u32

	gl.GenVertexArrays(1, &vao)
	gl.GenBuffers(1, &vbo)
	gl.BindVertexArray(vao)

	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(gl.ARRAY_BUFFER, len(domain) * size_of(f32), raw_data(domain), gl.STATIC_DRAW)

	gl.VertexAttribPointer(0, 1, gl.FLOAT, gl.FALSE, size_of(f32), 0)
	gl.EnableVertexAttribArray(0)

	gl.BindVertexArray(0)

	vs, fs, gs: u32

	if shader, ok, err := gfx.make_vertex_shader(#load("shaders/par_test_vs.glsl", cstring)); ok {
		vs = shader
	} else {
		log.error(err)
	}

	if shader, ok, err := gfx.make_fragment_shader(#load("shaders/par_test_fs.glsl", cstring));
	   ok {
		fs = shader
	} else {
		log.error(err)
	}

	if shader, ok, err := gfx.make_geometry_shader(#load("shaders/par_test_gs.glsl", cstring));
	   ok {
		gs = shader
	} else {
		log.error(err)
	}

	defer {
		gl.DeleteShader(vs)
		gl.DeleteShader(fs)
		gl.DeleteShader(gs)
	}

	if prog, ok, err := gfx.make_shader_program({vs, fs, gs}); ok {
		state.par_s_program = prog
	} else {
		log.error(err)
	}

	return
}

init :: proc(state: ^State) {
	state.screen_vao = screen_quad_init()
	state.par_vao = parameteric_test_setup()

	gl.Enable(gl.BLEND)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
	// gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)

	return
}


draw :: proc() {
	gl.ClearColor(0.0, 0.0, 0.0, 1.0)
	gl.Clear(gl.COLOR_BUFFER_BIT)

	gl.BindVertexArray(state.screen_vao)
	for &plot in state.implicits {
		gl.UseProgram(plot.s_program)
		gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil)
	}

	// gl.BindVertexArray(state.par_vao)
	// gl.UseProgram(state.par_s_program)
	// gl.DrawArrays(gl.LINES, 0, 1024)

	@(static)
	input_buf: [512]u8

	@(static)
	function_color: [3]f32

	imgui.PushItemWidth(-1.0)
	imgui.InputText("##", cstring(raw_data(input_buf[:])), len(input_buf))
	imgui.ColorEdit3("##", &function_color)
	imgui.PopItemWidth()

	window_width := imgui.GetWindowSize().x

	if imgui.Button("Add Function", {window_width, 0}) {
		if str, err := strings.clone_from_cstring(cstring(raw_data(input_buf[:]))); err == nil {
			if plot, ok := create_implicit(str, function_color); ok {
				append(&state.implicits, plot)
			}
		} else {
			log.error(err)
		}
	}

	if imgui.Button("Add Example Functions", {window_width, 0}) {
		plot_defs := [?]string {
			"pow(z.x, 3.0) + pow(z.y, 3.0) - 3.0 * z.x * z.y",
			"sin(z.x + z.y) - cos(z.x * z.y) + 1.0",
			"pow(dot(z, z), 2.0) + 4.0 * z.x * dot(z, z) - 4.0 * pow(z.y, 2.0)",
		}

		plot_cols := [?][3]f32{{0.41, 1.00, 1.00}, {1.00, 0.41, 0.78}, {1.0, 1.0, 1.0}}

		for &plot_def, i in plot_defs {
			if plot, ok := create_implicit(plot_def, plot_cols[i]); ok {
				append(&state.implicits, plot)
			}
		}
	}

	imgui.BeginTable("Functions", 2)

	to_remove := -1
	for plot, i in state.implicits {
		imgui.TableNextRow()
		imgui.TableNextColumn()
		imgui.Text(strings.unsafe_string_to_cstring(plot.expression))

		imgui.TableNextColumn()
		if imgui.Button(strings.unsafe_string_to_cstring(fmt.tprintf("Delete##%v", i))) {
			to_remove = i
		}
	}

	if (to_remove != -1) {
		gl.DeleteProgram(state.implicits[to_remove].s_program)
		ordered_remove(&state.implicits, to_remove)
		to_remove = -1
	}

	imgui.EndTable()
}
