uniform float4x4 ViewProj;
uniform float4 color;

struct VertData {
	float4 pos : POSITION;
};

VertData mainTransform(VertData v_in)
{
	VertData v_in;
	v_in.pos = mul(float4(v_in.pos.xyz, 1.0), ViewProj);
	return v_in;
}

float4 mainImage(VertData v_in) : TARGET
{
	return color;
}

technique Draw
{
	pass
	{
		vertex_shader = mainTransform(v_in);
		pixel_shader  = mainImage(v_in);
	}
}
