Shader "Custom/GrassShaderURP"
{
    Properties
    {
        _Color("Base Color", Color) = (0.2, 0.8, 0.2, 1)
        _MainTex("Main Texture", 2D) = "white" {}
        _WindStrength("Wind Strength", Float) = 0.03
        _WindFrequency("Wind Frequency", Float) = 1.0
        _WindDirection("Wind Direction", Vector) = (1, 0, 0)
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

                FragmentInput vert(VertexInput IN)
                {
                    FragmentInput OUT;

                    // Get time-based animation value
                    float time = _Time.y * _WindFrequency;

                    // Transform vertex position to world space
                    float3 worldPos = TransformObjectToWorld(IN.positionOS.xyz);

                    // Normalize wind direction and calculate wave offset
                    float3 normalizedDirection = normalize(_WindDirection);
                    float noise = frac(sin(dot(worldPos.xz, float2(12.9898, 78.233))) * 43758.5453);
                    float wave = sin(dot(worldPos.xz, normalizedDirection.xz) * 0.5 + time + noise) * _WindStrength;

                    // Apply wave to the y-position
                    worldPos.y += wave;

                    // Transform back to homogeneous clip space
                    OUT.positionHCS = TransformWorldToHClip(worldPos);
                    OUT.uv = IN.uv;
                    return OUT;
                }

                half4 frag(FragmentInput IN) : SV_Target
                {
                    half4 texColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                    return texColor * _Color;
                }
                ENDHLSL
            }
        }

            Fallback Off
}