uniform float4x4  ViewProj;
uniform texture2d image;
uniform float2    uv_pixel_interval;

sampler_state textureSampler {
	Filter    = Linear;
	AddressU  = Wrap;
	AddressV  = Wrap;
	BorderColor = 00000000;
};

struct VertData {
	float4 pos : POSITION;
	float2 uv  : TEXCOORD;  // FC
	float4 uv1 : TEXCOORD1; // NW, NE
	float4 uv2 : TEXCOORD2; // SW, SE
};

VertData mainTransform(VertData v_in)
{
	VertData     v_out;
	v_out.pos    = mul(float4(v_in.pos.xyz, 1.0), ViewProj);

	v_out.uv     = v_in.uv;
	v_out.uv1.xy = v_in.uv + float2(-1,-1) * uv_pixel_interval;
	v_out.uv1.zw = v_in.uv + float2(+1,-1) * uv_pixel_interval;
	v_out.uv2.xy = v_in.uv + float2(-1,+1) * uv_pixel_interval;
	v_out.uv2.zw = v_in.uv + float2(+1,+1) * uv_pixel_interval;

	return v_out;
}

float4 mainImage(VertData v_in) : TARGET
{
	const float fxaa_reduce_min = 1.0 / 128.0;
	const float kMaxScaled = 1.0 / 8.0;
	const float kSharpness = 8.0;
	const float3 luma = float3(0.299, 0.587, 0.114); 


	float3 rgbNW  = image.Sample(textureSampler, v_in.uv1.xy).xyz;
	float3 rgbNE  = image.Sample(textureSampler, v_in.uv1.zw).xyz;
	float3 rgbSW  = image.Sample(textureSampler, v_in.uv2.xy).xyz;
	float3 rgbSE  = image.Sample(textureSampler, v_in.uv2.zw).xyz;
	float4 color  = image.Sample(textureSampler, v_in.uv.xy);
	float3 rgbM   = color.xyz;

	float  lumaNW = dot(luma, rgbNW);
	float  lumaNE = dot(luma, rgbNE) + 1.0 / 384.0;
	float  lumaSW = dot(luma, rgbSW);
	float  lumaSE = dot(luma, rgbSE);
	float  lumaM  = dot(luma, rgbM);

	float  lumaDiagMin = min(min(lumaNW, lumaNE), min(lumaSW, lumaSE));
	float  lumaMin = min(lumaM, lumaDiagMin);

	float  lumaDiagMax = max(min(lumaNW, lumaNE), max(lumaSW, lumaSE));
	float  lumaMax = max(lumaM, lumaDiagMax);

	if ((lumaMax - lumaMin) < max(0.05, lumaDiagMax * kMaxScaled))
		return float4(rgbM, color.w);

	float2 dir;
	dir.x = (lumaSW - lumaNE) + (lumaSE - lumaNW);
	dir.y = (lumaSW - lumaNE) - (lumaSE - lumaNW);

	dir = normalize(dir);

	float3 n1 = image.Sample(textureSampler, v_in.uv - dir * (0.5 * uv_pixel_interval)).xyz;
	float3 p1 = image.Sample(textureSampler, v_in.uv + dir * (0.5 * uv_pixel_interval)).xyz;

	float dirRep = min(abs(dir.x), abs(dir.y)) * kSharpness; // sharpness
	float2 dir2 = clamp(dir.xy / dirRep, -2.0, 2.0);

	float3 n2 = image.Sample(textureSampler, v_in.uv - dir2 * (2.0 * uv_pixel_interval)).xyz;
	float3 p2 = image.Sample(textureSampler, v_in.uv + dir2 * (2.0 * uv_pixel_interval)).xyz;

	float3 rgbA = n1 + p1;
	float3 rgbB = ((n2 + p2) * 0.25) + (rgbA * 0.25);

	float lumaRGBB = rgbB.y;

	if (lumaRGBB < lumaMin || lumaRGBB > lumaMax)
		return float4(rgbA * 0.5, color.w);
	else
		return float4(rgbB, color.w);
}

technique Draw
{
	pass
	{
		vertex_shader = mainTransform(v_in);
		pixel_shader  = mainImage(v_in);
	}
}
