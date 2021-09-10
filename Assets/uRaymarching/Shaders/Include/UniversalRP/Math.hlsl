#ifndef URAYMARCHING_MATH_HLSL
#define URAYMARCHING_MATH_HLSL

#include "Packages/jp.keijiro.noiseshader/Shader/Common.hlsl"

float Rand(float2 seed)
{
    return frac(sin(dot(seed, float2(12.9898, 78.233))) * 43758.5453);
}

inline float Mod(float a, float b)
{
    return frac(abs(a / b)) * abs(b);
}

inline float2 Mod(float2 a, float2 b)
{
    return frac(abs(a / b)) * abs(b);
}

inline float3 Mod(float3 a, float3 b)
{
    return frac(abs(a / b)) * abs(b);
}

inline float SmoothMin(float d1, float d2, float k)
{
    float h = exp(-k * d1) + exp(-k * d2);
    return -log(h) / k;
}

inline float SmoothMax(float a, float b, float k) {
  return -SmoothMin(-a, -b, k);
}

inline float Repeat(float pos, float span)
{
    return Mod(pos, span) - span * 0.5;
}

inline float2 Repeat(float2 pos, float2 span)
{
    return Mod(pos, span) - span * 0.5;
}

inline float3 Repeat(float3 pos, float3 span)
{
    return Mod(pos, span) - span * 0.5;
}

inline float3 Rotate(float3 p, float angle, float3 axis)
{
    float3 a = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float r = 1.0 - c;
    float3x3 m = float3x3(
        a.x * a.x * r + c,
        a.y * a.x * r + a.z * s,
        a.z * a.x * r - a.y * s,
        a.x * a.y * r - a.z * s,
        a.y * a.y * r + c,
        a.z * a.y * r + a.x * s,
        a.x * a.z * r + a.y * s,
        a.y * a.z * r - a.x * s,
        a.z * a.z * r + c
    );
    return mul(m, p);
}

inline float3 TwistY(float3 p, float power)
{
    float s = sin(power * p.y);
    float c = cos(power * p.y);
    float3x3 m = float3x3(
          c, 0.0,  -s,
        0.0, 1.0, 0.0,
          s, 0.0,   c
    );
    return mul(m, p);
}

inline float3 TwistX(float3 p, float power)
{
    float s = sin(power * p.y);
    float c = cos(power * p.y);
    float3x3 m = float3x3(
        1.0, 0.0, 0.0,
        0.0,   c,   s,
        0.0,  -s,   c
    );
    return mul(m, p);
}

inline float3 TwistZ(float3 p, float power)
{
    float s = sin(power * p.y);
    float c = cos(power * p.y);
    float3x3 m = float3x3(
          c,   s, 0.0,
         -s,   c, 0.0,
        0.0, 0.0, 1.0
    );
    return mul(m, p);
}

float ClassicNoise_impl(float3 pi0, float3 pf0, float3 pi1, float3 pf1)
{
    pi0 = wglnoise_mod289(pi0);
    pi1 = wglnoise_mod289(pi1);

    float4 ix = float4(pi0.x, pi1.x, pi0.x, pi1.x);
    float4 iy = float4(pi0.y, pi0.y, pi1.y, pi1.y);
    float4 iz0 = pi0.z;
    float4 iz1 = pi1.z;

    float4 ixy = wglnoise_permute(wglnoise_permute(ix) + iy);
    float4 ixy0 = wglnoise_permute(ixy + iz0);
    float4 ixy1 = wglnoise_permute(ixy + iz1);

    float4 gx0 = lerp(-1, 1, frac(floor(ixy0 / 7) / 7));
    float4 gy0 = lerp(-1, 1, frac(floor(ixy0 % 7) / 7));
    float4 gz0 = 1 - abs(gx0) - abs(gy0);

    bool4 zn0 = gz0 < -0.01;
    gx0 += zn0 * (gx0 < -0.01 ? 1 : -1);
    gy0 += zn0 * (gy0 < -0.01 ? 1 : -1);

    float4 gx1 = lerp(-1, 1, frac(floor(ixy1 / 7) / 7));
    float4 gy1 = lerp(-1, 1, frac(floor(ixy1 % 7) / 7));
    float4 gz1 = 1 - abs(gx1) - abs(gy1);

    bool4 zn1 = gz1 < -0.01;
    gx1 += zn1 * (gx1 < -0.01 ? 1 : -1);
    gy1 += zn1 * (gy1 < -0.01 ? 1 : -1);

    float3 g000 = normalize(float3(gx0.x, gy0.x, gz0.x));
    float3 g100 = normalize(float3(gx0.y, gy0.y, gz0.y));
    float3 g010 = normalize(float3(gx0.z, gy0.z, gz0.z));
    float3 g110 = normalize(float3(gx0.w, gy0.w, gz0.w));
    float3 g001 = normalize(float3(gx1.x, gy1.x, gz1.x));
    float3 g101 = normalize(float3(gx1.y, gy1.y, gz1.y));
    float3 g011 = normalize(float3(gx1.z, gy1.z, gz1.z));
    float3 g111 = normalize(float3(gx1.w, gy1.w, gz1.w));

    float n000 = dot(g000, pf0);
    float n100 = dot(g100, float3(pf1.x, pf0.y, pf0.z));
    float n010 = dot(g010, float3(pf0.x, pf1.y, pf0.z));
    float n110 = dot(g110, float3(pf1.x, pf1.y, pf0.z));
    float n001 = dot(g001, float3(pf0.x, pf0.y, pf1.z));
    float n101 = dot(g101, float3(pf1.x, pf0.y, pf1.z));
    float n011 = dot(g011, float3(pf0.x, pf1.y, pf1.z));
    float n111 = dot(g111, pf1);

    float3 fade_xyz = wglnoise_fade(pf0);
    float4 n_z = lerp(float4(n000, n100, n010, n110),
                      float4(n001, n101, n011, n111), fade_xyz.z);
    float2 n_yz = lerp(n_z.xy, n_z.zw, fade_xyz.y);
    float n_xyz = lerp(n_yz.x, n_yz.y, fade_xyz.x);
    return 1.46 * n_xyz;
}

// Classic Perlin noise
float ClassicNoise(float3 p)
{
    float3 i = floor(p);
    float3 f = frac(p);
    return ClassicNoise_impl(i, f, i + 1, f - 1);
}

// Classic Perlin noise, periodic variant
float PeriodicNoise(float3 p, float3 rep)
{
    float3 i0 = wglnoise_mod(floor(p), rep);
    float3 i1 = wglnoise_mod(i0 + 1, rep);
    float3 f = frac(p);
    return ClassicNoise_impl(i0, f, i1, f - 1);
}

float4 SimplexNoiseGrad(float3 v)
{
    // First corner
    float3 i  = floor(v + dot(v, 1.0 / 3));
    float3 x0 = v   - i + dot(i, 1.0 / 6);

    // Other corners
    float3 g = x0.yzx <= x0.xyz;
    float3 l = 1 - g;
    float3 i1 = min(g.xyz, l.zxy);
    float3 i2 = max(g.xyz, l.zxy);

    float3 x1 = x0 - i1 + 1.0 / 6;
    float3 x2 = x0 - i2 + 1.0 / 3;
    float3 x3 = x0 - 0.5;

    // Permutations
    i = wglnoise_mod289(i); // Avoid truncation effects in permutation
    float4 p = wglnoise_permute(    i.z + float4(0, i1.z, i2.z, 1));
           p = wglnoise_permute(p + i.y + float4(0, i1.y, i2.y, 1));
           p = wglnoise_permute(p + i.x + float4(0, i1.x, i2.x, 1));

    // Gradients: 7x7 points over a square, mapped onto an octahedron.
    // The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
    float4 gx = lerp(-1, 1, frac(floor(p / 7) / 7));
    float4 gy = lerp(-1, 1, frac(floor(p % 7) / 7));
    float4 gz = 1 - abs(gx) - abs(gy);

    bool4 zn = gz < -0.01;
    gx += zn * (gx < -0.01 ? 1 : -1);
    gy += zn * (gy < -0.01 ? 1 : -1);

    float3 g0 = normalize(float3(gx.x, gy.x, gz.x));
    float3 g1 = normalize(float3(gx.y, gy.y, gz.y));
    float3 g2 = normalize(float3(gx.z, gy.z, gz.z));
    float3 g3 = normalize(float3(gx.w, gy.w, gz.w));

    // Compute noise and gradient at P
    float4 m  = float4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3));
    float4 px = float4(dot(g0, x0), dot(g1, x1), dot(g2, x2), dot(g3, x3));

    m = max(0.5 - m, 0);
    float4 m3 = m * m * m;
    float4 m4 = m * m3;

    float4 temp = -8 * m3 * px;
    float3 grad = m4.x * g0 + temp.x * x0 +
                  m4.y * g1 + temp.y * x1 +
                  m4.z * g2 + temp.z * x2 +
                  m4.w * g3 + temp.w * x3;

    return 107 * float4(grad, dot(m4, px));
}

float SimplexNoise(float3 v)
{
    return SimplexNoiseGrad(v).w;
}

#define m3 float3x3(-0.73736, 0.45628, 0.49808, 0, -0.73736, 0.67549, 0.67549, 0.49808, 0.54371)

float3 SineNoise(float3 v, float t)
{
    float3 q = float3(v.x, v.y + t, v.z);
    float3 c = float3(0,0,0);
    for (int i = 0; i < 8; i++) {
        q = mul(q, m3);// m3* q;
        float3 s = sin(q.xzy);
        q += s * 2.;
        c += s;
    }
    return c;
}

#endif
