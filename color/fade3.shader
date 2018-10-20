uniform float4x4 ViewProj;
uniform float4   first;
uniform float4   middle;
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

	if (s < 0.5)
		return lerp(first, middle, s * 2.0);
	else
		return lerp(middle, last, (s - 0.5) * 2.0);
}

technique Draw
{
	pass
	{
		vertex_shader = mainTransform(v_in);
		pixel_shader  = mainImage(v_in);
	}
}
