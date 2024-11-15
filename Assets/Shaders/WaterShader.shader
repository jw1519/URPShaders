Shader "Custom/WaterShader"
{
    Properties
    {
        _Color("Base Color", Color) = (0.2, 0.8, 0.2, 0.5)
        _MainTex("Main Texture", 2D) = "white" {}
        _WindStrength("Wind Strength", Float) = 0.8
        _WindFrequency("Wind Frequency", Float) = 1.0
        _WindDirection("Wind Direction", Vector) = (1, 0, 1)
        _WaveDensity("Wave Density", Float) = 20.0
        _WaveHeight("Wave Height", Float) = 0.2
        _SwayStrength("Sway Strength", Float) = 0.1

        _DepthGradientShallow("Depth Gradient Shallow", Color) = (0.325, 0.807, 0.971, 0.725)
        _DepthGradientDeep("Depth Gradient Deep", Color) = (0.086, 0.407, 1, 0.749)
        _DepthMaxDistance("Depth Maximum Distance", Float) = 1
    }

        SubShader
        {
            Tags { "RenderPipeline" = "UniversalRenderPipeline" "RenderType" = "Opaque" }
            LOD 200

            Pass
            {
                Name "GrassPass"
                Tags { "LightMode" = "UniversalForward" }

                HLSLPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

                TEXTURE2D(_MainTex);
                SAMPLER(sampler_MainTex);
                float4 _Color;
                float _WindStrength;
                float _WindFrequency;
                float3 _WindDirection;
                float _WaveDensity;
                float _WaveHeight;
                float _SwayStrength;

                float4 _DepthGradientShallow;
                float4 _DepthGradientDeep;

                float _DepthMaxDistance;

                sampler2D _CameraDepthTexture;

                struct VertexInput
                {
                    float4 positionOS : POSITION;
                    float3 normalOS : NORMAL;
                    float2 uv : TEXCOORD0;
                };

                struct FragmentInput
                {
                    float4 positionHCS : SV_POSITION;
                    float2 uv : TEXCOORD0;
                };

                // Perlin noise function
                float perlinNoise(float2 coord)
                {
                    float2 p = floor(coord);
                    float2 f = frac(coord);

                    f = f * f * (3.0 - 2.0 * f);
                    float n = p.x + p.y * 57.0;

                    float res = lerp(
                        lerp(frac(sin(n) * 43758.5453), frac(sin(n + 1.0) * 43758.5453), f.x),
                        lerp(frac(sin(n + 57.0) * 43758.5453), frac(sin(n + 58.0) * 43758.5453), f.x),
                        f.y
                    );

                    return res;
                }

                FragmentInput vert(VertexInput IN)
                {
                    FragmentInput OUT;

                    // Time-based animation value
                    float time = _Time.y * _WindFrequency;

                    // Transform vertex position to world space
                    float3 worldPos = TransformObjectToWorld(IN.positionOS.xyz);

                    // Normalize wind direction and scale for density
                    float3 normalizedDirection = normalize(_WindDirection);
                    float2 scaledPos = worldPos.xz * _WaveDensity;

                    // Calculate random noise offset
                    float noiseOffset = perlinNoise(worldPos.xz * 0.1) * 2.0 - 1.0; // Perlin noise in range [-1, 1]

                    // Combine noise and sine wave for vertical wave motion
                    float wave = sin(dot(scaledPos, normalizedDirection.xz) + time + noiseOffset) * _WindStrength;
                    worldPos.y += wave * _WaveHeight;

                    // Add horizontal sway
                    float sway = sin(time + noiseOffset) * _SwayStrength;
                    worldPos.x += sway * normalizedDirection.x; // Sway along the X direction
                    worldPos.z += sway * normalizedDirection.z; // Sway along the Z direction

                    // Transform back to homogeneous clip space
                    OUT.positionHCS = TransformWorldToHClip(worldPos);
                    return OUT;
                }

                half4 frag(FragmentInput IN) : SV_Target
                {
                    // Sample the texture
                    half4 texColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);

                    // Apply color tint
                    return texColor * _Color;
                }
                ENDHLSL
            }
        }

            Fallback Off
}