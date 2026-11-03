fn hash(p: vec2<f32>) -> f32 {
    let q = vec2<u32>(vec2<i32>(floor(p)));
    var h = q.x * 1597334673u ^ q.y * 3812015801u;
    h = (h ^ (h >> 15u)) * 2246822519u;
    h = (h ^ (h >> 13u)) * 3266489917u;
    h = h ^ (h >> 16u);
    return f32(h >> 8u) / 16777216.0;
}

fn noise(p: vec2<f32>) -> f32 {
    let i = floor(p);
    let f = fract(p);
    let u = f * f * (3.0 - 2.0 * f);
    let a = hash(i);
    let b = hash(i + vec2<f32>(1.0, 0.0));
    let c = hash(i + vec2<f32>(0.0, 1.0));
    let d = hash(i + vec2<f32>(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

fn fbm(p: vec2<f32>) -> f32 {
    var v = 0.0;
    var amp = 0.5;
    var q = p;
    for (var k = 0; k < 4; k++) {
        v += amp * noise(q);
        q = q * 2.02 + vec2<f32>(1.6, 9.1);
        amp *= 0.5;
    }
    return v;
}

fn shade(s: Shader) -> vec4<f32> {
    let t = s.time * 0.08;
    let uv = s.uv;

    let p = vec2<f32>(uv.x * 2.4 + t * 0.2, uv.y * 1.8 - t * 0.15);
    let n1 = fbm(p);
    let n2 = fbm(p + vec2<f32>(n1 * 1.2, t * 0.3));

    let wave = 0.5 + 0.5 * sin(uv.y * 3.14159 + n2 * 2.4 - t);
    let warm_flow = mix(s.color.rgb, s.color2.rgb, clamp(wave * 0.85 + n1 * 0.35, 0.0, 1.0));

    let vignette = smoothstep(1.4, 0.2, length(uv - vec2<f32>(0.5, 0.5)));
    let col = warm_flow * (0.75 + 0.25 * vignette);

    return vec4<f32>(col, 1.0);
}
