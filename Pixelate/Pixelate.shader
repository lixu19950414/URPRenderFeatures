Shader "Hidden/Custom/Pixelate"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_PixelateX("Pixelate X", Int) = 5
		_PixelateY("Pixelate Y", Int) = 5
	}

	SubShader
	{
		Cull Off ZWrite Off ZTest Always
		Pass
		{
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			sampler2D _MainTex;
			int _PixelateX;
			int _PixelateY;

			struct appdata
			{
				float4 vertex: POSITION;
				float2 uv: TEXCOORD0;
			};

			struct v2f
			{
				float2 uv: TEXCOORD0;
				float4 vertex: SV_POSITION;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = TransformObjectToHClip(v.vertex.xyz);
				o.uv = v.uv;
				return o;
			}

			half4 frag(v2f i): SV_Target
			{
				int2 pixelate = int2(_PixelateX, _PixelateY);
				half4 rescol = float4(0, 0, 0, 0);
				float2 pixelSize = 1.0 / float2(_ScreenParams.x, _ScreenParams.y);
				float2 blockSize = pixelSize * pixelate;
				float2 currentBlock = float2
				(
					(floor(i.uv.x / blockSize.x) * blockSize.x),
					(floor(i.uv.y / blockSize.y) * blockSize.y)
				);
				rescol = tex2D(_MainTex, currentBlock + blockSize / 2);
				rescol += tex2D(_MainTex, currentBlock + float2(blockSize.x / 4, blockSize.y / 4));
				rescol += tex2D(_MainTex, currentBlock + float2(blockSize.x / 2,blockSize.y/4));
				rescol += tex2D(_MainTex, currentBlock + float2((blockSize.x / 4) * 3, blockSize.y / 4));
				rescol += tex2D(_MainTex, currentBlock + float2(blockSize.x / 4, blockSize.y / 2));
				rescol += tex2D(_MainTex, currentBlock + float2((blockSize.x / 4) * 3, blockSize.y / 2));
				rescol += tex2D(_MainTex, currentBlock + float2(blockSize.x / 4, (blockSize.y / 4) * 3));
				rescol += tex2D(_MainTex, currentBlock + float2(blockSize.x / 2, (blockSize.y / 4) * 3));
				rescol += tex2D(_MainTex, currentBlock + float2((blockSize.x / 4) * 3, (blockSize.y / 4) * 3));
				rescol /= 9;
				return rescol;
			}

			ENDHLSL
		}
	}
}
