Shader "Unlit/BlendSH"
{
    Properties{
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags{ "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}

        HLSLINCLUDE

        #pragma prefer_hlslcc gles
        #pragma exclude_renderers d3d11_9x

        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityInput.hlsl"

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);

        TEXTURE2D(_ResRadialBlurTex);
        SAMPLER(sampler_ResRadialBlurTex);

        //xy:sunpos  z:_range  w:radio
        float4 _param;

        struct Attributes
        {
            float4 positionOS   : POSITION;
            float2 texcoord : TEXCOORD0;
            UNITY_VERTEX_INPUT_INSTANCE_ID
        };

        struct Varyings
        {
            half4  positionCS   : SV_POSITION;
            half2  uv           : TEXCOORD0;
            
            UNITY_VERTEX_OUTPUT_STEREO
        };

        Varyings Vertex(Attributes input)
        {
            Varyings output;
            UNITY_SETUP_INSTANCE_ID(input);
            UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
            output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
            output.uv = UnityStereoTransformScreenSpaceTex(input.texcoord);
            return output;
        }

        half4 Fragment(Varyings input) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
            float factor = _param.w*saturate(_param.z - length(_param.xy-half2(0.5f,0.5f)));
            return half4(SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv).rgb + factor*SAMPLE_TEXTURE2D(_ResRadialBlurTex, sampler_ResRadialBlurTex, input.uv).rgb,1);
            //return half4(SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv).rgb*(1-factor) +  factor*SAMPLE_TEXTURE2D(_ResRadialBlurTex, sampler_ResRadialBlurTex, input.uv).rgb,1);
        }

        ENDHLSL

        Pass
        {
            Name "RadialBlur"
            ZWrite Off
            Cull Off

            HLSLPROGRAM
            #pragma vertex   Vertex
            #pragma fragment Fragment
            ENDHLSL
        }
    }
}