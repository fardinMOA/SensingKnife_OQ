Shader "Raymarching/TransformProvider"
{

Properties
{
    [Header(Base)]
    [MainColor] _BaseColor("Color", Color) = (0.5, 0.5, 0.5, 1)
    [HideInInspector][MainTexture] _BaseMap("Albedo", 2D) = "white" {}
    [Gamma] _Metallic("Metallic", Range(0.0, 1.0)) = 0.5
    _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5

    [Header(Pass)]
    [Enum(UnityEngine.Rendering.CullMode)] _Cull("Culling", Int) = 2
    [Enum(UnityEngine.Rendering.BlendMode)] _BlendSrc("Blend Src", Float) = 5 
    [Enum(UnityEngine.Rendering.BlendMode)] _BlendDst("Blend Dst", Float) = 10
    [Toggle][KeyEnum(Off, On)] _ZWrite("ZWrite", Float) = 1

    [Header(Raymarching)]
    _Loop("Loop", Range(1, 100)) = 30
    _MinDistance("Minimum Distance", Range(0.001, 0.1)) = 0.01
    _DistanceMultiplier("Distance Multiplier", Range(0.001, 2.0)) = 1.0

    [PowerSlider(10.0)] _NormalDelta("NormalDelta", Range(0.00001, 0.1)) = 0.0001

// @block Properties
[Header(Additional Parameters)]
_Smooth("Smooth", float) = 1.0
_CubeColor("Cube Color", Color) = (1.0, 1.0, 1.0, 1.0)
_SphereColor("Sphere Color", Color) = (1.0, 1.0, 1.0, 1.0)
_TorusColor("Torus Color", Color) = (1.0, 1.0, 1.0, 1.0)
_PlaneColor("Plane Color", Color) = (1.0, 1.0, 1.0, 1.0)
_NoiseSize("Noise Size", Vector) = (0.01, 0.1, 0.1, 1.0)
// @endblock
}

SubShader
{

Tags 
{ 
    "RenderType" = "Opaque"
    "Queue" = "Geometry"
    "IgnoreProjector" = "True" 
    "RenderPipeline" = "UniversalPipeline" 
    "DisableBatching" = "True"
}

LOD 300

HLSLINCLUDE

#define WORLD_SPACE 

#define OBJECT_SHAPE_CUBE

#define CHECK_IF_INSIDE_OBJECT

#define DISTANCE_FUNCTION DistanceFunction
#define POST_EFFECT PostEffect

#include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
#include "Assets\uRaymarching\Shaders\Include\UniversalRP/Primitives.hlsl"
#include "Assets\uRaymarching\Shaders\Include\UniversalRP/Math.hlsl"
#include "Assets\uRaymarching\Shaders\Include\UniversalRP/Structs.hlsl"
#include "Assets\uRaymarching\Shaders\Include\UniversalRP/Utils.hlsl"

// @block DistanceFunction
// These inverse transform matrices are provided
// from TransformProvider script 
float4x4 _Cube;
float4x4 _Sphere;
float4x4 _Torus;
float4x4 _Plane; 
float4x4 _lKnife;

float _Smooth;
float3 _NoiseSize;

inline float DistanceFunction(float3 wpos)
{
    //wpos = wpos - ClassicNoise(wpos)*0.21;
    float4 cPos = mul(_Cube, float4(wpos, 1.0));
    float4 sPos = mul(_Sphere, float4(wpos, 1.0));
    float4 tPos = mul(_Torus, float4(wpos, 1.0));
    float4 pPos = mul(_Plane, float4(wpos, 1.0));
    float4 lKPos = mul(_lKnife, float4(wpos, 1.0));
    float s = Sphere(sPos, 0.5);
    //float s2 = Sphere(cPos, 0.6);
    float s2 = Sphere(cPos, 0.75) ;//+ SineNoise(cPos*0.1, _Time.x )*_NoiseSize.xyz, 0.75);
    //float s2 = Sphere(cPos + SimplexNoise(cPos*2.0)*0.21, 0.6);
    float t = Torus(tPos, float2(0.5, 0.2));
    float knife = min(Sphere(pPos, 0.075), Sphere(lKPos, 0.075));
    float sc = SmoothMin(s, s2, _Smooth);
   float tp = SmoothMin(t, knife, _Smooth);
    return SmoothMax(sc, -tp, _Smooth);
}
// @endblock

#define PostEffectOutput SurfaceData

// @block PostEffect
float4 _CubeColor;
float4 _SphereColor;
float4 _TorusColor;
float4 _PlaneColor;

inline void PostEffect(RaymarchInfo ray, inout PostEffectOutput o)
{
    float3 wpos = ray.endPos;// - ClassicNoise(ray.endPos)*0.21;
    float4 cPos = mul(_Cube, float4(wpos, 1.0));
    float4 sPos = mul(_Sphere, float4(wpos, 1.0));
    float4 tPos = mul(_Torus, float4(wpos, 1.0));
    float4 pPos = mul(_Plane, float4(wpos, 1.0));
    float4 lKPos = mul(_lKnife, float4(wpos, 1.0));
    float s = Sphere(sPos, 0.5);
    //float s2 = Sphere(cPos, 0.6);
    float s2 = Sphere(cPos, 0.75) ;//+ SineNoise(cPos*0.1,  _Time.x )*_NoiseSize.xyz, 0.75);
    //float s2 = Sphere(cPos + SimplexNoise(cPos*2.0)*0.21, 0.6);
    float t = Torus(tPos, float2(0.5, 0.2));
    float knife = min(Sphere(pPos, 0.075), Sphere(lKPos, 0.075));
   float4 a = normalize(float4(1.0 / s, 1.0 / s2, 1.0 / t, 1.0 / knife));
    o.albedo =
        a.x * _SphereColor +
        a.y * _CubeColor +
        a.z * _TorusColor +
        a.w * _PlaneColor;
}
// @endblock

ENDHLSL

Pass
{
    Name "ForwardLit"
    Tags { "LightMode" = "UniversalForward" }

    Blend [_BlendSrc] [_BlendDst]
    ZWrite [_ZWrite]
    Cull [_Cull]

    HLSLPROGRAM

    #pragma shader_feature _NORMALMAP
    #pragma shader_feature _ALPHATEST_ON
    #pragma shader_feature _ALPHAPREMULTIPLY_ON
    #pragma shader_feature _EMISSION
    #pragma shader_feature _METALLICSPECGLOSSMAP
    #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
    #pragma shader_feature _OCCLUSIONMAP
    #pragma shader_feature _SPECULARHIGHLIGHTS_OFF
    #pragma shader_feature _ENVIRONMENTREFLECTIONS_OFF
    #pragma shader_feature _SPECULAR_SETUP
    #pragma shader_feature _RECEIVE_SHADOWS_OFF

    #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
    #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
    #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
    #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
    #pragma multi_compile _ _SHADOWS_SOFT
    #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE

    #pragma multi_compile _ DIRLIGHTMAP_COMBINED
    #pragma multi_compile _ LIGHTMAP_ON
    #pragma multi_compile_fog
    #pragma multi_compile_instancing

    #pragma prefer_hlslcc gles
    #pragma exclude_renderers d3d11_9x
    #pragma target 2.0

    #define RAY_STOPS_AT_DEPTH_TEXTURE
    #define RAY_STARTS_FROM_DEPTH_TEXTURE

    #pragma vertex Vert
    #pragma fragment Frag
    #include "Assets\uRaymarching\Shaders\Include\UniversalRP/ForwardLit.hlsl"

    ENDHLSL
}

Pass
{
    Name "DepthOnly"
    Tags { "LightMode" = "DepthOnly" }

    ZWrite On
    ColorMask 0
    Cull [_Cull]

    HLSLPROGRAM

    #pragma shader_feature _ALPHATEST_ON
    #pragma multi_compile_instancing

    #pragma prefer_hlslcc gles
    #pragma exclude_renderers d3d11_9x
    #pragma target 2.0

    #pragma vertex Vert
    #pragma fragment Frag
    #include "Assets\uRaymarching\Shaders\Include\UniversalRP/DepthOnly.hlsl"

    ENDHLSL
}

}

FallBack "Hidden/Universal Render Pipeline/FallbackError"
CustomEditor "uShaderTemplate.MaterialEditor"

}