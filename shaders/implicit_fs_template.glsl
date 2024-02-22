#version 330 core
precision highp float;

in vec3 vPos;
out vec4 fCol;

uniform float width;
uniform vec3 line_color;
uniform float thickness;
uniform vec2 offset;

float epsilon = thickness * width / 1024.0;

float f(vec2 z)
{{
    return %s;
}}

vec2 grad(vec2 z)
{{
    vec2 h = vec2( 0.00001, 0.0 );
    return vec2( f(z+h.xy) - f(z-h.xy),
                 f(z+h.yx) - f(z-h.yx) )/(2.0*h.x);
}}

void main()
{{
    vec2 z = (vPos.xy + offset) * width;

    float de = abs(f(z)) / length(grad(z));
    float col = 1.0 - smoothstep(1.0 * epsilon, 2 * epsilon, de);

    fCol = vec4(line_color * col, col);
}} 
