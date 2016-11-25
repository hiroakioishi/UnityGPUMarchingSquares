Shader "Hidden/GPUMarchingSquares/Render"
{
	Properties
	{
	}

	CGINCLUDE
	#include "UnityCG.cginc"

	#define M_PI 3.1415926535897932384626433832795

		struct VoxelData
	{
		float3 pos : POSITION;
		float2 uv  : TEXCOORD0;
	};

	struct v2g
	{
		float4 pos   : SV_POSITION;
		float2 uv    : TEXCOORD0;
	};

	struct g2f
	{
		float4 pos : SV_POSITION;
		float4 col : COLOR;
	};

	static const int counts[16] =
	{
		0, 1, 1, 2,
		1, 2, 2, 3,
		1, 2, 2, 3,
		2, 3, 3, 2
	};

	static const float3 indices[16][3] =
	{
		{ { 8, 8, 8 },{ 8, 8, 8 },{ 8, 8, 8 } }, // 0
		{ { 5, 4, 0 },{ 8, 8, 8 },{ 8, 8, 8 } }, // 1
		{ { 1, 4, 6 },{ 8, 8, 8 },{ 8, 8, 8 } }, // 2
		{ { 6, 1, 0 },{ 0, 5, 6 },{ 8, 8, 8 } }, // 3

		{ { 7, 5, 2 },{ 8, 8, 8 },{ 8, 8, 8 } }, // 4
		{ { 2, 4, 0 },{ 4, 2, 7 },{ 8, 8, 8 } }, // 5
		{ { 7, 5, 2 },{ 1, 4, 6 },{ 8, 8, 8 } }, // 6
		{ { 0, 2, 7 },{ 0, 7, 6 },{ 0, 6, 1 } }, // 7

		{ { 6, 7, 3 },{ 8, 8, 8 },{ 8, 8, 8 } }, // 8
		{ { 5, 4, 0 },{ 6, 7, 3 },{ 8, 8, 8 } }, // 9
		{ { 7, 1, 4 },{ 1, 7, 3 },{ 8, 8, 8 } }, // 10
		{ { 0, 5, 7 },{ 0, 7, 3 },{ 0, 3, 1 } }, // 11

		{ { 2, 6, 5 },{ 3, 6, 2 },{ 8, 8, 8 } }, // 12
		{ { 0, 2, 3 },{ 0, 3, 6 },{ 0, 6, 4 } }, // 13
		{ { 3, 1, 2 },{ 4, 5, 2 },{ 2, 1, 4 } }, // 14
		{ { 2, 1, 0 },{ 1, 2, 3 },{ 8, 8, 8 } }, // 15
	};

	StructuredBuffer<VoxelData> _VoxelBuffer;
	sampler2D _DensityTex;

	float3 _VoxelSize;
	fixed4 _Color;
	int    _Interpolation; // 0:false, 1:true

	v2g vert(uint id : SV_VertexID)
	{
		v2g o = (v2g)0;
		float2 uv = _VoxelBuffer[id].uv;
		o.pos = float4(uv, 0, 1);
		o.uv = uv;
		return o;
	}

	[maxvertexcount(9)]
	void geom(point v2g input[1], inout TriangleStream<g2f> triStream)
	{
		g2f o = (g2f)0;

		float2 uv = input[0].uv;

		float3 center = input[0].pos.xyz - 0.5;

		float2 delta = _VoxelSize.xy * _VoxelSize.z;

		float2 dx = float2(delta.x, 0.0);
		float2 dy = float2(0.0, delta.y);

		float c0 = tex2Dlod(_DensityTex, float4(uv, 0, 0) + float4(-_VoxelSize.x * 0.5, -_VoxelSize.y * 0.5, 0, 0)).r;
		float c1 = tex2Dlod(_DensityTex, float4(uv, 0, 0) + float4(_VoxelSize.x * 0.5, -_VoxelSize.y * 0.5, 0, 0)).r;
		float c2 = tex2Dlod(_DensityTex, float4(uv, 0, 0) + float4(-_VoxelSize.x * 0.5, _VoxelSize.y * 0.5, 0, 0)).r;
		float c3 = tex2Dlod(_DensityTex, float4(uv, 0, 0) + float4(_VoxelSize.x * 0.5, _VoxelSize.y * 0.5, 0, 0)).r;

		float2 pos[8] = { float2(0,0), float2(0,0), float2(0,0), float2(0,0), float2(0,0), float2(0,0), float2(0,0), float2(0,0) };
		pos[0] = -dx - dy; // LB
		pos[1] = +dx - dy; // RB
		pos[2] = -dx + dy; // LT
		pos[3] = +dx + dy; // RT
		pos[4] = -dy;
		pos[5] = -dx;
		pos[6] = +dx;
		pos[7] = +dy;

		int cellType = 0;
		if (_Interpolation < 0.5)
		{
			cellType =
				step(0.5, c0) +
				step(0.5, c1) * 2 +
				step(0.5, c2) * 4 +
				step(0.5, c3) * 8;
		}
		else
		{
			cellType =
				step(0.2, c0) +
				step(0.2, c1) * 2 +
				step(0.2, c2) * 4 +
				step(0.2, c3) * 8;

			float b = lerp(-1.0, 1.0, ((0.2 - c0) / (c1 - c0)));
			float l = lerp(-1.0, 1.0, ((0.2 - c0) / (c2 - c0)));
			float r = lerp(-1.0, 1.0, ((0.2 - c1) / (c3 - c1)));
			float t = lerp(-1.0, 1.0, ((0.2 - c2) / (c3 - c2)));

			pos[4] = +b * dx - dy;
			pos[5] = -dx + l * dy;
			pos[6] = +dx + r * dy;
			pos[7] = +t * dx + dy;

		}
		

		for (int p = 0; p < counts[cellType]; ++p)
		{
			for (int v = 0; v < 3; v++)
			{
				float3 vp = center + float3(pos[indices[cellType][p][v]], 0);
				o.pos = mul(UNITY_MATRIX_MVP, float4(vp, 1));
				o.col = float4(uv.xy, 0, 1);

				triStream.Append(o);
			}
			triStream.RestartStrip();
		}
	}

	fixed4 frag(g2f i) : SV_Target
	{
		return _Color;
		//return i.col;
	}

		ENDCG

		SubShader
	{
		Tags{ "RenderType" = "Opaque" }
			LOD 100
			Cull Off
			Pass
		{
			CGPROGRAM
			#pragma target 5.0
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag
			ENDCG
		}
	}

}