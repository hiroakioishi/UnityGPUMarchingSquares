Shader "Hidden/GPUMarchingSquares/DensityPainter"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}

	}
	CGINCLUDE
	#include "UnityCG.cginc"

	sampler2D _MainTex;
	float4 _MainTex_ST;

	float4 _Mouse;

	float  _Threshold;
	float  _Alpha;

	fixed4 frag(v2f_img i) : SV_Target
	{
		fixed4 col = tex2D(_MainTex, i.uv);

		float dist = distance(i.uv.xy, _Mouse.xy);
		if (dist < _Mouse.z)
		{
			dist /= _Mouse.z;
			dist = 1.0 - dist;
			dist *= _Alpha;
			col += _Mouse.w ? fixed4(dist, dist, dist, 0) : -fixed4(dist, dist, dist, 0);
		}
		return saturate(col);
	}

	ENDCG

	SubShader
	{
		Tags{ "RenderType" = "Opaque" }
		ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag
			ENDCG
		}
	}
}