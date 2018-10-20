uniform float4x4 ViewProj;
uniform float4   minColor;
uniform float4   maxColor;
uniform float    seed;

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

float rand(float2 co){
    return frac(sin(dot(co.xy, float2(12.9898, 78.233))) * 43758.5453);
}

float4 mainImage(VertData v_in) : TARGET
{
	float s = seed;
	float x = lerp(minColor.x, maxColor.x, rand(float2(s,s)));
	s += x;
	float y = lerp(minColor.y, maxColor.y, rand(float2(s,s)));
	s += y;
	float z = lerp(minColor.z, maxColor.z, rand(float2(s,s)));

	return float4(x,y,z, 1);
}

technique Draw
{
	pass
	{
		vertex_shader = mainTransform(v_in);
		pixel_shader  = mainImage(v_in);
	}
}
