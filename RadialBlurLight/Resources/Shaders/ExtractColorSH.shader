Shader "Unlit/ExtractColorSH"
{
    Properties{
        _Threshold("Threshold", float) = 0.7
    }
    SubShader
    {
        Tags{ "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}

        HLSLINCLUDE

        #pragma prefer_hlslcc gles
        #pragma exclude_renderers d3d11_9x

        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
        

        TEXTURE2D(_CameraColorTexture);
        SAMPLER(sampler_CameraColorTexture);
        float _Threshold;

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
            half4 col = SAMPLE_TEXTURE2D(_CameraColorTexture, sampler_CameraColorTexture, input.uv);
            return step(_Threshold, col.b)*_MainLightColor;
        }

        ENDHLSL

        Pass
        {
            Name "ExtractColor"
            ZWrite Off
            Cull Off

            HLSLPROGRAM
            #pragma vertex   Vertex
            #pragma fragment Fragment
            ENDHLSL
        }
    }
}
