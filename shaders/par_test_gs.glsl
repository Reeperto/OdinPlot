#version 330 core

layout (lines) in;
layout (triangle_strip, max_vertices = 4) out;

float width = 10.0 / 1024.0;

void main()
{
    vec2 start = gl_in[0].gl_Position.xy;
    vec2 end   = gl_in[1].gl_Position.xy;

    vec2 direction = normalize(end - start);
    vec2 perp = vec2(-direction.y, direction.x) * width;
    vec2 epsilon = direction * 0.004;

    start -= epsilon;
    end += epsilon;

    gl_Position = vec4(start + perp, 0.0, 1.0);
    EmitVertex();

    gl_Position = vec4(start - perp, 0.0, 1.0);
    EmitVertex();

    gl_Position = vec4(end + perp, 0.0, 1.0);
    EmitVertex();

    gl_Position = vec4(end - perp, 0.0, 1.0);
    EmitVertex();

    EndPrimitive();
}
