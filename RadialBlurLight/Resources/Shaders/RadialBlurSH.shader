Shader "Unlit/RadialBlurSH"
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

        #define SAMPLE_COUNT 12
        #define ONE_OVER_SAMPLE_COUNT  1.0f/SAMPLE_COUNT

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        float _Threshold;
        float _factor;
        float2 _sunPos;

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
            output.uv.xy = UnityStereoTransformScreenSpaceTex(input.texcoord);
            return output;
        }

        half4 Fragment(Varyings input) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
            half4 col = half4(0,0,0,0);
            half2 dir = _sunPos - input.uv.xy;
         //   half oneOverSampleCnt = 1.0f/(float)SAMPLE_COUNT;
            half2 delta = _factor*dir*ONE_OVER_SAMPLE_COUNT;
            for(int i = 0; i < SAMPLE_COUNT; ++i){
                half2 uv = input.uv.xy + i*delta;
                col += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
            }
            return half4(col.rgb*ONE_OVER_SAMPLE_COUNT,1);
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