uniform float4x4  ViewProj;
uniform texture2d image;
uniform float2    uv_pixel_interval;

sampler_state textureSampler {
	Filter    = Point;
	AddressU  = Wrap;
	AddressV  = Wrap;
	BorderColor = 00000000;
};

struct VertData {
	float4 pos : POSITION;
	float2 uv  : TEXCOORD;
};

VertData mainTransform(VertData v_in)
{
	VertData     v_out;
	v_out.pos    = mul(float4(v_in.pos.xyz, 1.0), ViewProj);
	v_out.uv     = v_in.uv;

	return v_out;
}

float4 mainImage(VertData v_in) : TARGET
{
	// kernel definition (in glsl matrices are filled in column-major order)

	const float3x3 Gx = float3x3( -1, -2, -1, 0, 0, 0, 1, 2, 1 ); // x direction kernel
	const float3x3 Gy = float3x3( -1, 0, 1, -2, 0, 2, -1, 0, 1 ); // y direction kernel

	// fetch the 3x3 neighbourhood of a fragment

	// first column

	float3 tx0y0 = image.Sample(textureSampler, v_in.uv + uv_pixel_interval * float2( -1, -1 ) );
	float3 tx0y1 = image.Sample(textureSampler, v_in.uv + uv_pixel_interval * float2( -1,  0 ) );
	float3 tx0y2 = image.Sample(textureSampler, v_in.uv + uv_pixel_interval * float2( -1,  1 ) );

	// second column

	float3 tx1y0 = image.Sample(textureSampler, v_in.uv + uv_pixel_interval * float2(  0, -1 ) );
	float3 tx1y1 = image.Sample(textureSampler, v_in.uv + uv_pixel_interval * float2(  0,  0 ) );
	float3 tx1y2 = image.Sample(textureSampler, v_in.uv + uv_pixel_interval * float2(  0,  1 ) );

	// third column

	float3 tx2y0 = image.Sample(textureSampler, v_in.uv + uv_pixel_interval * float2(  1, -1 ) );
	float3 tx2y1 = image.Sample(textureSampler, v_in.uv + uv_pixel_interval * float2(  1,  0 ) );
	float3 tx2y2 = image.Sample(textureSampler, v_in.uv + uv_pixel_interval * float2(  1,  1 ) );

	// gradient value in x direction

	float3 valueGx = Gx[0][0] * tx0y0 + Gx[1][0] * tx1y0 + Gx[2][0] * tx2y0 + 
		Gx[0][1] * tx0y1 + Gx[1][1] * tx1y1 + Gx[2][1] * tx2y1 + 
		Gx[0][2] * tx0y2 + Gx[1][2] * tx1y2 + Gx[2][2] * tx2y2; 

	// gradient value in y direction

	float3 valueGy = Gy[0][0] * tx0y0 + Gy[1][0] * tx1y0 + Gy[2][0] * tx2y0 + 
		Gy[0][1] * tx0y1 + Gy[1][1] * tx1y1 + Gy[2][1] * tx2y1 + 
		Gy[0][2] * tx0y2 + Gy[1][2] * tx1y2 + Gy[2][2] * tx2y2; 

	// magnitute of the total gradient

	float3 G = (sqrt( ( valueGx * valueGx ) + ( valueGy * valueGy ) ));

	return float4(G, 1);
}

technique Draw
{
	pass
	{
		vertex_shader = mainTransform(v_in);
		pixel_shader  = mainImage(v_in);
	}
}
