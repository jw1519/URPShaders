// Custom unlit shader for URP/HDRP
Shader "Custom/URPUnlitBaseColor"
{
    Properties
    {
        // Base colour property accessible from the inspector
        _BaseColor("Base Color", Color) = (1, 0, 0, 1)
    }

        SubShader
    {
        // Specify rendering for Universal Render Pipeline
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert      // Vertex shader entry point
            #pragma fragment frag    // Fragment shader entry point
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // Input structure from Unity's vertex pipeline
            struct Attributes
            {
                float4 positionOS : POSITION; // Object space vertex position
            };

            // Data passed from the vertex shader to the fragment shader
            struct FragmentInput
            {
                float4 positionHCS : SV_POSITION; // Homogeneous clip-space position
            };

            // Base colour property
            float4 _BaseColor;

            // Vertex shader: transform vertex positions to clip space
            FragmentInput vert(Attributes IN)
            {
                FragmentInput OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                return OUT;
            }

            // Fragment shader: return the base colour
            half4 frag(FragmentInput IN) : SV_Target
            {
                return half4(_BaseColor.rgb, _BaseColor.a);
            }
            ENDHLSL
        }
    }
}