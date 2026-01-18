shader_type sky;

uniform float time_scale = 0.03;
uniform float rotation_speed = 0.02;
uniform float noise_scale = 1.8;
uniform float intensity = 1.3;
uniform float stars_density = 120.0;

uniform vec3 color_void       : source_color = vec3(0.03, 0.01, 0.05);
uniform vec3 color_flesh      : source_color = vec3(0.25, 0.05, 0.3);
uniform vec3 color_eldritch   : source_color = vec3(0.9, 0.6, 1.0);
uniform vec3 color_star       : source_color = vec3(1.0, 0.85, 0.7);

// --- Hash et noise 3D ---
float hash(vec3 p) {
    return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float noise3(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    vec3 u = f*f*(3.0 - 2.0*f);

    return mix(
        mix(
            mix(hash(i + vec3(0,0,0)), hash(i + vec3(1,0,0)), u.x),
            mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), u.x),
            u.y
        ),
        mix(
            mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), u.x),
            mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), u.x),
            u.y
        ),
        u.z
    );
}

float fbm(vec3 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 5; i++) {
        v += noise3(p) * a;
        p *= 2.0;
        a *= 0.5;
    }
    return v;
}

// --- Hash pour étoiles ---
float hash_star(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898,78.233))) * 43758.5453);
}

// --- Étoiles rondes et pulsantes ---
float star(vec2 uv, float density, float t) {
    vec2 id = floor(uv * density);
    vec2 f = fract(uv * density) - 0.5;

    float n = hash_star(id);

    float radius = 0.02;
    float shape = smoothstep(radius, 0.0, length(f));

    float pulse = sin(t*3.0 + n*TAU) * 0.5 + 0.5;

    return shape * pulse * step(0.995, n);
}

void sky() {
    float t = TIME * time_scale;

    // --- Direction sphérique avec rotation ---
    float lon = SKY_COORDS.x * TAU + TIME * rotation_speed;
    float lat = (SKY_COORDS.y - 0.5) * PI;
    vec3 dir = vec3(
        cos(lat) * cos(lon),
        sin(lat),
        cos(lat) * sin(lon)
    );

    // --- Pulsation ondulante globale ---
    float wave = sin(dot(dir*2.0, vec3(1.0,1.0,1.0)) + TIME*1.5) * 0.25 + 0.75;

    // --- Tentacules / volutes cosmiques ---
    float swirl = sin(dot(dir*3.0, vec3(1.0,2.0,1.5)) + t*0.7);
    float swirl2 = cos(dot(dir*2.5, vec3(-1.0,1.5,2.0)) + t*0.9);
    float volute = (swirl + swirl2) * 0.25 + 0.5;

    // --- Noise eldritch vivant ---
    float n = fbm(dir*noise_scale + vec3(0.0, t, t*0.5)) * wave * volute;
    n = pow(n, 1.6);

    // --- Couleurs eldritch ---
    vec3 col = mix(color_void, color_flesh, n);
    col = mix(col, color_eldritch, n*n);

    // --- Étoiles rondes pulsantes ---
    float star_mask = star(SKY_COORDS, stars_density, TIME);
    col += color_star * star_mask;

    // --- Intensité finale ---
    COLOR = col * intensity;
}
