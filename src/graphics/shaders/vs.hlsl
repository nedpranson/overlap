cbuffer vertexBuffer : register(b0)
{
  float4x4 mvp;
};

struct VertexInput
{
  float2 pos : POSITION;
  float2 uv  : TEXCOORD0;
  uint   col : COLOR0;
  uint flags : TEXCOORD1;
};

struct VertexOutput
{
  float4 pos : SV_POSITION;
  float2 uv  : TEXCOORD0;
  float4 col : COLOR0;
  uint flags : TEXCOORD1;
};

float4 unpack_uint(uint col)
{
    float4 result;
    result.w = ((col >> 0)  & 0xFF) / 255.0;
    result.z = ((col >> 8)  & 0xFF) / 255.0;
    result.y = ((col >> 16) & 0xFF) / 255.0;
    result.x = ((col >> 24) & 0xFF) / 255.0;
    return result;
}

VertexOutput VS(VertexInput input)
{
  VertexOutput output;
  output.pos = mul(mvp, float4(input.pos, 0.0, 1.0));
  output.uv = input.uv;
  output.col = unpack_uint(input.col);
  output.flags = input.flags;
  return output;
}
