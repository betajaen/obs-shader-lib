uniform float4x4 ViewProj;
uniform float4   first;
uniform float4   last;
uniform float    speed;

uniform texture2d image;

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
	float s = abs(sin(elapsed_time * speed * 0.01));
	return lerp(first, last, s);
}

technique Draw
{
	pass
	{
		vertex_shader = mainTransform(v_in);
		pixel_shader  = mainImage(v_in);
	}
}
