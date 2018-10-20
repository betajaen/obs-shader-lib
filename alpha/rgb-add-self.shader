uniform float4x4  ViewProj;
uniform texture2d image;
uniform float amount;

sampler_state textureSampler {
	Filter    = Point;
	AddressU  = Wrap;
	AddressV  = Wrap;
	BorderColor = 00000000;
};

struct VertData {
	float4 pos : POSITION;
	float2 uv  : TEXCOORD0;
};

VertData mainTransform(VertData v_in)
{
	VertData v_out;
	v_out.pos = mul(float4(v_in.pos.xyz, 1.0), ViewProj);
	v_out.uv  = v_in.uv;
	return v_out;
}

float4 mainImage(VertData v_in) : TARGET
{
	float4 col = image.Sample(textureSampler, v_in.uv);
	return float4(saturate(col.xyz + col.xyz  * col.w * amount), 1);
}

technique Draw
{
	pass
	{
		vertex_shader = mainTransform(v_in);
		pixel_shader  = mainImage(v_in);
	}
}
