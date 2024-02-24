package main

import "core:c"
import "core:fmt"
import "core:log"
import "core:strings"
import "core:time"

import gl "vendor:OpenGL"
import "vendor:glfw"

import "gfx"
import "maths"

import imgui "imgui"
import imgl3 "imgui/gl3"
import imglfw "imgui/glfw"

PROGRAM_NAME :: "2D Plotter"
GL_MAJOR_VERSION: c.int : 4
GL_MINOR_VERSION: c.int : 1

running := true

State :: struct {
	par_s_program:       u32,
	screen_vao, par_vao: u32,
	implicits:           [dynamic]ImplictPlot,
	width:               float_var(1),
	grid_offset:         float_var(2),
}

state := State {
	implicits     = make([dynamic]ImplictPlot),
	width         = make_float_var(4.0),
	grid_offset   = make_float_var([2]f32{0.0, 0.0}),
	screen_vao    = 0,
	par_vao       = 0,
	par_s_program = 0,
}

run_app :: proc() {
	using state
	context.logger = log.create_console_logger()

	if !glfw.Init() {
		log.error("GLFW initialization failed")
		return
	}
	defer glfw.Terminate()

	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_MAJOR_VERSION)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_MINOR_VERSION)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
	glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, gl.TRUE)

	window := glfw.CreateWindow(1024, 1024, PROGRAM_NAME, nil, nil)
	if window == nil {
		log.error("Failed to create window")
		return
	}
	defer glfw.DestroyWindow(window)

	glfw.MakeContextCurrent(window)
	glfw.SwapInterval(1)

	glfw.SetKeyCallback(window, handle_key)
	glfw.SetScrollCallback(window, handle_scroll)
	glfw.SetCharCallback(
		window,
		proc "c" (window: glfw.WindowHandle, c: rune) {imglfw.CharCallback(window, u32(c))},
	)
	glfw.SetMouseButtonCallback(
		window,
		proc "c" (window: glfw.WindowHandle, button, action, mods: c.int) {
			imglfw.MouseButtonCallback(window, button, action, mods)
		},
	)
	glfw.SetFramebufferSizeCallback(window, handle_resize)

	gl.load_up_to(int(GL_MAJOR_VERSION), int(GL_MINOR_VERSION), glfw.gl_set_proc_address)

	// ImGui Setup
	init_imgui(window)
	defer {
		imgl3.Shutdown()
		imglfw.Shutdown()
		imgui.DestroyContext()
	}

	// Plot setup
	init(&state)

	// Main loop
	io := imgui.GetIO()
	for (!glfw.WindowShouldClose(window) && running) {
		glfw.PollEvents()

		if !io.WantCaptureMouse {
			handle_mouse_pos(window)
		}

		imgl3.NewFrame()
		imglfw.NewFrame()
		imgui.NewFrame()

		update()
		draw()

		// FPS Counter
		when ODIN_DEBUG == true {
			imgui.DrawList_AddText(
				imgui.GetBackgroundDrawList(),
				{10, 10},
				imgui.ColorConvertFloat4ToU32({1.0, 1.0, 1.0, 1.0}),
				strings.unsafe_string_to_cstring(fmt.tprint("FPS", io.Framerate)),
			)
		}

		imgui.Render()
		imgl3.RenderDrawData(imgui.GetDrawData())
		glfw.SwapBuffers(window)

		free_all(context.temp_allocator)
	}

	cleanup()
}

update :: proc() {}

cleanup :: proc() {
	for implict in &state.implicits {
		delete_implicit(&implict)
	}
	delete(state.implicits)
}
