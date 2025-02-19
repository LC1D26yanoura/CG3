#include "Object3d.hlsl"

struct Material
{
    float4 color;
    int enableLighting;
    float4x4 uvTransform;
};

struct PixelShaderOutput
{
    float4 color : SV_TARGET0;
};

struct DirectionalLight
{
    float4 color;
    float3 direction;
    float intensity;
};

struct Camera
{
    float3 worldPosition;
};

ConstantBuffer<Material> gMaterial : register(b0);
Texture2D<float4> gTexture : register(t0);
SamplerState gSampler : register(s0);
ConstantBuffer<DirectionalLight> gDirectionalLight : register(b1);
ConstantBuffer<Camera> gCamera : register(b2);

PixelShaderOutput main(VertexShanderOutput input)
{
    float4 transformedUV = mul(float4(input.texcoord, 0.0f, 1.0f), gMaterial.uvTransform);
    float4 textureColor = gTexture.Sample(gSampler, transformedUV.xy);
    PixelShaderOutput output;
    
    if (gMaterial.enableLighting != 0)
    {
        float3 toEye = normalize(gCamera.worldPosition - input.worldPosition);
        
        float3 reflectLight = reflect(-gDirectionalLight.direction, normalize(input.normal));

        float RdotE = dot(reflectLight, toEye);
        float specularPow = pow(saturate(RdotE), 70); // 反射強度  
        
        float NdotL = dot(normalize(input.normal), -gDirectionalLight.direction);
        float cos = pow(NdotL * 0.5f + 0.5f, 2.0f);
        
       // output.color.rgb = gMaterial.color.rgb * textureColor.rgb * gDirectionalLight.color.rgb * cos * gDirectionalLight.intensity;
        
         // 拡散反射
        float3 diffuse = gMaterial.color.rgb * textureColor.rgb * gDirectionalLight.color.rgb * cos * gDirectionalLight.intensity;
        
        // 鏡面反射
        float3 specular = gDirectionalLight.color.rgb * gDirectionalLight.intensity * specularPow * float3(1.0f, 1.0f, 1.0f);
        
        //拡散反射・鏡面反射
        output.color.rgb = diffuse + specular;
        
         //アルファは今まで通り
        output.color.a = gMaterial.color.a * textureColor.a;
    }
    else
    { // Lightingしない場合。前回までと同じ演算
        output.color = gMaterial.color * textureColor;
    }
    //output.colorのα値が0の時にpixelを棄却
    if (output.color.a == 0.0)
    {
        discard;
    }
    return output;
}