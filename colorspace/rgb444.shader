uniform float4x4 ViewProj;
uniform texture2d image;

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

int doRound(int number, int multiple)
{
    return ((number + multiple/2) / multiple) * multiple;
}

float4 mainImage(VertData v_in) : TARGET
{
	float2 uv = v_in.uv;
	float3 col = image.Sample(textureSampler, uv).xyz;
	col *= 255.0;

	int R = int(col.r);
    int G = int(col.g);
    int B = int(col.b);
    
    R = R * 15 / 255;
    G = G * 15 / 255;
    B = B * 15 / 255;
    
    R = R * 16 + R;
    G = G * 16 + G;
    B = B * 16 + B;
       
    col = float3(R, G, B) / 255.0;

	return float4(col, 1);
}


technique Draw
{
	pass
	{
		vertex_shader = mainTransform(v_in);
		pixel_shader  = mainImage(v_in);
	}
}
