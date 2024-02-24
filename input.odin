package main

import "base:runtime"

import "core:c"
import "core:log"
import "core:math"

import gl "vendor:OpenGL"
import "vendor:glfw"

import imgui "imgui"
import imgl3 "imgui/gl3"
import imglfw "imgui/glfw"

MouseState :: struct {
	last_x, last_y: f64,
	dx, dy:         f64,
}

mouse_state := MouseState{}

handle_mouse_pos :: proc(window: glfw.WindowHandle) {
	using mouse_state

	x, y := glfw.GetCursorPos(window)

	dx = last_x - x
	dy = last_y - y

	if (glfw.GetMouseButton(window, glfw.MOUSE_BUTTON_LEFT) == glfw.PRESS) {
		update_float_var(
			&state.grid_offset,
			state.grid_offset.val + {f32(mouse_state.dx / 1024.0), -f32(mouse_state.dy / 1024.0)},
		)
	}

	last_x = x
	last_y = y
}

handle_scroll :: proc "c" (window: glfw.WindowHandle, dx, dy: c.double) {
	new_width := state.width.val[0] * (1.0 / (1.0 + math.exp(f32(dy))) + 0.5)
	update_float_var(&state.width, new_width)
	imglfw.ScrollCallback(window, dx, dy)
}

handle_key :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: c.int) {
	using state

	imglfw.KeyCallback(window, key, scancode, action, mods)

	if action == glfw.PRESS {
		switch key {
		case glfw.KEY_ESCAPE:
			running = false
		}
	}
}

handle_resize :: proc "c" (window: glfw.WindowHandle, width, height: i32) {}
