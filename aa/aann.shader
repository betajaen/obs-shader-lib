uniform float4x4 ViewProj;
uniform texture2d image;

uniform float2 elapsed_time;
uniform float2 uv_offset;
uniform float2 uv_scale;
uniform float2 uv_pixel_interval;

uniform float srcWidth;
uniform float srcHeight;
uniform float dstWidth;
uniform float dstHeight;

sampler_state textureSampler {
	Filter    = Linear;
	AddressU  = Border;
	AddressV  = Border;
	BorderColor = 00000000;
};

struct VertData {
	float4 pos : POSITION;
	float2 uv  : TEXCOORD0;
};

VertData mainTransform(VertData v_in)
{
	VertData vert_out;
	vert_out.pos = mul(float4(v_in.pos.xyz, 1.0), ViewProj);
	vert_out.uv  = v_in.uv;
	return vert_out;
}


#define NOT(fl) (1-fl)
#define YES(fl) fl

float4 vpow(float4 n, float e)
{
    return float4(pow(n.x, e), pow(n.y, e), pow(n.z, e), pow(n.w, e));
}

float4 getLQV(float3 mine) {
    return float4
    ( mine.r
    , mine.g
    , mine.b
    ,(mine.r + mine.g + mine.b)/3);
}

float3 fromLQV(float4 mine) {
    float f = mine.w/(mine.r + mine.g + mine.b)*3;
    return float3(mine.rgb)*f;
}

float3 percent(float ssize, float tsize, float coord) {
    float minfull = (coord*tsize - 0.5) /tsize*ssize;
    float maxfull = (coord*tsize + 0.5) /tsize*ssize;

    float realfull = floor(maxfull);

    if (minfull > realfull) {
        return float3(1, (realfull+0.5)/ssize, (realfull+0.5)/ssize);
    }

    return float3(
            (maxfull - realfull) / (maxfull - minfull),
            (realfull-0.5) / ssize,
            (realfull+0.5) / ssize
        );
}

float4 aann(float2 texture_size, float2 output_size, float2 texCoord)
{
    float cheapsrgb = 2.1;
    float gamma = 3.0;
    float3 xstuff = percent(texture_size.x, output_size.x, texCoord.x);
    float3 ystuff = percent(texture_size.y, output_size.y, texCoord.y);

    float xkeep = xstuff[0];
    float ykeep = ystuff[0];
    
    // get points to interpolate across, in linear rgb
    float4 a = getLQV(vpow(image.Sample(textureSampler,float2(xstuff[1],ystuff[1])), cheapsrgb).rgb);
    float4 b = getLQV(vpow(image.Sample(textureSampler,float2(xstuff[2],ystuff[1])), cheapsrgb).rgb);
    float4 c = getLQV(vpow(image.Sample(textureSampler,float2(xstuff[1],ystuff[2])), cheapsrgb).rgb);
    float4 d = getLQV(vpow(image.Sample(textureSampler,float2(xstuff[2],ystuff[2])), cheapsrgb).rgb);
    
    // use perceptual gamma for luminance component
    a.w = pow(a.w, 1/gamma);
    b.w = pow(b.w, 1/gamma);
    c.w = pow(c.w, 1/gamma);
    d.w = pow(d.w, 1/gamma);
    
    // interpolate
    float4 gammaLQVresult =
        NOT(xkeep)*NOT(ykeep)*a +
        YES(xkeep)*NOT(ykeep)*b +
        NOT(xkeep)*YES(ykeep)*c +
        YES(xkeep)*YES(ykeep)*d;
    
    // change luminance gamma back to linear
    float4 LQVresult = gammaLQVresult;
    LQVresult.w = pow(gammaLQVresult.w, gamma);
    
    // convert back to srgb; lqv -> lrgb -> srgb
    float4 c1 = vpow(float4(fromLQV(LQVresult), 1), 1/cheapsrgb);
      return c1;
}

float4 mainImage(VertData v_in) : TARGET
{
	return aann(float2(srcWidth, srcHeight), float2(dstWidth, dstHeight), v_in.uv);
}



technique Draw
{
	pass
	{
		vertex_shader = mainTransform(v_in);
		pixel_shader  = mainImage(v_in);
	}
}
