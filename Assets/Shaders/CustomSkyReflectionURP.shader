Shader "Custom/SkyReflectionURP"
{
    Properties
    {
        // Add any properties if needed for future customisation
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalRenderPipeline" "RenderType" = "Opaque" }

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct VertexInput
            {
                float4 positionOS : POSITION; // Object space vertex position
                float3 normalOS : NORMAL;    // Object space normal
            };

            struct FragmentInput
            {
                float4 positionHCS : SV_POSITION; // Clip-space position
                float3 worldRefl : TEXCOORD0;     // World space reflection vector
            };

            // Vertex shader: calculates world reflection vector and clip-space position
            FragmentInput vert(VertexInput IN)
            {
                FragmentInput OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                float3 worldPos = TransformObjectToWorld(IN.positionOS.xyz);
                float3 worldViewDir = GetWorldSpaceViewDir(worldPos);
                float3 worldNormal = TransformObjectToWorldNormal(IN.normalOS);
                OUT.worldRefl = reflect(-worldViewDir, worldNormal);
                return OUT;
            }

            // Fragment shader: samples the reflection cubemap
            half4 frag(FragmentInput IN) : SV_Target
            {
                // Sample the cubemap using the reflection vector
                half4 skyData = SAMPLE_TEXTURECUBE_LOD(_GlossyEnvironmentCubeMap, sampler_GlossyEnvironmentCubeMap, IN.worldRefl, 0);

                // Use the sampled colour directly without HDR decoding
                return half4(skyData.rgb, 1.0);
            }
            ENDHLSL
        }
    }
}