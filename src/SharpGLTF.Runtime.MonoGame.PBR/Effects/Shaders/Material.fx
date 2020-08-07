﻿

// https://github.com/KhronosGroup/glTF-Sample-Viewer/blob/master/src/shaders/pbr.frag#L93

struct MaterialInfo
{
    float perceptualRoughness;      // roughness value, as authored by the model creator (input to shader)
    float3 f0;                        // full reflectance color (n incidence angle)

    float alphaRoughness;           // roughness mapped to a more linear change in the roughness (proposed by [2])
    float3 albedoColor;

    float3 f90;                       // reflectance color at grazing angle
    float metallic;

    float3 n;
    float3 baseColor; // getBaseColor()

    float sheenIntensity;
    float3 sheenColor;
    float sheenRoughness;

    float anisotropy;

    float3 clearcoatF0;
    float3 clearcoatF90;
    float clearcoatFactor;
    float3 clearcoatNormal;
    float clearcoatRoughness;

    float subsurfaceScale;
    float subsurfaceDistortion;
    float subsurfacePower;
    float3 subsurfaceColor;
    float subsurfaceThickness;

    float thinFilmFactor;
    float thinFilmThickness;

    float thickness;

    float3 absorption;

    float transmission;
};

// https://github.com/KhronosGroup/glTF-Sample-Viewer/blob/master/src/shaders/pbr.frag#L136
NormalInfo getNormalInfo(VsOutTexNorm input)
{
    // create tangent basis:

    float3 t = normalize(input.TangentBasisX);
    float3 b = normalize(input.TangentBasisY);
    float3 ng = normalize(input.TangentBasisZ);
    float3x3 tangentBasis = float3x3(t, b, ng);

    // Compute pertubed normals:

    float3 n = SAMPLE_TEXTURE(NormalTexture, input.TextureCoordinate).xyz * float3(2, 2, 2) - float3(1, 1, 1);
    n *= float3(NormalScale.x, NormalScale.x, 1.0);
    n = mul(n, tangentBasis);
    n = normalize(n);

    NormalInfo info;
    info.ng = ng;
    info.t = t;
    info.b = b;
    info.n = n;
    return info;
}

float4 getBaseColor(float2 uv, float4 vertexColor)
{
    
#ifdef MATERIAL_SPECULARGLOSSINESS
    float4 baseColor = DiffuseScale;
#elif defined(MATERIAL_METALLICROUGHNESS)
    float4 baseColor = BaseColorScale;
#else
    float4 baseColor = 1;
#endif

#ifdef MATERIAL_SPECULARGLOSSINESS
    baseColor *= sRGBToLinear(SAMPLE_TEXTURE(DiffuseTexture, uv));
#elif MATERIAL_METALLICROUGHNESS
    baseColor *= sRGBToLinear(SAMPLE_TEXTURE(BaseColorTexture, uv));
#endif    

    return baseColor * vertexColor;
}


MaterialInfo getMetallicRoughnessInfo(MaterialInfo info, float f0_ior, float2 uv)
{
    info.metallic = MetalRoughnessScale.x;
    info.perceptualRoughness = MetalRoughnessScale.y;


    // Roughness is stored in the 'g' channel, metallic is stored in the 'b' channel.
    // This layout intentionally reserves the 'r' channel for (optional) occlusion map data
    float4 mrSample = SAMPLE_TEXTURE(MetalRoughnessTexture, uv);
    info.perceptualRoughness *= mrSample.g;
    info.metallic *= mrSample.b;


#ifdef MATERIAL_METALLICROUGHNESS_SPECULAROVERRIDE
    // Overriding the f0 creates unrealistic materials if the IOR does not match up.
    float3 f0 = getMetallicRoughnessSpecularFactor();
#else
    // Achromatic f0 based on IOR.
    float3 f0 = f0_ior;
#endif

    info.albedoColor = lerp(info.baseColor.rgb * (1.0 - f0), 0, info.metallic);
    info.f0 = lerp(f0, info.baseColor.rgb, info.metallic);

    return info;
}

