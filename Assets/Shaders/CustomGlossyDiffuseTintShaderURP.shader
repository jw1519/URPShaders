Shader "Custom/GlossyDiffuseTintShaderURP"
{
    Properties
    {
        // Defines a texture property for the base colour or pattern of the material.
        _MainTex("Main Texture", 2D) = "white" {}

    // Defines a tint colour to be applied to the texture.
    _Color("Tint Color", Color) = (1, 1, 1, 1)

        // Controls the glossiness of the material, affecting the sharpness of specular highlights.
        _Glossiness("Glossiness", Range(0, 1)) = 0.5

        // Defines the color of the specular highlights.
        _SpecColor("Specular Color", Color) = (1, 1, 1, 1)
    }

        SubShader
    {
        // Specifies that this shader is compatible with the Universal Render Pipeline and treats the material as opaque.
        Tags { "RenderPipeline" = "UniversalRenderPipeline" "RenderType" = "Opaque" }
        LOD 200 // Specifies the level of detail for the shader.

        Pass
        {
            // Configures the shader for URP's forward rendering pipeline.
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert      // Entry point for the vertex shader.
            #pragma fragment frag    // Entry point for the fragment shader.
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" // Includes URP's core shader utilities.

        // Input structure representing the vertex data.
        struct VertexInput
        {
            float4 positionOS : POSITION;  // Vertex position in object space.
            float3 normalOS : NORMAL;     // Normal vector in object space.
            float2 uv : TEXCOORD0;        // UV coordinates for texture sampling.
        };

        // Structure to pass data from the vertex shader to the fragment shader.
        struct FragmentInput
        {
            float4 positionHCS : SV_POSITION; // Position in homogeneous clip space.
            float3 worldNormal : TEXCOORD1;  // Normal vector transformed to world space.
            float3 worldPos : TEXCOORD2;     // Vertex position in world space.
            float2 uv : TEXCOORD0;           // UV coordinates for texture sampling.
        };

        // Texture and property declarations.
        TEXTURE2D(_MainTex);               // Main texture.
        SAMPLER(sampler_MainTex);          // Sampler for the main texture.
        float4 _Color;                     // Tint colour.
        float _Glossiness;                 // Glossiness factor.
        float4 _SpecColor;                 // Specular colour.

        // Vertex shader: prepares data for the fragment shader.
        FragmentInput vert(VertexInput IN)
        {
            FragmentInput OUT;
            // Transforms vertex position from object space to clip space.
            OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);

            // Transforms normal from object space to world space.
            OUT.worldNormal = TransformObjectToWorldNormal(IN.normalOS);

            // Transforms position from object space to world space.
            OUT.worldPos = TransformObjectToWorld(IN.positionOS.xyz);

            // Passes UV coordinates for texture sampling.
            OUT.uv = IN.uv;
            return OUT;
        }

        // Fragment shader: calculates the final pixel colour.
        half4 frag(FragmentInput IN) : SV_Target
        {
            // Samples the main texture using UV coordinates and applies the tint colour.
            half4 texColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
            half4 finalColor = texColor * _Color;

            // Calculates the diffuse lighting using the main directional light.
            float3 worldLightDir = normalize(_MainLightPosition.xyz); // Direction of the main light.
            float3 lightColor = _MainLightColor.rgb;                  // Colour of the main light.
            float lambert = max(0.0, dot(IN.worldNormal, worldLightDir)); // Lambertian reflection term.
            finalColor.rgb *= lambert * lightColor; // Modulates texture colour with diffuse lighting.

            // Calculates the specular highlights.
            float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - IN.worldPos); // View direction.
            float3 halfDir = normalize(viewDir + worldLightDir); // Halfway vector between view and light directions.

            // Adjusts glossiness to control the sharpness of specular highlights.
            float glossinessPower = lerp(8.0, 256.0, _Glossiness); // Maps glossiness from 0 to 1 to a reasonable range.
            float specIntensity = pow(max(0.0, dot(IN.worldNormal, halfDir)), glossinessPower); // Specular intensity.
            specIntensity *= saturate(_Glossiness); // Scales intensity based on glossiness.

            // Adds the specular highlights to the final colour.
            finalColor.rgb += specIntensity * _SpecColor.rgb * lightColor;

            // Outputs the final pixel colour.
            return finalColor;
        }
        ENDHLSL
        }
    }
}
