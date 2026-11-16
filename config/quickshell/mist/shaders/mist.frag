#version 440
// Drifting mist over the wallpaper. Three layers of domain-warped fractal noise
// (valley mist, high wisps, near haze), each drifting with the wind at its own
// speed, lit by a blurred copy of the wallpaper underneath, so it takes on the
// colours of whatever it passes over.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;       // seconds
    float aspect;     // width / height
    float strength;   // how thick the mist gets, 0..1
};
layout(binding = 1) uniform sampler2D scene;   // the wallpaper as shown, tiny = blurred

float hash(vec2 p) {                     // sine-free hash (Dave Hoskins)
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float noise(vec2 p) {                    // value noise, quintic fade
    vec2 i = floor(p), f = fract(p);
    vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    float a = hash(i), b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0)), d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

const mat2 ROT = mat2(0.80, 0.60, -0.60, 0.80);

float fbm(vec2 p) {
    float v = 0.0, a = 0.5;
    for (int i = 0; i < 4; i++) {
        v += a * noise(p);
        p = ROT * p * 2.03 + 17.1;
        a *= 0.5;
    }
    return v / 0.9375;
}

// One mist layer: noise warped by noise, so it frays into wisps and slowly
// rolls instead of sliding past as a fixed pattern.
float mist(vec2 p, float t, float wind) {
    p.x += t * wind;
    vec2 q = vec2(fbm(p + vec2(0.0, t * 0.020)),
                  fbm(p + vec2(5.2, 1.3) - vec2(t * 0.015, 0.0)));
    return fbm(p + 2.2 * q + vec2(t * 0.012, 0.0));
}

void main() {
    vec2 uv = qt_TexCoord0;              // 0..1, y down
    vec2 p = vec2(uv.x * aspect, uv.y);
    float t = time;

    // valley mist: a band between the far peaks and the near hills, thinning
    // out lower down so the foreground stays crisp
    float band = smoothstep(0.30, 0.48, uv.y) * (1.0 - smoothstep(0.60, 0.82, uv.y));
    float d1 = smoothstep(0.46, 0.78, mist(p * vec2(1.4, 3.6), t, 0.010)) * band;

    // big, slow cloud banks rolling through the same band (far away, so slower)
    float banks = smoothstep(0.50, 0.80, mist(p * vec2(0.6, 1.9) + 20.0, t * 0.7, 0.006));
    float d1b = banks * band * 0.75;

    // thin high wisps across the sky
    float sky = 1.0 - smoothstep(0.14, 0.44, uv.y);
    float d2 = smoothstep(0.50, 0.82, mist(p * vec2(0.9, 2.6) + 40.0, t, 0.006)) * sky * 0.75;

    // faint near haze at the very bottom, drifting faster (it is closer)
    float d3 = smoothstep(0.50, 0.88, fbm(p * vec2(0.8, 1.8) + vec2(t * 0.022, 0.0) + 90.0))
             * smoothstep(0.72, 1.0, uv.y) * 0.22;

    float density = clamp(d1 + d1b + d2 + d3, 0.0, 1.0);

    // lit by what is behind it: the scene's colour, lifted and a little greyed
    vec3 bg = texture(scene, uv).rgb;
    float lum = dot(bg, vec3(0.299, 0.587, 0.114));
    vec3 col = min(mix(vec3(lum), bg, 0.70) * 1.50 + vec3(0.09, 0.11, 0.13), vec3(1.0));

    float a = density * strength;
    fragColor = vec4(col * a, a) * qt_Opacity;
}
