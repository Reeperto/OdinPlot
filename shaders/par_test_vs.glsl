#version 330 core
layout (location = 0) in float dom_x;

void main()
{
    gl_Position = vec4(dom_x, 0.125 * floor(dom_x * 8.0), 0.0, 1.0);
}
